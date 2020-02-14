class ChipFsInfo < ActiveRecord::Base
  has_one :masterchip
  #after_create :set_attributes
  def set_attributes
    update_attributes(:available_blocks=>self.available_blocks.to_i-1,:free_blocks=>self.free_blocks.to_i-1)
  end
end
