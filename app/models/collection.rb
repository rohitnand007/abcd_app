class Collection < ActiveRecord::Base
  has_many :book_collections, :dependent => :destroy
  has_many :books, :through=>:book_collections
  has_many :user_book_collections, :dependent => :destroy #, :after_add=>:check
  has_many :users,:through=>:user_book_collections
  attr_accessor :collection_books
  belongs_to :user
  #attr_accessible :multiple_recipient_ids

  validates :name, :presence => true

  def check(book_collection)
    unless self.user_id.nil?
      UserGroup.joins(:user).includes(:user).where(:group_id=>self.user_id).each do |user|
        command ="mosquitto_pub -p 3333 -t #{user.user.edutorid} -m 16  -i Edeployer -q 2 -h 173.255.254.228"
        system(command)
      end
    end
  end

end
