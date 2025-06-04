class RequestDepartmentJsonb < ActiveRecord::Migration[7.0]
  def up
    Request.all.each do |request|
      dep_str = request.departments&.strip
      if !dep_str.blank?
        request.departments = dep_str.split(",").map do |dep|
                                code, name = dep.split(" ")
                                code = code.strip.gsub("(","").gsub(")","")
                                { code: code, name: name }
                              end.to_json
        request.save
      end
    end
    change_column :requests, :departments, "jsonb USING departments::jsonb"
  end

  def down
    change_column :requests, :departments, :string

    Request.all.each do |request|
      dep_json = request.departments
      if dep_json.present?
        request.departments = JSON.parse(dep_json).map{|dep| "(#{dep["code"]}) #{dep["name"]}"}.join(",")
        request.save
      end
    end
  end
end
