class PassageQuestion < ActiveRecord::Base
  belongs_to :question
  has_many :questions, foreign_key: :question_id
end
