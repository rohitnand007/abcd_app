class BookCollection < ActiveRecord::Base
  belongs_to :book
  belongs_to :collection

  #after_save :

end
