# frozen_string_literal: true

class MediafluxScriptFactory
  def project
    @project ||= Project.find(@project_id)
  end
  delegate :project_directory, to: :project
  def project_parent
    project.project_directory_parent_path
  end
  alias path_id project_parent
  delegate :metadata, to: :project

  def project_namespace
    @project_namespace ||= "#{project_directory}NS"
  end

  def departments
    metadata["departments"]
  end

  def department_fields
    departments.map { |department| ":Department \"#{department}\"" }
  end

  def created_on_metadata
    project.metadata_json["created_on"]
  end

  def created_on_time
    Time.zone.parse(created_on_metadata)
  end

  def created_on_formatted
    created_on_time.strftime("%e-%b-%Y %H:%M:%S")
  end

  def created_on
    created_on_formatted.upcase
  end

  def requested_by
    project.metadata_model.created_by
  end

  def request_date_time
    project.metadata_model.created_on
  end

  def requested_date
    Mediaflux::Time.format_date_for_mediaflux(request_date_time)
  end

  # rubocop:disable Metrics/AbcSize
  def build_create_script
    <<-ATERM
      # Run these steps from Aterm to create a project in Mediaflux with its related components

      # Create the namespace for the project
      asset.namespace.create :namespace #{project_namespace}

      # Create the collection asset for the project
      asset.create
        :pid path=#{project_parent}
        :namespace #{project_namespace}
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
            :StorageCapacity < :Size "#{project.metadata_json['storage_capacity']['size']['requested']}>" :Unit #{project.metadata_json['storage_capacity']['unit']['requested']}"
            :StoragePerformance "#{project.metadata_json['storage_performance_expectations']['requested']}"
            :ProjectPurpose "#{project.metadata_json['project_purpose']}"
            :Submission < :RequestedBy "#{requested_by}" :RequestDateTime "#{requested_date}" >
            :SchemaVersion "#{project.metadata['schema_version']}"
          >
        >

    # Define accumulator for file count
    asset.collection.accumulator.add
      :id path=#{path_id}
      :cascade true
      :accumulator <
        :name #{project_directory}-count
        :type collection.asset.count
      >

    # Define accumulator for total file size
    asset.collection.accumulator.add
      :id path=#{path_id}
      :cascade true
      :accumulator <
      :name #{project_directory}-size
        :type content.all.size
      >

    # Define storage quota
    asset.collection.quota.set
      :id path=#{path_id}
      :quota < :allocation 500 GB :on-overflow fail :description "500 GB quota for #{project_directory}>"
    ATERM
  end
  # rubocop:enable Metrics/AbcSize

  def initialize(project_id)
    @project_id = project_id
  end
end
