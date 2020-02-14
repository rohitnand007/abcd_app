class Chapter < Content

  belongs_to :content
  belongs_to :subject
  belongs_to :board
  belongs_to :content_year
  has_many :topics, :conditions=>{:type=>'Topic'}, :foreign_key => 'chapter_id', :dependent => :destroy
  has_many :sub_topics, :conditions=>{:type=>'SubTopic'}, :foreign_key => 'chapter_id'  , :dependent => :destroy
  has_many :assets,:as=>:archive, :dependent => :destroy
  has_many :assessments, :conditions=>{:type=>'Assessment'}, :foreign_key => 'chapter_id', :dependent => :destroy
  has_many :assessment_practice_tests, :conditions=>{:type=>'AssessmentPracticeTest'}, :foreign_key => 'chapter_id', :dependent => :destroy
  has_many :assessment_insti_tests, :conditions=>{:type=>'AssessmentInstiTest'}, :foreign_key => 'chapter_id', :dependent => :destroy
  has_many :assessment_categories, :conditions=>{:type=>'AssessmentCategory'}, :foreign_key => 'chapter_id', :dependent => :destroy
  accepts_nested_attributes_for :assets, :allow_destroy=>true, :reject_if => :all_blank
  attr_accessible :assets_attributes 
  has_one :content_profile,:foreign_key=>:content_id, :dependent => :destroy
  accepts_nested_attributes_for :content_profile, :allow_destroy=>true, :reject_if => :all_blank
  attr_accessible :content_profile_attributes
  has_one :quiz_target_location

  #Validations -----------------------------------------------------------------------
    validates :board_id,:content_year_id,:subject_id,:presence => true
    validates :name,:presence => true, :uniqueness => {:scope => [:board_id,:content_year_id,:subject_id,:play_order]}
    #validates :play_order, :presence => true,:numericality => true

\

  #-----------------------------------------------------------------------------------

end