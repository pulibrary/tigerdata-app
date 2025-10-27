# frozen_string_literal: true

require "csv"
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :rememberable, :omniauthable

  has_many :user_requests, dependent: :destroy

  paginates_per 100

  USER_REGISTRATION_LIST = Rails.root.join("data", "user_registration_list_#{Rails.env}.csv")

  attr_accessor :mediaflux_session

  def self.from_cas(access_token)
    user = User.find_by(provider: access_token.provider, uid: access_token.uid)
    if user.present? && user.given_name.nil? # fix any users that do not have the name information loaded
      user.initialize_name_values(access_token.extra)
      user.save
    end
    user
  end

  # Users that can be project sponsors
  def self.sponsor_users
    if Rails.env.development? || Rails.env.staging?
      User.where(eligible_sponsor: true).or(User.where(developer: true))
    else
      User.where(eligible_sponsor: true)
    end
  end

  # Users that can be data managers
  def self.manager_users
    if Rails.env.development? || Rails.env.staging?
      User.where(eligible_manager: true).or(User.where(developer: true))
    else
      User.where(eligible_manager: true)
    end
  end

  def clear_mediaflux_session(session)
    Rails.logger.debug("!!!!!!! Clearing Mediaflux session !!!!!!!!")
    @mediaflux_session = nil
    session[:mediaflux_session] = nil
  end

  def mediaflux_from_session(session)
    logger.debug "Session Get #{session[:mediaflux_session]} cas: #{session[:active_web_user]}  user: #{uid}"
    if session[:mediaflux_session].blank?
      logger.debug("!!!! Creating a new session !!! #{uid}")
      session[:mediaflux_session] = SystemUser.mediaflux_session
      session[:active_web_user] = false
    end
    @active_web_user = session[:active_web_user]
    @mediaflux_session = session[:mediaflux_session]
  end

  def mediaflux_login(token, session)
    logger.debug("mediaflux session created for #{uid}")
    logon_request = Mediaflux::LogonRequest.new(identity_token: token, token_type: "cas")
    if logon_request.error?
      raise "Invalid Logon #{logon_request.response_error}"
    end
    @mediaflux_session = logon_request.session_token
    @active_web_user = true
    session[:mediaflux_session] = @mediaflux_session
    session[:active_web_user] = @active_web_user
    logger.debug "Login Session #{session[:mediaflux_session]} cas: #{session[:active_web_user]}  user: #{uid}"

    User.update_user_roles(user: self)
  end

  def terminate_mediaflux_session
    return if @mediaflux_session.nil? # nothing to terminate
    logger.debug "!!!! Terminating mediaflux session"

    Mediaflux::LogoutRequest.new(session_token: @mediaflux_session).response_body
    @mediaflux_session = nil
  end

  # Initialize the name values from the CAS information.
  # Our name fields do not match their name fields, so we need to translate.
  def initialize_name_values(extra_cas_info)
    self.given_name = extra_cas_info.givenname
    self.family_name =  extra_cas_info.sn
    self.display_name = extra_cas_info.pudisplayname
  end

  # Return the display name if it exists, otherwise return the uid
  # @return [String]
  def display_name_safe
    return uid if given_name.blank? && family_name.blank?

    [given_name, family_name, "(#{uid})"].compact.join(" ")
  end

  # Is this user eligible to be a data sponsor in this environment?
  # @return [Boolean]
  def eligible_sponsor?
    return true if developer
    super
  end

  # Is this user eligible to be a data manger in this environment?
  # @return [Boolean]
  def eligible_manager?
    return true if developer
    super
  end

  def developer?
    return true if developer
    super
  end

  # Is this user eligible to be a data user in this environment?
  # @return [Boolean]
  def eligible_data_user?
    return true if developer
    return true if !eligible_sponsor? && !eligible_manager
  end

  # Is this user eligible to be a sysadmin in this environment?
  # @return [Boolean]
  def eligible_sysadmin?
    (!Rails.env.production? && (developer || sysadmin)) || (Rails.env.production? && sysadmin)
  end

  def eligible_to_create_new?
    return true if eligible_sysadmin?

    !Rails.env.production? && (eligible_sponsor? && trainer?)
  end

  # Methods serialize_into_session() and serialize_from_session() are called by Warden/Devise
  # to calculate what information will be stored in the session and to serialize an object
  # back from the session.
  #
  # By default Warden/Devise store the database ID of the record (e.g. User.id) but this causes
  # problems if we repopulate our User table and the IDs change. The implementation provided below
  # uses the User.uid field (which is unique, does not change, and it's required) as the value to
  # store in the session to prevent this issue.
  #
  # References:
  #   https://stackoverflow.com/questions/23597718/what-is-the-warden-data-in-a-rails-devise-session-composed-of/23683925#23683925
  #   https://web.archive.org/web/20211028103224/https://tadas-s.github.io/ruby-on-rails/2020/08/02/devise-serialize-into-session-trick/
  #   https://github.com/wardencommunity/warden/wiki/Setup
  def self.serialize_into_session(record)
    # The return value _must_ have at least two elements since the serialize_from_session() requires
    # two arguments (see below)
    [record.uid, ""]
  end

  def self.serialize_from_session(key, _salt, _opts = {})
    User.where(uid: key)&.first
  end

  # Fetches the most recent download jobs for the user
  def latest_downloads(limit: 10)
    @latest_downloads ||= begin
                            downloads = UserRequest.where(user_id: id).where(["completion_time > ?", 7.days.ago]).order(created_at: "DESC").limit(limit)
                            downloads.map{|download| UserRequestPresenter.new(download)}
                          end
  end

  # Updates the user's roles (sys admin, developer) depending on the information on Mediaflux.
  # This method is meant to be used only for the current logged in user since the roles depend on the Mediaflux session.
  def self.update_user_roles(user:)
    raise "User.update_user_roles called with for a user without a Mediaflux session" if user.mediaflux_session.nil?

    mediaflux_roles = mediaflux_roles(user:)
    update_developer_status(user:, mediaflux_roles:)
    update_sysadmin_status(user:, mediaflux_roles:)
  rescue => ex
    Rails.logger.error("Error updating roles for user (id: #{user.id}) status, error: #{ex.message}")
  end

  # Returns the roles in Mediaflux for the user in the session.
  # This method is meant to be used only for the current logged in user since the roles depend on the Mediaflux session.
  def self.mediaflux_roles(user:)
    raise "User.mediaflux_roles called with for a user without a Mediaflux session" if user.mediaflux_session.nil?

    request = Mediaflux::ActorSelfDescribeRequest.new(session_token: user.mediaflux_session)
    request.resolve
    request.roles
  end

  private

  def self.update_developer_status(user:, mediaflux_roles:)
    # TODO: Figure out why the role name is different in staging from production:
    #   production:   "pu-smb-group:PU:tigerdata:librarydevelopers"
    #   staging:      "pu-oit-group:PU:tigerdata:librarydevelopers"
    #   development:  "pu-lib:developer"
    #   test:         "system-administrator"
    developer_now = mediaflux_roles.include?("pu-smb-group:PU:tigerdata:librarydevelopers") ||
      mediaflux_roles.include?("pu-oit-group:PU:tigerdata:librarydevelopers") ||
      mediaflux_roles.include?("pu-lib:developer") ||
      mediaflux_roles.include?("system-administrator")
    if user.developer != developer_now
      # Only update the record in the database if there is a change
      Rails.logger.info("Updating developer role for user #{user.id} to #{developer_now}")
      user.developer = developer_now
      user.save!
    end
  end

  def self.update_sysadmin_status(user:, mediaflux_roles:)
    sysadmin_now = mediaflux_roles.include?("system-administrator")
    if user.sysadmin != sysadmin_now
      # Only update the record in the database if there is a change
      Rails.logger.info("Updating sysadmin role for user #{user.id} to #{sysadmin_now}")
      user.sysadmin = sysadmin_now
      user.save!
    end
  end
end
