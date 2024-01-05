# frozen_string_literal: true
require "dry/monads"
include Dry::Monads[:result] # Needed to mock the datacite client Success and Failure

def stub_datacite_doi(result: Success("It worked"))
  stub_datacite = instance_double("Datacite::Client")
  allow(stub_datacite).to receive(:update).and_return(result)
  allow(Datacite::Client).to receive(:new).and_return(stub_datacite)
  stub_datacite
end
