class EbuildApp < ActiveRecord::Base
  require 'ruby_apk'
  require 'nokogiri'

  belongs_to :ebuild_tag#, :inverse_of => :ebuild_app

  Paperclip.interpolates :path_location do |attachment, style|
    @institution = attachment.instance.ebuild_tag.institution_id
    @ebuild = attachment.instance.ebuild_tag.ebuild_name
    "edutor_apps/#{@institution}/#{@ebuild}/:id/:basename" + ".:extension"
  end


  has_attached_file :attachment,
                    :url=>"path_location",
                    :path => ":rails_root/:path_location"

  validates_attachment_presence :attachment
  validates_format_of :attachment_file_name, :with => %r{\.(apk)$}i
  validates :package, :uniqueness => {:scope => :ebuild_tag_id}

  validate :check_package



  before_create :set_build_details


  def set_build_details
    @apk = Android::Apk.new(self.attachment.queued_for_write[:original].path)
    @xml_data = Nokogiri::XML(@apk.manifest.to_xml)
    self.package = @xml_data.xpath('manifest').attr('package').value
    self.sharedUserId = @xml_data.xpath('manifest').attr('sharedUserId').value
    self.versionCode = @xml_data.xpath('manifest').attr('versionCode').value
  end

  def check_package
    if !EbuildApp.where(:ebuild_tag_id=>self.id,:package=>self.package).empty?
      errors.add(:base, "You are uploading the multiple apks with same package")
    end
  end



end
