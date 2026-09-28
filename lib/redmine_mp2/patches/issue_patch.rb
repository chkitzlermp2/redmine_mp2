# mp2 Issue customization: targeted overrides only.
#
#   1. `state` scope for filtering issues by status id (used by the project
#      phase-overview table).
#   2. `read_attribute_for_validation` fix for done_ratio (see below).
#
# IMPORTANT: Do NOT reintroduce a full copy of app/models/issue.rb. The old
# plugin shipped a 2000-line copy of the core model with a handful of tweaks.
# That copy went stale on the Redmine 7 upgrade and was missing the new
# #time_loggable? method, which is what caused the 500 error on every issue
# page. All those tweaks were reviewed and dropped (core behaviour is fine).
# Add future overrides here as targeted methods.
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

      # done_ratio validation fix
      #
      # redmine_issue_field_visibility overrides the reader of every hideable
      # core field:
      #
      #   define_method field do
      #     super() unless hidden_core_field?(field)
      #   end
      #
      # so for a role that must not see "% erledigt" (e.g. Reporter),
      # issue.done_ratio returns nil although the column holds 0 (DB default,
      # NOT NULL; core clear_disabled_fields also sets 0). The plugin's own
      # comment says done_ratio "makes trouble if nil'd", but the exclusion is
      # missing in its HIDEABLE_CORE_FIELDS list. Core's inclusion validation
      # 0..100 then reads nil and fails with "ist kein gültiger Wert".
      #
      # The old plugin "solved" this by commenting out the validation in its
      # copy of issue.rb. Here only the value used for validation is taken
      # from the real column; hiding in views, lists and API stays untouched.
      #
      # This module is prepended last and sits first in Issue.ancestors, so
      # this method wins over the visibility plugin.
      def read_attribute_for_validation(attr)
        return read_attribute(:done_ratio) if attr.to_s == 'done_ratio'
        super
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineMp2::Patches::IssuePatch)
  Issue.prepend(RedmineMp2::Patches::IssuePatch)
end