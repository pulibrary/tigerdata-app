# frozen_string_literal: true
class ReadOnlyUser < User
  def data_user_name
    super + " (read only)"
  end
end
