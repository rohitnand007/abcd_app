class Ipack < ActiveRecord::Base
  has_and_belongs_to_many :ibooks
  has_many :license_sets
  validates_uniqueness_of :name, scope: :publisher_id
  validates_presence_of :name

  def created_date
    Time.at(self.created_at).strftime("%d/%m/%Y")
  end

  def assigned?
    self.license_sets.present?
  end
end
