class Masterchip < ActiveRecord::Base
  has_one :masterchip_details, :dependent => :destroy
  has_one :asset, :as => :archive, :dependent => :destroy
  before_create :set_masterchip_id
  validates_uniqueness_of :cid, :serial

  before_destroy :unlink_powerchips

  belongs_to :chip_fs_info

  accepts_nested_attributes_for :asset, :allow_destroy=>true, :reject_if => :all_blank


  def set_masterchip_id
 #   require 'digest/md5'
  #  digest = Digest::MD5.hexdigest(self.cid+self.serial)
  #  update_attribute(:issue_id,digest)
   self.issue_id = loop do
      random_key = SecureRandom.hex(4)
      break random_key unless Masterchip.exists?(issue_id: random_key)
    end
  end

  def unlink_powerchips
    Powerchip.where(:masterchip_id=>self.issue_id).update_all(:masterchip_id=>nil)
  end

end
