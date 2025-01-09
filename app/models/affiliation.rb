# frozen_string_literal: true
class Affiliation < ApplicationRecord
  # Affiliation file is loaded onto the servers via pransible into the shared folder
  def self.load_from_file(file)
    affiliations = CSV.read(file, headers: true, skip_lines: /^JT_CF.*/)
    affiliations.each do |data|
      code = data["Dept"]
      if Affiliation.where(code: ).count == 0
        self.create(code: code, name: data["Department Descr"])
      end
    end  
  end
end
