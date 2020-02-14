class Powerchip < ActiveRecord::Base
  validates_uniqueness_of :cid#, :serial
  has_one :user_device_powerchip, :dependent => :destroy
end
