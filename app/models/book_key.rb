class BookKey < ActiveRecord::Base
  belongs_to :book

  has_attached_file :attachment,
                    :url=>"pearson_books/keys/:id/:basename" + ".:extension",
                    :path => ":rails_root/:url"

  validates_attachment_presence :attachment
  validates  :attachment_file_name, :uniqueness => true
end
