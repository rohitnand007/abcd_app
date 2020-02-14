class QuizIbookLocation < ActiveRecord::Base
  belongs_to :ibook
  belongs_to :quiz_targeted_group
  after_create :set_uri

  def set_uri
    self.update_attribute(:uri, self.uri.split("$").first + "/" + self.quiz_targeted_group.quiz.name + "_" + Time.now.to_i.to_s) if self.quiz_targeted_group
  end
end
