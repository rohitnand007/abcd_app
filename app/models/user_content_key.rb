class UserContentKey < ActiveRecord::Base
  belongs_to :drm_content
  belongs_to :user
end
