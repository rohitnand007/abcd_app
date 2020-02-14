class SubTopic < Content

  belongs_to :subject
  belongs_to :board
  belongs_to :content_year
  belongs_to :chapter
  belongs_to :topic
  has_many :assets,:as=>:archive, :dependent => :destroy
  attr_accessible :assets_attributes
  accepts_nested_attributes_for :assets, :allow_destroy=>true, :reject_if => :all_blank
  has_one :quiz_target_location

  #Validations -----------------------------------------------------------------------
  validates :board_id,:content_year_id,:subject_id,:chapter_id,:topic_id,:presence => true
  #validates :play_order, :presence => true,:numericality => true
  validates :name,:presence => true, :uniqueness => {:scope => [:board_id,:content_year_id,:subject_id,:chapter_id,:topic_id]}                               \
  #-----------------------------------------------------------------------------------

end