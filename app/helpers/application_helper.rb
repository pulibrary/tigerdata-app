# frozen_string_literal: true
module ApplicationHelper

    def project_type(project)
        project.metadata["storage_performance_expectations"]["approved"].nil? ? "Requested #{project.metadata["storage_performance_expectations"]["requested"]}" : project.metadata["storage_performance_expectations"]["approved"]
    end

    def latest_file_list_time(project)
        @my_inventory_requests.where(project_id:project.id).empty? ? "Never requested" : "Prepared #{time_ago_in_words(@my_inventory_requests.where(project_id:project.id).sort_by(&:completion_time).reverse.first.completion_time)} ago"
    end 

    def last_activity_on_project(project)
        project.metadata["updated_on"].nil? ? "Not yet active" : "#{time_ago_in_words(project.metadata["updated_on"])} ago"
    end 
end
