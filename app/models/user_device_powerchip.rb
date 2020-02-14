class UserDevicePowerchip < ActiveRecord::Base
  belongs_to:powerchip
  belongs_to:user
  belongs_to:device
  belongs_to:device_property
  #validates_uniquiness_of :powerchip_id,:user_id
end
