class CenterAdmin < User
  belongs_to :center

  has_many :users,:foreign_key => 'center_id',:primary_key=>'center_id',:conditions => {:is_group=>false}
  has_many :academic_classes, :foreign_key => 'center_id',:primary_key=>'center_id',:conditions => {:type=>'AcademicClass'}
  has_many :sections, :foreign_key => 'center_id',:primary_key=>'center_id',:conditions => {:type=>'Section'}
  has_many :student_groups,:foreign_key => 'center_id',:primary_key=>'center_id',:conditions => {:type=>'StudentGroup'}
  has_many :teachers,:foreign_key => 'center_id',:primary_key=>'center_id',:conditions=>{:type=>'Teacher'}
  has_many :center_devices,:class_name => 'Device'
  has_many :students,:class_name=>'User',:foreign_key => 'center_id',:primary_key=>'center_id',:conditions=>{:type=>'Student'}
  has_many :usages,:through => :students

  #to get the assessmnets published by IA
  #has_many :assessments,:through=>:assets, :foreign_key => 'publisher_id',:class_name => 'Content',
   #       :conditions=>['type like ? or type like ? or type like ? or type like ? ','Assessment','AssessmentInstiTest','AssessmentPracticeTest','AssessmentHomeWork']
end
