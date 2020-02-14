class BookCover < ActiveRecord::Base
  belongs_to :book

  has_attached_file :attachment,
                    :url=>"pearson_books/covers/:id/:basename" + ".:extension",
                    :path => ":rails_root/public/:url"


  validates_attachment_presence :attachment

end
