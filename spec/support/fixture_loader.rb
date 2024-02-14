# frozen_string_literal: true

def fixture_file(filename)
  full_path = Rails.root.join("spec", "fixtures", filename)
  File.new(full_path).read
end
