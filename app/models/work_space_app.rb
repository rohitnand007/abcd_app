class WorkSpaceApp < ActiveRecord::Base
  belongs_to :user
  attr_accessor :multiple_recipient_ids

end
