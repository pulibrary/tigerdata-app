# frozen_string_literal: true

namespace :dev_license do
  desc "output the license expiration and create a warning if it is getting close to expiration"
  task expiration_check: :environment do
    mfcommand = "java -Dmf.host=localhost -Dmf.transport=http -Dmf.domain=system -Dmf.user=manager -Dmf.password=change_me -Dmf.port=80 " \
                "-jar /opt/mediaflux/bin/aterm.jar --app exec licence.describe |grep expiry"
    output = `docker exec mediaflux  bin/bash -c '#{mfcommand}'`
    if output.include?("expiry")
      _, date_str = output.split(" ").map(&:strip)
      expiration_date = Time.zone.parse(date_str)
      if expiration_date < Time.zone.now
        raise "Mediaflux Development license is expired"
      else
        File.open("mediaflux-dev-license-expiration.txt", "w") { |f| f.write expiration_date }
        `git add mediaflux-dev-license-expiration.txt`
        puts "License Expiration file added.  License expires on #{expiration_date}"
      end
    else
      raise "!!! Mediaflux is not running !!! No expiration information can be gathered"
    end
  end
end
