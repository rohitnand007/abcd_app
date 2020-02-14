class LearningActivity < ActiveRecord::Base
  serialize :data
  has_many :tag_mappings, :as => :taggable
  has_many :tags, :through => :tag_mappings


  def download_package
    learning_type = learning_activity_type
    template_zipfile = Rails.root.to_s+"/app/views/learning_activities/play_#{learning_type}.zip"
    dirname = Rails.root.to_s+"/public/learning_activities/data_files"
    download_zipfile = Rails.root.to_s+"/public/learning_activities/data_files/#{learning_type}_#{id.to_s}_#{Time.now.to_i.to_s}.zip"
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    FileUtils.cp_r(template_zipfile, download_zipfile)
    datafile = Tempfile.new(['json','.js'])
    datafile.write("var jsonData = "+self.data.to_json)
    datafile.rewind
    datafile.close
    Zip::ZipFile.open(download_zipfile, 'w') do |zip|
      zip.remove("play_#{learning_type}/js/json.js")
      zip.add("play_#{learning_type}/js/json.js",datafile)
      self.activity_images.each do |image|
        zip.add("play_#{learning_type}/json_images/#{image.attachment_file_name}",image.attachment.path)
      end
    end
    datafile.delete
    FileUtils.chmod 0644, download_zipfile
    return download_zipfile
  end


  def activity_images
    Image.find_all_by_attachment_file_name(data["images"])
  end

end
