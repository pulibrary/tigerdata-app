# frozen_string_literal: true

# Represents a nil user that returns default values.
class NilUser
  # Gets the display name for nil user.
  # @return [String] "NA"
  def display_name_only_safe
    "NA"
  end

  # Gets the uid for nil user.
  # @return [String] ""
  def uid
    ""
  end
end
