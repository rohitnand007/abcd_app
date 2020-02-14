class DeviceMessage < ActiveRecord::Base
  belongs_to :user_group, :foreign_key=>"group_id"
  belongs_to :device, :foreign_key=>"deviceid"
  belongs_to :sender, :class_name=>"User", :foreign_key=>"sender_id"
  belongs_to :recipient, :class_name=>"User", :foreign_key=>"recipient_id"
  has_many :assets,:as=>:archive, :dependent=>:destroy
  has_many :message_acknowledgs, :conditions=>{:message_type=>'DeviceMessage'}, :foreign_key => 'message_id', :dependent => :destroy
  accepts_nested_attributes_for :assets, :allow_destroy=>true, :reject_if => :all_blank
  attr_accessor :control_message_subject,:multiple_recipient_ids ,:server, :port
  after_create :update_message_id, :send_mqtt_messsge

  CONTROL_MESSAGE_TYPES = ['Execute Scripts','WiFi Settings','Configuration Settings','APK','Index Update','Kill']

  validate :validate_fields

  def validate_fields
    if self.group_id.nil? and self.deviceid.nil?
      errors.add :recipient_id, "Please select atleast one individual or group"
    end
  end


  def update_message_id
    # message_id is combo of sender_id+count_of_all_his_sent where used for tablet to identify uniquely in the portal.
#    last_message_count = DeviceMessage.find_all_by_sender_id(self.sender_id).count
    update_attribute(:message_id,"-"+self.sender_id.to_s+"_"+self.id.to_s+Time.now.to_i.to_s)
end

  def send_mqtt_messsge
    unless self.deviceid.nil?
      command ="mosquitto_pub -p 3333 -t #{self.deviceid} -m 12  -i Edeployer -q 2 -h 173.255.254.228"
      system(command)
    else
      unless self.group_id.nil?
        #UserGroup.includes(:user).where(:group_id=>@message.group_id).where('users.edutorid like?','%ES-%')
        UserGroup.joins(:user).includes(:user=>:devices).where(:group_id=>self.group_id).each do |user_group|
          unless user_group.user.devices.nil?
            user_group.user.devices.each do|device|
              command ="mosquitto_pub -p 3333 -t #{device.deviceid} -m 12  -i Edeployer -q 2 -h 173.255.254.228"
              system(command)
            end
          end
        end
      end
    end
  end

end
