class WebLink < Content
  default_scope order('id desc')
  belongs_to :subject
  belongs_to :board
  belongs_to :content_year
  belongs_to :chapter
  belongs_to :topic
  belongs_to :sub_topic
  has_one :asset,:as=>:archive, :dependent => :destroy
  has_one :web_link_video, :dependent => :destroy
  has_one :web_link_flash, :dependent => :destroy
  attr_accessible :asset_attributes
  accepts_nested_attributes_for :asset, :allow_destroy=>true, :reject_if => :all_blank
  accepts_nested_attributes_for :web_link_video
  accepts_nested_attributes_for :web_link_flash
  validates :board_id,:content_year_id,:subject_id,:chapter_id,:name,:presence => true

  #Validations
  #--------------------------------------------------------------------------------------------
  #validates :name,:presence => true
  #---------------------------------------------------------------------------------------------

end
