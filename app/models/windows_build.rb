class WindowsBuild < ActiveRecord::Base

  Paperclip.interpolates :file_path_location do |attachment, style|
    @institution = attachment.instance.institution_id
    @id = attachment.instance.id
    "windows_apps/#{@institution}/#{@id}/:basename" + ".:extension"
  end


  has_attached_file :attachment,
                    :url=>":file_path_location",
                    :path => ":rails_root/:file_path_location"

  validates_attachment_presence :attachment
  validates_format_of :attachment_file_name, :with => %r{\.(exe)$}i
  validates :version, :uniqueness => {:scope => :academic_class_id}
  validates_presence_of :institution_id,:center_id,:academic_class_id

end
