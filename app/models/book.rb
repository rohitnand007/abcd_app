class Book < ActiveRecord::Base

  has_one :book_asset, :dependent => :destroy , :inverse_of => :book
  has_one :book_cover, :dependent => :destroy
  has_one :book_key, :dependent => :destroy
  belongs_to :book_publisher
  has_many :book_collections, :dependent => :destroy
  has_many :collections, :through => :book_collections
  accepts_nested_attributes_for :book_asset
  accepts_nested_attributes_for :book_cover
  accepts_nested_attributes_for :book_key

  validates :name, :presence => :true
  validates_associated :book_asset , :book_key
  validates :isbn, :uniqueness=>true

end
