class ClassRoom < ActiveRecord::Base
 #THE callbacks need to be placed first line beacasue this is nested with teacher
  #before_save :set_content
  #THE callbacks need to be placed first line beacasue this is nested with teacher

  belongs_to :teacher
  #belongs_to :content

  belongs_to :user_group,:primary_key => 'group_id' ,:foreign_key => 'group_id',:class_name => 'User'


  
  #classroom belongs to group/section
  belongs_to  :section,:foreign_key => "group_id"
  belongs_to :student_group,:foreign_key => "group_id"

  attr_accessor :board_id,:year_id,:class_teacher



  def set_content
    self.content_id = self.year_id if self.class_teacher == "1" or self.content_id.blank? or self.content_id.nil?
  end

  validates :group_id,:presence=>true

  def class_room_group
    #for class_room.section.nil? ? class_room.student_group.name : class_room.section.academic_class.name
    self.section.nil? ? self.student_group : self.section.academic_class
  end


end
