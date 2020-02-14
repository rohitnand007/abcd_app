class BuildInfo < ActiveRecord::Base
  attr_accessible :build_number
  belongs_to :section
  belongs_to :student_group
  attr_accessible :user_id
end
