class CreateWorkflows < ActiveRecord::Migration[7.1]
  def change
    create_table :workflows do |t|
      t.json :definition, null: false  # Store the workflow definition as a JSON column
      t.boolean :active, default: true # Flag to indicate if the workflow is active
      t.timestamps
    end
  end
end
