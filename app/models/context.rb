class Context < ActiveRecord::Base
  #validates :board_id, :content_year_id,:subject_id,   :presence => true
  has_one :question
  has_one :quiz
  belongs_to :board
  belongs_to :content_year
  belongs_to :chapter
  belongs_to :subject
  belongs_to :topic
  before_save :set_defaults
  before_create :set_defaults

  def set_defaults
    if self.chapter_id.nil?
      self.chapter_id = 0
    end
    if self.topic_id.nil?
      self.topic_id = 0
    end
  end
end
