module UsersHelper
  def asign_roles(user)
    case user.role.id
      when 1 #EA
        Role.where('id = ? or (id > ? and id < ?) ',16,user.role.id,8)
      when 2 #IA
        Role.where('id>=? and id<=?',user.role.id,7)
      when 3 #CR
        Role.where('id>? and id<?',user.role.id,7)
      when 5 #ET
        Role.where('id=?',4)
      else
        []
    end
    #if user.role.id==1 and user.role.id!=2
    # Role.where('id > ? and id < ? ',user.role.id,8)
    #elsif user.role.id==2
    # Role.where('id>=? and id<=?',user.role.id,7)
    #else
    # Role.where('id>? and id<?',user.role.id,7)
    #end
  end

  def asign_groups(user)
    #users = User.where('is_group =? and center_id=? and edutorid like ?',true,user.center_id,"%SG-%").select(:id)
    # profile = Profile.find_all_by_user_id(users)

    if current_user.is? 'EA'
      users = Institution.select(:id) + Center.select(:id)
      profile = Profile.find_all_by_user_id(users)
    elsif current_user.is?'IA' or current_user.is? 'EO'
      users = current_user.student_groups.select(:id) + current_user.centers.select(:id) + Institution.where(:id=>current_user.institution.id).select(:id)
      profile = Profile.find_all_by_user_id(users)
    elsif current_user.is?'CR'
      users = current_user.academic_classes.select(:id) + current_user.sections.select(:id) +current_user.student_groups.select(:id)
      profile = Profile.find_all_by_user_id(users)
    elsif current_user.is? 'ET'
      #users = current_user.groups.select("users.id") + current_user.base_groups
      #profile = Profile.find_all_by_user_id(users)
      # stduent_groups = StudentGroup.includes(:profile).where(:institution_id=>current_user.institution_id,:center_id=>current_user.center_id).map(&:id)
      stduent_groups = current_user.student_group_ids
      # getting all the sections/classes of teacher from classrooms and filtering to get only respective sections
      #current_user.sections.uniq
      profile = Profile.find_all_by_user_id(stduent_groups)
      # profile = Profile.find_all_by_user_id(((current_user.groups.select { |g| ["Institution", "Center"].exclude?(g.type) }.uniq.map(&:id) << current_user.section)+stduent_groups).uniq)
      #profile = profile.map {|u| Hash[user_id: u.id, firstname: u.user.academic_class.name+"_"+u.user.name]}
    else
      []
    end

  end

  def new_build_groups(user)
    #users = User.where('is_group =? and center_id=? and edutorid like ?',true,user.center_id,"%SG-%").select(:id)
    # profile = Profile.find_all_by_user_id(users)

    if current_user.is? 'EA'
      users = Institution.select(:id) + Center.select(:id)
      profile = Profile.find_all_by_user_id(users)
    elsif current_user.is?'IA'
      users = current_user.student_groups.select(:id) + current_user.centers.select(:id) + Institution.where(:id=>current_user.institution.id).select(:id)
      profile = Profile.find_all_by_user_id(users)
    elsif current_user.is?'CR'
      users = current_user.academic_classes.select(:id) + current_user.sections.select(:id) +current_user.student_groups.select(:id)
      profile = Profile.find_all_by_user_id(users)
    elsif current_user.is? 'EO'
      student_groups = current_user.student_group_ids
      profile = Profile.find_all_by_user_id(student_groups)
    elsif current_user.is? 'ET'
      #users = current_user.groups.select("users.id") + current_user.base_groups
      #profile = Profile.find_all_by_user_id(users)
      # stduent_groups = StudentGroup.includes(:profile).where(:institution_id=>current_user.institution_id,:center_id=>current_user.center_id).map(&:id)
      stduent_groups = current_user.student_group_ids
      # getting all the sections/classes of teacher from classrooms and filtering to get only respective sections
      #current_user.sections.uniq
      profile = Profile.find_all_by_user_id(stduent_groups)
      # profile = Profile.find_all_by_user_id(((current_user.groups.select { |g| ["Institution", "Center"].exclude?(g.type) }.uniq.map(&:id) << current_user.section)+stduent_groups).uniq)
      #profile = profile.map {|u| Hash[user_id: u.id, firstname: u.user.academic_class.name+"_"+u.user.name]}
    else
      []
    end

  end



  #breadcrumbs
  def bread_crumb_show_page
    if current_et
      content_tag(:ul,
=begin
                  content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
                  content_tag(:li,"#{link_to  'My Classes', teacher_path(current_user)}".html_safe) +
=end
                  content_tag(:li,"#{link_to  'Student Information', '#',{:class=>'current'}}".html_safe) )
    else
      content_tag(:ul,
=begin
                  content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
                  content_tag(:li,"#{link_to  'Users', users_path}".html_safe) +
=end
                  content_tag(:li,"#{link_to   'Student Information', '#',{:class=>'current'}}".html_safe) )
    end
  end

 def pearson_assign_groups(user)
    users = User.select(:id).where(:institution_id=>user.institution_id,:is_group=>true)
    profiles = Profile.find_all_by_user_id(users)
    options = profiles.collect{|i|[i.display_name+"--"+i.user.type,i.user_id]}
  end


end
