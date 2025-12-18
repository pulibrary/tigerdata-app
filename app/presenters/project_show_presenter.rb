# frozen_string_literal: true
class ProjectShowPresenter
  delegate "id", "in_mediaflux?", "mediaflux_id", "status", to: :project
  delegate "project_id", "storage_performance_expectations", to: :project_metadata

  attr_reader :project, :project_metadata

  # @return [Class] The presenter class for building XML Documents from Projects
  def self.xml_presenter_class
    ProjectXmlPresenter
  end

  # Constructor
  # @param project [Project] the project to be presented
  # @param current_user [User] the user currently logged in
  # @param project_mf [Hash] the current representation of the project in Mediaflux
  def initialize(project, current_user, project_mf: nil)
    @project = project
    @project_mf = project_mf || project.mediaflux_metadata(session_id: current_user.mediaflux_session)
    @project_metadata = @project&.metadata_model
  end

  def title
    @project_mf[:title]
  end

  def description
    @project_mf[:description]
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
    @data_sponsor ||= User.find_by(uid: @project_mf[:data_sponsor])
  end

  def data_manager
    @data_manager ||= User.find_by(uid: @project_mf[:data_manager])
  end

  def data_read_only_users
    (@project_mf[:ro_users] || []).map { |uid| UserPresenter.new(User.find_by(uid:)) }.compact
  end

  def data_read_write_users
    (@project_mf[:rw_users] || []).map { |uid| UserReadWritePresenter.new(User.find_by(uid:)) }.compact
  end

  def data_users
    @data_users ||= begin
                      unsorted_data_users = data_read_only_users + data_read_write_users
                      sorted_data_users = unsorted_data_users.sort_by { |u| u.family_name || u.uid }
                      sorted_data_users.uniq { |u| u.uid }
                    end
  end

  def data_user_names
    user_model_names = data_users.map(&:display_name_safe)
    user_model_names.join(", ")
  end

  def project_purpose
    ProjectPurpose.label_for(@project_mf[:project_purpose])
  end

  # used to hide the project root that is not visible to the end user
  def project_directory
    # This value comes from Mediaflux without the extra hidden root
    directory = @project_mf[:project_directory] || ""
    directory.start_with?("/") ? directory : "/" + directory
  end

  def hpc
    @project_mf[:hpc] == true ? "Yes" : "No"
  end

  def globus
    @project_mf[:globus] == true ? "Yes" : "No"
  end

  def smb
    @project_mf[:smb] == true ? "Yes" : "No"
  end

  def number_of_files
    @project_mf[:number_of_files]
  end

  def departments
    @project_mf[:departments] || []
  end

  def submission_provenance
    @project.metadata_json["submission"]
  end

  def requested_by_display_name
    requested_by_user.display_name_only_safe
  end

   def requested_by_uid
    requested_by_user.uid
  end

  def requested_on
    date_time = {}
    req_date =  safe_date(@project.metadata_json["submission"]["request_date_time"])
    date = req_date.strftime("%B %d, %Y")
    time = req_date.strftime("%I:%M %p")
    date_time["#{date}"] = time
    date_time
  end

  def approved_by_display_name
    approved_by_user.display_name_only_safe
  end

  def approved_by_uid
    approved_by_user.uid
  end

  def approved_on
    date_time = {}
    approve_date =  safe_date(@project.metadata_json["submission"]["approved_on"])
    date = approve_date.strftime("%B %d, %Y")
    time = approve_date.strftime("%I:%M %p")
    date_time["#{date}"] = time
    date_time
  end

  def department_codes
    @dep_with_codes = {}
    departments_list = departments.nil? ? [] : departments.first.split(", ")
    departments_list.map do |dept|
      tmp_code = Affiliation.find_fuzzy_by_name(dept)
      @dep_with_codes[dept] = tmp_code.code unless tmp_code.nil?
    end
    @dep_with_codes
  end

  def project_id
    @project_mf[:project_id]
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

  def quota_percentage(session_id:, dashboard: false)
    storage_capacity = project.storage_capacity_raw(session_id:)
    return 0 if storage_capacity.zero?
    storage_usage = project.storage_usage_raw(session_id:)
    return 0 if storage_usage == 0
    storage_value = (storage_usage.to_f / storage_capacity.to_f) * 100
    minimum_storage_used = true if storage_value > 0 && storage_value < 1
    storage_value = 1 if minimum_storage_used
    storage_value += 1 if minimum_storage_used && dashboard
    storage_value
  end

  def user_has_access?(user:)
    return true if user.eligible_sysadmin?
    data_sponsor&.uid == user.uid || data_manager&.uid == user.uid || data_users.map(&:uid).include?(user.uid)
  end

  def project_in_rails?
    project != nil
  end

  private

    def requested_by_user
      @requested_by_user ||= safe_user(submission_provenance["requested_by"])
    end

    def approved_by_user
      @approved_by_user ||= safe_user(submission_provenance["approved_by"])
    end

    def safe_user(uid)
      if uid.blank?
        NilUser.new
      else
        User.find_by(uid:) ||  NilUser.new
      end
    end

    def safe_date(date)
      if date.blank?
        NilDate.new
      else
        date.to_datetime || NilDate
      end
    end

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

    def rails_project(project_mf)
      database_record = Project.find_by(mediaflux_id: project_mf[:mediaflux_id])
      if database_record.nil?
        message = "Mediaflux project with ID #{project_mf[:mediaflux_id]} is not in the Rails database (title: #{project_mf[:title]})"
        Rails.logger.warn(message)
        Honeybadger.notify(message)
      end
      database_record
    end
end
