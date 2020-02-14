class UserQuizData < ActiveRecord::Base
  serialize :result_json
  # attr_accessible :title, :body
end
