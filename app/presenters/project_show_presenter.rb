# frozen_string_literal: true
class ProjectShowPresenter
  delegate "id", "in_mediaflux?", "mediaflux_id", "pending?", "status", "title", to: :project
  delegate "description", "project_id", "storage_performance_expectations", "project_purpose", to: :project_metadata

  attr_reader :project, :project_metadata

  # @return [Class] The presenter class for building XML Documents from Projects
  def self.xml_presenter_class
    ProjectXmlPresenter
  end

  def initialize(project)
    @project = project
    @project_metadata = @project.metadata_model
  end

  # @return [String] the XML for the project Document 
  def to_xml
    xml_document.to_xml
  end

  # @return [Nokogiri::XML::Document] the XML Document for the Project
  def xml_document
    @xml_document ||= xml_presenter.document
  end

  def created
    @project.created_at.strftime("%b %e, %Y %l:%M %p")
  end

  def updated
    @project.updated_at.strftime("%b %e, %Y %l:%M %p")
  end

  def data_sponsor
    User.find_by(uid: @project.metadata["data_sponsor"]).uid
  end

  def data_manager
    User.find_by(uid: @project.metadata["data_manager"]).uid
  end

  # used to hide the project root that is not visible to the end user
  def project_directory
    project.project_directory.gsub(Mediaflux::Connection.hidden_root, "")
  end

  # This assumed that the storage usage is recorded in the same units as the units specified in the StorageCapacity metadata
  def storage_usage(session_id:)
    persisted = project.storage_usage_raw(session_id: session_id)
    value = persisted.to_f

    value*default_usage_divisor
  end

  def storage_capacity(session_id: nil)
    return project_metadata.storage_capacity if session_id.nil?

    persisted = project.storage_capacity_raw(session_id: session_id)
    value = persisted.to_f

    value*default_capacity_divisor
  end

  def formatted_storage_capacity(session_id:)
    value = storage_capacity(session_id: session_id)
    format("%.3f", value)
  end

  def formatted_quota_percentage(session_id:)
    value = quota_percentage(session_id:)
    format("%.3f", value)
  end

  def quota_usage(session_id:)
    if project.pending?
      quota_usage = "0 KB out of 0 GB used"
    else
      quota_usage = "#{project.storage_usage(session_id:)} out of #{project.storage_capacity(session_id:)} used"
    end
    quota_usage
  end

  def quota_percentage(session_id:)
    return 0 if project.pending? || project.storage_capacity_raw(session_id:).zero?

   (project.storage_usage_raw(session_id:).to_f / project.storage_capacity_raw(session_id:).to_f) * 100
  end

  private

    def default_usage_divisor
      1.0/(1000.0**1)
    end

    # Capacity is in bytes
    def default_capacity_divisor
      1.0/(1000.0**3)
    end

    def storage_remaining(session_id:)
      capacity = storage_capacity(session_id: session_id)
      return 0.0 if capacity.zero?

      usage = storage_usage(session_id: session_id)

      remaining = (capacity/default_capacity_divisor) - usage
      remaining*default_capacity_divisor
    end

    def xml_presenter_args
      project
    end

    def xml_presenter
      @xml_presenter ||= self.class.xml_presenter_class.new(xml_presenter_args)
    end
end
