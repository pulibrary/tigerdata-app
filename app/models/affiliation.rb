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

  def self.find_fuzzy_by_name(name)
    find_by(name: name) || Affiliation.where("name like '%#{name}%'").order(:code).first
  end
end
