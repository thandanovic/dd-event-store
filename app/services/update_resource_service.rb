class UpdateResourceService
    include WorkflowHelper
  
    def initialize(step, payload)
      @step = step
      @payload = payload
    end
  
    def call
      resource_type = @payload[:resource_type]
      resource = JSON.parse(@payload[:resource])
      @payload.merge!(resource)
      field = @step["field"]
      value = WorkflowHelper.get_value(@payload, @step["value"])
  
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
  end