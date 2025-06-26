# frozen_string_literal: true
require "rails_helper"

describe ProjectsController, type: :routing do
  describe "routing" do
    it "routes to #new_project" do
      expect(get: "/projects/new").to route_to(controller: "projects", action: "new")
    end

    it "routes to #project" do
      expect(get: "/projects/1").to route_to(controller: "projects", action: "show", id: "1")
    end

    it "routes to #edit_project" do
      expect(get: "/projects/1/edit").to route_to(controller: "projects", action: "edit", id: "1")
    end

    it "routes to #projects" do
      expect(get: "/projects").to route_to(controller: "projects", action: "index")
    end

    it "routes to #project_show_mediaflux" do
      expect(get: "/projects/1/1-mf").to route_to(controller: "projects", action: "show_mediaflux", id: "1")
      expect(get: "/projects/1/1-mf.xml").to route_to(controller: "projects", action: "show_mediaflux", id: "1", format: "xml")
    end
  end
end
