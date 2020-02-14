class CdnUser < User

  has_many :user_devices, :foreign_key => :user_id
  has_many :devices, :through => :user_devices
  has_one :cdn_config, :foreign_key => :user_id


end