# frozen_string_literal: true
class ProjectAccumulator
  # TODO: modify create! to validate and create accumulators if they are not present
  # change accum_names to be a an array of strings instead of an array of xml objects

  def create!(mediaflux_project_id:, session_id:)
    collection_metadata = validate(mediaflux_project_id: mediaflux_project_id, session_id: session_id)
    return unless collection_metadata.length < 3

    Rails.logger.info("ProjectAccumulator: Accumulators not complete for project #{mediaflux_project_id}")

    accum_names = collection_metadata[:accum_names]
    if accum_names.exclude?("accum-count")
      create_accum_count
    elsif accum_names.exclude?("accum-size")
      create_accum_size
    elsif accum_names.exclude?("accum-store-size")
      create_accum_store_size
    end
  end

  def validate(mediaflux_project_id:, session_id:)
    collection_metadata = Mediaflux::Http::AssetMetadataRequest.new(session_token: session_id, id: mediaflux_project_id).metadata

    collection_metadata
  end

  private

    def create_accum_count
      accum_count = Mediaflux::Http::AccumulatorCreateCollectionRequest.new(
          session_token: session_id,
          name: "accum-count",
          collection: mediaflux_project_id,
          type: "collection.asset.count"
        )
      accum_count.resolve
    end

    def create_accum_size
      accum_size = Mediaflux::Http::AccumulatorCreateCollectionRequest.new(
          session_token: session_id,
          name: "accum-size",
          collection: mediaflux_project_id,
          type: "content.all.size"
        )
      accum_size.resolve
    end

    def create_accum_store_size
      accum_store_size = Mediaflux::Http::AccumulatorCreateCollectionRequest.new(
          session_token: session_id,
          name: "accum-store-size",
          collection: mediaflux_project_id,
          type: "content.all.store.size"
        )
      accum_store_size.resolve
    end
end
