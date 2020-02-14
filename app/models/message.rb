class Message < ActiveRecord::Base

  scope :all_received_messages ,lambda{|current_user,group_ids|
    where("recipient_id =? or group_id IN (?)",current_user,group_ids)
  }

  serialize :attachments

  has_many :user_messages, :dependent=>:destroy
  has_many :content_deliveries

  belongs_to :user, :foreign_key=>"sender_id"

  belongs_to :user_group, :foreign_key=>"group_id"
  belongs_to :sender, :class_name=>"User", :foreign_key=>"sender_id"
  belongs_to :recipient, :class_name=>"User", :foreign_key=>"recipient_id"
  belongs_to :group, :class_name=>"User", :foreign_key=>"group_id"
  has_many :message_acknowledgs
  has_many :assets,:as=>:archive, :dependent=>:destroy
  has_many :message_user_downloads
  has_many :message_acknowledgs, :conditions=>{:message_type=>'Message'}, :foreign_key => 'message_id', :dependent => :destroy
  accepts_nested_attributes_for :assets, :allow_destroy=>true, :reject_if => :all_blank
  attr_accessor :control_message_subject,:multiple_recipient_ids,:receiver_name
  attr_accessible :multiple_recipient_ids,:receiver_name, :recipient_id, :group_id, :subject, :sender_id, :message_type, :severity, :label, :body,:attachments,:assets_attributes,
                  :control_message_subject
  #validate :message_requirements,:validate_attachments

  #validate :validate_attachments,:unless => Proc.new { |message| message.sender_id == 1}

  #EA_MESSAGE_TYPES = ["Alert","Timetable","Centerreport","Attendance","Content","Control Message", "Micro Scheduler","Rubric",'ConceptMap','Epub Book']


  EA_MESSAGE_TYPES = ["Alert","Report","Content"]

  MESSAGE_TYPES = ["Notification","Report","Content"]

  #MESSAGE_TYPES = ["Alert","Timetable","Centerreport","Attendance","Content", "Micro Scheduler","Rubric"]

  CONTROL_MESSAGE_TYPES = ['Enroll','De-Enroll','Execute Scripts','WiFi Settings','Configuration Settings','APK','Index Update','Kill']

  #validates :recipient_id, :presence => true, :unless => lambda { self.group_id.blank? }
  validates_presence_of :recipient_id, :unless => :group_id?  ,:message=>"Please select individual or group"

  after_create :update_message_id,:set_body_message,:change_enroll_status,:send_mqtt_messsge
  #after_create :create_message_acknowledgement,:if=>Proc.new{|message| message.severity==2}
  before_create :set_subject_and_recipient

  def change_enroll_status
    user =  User.find(self.recipient_id) rescue nil
    if self.subject.eql?'Enroll' and !user.nil?
      user.update_attribute(:is_enrolled,true)
    elsif self.subject.eql?'De-Enroll' and !user.nil?
      user.update_attribute(:is_enrolled,false)
    end
  end


  def set_body_message
    if self.subject.eql?'APK' or self.subject.eql?'Timetable' or self.subject.eql?'Index Update'
      name_path = self.assets.first.attachment_file_name+":"+self.assets.first.url
      self.update_attribute(:body,name_path)
    end
  end

  def set_subject_and_recipient
    self.subject = self.control_message_subject if self.message_type.eql?("Control Message") and !self.control_message_subject.blank?
  end


  def update_message_id
    # message_id is combo of sender_id+count_of_all_his_sent where used for tablet to identify uniquely in the portal.
#    last_message_count = Message.find_all_by_sender_id(self.sender_id).count
    update_attribute(:message_id,self.sender_id.to_s+"_"+DateTime.now.strftime('%Q').to_s)
  end


  def validate_attachments
    unless self.assets.empty?
      self.assets.each do |asset|
        case self.message_type
          when 'Content'
            errors.add(:attachment,"should be a Pdf or ZIP") unless asset.content_type =~ /pdf/ or asset.content_type =~ /zip/
          when 'Centerreport'
            errors.add(:attachment,"should be a PDF") unless asset.content_type =~ /pdf/
          when 'Attendance'
            errors.add(:attachment,"should be a PDF") unless asset.name.nil? and asset.content_type =~ /pdf/
          else
            errors.add(:attachment,"should be a CSV") unless asset.content_type =~ /csv/
        end
      end
    else
      errors.add(:message,"should have attachment") unless self.message_type.eql?('Attendance')
    end
  end

  def message_requirements
    if recipient_id.blank? and group_id.blank?
      errors.add(:recipient_id, "please select valid recipient user or group")
    else
      if recipient_id.blank?
        if User.find_by_id(recipient_id)
          errors.add(:recipient_id, "please select valid recipient")
        end
      end
    end
  end


=begin
  commented as recipients ids are multiple now.
  def receiver_name=(receiver_name)
    user = Profile.find_by_surname(receiver_name)
    if user
      self.recipient_id = user.user_id
    else
      errors[:user_name] << "Invalid name entered"
    end
  end

  def receiver_name
    Profile.find_by_user_id(recipient_id).surname if recipient_id
  end
=end

  def self.send_birthday_wishes
    User.students.where(:date_of_birth=>Date.today.to_datetime.to_i).each do |user|
      Message.create(recipient_id: user.id, subject: 'Edutor Wishes: Happy Brithday',sender_id: 1)
    end
  end

  def create_message_acknowledgement
    if self.group_id
      UserGroup.where(:group_id=>self.group_id).each do |user|
        MessageAcknowledg.transaction do
          MessageAcknowledg.create(:user_id=>user.user_id,:message_id=>self.id)
        end
      end
    else
      MessageAcknowledg.create(:user_id=>self.recipient_id,:message_id=>self.id)
    end
  end

  def send_mqtt_messsge
    if self.severity != 10
      unless self.recipient_id.nil?
        UserMessage.create(:user_id=>self.recipient_id,:message_id=>self.id)
       # command ="mosquitto_pub -p 3333 -t #{self.recipient.edutorid} -m 2  -i Edeployer -q 2 -h 173.255.254.228"
    #    logger.info "===#{command}"
       # system(command)
      else
        unless self.group_id.nil?
          #UserGroup.includes(:user).where(:group_id=>@message.group_id).where('users.edutorid like?','%ES-%')
          UserGroup.includes(:user).where(:group_id=>self.group_id).each do |user|
            UserMessage.create(:user_id=>user.user_id,:message_id=>self.id)
          #  command ="mosquitto_pub -p 3333 -t #{user.user.edutorid} -m 2  -i Edeployer -q 2 -h 173.255.254.228"
           # system(command)
          end
        end
      end
    end
  end
  def message_download_status(user_id)
    w = UserMessage.where(["message_id = ? and user_id = ?", "#{self.id}", "#{user_id}"]).first
    if w.nil?
      return 'Not Yet Published'
    elsif w.sync == false
       return 'Yes'
    elsif w.sync == true
      return 'No'
    end

  end

  def message_sync_count(group_id)
    users = User.find(group_id).students
    count = 0
    users.each do |stu|
      count = count.next if self.message_download_status(stu.id) == 'Yes'
    end
    count
  end

  def message_sync_individual_count(recipients)
    recipients =  recipients.split(",")
    users = User.find(recipients)
    count = 0
    users.each do |stu|
      count = count.next if self.message_download_status(stu.id) == 'Yes'
    end
    count

  end

end
