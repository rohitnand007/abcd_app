module ApplicationHelper

  #milliseconds to datetime
  #example: Time.at(User.last.created_at.to_datetime.strftime("%s").to_i).to_datetime
  def milli_to_datetime(milliseconds)
    Time.at(milliseconds.to_i).to_datetime
  end




  def show_content_path(content)
    if content.type.eql?("Chapter")
      chapter_path(content)
    elsif content.type.eql?("Topic")
      topic_path(content)
    elsif content.type.eql?("SubTopic")
      sub_topic_path(content)
    elsif content.type.eql?("Assessment")
      assessment_path(content)
    else
      content_path(content)
    end
  end

  def content_edit_path(content)
    if content.type.eql?("Chapter")
      edit_chapter_path(content)
    elsif content.type.eql?("Topic")
      edit_topic_path(content)
    elsif content.type.eql?("SubTopic")
      edit_sub_topic_path(content)
    elsif content.type.eql?("Assessment")
      edit_assessment_path(content)
    else
      edit_content_path(content)
    end
  end

  def display_content_status(status)
    if status != nil
      Content::STATUS[status].to_s
    end
  end

  def content_lock(locked)
    if locked == 1
      image_tag "lock_small.png" ,:align => 'right'
    else
      image_tag "unlock_small.png" ,:align => 'right'
    end
  end

  def set_url_store(url,content)
    link = []
    case content.type
      when "Subject"
        link <<  url.sub("?subject=#{content.id}&","?")
        link <<  url.sub("?subject=#{content.id}","")
        link <<  url.sub("&subject=#{content.id}","")
        link = link - [url]
        return  link[0].to_s
      when "ContentYear"
        link <<  url.sub("?year=#{content.id}&","?")
        link <<  url.sub("?year=#{content.id}","")
        link <<  url.sub("&year=#{content.id}","")
        link = link - [url]
        return  link[0].to_s
      when "Course"
        link <<  url.sub("?course=#{content.id}&","?")
        link <<  url.sub("?course=#{content.id}","")
        link <<  url.sub("&course=#{content.id}","")
        link = link - [url]
        return  link[0].to_s
    end

  end

  def link_to_edit(path)
    link_to image_tag('web-app-theme/themes/default/icons/edit.png' ,:title=>'Edit',:class=>'tipTipTop'),path
  end

  def link_to_show(path)
    link_to image_tag('web-app-theme/themes/default/icons/show.png',:title=>'Show',:class=>'tipTipTop'), path
  end

  def link_to_delete(path)
    link_to(image_tag('web-app-theme/themes/default/icons/delete.png',:title=>'Delete',:class=>'tipTipTop'),path,:class=>'delete_record', :remote=>true,:method => :delete, :confirm => "#{t("web-app-theme.confirm", :default => "Are you sure?")}")
  end

  def link_to_download(path,title)
    link_to image_tag('web-app-theme/themes/default/icons/download.png',:title=>title,:class => 'tipTipTop'), path
  end

  def link_to_upload(path,title)
    link_to image_tag('web-app-theme/themes/default/icons/upload.png',:title=>title,:class => 'tipTipTop'), path
  end

  def link_to_contact(path,title)
    link_to image_tag('web-app-theme/themes/default/icons/contact.png',:title=>title,:class => 'tipTipTop'), path
  end

  def link_to_reject(path,title)
    link_to image_tag('web-app-theme/themes/default/icons/reject.png',:class=>'tipTipTop',:title=>title), path
  end

  def link_to_publish(path,title)
    link_to image_tag('web-app-theme/themes/default/icons/publish.png',:class=>'tipTipTop',:title=>title), path
  end

  def link_to_menu(text)
    link_to content_tag(:span,"#{text} #{content_tag(:em,image_tag('web-app-theme/themes/default/menubar-downarrow.png'))}".html_safe) ,"#"
  end


  def display_boards(object)
    object.boards.map(&:name).join(',')
  end

  def institute_admins_with_links(institute_admins)
    raw institute_admins.map{|ia| link_to ia.edutorid,user_path(ia) }.join(',')
  end

  def center_admins_with_links(center_admins)
    raw center_admins.map{|ca| link_to ca.edutorid,user_path(ca) }.join(',')
  end

