# frozen_string_literal: true
require "rails_helper"

RSpec.describe TigerData::LdapError do
  it "can be instantiated" do
    ldaperror = TigerData::LdapError.new
    expect(ldaperror).to be_instance_of TigerData::LdapError
  end
end
