require "open-uri"
class Image < ActiveRecord::Base
  has_many :question_images, :foreign_key => "image_id", :dependent => :destroy
  Paperclip.interpolates :image_path_url do |attachment, style|
    #@time = Time.now.to_i.to_s
    #return @time+":basename" + ".:extension"
    return ":basename" + ".:extension"
  end

  Paperclip.interpolates :image_set_attachment_path do |attachment, style|
    # return "#{Rails.root.to_s}/public/concept_images/:image_path_url"
    return "#{Rails.root.to_s}/public/question_images/:image_path_url"
  end

  has_attached_file :attachment,
                    :url => ":image_path_url",
                    :path => ":image_set_attachment_path"
  #validates_asset_content_type :attachment, :content_type => 'application/zip'
  after_create :set_src

  before_create :randomize_file_name

  def set_src
    url = self.attachment.path.split("?")[0].to_s.gsub(Rails.root.to_s+"/public","")
    update_attribute(:src,url.split("?")[0].to_s)
  end

  def image_from_url(url)
    self.attachment = open(url)
  end

  def randomize_file_name
    extension = File.extname(attachment_file_name).downcase
    self.attachment.instance_write(:file_name, "image_#{SecureRandom.uuid}#{extension}")
  end
end
