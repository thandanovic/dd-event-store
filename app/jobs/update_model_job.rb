class UpdateModelJob < ApplicationJob
  queue_as :default

  def perform(payload)
    Rails.logger.info "UpdateModelJob: #{payload}"
  end
end