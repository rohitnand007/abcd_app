class Animation < Content
  belongs_to :subject
  belongs_to :board
  belongs_to :content_year
  belongs_to :chapter
  belongs_to :topic
  belongs_to :sub_topic
  has_one :asset,:as=>:archive, :dependent => :destroy
  attr_accessible :asset_attributes
  accepts_nested_attributes_for :asset, :allow_destroy=>true, :reject_if => :all_blank

  #Validations
  #--------------------------------------------------------------------------------------------
  #validates :name,:presence => true
  #---------------------------------------------------------------------------------------------

end
