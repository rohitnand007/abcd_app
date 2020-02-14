class IgnitorUserChip < ActiveRecord::Base
  belongs_to :user
  def powerchip
    nil
  end
end
