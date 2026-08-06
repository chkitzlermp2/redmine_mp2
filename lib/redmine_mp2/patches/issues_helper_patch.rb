module RedmineMp2
	module Patches
		module IssuesHelperPatch
			def self.included(base)
				base.extend(ClassMethods)
				base.send(:include, InstanceMethods)
			end

			# Class methods
			module ClassMethods
				
			end
		  
			# Instance methods
			module InstanceMethods
				class IssueFieldsRowsMP2
					include ActionView::Helpers::TagHelper

					def initialize
					  @left = []
					  @right = []
					end

					def left(*args)
					  args.any? ? @left << cells(*args) : @left
					end

					def right(*args)
					  args.any? ? @right << cells(*args) : @right
					end

					def size
					  @left.size > @right.size ? @left.size : @right.size
					end

					def to_html
					  # Own mp2- classes only (no core class names like
					  # splitcontent / detailsCollapsed) to avoid inheriting
					  # core CSS such as `.detailsCollapsed { display:none }`.
					  # NOTE: this runs inside a plain Ruby object, not a view,
					  # so the `l` helper is unavailable -> use I18n.t directly.
					  label = I18n.t(:label_mp2_additional_info)

					  left_html = content_tag('div', @left.reduce(&:+), :class => 'mp2-col mp2-col-left')

					  # Only render the collapsible right column when it has fields.
					  if @right.any?
					    right_html = content_tag('div',
					      content_tag('a', label, :href => '#', :class => 'mp2-toggle mp2-toggle-hide') +
					      content_tag('a', label, :href => '#', :class => 'mp2-toggle mp2-toggle-show') +
					      content_tag('div', @right.reduce(&:+), :class => 'mp2-details'),
					    :class => 'mp2-col mp2-col-right')
					  else
					    right_html = ''.html_safe
					  end

					  content_tag('div', left_html + right_html, :class => 'mp2-split')
					end

					def cells(label, text, options={})
					  options[:class] = [options[:class] || "", 'attribute'].join(' ')
					  content_tag 'div',
						content_tag('div', label + ":", :class => 'label') + content_tag('div', text, :class => 'value'),
						options
					end
				end

				def issue_fields_rows_mp2
				r = IssueFieldsRowsMP2.new
				yield r
				r.to_html
				end
			
				def render_half_width_custom_fields_rows_mp2(issue, rows)
					values = issue.visible_custom_field_values.reject {|value| value.custom_field.full_width_layout?}
					return if values.empty?
					values.each_with_index do |value, i|
						key = "cf_#{value.custom_field.id}"
						if RedmineMp2::FieldConfig.right?(key)
							css = "cf_#{value.custom_field.id} collapsed"
							rows.right custom_field_name_tag(value.custom_field), show_value(value), :class => css
						else
							css = "cf_#{value.custom_field.id} "
							rows.left custom_field_name_tag(value.custom_field), show_value(value), :class => css
						end
					end
				end
			end		
		end
	end
end

unless IssuesHelper.included_modules.include? RedmineMp2::Patches::IssuesHelperPatch
  IssuesHelper.send(:include, RedmineMp2::Patches::IssuesHelperPatch)
end
