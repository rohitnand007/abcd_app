class UsersTagsDb < ActiveRecord::Base
	#columns :user_id, :tags_db_id
	belongs_to :user 
	belongs_to :tags_db
	validates_uniqueness_of :user_id #, :scope => [:tags_db_id]
end