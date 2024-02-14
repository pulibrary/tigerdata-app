# frozen_string_literal: true

require "csv"
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :rememberable, :omniauthable

  has_many :user_jobs, dependent: :destroy

  USER_REGISTRATION_LIST = Rails.root.join("data", "user_registration_list.csv")

  def self.from_cas(access_token)
    user = User.find_by(provider: access_token.provider, uid: access_token.uid)
    if user.present? && user.given_name.nil? # fix any users that do not have the name information loaded
      user.initialize_name_values(access_token.extra)
      user.save
    end
    user
  end

  def self.all_users
    User.all.map(&:uid)
  end

  def self.sponsor_users
    users = if Rails.env.development? || Rails.env.staging?
              User.where(eligible_sponsor: true).or(User.where(superuser: true))
            else
              User.where(eligible_sponsor: true)
            end
    users.map(&:uid)
  end

  def clear_mediaflux_session(session)
    @mediaflux_session = nil
    session[:mediaflux_session] = nil
  end

  def mediaflux_from_session(session)
    if session[:mediaflux_session].blank?
      session[:mediaflux_session] = mediaflux_session
    else
      @mediaflux_session = session[:mediaflux_session]
    end
  end

  def mediaflux_session
    @mediaflux_session ||= begin
                            logon_request = Mediaflux::Http::LogonRequest.new
                            logon_request.resolve
                            logon_request.session_token
                          end
  end

  def terminate_mediaflux_session
    return if @mediaflux_session.nil? # nothing to terminate

    Mediaflux::Http::LogoutRequest.new(session_token: @mediaflux_session).response_body
    @mediaflux_session = nil
  end

  def initialize_name_values(extra_cas_info)
    self.given_name = extra_cas_info.givenname
    self.family_name =  extra_cas_info.sn
    self.display_name = extra_cas_info.pudisplayname
  end

  def display_name_safe
    return uid if display_name.blank?

    display_name
  end

  def eligible_sponsor?
    return true if superuser
    super
  end

  def eligible_manager?
    return true if superuser
    super
  end

  def eligible_sysadmin?
    return true if superuser || sysadmin
  end

  def self.csv_data
    CSV.parse(File.read(USER_REGISTRATION_LIST), headers: true)
  end

  def self.load_registration_list
    User.csv_data.each do |line|
      user = User.find_by(uid: line["uid"]) || User.new
      user.uid = line["uid"]
      user.family_name = line["family_name"]
      user.display_name = line["display_name"]
      user.email = user.uid + "@princeton.edu"
      # If we don't say that this is a cas user, they won't be able to log in with CAS
      user.provider = "cas"
      user.eligible_sponsor = line["eligible_sponsor"] == "TRUE"
      user.eligible_manager = line["eligible_manager"] == "TRUE"
      user.superuser = line["superuser"] == "TRUE"
      user.sysadmin = line["sysadmin"] == "TRUE"
      user.save
    end
  end
end
