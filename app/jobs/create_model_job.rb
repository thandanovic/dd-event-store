class CreateModelJob < ApplicationJob
  queue_as :default

  def perform(payload)
    Rails.logger.info "CreateModelJob: #{payload}"
  end
end