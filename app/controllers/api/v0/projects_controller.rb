# frozen_string_literal: true
module Api
    module V0
        class ProjectsController < ApplicationController
            def index
                render json: ApiMiddleware.new().projects.to_json
            end
        end
    end
end
  