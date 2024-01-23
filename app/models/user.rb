# frozen_string_literal: true

require "csv"
class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :rememberable, :omniauthable

  PROJECT_SPONSOR = :project_sponsor
  MEDIAFLUX_ADMIN = :mediaflux_admin
  USER_REGISTRATION_LIST = Rails.root.join("data", "user_registration_list.csv")

  def self.from_cas(access_token)
    user = User.find_by(provider: access_token.provider, uid: access_token.uid)
    if user.nil?
      # Create the user with some basic information from CAS.
      #
      # Other bits of information that we could use are:
      #
      #   access_token.extra.department (e.g. "Library - Information Technology")
      #   access_token.extra.extra.departmentnumber (e.g. "41006")
      #   access_token.extra.givenname (e.g. "Harriet")
      #   access_token.extra.displayname (e.g. "Harriet Tubman")
      #
      user = User.new
      user.provider = access_token.provider
      user.uid = access_token.uid # this is the netid
      user.email = access_token.extra.mail
      user.initialize_name_values(access_token.extra)
      user.save
    elsif user.given_name.nil? # fix any users that do not have the name information loaded
      user.initialize_name_values(access_token.extra)
      user.save
    end
    user
  end

  def self.all_users
    User.all.map(&:uid)
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

  def self.csv_data
    CSV.parse(File.read(USER_REGISTRATION_LIST), headers: true)
  end

  def self.load_registration_list
    User.csv_data.each do |line|
      next if User.find_by(uid: line["NetID"])
      user = User.new
      user.uid = line["NetID"]
      user.family_name = line["LastName"]
      user.display_name = line["DisplayName"]
      user.email = user.uid + "@princeton.edu"
      user.save
    end
  end
end
