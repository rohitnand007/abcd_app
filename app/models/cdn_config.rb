class CdnConfig < ActiveRecord::Base
  belongs_to :cdn_user, :foreign_key => :user_id

  has_many :cdn_centers

  has_many :centers, :through=>:cdn_centers

  accepts_nested_attributes_for :cdn_centers, :allow_destroy=>true, :reject_if => :all_blank
  
  after_create :set_cdn_user

  def set_cdn_user
    cdn_user = CdnUser.new
    cdn_user.email = "cdn_"+Time.now.to_i.to_s+"@"+self.id.to_s+"abcde.com"
    # cdn_user.role_id = 18
    password = SecureRandom.hex(3)
    cdn_user.password = password
    cdn_user.plain_password = password
    cdn_user.is_activated=true
    cdn_user.is_group=false
    cdn_user.save
    cdn_user.create_profile(:firstname=>"cdn-"+self.cdn_name,:user_id=>cdn_user.id)
    cdn_user.devices.create(:deviceid=>'CDN'+SecureRandom.hex(5),:mac_id=>SecureRandom.hex(5))
    self.update_attribute(:user_id,cdn_user.id)
  end

end
