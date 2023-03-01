# frozen_string_literal: true
class RolesController < ApplicationController
    def index
        @roles = Role.all
    end
  end
  