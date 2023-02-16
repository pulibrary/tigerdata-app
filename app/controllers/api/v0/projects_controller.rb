# frozen_string_literal: true
module Api
    module V0
        class ProjectsController < ApplicationController
            def index
                render json: ApiClient.new().projects.to_json
            end
        end
    end
end
  