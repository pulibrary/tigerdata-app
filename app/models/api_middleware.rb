# frozen_string_literal: true
class ApiMiddleware
  # The database and Mediaflux should only be accessed through this class.
  # Since our backend is in flux, and we're not sure what will be handled
  # by the database and what by mediaflux, we do not want references to
  # either scattered across the codebase.
  #
  # As the middleware grows to support the needs of the frontend,
  # we need to be sure to add corresponding API routes.
  def projects
    [{ name: "fake project" }]
  end
end
