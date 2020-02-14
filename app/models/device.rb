class Device < ActiveRecord::Base
  scope :by_device_id, lambda{|device_id|
    where('deviceid like ?', device_id)
  }
  scope :by_device_or_mac_or_android_id, lambda{|id|
    where('deviceid like ? or mac_id like ? or android_id like ?', id,id,id)
  }
  belongs_to :ebuild_tag
  has_many :user_devices, :dependent=>:destroy
  has_many :users, :through => :user_devices
  has_many :teachers, :through => :user_devices
  has_many :power_chips, :primary_key => 'deviceid'
  belongs_to :institution,:foreign_key => 'institution_id'
  belongs_to :center,:foreign_key => 'center_id'
  has_many :device_messages, :primary_key=>'deviceid',:foreign_key=>"deviceid"

  attr_accessible :user_name,:model,:deviceid,:status,:device_type,:institution_id,:center_id,:user_ids,:android_id,:mac_id

  validates_presence_of :deviceid
  validates_uniqueness_of :deviceid,:mac_id


  DEVICE_TYPES = ["Primary",""]
  DEVICE_STATUS = ["Assigned","Repair","Deleted"]

  after_initialize :set_status_default_value

  before_create :set_defaults
  after_save :remove_user_devices,:if=>Proc.new{|device| device.status.eql?DEVICE_STATUS[2]}
  #after_create :set_device_id

  def set_defaults
    #for default institution and center
    if self.institution_id.nil? and self.center_id.nil?
      self.institution_id = 4
      self.center_id = 6
    end
  end

  def set_device_id
    #for generating device id on creation if nil
    update_attribute(:deviceid,"EDDID"+"-%05d"%id) if self.deviceid.blank? or self.deviceid.nil?
  end

  def user_name=(user_name)
    user = Profile.find_by_surname(user_name)
    if user
      self.user_id = user.user_id
    else
      errors[:user_name] << "Invalid name entered"
    end
  end

  def user_name
    user.fullname if user
  end

  def remove_user_devices
    #if status is deleted then remove the user devices links
    if self.status.eql?DEVICE_STATUS[2]
      self.user_ids =[]
    end
  end
  #to check whether the mac and android ids of device are nil
  def is_already_reset?
    self.mac_id.nil? and self.android_id.nil?
  end

  private
  def set_status_default_value
   self.status ||= "Assigned"   unless attributes["status"].nil?
   self.device_type ||= 'Primary' unless attributes["device_type"].nil?
  end
end
