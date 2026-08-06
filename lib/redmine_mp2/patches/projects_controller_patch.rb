# Adds mp2 phase/state issue counts to the project overview action.
# Uses Module#prepend (Redmine 7 style) instead of the removed
# alias_method_chain / manual alias technique.
module RedmineMp2
  module Patches
    module ProjectsControllerPatch
      # mp2 workflow status IDs shown in the phase overview table.
      # Central definition — adjust here if your IssueStatus IDs change.
      PHASE_STATUS_IDS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13].freeze

      def show
        super
        return unless @project

        # Suppress the members box on the project overview WITHOUT touching any
        # view: the core _members_box partial renders only `if
        # @principals_by_role.any?`, so clearing it here means the box (and all
        # member names/roles) is never emitted into the HTML. This is more
        # robust than a Deface selector and leaks no data to the client.
        @principals_by_role = {}

        cond = @project.project_condition(Setting.display_subprojects_issues?)
        @open_issues_by_state = {}
        PHASE_STATUS_IDS.each do |sid|
          @open_issues_by_state[sid] =
            Issue.visible.state(sid).where(cond).group(:tracker).count
        end
      end
    end
  end
end

unless ProjectsController.included_modules.include?(RedmineMp2::Patches::ProjectsControllerPatch)
  ProjectsController.prepend(RedmineMp2::Patches::ProjectsControllerPatch)
end
