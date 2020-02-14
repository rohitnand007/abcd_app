class Simulation < ActiveRecord::Base
  attr_accessible :asset_guid, :book_guid, :extra_info, :screenshot, :user_id
  has_attached_file :screenshot, :path =>  ":rails_root/public/system/:class/:attachment/:user_id/:book_guid/:asset_guid/:filename"
  validates :screenshot, :attachment_presence => true
  # validates :screenshot,:content_type => { :content_type => "image/png" }

end
