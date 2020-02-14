class Center < User

  has_many :users,:foreign_key => 'center_id'
  has_many  :center_admins,:foreign_key => 'center_id'
  has_many :academic_classes, :foreign_key => 'center_id',:conditions => {:type=>'AcademicClass'}
  has_many :sections, :foreign_key => 'center_id',:conditions => {:type=>'Section'}
  has_many :student_groups,:foreign_key => 'center_id',:conditions => {:type=>'StudentGroup'}
  has_many :teachers,:foreign_key => 'center_id',:conditions=>{:type=>'Teacher'}
  has_many :center_devices,:class_name => 'Device'
  has_many :students, :foreign_key => 'center_id',:conditions=>{:type=>'Student'}
  has_many :usages,:through => :students
  has_one :est,:class_name => 'User',:foreign_key => 'center_id',:conditions=>['edutorid like ?',"EST-%"]
  has_many :class_rooms,:through => :teachers,:foreign_key => 'teacher_id'
  has_many :cdn_centers
  has_many :cdn_configs,:through=>:cdn_centers
  has_many :license_sets

  before_save :set_role_and_group #,:if=>Proc.new{|cent| cent.role_id.nil? or cent.role_id.blank?}
  after_create :create_group_user
  #after_save :update_boards

  delegate :firstname,:to => :profile, :allow_nil => true
  validate :check_name_existence
  validates :institution_id,:presence => true
  #validates :email,:presence => true


  def check_name_existence
    users = Center.joins(:profile).where(institution_id: institution_id).where('profiles.firstname =?',firstname)
    errors.add(:firstname,"already taken for this entrys") if !users.blank? and self.id != users.first.id
  end

  def update_boards
    if self.board_ids.empty?
      self.board_ids = [self.institution.boards.first.id] rescue [Board.first.try(:id)]
    end
  end


  def set_role_and_group
    #self.role_id = 13
    self.is_group = true
  end

  def create_group_user
    #creating center admin for center
    ca=CenterAdmin.create email:"CR_"+Time.now.to_i.to_s+"@abcd.com"
    ca.password="abcd123"
    ca.is_activated=true
    ca.institution_id=self.institution_id
    ca.center_id=self.id
    ca.is_group=false
    ca.save
    ca.create_profile(:firstname=>'CR').save


    #creating one est per center
   # est=User.create email:"group-est"+self.email
   # est.password="edutor"
   # est.is_activated=true
   # est.institution_id=self.institution_id
   # est.center_id=self.id
   # est.is_group=false
   # est.role_id = 7
   # est.save
   # est.create_profile(:firstname=>'EST').save
  end

  def get_book_ids
    l_s = LicenseSet.includes(ipack: :ibooks).where(id: license_set_ids)
    book_ids = l_s.map {|l| l.ipack.ibooks.map(&:ibook_id)}
    book_ids.flatten.uniq
  end

end
