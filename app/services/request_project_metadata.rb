# frozen_string_literal: true
class RequestProjectMetadata
  class << self
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def convert(request)
      {
        title: request[:project_title],
        description: request[:description],
        project_purpose: request[:project_purpose],
        status: Project::APPROVED_STATUS,
        data_sponsor: request[:data_sponsor],
        data_manager: request[:data_manager],
        departments: departments(request),
        data_user_read_only: read_only_users(request),
        data_user_read_write: read_write_users(request).compact,
        project_directory: project_directory(request),
        storage_capacity: storage_capacity(request),
        storage_performance_expectations: { requested: "Standard", approved: "Standard" },
        created_by: nil,
        created_on: request[:created_at],
        project_id: ProjectMetadata::DOI_NOT_MINTED,
        number_of_files: request[:number_of_files],
        hpc: request[:hpc]&.downcase == "yes",
        smb: request[:smb]&.downcase == "yes",
        globus: request[:globus]&.downcase == "yes"
      }
    end
     # rubocop:enable Metrics/AbcSize
     # rubocop:enable Metrics/MethodLength

     private

       def project_directory(request)
         [Rails.configuration.mediaflux["api_root"], request[:parent_folder], request[:project_folder]].compact_blank.join("/")
       end

       def read_only_users(request)
         request[:user_roles].select { |u| u["read_only"] || u["read_only"].nil? }.map { |u| u["uid"] }
       end

       def read_write_users(request)
         request[:user_roles].select { |u| u["read_only"] == false }.map { |u| u["uid"] }
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
