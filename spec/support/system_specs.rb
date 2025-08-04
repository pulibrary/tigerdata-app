# frozen_string_literal: true
Capybara.configure do |config|
  config.default_driver = :chrome_headless
end

Capybara.register_driver :chrome_headless do |app|
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = 120
  options = Selenium::WebDriver::Chrome::Options.new(args: %w[disable-gpu no-sandbox headless whitelisted-ips window-size=1400,1400])
  options.add_argument(
    "--enable-features=NetworkService,NetworkServiceInProcess"
  )
  options.add_argument("--profile-directory=Default")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, http_client: client)
end

Capybara.javascript_driver = :chrome_headless

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by(:rack_test)
  end

  config.before(:each, type: :system, js: true) do
    if ENV["RUN_IN_BROWSER"]
      driven_by(:selenium)
    else
      driven_by(:chrome_headless)
    end
  end
  config.before(:each, type: :system, js: true, in_browser: true) do
    driven_by(:selenium)
  end
end
