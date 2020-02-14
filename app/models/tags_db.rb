class TagsDb < ActiveRecord::Base
	#columns: id, db_name
	has_many :users_tags_dbs, :class_name => "UsersTagsDb" ,:foreign_key => :tags_db_id, :dependent => :destroy
	has_many :tags, :dependent => :destroy
	has_many :users, :through => :users_tags_dbs

end