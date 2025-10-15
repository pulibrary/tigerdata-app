# frozen_string_literal: true
class PrincetonUsers
  CHARS_AND_NUMS =  ('a'..'z').to_a + (0..9).to_a + ['-']
  RDSS_DEVELOPERS = %w[bs3097 jrg5 cac9 hc8719 rl3667 kl37 pp9425 jh6441].freeze

  class << self


    # Returns a list of Users that match the given query
    def user_list_query(query)
      tokens = query.downcase.strip.split(/[^a-zA-Z\d]/).compact_blank
      return [] if tokens.count == 0

      user_query = tokens.inject(User.all) do |partial_query, token|
                     search_token = '%'+User.sanitize_sql_like(token)+'%'
                     partial_query.where("(LOWER(display_name) like ?) OR (LOWER(uid) like ?)", search_token, search_token).order(:display_name)
                   end
      user_query.map{|user| { uid: user.uid, name: user.display_name, display_name: user.display_name_safe } }
    end

    def load_rdss_developers
      RDSS_DEVELOPERS.each do |netid|
        create_user_from_ldap_by_uid(netid)
        rescue TigerData::LdapError
        raise TigerData::LdapError, "Unable to create user from LDAP. Are you connected to VPN?"
      end
    end

    # Creates users from LDAP data, starting with the given uid prefix.
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
      raise TigerData::LdapError, "More than one user matches supplied uid: #{uid}" if person.length > 1
      raise TigerData::LdapError, "No user with uid #{uid} found" if person.empty?
      user_from_ldap(person.first)
    end

  # Creates or updates a User from an LDAP entry.
  # @param ldap_person [Net::LDAP::Entry] an LDAP entry representing a person
  # @return [User, nil] the created or updated User, or nil if the LDAP entry is missing a edupersonprincipalname
    def user_from_ldap(ldap_person)
      return if check_for_malformed_ldap_entries(ldap_person)
      uid = ldap_person[:uid].first.downcase
      current_entries = User.where(uid:)
      if current_entries.empty?
        User.create(uid: , display_name: ldap_person[:pudisplayname].first,
                    family_name: ldap_person[:sn].first, given_name: ldap_person[:givenname].first,
                    email: ldap_person[:edupersonprincipalname].first, provider: "cas")
      else
        user = current_entries.first
        if user.display_name.blank?
          user.display_name = ldap_person[:pudisplayname].first
          user.family_name = ldap_person[:sn].first
          user.given_name = ldap_person[:givenname].first
          user.provider = "cas"
          user.save
        end
        user
      end
    end

    # If any required LDAP fields are missing, return true
    # @param ldap_person [Net::LDAP::Entry] an LDAP entry representing a person
    # @return [Boolean] true if the LDAP entry is missing required fields, false otherwise
    def check_for_malformed_ldap_entries(ldap_person)
      uid_blank = ldap_person[:uid].blank?
      edupersonprincipalname_blank = ldap_person[:edupersonprincipalname].blank?
      malformed = uid_blank || edupersonprincipalname_blank
      malformed
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
