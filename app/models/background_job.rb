class BackgroundJob < ActiveRecord::Base
  belongs_to :scheduled_task, :polymorphic => true
  belongs_to :recipient, :polymorphic => true
end
