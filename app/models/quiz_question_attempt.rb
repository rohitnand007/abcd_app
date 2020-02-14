class QuizQuestionAttempt < ActiveRecord::Base
  has_many :mcq_question_attempts
  has_many :match_question_attempts
  has_many :fib_question_attempts
  has_many :parajumble_question_attempts
  belongs_to :quiz_attempt
  has_one :question
  belongs_to :user

  def answer_given
    question = Question.find(self.question_id)
    if question.qtype == 'fib'
     return self.fib_question_attempts.first.fib_question_answer
    elsif ["multichoice","truefalse"].include? question.qtype
      question_answer_ids = question.question_answers.map(&:id)
      return self.mcq_question_attempts.map{|mcq_question_attempt| question_answer_ids.index(mcq_question_attempt.question_answer_id)+1}.join(",")
    else
      return ""
    end
  end
end
