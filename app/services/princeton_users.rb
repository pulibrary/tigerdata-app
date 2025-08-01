# frozen_string_literal: true
class PrincetonUsers
  CHARS_AND_NUMS =  ('a'..'z').to_a + (0..9).to_a + ['-']

  class << self

    def user_list
      Rails.cache.fetch("princeton_user_list", expires_in: 6.hours) do
        @user_list = User.all.map { |user| { uid: user.uid, name: user.display_name } }
      end
    end

    def create_users_from_ldap(current_uid_start: "", ldap_connection: default_ldap_connection)
      CHARS_AND_NUMS.each do |char|
        filter =(~ Net::LDAP::Filter.eq( "pustatus", "guest" )) & Net::LDAP::Filter.eq("uid", "#{current_uid_start}#{char}*")
        people = ldap_connection.search(filter:, attributes: [:pudisplayname, :givenname, :sn, :uid, :edupersonprincipalname]);
        if ldap_connection.get_operation_result.message == "Success"
          people.each{|person| user_from_ldap(person)}
        else
          create_users_from_ldap(current_uid_start: "#{current_uid_start}#{char}", ldap_connection:)
        end
      end
    end

    def create_user_from_ldap_by_uid(uid, ldap_connection: default_ldap_connection)
      filter = Net::LDAP::Filter.eq('uid', uid)
      person = ldap_connection.search(filter:, attributes: [:pudisplayname, :givenname, :sn, :uid, :edupersonprincipalname]);
      raise StandardError "More than one user matches supplied uid: #{uid}" if person.length > 1
      raise StandardError "No user with uid #{uid} found" if person.empty?
      user_from_ldap(person.first)
    end

    def user_from_ldap(ldap_person)
      return if ldap_person[:edupersonprincipalname].blank?
      uid = ldap_person[:uid].first.downcase
      current_entries = User.where(uid:)
      if current_entries.empty?
        User.create(uid: , display_name: ldap_person[:pudisplayname].first, 
                    family_name: ldap_person[:sn].first, given_name: ldap_person[:givenname].first, 
                    email: ldap_person[:edupersonprincipalname].first)
      else
        user = current_entries.first
        if user.display_name.blank?
          user.display_name = ldap_person[:pudisplayname].first
          user.family_name = ldap_person[:sn].first
          user.given_name = ldap_person[:givenname].first
          user.save
        end
      end
    end

    def default_ldap_connection
      @default_ldap_connection ||= Net::LDAP.new host: "ldap.princeton.edu", base: "o=Princeton University,c=US", port: 636,
                                                  encryption: {
                                                    method: :simple_tls,
                                                    tls_options: OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
                                                  }
    end
  end
end
