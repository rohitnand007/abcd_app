class MessageQuizTargetedGroup < ActiveRecord::Base
  belongs_to :quiz_targeted_group
  belongs_to :message
end
