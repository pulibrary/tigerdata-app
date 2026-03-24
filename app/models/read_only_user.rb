# frozen_string_literal: true

# Represents a read-only user, extending User with modified display name.
class ReadOnlyUser < User
  # Gets the display name with read-only indicator.
  # @return [String] the display name with "(read only)"
  def display_name_safe
    super + " (read only)"
  end
end
