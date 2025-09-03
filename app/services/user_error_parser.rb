# frozen_string_literal: true
class UserErrorParser
  class << self
    def csv_users(errors_str)
      users = parse(errors_str)
      "uid,email,given_name,family_name,display_name,eligible_sponsor," \
      "eligible_manager,developer,sysadmin,tester_trainer,DateAdded,AddedBy,Notes\n" \
      "#{users.join("\n")}"
    end

    def parse(errors_str)
      errors = errors_str.split("\n")
      roles = errors.map { |error| parse_line(error) }.flatten
      user_roles = roles.group_by { |role| role[:uid] }
      user_roles.map do |uid, user_role|
        "#{uid},,,,,#{sponsor_flag(user_role)},#{manager_flag(user_role)},,,,#{report_date},ImportProcess,\"Capacity Early Adopter\""
      end
    end

      private

        def parse_line(error)
          error_messages = error.split(";")
          error_messages.map do |str|
            user_role = str.split(":").last
            parts = user_role.split(" for role ")
            uid = parts.first
            role = parts.last
            { uid: uid.strip, role: role.strip }
          end
        end

        def report_date
          Time.current.in_time_zone("America/New_York").strftime("%Y-%m-%d")
        end

        def sponsor_flag(roles)
          if roles.count { |data| data[:role] == "Data Sponsor" }.positive?
            "TRUE"
          else
            ""
          end
        end

        def manager_flag(roles)
          if roles.count { |data| data[:role] == "Data Manager" }.positive?
            "TRUE"
          else
            ""
          end
        end
  end
end
