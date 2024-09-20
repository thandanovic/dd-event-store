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
      process_step(step, payload)
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

  def process_step(step, payload)
    case step["type"]
    when "Condition"
      handle_condition(step, payload)
    when "Processor"
      handle_processor(step, payload)
    when "Action"
      handle_action(step, payload)
    end
  end

  def handle_condition(step, payload)
    if evaluate_condition(step["condition"], payload)
      @current_step = step["true_steps"].first
    else
      @current_step = step["false_steps"].first
    end
  end

  def find_next_step(step, payload)
    if step["type"] == "Condition"
      condition_result = evaluate_condition(step["condition"], payload)
      condition_result ? step["true_steps"].first : step["false_steps"].first
    else
      current_index = @workflow.definition["steps"].index(step)
      next_step = @workflow.definition["steps"][current_index + 1]
      next_step ? next_step["id"] : nil
    end
  end

  def handle_processor(step, payload)
    step["actions"].each do |action|
      action["type"] == "Math" ? perform_math(action, payload) : handle_action(action, payload)
    end
  end

  def handle_action(step, payload)
    case step["action_type"]
    when "Email"
      WorkflowHelper.send_email(step, payload)
    when "Document"
      WorkflowHelper.generate_document(step, payload)
    when "SMS"
      WorkflowHelper.send_sms(step, payload)
    when "model_update"
      UpdateResourceService.new(step, payload).call
    when "model_insert"
      CreateResourceService.new(step, payload).call
    end
  end

  def evaluate_condition(condition, payload)
    ConditionEvaluatorService.new(condition, payload).evaluate
  end

  def perform_math(action, payload)
    MathOperationPerformerService.new(action, payload).perform
  end
end