class Board < Content

  belongs_to :content
  has_many :content_years,:conditions=>{:type=>'ContentYear'}, :dependent => :destroy
  has_many :subjects, :conditions=>{:type=>'Subject'}, :foreign_key => 'board_id'
  has_many :chapters, :conditions=>{:type=>'Chapter'}, :foreign_key => 'board_id'
  has_many :topics, :conditions=>{:type=>'Topic'}, :foreign_key => 'board_id'
  has_many :sub_topics, :conditions=>{:type=>'SubTopic'}, :foreign_key => 'board_id'
  has_many :assessments, :conditions=>{:type=>'Assessment'}, :foreign_key => 'board_id'
  has_and_belongs_to_many :users
  has_one :quiz_target_location

  #Validations -----------------------------------------------------------------------
  validates :name,:code,:presence => true
  validates :name, :uniqueness => true
  #-----------------------------------------------------------------------------------
  
end