class Topic < Content

  belongs_to :chapter
  belongs_to :subject
  belongs_to :board
  belongs_to :content_year
  has_many :sub_topics, :conditions=>{:type=>"SubTopic"}, :foreign_key => 'topic_id', :dependent => :destroy
  has_many :assessments, :conditions=>{:type=>'Assessment'}, :foreign_key => 'sub_topic_id'
  attr_accessible :assets_attributes
  has_many :assets,:as=>:archive, :dependent => :destroy
  accepts_nested_attributes_for :assets, :allow_destroy=>true, :reject_if => :all_blank
  has_one :quiz_target_location

  #Validations -----------------------------------------------------------------------
  validates :board_id,:content_year_id,:subject_id,:chapter_id,:presence => true
  #validates :play_order, :presence => true,:numericality => true
  validates :name,:presence => true, :uniqueness => {:scope => [:board_id,:content_year_id,:subject_id,:chapter_id,:play_order]}                               \
  #-----------------------------------------------------------------------------------

end