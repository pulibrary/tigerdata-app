# frozen_string_literal: true
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :rememberable, :omniauthable

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
      user.save
    end
    user
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
end
