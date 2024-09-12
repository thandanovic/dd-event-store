class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class



  


  def log_creation
    ResourceCreated.new(data: { resource_type: self.class.name,resource: self.to_json }).tap do |event|
      Rails.configuration.event_store.publish(event)
      Rails.logger.info(event)
    end
  end

  def log_update
    ResourceUpdated.new(data: { resource_type: self.class.name, resource: self.to_json }).tap do |event|
      Rails.configuration.event_store.publish(event)
      Rails.logger.info(event)
    end
  end

  def log_deletion
    ResourceDeleted.new(data: { resource_type: self.class.name, resource: self.to_json }).tap do |event|
      Rails.configuration.event_store.publish(event)
      Rails.logger.info(event)
    end
  end
end
