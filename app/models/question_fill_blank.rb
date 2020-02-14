class QuestionFillBlank < ActiveRecord::Base
  validates :answer, :presence => true
  #has_many :fill_question_attempts
end
