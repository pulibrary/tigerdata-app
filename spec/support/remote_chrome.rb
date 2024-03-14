# frozen_string_literal: true

require "capybara/rspec"
require "selenium-webdriver"

# Add options for the Chrome browser
options = Selenium::WebDriver::Chrome::Options.new

# Disable notifications
options.add_argument("--disable-notifications")
options.add_argument("--headless")
options.add_argument("--disable-gpu")
options.add_argument("--test-type")
options.add_argument("--ignore-certificate-errors")
options.add_argument("--disable-popup-blocking")
options.add_argument("--disable-extensions")
options.add_argument("--enable-automation")
options.add_argument("--window-size=1920,1080")
options.add_argument("--start-maximized")

Capybara.register_driver :headless_selenium_chrome_in_container do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :remote,
    url: "http://192.168.10.60:4444/wd/hub",
    options: options
  )
end

# Capybara.register_driver :selenium_chrome_in_container do |app|
#   Capybara::Selenium::Driver.new(app,
#     browser: :remote,
#     url: "http://192.168.10.60:4444/wd/hub",
#     desired_capabilities: :chrome)
# end
