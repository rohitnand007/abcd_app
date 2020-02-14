class StudentGroupOwner < ActiveRecord::Base
  attr_accessible :student_group_id, :user_id

  belongs_to :user
  belongs_to :student_group

  validates :student_group_id, uniqueness: true
end
