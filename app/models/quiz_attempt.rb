class QuizAttempt < ActiveRecord::Base
  has_many :quiz_question_attempts
  belongs_to :quiz
  belongs_to :user

  def valid_quiz_question_attempts
    valid_quiz_question_attempts = []
    all_quiz_question_attempts = self.quiz_question_attempts
    all_quiz_question_attempts.each{|i|
      # preloads question answers and question fill blank objects
      question = Question.find(i.question_id)
      if i.correct?
        valid_quiz_question_attempts << i.id
      else
        if question.qtype == 'fib'
          q_attempts = FibQuestionAttempt.where(:quiz_question_attempt_id => i.id)
          if q_attempts.present? && !q_attempts.all? { |qa| qa.selected==false }
            valid_quiz_question_attempts << i.id
          end
        else
          q_attempt = McqQuestionAttempt.where(:quiz_question_attempt_id=>i.id).first
          if  !q_attempt.nil? && q_attempt.question_answer_id!=0
            valid_quiz_question_attempts << i.id
          end
        end
      end
    }
    QuizQuestionAttempt.where(id:valid_quiz_question_attempts)
  end

end
