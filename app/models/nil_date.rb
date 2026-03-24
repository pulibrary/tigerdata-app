# frozen_string_literal: true

# Represents a nil date that returns "NA" for strftime.
class NilDate
  # Formats the nil date.
  # @param _arg [String] the format string, ignored.
  # @return [String] "NA"
  def strftime(_arg)
    "NA"
  end
end
