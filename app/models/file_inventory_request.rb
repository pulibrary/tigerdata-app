# frozen_string_literal: true
class FileInventoryRequest < UserRequest
  def output_file
    request_details["output_file"]
  end
end
