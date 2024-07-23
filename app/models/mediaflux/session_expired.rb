# frozen_string_literal: true
module Mediaflux
  # A error to be thrown when the session has expired
  #   This error should be rescued and the session reinitialize when this occurs
  #
  class SessionExpired < StandardError
  end
end
