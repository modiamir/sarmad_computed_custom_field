module ComputedCustomField
  module CustomFieldsHelperPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :custom_field_tag, :patch
      end
    end

    module InstanceMethods
      def custom_field_tag_with_patch(prefix, custom_value)
        custom_value.custom_field.format.edit_tag self,
          custom_field_tag_id(prefix, custom_value.custom_field),
          custom_field_tag_name(prefix, custom_value.custom_field),
          custom_value,
          :class => "#{custom_value.custom_field.field_format}_cf",
          :disabled => custom_value.custom_field.is_computed
      end
    end

    def render_computed_custom_fields_select(custom_field)
      options = render_options_for_computed_custom_fields_select(custom_field)
      select_tag '', grouped_options_for_select(options), size: 5, multiple: true, id: 'available_cfs'
    end

    def render_options_for_computed_custom_fields_select(custom_field)
      options = custom_fields_for_options(custom_field).map do |field|
        is_computed = field.is_computed? ? ", #{l(:field_is_computed)}" : ''
        format = I18n.t(field.format.label)
        title = "#{field.name} (#{format}#{is_computed})"
        [content_tag(:span, title, title: title), "cfs[#{field.id}]"]
      end

      if custom_field.type == 'ProjectCustomField'
        tracker_option_groups = Tracker.all.map do |t|
          tracker_fields_options = t.custom_fields.map do |field|
            is_computed = field.is_computed? ? ", #{l(:field_is_computed)}" : ''
            format = I18n.t(field.format.label)
            title = "#{field.name} (#{format}#{is_computed})"
            [content_tag(:span, title, title: title), "ts[#{t.id}][#{field.id}]"]
          end
          ["Tracker Custom Fields: #{t.name}", tracker_fields_options]
        end

        tracker_attr_option_groups = Tracker.all.map do |t|
          issue_attributes = Issue.column_names.map do |attr|
            [content_tag(:span, attr, title: attr), "ta[#{t.id}][:#{attr}]"]
          end

          ["Tracker Attributes: #{t.name}", issue_attributes]
        end


        issue_attributes = Issue.column_names.map do |attr|
          [content_tag(:span, attr, title: attr), "ia[:#{attr}]"]
        end
        issue_attribute_option_group = {"Issue attributes": issue_attributes}

        opts = {"current project": options}.
          merge(tracker_option_groups.to_h).
          merge(tracker_attr_option_groups.to_h).
          merge(issue_attribute_option_group.to_h)
      else
        opts = {"current project": options}
      end


    end

    def custom_fields_for_options(custom_field)
      CustomField.where(type: custom_field.type).where('custom_fields.id != ?', custom_field.id || 0)
    end
  end
end

unless CustomFieldsHelper.included_modules
                         .include?(ComputedCustomField::CustomFieldsHelperPatch)
  CustomFieldsHelper.send :include, ComputedCustomField::CustomFieldsHelperPatch
end
