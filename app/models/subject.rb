class Subject < Content

  belongs_to :board
  belongs_to :content_year
  belongs_to :parent_subject, :class_name => 'Subject', :foreign_key => 'subject_id'
  has_many :sub_subjects, :conditions=>{:type=>"Subject"}, :foreign_key => 'subject_id', :dependent => :destroy,:class_name => 'Subject'
  has_many :chapters, :conditions=>{:type=>"Chapter"}, :foreign_key => 'subject_id', :dependent => :destroy
  has_many :topics, :conditions=>{:type=>'Topic'}, :foreign_key => 'subject_id'
  has_many :sub_topics, :conditions=>{:type=>'SubTopic'}, :foreign_key => 'subject_id'
  has_many :assessments, :conditions=>{:type=>'Assessment'}, :foreign_key => 'subject_id'
  attr_accessible :assets_attributes
  has_one :asset,:as=>:archive, :dependent => :destroy
  has_one :quiz_target_location
  attr_accessible :asset_attributes
  accepts_nested_attributes_for :asset, :allow_destroy=>true, :reject_if => :all_blank

  #Validations -----------------------------------------------------------------------
  validates :board_id,:content_year_id,:presence => true
  validates :name,:presence => true, :uniqueness => {:scope => [:board_id,:content_year_id]}                               \
  #-----------------------------------------------------------------------------------

  def name_with_content_year
    self.board.try(:name)+"_"+self.content_year.try(:name).to_s+"_"+self.try(:name).to_s
  end

end
