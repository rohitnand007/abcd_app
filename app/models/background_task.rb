class BackgroundTask < ActiveRecord::Base
  belongs_to :parent_obj, :polymorphic => true
end
