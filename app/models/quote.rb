class Quote < ActiveRecord::Base
  has_many :user_quotes
  attr_accessor :author
  validates :name,:author, :presence=>true
end
