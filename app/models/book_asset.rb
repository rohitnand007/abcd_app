class BookAsset < ActiveRecord::Base
  belongs_to :book, :inverse_of => :book_asset

  has_attached_file :attachment,
                    :url=>"pearson_books/books/:id/:basename" + ".:extension",
                    :path => ":rails_root/:url"

 validates_attachment_presence :attachment , :if => :check_file
 validates  :attachment_file_name, :uniqueness => true, :if=> :check_file

  def check_file
   if self.book.book_type == true
     false
   else
     true
   end
  end


end
