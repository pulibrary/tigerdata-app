# frozen_string_literal: true
module PdcDescribe
  class LoadLdapConfig < Rails::Application
    config.ldap = config_for(:ldap)
  end
end
