# frozen_string_literal: true
class Affiliation
  def self.all
    data = []
    data << { code: "HPC", name: "High Performance Computing" }
    data << { code: "RDSS", name: "Research Data and Scholarly Services" }
    data << { code: "PRDS", name: "Princeton Research Data Service" }
    data << { code: "PPPL", name: "Princeton Plasma Physics Laboratory" }
    data
  end
end
