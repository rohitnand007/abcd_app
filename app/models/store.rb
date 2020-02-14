class Store < ActiveRecord::Base
  has_many :publisher_stores
  has_many :publishers, :through => :publisher_stores, :uniq => true
  belongs_to :store_admin
  has_and_belongs_to_many :institutions, :uniq=> true
  after_create :create_store_admin

  def create_store_admin
    sta=StoreAdmin.create({email: "store_admin"+Time.now.to_i.to_s+"@ignitorlearning.com",
                           role_id: 19,
                           password: 'edutor',
                           edutorid: Time.now.to_i,
                           rollno: Time.now.to_i,
                           spree_api_key: Time.now.to_i
                          })
    sta.is_activated = true
    sta.is_group = false
    sta.confirmed_at = Time.now.to_i
    sta.confirmation_token = nil
    sta.save
    sta.create_profile(:firstname => 'STA')
    self.update_attribute :store_admin_id, sta.id
  end

  def v1_books_count
    v1books = 0
    self.publishers.each do |publisher| 
      books=publisher.ibooks.select{|ibook| ibook if ibook.version==1}.count
      v1books+=books
    end
    v1books
  end
  def v2_books_count
    v2books = 0
    self.publishers.each do |publisher| 
      books=publisher.ibooks.select{|ibook| ibook if ibook.version==2}.count
      v2books+=books
    end
    v2books
  end
end
