# frozen_string_literal: true
class FileInventoryRequest < UserRequest

    def output_file
        return request_details["output_file"]
    end

end
