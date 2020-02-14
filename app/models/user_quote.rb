class UserQuote < ActiveRecord::Base
  belongs_to :quote
  belongs_to :user
 validates :quote_id, :uniqueness => {:scope =>[:user_id]}
end
