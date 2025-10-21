# frozen_string_literal: true
class ProjectShowPresenter
  delegate "id", "in_mediaflux?", "mediaflux_id", "status", to: :project
  delegate "project_id", "storage_performance_expectations", "project_purpose", to: :project_metadata

  attr_reader :project, :project_metadata

  # @return [Class] The presenter class for building XML Documents from Projects
  def self.xml_presenter_class
    ProjectXmlPresenter
  end

  # `project` can be a Project model or a Hash with the project data straight from Mediaflux.
  # It is a Project model when used from the Project show page but it is a Hash when used
  # from the Dashboard.
  def initialize(project)
    if project.is_a?(Hash)
      # If the project is a Hash we assume it contains the raw data about the project from Mediaflux.
      @project_mf = project
      # Fetch the Rails project from our database since we still need some of its values.
      @project = Project.where(mediaflux_id: @project_mf[:mediaflux_id]).first
      if @project.nil?
        Rails.logger.warn("Mediaflux project with ID #{@project_mf[:mediaflux_id]} is not in the Rails database (title: #{@project_mf[:title]})")
        Honeybadger.notify("Mediaflux project with ID #{@project_mf[:mediaflux_id]} is not in the Rails database (title: #{@project_mf[:title]})")
      end
    else
      @project_mf = nil
      @project = project
    end
    @project_metadata = @project&.metadata_model
  end

  def title
    if @project_mf.nil?
      @project.title
    else
      @project_mf[:title]
    end
  end

  def description
    if @project_mf.nil?
      @project.metadata_model.description
    else
      @project_mf[:description]
    end
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
    if @project_mf.nil?
      User.find_by(uid: @project.metadata["data_sponsor"]).uid
    else
      User.find_by(uid: @project_mf[:data_sponsor])&.uid
    end
  end

  def data_manager
    if @project_mf.nil?
      User.find_by(uid: @project.metadata["data_manager"]).uid
    else
      User.find_by(uid: @project_mf[:data_manager])&.uid
    end
  end

  def project_purpose
    if @project_mf.nil?
      project.project_metadata.project_purpose
    else
      @project_mf[:project_purpose]
    end
  end

  # used to hide the project root that is not visible to the end user
  def project_directory
    project.project_directory.gsub(Mediaflux::Connection.hidden_root, "")
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
    "#{project.storage_usage(session_id:)} out of #{project.storage_capacity(session_id:)} used"
  end

  def quota_percentage(session_id:)
    storage_capacity = project.storage_capacity_raw(session_id:)
    return 0 if storage_capacity.zero?

    storage_usage = project.storage_usage_raw(session_id:)
    (storage_usage.to_f / storage_capacity.to_f) * 100
  end

  private

    # Capacity is in bytes
    def default_capacity_divisor
      1.0/(1000.0**3)
    end

    def xml_presenter_args
      project
    end

    def xml_presenter
      @xml_presenter ||= self.class.xml_presenter_class.new(xml_presenter_args)
    end
end
