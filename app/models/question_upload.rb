class QuestionUpload < ActiveRecord::Base

	include Workflow

  workflow_column :package_status
  workflow do
    state :uploaded do
    	event :error_in_doc, :transitions_to => :rejected
      event :send_to_windows_server, :transitions_to => :awaiting_from_windows_server
      event :failed_to_send_to_windows_server, :transition_to => :windows_server_error
    end
    state :awaiting_from_windows_server do
      event :error_in_doc, :transitions_to => :rejected
      event :converted_to_etx, :transitions_to => :extract_and_send_to_delayed_job
    end
    state :extract_and_send_to_delayed_job do 
    	event :added_to_delayed_job, :transitions_to => :queued_in_delayed_job
    end
    state :queued_in_delayed_job do 
    	event :started, :transitions_to => :processing_in_delayed_job
    end
    state :processing_in_delayed_job do 
    	event :error_in_etx, :transitions_to => :etx_error 
    	event :successfully_processed, :transitions_to => :finished_delayed_job
    end
    state :finished_delayed_job do 
    	event :start_approving, :transitions_to => :partially_approved
    end
    state :partially_approved do 
    	event :update_question, :transitions_to => :partially_approved
    	event :approve_question, :transitions_to => :partially_approved
    	event :remove_question, :transitions_to => :partially_approved
    	event :finished, :transitions_to => :all_approved
    end
    state :all_approved
    state :rejected
    state :windows_server_error
    state :etx_error
  end

	belongs_to :user
	belongs_to :publisher_question_bank
	has_one :question_zip_upload
	has_one :zip_upload, :through => :question_zip_upload
	serialize :questions_status
	has_attached_file :attachment, :path => ":rails_root/public/system/:class/:attachment/:id/:filename"
	has_attached_file :converted_attachment, :path => ":rails_root/public/system/:class/:attachment/:id/converted.zip"
	attr_accessible :package_status, :name, :questions_status, :user_id, :attachment, :converted_attachment, :etx_download_link, :publisher_question_bank_id
	validates_attachment_presence :attachment
	validates_presence_of :name, :user_id, :guid
	validate :attachment_type_by_extension

	before_create :set_defaults
	after_create :extract

	#-----------------------------------------------------------------------------------------
	# Package Status
		# Uploaded
		# Sent to windows server
		# Recived from windows server
		# Error in doc
		# Sent to delayed Job
		# Finished delayed Job
		# Partially Approved
		# All Approved
	# -----------------------------------------------------------------------------------------------

	# --------------------------------------------------------------------------------------------
	# questions_status
		# question_ids: []
		# For each question
			# Invalid:
				# Tags not present (Question is in Hidden mode)
			# Valid:
				# Hidden
				# Approved
		# 

	# --------------------------------------------------------------------------------------------

	# do not show tags: qsubtype
	# do not update tags: qsubtype, chapter

	def set_defaults

	end

	def extract

	end

	def attachment_type_by_extension

	end

	def send_to_windows_server_to_convert(portal_domain)
	# upload_url = request_base_url+ "/user_assets/#{self.id}/download_asset/video.mp4"
  #   # upload_url = "http://testing2.myedutor.com/message_download/182430/2237/1435671169/2-2-1.mp4"
  #   url = URI.parse("http://api.vdocipher.com/v2/importURL?url=#{upload_url}")
  #   req = Net::HTTP::Post.new(url.to_s)
  #   req.body = 'clientSecretKey=' + $vdo_cipher_key
  #   res = Net::HTTP.start(url.host, url.port, use_ssl:false) {|http|http.request(req)}
  #   otp = JSON.parse(res.body)
  #   self.vdocipher_id = otp['id']
  #   self.save
  begin
	  # url = URI.parse('https://localhost:3000/question_uploads/test_windows')
	  url = URI.parse($windows_server +  '/send_docs_download_link')
	  req = Net::HTTP::Post.new(url.to_s, initheader = {'Content-Type' =>'application/json'})
	  req.body = {gid: self.guid, download_link: portal_domain + "/question_uploads/#{self.guid}/download_attachment"}.to_json
	  res = Net::HTTP.start(url.hostname, url.port) { |http| http.request(req) }
	  self.send_to_windows_server!
	 rescue Exception => e
	 	logger.info "Exception in while sending it to windows server....#{e.message}"
	 	self.failed_to_send_to_windows_server!
	 end
	end

	def delete_etx_in_windows_server(portal_domain)
	  url = URI.parse('https://localhost:3000/question_uploads/test_windows')
	  # url = URI.parse($windows_server +  '/delete_etx')
	  req = Net::HTTP::Post.new(url.to_s, initheader = {'Content-Type' =>'application/json'})
	  req.body = {gid: self.guid}.to_json
	  res = Net::HTTP.start(url.hostname, url.port) { |http| http.request(req) }
	end

	def download_etx_from_windows_server
		download_link = $windows_server + self.etx_download_link
		# download_link = "http://localhost:3000/question_uploads/#{self.guid}/download_attachment"
		tmp_file_path = "#{Rails.root.to_s}/tmp/etx_zip_#{Time.now.to_i}.docx"
		File.open(tmp_file_path, "wb") do |file|
		  open(download_link, "rb") do |read_file|
		   	file.write(read_file.read)
		  end
		end
		self.converted_attachment = File.open(tmp_file_path)
		# self.converted_to_etx!
		self.save
	end

	def init_status_after_etx_download
		# return false if !self.converted_attachment.present?
		create_zip_upload
		extract_zip_and_create_questions
		init_questions_status
	end

	def create_zip_upload

		self.update_attribute('package_status', 'partially_approved')
		self.save
		# Only after coverted attachment is available
		file_path = self.converted_attachment.path
		# file_path = "/home/krishna/Desktop/questions_zip.zip"
		zip_upload = ZipUpload.new
		zip_upload.asset = File.open(file_path)
		if zip_upload.save
			self.zip_upload = zip_upload
		else
			false
		end
	end

	def extract_zip_and_create_questions
		if !self.zip_upload.present?
			return false
		end
		question_bank = self.publisher_question_bank

		zip_upload = self.zip_upload
		file_name = zip_upload.asset_file_name
    full_file_name = zip_upload.asset.path
    dir = zip_upload.asset.path.gsub("/#{zip_upload.asset_file_name}", "")
    Archive::Zip.extract(full_file_name, dir)
    destfile="#{Rails.root.to_s}"+"/public"+"/question_images"
    FileUtils.cp_r Dir[dir+"/*"], destfile
    if (Dir[dir+"/"+'/*.etx'])!=[]
      Dir[dir+"/"+'/*.etx'].each do |etxfile|
        etx_file = zip_upload.etx_files.create(:filename => etxfile)
        zip_upload.process_etx etx_file.filename, self.user_id, question_bank.id, true
      end
    end
	end

	def get_question_ids_from_etx
		question_ids = []
		# return if not in desired state
		return question_ids if self.current_state < :partially_approved
		self.zip_upload.etx_files.each do |etx_file|
			q_no = []
			q_no = etx_file.ques_no.split(",") if etx_file.ques_no.present?
			question_ids += q_no 
		end
		question_ids
	end

	def get_question_status(q_id)
		tags_db = User.find(self.user_id).tags_db
		return "Tags DB not assigned." if !tags_db.present?
		return "Approved" if self.questions_status["#{q_id}"] == "Approved"
		status = ""
		valid_tags = Hash.new
		valid_tags['academic_class'] = tags_db.tags.s_class.map(&:value)
		valid_tags['subject'] = tags_db.tags.s_subject.map(&:value)
		valid_tags['concept_names'] = tags_db.tags.s_concept.map(&:value)
		valid_tags['chapter'] = []
		valid_tags['difficulty_level'] = []
		valid_tags['blooms_taxonomy'] = []
		valid_tags['specialCategory'] = []
		valid_tags['qsubtype'] = []
		tag_categories = ['academic_class', 'subject', 'concept_names']#, 'chapter', 'difficulty_level', 'blooms_taxonomy', 'specialCategory', 'qsubtype']
	  # GroupCode = HashWithIndifferentAccess.new({"academic_class" => "ac", "subject" => "su",
	  #                                            "chapter" => "ch", "concept_names" => "co",
	  #                                            "difficulty_level" => "dl", "blooms_taxonomy" => "bl",
	  #                                            "specialCategory" => "sc", "qsubtype" => "ty"})
	  question_tags = Question.find(q_id).tags
	  tag_categories.each do |tag_c|
	  	if (tags=question_tags.where(name: tag_c)).present? && !(valid_tags[tag_c].include? tags.first.value)
	  		status += " #{tag_c} tag #{tags.first.value} is not present "
	  	end
	  end
	  if !status.present?
	  	status = Question.find(q_id).hidden ? "OK" : "Approved"
	  end
	  return status

	end

	def init_questions_status
		return false if self.current_state < :finished_delayed_job
		question_ids = get_question_ids_from_etx 
		data = Hash.new
		data['question_ids'] = question_ids
		question_ids.each do |q_id|
			data[q_id] = ""
		end
		data['total_approved'] = 0
		self.questions_status = data
		self.save

		data = Hash.new
		data['question_ids'] = question_ids
		question_ids.each do |q_id|
			data[q_id] = get_question_status q_id
		end
		data['total_approved'] = 0
		self.questions_status = data
		self.save
	end

	def update_question_tags_and_status(question_id, new_tags)
		# new tags = [ {'name' => 'value'},..]
		question = Question.find(question_id)
		old_tags = question.tags
		logger.info "New Tags: #{new_tags}"
		logger.info "Old Tags: #{old_tags}"
		old_tags.each {|tag| question.remove_tag(tag.name, tag.value) if tag.name != "chapter" }
		new_tags.each {|tag| question.add_tags(tag['name'], tag['value'])}
		update_question_status(question_id)
	end

	def update_question_status(question_id)
		status = get_question_status(question_id)
		self.questions_status["#{question_id}"] = status
		self.save
	end

	def approve_question_id(question_id)
		q_status = get_question_status(question_id)
		if q_status == "OK"
			question = Question.find(question_id)
			question.update_attribute("hidden", false)
			question.update_redis_server_after_question_creation
			self.questions_status["#{question_id}"] = "Approved"
			self.approve_question!
			self.questions_status['total_approved'] += 1
			self.save
			reevaluate_package_status
			return true
		end
		return false
	end

	def reevaluate_package_status
		return false if self.current_state != :partially_approved
		question_ids = self.questions_status['question_ids']
		total_approved = 0
		question_ids.each do |question_id|
			update_question_status(question_id)
			total_approved += 1 if self.questions_status["#{question_id}"] == "Approved"
		end
		self.questions_status['total_approved'] = total_approved
		self.save
		if question_ids.count == total_approved
			# self.package_status = "All Approved"
			self.finished!
			# self.save
		end
		return true
	end
end
