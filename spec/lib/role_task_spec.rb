# frozen_string_literal: true
# in spec/tasks/notify_spec.rb
require "rails_helper"
Rails.application.load_tasks

describe "roles.rake" do
  after do
    Rake.application["roles:default_mediaflux_admins"].reenable
    Rake.application["roles:default_sponsors"].reenable
  end
  describe "default_mediaflux_admins" do
    it "updates a notifications" do
      expect { Rake::Task["roles:default_mediaflux_admins"].invoke }.to change { User.count }.by(1)
      expect(User.last).to have_role(User::MEDIAFLUX_ADMIN)
    end
  end

  describe "default_sponsors" do
    it "updates a notifications" do
      expect { Rake::Task["roles:default_sponsors"].invoke }.to change { User.count }.by(1)
      expect(User.last).to have_role(User::PROJECT_SPONSOR)
    end
  end

  it "should add roles to user when multiple rake tasks are run" do
    expect { Rake::Task["roles:default_sponsors"].invoke }.to change { User.count }.by(1)
    expect { Rake::Task["roles:default_mediaflux_admins"].invoke }.to change { User.count }.by(0)
    expect(User.last).to have_role(User::PROJECT_SPONSOR)
    expect(User.last).to have_role(User::MEDIAFLUX_ADMIN)
  end
end
