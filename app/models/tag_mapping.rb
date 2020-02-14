class TagMapping < ActiveRecord::Base
	belongs_to :taggable, :polymorphic => true
	belongs_to :tag

	validates_presence_of :tag_id, :taggable_id, :taggable_type
	validates_uniqueness_of :tag_id, :scope => [:taggable_id, :taggable_type]
end