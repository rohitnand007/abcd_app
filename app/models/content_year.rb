class ContentYear < Content
  belongs_to :board
  has_many :subjects, :conditions=>{:type=>'Subject'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :chapters, :conditions=>{:type=>'Chapter'}, :foreign_key => 'content_year_id'
  has_many :topics, :conditions=>{:type=>'Topic'}, :foreign_key => 'content_year_id'
  has_many :sub_topics, :conditions=>{:type=>'SubTopic'}, :foreign_key => 'content_year_id'
  has_many :assessments, :conditions=>{:type=>'Assessment'}, :foreign_key => 'content_year_id'
  has_many :assessment_practice_tests, :conditions=>{:type=>'AssessmentPracticeTest'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :assessment_insti_tests, :conditions=>{:type=>'AssessmentInstiTest'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :assessment_categories, :conditions=>{:type=>'AssessmentCategory'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :assessment_end_chapter_quizzes, :conditions=>{:type=>'AssessmentEndChapterQuiz'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :assessment_end_topic_quizzes, :conditions=>{:type=>'AssessmentEndTopicQuiz'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :assessment_iits, :conditions=>{:type=>'AssessmentIit'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :assessment_in_topic_quizzes, :conditions=>{:type=>'AssessmentInTopicQuiz'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :assessment_inclasses, :conditions=>{:type=>'AssessmentInclass'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :assessment_olympiads, :conditions=>{:type=>'AssessmentOlympiad'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :assessment_quizzes, :conditions=>{:type=>'AssessmentQuiz'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :tsps, :conditions=>{:type=>'Tsp'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :web_links, :conditions=>{:type=>'WebLink'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :keywords, :conditions=>{:type=>'Keyword'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :concept_maps, :conditions=>{:type=>'ConceptMap'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :animations, :conditions=>{:type=>'Animation'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_many :activities, :conditions=>{:type=>'Activity'}, :foreign_key => 'content_year_id', :dependent => :destroy
  has_one :quiz_target_location
  has_one :asset,:as=>:archive, :dependent => :destroy
  attr_accessible :asset_attributes
  accepts_nested_attributes_for :asset, :allow_destroy=>true, :reject_if => :all_blank

  #Validations -----------------------------------------------------------------------
  validates :board_id,:presence => true
  validates :name,:presence => true, :uniqueness => {:scope => :board_id}
  #-----------------------------------------------------------------------------------

  def name_with_content_year
    self.board.try(:name)+"_"+self.try(:name).to_s
  end

  end