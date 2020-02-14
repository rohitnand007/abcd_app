class MatchQuestionAttempt < ActiveRecord::Base
  belongs_to :quiz_question_attempt
  belongs_to :question_match_sub
end
