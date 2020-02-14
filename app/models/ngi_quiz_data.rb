class NgiQuizData < ActiveRecord::Base
  validates_uniqueness_of :publish_id
  # attr_accessible :title, :body
end
