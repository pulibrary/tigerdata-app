# frozen_string_literal: true
class ReadOnlyUser < User
  def display_name_safe
    super + " (read only)"
  end
end
