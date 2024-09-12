class Post < ApplicationRecord
  after_create :log_creation
  after_update :log_update
  after_destroy :log_deletion
end
