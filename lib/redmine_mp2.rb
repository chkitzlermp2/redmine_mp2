module RedmineMp2
  # Load patches and hooks once Rails is ready. Using to_prepare avoids
  # touching the database at load time (which breaks during migrations and
  # asset precompile on Redmine 6/7) and reloads cleanly in development.
  def self.setup
    require File.expand_path('../redmine_mp2/patches/mail_handler_patch', __FILE__)
    require File.expand_path('../redmine_mp2/patches/issues_helper_patch', __FILE__)
    require File.expand_path('../redmine_mp2/patches/issue_patch', __FILE__)
    require File.expand_path('../redmine_mp2/patches/projects_controller_patch', __FILE__)
  end
end

# View hooks (safe to require at load time).
require File.expand_path('../redmine_mp2/hooks', __FILE__)
require File.expand_path('../redmine_mp2/field_config', __FILE__)

Rails.configuration.to_prepare do
  RedmineMp2.setup
end
