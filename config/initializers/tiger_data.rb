# frozen_string_literal: true

tiger_data_lib_pattern = Rails.root.join("lib", "tiger_data", "**", "*.rb")
tiger_data_lib_paths = Dir[tiger_data_lib_pattern]
tiger_data_lib_paths.each { |file| require file }
