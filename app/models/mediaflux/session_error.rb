# frozen_string_literal: true
module Mediaflux
  # A error to be thrown when the session logon has an error
  #   This error should not happen, but can happen if there is a bad password or a communication error
  #
  class SessionError < StandardError
  end
end
