class CreateWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_executions do |t|
      t.references :workflow, foreign_key: true, null: false # Reference to the workflow
      t.string :status, null: false, default: 'new'  # Status of the workflow execution
      t.text :error_message                                 # Error message if the workflow failed
      t.string :workflow_event_store_id                    # ID for tracking the workflow event store
      t.string :last_event_handler                          # The last event handler executed

      t.timestamps
    end
  end
end
