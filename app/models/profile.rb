class Profile < ActiveRecord::Base
  has_attached_file :photo, :styles => { :small => "125x50>",:thumb =>"75x75>",:large=>"200x200>" },
                    :url  => "/avatars/profiles/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/avatars/profiles/:id/:style/:basename.:extension"
  belongs_to :user
  attr_accessible :surname,:firstname,:user_id,:photo,:height,:weight,:blood_group,:gender,:middlename,:parent_email,:parent_mobile,:address,:website,:phone,
                  :device_screen_name,:web_screen_name,:alternateemail,:user_attributes


  validates :firstname, :presence => true
  #validates :phone, :numericality => true,:length => {:minimum=>10},:allow_blank => true
  #validates :height,:weight,:numericality => { :greater_than => 0, :less_than_or_equal_to => 100 },:allow_blank => true

  # validates :web_screen_name,:uniqueness=> { :case_sensitive => false },:allow_blank => true

  accepts_nested_attributes_for :user

#  after_save :update_photo_url

  def display_name
    "#{self.surname}  #{self.firstname}"
  end

  def autocomplete_display_name
    "#{self.surname}  #{self.firstname} #{self.try(:user).try(:edutorid)} #{self.try(:user).try(:rollno)}"
  end

  def section_name
    a = self.user.academic_class.try(:firstname)
    if a.nil?
      self.firstname
    else
      "#{a}_#{self.firstname}"
    end
  end

  def build_info
    a = User.find(self.user_id)
    if a.respond_to?(:sections)
      sec_ids = a.sections.collect(&:id)
      build_info = BuildInfo.where(user_id: sec_ids).collect(&:build_number).uniq
      if build_info.count == 1
        BuildInfo.find_by_user_id(self.user_id).present? ? BuildInfo.find_by_user_id(self.user_id).build_number : build_info.first
      else
        BuildInfo.find_by_user_id(self.user_id).present? ? BuildInfo.find_by_user_id(self.user_id).build_number : "1.0"
      end
    else
      BuildInfo.find_by_user_id(self.user_id).present? ? BuildInfo.find_by_user_id(self.user_id).build_number : "4.0"
    end
    end

  def update_photo_url
    if self.user.role_id == 4  && !self.photo_file_size.nil?
      file_path = self.photo(:small).split('?')[0]
      size =  File.size(Rails.root.to_s+'/public/'+file_path)
      update_column(:photo_file_size,size)
      update_column(:web_screen_name,file_path)
    end
  end
  def id_with_build_info
    "#{self.user.id}|#{self.user.profile.build_info}"
  end

end
