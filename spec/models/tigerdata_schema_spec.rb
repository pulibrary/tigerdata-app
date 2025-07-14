# frozen_string_literal: true
require "rails_helper"

RSpec.describe TigerdataSchema, type: :model do

    let (:aterm_schema_command_pretty) do
        "asset.doc.namespace.update :create true :namespace tigerdata :description \"TigerData metadata schema\"\n\n" \
        "asset.doc.type.update :create true :description \"Project metadata\" :type tigerdata:project :definition < \\\n" \
        "  :element -name ProjectDirectory -type string -index true -min-occurs 1 -max-occurs 1 -label \"Project Directory\" \\\n" \
        "    < \\\n" \
        "      :description \"The locally unique name for the project's top-level directory\" \\\n" \
        "      :instructions \"The locally unique name for the project's top-level directory, as shown in a file path. Data Sponsors may suggest a project directory name that is meaningful to them, subject to system administrator approval.\" \\\n" \
        "    > \\\n" \
        "  :element -name Title -type string -min-occurs 1 -max-occurs 1 -label \"Title\" \\\n" \
        "    < \\\n" \
        "      :description \"A plain-language title for the project\" \\\n" \
        "      :instructions \"A plain-language title for the project (at the highest level, if sub-projects exist), which will display in metadata records and search results, and which can be edited later (unlike the Project ID).\" \\\n" \
        "    > \\\n" \
        "  :element -name Description -type string -min-occurs 0 -max-occurs 1 -label \"Description\" \\\n" \
        "    < \\\n" \
        "      :description \"A brief description of the project\" \\\n" \
        "      :instructions \"A brief description of the project (at the highest level, if sub-projects exist), which serves to summarize the project objectives and (anticipated) data and metadata included in the project.\" \\\n" \
        "    > \\\n" \
        "  :element -name Status -type string -index true -min-occurs 1 -max-occurs 1 -label \"Status\" \\\n" \
        "    < \\\n" \
        "      :description \"The current status of the project\" \\\n" \
        "      :instructions \"The current status of the project, as it pertains to the major events tracked by provenance fields (e.g., active, approved, pending, published, or retired).\" \\\n" \
        "    > \\\n" \
        "  :element -name DataSponsor -type string -index true -min-occurs 1 -max-occurs 1 -label \"Data Sponsor\" \\\n" \
        "    < \\\n" \
        "      :description \"The person who takes primary responsibility for the project\" \\\n" \
        "      :instructions \"The 'Data Sponsor' is the person who takes primary responsibility for the project, including oversight of all of the other roles, all of the data contained in the project, and all of the metadata associated with the data and the project itself. This field is required for all projects in TigerData, and all files in a given project inherit the Data Sponsor value from the project metadata. The person filling the role must be both a registered TigerData user and a current member of the list of eligible Data Sponsors for TigerData.\" \\\n" \
        "    > \\\n" \
        "  :element -name DataManager -type string -index true -min-occurs 1 -max-occurs 1 -label \"Data Manager\" \\\n" \
        "    < \\\n" \
        "      :description \"The person who manages the day-to-day activities for the project\" \\\n" \
        "      :instructions \"The 'Data Manager' is the person who manages the day-to-day activities for the project, including both data and metadata, but not including role assignments, which is instead determined by the Data Sponsor. (However, the same person may fill both the Data Sponsor and the Data Manager roles on the same project, provided they are eligible for both.) This field is required for all projects in TigerData, and all files in a given project inherit the Data Manager value from the project metadata. The person filling the role must be both a registered TigerData user and current member of the list of eligible Data Managers for TigerData.\" \\\n" \
        "    > \\\n" \
        "  :element -name DataUser -type string -index true -min-occurs 0 -label \"Data User(s)\" \\\n" \
        "    < \\\n" \
        "      :description \"A person who has read and write access privileges to the project\" \\\n" \
        "      :instructions \"A 'Data User' is a person who has access privileges to a given project or file, including data and metadata. This field is optional for both projects and files. Any number of Data Users may be assigned to a given project or file, with or without a read-only restriction. All Data Users must be registered for TigerData prior to assignment.\" \\\n" \
        "      :attribute -name ReadOnly -type boolean -min-occurs 0 \\\n" \
        "        < :description \"Determines whether a given Data User is limited to read-only access to files\" > \\\n" \
        "    > \\\n" \
        "  :element -name Department -type string -index true -min-occurs 1 -label \"Department(s)\" \\\n" \
        "    < \\\n" \
        "      :description \"The primary Princeton University department(s) affiliated with the project\" \\\n" \
        "      :instructions \"The primary Princeton University department(s) affiliated with the project. In cases where the Data Sponsor holds cross-appointments, or where multiple departments are otherwise involved with the project, multiple departments may be recorded. This field is not meant to capture the departmental affiliations of every person connected to this project, but rather the departments directly tied to the project itself.\" \\\n" \
        "    > \\\n" \
        "  :element -name CreatedOn -type date -min-occurs 1 -max-occurs 1 -label \"Created On\" \\\n" \
        "    < \\\n" \
        "      :description \"Timestamp project was created\" \\\n" \
        "    > \\\n" \
        "  :element -name CreatedBy -type string -min-occurs 1 -max-occurs 1 -label \"Created By\" \\\n" \
        "    < \\\n" \
        "      :description \"User that created the project\" \\\n" \
        "    > \\\n" \
        "  :element -name UpdatedOn -type date -min-occurs 0 -max-occurs 1 -label \"Updated On\" \\\n" \
        "    < \\\n" \
        "      :description \"Timestamp project was updated\" \\\n" \
        "    > \\\n" \
        "  :element -name UpdatedBy -type string -min-occurs 0 -max-occurs 1 -label \"Updated By\" \\\n" \
        "    < \\\n" \
        "      :description \"User that updated the project\" \\\n" \
        "    > \\\n" \
        "  :element -name ProjectID -type string -index true -min-occurs 1 -max-occurs 1 -label \"Project ID\" \\\n" \
        "    < \\\n" \
        "      :description \"The universally unique identifier for the project (or in some cases, for the sub-project), automatically generated as a valid DOI compliant with ISO 26324:2012.\" \\\n" \
        "      :instructions \"Records the DOI reserved for the project, from which the automatic code component of the Project ID is determined\" \\\n" \
        "    > \\\n" \
        "  :element -name StorageCapacity -type document -min-occurs 1 -max-occurs 1 -label \"Storage Capacity\" \\\n" \
        "    < \\\n" \
        "      :description \"The requested storage capacity (default 500 GB)\" \\\n" \
        "      :instructions \"The anticipated amount of storage needed (in gigabytes or terabytes), given so that the system administrators can prepare the appropriate storage systems for access by the project team\" \\\n" \
        "      :element -name Size -type float -min-occurs 1 -max-occurs 1 -label \"Size\" \\\n" \
        "        < \\\n" \
        "          :description \"The numerical value of the quantity\" \\\n" \
        "          :instructions \"The numerical value of the quantity (e.g., count, size, magnitude, etc.)\" \\\n" \
        "          :attribute -name Requested -type string -min-occurs 0 \\\n" \
        "            < :description \"The requested value provided by the Data Sponsor or Data Manager.\" > \\\n" \
        "          :attribute -name Approved -type string -min-occurs 0 \\\n" \
        "            < :description \"The value approved and assigned by a system administrator (may not be the same as the requested value).\" > \\\n" \
        "        > \\\n" \
        "      :element -name Unit -type string -min-occurs 1 -max-occurs 1 -label \"Unit\" \\\n" \
        "        < \\\n" \
        "          :description \"The unit of measure for the quantity\" \\\n" \
        "          :instructions \"The unit of measure for the quantity (e.g., MB, GB, TB, etc.)\" \\\n" \
        "          :attribute -name Requested -type string -min-occurs 0 \\\n" \
        "            < :description \"The requested value provided by the Data Sponsor or Data Manager.\" > \\\n" \
        "          :attribute -name Approved -type string -min-occurs 0 \\\n" \
        "            < :description \"The value approved and assigned by a system administrator (may not be the same as the requested value).\" > \\\n" \
        "        > \\\n" \
        "    > \\\n" \
        "  :element -name Performance -type string -index true -min-occurs 1 -max-occurs 1 -label \"Storage Performance Expectations\" \\\n" \
        "    < \\\n" \
        "      :description \"The requested storage performance (default Standard)\" \\\n" \
        "      :instructions \"The expected needs for storage performance, i.e. relative read/write and transfer speeds. The 'Standard' default for TigerData is balanced and tuned for moderate usage. Those who expect more intensive usage should select the 'Premium' option, while those who expect to simply store their data for long-term, low-usage should select the 'Eco' option\" \\\n" \
        "      :attribute -name Requested -type string -min-occurs 0 \\\n" \
        "        < :description \"The requested value provided by the Data Sponsor or Data Manager.\" > \\\n" \
        "      :attribute -name Approved -type string -min-occurs 0 \\\n" \
        "        < :description \"The value approved and assigned by a system administrator (may not be the same as the requested value).\" > \\\n" \
        "    > \\\n" \
        "  :element -name ProjectPurpose -type string -index true -min-occurs 1 -max-occurs 1 -label \"Project Purpose\" \\\n" \
        "    < \\\n" \
        "      :description \"The high-level category for the purpose of the project (research, administrative, or library)\" \\\n" \
        "      :instructions \"The high-level category for the purpose of the project: 'Research' (default), 'Administrative', or 'Library Archive'.\" \\\n" \
        "    > \\\n" \
        "  :element -name Submission -type document -min-occurs 1 -max-occurs 1 -label \"Submission\" \\\n" \
        "    < \\\n" \
        "      :description \"A record of a project's initial submission\" \\\n" \
        "      :instructions \"A record of a project's initial submission, including the request to create a new project and the approval or denial by system administrators.\" \\\n" \
        "      :element -name RequestedBy -type string -min-occurs 1 -max-occurs 1 -label \"Requested By\" \\\n" \
        "        < \\\n" \
        "          :description \"The person who made the request\" \\\n" \
        "          :instructions \"The person who made the request, given as a locally unique user.\" \\\n" \
        "        > \\\n" \
        "      :element -name RequestDateTime -type date -min-occurs 1 -max-occurs 1 -label \"Request Date-Time\" \\\n" \
        "        < \\\n" \
        "          :description \"The date and time the request was made\" \\\n" \
        "          :instructions \"The date and time the request was made, following ISO 8601 standards for timestamps.\" \\\n" \
        "        > \\\n" \
        "      :element -name ApprovedBy -type string -min-occurs 0 -max-occurs 1 -label \"Approved By\" \\\n" \
        "        < \\\n" \
        "          :description \"The person who approved the request\" \\\n" \
        "          :instructions \"The person who approved the request, given as a locally unique user.\" \\\n" \
        "        > \\\n" \
        "      :element -name ApprovalDateTime -type date -min-occurs 0 -max-occurs 1 -label \"Approval Date-Time\" \\\n" \
        "        < \\\n" \
        "          :description \"The date and time the request was approved\" \\\n" \
        "          :instructions \"The date and time the request was approved, following ISO 8601 standards for timestamps\" \\\n" \
        "        > \\\n" \
        "      :element -name DeniedBy -type string -min-occurs 0 -max-occurs 1 -label \"Denied  By\" \\\n" \
        "        < \\\n" \
        "          :description \"The person who denied the request\" \\\n" \
        "          :instructions \"The person who denied the request, given as a locally unique user.\" \\\n" \
        "        > \\\n" \
        "      :element -name DenialDateTime -type date -min-occurs 0 -max-occurs 1 -label \"Denial Date-Time\" \\\n" \
        "        < \\\n" \
        "          :description \"The date and time the request was denied\" \\\n" \
        "          :instructions \"The date and time the request was denied, following ISO 8601 standards for timestamps\" \\\n" \
        "        > \\\n" \
        "      :element -name EventlNote -type document -min-occurs 0 -label \"Event Note(s)\" \\\n" \
        "        < \\\n" \
        "          :description \"A supplementary record for a provenance event\" \\\n" \
        "          :instructions \"A supplementary record of noteworthy details for a given provenance event (e.g., quota decisions, storage tier assignments, revisions to submitted metadata, explanations of extenuating circumstances, etc.)\" \\\n" \
        "          :element -name NoteBy -type string -min-occurs 1 -max-occurs 1 -label \"Note By\" \\\n" \
        "            < \\\n" \
        "              :description \"The person making the note.\" \\\n" \
        "            > \\\n" \
        "          :element -name NoteDateTime -type date -min-occurs 1 -max-occurs 1 -label \"Note Date-Time\" \\\n" \
        "            < \\\n" \
        "              :description \"The date and time the note was made\" \\\n" \
        "            > \\\n" \
        "          :element -name EventType -type string -min-occurs 1 -max-occurs 1 -label \"Event Type\" \\\n" \
        "            < \\\n" \
        "              :description \"A general category label for the event note\" \\\n" \
        "            > \\\n" \
        "          :element -name Message -type string -min-occurs 1 -max-occurs 1 -label \"Message\" \\\n" \
        "            < \\\n" \
        "              :description \"The plain-language message contents of the event note.\" \\\n" \
        "            > \\\n" \
        "        > \\\n" \
        "    > \\\n" \
        "  :element -name Revision -type document -min-occurs 0 -max-occurs 1 -label \"Revision(s)\" \\\n" \
        "    < \\\n" \
        "      :description \"A record of major revisions to an active project, if applicable\" \\\n" \
        "      :instructions \"A record of major revisions to an active project, if applicable–i.e., those requiring a special request and approval from a system administrator, such as a change in the Data Sponsor or capacity and performance increases.\" \\\n" \
        "      :element -name RequestedBy -type string -min-occurs 1 -max-occurs 1 -label \"Requested By\" \\\n" \
        "        < \\\n" \
        "          :description \"The person who made the request\" \\\n" \
        "          :instructions \"The person who made the request, given as a locally unique user.\" \\\n" \
        "        > \\\n" \
        "      :element -name RequestDateTime -type date -min-occurs 1 -max-occurs 1 -label \"Request Date-Time\" \\\n" \
        "        < \\\n" \
        "          :description \"The date and time the request was made\" \\\n" \
        "          :instructions \"The date and time the request was made, following ISO 8601 standards for timestamps.\" \\\n" \
        "        > \\\n" \
        "      :element -name ApprovedBy -type string -min-occurs 0 -max-occurs 1 -label \"Approved By\" \\\n" \
        "        < \\\n" \
        "          :description \"The person who approved the request\" \\\n" \
        "          :instructions \"The person who approved the request, given as a locally unique user.\" \\\n" \
        "        > \\\n" \
        "      :element -name ApprovalDateTime -type date -min-occurs 0 -max-occurs 1 -label \"Approval Date-Time\" \\\n" \
        "        < \\\n" \
        "          :description \"The date and time the request was approved\" \\\n" \
        "          :instructions \"The date and time the request was approved, following ISO 8601 standards for timestamps\" \\\n" \
        "        > \\\n" \
        "      :element -name DeniedBy -type string -min-occurs 0 -max-occurs 1 -label \"Denied  By\" \\\n" \
        "        < \\\n" \
        "          :description \"The person who denied the request\" \\\n" \
        "          :instructions \"The person who denied the request, given as a locally unique user.\" \\\n" \
        "        > \\\n" \
        "      :element -name DenialDateTime -type date -min-occurs 0 -max-occurs 1 -label \"Denial Date-Time\" \\\n" \
        "        < \\\n" \
        "          :description \"The date and time the request was denied\" \\\n" \
        "          :instructions \"The date and time the request was denied, following ISO 8601 standards for timestamps\" \\\n" \
        "        > \\\n" \
        "      :element -name EventlNote -type document -min-occurs 0 -label \"Event Note(s)\" \\\n" \
        "        < \\\n" \
        "          :description \"A supplementary record for a provenance event\" \\\n" \
        "          :instructions \"A supplementary record of noteworthy details for a given provenance event (e.g., quota decisions, storage tier assignments, revisions to submitted metadata, explanations of extenuating circumstances, etc.)\" \\\n" \
        "          :element -name NoteBy -type string -min-occurs 1 -max-occurs 1 -label \"Note By\" \\\n" \
        "            < \\\n" \
        "              :description \"The person making the note.\" \\\n" \
        "            > \\\n" \
        "          :element -name NoteDateTime -type date -min-occurs 1 -max-occurs 1 -label \"Note Date-Time\" \\\n" \
        "            < \\\n" \
        "              :description \"The date and time the note was made\" \\\n" \
        "            > \\\n" \
        "          :element -name EventType -type string -min-occurs 1 -max-occurs 1 -label \"Event Type\" \\\n" \
        "            < \\\n" \
        "              :description \"A general category label for the event note\" \\\n" \
        "            > \\\n" \
        "          :element -name Message -type string -min-occurs 1 -max-occurs 1 -label \"Message\" \\\n" \
        "            < \\\n" \
        "              :description \"The plain-language message contents of the event note.\" \\\n" \
        "            > \\\n" \
        "        > \\\n" \
        "    > \\\n" \
        "  :element -name SchemaVersion -type string -min-occurs 1 -max-occurs 1 -label \"Schema Version\" \\\n" \
        "    < \\\n" \
        "      :description \"The version of the TigerData Standard Metadata Schema used\" \\\n" \
        "      :instructions \"The version of the TigerData Standard Metadata Schema used for this project or subproject record. Ordinarily, the version is recorded at the time of the (sub)project creation. Values are expected to follow the numerical semantic versioning convention.\" \\\n"\
        "    > \\\n" \
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
