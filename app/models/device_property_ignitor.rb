class DevicePropertyIgnitor < ActiveRecord::Base
  #validates_uniqueness_of :mac_id
  has_one :user_device_powerchip
end
