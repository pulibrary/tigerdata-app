# frozen_string_literal: true
# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!
require "axe-rspec"
require "capybara/rspec"
require "devise"
require "webmock/rspec"
WebMock.disable_net_connect!(allow_localhost: true,
                             allow: ["chromedriver.storage.googleapis.com", "0.0.0.0", "mflux-ci.lib.princeton.edu", "mflux-staging.lib.princeton.edu"])
# WebMock.enable_net_connect!
Dir[Rails.root.join("spec", "support", "**", "*.rb")].sort.each { |file| require file }

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# Disable animations in system tests.
# This should make them faster and more reliable.
Capybara.disable_animation = true

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system

  config.before(:each, type: :system) do
    ActiveJob::Base.queue_adapter = :test
    if ENV["RUN_IN_BROWSER"]
      driven_by(:selenium)
    else
      driven_by(:selenium_headless)
    end
  end
end

# Mimics Capybara `fill_in` but issues a "tab" keystroke at the end
# so that validations on the textbox (if any) kick-in.
def fill_in_and_out(element_id, with:)
  fill_in element_id, with: with
  # Tab out of the textbox (https://www.grepper.com/answers/723997/focusout+event+in+capybara)
  find("#" + element_id).native.send_keys :tab
end

# Generates a random project directory so that each test goes to its own location in Mediaflux
def random_project_directory
  "#{Time.now.utc.iso8601.gsub(':','-')}-#{rand(1..100000)}"
end

# Generates a random project id in the form 10.nnn/nnn
def random_project_id
  "10.#{rand(1..100000)}/#{rand(1..100000)}"
end