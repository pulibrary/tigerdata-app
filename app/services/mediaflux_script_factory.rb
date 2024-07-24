# frozen_string_literal: true

class MediafluxScriptFactory
  def initialize(project:)
    @project = project
    @metadata = project.metadata_model

    root_ns = Rails.configuration.mediaflux["api_root_collection_namespace"]
    parent_collection = Rails.configuration.mediaflux["api_root_collection_name"]
    @root_info = Mediaflux::RootCollectionAsset.new(session_token: nil, root_ns: root_ns, parent_collection: parent_collection)
  end

  def aterm_script
    prolog = "# Run these steps from Aterm to create a project in Mediaflux with its related components"
    [prolog, script_root_tree_create, script_asset_create, script_accumulators].join("\r\n\r\n")
  end

  def project_namespace
    Pathname.new(@root_info.parent_ns).join(@project.project_directory_short + "NS")
  end

  def project_parent_path
    Pathname.new(@root_info.path)
  end

  def project_path
    Pathname.new(project_parent_path).join(@project.project_directory_short)
  end

  private

    def created_on
      Mediaflux::Time.format_date_for_mediaflux(@metadata.created_on)
    end

    def department_fields
      @metadata.departments.map { |department| ":Department \"#{department}\"" }
    end

    def data_users
      users = @metadata.ro_users.map { |user| ":DataUser \"#{user}\"" }
      users += @metadata.rw_users.map { |user| ":DataUser \"#{user}\" -ReadOnly true" }
      users
    end

    # rubocop:disable Metrics/AbcSize
    def script_asset_create
      <<-ATERM
      # Create the namespace for the project
      asset.namespace.create :namespace #{project_namespace}

      # Create the collection asset for the project
      asset.create
        :pid path=#{project_parent_path}
        :namespace #{project_namespace}
        :name #{@project.project_directory_short}
        :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true
        :type "application/arc-asset-collection"
        :meta <
          :tigerdata:project <
            :ProjectDirectory "#{@metadata.project_directory}"
            :Title "#{@metadata.title}"
            :Description "#{@metadata.description}"
            :Status "#{@metadata.status}"
            :DataSponsor "#{@metadata.data_sponsor}"
            :DataManager "#{@metadata.data_manager}"
            #{department_fields.join(' ')}
            #{data_users.join(' ')}
            :CreatedOn "#{created_on}"
            :CreatedBy "#{@metadata.created_by}"
            :ProjectID "#{@metadata.project_id}"
            :StorageCapacity < :Size #{@metadata.storage_capacity['size']['requested']} :Unit "#{@metadata.storage_capacity['unit']['requested']}" >
            :Performance "#{@metadata.storage_performance_expectations['requested']}"
            :ProjectPurpose "#{@metadata.project_purpose}"
            :Submission < :RequestedBy "#{@metadata.created_by}" :RequestDateTime "#{created_on}" >
            :SchemaVersion "#{@metadata.schema_version}"
          >
        >
        :quota <
          :allocation #{@metadata.storage_capacity['size']['requested']} #{@metadata.storage_capacity['unit']['requested']}
          :description "Project Quota"
        >
    ATERM
    end
    # rubocop:enable Metrics/AbcSize

    def script_root_tree_create
      # We should never attempt to create the root tree in production
      return "" if Rails.env.production?

      # Commands to create the root namespace and the two required nodes
      <<-ATERM
      # Create the root namespace (OPTIONAL)
      asset.namespace.create :namespace #{@root_info.root_ns}

      # Create the parent namespace (OPTIONAL)
      asset.namespace.create :namespace #{@root_info.parent_ns}

      # Create the parent collection (OPTIONAL)
      asset.create
        :namespace #{@root_info.root_ns}
        :name #{@root_info.parent_collection}
        :collection -unique-name-index true -contained-asset-index true -cascade-contained-asset-index true true
        :type "application/arc-asset-collection"
      ATERM
    end

    def script_accumulators
      <<-ATERM
    # Define accumulator for file count
    asset.collection.accumulator.add
      :id path=#{project_path}
      :cascade true
      :accumulator <
        :name #{@project.project_directory_short}-count
        :type collection.asset.count
      >

    # Define accumulator for total file size
    asset.collection.accumulator.add
      :id path=#{project_path}
      :cascade true
      :accumulator <
      :name #{@project.project_directory_short}-size
        :type content.all.size
      >
    ATERM
    end
end
