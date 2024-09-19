class WorkflowProcessor
  def initialize(workflow)
    @workflow = workflow
    @current_step = workflow.definition["steps"].first["id"]
    @workflow_execution = WorkflowExecution.create!(workflow: workflow, status: :not_started)
  end

  def execute(event)
    payload = event.data
    @workflow_execution.update!(status: :in_progress, workflow_event_store_id: event.correlation_id)

    while @current_step
      step = find_step(@current_step)

      case step["type"]
      when "Condition"
        handle_condition(step, payload)
      when "Processor"
        handle_processor(step, payload)
      when "Action"
        handle_action(step, payload)
      end
      @current_step = find_next_step(step, payload)
    end
    @workflow_execution.update!(status: :success)
  rescue StandardError => e
    @workflow_execution.update!(status: :failed, error_message: e.message)
    raise e
  end

  private

  def find_step(step_id)
    @workflow.definition["steps"].find { |s| s["id"] == step_id }
  end

  def handle_condition(step, payload)
    if evaluate_condition(step["condition"], payload, step)
      @current_step = step["true_steps"].first
    else
      @current_step = step["false_steps"].first
    end
  end

  def find_next_step(step, payload)
    if step["type"] == "Condition"
      condition_result = evaluate_condition(step["condition"], payload, step)
      return step["true_steps"].first if condition_result
      return step["false_steps"].first
    else
      current_index = @workflow.definition["steps"].index(step)
      next_step = @workflow.definition["steps"][current_index + 1]
      next_step ? next_step["id"] : nil
    end
  end

  def handle_processor(step, payload)
    step["actions"].each do |action|
      case action["type"]
      when "Math"
        perform_math(action, payload)
      else
        handle_action(action, payload)
      end
    end
  end

  def handle_action(step, payload)
    case step["action_type"]
    when "Email"
      send_email(step, payload)
    when "Document"
      generate_document(step, payload)
    when "SMS"
      send_sms(step, payload)
    when "model_update"
      model_update(step, payload)
    when "model_insert"
      model_insert(step, payload)
    end

    @current_step = find_next_step(step, payload)
  end

  def evaluate_condition(condition, payload, step)
    field_value = payload[condition["field"]]
    result = case condition["operator"]
             when "Equal"
               field_value == condition["value"]
             when "NotEqual"
               field_value != condition["value"]
             when "GreaterThan"
               field_value > condition["value"]
             when "LessThan"
               field_value < condition["value"]
             when "GreaterThanOrEqual"
               field_value >= condition["value"]
             when "LessThanOrEqual"
               field_value <= condition["value"]
             when "Between"
               value_range = condition["value"]
               value_range.include?(field_value)
             when "In"
               condition["value"].include?(field_value)
             when "Like"
               field_value =~ /#{condition["value"]}/
             when "IsNull"
               field_value.nil?
             when "IsNotNull"
               !field_value.nil?
             when "And"
               condition["sub_conditions"].all? { |sub_condition| evaluate_condition(sub_condition, payload, step) }
             when "Or"
               condition["sub_conditions"].any? { |sub_condition| evaluate_condition(sub_condition, payload, step) }
             when "Not"
               !evaluate_condition(condition["sub_condition"], payload, step)
             else
               false
             end
    result
  end

  def perform_math(action, payload)
    operand1 = payload[action["operand1"]]
    operand2 = action["operand2"]
    result = case action["operation"]
             when "Add"
               operand1 + operand2
             when "Subtract"
               operand1 - operand2
             when "Multiply"
               operand1 * operand2
             when "Divide"
               operand1 / operand2
             end
    payload[action["result_field"]] = result
  end

  def model_update(step, payload)
    resource_type = payload[:resource_type]
    resource = JSON.parse(payload[:resource])
    payload.merge!(resource)
    field = step["field"]
    value = get_value(payload, step["value"])
    UpdateResource.new(data: {
      update_type: "base_model",
      resource_type: resource_type,
      resource: resource,
      definition: {
        field: field,
        value: value
      }
    }).tap do |event|
      Rails.configuration.event_store.publish(event)
    end
  end

  def model_insert(step, payload)
    resource = JSON.parse(payload[:resource])
    payload.merge!(resource)

    payload['post_id'] ||= payload['id']

    post = Post.find(payload['post_id'])
    payload['content'] = post.content

    resource_type = step["model"]
    attributes = step["attributes"].transform_values { |v| get_value(payload, v) }

    CreateResource.new(data: {
      insert_type: "base_model",
      resource_type: resource_type,
      resource: resource,
      definition: { attributes: attributes }
    }).tap do |event|
      Rails.configuration.event_store.publish(event)
    end
  end

  def get_value(payload, value)
    value.gsub(/\{\{(\w+)\}\}/) do |match|
      field = match[2..-3]
      payload.fetch(field, match)
    end
  end

  def send_email(action, payload)
    # Implementation to send an email
  end

  def generate_document(action, payload)
    # Implementation to generate a document
  end

  def send_sms(action, payload)
    # Implementation to send an SMS
  end
end