# frozen_string_literal: true
module Api
  module V0
    class ProjectsController < ApplicationController
      def index
        # :nocov:
        projects = MediafluxWrapper.new.projects
        render json: projects.to_json
        # :nocov:
      end
    end
  end
end
