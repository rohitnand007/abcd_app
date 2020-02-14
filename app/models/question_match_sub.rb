class QuestionMatchSub < ActiveRecord::Base
  validates :answertext, :questiontext, :presence => true
  has_many :match_question_attempts
  before_create :set_defaults
  def set_defaults
    self.questiontextformat = 1
  end
end
