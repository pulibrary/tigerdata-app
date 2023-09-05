# frozen_string_literal: true
namespace :servers do
  task initialize: :environment do
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
  end

  desc "Starts development dependencies"
  task start: :environment do
    system("lando start")
    system("rake servers:initialize")
    system("rake servers:initialize RAILS_ENV=test")
  end

  desc "Stop development dependencies"
  task stop: :environment do
    system "lando stop"
  end

  task schema: :environment do
    mf_session = User.where(uid:"hc8719").first.mediaflux_session

    schema_name = "td_schema_07"
    description = "TigerData Metadata"
    schema_request = Mediaflux::Http::SchemaCreateRequest.new(
      name: schema_name,
      description: description,
      session_token: mf_session
    )
    # puts schema_request

    fields = []
    fields << {name: "id", type: "string", index: true, "min-occurs" => 1, "max-occurs" => 1, label: "something"}
    fields << {name: "title", type: "string"}
    fields << {name: "description", type: "string"}
    fields_request = Mediaflux::Http::SchemaFieldsCreateRequest.new(
      schema_name: schema_name,
      document: "project",
      description: "Project Metadata",
      fields: fields,
      session_token: mf_session)
    puts fields_request
    # puts fields_request.send("http_request").body
  end
end
