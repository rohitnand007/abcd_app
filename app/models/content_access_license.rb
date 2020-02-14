class ContentAccessLicense < ActiveRecord::Base
	belongs_to :license_set
	belongs_to :content_access_permission

	validates_presence_of :license_set_id, :content_access_permission_id
	validates_uniqueness_of :license_set_id, :scope=>[:content_access_permission_id]

end