# frozen_string_literal: true

# Converts the cas token into a user
class UserFromEntraAttributes <  Dry::Operation

  def call(access_token:)
    uid = step parse_entra_uid(access_token)
    current_user = step existing_user(uid:)
    user_attributes = step user_from_token(uid:, current_user:, access_token:)
  end

  private

  def existing_user(uid:)
    user = User.find_by(uid: uid)
    if user.nil?
      return( Failure(:user_not_found, "User with uid #{uid} not found") ) 
    end
    Success(user)
  end

  def user_from_token(uid:, current_user:, access_token:)
    if current_user.given_name.blank?
      current_user.given_name = access_token.extra.raw_info.given_name || uid
      current_user.family_name = access_token.extra.raw_info.family_name || uid
      current_user.display_name = access_token.extra.raw_info.name || uid
      current_user.save!
    end
    return Success(current_user)
  end

  def parse_entra_uid(access_token)
    return Failure(:invalid_token, "Invalid access token") if access_token.nil?

    email = access_token.extra.raw_info.unique_name
    uid = email.split('@princeton.edu').first
    return Success(uid)
  end
end
