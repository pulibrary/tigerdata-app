# frozen_string_literal: true
class MediafluxWrapper
  # All calls to Mediaflux should be made through this class.
  # TODO: Figure out authentication and authorization.
  # TODO: Figure out what data Mediaflux and Postgres are responsible for.
  # (Projects may eventually be handled by Postgres, but I need something for the example.)
  def projects
    [{ name: "fake project" }]
  end
end
