# mp2 Issue customization: ONLY adds a `state` scope for filtering issues by
# status id (used by the project phase-overview table).
#
# IMPORTANT: Do NOT reintroduce a full copy of app/models/issue.rb. The old
# plugin shipped a 2000-line copy of the core model with a handful of tweaks.
# That copy went stale on the Redmine 7 upgrade and was missing the new
# #time_loggable? method, which is what caused the 500 error on every issue
# page. All those tweaks were reviewed and dropped (core behaviour is fine),
# leaving just this scope. Add future overrides here as targeted methods.
module RedmineMp2
  module Patches
    module IssuePatch
      def self.prepended(base)
        base.class_eval do
          # Usage: Issue.state(8) => issues whose status_id == 8
          scope :state, lambda { |*args|
            id = args.size > 0 ? args.first : 1
            joins(:status).where("#{IssueStatus.table_name}.id = ?", id)
          }
        end
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineMp2::Patches::IssuePatch)
  Issue.prepend(RedmineMp2::Patches::IssuePatch)
end
