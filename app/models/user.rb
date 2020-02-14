class User < ActiveRecord::Base
  scope :students, :conditions=>{:type=>'Student'}
  scope :students_enrolled, :conditions=>{:type=>'Student',:is_enrolled=>true}
  scope :students_activated, :conditions=>{:type=>'Student',:is_activated=>true}
  scope :students_de_enrolled, :conditions=>{:type=>'Student',:is_enrolled=>false}

  scope :search_select, select('id,email,rollno,academic_class_id,section_id,is_enrolled,edutorid,last_sign_in_at,sign_in_count,school_uid,is_activated,rc')
  scope :search_includes, includes([{:academic_class=>:profile},{:section=>:profile},:profile,:devices])

  scope :by_profile_first_name, lambda{|term|
                                includes(:profile).where('profiles.firstname like ?',term)
                              }

  scope :by_profile_first_name_or_surname_or_roll_no_or_edutor_id, lambda{|term|
                                                                   includes(:profile).where('profiles.firstname like ? or profiles.surname like? or users.rollno like ? or users.edutorid like ?',term,term,term,term)
                                                                 }

  composed_of :date_of_birth,:class_name => 'Date',:mapping => %w(date_of_birth to_datetime),:constructor => Proc.new{ |item| item },:converter => Proc.new{ |item| item }

  include CsvMapper
  include Overrides

  #SHORT_ROLES = [nil,"EA","IA","CR","ES","ET","EP","EST","SG","CLG","SEG","IG","CG","PT","PR","ECP"]
  SHORT_ROLES = [nil, "EA", "IA", "CR", "ES", "ET", "EP", "EST", "ECT", "SG", "CLG", "SEG", "IG", "CG", "PT", "PR", "ECP", "ESC", "CDN", "STA","MOE","EO"] #added nil since the roles are changed
  ROLES = {"EdutorAdmin"=>"EA","Student"=>"ES", "Publisher"=>"ECP", "Institution"=>"IG", "InstituteAdmin"=>"IA", "Center"=>"CG", "CenterAdmin"=>"CR", "AcademicClass"=>"CLG", "Section"=>"SEG", "Teacher"=>"ET", "StudentGroup"=>"SG", "Moe"=>"MOE", "CdnUser"=>"CDN", "EducationOfficer"=>"EO"}

  belongs_to :institute_admin
  belongs_to :center_admin
  belongs_to :institution
  belongs_to :center
  #belongs_to :device
  belongs_to :academic_class
  belongs_to :section
  belongs_to :teacher
  has_many :student_group_owners, :dependent => :destroy
  has_many :student_groups, :through=> :student_group_owners

  belongs_to :role
  has_one :profile
  has_many :assessment_pdf_jobs, :as => :recipient
  has_many :message_user_downloads
  has_many :quiz_question_attempts
  has_many :user_devices, :uniq => true
  has_many :devices, :through => :user_devices, :uniq => true

  has_many :user_groups, :dependent => :destroy
  has_many :groups,:through => :user_groups  , :dependent => :destroy
  has_many :inverse_user_groups, :class_name=>'UserGroup', :foreign_key=>'group_id'
  has_many :inverse_groups,:through => :inverse_user_groups, :source => :user
  has_many :class_rooms,:through => :user_groups

  has_many :message_acknowledgs, :dependent => :destroy
  has_many :sent_messages,:class_name=>"Message",:foreign_key =>'sender_id'
  has_many :individual_inbox_control_messages,:class_name=>"Message",:foreign_key => 'recipient_id',:conditions=>['message_type=?',"Control Message"]
  has_many :test_results
  has_many :usages
  has_many :analytics_usages
  has_and_belongs_to_many :boards
  has_and_belongs_to_many :license_sets
  has_many :assets, :foreign_key => 'publisher_id'
  #has_many :assessments,:through=>:assets,:source=>:user, :foreign_key => 'publisher_id'
  has_many :assessment_categories,:through=>:assets,:source=>:user, :foreign_key => 'publisher_id'

  has_many :contents,:through=>:assets, :foreign_key => 'publisher_id'
  has_many :test_configurations,:through => :user_groups
  has_many :test_results

  has_one :user_key

  has_many :user_content_keys

  has_many :user_activities

  has_many :user_usages

  has_many :user_quotes

  has_many :quotes, :through => :user_quotes

  has_many :book_collections

  has_many :collections, :through=> :book_collections

  has_many :books, :through=> :collections

  has_many :user_books

  has_many :user_book_collection

  has_many :user_assets

  #has_one  :cdn_config

  has_many :ignitor_user_chips

  has_many :question_bank_users

  has_many :publisher_question_banks, through: :question_bank_users

  has_many :content_access_permissions

  has_one :user_device_info, :dependent=>:destroy

  #has_many :messages ,:class_name=>"Message",:include=>[:users], :codnitions=>['group_id =? or recipient_id',self.id,self.user_group.group_id]
  #accepts_nested_attributes_for :user_groups, :allow_destroy=>true, :reject_if => :all_blank
  accepts_nested_attributes_for :profile, :allow_destroy=>true, :reject_if => :all_blank

  accepts_nested_attributes_for :devices, :allow_destroy=>true,:reject_if => lambda { |d| d[:deviceid].blank? }



  #validates :role_id,:presence => :true,:if=>Proc.new{|user| user.class==User }
  validates_uniqueness_of :edutorid
  # validates_format_of :rollno ,:with=>/^[0-9a-zA-Z]+$/ ,:allow_blank=>true

  def check_child?
    ["AcademicClass", "Center", "CenterAdmin", "InstituteAdmin", "Institution", "Publisher", "Section", "StudentGroup", "Teacher", "CdnUser", "Moe"].include? self.type
  end

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,:token_authenticatable ,
         :recoverable, :rememberable, :trackable, :authentication_keys => [:login]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me , :edutorid,:is_activated,:role_id,:device_id,
                  :institution_id,:center_id,:academic_class_id,:section_id,:rollno,:is_group,:profile_attributes, :group_ids,:plain_password,
                  :devices_attributes, :is_class_teacher,:board_tokens,:date_of_birth,:is_enrolled,:school_uid,:inverse_group_ids,:user_configuration_attributes,:is_printable,:extras,:build_info_attributes,:group_tokens,:rc

  attr_reader :board_tokens,:group_tokens

  attr_accessor :login

  def login=(login)
    @login = login
  end

  def login
    @login || self.edutorid || self.email || self.rollno
  end

  def board_tokens=(ids)
    self.board_ids = ids.split(",")
  end


  def group_tokens=(ids)
    self.group_ids = ids.split(",")
  end

  after_create :update_edutor_id_and_activate_user
  #after_create :set_password_for_student

  after_save :update_base_groups,:update_class_rooms

  validate :validate_defaults

  after_create :move_device, :if => Proc.new{|user| user.devices.any?}

  before_save :ensure_authentication_token

  def move_device
    self.devices.first.update_attributes(:institution_id=>self.institution_id,:center_id=>self.center_id) if self.devices.any?
  end

  def validate_defaults
    if self.role_id == 4 #ES
      errors.add(:institution_id,"should not be empty.") if self.institution_id.blank? or self.institution_id.nil?
      errors.add(:center_id,"should not be empty.") if self.center_id.blank? or self.center_id.nil?
      errors.add(:academic_class_id,"should not be empty.") if self.academic_class_id.blank? or self.academic_class_id.nil?
      errors.add(:section_id,"should not be empty.") if self.section_id.blank? or self.section_id.nil?
    elsif self.role_id == 2 #IA
      errors.add(:institution_id,"should not be empty.") if self.institution_id.blank? or self.institution_id.nil?
    elsif self.role_id == 3 #CA
      errors.add(:institution_id,"should not be empty.") if self.institution_id.blank? or self.institution_id.nil?
      errors.add(:center_id,"should not be empty.") if self.center_id.blank? or self.center_id.nil?
    elsif  self.role_id == 5 #ET
      errors.add(:institution_id,"should not be empty.") if self.institution_id.blank? or self.institution_id.nil?
      errors.add(:center_id,"should not be empty.") if self.center_id.blank? or self.center_id.nil?
      errors.add(:academic_class_id,"should not be empty.") if self.academic_class_id.blank? or self.academic_class_id.nil?
      errors.add(:section_id,"should not be empty.") if self.section_id.blank? or self.section_id.nil?
    end
  end


  def update_type
    if self.role_id==2
      self.update_attribute(:type,'InstituteAdmin')
    elsif self.role_id==3
      self.update_attribute(:type,'CenterAdmin')
    elsif self.role_id==5
      self.update_attribute(:type,'Teacher')
    elsif self.role_id==16
      self.update_attribute(:type,'Publisher')
    end
  end


  def update_email
    if (self.role_id==4 and (self.email.blank? or self.email.nil?))
      update_attribute(:email, self.edutorid + "@myedutor.com")
    end
  end





  def set_password_for_student
    if self.role_id==4 and self.date_of_birth!= nil and !self.password.present?
      self.password = self.generate_password_by_dob
      self.save
    end
  end

  def update_class_rooms
    #default adding teacher to class room based on the base ac_class and section and subject also selected
    # if self.type.eql?'Teacher' and Teacher.find(self.id).teacher_class_rooms.empty?
    #   ClassRoom.find_or_create_by_teacher_id_and_content_id_and_group_id(self.id,self.section.boards.first.id,self.section.try(:id),:year_id=>self.section.boards.first.id)
    # end
  end

  def update_base_groups
    self.group_ids = (self.group_ids + self.base_groups).uniq
  end

  def date_of_birth
    Time.at(self[:date_of_birth]).to_date  unless self[:date_of_birth].nil?
  end

  def remember_created_at
    (Time.at(self[:remember_created_at]).to_time) unless self[:remember_created_at].nil?
  end

  def update_edutor_id_and_activate_user
    #if role_id.present?
    edutor_id = ROLES[type]+"-%05d"
    update_attributes(:edutorid=>edutor_id% id,:is_activated=>true,:rc=>ROLES[type])
    #update_attribute(:email,self.edutorid+'@myedutor.com') if self.role_id == 4 and self.email.eql?'rotude@myedutor.com'
    #end
  end

  def fullname
    if self.profile
      "#{profile.surname} #{profile.firstname}"
    else
      "#{email}"
    end
  end

  def self.groups
    User.where('is_group is true')
  end

  def received_messages
    Message.find(:conditions=>["recipient_id =? or group_id =?",self.id,self.user_group.group_id])
  end

  def user_group_name
    if self.user_group
      User.find_by_id(self.user_group.group_id).profile.firstname
    end
  end

  #  def update_with_password(params={})
  #    if params[:password].blank?
  #      params.delete(:current_password)
  #      self.update_without_password(params)
  #    else
  #      self.verify_password_and_update(params)
  #    end
  #  end

  #checking the user activity status
  def active_for_authentication?
    super && self.is_activated
  end

  #custom method for checking the user role
  def is?(role)
    role.to_s.eql?ROLES[type]
  end

  #to get crs for Institute Admin and Center
  def self.crs_for_IA_and_Center(institution_id,center_id)
    select('id,edutorid').where('institution_id=? and center_id=? and edutorid like ?',institution_id,center_id,"%CR%")
  end

  #get Institute admin info by instituteid
  def self.edutorid_by_institute(institution_id)
    select('id,institution_id,edutorid').where('institution_id = ? and edutorid like ?',institution_id,"%IA%").first
  end

  #get group user_ids from inst_id and cener
  def self.group_user_ids_by_institute_and_center(institution_id,center_id)
    if !institution_id.nil? and center_id.nil?
      select('id').where('is_group=? and institution_id = ? and edutorid like ?',true,institution_id,"%SG-%")
    elsif institution_id.nil? and !center_id.nil?
      select('id').where('is_group=? and institution_id = ? and edutorid like ?',true,institution_id,"%SG-%")
    else
      select('id').where('is_group=? and institution_id = ? and center_id=? and edutorid like ?',true,institution_id,center_id,"%SG-%")
    end
  end

  def set_IA_defaults_and_create
    self.role_id=2
    self.center_id=0
    self.academic_class_id=0
    self.section_id=0
    self.is_group=true
  end

  def name
    if self.type.eql?'Section'
      self.profile.nil? ? nil : self.academic_class.profile.try(:display_name) + "_" +self.profile.firstname
    else
      self.profile.nil? ? nil : self.profile.display_name
    end
  end

  def section_with_class
    self.profile.nil? ? nil : self.academic_class.name + self.profile.firstname rescue self.profile.firstname
  end

  def section_with_class_and_center
    self.profile.nil? ? nil : self.center.name + "_" + self.section_with_class rescue self.profile.firstname
  end

  def section_with_class_and_center_and_institution
    self.profile.nil? ? nil : self.institution.name + "_" + self.section_with_class_and_center rescue self.profile.firstname
  end

  #base groups are the groups for user where he belongs to inst,cent,class,section and rest like SG's will be stored in user_groups table.
  def base_groups
    [self.institution_id,self.center_id,self.academic_class_id,self.section_id].compact   rescue []
  end

  def base_group_objects
    User.find(self.base_groups) rescue []
  end

  #used to get all subjects for different roles except student
  def class_contents
    return Board.all.map{|board| board.subjects}.uniq.flatten if self.id==1
    case self.type
      when 'Teacher'
        #by default teacher classroom content belongs to board,if it is board we are not showing any content because teacher classroom should be a class-teacher or subject teacher i.e belongs to content-year or subject
        Teacher.find(self.id).teacher_class_rooms.map{|class_room| (class_room.content.type.eql?('Board') ? [] : class_room.content.type.eql?('ContentYear') ? class_room.content.subjects : class_room.content)}.uniq.flatten rescue []
      when 'CenterAdmin'
        self.center.boards.map{|board| board.subjects}.uniq.flatten
      when 'InstituteAdmin'
        self.institution.boards.map{|board| board.subjects}.uniq.flatten
      else
        []
    end
  end

  #used to get all subjects for student through classrooms
  def user_class_contents
    self.class_rooms.group(:content_id).map{|class_room| (class_room.content.type.eql?'Board' or class_room.content.type.eql?'ContentYear') ? class_room.content.subjects : class_room.content}.uniq.flatten
  end

  def self.send_messages(user_ids,sender_id,subject)
    user_ids.each do |user_id|
      if subject.eql?'Enroll' or subject.eql?'De-Enroll' or subject.eql?'Activate' or subject.eql? 'In-Activate'
        check_last_message = Message.find_last_by_recipient_id(user_id)
        if check_last_message.nil?
          Message.create(sender_id: sender_id,recipient_id: user_id,subject: subject,message_type: "Control Message")
        elsif !check_last_message.nil? and !check_last_message.subject.eql?subject
          Message.create(sender_id: sender_id,recipient_id: user_id,subject: subject,message_type: "Control Message")
        end
      else
        Message.create(sender_id: sender_id,recipient_id: user_id,subject: subject,message_type: "Control Message")
      end
    end
  end

  #csv download
  def self.csv_header
    "edutorid,class,section,school_registration_num,name,password".split(",")
  end

  def to_csv
    [edutorid, academic_class.profile.firstname, section.profile.firstname, school_uid, profile.firstname.gsub(" ","-"), "4123"]
  end

  #to get all assessments from teachers classrooms
  def all_assessments
    teacher_class_rooms = case self.type
                            when 'Teacher'
                              self.teacher_class_rooms
                            when 'CenterAdmin'
                              self.center.class_rooms
                            when 'InstituteAdmin'
                              self.institution.class_rooms
                            else
                              []
                          end
    content_ids = teacher_class_rooms.map(&:content_id)
    Content.where('board_id IN (?) or content_year_id IN (?) or subject_id IN (?)',content_ids,content_ids,content_ids).assessment_types
  end

  def get_groups
    case self.type
      when 'Teacher'
        self.sections.select('users.id').map(&:id) + self.student_groups.select('users.id').map(&:id)  + self.my_students.map(&:id)
      #self.groups + self.my_students
      when 'CenterAdmin'
        #self.groups + self.academic_classes + self.sections + self.students
        self.center.try(:inverse_groups).select('users.id').map(&:id)   # to get all the users and groups under center
      when 'InstituteAdmin'
        #self.groups + self.centers + self.academic_classes + self.sections + self.students
        self.institution.try(:inverse_groups).select('users.id').map(&:id) # to get all the users and groups under institution
      else
        []
    end
  end
  #to get the assessments through test configuration groups
  def assessments
    self.all_assessments.joins(:test_configurations).where('test_configurations.group_id IN(?)',get_groups).group('contents.id')
  end

  #get all the test-configs based on current user groups and user assessments (the group_id might contains the user ids also beacause the test config created for individuals too so in get_groups method we are considering the students tooo)
  def test_configurations_by_assessments(assessment_ids)
    #test_config_ids = self.assessments.map{|assessment| assessment.test_configurations.where('group_id IN (?)',self.get_groups).map(&:id)}.flatten!
    TestConfiguration.where(:group_id=>self.get_groups,:content_id=>assessment_ids)
  end

  def ignitor_books
    if self.is? 'IA'
      ids = self.institution.license_sets.collect(&:ipack_id)
    elsif self.is? "CR"
      ids = self.center.license_sets.collect(&:ipack_id)
    elsif self.is? "ECP"
      return self.ibooks.flatten.uniq
    else
      ids = self.license_sets.collect(&:ipack_id)
    end
    @ipacks = Ipack.includes(:ibooks).where(id: ids)
    @books = []
    @ipacks.each do |ipack|
      @books << ipack.ibooks
    end
    @books.flatten.uniq
  end

  def ignitor_packs
    if self.is? "ES" or self.is? "ET"
      @license_sets = self.license_sets.sort_by(&:created_at).reverse
      @license_pack_info = []
      @license_sets.each do |license_pack_info|
        @license_pack_info << {license_set_id:license_pack_info.id,ipack_id:license_pack_info.ipack_id,ipack_name:Ipack.where(id:license_pack_info.ipack_id).first.name,ipack_books:Ipack.where(id:license_pack_info.ipack_id).first.ibooks.collect{|e| e.get_title_and_class }.join('<br />').html_safe}
      end
      return @license_pack_info
    else
      ignitor_books
      # @ipacks = Ipack.where(id: @license_sets)
    end
  end

