class MasterchipDetails < ActiveRecord::Base
  validates_presence_of :course
  belongs_to :masterchip
  has_one :asset, :as => :archive, :dependent => :destroy
  accepts_nested_attributes_for :asset, :allow_destroy=>true, :reject_if => :all_blank

end
