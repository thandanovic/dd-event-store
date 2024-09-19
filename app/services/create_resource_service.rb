class CreateResourceService
    include WorkflowHelper
  
    def initialize(step, payload)
      @step = step
      @payload = payload
    end
  
    def call
      resource = JSON.parse(@payload[:resource])
      @payload.merge!(resource)
      @payload['post_id'] ||= @payload['id']
      post = Post.find(@payload['post_id'])
      @payload['content'] = post.content
      resource_type = @step["model"]
      attributes = @step["attributes"].transform_values { |v| WorkflowHelper.get_value(@payload, v) }
  
      CreateResource.new(data: {
        insert_type: "base_model",
        resource_type: resource_type,
        resource: resource,
        definition: { attributes: attributes }
      }).tap do |event|
        Rails.configuration.event_store.publish(event)
      end
    end
  end