class DrmAsset < ActiveRecord::Base
  belongs_to :drm_content
  has_attached_file :attachment
end
