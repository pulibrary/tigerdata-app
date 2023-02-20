# frozen_string_literal: true
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :omniauthable

  def self.from_cas(access_token)
    User.where(provider: access_token.provider, uid: access_token.uid).first

    # You can update this logic to create users automatically after they have authenticated
    # via CAS. The hash in `request.env["omniauth.auth"]` has the information about the
    # authenticated user.
  end
end
