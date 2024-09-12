class WorkflowExecution < ApplicationRecord
  belongs_to :workflow

  enum status: { not_started: 'not_started', in_progress: 'in_progress', success: 'success', failed: 'failed' }

  validates :status, presence: true
 
  

  private

  # Ensure that `workflow_event_store_id` is present if the execution has completed or failed
  def completed_or_failed?
    success? || failed?
  end
end