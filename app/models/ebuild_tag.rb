class EbuildTag < ActiveRecord::Base
  belongs_to :institution
  has_one :device
  has_many :ebuild_apps,:dependent=>:destroy
  has_many :ebuild_publish ,:dependent=>:destroy,:foreign_key => :publish_ebuild_tag_id
  has_many :ebuild_publish_new, :class_name => :ebuild_tag
  validates_presence_of :ebuild_name,:institution_id

  accepts_nested_attributes_for :ebuild_apps, :allow_destroy=>true,:reject_if => :all_blank
  accepts_nested_attributes_for :ebuild_publish, :allow_destroy=>true, :reject_if => :all_blank

  validates_presence_of :ebuild_name, :institution_id
  validates_uniqueness_of :ebuild_name
  validate :require_ebuild_apks

  #private
  def require_ebuild_apks
    errors.add(:base, "You must provide at least one apk") if ebuild_apps.empty?
    errors.add(:base, "You must select the group") if ebuild_publish.empty?
  end

end
