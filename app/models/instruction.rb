class Instruction < ActiveRecord::Base
  # attr_accessible :title, :body
  validates_presence_of :template_name
end
