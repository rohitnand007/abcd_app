class VdoUpload < ActiveRecord::Base
  has_attached_file :attachment
  serialize :files_status
  validates_attachment_presence :attachment, :path => ":rails_root/public/system/:class/:attachment/:id/:filename"
  # validates_attachment_content_type :attachment,
  #                                   :content_type => ["application/zip", "application/x-zip", "application/x-zip-compressed"]
                                                      
  before_create :set_defaults
  # after_create :extract_package

  #package_status : Uploaded, Extracted, Unsupported Content, CSV Checked, Partially approved, All approved
  #files_status : Tag is not present, Ok, Approved
  def set_defaults
  	self.package_status = "Uploaded"
  end

  def extract_package
    if self.package_status != "Uploaded"
      return #already extracted
    end
	  package_path = self.attachment.path.split("/")
	  package_path.pop
	  parent_dir = package_path.join("/")
	  begin
	      if(File.extname(self.attachment.path) == ".zip")
	        Zip::ZipFile.open(self.attachment.path) { |zip_file|
	          zip_file.each { |f|
	            f_path=File.join("#{parent_dir}"+"_extract", f.name)
	            FileUtils.mkdir_p(File.dirname(f_path))
	              zip_file.extract(f, f_path) unless File.exist?(f_path)
	          }
	        }
	      end
	      self.package_status = "Extracted"
	      self.save
	  rescue Exception => e
	    logger.info "Exception while extracting vdo_upload is #{e}"
	  end
  end

  def update_csv(asset_name, tags)
  	csv_file_path = get_csv_file_path
  	prev_data = CSV.read(csv_file_path)
  	CSV.open(csv_file_path, "wb") do |csv|
  		prev_data.each do |d|
  			if d[2] == asset_name
  				d[3] = tags["academic_class"]
  				d[4] = tags["subject"]
  				d[5] = tags["concept"]
  			end
  			csv << d
  		end
  	end
  	self.update_package_status
  end

  def get_asset_info(asset_name)
  	#returs hash {asset_name , file_name, tag, academic_class, subject, status}
  	dir_path = self.get_extract_dir_path
  	csv_files = Dir[dir_path + "*.csv"]
  	csv_path = csv_files[0]
  	asset_info = Hash.new
  	CSV.foreach(csv_path, :headers => true, :col_sep => ',') do |row|
  		#columns: 0:S.No, 1:file_name, 2:asset_name, 3:academic_class, 4:subject, 5:concept_name
  		if row[2] == asset_name
  			asset_info["s_no"] = row[0]
  			asset_info["file_name"] = row[1]
  			asset_info["asset_name"] = row[2]
  			asset_info["academic_class"] = row[3]
  			asset_info["subject"] = row[4]
  			asset_info["concept"] = row[5]
  			asset_info["status"] = self.files_status[asset_name]
  		end
  	end
  	return asset_info
  end

  def get_assets_list(get_file_names=false)
  	dir_path = self.get_extract_dir_path
  	csv_files = Dir[dir_path + "*.csv"]
  	csv_path = csv_files[0]
  	assets_list = Array.new
  	CSV.foreach(csv_path, :headers => true, :col_sep => ',') do |row|
  		#columns: 0:S.No, 1:file_name, 2:asset_name, 3:academic_class, 4:subject, 5:concept_name
      if get_file_names
        assets_list << row[1]
      else
  		  assets_list << row[2]
      end
  	end
  	return assets_list
  end

  def approve_asset(asset_name, request_base_url)
  	#if asset already approved ignore
    logger.info "Request Url: #{request_base_url}"
  	if self.files_status[asset_name] == "Approved"
  		return
  	end
		csv_file_path = self.get_csv_file_path
		file_name = ""
		tags = Hash.new
		CSV.foreach(csv_file_path, :headers => true, :col_sep => ',') do |row|
			#columns: 0:S.No, 1:file_name, 2:asset_name, 3:academic_class, 4:subject, 5:concept_name
			if row[2] == asset_name
				file_name = row[1]
				tags["academic_class"] = row[3]
				tags["subject"] = row[4]
				concepts = Array.new
				concepts << row[5]
				tags["concept_names"] = concepts
				break
			end
		end
		asset_file_path = self.get_asset_file_path(file_name)
		logger.info asset_file_path
		self.update_files_status(asset_name)
		if self.files_status[asset_name] == "OK"
			begin
				user_asset = UserAsset.new
	      user_asset.attachment = File.open(asset_file_path)
	      user_asset.user_id = self.user_id
	      user_asset.guid = self.generate_guid
	      user_asset.asset_name = asset_name
				if File.extname(asset_file_path) == ".pdf"
					user_asset.asset_type = "pdf"
				elsif File.extname(asset_file_path) == ".mp4"
		      user_asset.asset_type = "mp4"
		    end
	      if user_asset.save
	        user_asset.extract_encrypt_and_zip
	        user_asset.add_tags(tags["academic_class"], tags["subject"], tags["concept_names"])
	        user_asset.upload_attachment_to_vdo_cipher(request_base_url) if user_asset.asset_type == "mp4"
	        logger.info "Asset Uploaded"
	        self.files_status[asset_name] = "Approved"
	        self.save
	      else
	        logger.info user_asset.errors.messages
	        notice_message = "Error while uploading. Please check #{file_name} and its info in csv."
	      end
	    rescue Exception => e 
	    	logger.info "Exception : #{e}"
	    end
		end
		#update_package status
		self.update_package_status
  end

  def update_files_status(asset_name)
  	if self.files_status.present? && self.files_status[asset_name] == "Approved"
  		return
  	end
  	#by checking the info from csv
  	tags_db = UsersTagsDb.find_by_user_id(self.user_id).tags_db
  	ac_tags = tags_db.tags.where(standard: true, name: "academic_class").map(&:value).map!{|t| t.downcase}
  	su_tags = tags_db.tags.where(standard: true, name: "subject").map(&:value).map!{|t| t.downcase}
  	co_tags = tags_db.tags.where(standard: true, name: "concept_name").map(&:value).map!{|t| t.downcase}
  	csv_path = self.get_csv_file_path
  	prev_status = self.files_status
  	prev_status = Hash.new if prev_status.nil?
  	CSV.foreach(csv_path, :headers => true, :col_sep => ',') do |row|
  		#columns: 0:S.No, 1:file_name, 2:asset_name, 3:academic_class, 4:subject, 5:concept_name
  		if row[2] == asset_name
  			status_info = ""
  			ac_present = ac_tags.include? row[3].downcase
  			su_present = su_tags.include? row[4].downcase
  			co_present = co_tags.include? row[5].downcase
  			if ac_present && su_present && co_present
  				status_info = "OK"
  			else
  				status_info += "Academic Class tag #{row[3]} is not present. " if !ac_present
  				status_info += "Subject tag #{row[4]} is not present. " if !su_present
  				status_info += "Concept tag #{row[5]} is not present. " if !co_present
  			end
  			# files_status = Hash.new
  			# files_status = self.files_status if self.files_status.present?
  			prev_status[asset_name] = status_info
  			self.files_status = prev_status
  			self.save
  			break
  		end
  	end
  end

  def update_all_files_status
  	assets_list = self.get_assets_list
  	assets_list.each {|a| self.update_files_status(a)}
  end

  def update_package_status
  	if self.package_status == "All Approved"
  		return
  	end
  	self.extract_package
  	self.update_all_files_status
  	assets_list = self.get_assets_list
  	partially_appoved = false
  	total_approved = 0
  	assets_list.each do |a|
  		if self.files_status[a] == "Approved"
  			partially_appoved = true
  			total_approved += 1
  		end
  	end
  	if assets_list.count == total_approved
  		self.update_attribute('package_status', 'All Approved')
  		self.delete_package_and_extracted_files
  	elsif partially_appoved
  		self.update_attribute('package_status', 'Partially Approved')
  	else
  		self.update_attribute('package_status', 'Extracted')
  	end
  end

  def delete_package_and_extracted_files
  end

  def get_extract_dir_path
  	package_path = self.attachment.path
    dir_path = package_path.split("/")
    file_name = dir_path.pop
    return dir_path.join("/")+"_extract/"
  end

  def get_csv_file_path
  	dir_path = self.get_extract_dir_path
  	csv_files = Dir[dir_path + "*.csv"]
  	csv_path = csv_files[0]
  	return csv_path
  end

  def get_asset_file_path(file_name)
  	dir_path = self.get_extract_dir_path
  	return dir_path + file_name
  end

  def generate_guid
  	SecureRandom.uuid
  end

  def verify_package
    #after extraction
    #check if files format is pdf, mp4 or csv
    unsupported_files = []
    all_file_names = []
    file_path = self.get_extract_dir_path
    #validate files present are only pdf, mp4 and one csv
    Dir[file_path + '*.*'].each do |file|
      unless File.extname(file) == ".mp4" || File.extname(file) == ".pdf" || File.extname(file) == ".csv"
        unsupported_files << File.basename(file)
      end
      all_file_names << File.basename(file) if File.extname(file)!=".csv"
    end
    if !unsupported_files.empty?
      message = "Unsupported file format for files: #{unsupported_files.join(',')}"
      return {status: "Unsupported files present.", message: message}
    end
    #validate presence of one csv
    csv_files = Dir[file_path+'*.csv']
    if csv_files.count != 1
      message = "Make sure that one csv is present."
      return {status: "CSV count error", message: message}
    end
    #validate equivalence of files present and file names in csv
    all_file_names_from_csv = self.get_assets_list(true)
    if all_file_names_from_csv.sort != all_file_names.sort
      message = "Make sure that file names in csv are consistent with files present."
      return {status: "Invalid Package", message: message}
    end
    #valid package
    message = "Package Uploaded Successfully."
    return {status: "Valid Package", message: message}
  end
end