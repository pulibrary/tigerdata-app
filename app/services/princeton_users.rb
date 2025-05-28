# frozen_string_literal: true
class PrincetonUsers
  class << self
    def user_list
      Rails.cache.fetch("princeton_user_list", expires_in: 6.hours) do
        # TODO: - pull this from ldap instead of just the database
        @user_list = User.all.map { |user| { uid: user.uid, name: user.display_name } }
      end
    end
  end
end
