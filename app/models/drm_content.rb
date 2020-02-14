class DrmContent < ActiveRecord::Base
  belongs_to :drm_publisher
  belongs_to :drm_license
  has_many :drm_assets
  has_many :user_content_keys, :foreign_key=>'content_id'
end
