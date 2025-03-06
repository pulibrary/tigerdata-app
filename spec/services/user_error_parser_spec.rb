# frozen_string_literal: true
require "rails_helper"

RSpec.describe UserErrorParser do
  let(:data) do
    "Error creating project for 1013662446: Invalid netid: uid1 for role Data Manager;" \
    "Invalid netid: uid2 for role Data Sponsor;Invalid netid: uid3 for role Data User Read Only;" \
    "Invalid netid: uid4 for role Data User Read Only;Invalid netid: uid5 for role Data User Read Only;"\
    "Invalid netid: uid6 for role Data User Read Only;Invalid netid: uid7 for role Data User Read Only;Invalid netid: uid8 for role Data User Read Only\n" \
    "Error creating project for 11307511: Invalid netid: uid1 for role Data Sponsor\n" \
    "Error creating project for 888956429: Invalid netid: uid9 for role Data Manager;Invalid netid: uid10 for role Data Sponsor;Invalid netid: uid12 for role Data User Read Only\n" \
    "Error creating project for 891009485: Invalid netid: uid3 for role Data Manager;Invalid netid: uid13 for role Data Sponsor;" \
    "Invalid netid: uid5 for role Data User Read Only;Invalid net id: uid11 for role Data User Read Only\n"
  end

  let(:data_output) do
    [
      "uid1,,,,,TRUE,TRUE,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
      "uid2,,,,,TRUE,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
      "uid3,,,,,,TRUE,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
      "uid4,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
      "uid5,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
      "uid6,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
      "uid7,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
      "uid8,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
      "uid9,,,,,,TRUE,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
      "uid10,,,,,TRUE,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
      "uid12,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
      "uid13,,,,,TRUE,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
      "uid11,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\""
    ]
  end

  describe "#parse" do
    let(:data_sponsor_only) { "Error creating project for 1013662446: Invalid netid: uid1 for role Data Sponsor\n" }
    let(:data_sponsor_only_output) { "uid1,,,,,TRUE,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"" }
    let(:data_sponsor_and_manager) { "Error creating project for 1013662446: Invalid netid: uid1 for role Data Manager; Invalid netid: uid1 for role Data Sponsor\n" }
    let(:data_sponsor_and_manager_output) { "uid1,,,,,TRUE,TRUE,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"" }
    let(:multiple_user) do
      "Error creating project for 1013662446: Invalid netid: uid1 for role Data Manager;Invalid netid: uid2 for role Data Sponsor;" \
      "Invalid netid: uid3 for role Data User Read Only;Invalid netid: uid4 for role Data User Read Only;Invalid netid: uid5 for role Data User Read Only;" \
      "Invalid netid: uid6 for role Data User Read Only;Invalid netid: uid7 for role Data User Read Only;Invalid netid: uid8 for role Data User Read Only\n"
    end
    let(:multiple_user_output) do
      [
        "uid1,,,,,,TRUE,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
        "uid2,,,,,TRUE,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
        "uid3,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
        "uid4,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
        "uid5,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
        "uid6,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
        "uid7,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\"",
        "uid8,,,,,,,,,,#{Time.current.in_time_zone('America/New_York').strftime('%Y-%m-%d')},ImportProcess,\"Capacity Early Adopter\""
      ]
    end

    it "creates 1 row with data sponsor " do
      output = UserErrorParser.parse(data_sponsor_only)
      expect(output.count).to eq(1)
      expect(output.first).to eq(data_sponsor_only_output)
    end

    it "creates 1 row with data sponsor and data manager" do
      output = UserErrorParser.parse(data_sponsor_and_manager)
      expect(output.count).to eq(1)
      expect(output.first).to eq(data_sponsor_and_manager_output)
    end

    it "creates a row for each user" do
      output = UserErrorParser.parse(multiple_user)
      expect(output.count).to eq(8)
      output.each_with_index { |line, idx| expect(line).to eq(multiple_user_output[idx]) }
    end

    it "can process multiple lines" do
      output = UserErrorParser.parse(data)
      expect(output.count).to eq(13)
      output.each_with_index { |line, idx| expect(line).to eq(data_output[idx]) }
    end
  end

  describe "csv_users" do
    let(:header_line) { "uid,email,given_name,family_name,display_name,eligible_sponsor,eligible_manager,superuser,sysadmin,tester_trainer,DateAdded,AddedBy,Notes\n" }

    it "produces a csv with a header" do
      csv = UserErrorParser.csv_users(data)
      expect(csv).to eq(header_line + data_output.join("\n"))
    end
  end
end
