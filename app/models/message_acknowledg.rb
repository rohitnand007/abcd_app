class MessageAcknowledg < ActiveRecord::Base
  belongs_to :message
  belongs_to :device_message
  belongs_to :user
end
