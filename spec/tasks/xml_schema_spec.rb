require "rails_helper"

#Rails.application.load_tasks

describe "xml_schema.rake" do
    it "validates XML examples against the TigerData metadata schema" do
        schema_file = "./lib/assets/tigerdata_metadata/v0.8/TigerData_StandardMetadataSchema_v0.8.xsd"
        document_file = "./lib/assets/tigerdata_metadata/v0.8/TigerData_MetadataExample-Project-Request_v0.8.xml"
        stdout = StringIO.new
        $stdout = stdout
        Rake::Task["xml_schema:validate_example"].invoke(schema_file,document_file)
        $stdout = STDOUT
        output = stdout.string
        Rake.application["xml_schema:validate_example"].reenable
        expect(output).to include("OK!")
    end
end