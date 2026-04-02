# frozen_string_literal: true
module PdcDescribe
  class LoadProjectConfig < Rails::Application
    config.project_defaults = config_for(:project)
    config.project_file_display_limit = config.project_defaults[:file_display_limit].to_i
  end
end
