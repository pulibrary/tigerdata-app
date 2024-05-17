# frozen_string_literal: true
#
# Disable these Rubocop warnings since generating an Aterm script is a prototype.
# If we decide to pursue this idea forward we can refactor the code.
#
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
class ProjectAterm
  # Produces an Aterm script to create a project in Mediaflux
  def self.create_script(project)
    root_collection_namespace = Rails.configuration.mediaflux["api_root_collection_namespace"]
    root_namespace = Rails.configuration.mediaflux["api_root_ns"]
    root_collection_name = Rails.configuration.mediaflux["api_root_collection_name"]
    project_directory = project.project_directory_short
    project_directory_full = project.project_directory_full
    project_parent = project.project_directory_parent_path
    project_namespace_full = "#{root_namespace}/#{project.project_directory}NS"
    department_fields = project.metadata_json["departments"].map { |department| ":Department \"#{department}\"" }
    created_on = ProjectMediaflux.format_date_for_mediaflux(project.metadata_json["created_on"])
    requested_by = project.metadata.dig("submission", "requested_by") || ""
    requested_date = ProjectMediaflux.format_date_for_mediaflux(project.metadata.dig("submission", "request_date_time"))

    script = <<-ATERM
      # Run these steps from Aterm to create a project in Mediaflux with its related components

      # --- These statements are only needed on an EMPTY MEDIAFLUX ---
      # Create root namespace, the tigerdata root namespace, and the tigerdata root collection under the root namespace
      # asset.namespace.create :namespace #{root_collection_namespace}
      # asset.namespace.create :namespace #{root_namespace}
      # asset.create :name #{root_collection_name} :namespace #{root_collection_namespace} :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true
      # ---------------------------------------------------------------

      # Create the namespace for the project under the tigerdata root namespace
      asset.namespace.create :namespace #{project_namespace_full}

      # Create the collection asset for the project
      asset.create
        :pid path=#{project_parent}
        :namespace #{project_namespace_full}
        :name #{project_directory}
        :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true
        :type "application/arc-asset-collection"
        :meta <
          :tigerdata:project <
            :ProjectDirectory "#{project_directory}"
            :Title "#{project.metadata_json['title']}"
            :Description "#{project.metadata_json['description']}"
            :Status "#{project.metadata_json['status']}"
            :DataSponsor "#{project.metadata_json['data_sponsor']}"
            :DataManager "#{project.metadata_json['data_manager']}"
            #{department_fields.join(' ')}
            :CreatedOn "#{created_on}"
            :CreatedBy "#{project.metadata_json['created_by']}"
            :ProjectID "#{project.metadata_json['project_id']}"
            :StorageCapacity < :Size "#{project.metadata_json['storage_capacity']['size']['requested']}" :Unit "#{project.metadata_json['storage_capacity']['unit']['requested']}" >
            :ProjectPurpose "#{project.metadata_json['project_purpose']}"
            :Performance "#{project.metadata_json['storage_performance_expectations']['requested']}"
            :Submission < :RequestedBy "#{requested_by}" :RequestDateTime "#{requested_date}" >
            :SchemaVersion "#{project.metadata['schema_version']}"
          >
        >

    # Define accumulator for file count
    asset.collection.accumulator.add
      :id path=#{project_directory_full}
      :cascade true
      :accumulator <
        :name #{project_directory}-count
        :type collection.asset.count
      >

    # Define accumulator for total file size
    asset.collection.accumulator.add
      :id path=#{project_directory_full}
      :cascade true
      :accumulator <
      :name #{project_directory}-size
        :type content.all.size
      >

    # Define storage quota
    asset.collection.quota.set
      :id path=#{project_directory_full}
      :quota < :allocation 500 GB :on-overflow fail :description "500 GB quota for #{project_directory}>"

    ATERM

    script
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
