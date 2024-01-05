# frozen_string_literal: true
class PULDatacite
  class << self
    # Determines whether or not a test DOI should be referenced
    # (this avoids requests to the DOI API endpoint for non-production deployments)
    # @return [Boolean]
    def publish_test_doi?
      (Rails.env.development? || Rails.env.test?) && Rails.configuration.datacite.user.blank?
    end
  end

  attr_reader :datacite_connection

  def initialize
    @datacite_connection = Datacite::Client.new(username: Rails.configuration.datacite.user,
                                                password: Rails.configuration.datacite.password,
                                                host: Rails.configuration.datacite.host)
  end

  def draft_doi
    if PULDatacite.publish_test_doi?
      Rails.logger.info "Using hard-coded test DOI during development."
      "10.34770/tbd"
    else
      result = datacite_connection.autogenerate_doi(prefix: Rails.configuration.datacite.prefix)
      if result.success?
        result.success.doi
      else
        raise("Error generating DOI. #{result.failure.status} / #{result.failure.reason_phrase}")
      end
    end
  end
end
