class QuestionImage < ActiveRecord::Base
 
belongs_to :question
attr_accessible :picture
has_attached_file :picture, :styles => { :medium => "300x300>", :thumb => "100x100>" }
end
