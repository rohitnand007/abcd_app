class WhiteSchool < ActiveRecord::Base
  belongs_to :publisher
  belongs_to :center
  belongs_to :institution
end
