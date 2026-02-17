# frozen_string_literal: true
class UserRolesUpdate < Dry::Operation

  def call(user:)
    step verify_session(user)
    mediaflux_roles = step retrieve_roles_from_mediaflux(user)
    step update_user_roles(user:, mediaflux_roles:)
  end

  private
    def verify_session(user)
      if user.mediaflux_session.nil?
        Failure("UserRolesUpdate called with for a user without a Mediaflux session")
      else
        Success("valid!")
      end
    end

    def retrieve_roles_from_mediaflux(user)
      request = Mediaflux::ActorSelfDescribeRequest.new(session_token: user.mediaflux_session)
      if request.error?
        Failure("Error retrieving roles from Mediaflux: #{request.response_error}")
      else
        Success request.roles
      end
    end


    def update_user_roles(user:, mediaflux_roles:)    
      changed = update_developer_status(user:, mediaflux_roles:)
      changed = update_sysadmin_status(user:, mediaflux_roles:) || changed
      changed = update_tester_status(user:, mediaflux_roles:) || changed
      if changed
        user.save!
      end
      Success(user)
    rescue StandardError => ex
      Failure("Error updating user roles! error: #{ex}")
    end


    def update_tester_status(user:, mediaflux_roles:)
      trainer_now = mediaflux_roles.include?("pu-smb-group:PU:tigerdata:tester-trainers") ||
                    mediaflux_roles.include?("pu-oit-group:PU:tigerdata:tester-trainers")
      if user.trainer != trainer_now
        # Only update the record in the database if there is a change
        Rails.logger.info("Updating trainer role for user #{user.id} to #{trainer_now}")
        user.trainer = trainer_now
        true
      else
        false
      end
    end

    def update_sysadmin_status(user:, mediaflux_roles:)
      sysadmin_now = mediaflux_roles.include?("system-administrator")
      if user.sysadmin != sysadmin_now
        # Only update the record in the database if there is a change
        Rails.logger.info("Updating sysadmin role for user #{user.id} to #{sysadmin_now}")
        user.sysadmin = sysadmin_now
        true
      else
        false
      end
    end

    def update_developer_status(user:, mediaflux_roles:)
      # Production authentication has groups prefixed by "pu-smb-group". 
      # In the future lower environments which currently have "pu-oit-group" should match production.
      # See https://github.com/PrincetonUniversityLibrary/tigerdata-config/issues/289
      #   production:            "pu-smb-group:PU:tigerdata:librarydevelopers"
      #   staging & development: "pu-oit-group:PU:tigerdata:librarydevelopers"
      #   test:                  "system-administrator"
      developer_now = mediaflux_roles.include?("pu-smb-group:PU:tigerdata:librarydevelopers") ||
        mediaflux_roles.include?("pu-oit-group:PU:tigerdata:librarydevelopers") ||
        mediaflux_roles.include?("system-administrator")
      if user.developer != developer_now
        # Only update the record in the database if there is a change
        Rails.logger.info("Updating developer role for user #{user.id} to #{developer_now}")
        user.developer = developer_now
        true
      else
        false
      end
    end

end
