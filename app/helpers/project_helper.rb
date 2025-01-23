# frozen_string_literal: true
# Helper methods for projects
module ProjectHelper
  # For a new project form, pre-populate the data sponsor field with the current user's netid.
  # For an existing project form, pre-populate the data sponsor field with the current value.
  def pre_populate_data_sponsor
    if @project.metadata[:data_sponsor].nil?
      current_user.uid
    else
      @project.metadata[:data_sponsor]
    end
  end

  # Returns a string with JSON representation of a list of users
  # The JSON can be used to feed the jQuery Autocomplete plug-in
  # rubocop:disable Rails/OutputSafety
  def user_list_json(users)
    json_elements = users.map do |user|
      { data: user.uid, value: "#{user.display_name_safe} (#{user.uid})" }.to_json
    end

    json_elements.join(",").html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def sponsor_list_json
    user_list_json(User.sponsor_users)
  end

  def manager_list_json
    user_list_json(User.manager_users)
  end

  def all_users_list_json
    user_list_json(User.all)
  end
end
