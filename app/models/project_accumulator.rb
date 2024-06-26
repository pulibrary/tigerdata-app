# frozen_string_literal: true
class ProjectAccumulators
  # TODO: modify create! to validate and create accumulators if they are not present

  def create!(mediaflux_project_id:, session_id:)
    accum_count = Mediaflux::Http::AccumulatorCreateCollectionRequest.new(
        session_token: session_id,
        name: "accum-count",
        collection: mediaflux_project_id,
        type: "collection.asset.count"
      )
    accum_count.resolve
    accum_size = Mediaflux::Http::AccumulatorCreateCollectionRequest.new(
        session_token: session_id,
        name: "accum-size",
        collection: mediaflux_project_id,
        type: "content.all.size"
      )
    accum_size.resolve
    accum_store_size = Mediaflux::Http::AccumulatorCreateCollectionRequest.new(
        session_token: session_id,
        name: "accum-store-size",
        collection: mediaflux_project_id,
        type: "content.all.store.size"
      )
    accum_store_size.resolve
  end

  def validate(mediaflux_project_id:, session_id:)
    collection_metadata = Mediaflux::Http::AssetMetadataRequest.new(session_token: session_id, id: mediaflux_project_id).metadata
    return true unless collection_metadata.length < 3

    Rails.logger.info("ProjectAccumulator: Accumulators not complete for project #{mediaflux_project_id}")
    collection_metadata
  end
end
