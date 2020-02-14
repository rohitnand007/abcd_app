class ContentProfile < ActiveRecord::Base
  belongs_to :content
  #has_one :asset, :as=>:attachment_class
  composed_of :expiry_date,:class_name => 'Time',:mapping => %w(expiry_date to_i),:constructor => Proc.new{ |item| item },:converter => Proc.new{ |item| item }

  def expiry_date
    Time.at(self[:expiry_date]) unless self[:expiry_date].nil?
  end

end