# frozen_string_literal: true
class ProjectAccumulator
  def create!(mediaflux_project_id:, session_id:)
    accum_names = validate(mediaflux_project_id: mediaflux_project_id, session_id: session_id)
    return true if accum_names == true

    # Create accumulators if they do not exist
    if accum_names.exclude?("accum-count")
      create_accum_count(mediaflux_project_id:, session_id:)
    end
    if accum_names.exclude?("accum-size")
      create_accum_size(mediaflux_project_id:, session_id:)
    end
    if accum_names.exclude?("accum-store-size")
      create_accum_store_size(mediaflux_project_id:, session_id:)
    end
  end

  def validate(mediaflux_project_id:, session_id:)
    collection_metadata = Mediaflux::Http::AssetMetadataRequest.new(session_token: session_id, id: mediaflux_project_id).metadata
    accum_names = collection_metadata[:accum_names].to_a.map(&:to_s)
    (accum_names.length == 3) ? true : accum_names
  end

  private

    def create_accum_count(mediaflux_project_id:, session_id:)
      accum_count = Mediaflux::Http::AccumulatorCreateCollectionRequest.new(
          session_token: session_id,
          name: "accum-count",
          collection: mediaflux_project_id,
          type: "collection.asset.count"
        )
      accum_count.resolve
    end

    def create_accum_size(mediaflux_project_id:, session_id:)
      accum_size = Mediaflux::Http::AccumulatorCreateCollectionRequest.new(
          session_token: session_id,
          name: "accum-size",
          collection: mediaflux_project_id,
          type: "content.all.size"
        )
      accum_size.resolve
    end

    def create_accum_store_size(mediaflux_project_id:, session_id:)
      accum_store_size = Mediaflux::Http::AccumulatorCreateCollectionRequest.new(
          session_token: session_id,
          name: "accum-store-size",
          collection: mediaflux_project_id,
          type: "content.all.store.size"
        )
      accum_store_size.resolve
    end
end
