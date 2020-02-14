module TeachersHelper
  #to disable the changing of center if teacher is associated with atleast one of the class
  def any_assigned_classes?
    params[:id].present? ?  Teacher.find(params[:id]).try(:teacher_class_rooms).any? :  true
  end
end
