# frozen_string_literal: true
module PdcDescribe
  class LoadProjectConfig < Rails::Application
    config.project_defaults = config_for(:project)
  end
end
