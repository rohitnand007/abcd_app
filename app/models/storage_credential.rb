class StorageCredential < ActiveRecord::Base
  belongs_to :publisher
  # attr_accessible :title, :body
end
