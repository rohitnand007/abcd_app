class CdnCenter < ActiveRecord::Base
	belongs_to :cdn_config
	belongs_to :center
end
