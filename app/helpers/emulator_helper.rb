# frozen_string_literal: true

require "yaml"

module EmulatorHelper
  def emulator_content
    @yaml_data = YAML.load_file("config/emulator.yml")
    return false if @yaml_data[Rails.env].nil? || @yaml_data[Rails.env] == "production"
    #return false unless current_page?("/")
    @emulator_title = @yaml_data[Rails.env]["title"]
    @emulator_body = @yaml_data[Rails.env]["body"]
    @emulator_alt_title = @yaml_data[Rails.env]["alt_title"]
    @emulator_alt_body = @yaml_data[Rails.env]["alt_body"]
    @absolute_user = User.find(current_user.id)
  end

  def homepage?
    return true if current_page?("/")
   end
  
   def otherpage?
    @current_role = check_role
    return true unless current_page?("/")
   end

   def check_role
    @role = nil
    if current_user.eligible_sponsor?
      @role = "Data Sponsor"
    elsif current_user.eligible_manager?
      @role = "Data Manager"
    elsif current_user.eligible_data_user? && current_user.trainer == false
      @role = "Data User"
    elsif current_user.sysadmin
      @role = "System Administrator"
    else
      @role = "Trainer"  
    end
    @role
   end
end
