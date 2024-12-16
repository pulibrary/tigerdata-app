# frozen_string_literal: true
class MediafluxChannel < ApplicationCable::Channel
  def subscribed
    update_state
  end

  def unsubscribed
    transmit({ state: false })
  end

  def update_state
    state = mf_version.present?

    transmit({ state: state })
  end

  private

    def session_token
      SystemUser.mediaflux_session
    end

    def version_request
      Mediaflux::VersionRequest.new(session_token: session_token)
    end

    def mf_version
      version_request.version
    end
end
