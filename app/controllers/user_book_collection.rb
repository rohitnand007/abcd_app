class UserBookCollection < ActiveRecord::Base
  belongs_to :user
  belongs_to :collection
  attr_accessor :multiple_user_ids
end
