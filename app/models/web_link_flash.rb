class WebLinkFlash < ActiveRecord::Base
  belongs_to :web_link

  has_attached_file :attachment,
                    :url=>"public/weblinks/flash/:id/:basename" + ".:extension",
                    :path => ":rails_root/:url"
end
