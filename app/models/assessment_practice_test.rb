class AssessmentPracticeTest < Content
  belongs_to :subject
  belongs_to :board
  belongs_to :content_year
  belongs_to :chapter
  belongs_to :topic
  belongs_to :sub_topic
  has_one :asset,:as=>:archive, :dependent => :destroy
  has_many :test_configurations,:foreign_key => 'content_id', :dependent => :destroy
  accepts_nested_attributes_for :test_configurations, :allow_destroy=>true, :reject_if => :all_blank
  attr_accessible :asset_attributes,:test_configurations_attributes
  accepts_nested_attributes_for :asset, :allow_destroy=>true, :reject_if => :all_blank

  #Validations
  #--------------------------------------------------------------------------------------------
  #validates :name,:presence => true
  #---------------------------------------------------------------------------------------------

end
