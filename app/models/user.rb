# frozen_string_literal: true
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :rememberable, :omniauthable

  has_many :allowed_roles, dependent: :restrict_with_exception
  has_many :project_user_roles, dependent: :restrict_with_exception

  def self.from_cas(access_token)
    user = User.find_by(provider: access_token.provider, uid: access_token.uid) || User.new

    # Update/create the user with some basic information from CAS.
    #
    # Other bits of information that we could use are:
    #
    #   access_token.extra.department (e.g. "Library - Information Technology")
    #   access_token.extra.extra.departmentnumber (e.g. "41006")
    #   access_token.extra.givenname (e.g. "Harriet")
    #   access_token.extra.displayname (e.g. "Harriet Tubman")
    #

    user.provider = access_token.provider
    user.uid = access_token.uid # this is the netid
    user.email = access_token.extra.mail
    user.save
    user
  end
end
