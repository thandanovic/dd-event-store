class WorkflowProcessor
  def initialize(workflow)
    @workflow = workflow
    @current_step = workflow.definition["steps"].first["id"]
    @workflow_execution = WorkflowExecution.create!(workflow: workflow, status: :not_started)
    
  end

  def execute(event)

    payload = event.data


    @workflow_execution.update!(status: :in_progress, workflow_event_store_id: event.correlation_id)

    puts "STEP"
    puts @current_step

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
    # add logic to write which step failed
  end



  private

  def find_step(step_id)
    @workflow.definition["steps"].find { |s| s["id"] == step_id }
  end

  def find_next_step(step, payload)
    if step["type"] == "Condition"
      evaluate_condition(step["condition"], payload) ? step["true_steps"].first : step["false_steps"].first
    end
  end

  def handle_condition(step, payload)
    # Evaluate the condition and set the next step based on its result
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
    puts "handle_action"
    puts step.inspect
  
    case step["action_type"]
    when "Email"
      send_email(step, payload)
    when "Document"
      generate_document(step, payload)
    when "SMS"
      send_sms(step, payload)
    when "model_update"
      model_update(step, payload)
    end
  end

  def evaluate_condition(condition, payload)
    field_value = payload[condition["field"]]
    case condition["operator"]
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
      condition["sub_conditions"].all? { |sub_condition| evaluate_condition(sub_condition, payload) }
    when "Or"
      condition["sub_conditions"].any? { |sub_condition| evaluate_condition(sub_condition, payload) }
    when "Not"
      !evaluate_condition(condition["sub_condition"], payload)
    else
      false
    end
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

    puts "model_update"
    puts step.inspect
    puts payload.inspect




    resource_type = payload[:resource_type]
    resource = JSON.parse(payload[:resource])

    puts resource.inspect
    puts resource_type.inspect

    
    field = step["field"]
    value = get_value(resource, step["value"])
    record = resource_type.constantize.find(resource["id"])


    UpdateResource.new(data: { update_type: "base_model", resource_type: resource_type, resource: resource, definition: {
      field: field,
      value: value
    } }).tap do |event|
      Rails.configuration.event_store.publish(event)
    end
  end

  def get_value(payload, value)    
    # Use regex to find all placeholders in the format {{field}}
    value.gsub(/\{\{(\w+)\}\}/) do |match|
      # Extract the field name from the placeholder (e.g., 'name' from '{{name}}')
      field = match[2..-3]
      
      # Replace the placeholder with the corresponding value from the payload
      # If the field doesn't exist in the payload, keep the placeholder unchanged
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
