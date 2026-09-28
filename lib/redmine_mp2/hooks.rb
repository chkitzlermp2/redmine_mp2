module RedmineMp2
  # View hooks. These inject mp2 markup into the stock Redmine views
  # WITHOUT replacing any core template, so the plugin survives upgrades.
  class Hooks < Redmine::Hook::ViewListener
    # Role that must not see the "Zusammenfassung" (issues report) links on
    # the project overview. Matched by name; change here if renamed.
    SUMMARY_HIDDEN_ROLE_NAME = 'Reporter'.freeze

    # Rendered INSIDE core's <div class="attributes"> (issues/show),
    # right before the closing tag. We hide the core rows via CSS and
    # show our own two-column, collapsible block instead.
    def view_issues_show_details_bottom(context = {})
      issue = context[:issue]
      return '' unless issue

      context[:controller].send(:render_to_string,
        partial: 'issues/mp2_attributes',
        locals:  { issue: issue })
    end

    # Load mp2 CSS + JS on every page (small, harmless if unused).
    # The customer-mode flag is exposed as a <meta> tag; mp2.js reads it and
    # toggles the body class. Keeping it out of Ruby view logic means the
    # setting can change without touching templates.
    def view_layouts_base_html_head(context = {})
      customer_mode = RedmineMP2Helper.get_setting(:darkmode).to_s == '1'
      right_fields = RedmineMp2::FieldConfig.right_field_keys.join(',')
      all_fields = RedmineMp2::FieldConfig.all_field_keys.join(',')
      tag.meta(name: 'mp2-customer-mode', content: customer_mode.to_s) +
        tag.meta(name: 'mp2-right-fields', content: right_fields) +
        tag.meta(name: 'mp2-all-fields', content: all_fields) +
        tag.meta(name: 'mp2-additional-label', content: l(:label_mp2_additional_info)) +
        stylesheet_link_tag('mp2', plugin: 'redmine_mp2') +
        javascript_include_tag('mp2', plugin: 'redmine_mp2')
    end

    # mp2 footer (Impressum / Datenschutz) on every page.
    def view_layouts_base_body_bottom(context = {})
      tag.div(class: 'mp2-footer') do
        raw(
          "&copy; #{Date.today.year} MP2 IT-Solutions GmbH | " \
          "#{link_to('Impressum', 'https://www.mp2.at/impressum')} | " \
          "#{link_to('Datenschutz', 'https://www.mp2.at/datenschutz')}"
        )
      end
    end

    # Injected before page content: mp2 welcome banner (home page) and the
    # project phase overview table. The phase table is rendered here (at the
    # bottom of the content area) and moved into place by mp2.js.
    def view_layouts_base_content(context = {})
      controller = context[:controller]
      return '' unless controller

      out = +''

      # Welcome page banner.
      if controller.is_a?(WelcomeController) && controller.action_name == 'index'
        out << tag.div(class: 'mp2-banner') do
          link_to('', 'https://www.mp2.at/', class: 'main_banner_1') +
            link_to('', 'https://www.mp2.at/', class: 'main_banner_2')
        end
      end

      # Project overview phase table.
      if controller.is_a?(ProjectsController) && controller.action_name == 'show'
        project = controller.instance_variable_get(:@project)
        trackers = controller.instance_variable_get(:@trackers)
        state_counts = controller.instance_variable_get(:@open_issues_by_state)
        if project && trackers.present? && state_counts.present?
          out << controller.send(:render_to_string,
            partial: 'projects/mp2_phase_overview')
        end

        # Hide "Zusammenfassung" for reporter-only users (see method below).
        out << mp2_hide_issue_summary_script if mp2_hide_issue_summary?(project)
      end

      out.html_safe
    end

    private

    # Redmine has no separate permission for the issues report: anyone with
    # :view_issues sees the "Zusammenfassung" link. So the decision is made
    # here by role.
    #
    # Hidden only if the user's roles in this project are ALL the reporter
    # role. Anyone with an additional role (e.g. developer) keeps the link;
    # admins always keep it.
    #
    # NOTE: This only hides the links. /projects/<id>/issues/report stays
    # reachable by URL. Blocking it would need a ReportsController patch.
    def mp2_hide_issue_summary?(project)
      user = User.current
      return false if project.nil? || !user.logged? || user.admin?

      roles = user.roles_for_project(project)
      roles.any? && roles.all? { |r| r.name == SUMMARY_HIDDEN_ROLE_NAME }
    end

    # Removes every link to .../issues/report inside #content: the one in
    # core's issues box (projects/show.html.erb: "| <%= link_to
    # l(:field_summary), project_issues_report_path(@project) %>") and the one
    # in the mp2 phase overview. The "|" in front is a plain text node and is
    # trimmed too, so "Alle Tickets anzeigen" does not end with a dangling
    # separator.
    # $= "/issues/report" matches only the summary itself, not the detail
    # reports (/issues/report/tracker etc.).
    def mp2_hide_issue_summary_script
      javascript_tag(<<~JS)
        document.addEventListener('DOMContentLoaded', function () {
          document.querySelectorAll('#content a[href$="/issues/report"]').forEach(function (a) {
            var prev = a.previousSibling;
            if (prev && prev.nodeType === 3) {
              prev.textContent = prev.textContent.replace(/\\|\\s*$/, '');
            }
            a.remove();
          });
        });
      JS
    end
  end
end