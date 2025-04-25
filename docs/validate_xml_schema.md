# Validate the TigerData XML Schema

To validate the TigerData XML Schema, use the `xml_schema:validate_example` rake task. The rake task requires two arguments; the XSD document of the schema, and the XML document to be validated against it.

TigerData metadata XML schemas and examples are stored in version-numbered folders in `lib/assets/tigerdata_metadata` in this repository, which are copied from [the tigerdata_metadata_schema repository](https://github.com/pulibrary/tigerdata_metadata_schema/).

## Instructions

1. Set environment variables for the XSD schema and example document that you are going to work with. Example:
   ```bash
   export SCHEMA_FILE_8=lib/assets/tigerdata_metadata/v0.8/TigerData_StandardMetadataSchema_v0.8.xsd
   export DOCUMENT_FILE=lib/assets/tigerdata_metadata/v0.8/TigerData_MetadataExample-Item_v0.8.xml
   ```
1. Run the rake task with your arguments as follows:
   ```bash
   bundle exec rake xml_schema:validate_example\[$SCHEMA_FILE,$DOCUMENT_FILE]
   ```
1. If there are errors, you should see them outputted to the terminal. Otherwise, if the XML document validates, you should see output something like the following:
   ```bash
   OK! - XML example lib/assets/tigerdata_metadata/v0.8/TigerData_MetadataExample-Project-Request_v0.8.xml validates against schema lib/assets/tigerdata_metadata/v0.8/TigerData_StandardMetadataSchema_v0.8.xsd
   ```
