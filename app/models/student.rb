class Student < User
  validates :email,:presence => true
  validates_presence_of :password, :on=>:create
  validates_confirmation_of :password
  validates_length_of :password, :within => 4..128,:allow_blank => true
  validates_uniqueness_of :rollno
  validates :institution_id,:center_id,:academic_class_id, :section_id ,:presence => true
  validates_format_of :email, :with  => Devise.email_regexp, :allow_blank => true, :if => :email_changed?
  validates_uniqueness_of  :email, :scope => [:institution_id],    :case_sensitive => false, :allow_blank => true, :if => :email_changed?

end