# Central place that knows which issue fields can be moved into the collapsible
# "Zusätzliche Informationen" (right) column, and which ones the admin has
# actually chosen. Used by BOTH the show view (helper) and the edit form (JS).
#
# Field keys:
#   * internal fields  -> the Redmine attribute name, e.g. "assigned_to_id"
#   * custom fields    -> "cf_<id>", e.g. "cf_24"
module RedmineMp2
  module FieldConfig
    # Internal (core) issue fields that make sense to move. Order = display
    # order when shown. Labels use Redmine's own i18n keys so they stay
    # translated. Keeps the list intentionally focused on the fields MP2 uses.
    INTERNAL_FIELDS = [
      ['status_id',        :field_status],
      ['priority_id',      :field_priority],
      ['assigned_to_id',   :field_assigned_to],
      ['category_id',      :field_category],
      ['fixed_version_id', :field_fixed_version],
      ['parent_issue_id',  :field_parent_issue],
      ['start_date',       :field_start_date],
      ['due_date',         :field_due_date],
      ['estimated_hours',  :field_estimated_hours],
      ['done_ratio',       :field_done_ratio],
      # Display-only: there is no input for spent time in the issue form, so
      # this key only affects the show view. The edit-form JS looks the field
      # up and skips it when not found, so listing it here is harmless.
      ['spent_time',       :label_spent_time]
    ].freeze

    module_function

    # The plugin setting: array of field keys that belong in the right,
    # collapsible column. Everything else stays in the left column.
    def right_field_keys
      raw = Setting.plugin_redmine_mp2 && Setting.plugin_redmine_mp2['right_fields']
      Array(raw).reject(&:blank?)
    end

    def right?(key)
      right_field_keys.include?(key.to_s)
    end

    # All custom fields that can appear on issues, for the settings checkboxes.
    def issue_custom_fields
      IssueCustomField.sorted.to_a
    rescue StandardError
      # sorted scope may not exist on very old versions; fall back.
      IssueCustomField.all.to_a
    end

    # Convenience: the key used for a custom field.
    def cf_key(custom_field)
      "cf_#{custom_field.id}"
    end

    # All movable field keys (internal + custom fields). Used by the edit-form
    # JS to place every field explicitly: configured keys go right, the rest
    # go left (Redmine's own left/right split is otherwise inconsistent).
    def all_field_keys
      internal = INTERNAL_FIELDS.map { |key, _label| key }
      custom = issue_custom_fields.map { |cf| cf_key(cf) }
      internal + custom
    end
  end
end
