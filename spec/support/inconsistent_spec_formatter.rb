# frozen_string_literal: true

class InconsistentSpecFormatter
  def initialize(output)
    @output = output
    log_file_path = Rails.root.join("tmp", "inconsistent_specs.log")
    @log_file = File.open(log_file_path, "w")
  end

  def example_failed(notification)
    if notification.example.metadata[:inconsistent]
      message = "Inconsistent spec failed: #{notification.example.full_description}"
      @output.puts(message)
      @log_file.puts(message)
    end
  end

  delegate :close, to: :@log_file
end
