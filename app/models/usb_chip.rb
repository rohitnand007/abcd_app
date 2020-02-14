class UsbChip < ActiveRecord::Base
  validates_presence_of :chipid, :chip_size, :extras
  # validates_uniqueness_of :chipid
end
