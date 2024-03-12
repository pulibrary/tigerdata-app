# frozen_string_literal: true
require "rails_helper"

RSpec.describe TigerdataSchema, type: :model do

    let (:aterm_schema_command_pretty) do   
        "asset.doc.namespace.update :create true :namespace tigerdata :description \"TigerData metadata schema\"\n\n" \
        "asset.doc.type.update :create true :description \"Project metadata\" :type tigerdata:project :definition < \\\n" \
        " :element -name Code -type string -index true -min-occurs 1 -max-occurs 1 -label \"Code\" \\\n" \
        "   < \\\n" \
        "     :description \"The unique identifier for the project\" \\\n" \
        "   > \\\n" \
        " :element -name Title -type string -min-occurs 1 -max-occurs 1 -label \"Title\" \\\n" \
        "   < \\\n" \
        "     :description \"A plain-language title for the project\" \\\n" \
        "     :instructions \"A plain-language title for the project (at the highest level, if sub-projects exist), which will display in metadata records and search results, and which can be edited later (unlike the Project ID).\" \\\n" \
        "   > \\\n" \
        " :element -name Description -type string -min-occurs 0 -max-occurs 1 -label \"Description\" \\\n" \
        "   < \\\n" \
        "     :description \"A brief description of the project\" \\\n" \
        "     :instructions \"A brief description of the project (at the highest level, if sub-projects exist), which serves to summarize the project objectives and (anticipated) data and metadata included in the project.\" \\\n" \
        "   > \\\n" \
        " :element -name Status -type string -index true -min-occurs 1 -max-occurs 1 -label \"Status\" \\\n" \
        "   < \\\n" \
        "     :description \"The current status of the project\" \\\n" \
        "   > \\\n" \
        " :element -name DataSponsor -type string -index true -min-occurs 1 -max-occurs 1 -label \"Data Sponsor\" \\\n" \
        "   < \\\n" \
        "     :description \"The person who takes primary responsibility for the project\" \\\n" \
        "     :instructions \"The ‘Data Sponsor’ is the person who takes primary responsibility for the project, including oversight of all of the other roles, all of the data contained in the project, and all of the metadata associated with the data and the project itself. This field is required for all projects in TigerData, and all files in a given project inherit the Data Sponsor value from the project metadata. The person filling the role must be both a registered TigerData user and a current member of the list of eligible Data Sponsors for TigerData.\" \\\n" \
        "   > \\\n" \
        " :element -name DataManager -type string -index true -min-occurs 1 -max-occurs 1 -label \"Data Manager\" \\\n" \
        "   < \\\n" \
        "     :description \"The person who manages the day-to-day activities for the project\" \\\n" \
        "     :instructions \"The ‘Data Manager’ is the person who manages the day-to-day activities for the project, including both data and metadata, but not including role assignments, which is instead determined by the Data Sponsor. (However, the same person may fill both the Data Sponsor and the Data Manager roles on the same project, provided they are eligible for both.) This field is required for all projects in TigerData, and all files in a given project inherit the Data Manager value from the project metadata. The person filling the role must be both a registered TigerData user and current member of the list of eligible Data Managers for TigerData.\" \\\n" \
        "   > \\\n" \
        " :element -name DataUser -type string -index true -min-occurs 0 -label \"Data User(s)\" \\\n" \
        "   < \\\n" \
        "     :description \"A person who has read and write access privileges to the project\" \\\n" \
        "     :instructions \"A ‘Data User’ is a person who has access privileges to a given project or file, including data and metadata. This field is optional for both projects and files. Any number of Data Users may be assigned to a given project or file, with or without a read-only restriction. All Data Users must be registered for TigerData prior to assignment.\" \\\n" \
        "     :attribute -name ReadOnly -type boolean -min-occurs 0 \\\n" \
        "       < :description \"Determines whether a given Data User is limited to read-only access to files\" > \\\n" \
        "   > \\\n" \
        " :element -name Department -type string -index true -min-occurs 1 -label \"Affiliated Department(s)\" \\\n" \
        "   < \\\n" \
        "     :description \"The primary Princeton University department(s) affiliated with the project\" \\\n" \
        "     :instructions \"The primary Princeton University department(s) affiliated with the project. In cases where the Data Sponsor holds cross-appointments, or where multiple departments are otherwise involved with the project, multiple departments may be recorded.\" \\\n" \
        "   > \\\n" \
        " :element -name CreatedOn -type date -min-occurs 1 -max-occurs 1 -label \"Created On\" \\\n" \
        "   < \\\n" \
        "     :description \"Timestamp project was created\" \\\n" \
        "   > \\\n" \
        " :element -name CreatedBy -type string -min-occurs 1 -max-occurs 1 -label \"Created By\" \\\n" \
        "   < \\\n" \
        "     :description \"User that created the project\" \\\n" \
        "   > \\\n" \
        " :element -name UpdatedOn -type date -min-occurs 0 -max-occurs 1 -label \"Updated On\" \\\n" \
        "   < \\\n" \
        "     :description \"Timestamp project was updated\" \\\n" \
        "   > \\\n" \
        " :element -name UpdatedBy -type string -min-occurs 0 -max-occurs 1 -label \"Updated By\" \\\n" \
        "   < \\\n" \
        "     :description \"User that updated the project\" \\\n" \
        "   > \\\n" \
        " :element -name ProjectID -type string -index true -min-occurs 1 -max-occurs 1 -label \"Project ID\" \\\n" \
        "   < \\\n" \
        "     :description \"The pul datacite drafted doi\" \\\n" \
        "     :instructions \"Records the DOI reserved for the project, from which the automatic code component of the Project ID is determined\" \\\n" \
        "   > \\\n" \
        " :element -name StorageCapacity -type string -index true -min-occurs 1 -max-occurs 1 -label \"Storage Capacity\" \\\n" \
        "   < \\\n" \
        "     :description \"The requested storage capacity (default 500 GB)\" \\\n" \
        "     :instructions \"The anticipated amount of storage needed (in gigabytes or terabytes), given so that the system administrators can prepare the appropriate storage systems for access by the project team\" \\\n" \
        "   > \\\n" \
        " :element -name StoragePerformance -type string -index true -min-occurs 1 -max-occurs 1 -label \"Storage Performance Expectations\" \\\n" \
        "   < \\\n" \
        "     :description \"The requested storage performance (default Standard)\" \\\n" \
        "     :instructions \"The expected needs for storage performance, i.e. relative read/write and transfer speeds. The ‘Standard’ default for TigerData is balanced and tuned for moderate usage. Those who expect more intensive usage should select the ‘Premium’ option, while those who expect to simply store their data for long-term, low-usage should select the ‘Eco’ option\" \\\n" \
        "   > \\\n" \
        " :element -name ProjectPurpose -type string -index true -min-occurs 1 -max-occurs 1 -label \"Project Purpose\" \\\n" \
        "   < \\\n" \
        "     :description \"The project purpose (default Research)\" \\\n" \
        "     :instructions \"The high-level category for the purpose of the project: ‘Research’ (default), ‘Administrative’, or ‘Library Archive’.\" \\\n" \
        "   > \\\n" \
        ">"
    end

    describe "#create_aterm_script" do

        let (:aterm_schema_command) { aterm_schema_command_pretty.gsub("\" \\\n","\"").gsub("< \\\n","<").gsub("> \\\n",">").gsub("0 \\\n","0") }

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
