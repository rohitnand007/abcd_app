class Teacher < User


  has_many :teacher_class_rooms,:class_name => 'ClassRoom'

  #has_many :test_configurations,:foreign_key => 'created_by'
  #has_many :assessments,:through=>:assets, :foreign_key => 'publisher_id'
  # has_many :assessments,:through=>:assets, :foreign_key => 'publisher_id',:class_name => 'Content',
  #        :conditions=>['type like ? or type like ? or type like ? or type like ? or type like ? or type like ? or type like ? ',
  #                     'Assessment','AssessmentInstiTest','AssessmentPracticeTest','AssessmentHomeWork','AssessmentIit','AssessmentInclass','AssessmentOlympiad']
  has_many :chapters,:through=>:assets, :foreign_key => 'publisher_id'
  has_many :topics,:through=>:assets, :foreign_key => 'publisher_id'
  has_many :sub_topics,:through=>:assets, :foreign_key => 'publisher_id'
  # teacher has many sections/groups through group_id
  #has_many :sections,:foreign_key => 'group_id',:through=>:teacher_class_rooms
  # has_many :student_groups,:foreign_key => 'group_id',:through=>:teacher_class_rooms
  has_many :student_groups, :through=> :student_group_owners
  has_many :content_layouts,:foreign_key => 'teacher_id'


  has_many :assets,:foreign_key=>"publisher_id"

  #assing device to teacher
  has_many :user_devices,:foreign_key => "user_id"
  has_many :devices, :through => :user_devices,:foreign_key => "user_id"

  #has_many :class_contents,:through => :teacher_class_rooms, :source=>:content

  #has_many :usages,:through => :class_contents


  before_create :set_defaults

  #after_save :update_class_room

  validates :rollno, :uniqueness => {:scope => [:institution_id]}

  validates :institution_id,:center_id,:academic_class_id,:section_id ,:presence => true
  attr_accessible :teacher_class_rooms_attributes
  accepts_nested_attributes_for :teacher_class_rooms, :allow_destroy=>true,:reject_if => :all_blank

  # accepts_nested_attributes_for :devices, :allow_destroy=>true,:reject_if => lambda { |d| d[:deviceid].blank? }


  #validates_associated :teacher_class_rooms

  def self.center_teachers_incomplete_class_details?(center)
    center.teachers.select('id').includes(:teacher_class_rooms).map{|teacher| teacher.incomplete_class_details? }.include?true
  end

  def incomplete_class_details?
    self.teacher_class_rooms.map{|class_room| return (class_room.content.try(:type).eql?'Board') ? true : false }
  end

  def set_defaults
    #self.role_id = 5
    self.is_activated = true
    self.is_enrolled = true #teacher also need to enrolled after create because device can be associated to teacher.
  end


  def my_students
    class_room_groups = self.teacher_class_rooms.map(&:group_id)
    class_room_groups.map{|group| User.find(group).users.students}.flatten
  end

  def ibooks
    ids = self.license_sets.collect(&:ipack_id)
    @ipacks = Ipack.includes(:ibooks).where(id: ids)
    @books = []
    @ipacks.each do |ipack|
      @books << ipack.ibooks
    end
    @books.flatten.uniq
  end

  def sections
    self.groups.where(:type=>'Section')
  end

  def students
    Student.where(:section_id=>self.groups.where(:type=>'Section').map(&:id))

  end

end
