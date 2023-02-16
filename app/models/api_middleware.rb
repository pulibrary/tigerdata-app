# frozen_string_literal: true
class ApiMiddleware
  # The database and Mediaflux should only be accessed through this class.
  # Since the respective responsibilities of the the two systems have not
  # been determined, we want all references to both in just one place.
  #
  # As the middleware grows to support the needs of the UI,
  # we need to be sure to add corresponding API routes.
  def projects
    [{ name: "fake project" }]
  end
end
