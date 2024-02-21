# frozen_string_literal: true
require "rails_helper"

RSpec.describe TigerdataSchema, type: :model do

    let (:aterm_schema_command_pretty) do
        "asset.doc.namespace.update :create true :namespace tigerdata :description \"TigerData metadata schema\"\n\n" \
        "asset.doc.type.update :create true :description \"Project metadata\" :type tigerdata:project :definition < \\\n" \
        " :element -name code -type string -index true -min-occurs 1 -max-occurs 1 -label \"The unique identifier for the project\" \\\n" \
        " :element -name title -type string -min-occurs 1 -max-occurs 1 -label \"A plain-language title for the project\" \\\n" \
        " :element -name description -type string -min-occurs 0 -max-occurs 1 -label \"A brief description of the project\" \\\n" \
        " :element -name status -type string -index true -min-occurs 1 -max-occurs 1 -label \"The current status of the project\" \\\n" \
        " :element -name data_sponsor -type string -index true -min-occurs 1 -max-occurs 1 -label \"The person who takes primary responsibility for the project\" \\\n" \
        " :element -name data_manager -type string -index true -min-occurs 1 -max-occurs 1 -label \"The person who manages the day-to-day activities for the project\" \\\n" \
        " :element -name data_users_rw -type string -index true -min-occurs 0 -label \"A person who has read and write access privileges to the project\" \\\n" \
        " :element -name data_users_ro -type string -index true -min-occurs 0 -label \"A person who has read-only access privileges to the project\" \\\n" \
        " :element -name departments -type string -index true -min-occurs 1 -label \"The primary Princeton University department(s) affiliated with the project\" \\\n" \
        " :element -name created_on -type date -min-occurs 1 -max-occurs 1 -label \"Timestamp project was created\" \\\n" \
        " :element -name created_by -type string -min-occurs 1 -max-occurs 1 -label \"User that created the project\" \\\n" \
        " :element -name updated_on -type date -min-occurs 0 -max-occurs 1 -label \"Timestamp project was updated\" \\\n" \
        " :element -name updated_by -type string -min-occurs 0 -max-occurs 1 -label \"User that updated the project\" \\\n" \
        " :element -name project_id -type string -index true -min-occurs 1 -max-occurs 1 -label \"The pul datacite drafted doi\" \\\n"\
        " :element -name storage_capacity -type string -index true -min-occurs 1 -max-occurs 1 -label \"The requested storage capacity (default 500 GB)\" \\\n"\
        " :element -name storage_performance -type string -index true -min-occurs 1 -max-occurs 1 -label \"The requested storage performance (default Standard)\" \\\n"\
        " :element -name project_purpose -type string -index true -min-occurs 1 -max-occurs 1 -label \"The project purpose (default Research)\" \\\n"\
        ">"
    end

    describe "#create_aterm_script" do

        let (:aterm_schema_command) { aterm_schema_command_pretty.gsub("\" \\\n","\"").gsub("< \\\n","<") }

        it "generates the aterm script" do
            tigerdata_schema = described_class.new(session_id: nil)
            expect(tigerdata_schema.create_aterm_schema_command).to eq(aterm_schema_command)
        end

        it "generates the human readable aterm script" do
            tigerdata_schema = described_class.new(session_id: nil)
            expect(tigerdata_schema.create_aterm_schema_command(" \\\n")).to eq(aterm_schema_command_pretty)
        end
    end

    describe "#create_aterm_doc_script" do
      it "creates a file in the doc area" do
        tigerdata_schema = described_class.new(session_id: nil)
        filename = Rails.root.join("tmp","script.txt")
        tigerdata_schema.create_aterm_doc_script(filename: )
        File.open(filename) do |file|
            file_contents = file.read
            expect(file_contents).to include(aterm_schema_command_pretty)
            expect(file_contents).to include("# This file was automatically generated")
            expect(file_contents).to include("To run this script")
            expect(file_contents).to include("script.execute :in file://")
        end
        File.delete(filename)
      end
    end
end
