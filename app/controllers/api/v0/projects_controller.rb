# frozen_string_literal: true
module Api
  module V0
    class ProjectsController < ApplicationController
      def index
        projects = MediafluxWrapper.new.projects
        render json: projects.to_json
      end
    end
  end
end
