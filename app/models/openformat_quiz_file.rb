class OpenformatQuizFile < ActiveRecord::Base
  belongs_to :message
  belongs_to :quiz_targeted_group
  has_many :user_openformat_quiz_code

end
