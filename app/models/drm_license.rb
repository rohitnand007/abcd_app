class DrmLicense < ActiveRecord::Base
  has_one :drm_content
end
