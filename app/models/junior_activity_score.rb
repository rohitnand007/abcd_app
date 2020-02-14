class JuniorActivityScore < ActiveRecord::Base
validates :user_id,:presence => true,:uniqueness => {:scope => [:user_id,:label]}
end
