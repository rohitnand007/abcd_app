class Concept < ActiveRecord::Base
  attr_accessible :name, :concept, :institution, :user
  has_many :concept_elements, :dependent => :destroy
  belongs_to :institution
  belongs_to :board
  belongs_to :content_year
  belongs_to :subject
  belongs_to :chapter
  belongs_to :user

  validates :board_id, :presence => true
  validates :content_year_id, :presence => true
  validates :subject_id, :presence => true
  validates :chapter_id, :presence => true
  validates :name, :presence => true
  validates :name, :uniqueness => {:scope => :user_id}

end
