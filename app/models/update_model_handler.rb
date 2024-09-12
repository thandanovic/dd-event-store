class UpdateModelHandler
  def call(event)
    puts event.inspect

   # get record by resource type and resource
    resource_type = event.data[:resource_type]
    resource = event.data[:resource]
    record = resource_type.constantize.find(resource["id"])

    value = event.data[:definition][:value]
    field = event.data[:definition][:field]

    # update record if event.data.definition is definition: {field: field,value: value}
    # if event.data.definition.present?
 
    puts record.inspect

    record.update!(field => value)
    
    

    # case event
    # when ResourceCreated
      
    #   LogEvent.new(data: { event_type: "Log", message: "Resource Created" }).tap do |event|
    #     Rails.configuration.event_store.publish(event)
    #   end
    # when ResourceDeleted
    #   Rails.logger.info("ResourceDeleted: #{id}")
    # when ResourceUpdated
    #   Rails.logger.info("ResourceUpdated: #{id}")
    # else
    #   raise "not supported event #{event.inspect}"
    # end
  end
end