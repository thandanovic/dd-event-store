class GlobalHandler
  def call(event)
    puts event.inspect

    #add logic to extract lawfirm ID from event
    
    # lawfirm_id = event.data[:lawfirm_id]
    
    # #Get all workflows for that lawfirm ID and on that event
    
    # workflows = Workflow.where(lawfirm_id: lawfirm_id, event: event.event_type)
    
    # workflows.each do |workflow|
    #  WorkflowProcessor.new(workflow).execute(event.data) if workflow.active?
    # end
    # 
    # load workflow from json
    
    

    case event
    when ResourceCreated



      
      LogEvent.new(data: { event_type: "Workflow", message: "Start" }).tap do |event|
        Rails.configuration.event_store.publish(event)
      end

      definition = JSON.parse(File.read("app/resources/update_workflow.json"))

      workflow = Workflow.find_by(definition: definition) || Workflow.new(definition: JSON.parse(File.read("app/resources/update_workflow.json"))) 

      workflow.save if workflow.new_record?
      
      puts workflow.definition.inspect
         
      WorkflowProcessor.new(workflow).execute(event)

      LogEvent.new(data: { event_type: "Workflow", message: "End" }).tap do |event|
        Rails.configuration.event_store.publish(event)
      end

      # CreateModelJob.perform_later(event.data)  
    when ResourceDeleted
      Rails.logger.info("ResourceDeleted:")
    when ResourceUpdated
      Rails.logger.info("ResourceUpdated:")
    else
      raise "not supported event #{event.inspect}"
    end
  end
end