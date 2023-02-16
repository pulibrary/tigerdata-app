class ApiMiddleware
    # The database and Mediaflux should only be accessed through this class.
    # Since our backend is in flux, and we're not sure what will be handled
    # by the database and what by mediaflux, we do not want references to
    # either scattered across the codebase.
    #
    # In turn, this class should only be referenced by api routes.
    # All the UI pages will depend on the API. Limiting ourselves to the
    # API will ensure that the API can do everything the UI can do.
    def projects
        [{name: "fake project"}]
    end
end
