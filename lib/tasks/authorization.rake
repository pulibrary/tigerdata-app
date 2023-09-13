# frozen_string_literal: true
require "net/http/persistent"

# frozen_string_literal: true
namespace :authorization do
  desc "Timing test for logon in via a newly created token"
  task by_new_token: :environment do
    main_logon = Mediaflux::Http::LogonRequest.new
    main_logon.resolve
    time_action("1 New Token") do
      create = Mediaflux::Http::CreateTokenRequest.new(domain: "princeton.edu", user: "test", session_token: main_logon.session_token)
      identity_token = create.identity
      logon = Mediaflux::Http::LogonRequest.new(identity_token: identity_token)
      logon.resolve
      Mediaflux::Http::LogoutRequest.new(session_token: logon.session_token)
    end

    time_action("1000 New Tokens") do
      1000.times do
        create = Mediaflux::Http::CreateTokenRequest.new(domain: "princeton.edu", user: "test", session_token: main_logon.session_token)
        identity_token = create.identity
        logon = Mediaflux::Http::LogonRequest.new(identity_token: identity_token)
        logon.resolve
        Mediaflux::Http::LogoutRequest.new(session_token: logon.session_token)
      end
    end
  end

  desc "Timing test for logon in via an exiting created token"
  task by_existing_token:  :environment do
    logon = Mediaflux::Http::LogonRequest.new
    logon.resolve
    create = Mediaflux::Http::CreateTokenRequest.new(domain: "princeton.edu", user: "test", session_token: logon.session_token)
    identity_token = create.identity
    time_action("1 Existing Token") do
      logon = Mediaflux::Http::LogonRequest.new(identity_token: identity_token)
      logon.resolve
      Mediaflux::Http::LogoutRequest.new(session_token: logon.session_token)
    end

    time_action("1000 Existing Tokens") do
      1000.times do
        logon = Mediaflux::Http::LogonRequest.new(identity_token: identity_token)
        logon.resolve
        Mediaflux::Http::LogoutRequest.new(session_token: logon.session_token)
      end
    end
  end

  desc "Timing test for logon in via a user session"
  task by_session:  :environment do
    time_action("1 Sesssion") do
      logon = Mediaflux::Http::LogonRequest.new(domain: "princeton.edu", user: "test", password: "change_me")
      logon.resolve
      Mediaflux::Http::LogoutRequest.new(session_token: logon.session_token)
    end

    time_action("1000 Sesssions") do
      1000.times do
        logon = Mediaflux::Http::LogonRequest.new(domain: "princeton.edu", user: "test", password: "change_me")
        logon.resolve
        Mediaflux::Http::LogoutRequest.new(session_token: logon.session_token)
      end
    end
  end

  desc "Timing test for logon via just http"
  task by_http: :environment do
    uri = URI "http://#{Mediaflux::Http::Request.mediaflux_host}:#{Mediaflux::Http::Request.mediaflux_port}/#{Mediaflux::Http::Request.request_path}"
    http = Net::HTTP::Persistent.new # 'my_app_name'
    time_action("1000 Sesssions") do
      1000.times do
        request = Net::HTTP::Post.new(Mediaflux::Http::Request.request_path)
        body = Nokogiri::XML::Builder.new do |xml|
          xml.request do
            xml.service(name: "system.logon") do
              xml.args do
                xml.domain "system"
                xml.user "manager"
                xml.password "change_me"
              end
            end
          end
        end
        request["Content-Type"] = "text/xml; charset=utf-8"
        request.body = body.to_xml
        resp = http.request uri, request
        resp.body
      end
      http.shutdown
    end
  end

  desc "Timing test for executing a service with a token"
  task service_with_token:  :environment do
    logon = Mediaflux::Http::LogonRequest.new(domain: "princeton.edu", user: "test", password: "change_me")
    logon.resolve
    create = Mediaflux::Http::CreateTokenRequest.new(domain: "princeton.edu", user: "test", session_token: logon.session_token)
    identity_token = create.identity
    time_action("1 list namespaces with token") do
      sexec = Mediaflux::Http::ServiceExecuteRequest.new(session_token: logon.session_token, service_name: "asset.namespace.list", token: identity_token)
      sexec.resolve
      puts sexec.response_xml
    end

    time_action("1000 list namespaces with token") do
      1000.times do
        sexec = Mediaflux::Http::ServiceExecuteRequest.new(session_token: logon.session_token, service_name: "asset.namespace.list", token: identity_token)
        sexec.resolve
      end
    end
  end

  desc "Timing test for executing a service without a token"
  task service_without_token: :environment do
    logon = Mediaflux::Http::LogonRequest.new(domain: "princeton.edu", user: "test", password: "change_me")
    logon.resolve
    time_action("1 list namespaces") do
      sexec = Mediaflux::Http::ServiceExecuteRequest.new(session_token: logon.session_token, service_name: "asset.namespace.list")
      sexec.resolve
      puts sexec.response_xml
    end

    time_action("1000 list namespaces") do
      1000.times do
        sexec = Mediaflux::Http::ServiceExecuteRequest.new(session_token: logon.session_token, service_name: "asset.namespace.list")
        sexec.resolve
      end
    end
  end

  def time_action(label)
    start_time = DateTime.now
    yield
    end_time = DateTime.now
    sec = end_time.to_f - start_time.to_f
    puts "#{label} #{sec * 1000} mili seconds #{sec} seconds"
  end
end
