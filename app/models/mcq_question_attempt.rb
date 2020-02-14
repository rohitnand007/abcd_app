class McqQuestionAttempt < ActiveRecord::Base
  belongs_to :quiz_question_attempt
  belongs_to :question_answer
end
