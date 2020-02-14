class PublisherStore < ActiveRecord::Base
  belongs_to :publisher
  belongs_to :store
  validates_uniqueness_of :store_id, :scope=>[:publisher_id]
end
