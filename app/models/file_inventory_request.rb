# frozen_string_literal: true

# Represents a file inventory request, inheriting from InventoryRequest.
class FileInventoryRequest < InventoryRequest
  # Gets the output file path.
  # @return [String] the output file.
  def output_file
    request_details["output_file"]
  end

  # Calculates the expiration date.
  # @return [ActiveSupport::TimeWithZone] expiration date 7 days after completion.
  def expiration_date
    completion_time + 7.days
  end
end
