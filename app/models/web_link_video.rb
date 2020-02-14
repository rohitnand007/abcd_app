class WebLinkVideo < ActiveRecord::Base
  belongs_to :web_link

  has_attached_file :attachment,
                    :url=>"public/weblinks/video/:id/:basename" + ".:extension",
                    :path => ":rails_root/:url"
end
