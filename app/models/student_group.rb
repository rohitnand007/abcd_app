class StudentGroup < User
  before_create :set_defaults
  has_many :student_user_groups,:class_name => "UserGroup", :foreign_key => :group_id
  has_many :users,:through => :student_user_groups
  has_one :build_info, :foreign_key => "user_id"

  delegate :firstname,:to => :profile, :allow_nil => true
  validates :institution_id,:presence=>:true
  validate :check_name_existence
  accepts_nested_attributes_for :build_info, :allow_destroy => true

  after_create :set_build

  def check_name_existence
    users = StudentGroup.joins(:profile).where(institution_id: institution_id,center_id: center_id).where('profiles.firstname =?',firstname)
    errors.add(:firstname,"already taken for this entry") if !users.blank? and self.id != users.first.id
  end

  def set_defaults
    #self.role_id = 9
    self.is_group = true
    self.is_activated = true
  end

  def students
     self.users.where(:type=>'Student')
  end

  def teachers
    self.users.where(:type=>'Teacher')
  end

  def build_number
    if self.build_info.present?
      self.build_info.build_number.present? ? self.build_info.build_number : "NA"
    else
      "No build info"
    end
  end

  def set_build
   BuildInfo.create(:user_id=>self.id)
  end

end
