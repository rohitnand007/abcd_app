#class Section < ActiveRecord::Base
class Section < User
  #Associations
  #---------------------------------------------------------------------------------------------------------------
  has_many :users,:foreign_key => 'section_id'
  has_many :student_groups,:foreign_key => 'section_id',:conditions => {:type=>'StudentGroup'}
  has_many :teachers, :foreign_key => 'section_id',:conditions => {:type=>'Teacher'}
  has_many :students,:foreign_key => 'section_id',:conditions=>{:rc=>'ES'}
  has_many :usages, :through => :students
  has_one :build_info, :foreign_key => 'user_id',:dependent => :destroy
  accepts_nested_attributes_for :build_info, :allow_destroy => true

  # Call Backs
  #--------------------------------------------------------------------------------------------------------------
  before_create :set_defaults
  #after_save :update_boards
  after_create  :update_defaults,:create_class_teacher
  after_create :section_build_info

  delegate :firstname,:to => :profile, :allow_nil => true

  # Validations
  #----------------------------------------------------------------------------------------------------------------
  validate :check_name_existence
  validates :institution_id,:center_id,:academic_class_id ,:presence => true

  def check_name_existence
    users = Section.joins(:profile).where(institution_id: institution_id,center_id: center_id,academic_class_id: academic_class_id).where('profiles.firstname =?',firstname)
    errors.add(:firstname,"already taken for this entry") if !users.blank? and self.id != users.first.id
  end


  def update_boards
    if self.board_ids.empty?
      self.board_ids = [self.institution.boards.first.id] rescue [Board.first.try(:id)]
    end
  end

  def section_build_info
    self.build_build_info
    self.build_info = BuildInfo.create
  end
  def set_defaults
    #self.role_id = 11
    self.is_group = true
    self.is_activated = true
  end

  def update_defaults
    update_attribute(:email,edutorid+"@edutor.com")  if self.email.nil?
  end

  def create_class_teacher
     #creating one est per center
    teacher=Teacher.create email:"ET_#{Time.now.to_i}@abcd.com"
    teacher.password="abcd123"
    teacher.is_activated=true
    teacher.institution_id=self.institution_id
    teacher.center_id=self.center_id
    teacher.academic_class_id=self.academic_class_id
    teacher.section_id=self.id
    teacher.is_group=false
    teacher.is_class_teacher = true
    #teacher.role_id = 5
    teacher.save
    first_name = "Teacher"+self.academic_class.name+self.name rescue "Teacher"
    teacher.create_profile(:firstname=>first_name)
  end
  

end