#Ajax - Spinner

  def ajax_spinner(id)
    content_tag(:span,image_tag('ajax-loader.gif',:alt=>'loading...'),:class=>'ajax_spinner',:id=>id)
  end


  def display_date_time(value)
    if !value.nil?
      if value.class == Bignum      #If Integer
        Time.at(value).to_datetime.strftime("%d-%b-%Y %I:%M %p")
      elsif value.class == DateTime #If Datetime
        value.strftime("%d-%b-%Y %I:%M %p")
      else
        Time.at(value).strftime("%d-%b-%Y %I:%M %p")
      end
    end
=begin
      %a - The abbreviated weekday name (``Sun'')
      %A - The  full  weekday  name (``Sunday'')
      %b - The abbreviated month name (``Jan'')
      %B - The  full  month  name (``January'')
      %c - The preferred local date and time representation
      %d - Day of the month (01..31)
      %H - Hour of the day, 24-hour clock (00..23)
      %I - Hour of the day, 12-hour clock (01..12)
      %j - Day of the year (001..366)
      %m - Month of the year (01..12)
      %M - Minute of the hour (00..59)
      %p - Meridian indicator (``AM''  or  ``PM'')
      %S - Second of the minute (00..60)
      %U - Week  number  of the current year,
                                        starting with the first Sunday as the first
      day of the first week (00..53)
      %W - Week  number  of the current year,
                                        starting with the first Monday as the first
      day of the first week (00..53)
      %w - Day of the week (Sunday is 0, 0..6)
      %x - Preferred representation for the date alone, no time
      %X - Preferred representation for the time alone, no date
      %y - Year without a century (00..99)
      %Y - Year with century
      %Z - Time zone name
      %% - Literal ``%'' character
=end
  end


  def build_checkbox_tags(objects,type)
    boxes = ''
    params["#{type}_ids"] ||= []
    unless objects.blank?
      objects.each do |obj|
        boxes <<   "<label class='filters-list'>"
        boxes << (check_box_tag "#{type}_ids[]",obj.id,params["#{type}_ids"].include?(obj.id.to_s) ? true : false ,{:class=>'filter_value',:onclick=>"mode_type('#{type}')"})
        boxes << "<span>#{obj.name}</span>"
        boxes << "</label>"
      end
    end
    raw boxes
  end

  def institutions
    (current_user.is?'EA') ? Institution.includes(:profile) : []
  end

  def centers
    (current_user.is?'IA') ? current_user.centers : []
  end

  def academic_classes
    if current_user.is?'CR'
      return current_user.center.academic_classes
    elsif current_user.is?'ET'
      return current_user.center.academic_classes
    else
      return []
    end
    #(current_user.is?'CR') ? current_user.center.academic_classes : []
  end

  def sections
    []
  end

  def get_contents
    if current_user.is? 'ET'
      current_user.class_contents
    else
      current_user.center.boards.map{|board| board.subjects}.flatten
    end
  end

  def disable_with_text(f)
    f.object.new_record? ? 'Creating...' : 'Updating...'
  end

  def get_class_rooms
    case current_user.type
      when 'Teacher'
        current_user.teacher_class_rooms
      when 'InstituteAdmin'
        current_user.institution.class_rooms.group(:group_id)
      when 'CenterAdmin'
        current_user.center.class_rooms.group(:group_id)
      else
        ClassRoom.group(:group_id)
    end
  end


=begin  def get_sections_or_groups_to_teacher
    case current_user.role.name
      when 'Institute Admin'
        current_user.sections+current_user.student_groups
      when 'Center Representative'
        current_user.sections+current_user.student_groups
      when 'Edutor Admin'
        Section.all + StudentGroup.all
      else
        []
    end

  end
