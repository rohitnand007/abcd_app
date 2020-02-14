class AcademicClass < User
  has_many :users,:foreign_key => 'academic_class_id'
  has_many :sections, :foreign_key => 'academic_class_id',:conditions => {:type=>'Section'}
  has_many :student_groups,:foreign_key => 'academic_class_id',:conditions => {:type=>'StudentGroup'}
  has_many :students,:class_name=>'User',:foreign_key => 'academic_class_id',:conditions=>{:type=>'Student'}
  has_many :usages,:through => :students

  before_create :set_defaults
  #after_create  :update_defaults
  #after_save :update_boards

  delegate :firstname,:to => :profile, :allow_nil => true
  validate :check_name_existence
  validates :institution_id,:center_id ,:presence => true

  def check_name_existence
    users = AcademicClass.joins(:profile).where(institution_id: institution_id,center_id: center_id).where('profiles.firstname =?',firstname)
    errors.add(:firstname,"already taken for this entry") if !users.blank? and self.id != users.first.id
  end

  def update_boards
    if self.board_ids.empty?
      self.board_ids = [self.institution.boards.first.id] rescue [Board.first.try(:id)]
    end
  end


  def set_defaults
    # self.role_id = 10
    self.is_group = true
    self.is_activated = true
  end

  def update_defaults
    update_attribute(:email,edutorid+"@edutor.com") if self.email.nil?
  end

end
