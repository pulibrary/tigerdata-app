# frozen_string_literal: true
class UserReadWritePresenter < UserPresenter
  def access_type
    "Data User - Read Write"
  end
end