=end

  def get_sections_or_groups_to_teacher
    params[:id].present? ? Teacher.find(params[:id]).try(:center).try(:sections) : []
  end

  def get_boards_to_teacher
    case current_user.rc
      when 'CR'
        current_user.center.boards
      when 'IA'
        current_user.institution.boards
      when 'EA'
        Board.all
      else
        []
    end
  end

  #used for cancan permission checks
  def display_link(name,path,action,model,*li_class)
    if can? action,model
      content_tag(:li,"#{link_to  name, path}".html_safe,:class => li_class)
    end
  end

  def bread_crumb_chapters_page
    if current_et
      content_tag(:ul,
                  content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
                      content_tag(:li,"#{link_to  'Upload Content',home_view_contents_path}".html_safe) +
                      content_tag(:li,"#{link_to  'Content List', teacher_contents_path}".html_safe) +
                      content_tag(:li,"#{link_to  'New Chapter', '#',{:class=>'current'}}".html_safe) )
    else
      content_tag(:ul,
                  content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
                      content_tag(:li,"#{link_to  'Chapters','#',{:class=>'current'}}".html_safe) )
    end
  end

  def bread_crumb_topics_page
    if current_et
      content_tag(:ul,
                  content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
                      content_tag(:li,"#{link_to  'Upload Content',home_view_contents_path}".html_safe) +
                      content_tag(:li,"#{link_to  'Content List', teacher_contents_path}".html_safe) +
                      content_tag(:li,"#{link_to  'New Topic', '#',{:class=>'current'}}".html_safe) )
    else
      content_tag(:ul,
                  content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
                      content_tag(:li,"#{link_to  'Topics','#',{:class=>'current'}}".html_safe) )
    end
  end

  def bread_crumb_sub_topics_page
    if current_et
      content_tag(:ul,
                  content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
                      content_tag(:li,"#{link_to  'Upload Content',home_view_contents_path}".html_safe) +
                      content_tag(:li,"#{link_to  'Content List', teacher_contents_path}".html_safe) +
                      content_tag(:li,"#{link_to  'New SubTopic', '#',{:class=>'current'}}".html_safe) )
    else
      content_tag(:ul,
                  content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
                      content_tag(:li,"#{link_to  'Sub Topics','#',{:class=>'current'}}".html_safe) )
    end
  end

  #content name for given id. Method used in content manage template
  def content_name(id)
    content = Content.find_by_id(id)
    if !content.nil?
      content.name
    else
      return false
    end

  end

  #to display link for user if IA or CA
  def display_edit_link_for_user(user)
    if user.type.eql?'InstituteAdmin'
      display_link("Edit",edit_institute_admin_path(user),:update,User)
    elsif user.type.eql?'CenterAdmin'
      display_link("Edit",edit_center_admin_path(user),:update,User)
    else
      display_link("Edit",edit_user_path(user),:update,User)
    end
  end

  #to display button for user if IA or CA
  def display_edit_button_for_user(user)
    if user.type.eql?'InstituteAdmin'
      link_to "Edit",edit_institute_admin_path(user), :class => "button icon edit"
    elsif user.type.eql?'CenterAdmin'
      link_to "Edit",edit_center_admin_path(user), :class => "button icon edit"
    else
      display_link("Edit",edit_user_path(user),:update,User,"button icon edit")
    end
  end

  #to check the content elements radio buttons checked

  def content_lock_status(value,lock_status)
    if value.to_s == lock_status.to_s
      i = true
    else
      i = false
    end
    return i
  end

  #Rewriting the wicked_pdf_image_tag for paperclip images

  def wicked_pdf_paperclip_image_tag(img, options={})
    if img[0].chr == "/" # images from paperclip
      new_image = img.slice 1..-1
      image_tag "file://#{Rails.root.join('public', new_image)}", options
    else
      image_tag "file://#{Rails.root.join('public', 'images', img)}", options
    end
  end

 def wicked_pdf_css_image_tag(img, options={})
    if img[0].chr == "/" # images from paperclip
      new_image = img.slice 1..-1
       "file://#{Rails.root.join('public', new_image)}"
    else
      "file://#{Rails.root.join('public', 'images', img)}"
    end
  end

  def question_attempt_average(total_students,question)
    attempts = QuizQuestionAttempt.where(:user_id=>total_students,:question_id=>question).count
    correct_attempts = QuizQuestionAttempt.where(:user_id=>total_students,:question_id=>question,:correct=>true).count
    average = (correct_attempts.to_f/attempts)*100

  end

  # Todo Calculate the percentile for a given quiz and score

  def quiz_percentile(publish,marks,total)
    marks_less = 0
    #L/N(100) = P
    return 0
  end


  # Message Acknowledgement status

  def message_status(status)
    message_status = {:'1'=>'MESSAGE RECIEVED',:'2'=>'MESSAGE DOWNLOADED',:'3'=>'MESSAGE EXECUTED',:'4'=>'MESSAGE READ',:'-1'=>'MESSAGE DOWNLOAD FAILED',:'-2'=>'MESSAGE EXECUTION FAILED',:'-3'=>'MESSAGE EXTRACTION FAILED'}
    return message_status[:"#{status}"]
  end

  # To calculate the usage duration

  def show_usage_duration(start_time,end_time)
    # distance_of_time_in_words( (end_time-start_time)/60 )
    if start_time != 0
      total_seconds = (end_time-start_time)

      seconds = total_seconds % 60
      minutes = (total_seconds / 60) % 60
      hours = total_seconds / (3600)

      time = ''

      if(hours > 0)
        time = format("%dh ", hours)
      end

      if(minutes > 0)
         time +=format("%dm ", minutes)
      end

      if(seconds > 0)
        time +=format("%02ds ", seconds)
      end

      return time
    end
  end

  def show_duration(total_seconds)
    # distance_of_time_in_words( (end_time-start_time)/60 )
    if total_seconds != 0

      seconds = total_seconds % 60
      minutes = (total_seconds / 60) % 60
      hours = total_seconds / (3600)

      time = ''

      if(hours > 0)
        time = format("%dh ", hours)
      end

      if(minutes > 0)
        time +=format("%dm ", minutes)
      end

      if(seconds > 0)
        time +=format("%02ds ", seconds)
      end

      return time
    end
  end



  def show_usage_session(start_time,end_time)
    # distance_of_time_in_words( (end_time-start_time)/60 )
    if start_time != 0
      total_seconds = (end_time-start_time)/1000

      seconds = total_seconds % 60
      minutes = (total_seconds / 60) % 60
      hours = total_seconds / (3600)

      time = ''

      if(hours > 0)
        time = format("%dh ", hours)
      end

      if(minutes > 0)
        time +=format("%dm ", minutes)
      end

      if(seconds > 0)
        time +=format("%02ds ", seconds)
      end

      return time
    end
  end

  def quiz_question_not_attempted(question_attempts,questions_count)
    question_attempts.count
  end


  def ignitor_assign_groups(user)
    if user.is?'EA'
      users = User.select(:id).where(:is_group=>true)
     else
      users = User.select(:id).where(:institution_id=>user.institution_id,:is_group=>true)
    end

    profiles = Profile.find_all_by_user_id(users)
    options = profiles.collect{|i|[i.display_name+"--"+i.user.type,i.user_id]}
  end

  def display_details
    id = current_user.edutorid
    a_class = AcademicClass.includes(:profile).find(current_user.academic_class_id).name  if !current_user.academic_class_id.nil?
    center = Center.includes(:profile).find(current_user.center_id).name if !current_user.center_id.nil?
    ins = Institution.includes(:profile).find(current_user.institution_id).name if !current_user.institution_id.nil?

    return "#{ins} #{center} #{a_class} #{id}"
  end
 
 #Display the date as per the South Africa time zone
  def display_as_timezone(time)
    time.strftime("%d-%b-%Y %I:%M %p")
    #Time.use_zone('Pretoria') do
    #  time.in_time_zone.strftime("%d-%b-%Y %I:%M %p")
    #end
  end



  #Display the date as per the South Africa time zone
  def display_as_timezone(time)
    time.strftime("%d-%b-%Y %I:%M %p")
    #Time.use_zone('Pretoria') do
    #  time.in_time_zone.strftime("%d-%b-%Y %I:%M %p")
    #end
  end

def link_to(name = nil, options = nil, html_options = nil, &block)
  super
end

end


