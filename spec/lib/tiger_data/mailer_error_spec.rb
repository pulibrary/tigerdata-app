# frozen_string_literal: true
require "rails_helper"

RSpec.describe TigerData::MailerError do
  it "can be instantiated" do
    mailererror = TigerData::MailerError.new
    expect(mailererror).to be_instance_of TigerData::MailerError
  end
end
