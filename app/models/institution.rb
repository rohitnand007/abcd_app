class Institution < User

  has_many :users,:foreign_key => 'institution_id'
  has_many :institute_admins,:foreign_key => 'institution_id'
  has_many :centers, :foreign_key => 'institution_id',:conditions => {:type=>'Center'}
  has_many :academic_classes, :foreign_key => 'institution_id',:conditions => {:type=>'AcademicClass'}
  has_many :sections, :foreign_key => 'institution_id',:conditions => {:type=>'Section'}
  has_many :student_groups,:foreign_key => 'institution_id',:conditions => {:type=>'StudentGroup'}
  has_many :teachers,:foreign_key => 'institution_id',:conditions=>{:type=>'Teacher'}
  has_many :publishers,:through => :user_groups,:conditions => {:type=>'Publisher'}

  has_many :institution_devices,:class_name => 'Device'
  has_many :students,:foreign_key => 'institution_id',:conditions=>{:type=>'Student'}
  has_many :usages, :through => :students
  has_many :class_rooms,:through => :teachers,:foreign_key => 'teacher_id'

  has_many :license_sets

  # Gives a database dedicated to the institute
  has_many :publisher_question_banks, :foreign_key => :publisher_id, :dependent => :destroy
  # Give purchased question banks
  has_many :question_bank_users, :foreign_key => :user_id, :dependent => :destroy
  has_many :purchased_question_banks, :through => :question_bank_users, :source => :publisher_question_bank, :foreign_key => :publisher_question_bank_id
  has_many :created_questions ,:class_name => "Question",:foreign_key => 'institution_id'
  has_many :qdb_questions, :source=>:questions , :through=>:publisher_question_banks
  # has_many :question_bank_users,:foreign_key => 'user_id', :dependent => :destroy

  has_and_belongs_to_many :stores
  has_and_belongs_to_many :ignitor_times

  has_one :user_configuration,:foreign_key => 'user_id'
  accepts_nested_attributes_for :user_configuration, :allow_destroy=>true, :reject_if => :all_blank

  after_create :create_group_user , :create_publisher_question_bank , :configure_to_use_tags, :create_moe
  #before_save :set_role_and_group,:if=>Proc.new{|inst| (inst.role_id.nil? or inst.role_id.blank?)}
  #after_save :update_boards

  delegate :firstname,:to => :profile, :allow_nil => true
  validate :check_name_existence
  #validates :email,:presence => true

  #validate :must_assign_one_board

  def  create_publisher_question_bank
    PublisherQuestionBank.create(publisher_id: self.id, description: "This is #{self.name}'s question bank'", question_bank_name: "#{self.name} Question Bank")
  end

  alias cqb create_publisher_question_bank

  def configure_to_use_tags
    self.user_configuration.update_attribute :use_tags, true
  end

  def update_boards
    if self.board_ids.empty?
      self.board_ids = [Board.first.try(:id)]
    end
  end

  def check_name_existence
    users = Institution.joins(:profile).where('profiles.firstname =?',firstname)
    errors.add(:firstname,"already taken for this entry") if !users.blank? and self.id != users.first.id
  end

  def must_assign_one_board
    errors.add(:base,"Must assign atleast one board") if self.board_ids.empty?
  end

  def set_role_and_group
    #self.role_id = 12
    self.is_group = true
  end

  def create_group_user
    ia=InstituteAdmin.create email:"IA_"+Time.now.to_i.to_s+"@abcd.com"
    ia.password="abcd123"
    ia.is_activated=true
    ia.institution_id=self.id
    ia.is_group=false
    ia.save
    ia.create_profile(:firstname=>'IA')
  end

  def create_moe
  ia= Moe.create email:"moe_"+Time.now.to_i.to_s+"@abcd.com"
  ia.password="abcd123"
  ia.is_activated=true
  ia.institution_id=self.id
  ia.is_group=false
  ia.save
  ia.create_profile(:firstname=>'MOE')
end

    #to get the institution boards through publishers
  #def boards
    #self.publishers.map{|pub| pub.boards}.flatten
  #end
  def get_book_ids
    l_s = LicenseSet.includes(ipack: :ibooks).where(id: license_set_ids)
    book_ids = l_s.map {|l| l.ipack.ibooks.map(&:ibook_id)}
    book_ids.flatten.uniq
  end
end
