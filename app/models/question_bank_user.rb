class QuestionBankUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :publisher_question_bank

  validates_uniqueness_of :publisher_question_bank_id, :scope => :user_id

end
