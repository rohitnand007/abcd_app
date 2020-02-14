class ContentPath < ActiveRecord::Base
belongs_to :content,  :foreign_key => 'id'
end