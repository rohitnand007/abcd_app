class UserDevice < ActiveRecord::Base
  belongs_to :user
  belongs_to :teacher
  belongs_to :device
  attr_accessible :user_id, :device_id
end
