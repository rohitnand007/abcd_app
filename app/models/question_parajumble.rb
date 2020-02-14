class QuestionParajumble < ActiveRecord::Base
  validates :questiontext, :presence => true
  has_many :parajumble_question_attempts
  before_create :set_defaults
  def set_defaults
    self.questiontextformat = 1
  end
end
