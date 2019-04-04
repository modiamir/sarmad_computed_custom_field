module ComputedCustomField
  module ModelPatch
    extend ActiveSupport::Concern

    included do
      before_validation :eval_computed_fields
    end

    private

    def eval_computed_fields
      custom_field_values.each do |value|
        next unless value.custom_field.is_computed?
        eval_computed_field value.custom_field
      end
    end

    # rubocop:disable Lint/UselessAssignment, Security/Eval
    def eval_computed_field(custom_field)
      cfs = parse_computed_field_formula custom_field.formula
      ts = parse_computed_field_formula_tracker custom_field.formula
      value = eval custom_field.formula
      self.custom_field_values = {
        custom_field.id => prepare_computed_value(custom_field, value)
      }
    rescue Exception => e
      errors.add :base, l(:error_while_formula_computing,
                          custom_field_name: custom_field.name,
                          message: e.message)
    end
    # rubocop:enable Lint/UselessAssignment, Security/Eval

    def parse_computed_field_formula(formula)
      @grouped_cfvs ||= custom_field_values
                        .group_by { |cfv| cfv.custom_field.id }
      cf_ids = formula.scan(/cfs\[(\d+)\]/).flatten.map(&:to_i)
      cf_ids.each_with_object({}) do |cf_id, hash|
        cfv = @grouped_cfvs[cf_id].first
        hash[cf_id] = cfv ? cfv.custom_field.cast_value(cfv.value) : nil
      end
    end

    def parse_computed_field_formula_tracker(formula)
      formula.scan(/ts\[(\d+)\]\[(\d+)\]/).each_with_object({}) do |pair, hash|
        tid = pair[0].to_i
        fid = pair[1].to_i

        sum = CustomValue.joins("join issues on issues.id = custom_values.customized_id").where(customized_type: "Issue", custom_field_id: fid).where("issues.tracker_id = ?", tid).where("custom_values.value is not null and custom_values.value <> ''").sum("cast(value as double precision)")

        hash[tid] = {} if hash[tid].nil?
        hash[tid][fid] = sum
      end
    end

    def prepare_computed_value(custom_field, value)
      return value.map { |v| prepare_computed_value(custom_field, v) } if value.is_a? Array

      result = case custom_field.field_format
               when 'bool'
                 value.is_a?(TrueClass) ? '1' : '0'
               when 'int'
                 value.to_i
               else
                 value.respond_to?(:id) ? value.id : value
               end
      result.to_s
    end
  end
end
