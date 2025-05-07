# frozen_string_literal: true
# Helper methods for users
module UserHelper
  def role_status_style(user_role)
    user_role ? "td-true bi-check-circle-fill" : "td-false bi-exclamation-circle"
  end
end
