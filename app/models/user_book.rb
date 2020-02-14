class UserBook < ActiveRecord::Base
  belongs_to :book
  validates :book_name,:presence => true, :uniqueness => {:scope => [:user_id]}
end