=begin
      csv header for below methods :published_content_stats, :published_assessment_stats
      "Teacher_Name,teacher_class_name,teacher_section_name,
      content_published_to,book_title, book_subject, book_class,
      display_name,Published_file_name(Physical),type_of_content,
      password_details,published_date,total_no_of_students, no_of_students_downloaded,
      link_to_download_published_content,Published_to_inbox_or_TOC,
      TOC_Subject_name,TOC_chapter_name,TOC_Topic_name"
=end


  def published_content_stats(start_time, end_time)
    start_time = start_time.to_i
    end_time = end_time.to_i
    arr = []
    @content_deliveries = ContentDelivery.where("user_id=? and created_at >=? and created_at < ? and message_id is NOT ? ", self.id, start_time, end_time, nil)
    @content_deliveries.each do |c|
      begin
        book_metadata = c.ibook.get_metadata
        uri = c.uri.split("/") if c.uri.present?
        location = uri
        location.pop
        location.shift

        arr << [self.edutorid + " (#{self.name})", self.class.name , self.academic_class.present? ? self.academic_class.name : "NA", self.section.present? ? self.section.name : "NA",
                c.group_id.present? ? User.find(c.group_id).name : c.recipients,
                book_metadata["displayName"],book_metadata["subject"],book_metadata["academicClass"],
                uri.last,c.user_asset.nil? ? "NA" : c.user_asset.asset_name,
                c.published_as,"NA",Time.at(c.created_at).to_formatted_s(:long),
                c.group_id.present? ? User.find(c.group_id).students.size : (c.recipients.nil? ? "NA" : c.recipients.split(",").size),
                c.group_id.present? ? c.message.message_sync_count(c.group_id) : (c.recipients.nil? ? "NA" :c.message.message_sync_individual_count(c.recipients)),
                c.message.assets.empty? ? "NA" : c.message.assets.last.attachment.url , c.published_to_inbox_or_toc,
                location[0].present? ? location[0] : "NA",
                location[1].present? ? location[1] : "NA", location[2].present? ? location[2] : "NA"]
      rescue
        next
      end
    end
    arr
  end

  def published_assessment_stats(start_time, end_time)
    arr1 = []
    start_time = start_time.to_i
    end_time = end_time.to_i
    @target_groups= QuizTargetedGroup.where("published_by=? and published_on >=? and published_on < ?", self.id, start_time, end_time)

    @target_groups.each do |c|
      arr = []

      if c.quiz_ibook_location.present?
        book_info = c.quiz_ibook_location
        begin
          book_metadata = Ibook.find(book_info.ibook_id).get_metadata unless book_info.ibook_id == 0
          uri = book_info.uri.split("/")
          location = uri
          location.pop
          location.shift
          msg = Message.find(c.message_quiz_targeted_group.message_id)
          arr = arr.push(self.edutorid + " (#{self.name})", self.class.name , self.academic_class.present? ? self.academic_class.name : "NA", self.section.present? ? self.section.name : "NA",
                         c.group_id.present? ? User.find(c.group_id).name : "NA",
                         book_metadata.present? ? book_metadata["displayName"]: "NA",
                         book_metadata.present? ? book_metadata["subject"]: "NA",
                         book_metadata.present? ? book_metadata["academicClass"]: "NA",
                         uri.last,c.subject,"Assessments",c.password, Time.at(c.published_on).to_formatted_s(:long),
                         c.group_id.present? ? User.find(c.group_id).students.size : "1",
                         c.group_id.present? ? msg.message_sync_count(c.group_id) : "1",
                         msg.assets.empty? ? "NA" : msg.assets.last.attachment.url)
          if book_info.ibook_id == 0
            arr = arr.push("inbox","NA","NA","NA")
          else
            arr = arr.push("toc",location[0].present? ? location[0] : "NA",location[1].present? ? location[1] : "NA",
                           location[2].present? ? location[2] : "NA")
          end

        rescue
          next
        end
      elsif c.quiz_target_location.present?
        quiz_target_location = c.quiz_target_location
        begin
          msg = Message.find(c.message_quiz_targeted_group.message_id)
          arr = arr.push(self.edutorid + " (#{self.name})", self.class.name , self.academic_class.present? ? self.academic_class.name : "NA", self.section.present? ? self.section.name : "NA",
                         c.group_id.present? ? User.find(c.group_id).name : "NA", "NA",
                         quiz_target_location.subject ? quiz_target_location.subject.name : "NA",
                         quiz_target_location.content_year ? quiz_target_location.content_year.name : "NA",
                         msg.body.split("/").last,c.subject,"Assessments",c.password, Time.at(c.published_on).to_formatted_s(:long),
                         c.group_id.present? ? User.find(c.group_id).students.size : "1",
                         c.group_id.present? ? msg.message_sync_count(c.group_id) : "1",
                         msg.assets.empty? ? "NA" : msg.assets.last.attachment.url,"Inbox","NA","NA","NA")
        rescue
          next
        end
      else
        begin
          msg = Message.find(c.message_quiz_targeted_group.message_id)
          arr = arr.push(self.edutorid + " (#{self.name})", self.class.name , self.academic_class.present? ? self.academic_class.name : "NA", self.section.present? ? self.section.name : "NA",
                         c.group_id.present? ? User.find(c.group_id).name : "NA",
                         "NA", "NA","NA",
                         c.quiz.name,c.subject,"Assessments",c.password, Time.at(c.published_on).to_formatted_s(:long),
                         c.group_id.present? ? User.find(c.group_id).students.size : "1",
                         c.group_id.present? ? msg.message_sync_count(c.group_id) : "1",
                         msg.assets.empty? ? "NA" : msg.assets.last.attachment.url,"Inbox","NA","NA","NA")
        rescue
          next
        end

      end
      arr1 << arr
    end
    arr1
  end

  # uploaded_content_stats along with how many times it has been published
  #csv header: "Teacher_Name,teacher_class_name,teacher_section_name,asset_name,attachment_file_name,launch_file,
  #content_type, number_of_times_published

  def uploaded_content_stats(start_time, end_time)
    @user_assets = UserAsset.where("user_id=? and created_at >=? and created_at <?",self.id,start_time, end_time)
    arr=[]
    @user_assets.each do |asset|
      arr.push(self.edutorid + " (#{self.name})", self.class.name , self.academic_class.present? ? self.academic_class.name : "NA", self.section.present? ? self.section.name : "NA",
               asset.asset_name,asset.attachment_file_name, asset.launch_file,
               asset.asset_type, asset.content_deliveries.count)
    end
  end

  def content_published_to_inbox(start_time, end_time)
    message_ids = []
    arr =[]
    start_time = start_time.to_i
    end_time = end_time.to_i
    @target_groups = QuizTargetedGroup.includes(:message_quiz_targeted_group).where("published_by=? and published_on >=? and published_on < ?", self.id, start_time, end_time)
    @target_groups.each do |q|
      if q.respond_to? :message_quiz_targeted_group
        message_ids <<  q.message_quiz_targeted_group.message_id if q.message_quiz_targeted_group
      end
    end
    @content_deliveries = ContentDelivery.where("user_id=? and created_at >=? and created_at < ? and message_id is NOT ? ", self.id, start_time, end_time, nil)
    @content_deliveries.each do |cd|
      message_ids << cd.message_id
    end


    if message_ids.size > 0
      @messages = Message.where("sender_id=? and created_at >=? and created_at < ? and id NOT IN (?)", self.id, start_time, end_time,message_ids.uniq.compact)

      @messages.each do |m|
        begin
          arr << [self.edutorid + " (#{self.name})", self.class.name , self.academic_class.present? ? self.academic_class.name : "NA", self.section.present? ? self.section.name : "NA",
                  m.group_id.present? ? User.find(m.group_id).name : m.recipient_id,
                  "NA","NA","NA","NA",m.assets.present? ? m.assets.first.attachment_file_name : "NA",m.message_type,"NA",Time.at(m.created_at).to_formatted_s(:long),
                  m.group_id.present? ? User.find(m.group_id).students.size : "1",
                  m.group_id.present? ? m.message_sync_count(m.group_id) : m.message_sync_individual_count(m.recipient_id.to_s),
                  m.assets.empty? ? "NA" : m.assets.last.attachment.url, "inbox","NA", "NA", "NA"]
        rescue
          next
        end
      end
    end
    arr
  end

  # Method intended to fetch active student count for child classes like Insitution, Center, Academic Class and Section
  def active_student_count
    if self.students.present?
      self.students.select { |s| s.sign_in_count > 0 }.size
    else
      0
    end
  end

  # You need to pass the time in hours as integer
  def recent_logged_in_student_count(x)
    if self.students.present?
      self.students.select { |s| s.current_sign_in_at > x.hours.ago.to_i if s.current_sign_in_at.present?}.size
    else
      0
    end
  end

  def get_store_url
    self.institution.stores.empty? ? "" : self.institution.stores.first.store_url
  end

  def get_ignitor_web_url
    self.institution.ignitor_times.empty? ? "" : self.institution.ignitor_times.first.ignitor_web_url
  end

  def tags_db
    if self.rc == 'ECP'
      user_id = self.id
      UsersTagsDb.find_by_user_id(user_id).present? ? UsersTagsDb.find_by_user_id(user_id).tags_db : nil
    elsif self.rc == 'IA' || self.rc == 'CR' || self.rc == 'ET'
      institution_id = self.institution.id
      if UsersTagsDb.find_by_user_id(institution_id).present?
        UsersTagsDb.find_by_user_id(institution_id).tags_db
      else
        nil
      end
    else
    end
  end

  def set_tags_db(tags_db_id)
    db = UsersTagsDb.find_by_user_id_and_tags_db_id(self.id, tags_db_id)
    if db.present?
    else
      UsersTagsDb.where(:user_id => self.id).destroy_all
      UsersTagsDb.create(:user_id => self.id, :tags_db_id => tags_db_id)
    end
  end

  def my_tags
    db = self.tags_db
    if db.present?
      tags = Hash.new
      tags['class_tags'] = Tag.where(name: 'academic_class', tags_db_id: db.id, standard: true)
      tags['subject_tags'] = Tag.where(name: 'subject', tags_db_id: db.id, standard: true)
      tags['concept_tags'] = Tag.where(name: 'concept_name', tags_db_id: db.id, standard: true)
      tags
    else
      nil
    end
  end
  def self.deactivate_users(user_ids = [])
    User.where(id:user_ids).each do |user|
      user.update_attribute(:is_activated,false)
    end
  end
  def self.reactivate_users(user_ids = [])
    User.where(id:user_ids).each do |user|
      user.update_attribute(:is_activated,true)
    end
  end
  def self.delete_user_messages(user_ids = [])
    user_ids.each do |user|
      UserMessage.where(user_id:user).delete_all
    end
  end
  def self.active_teacher_tests_assets(current_user_id)
    quizzes = Quiz.where("createdby=? and timecreated >=? and timecreated <? ",current_user_id,(30.days.ago).to_i, Time.now.to_i).count
    user_assets =  UserAsset.where("user_id=? and created_at >=? and created_at <?",current_user_id,(30.days.ago).to_i, Time.now.to_i).count
    active = (quizzes + user_assets) == 0 ? 0 : 1
    info_array = [active, quizzes, user_assets]
  end
  def self.active_teacher_tests_assets_consolidated(user_ids)
    teacher_container_info_t1 = {active_teachers:[],tests_published:[],assets_published:[]}
    t = user_ids.map{|teach_id| User.active_teacher_tests_assets(teach_id)}
    t.map{|p| teacher_container_info_t1[:active_teachers] << p[0]
    teacher_container_info_t1[:tests_published] << p[1]
    teacher_container_info_t1[:assets_published] << p[2]
    }
    teacher_container_info_t1[:active_teachers] = teacher_container_info_t1[:active_teachers].inject(0, &:+)
    teacher_container_info_t1[:tests_published] = teacher_container_info_t1[:tests_published].inject(0, &:+)
    teacher_container_info_t1[:assets_published] = teacher_container_info_t1[:assets_published].inject(0, &:+)
    return teacher_container_info_t1
  end
  protected
  def generate_password_by_dob
    # two digits of day + two digits of month + last two digits of complete year
    self.date_of_birth.day.to_s.rjust(2, "0") + self.date_of_birth.month.to_s.rjust(2, "0") + self.date_of_birth.year.to_s[2..3] rescue '4123'
  end

  # override the devise model recoverable method reset_password_period_valid? because of the reset_password_sent_at returning bignum for utc.
  def reset_password_period_valid?
    reset_password_sent_at && Time.at(reset_password_sent_at).to_datetime.utc >= self.class.reset_password_within.ago
  end

  #def self.find_for_database_authentication(warden_conditions)
  # conditions = warden_conditions.dup
  # login = conditions.delete(:login)
  # includes(:profile).where(conditions).where(["lower(profiles.web_screen_name) = :value OR lower(users.edutorid) = :value", { :value => login.strip.downcase }]).first
  #end

  def sync_usage
    User.where(:role_id=>4).each do |user|
      command ="mosquitto_pub -p 3333 -t #{user.edutorid} -m 6  -i Edeployer -q 2 -h 173.255.254.228"
      system(command)
      if !user.deivices.empty?
        command ="mosquitto_pub -p 3333 -t #{user.devices.first.deviceid} -m 6  -i Edeployer -q 2 -h 173.255.254.228"
        system(command)
      end
    end
  end

  def id_with_build_info
    "#{self.id}|#{self.profile.build_info}"
  end


  # Overwrite Devise's find_for_database_authentication method in User model
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(["lower(edutorid) = :value OR lower(email) = :value OR lower(rollno) = :value", { :value => login.downcase }]).first
    elsif conditions.has_key?(:edutorid) || conditions.has_key?(:email) || conditions.has_key?(:rollno)
      where(conditions.to_h).first
    end
  end



end
