# frozen_string_literal: true
class UserPresenter
  attr_reader :user

  delegate :uid, :family_name, to: :user

  def initialize(user)
    @user = user
  end

  def display_name
    user.display_name_only_safe
  end

  def access_type
    "Data User - Read Only"
  end
end
