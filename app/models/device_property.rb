class DeviceProperty < ActiveRecord::Base
  validates_uniqueness_of :imei, :mac_id
  has_one :user_device_powerchip
end
