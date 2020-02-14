class ParajumbleQuestionAttempt < ActiveRecord::Base
  belongs_to :quiz_question_attempt
  belongs_to :question_parajumble
end
