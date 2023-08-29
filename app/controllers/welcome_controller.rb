# frozen_string_literal: true
class WelcomeController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    return if current_user.nil?
    version_request = Mediaflux::Http::VersionRequest.new(session_token: current_user.mediaflux_session)
    @mf_version = version_request.version
  end

  # def set_note
  #   id = params[:id]
  #   note = media_flux.get_metadata(id)[:mf_note] || ""
  #   note += "Added a note at #{Time.now.getlocal} #{Time.now.zone}\r\n"
  #   media_flux.set_note(id, note)
  #   redirect_to root_url
  # end
end
