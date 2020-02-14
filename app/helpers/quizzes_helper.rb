module QuizzesHelper
  def assign_groups(user)
    #users = User.where('is_group =? and center_id=? and edutorid like ?',true,user.center_id,"%SG-%").select(:id)
   # profile = Profile.find_all_by_user_id(users)

    if current_user.is? 'EA'
       users = Institution.select(:id) + Center.select(:id)
       profile = Profile.find_all_by_user_id(users)
    elsif current_user.is?'IA'
       users = current_user.student_groups.select(:id) + current_user.centers.select(:id)
       profile = Profile.find_all_by_user_id(users)
     elsif current_user.is?'CR'
       users = current_user.academic_classes.select(:id) + current_user.sections.select(:id) +current_user.student_groups.select(:id)
       profile = Profile.find_all_by_user_id(users)
     elsif current_user.is? 'ET'
       #users = current_user.groups.select("users.id") + current_user.base_groups
       #profile = Profile.find_all_by_user_id(users)

       # getting all the sections/classes of teacher from classrooms and filtering to get only respective sections
       #current_user.sections.uniq
       profile = Profile.find_all_by_user_id(current_user.sections.uniq.map(&:id) << current_user.section)
       #profile = profile.map {|u| Hash[user_id: u.id, firstname: u.user.academic_class.name+"_"+u.user.name]}
     else
      []
     end

  end
end
