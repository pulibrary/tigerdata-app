# frozen_string_literal: true
class RequestProjectMetadata
  class << self
    def convert(request)
      {
        title: request[:project_title],
        description: request[:description],
        status: Project::PENDING_STATUS,
        data_sponsor: request[:data_sponsor],
        data_manager: request[:data_manager],
        departments: departments(request),
        data_user_read_only: data_users(request),
        project_directory: project_directory(request),
        storage_capacity: storage_capacity(request),
        storage_performance_expectations: { requested: "Standard", approved: "Standard" },
        created_by: nil,
        created_on: request[:created_at],
        project_id: ProjectMetadata::DOI_NOT_MINTED
      }
    end

     private

       def project_directory(request)
         [Rails.configuration.mediaflux["api_root"], request[:parent_folder], request[:project_folder]].compact_blank.join("/")
       end

       def data_users(request)
         request[:user_roles].map { |u| u["uid"] }
       end

       def departments(request)
         request[:departments].map { |d| d["name"] }
       end

       def storage_capacity(request)
         {
           size: {
             approved: request.approved_quota_size.to_s,
             requested: request.requested_quota_size.to_s
           },
           unit: {
             approved: request.approved_quota_unit,
             requested: request.requested_quota_unit
           }
         }
       end
  end
end
