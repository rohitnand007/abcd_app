
module Overrides
  # put your getter and setter overrides in this module.
  def created_at
    (Time.at(self[:created_at]).to_datetime) unless self[:created_at].nil?
  end

  def updated_at
    (Time.at(self[:updated_at]).to_datetime) unless self[:updated_at].nil?
  end
end
