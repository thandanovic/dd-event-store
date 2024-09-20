class ConditionEvaluatorService
    def initialize(condition, payload)
      @condition = condition
      @payload = payload
    end
  
    def evaluate
      field_value = @payload[@condition["field"]]
      case @condition["operator"]
      when "Equal"
        field_value == @condition["value"]
      when "NotEqual"
        field_value != @condition["value"]
      when "GreaterThan"
        field_value > @condition["value"]
      when "LessThan"
        field_value < @condition["value"]
      when "GreaterThanOrEqual"
        field_value >= @condition["value"]
      when "LessThanOrEqual"
        field_value <= @condition["value"]
      when "Between"
        @condition["value"].include?(field_value)
      when "In"
        @condition["value"].include?(field_value)
      when "Like"
        field_value =~ /#{@condition["value"]}/
      when "IsNull"
        field_value.nil?
      when "IsNotNull"
        !field_value.nil?
      when "And"
        @condition["sub_conditions"].all? { |sub_condition| ConditionEvaluator.new(sub_condition, @payload).evaluate }
      when "Or"
        @condition["sub_conditions"].any? { |sub_condition| ConditionEvaluator.new(sub_condition, @payload).evaluate }
      when "Not"
        !ConditionEvaluator.new(@condition["sub_condition"], @payload).evaluate
      else
        false
      end
    end
  end