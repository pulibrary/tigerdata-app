# frozen_string_literal: true
class Affiliation
  def self.all
    data = []
    data << { code: "23100", name: "Astrophysical Sciences" }
    data << { code: "HPC", name: "High Performance Computing" }
    data << { code: "RDSS", name: "Research Data and Scholarship Services" }
    data << { code: "PRDS", name: "Princeton Research Data Service" }
    data << { code: "PPPL", name: "Princeton Plasma Physics Laboratory" }
    data
  end
end
