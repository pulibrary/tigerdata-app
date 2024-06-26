# frozen_string_literal: true
class ProjectAccumulator
  def initialize(project:, session_id:)
    @collection_id = project.mediaflux_id
    @session_id = session_id
  end

  # Create accumulators for all newly created mediaflux projects
  #
  def create!
    accum_names = validate
    return true if accum_names == true

    # Create accumulators if they do not exist
    if accum_names.exclude?("accum-count")
      create_accum_count(collection_id: @collection_id, session_id: @session_id)
    end
    if accum_names.exclude?("accum-size")
      create_accum_size(collection_id: @collection_id, session_id: @session_id)
    end
    if accum_names.exclude?("accum-store-size")
      create_accum_store_size(collection_id: @collection_id, session_id: @session_id)
    end
  end

  # Validate that a project has the expected accumulators
  #
  def validate
    collection_metadata = Mediaflux::Http::AssetMetadataRequest.new(session_token: @session_id, id: @collection_id).metadata
    accum_names = collection_metadata[:accum_names].to_a.map(&:to_s)
    accum_names.size == 3 ? true : accum_names
  end

  private

    def create_accum_count(collection_id:, session_id:)
      accum_count = Mediaflux::Http::AccumulatorCreateCollectionRequest.new(
          session_token: session_id,
          name: "accum-count",
          collection: collection_id,
          type: "collection.asset.count"
        )
      accum_count.resolve
    end

    def create_accum_size(collection_id:, session_id:)
      accum_size = Mediaflux::Http::AccumulatorCreateCollectionRequest.new(
          session_token: session_id,
          name: "accum-size",
          collection: collection_id,
          type: "content.all.size"
        )
      accum_size.resolve
    end

    def create_accum_store_size(collection_id:, session_id:)
      accum_store_size = Mediaflux::Http::AccumulatorCreateCollectionRequest.new(
          session_token: session_id,
          name: "accum-store-size",
          collection: collection_id,
          type: "content.all.store.size"
        )
      accum_store_size.resolve
    end
end
