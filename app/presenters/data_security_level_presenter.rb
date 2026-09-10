# frozen_string_literal: true
# Presents a human-readable label for a project data security level.
class DataSecurityLevelPresenter
  # Maps integer security levels to their display labels.
  #
  # @return [Hash<Integer, String>] the data security level names
  LEVELS = {
    0 => "Level 0 - Public",
    1 => "Level 1 - Internal",
    2 => "Level 2 - Confidential",
    3 => "Level 3 - Restricted"
  }.freeze

  # Initializes the presenter with a raw security level value.
  #
  # @param level [Integer, String, NilClass] the stored data security level
  def initialize(level)
    @level = level
  end

  # Returns the display label for the configured data security level.
  #
  # @return [String] the user-facing label, or "——" when the level is unknown
  def to_s
    LEVELS.fetch(@level, "——")
  end

  # Alias for the display label.
  #
  # @return [String] the same value returned by {#to_s}
  alias level_name to_s
end
