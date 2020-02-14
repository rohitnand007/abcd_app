class InstituteAdmin < User

  belongs_to :institution

  has_many :users,:foreign_key => 'institution_id',:primary_key => 'institution_id',:conditions => {:is_group=>false}
  has_many :centers, :foreign_key => 'institution_id',:primary_key => 'institution_id',:conditions => {:type=>'Center'}
  has_many :academic_classes, :foreign_key => 'institution_id',:primary_key => 'institution_id',:conditions => {:type=>'AcademicClass'}
  has_many :sections, :foreign_key => 'institution_id',:primary_key => 'institution_id',:conditions => {:type=>'Section'}
  has_many :student_groups,:foreign_key => 'institution_id',:primary_key => 'institution_id',:conditions => {:type=>'StudentGroup'}


  has_many :institution_devices,:class_name => 'Device',:foreign_key => 'institution_id',:primary_key => 'institution_id'

  has_many :students,:class_name=>'Student',:foreign_key => 'institution_id',:primary_key => 'institution_id'

  has_many :teachers,:class_name=>'Teacher',:foreign_key => 'institution_id',:primary_key => 'institution_id'

  has_many :usages, :through => :students

  # to get the assessmnets published by IA
 # has_many :assessments,:through=>:assets, :foreign_key => 'publisher_id',:class_name => 'Content',
  #        :conditions=>['type like ? or type like ? or type like ? or type like ? ','Assessment','AssessmentInstiTest','AssessmentPracticeTest','AssessmentHomeWork']
end
