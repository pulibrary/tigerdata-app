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
      User.where(eligible_sponsor: true).or(User.where(superuser: true))
    else
      User.where(eligible_sponsor: true)
    end
  end

  # Users that can be data managers
  def self.manager_users
    if Rails.env.development? || Rails.env.staging?
      User.where(eligible_manager: true).or(User.where(superuser: true))
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

  def medaiflux_login(token, session)
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
    return uid if display_name.blank?

    display_name
  end

  # Is this user eligible to be a data sponsor in this environment?
  # @return [Boolean]
  def eligible_sponsor?
    return true if superuser
    super
  end

  # Is this user eligible to be a data manger in this environment?
  # @return [Boolean]
  def eligible_manager?
    return true if superuser
    super
  end

  # Is this user eligible to be a data user in this environment?
  # @return [Boolean]
  def eligible_data_user?
    return true if superuser
    return true if !eligible_sponsor? && !eligible_manager
  end

  # Is this user eligible to be a sysadmin in this environment?
  # @return [Boolean]
  def eligible_sysadmin?
    return true if superuser || sysadmin
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
    @latest_downloads ||= UserRequest.where(user_id: id).where(["completion_time > ?", 7.days.ago]).order(created_at: "DESC").limit(limit)
  end
end
