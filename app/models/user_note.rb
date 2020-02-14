class UserNote < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :asset_guid, :book_guid, :note_type, :page_no, :color, :note_id, :notes_data, :user_id
  serialize :notes_data
end
