# frozen_string_literal: true
class UsersController < ApplicationController
    before_action :set_breadcrumbs
  
    # GET /requests
    def index
      @users = User.order('family_name ASC NULLS LAST')
      add_breadcrumb("Current Users")
    end
  
    private
  
      def set_breadcrumbs
        add_breadcrumb("Dashboard", dashboard_path)
      end
  end
  