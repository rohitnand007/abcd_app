class QuizQuestionInstance < ActiveRecord::Base

  before_save :set_grade
  after_create :set_position

  belongs_to :quiz
  belongs_to :question

  def set_grade
    if self.grade.to_i == 0
      self.grade = self.question.defaultmark
      self.penalty = self.question.penalty
    end
  end

  def set_position
    if self.position.nil?
      self.update_column(:position,self.id)
    end
  end
end
