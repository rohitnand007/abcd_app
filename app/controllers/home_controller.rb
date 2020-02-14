class HomeController < ApplicationController
  require 'csv-mapper'
  require 'mqtt'

  skip_before_filter :authenticate_device_user , :only=>[:test_mqtt,:get_control_messages,:get_server_time,:initialize_forum_session,:message_download]
  skip_before_filter :authenticate_user!, :only=>[:oauth_callback, :test_mqtt,:get_control_messages,:get_server_time,:initialize_forum_session,:message_download,:get_class_details,:get_time,:juniortabstats,:pearson_usage,:get_pearson_usage,:get_user_caricature,:privacy_policy, :landing_page, :download_page]
  #caches_action :index

  def oauth_callback

    #client = OAuth2::Client.new('6c3b94f7-143e-4f76-8f28-8ab23ac8b9df', 'xQZrxosn2nBPoFFumfuT4jcFHY/Oh9qvBSK1y7BUmis=', :authorize_url => 'https://login.microsoftonline.com/7c4ea8eb-3db7-4f98-91fb-c46ff314fd43/oauth2/authorize?api-version=1.0' , :token_url => 'https://login.microsoftonline.com/7c4ea8eb-3db7-4f98-91fb-c46ff314fd43/oauth2/token?api-version=1.0')
    client = OAuth2::Client.new(ApplicationController::CLIENT_ID, ApplicationController::CLIENT_SECRET, :authorize_url => ApplicationController::AUTH_URL , :token_url => ApplicationController::TOKEN_URL)
    code = params[:code]
    session_state = params[:session_state]
    #user_client = params[:user_client]
    #if !user_client.nil?
    #  if user_client == 'win'
    #    token = client.auth_code.get_token(code, :redirect_uri => ApplicationController::REDIRECT_URI1 ,:resource => ApplicationController::RESOURCE)
    #  else
    #    token = client.auth_code.get_token(code, :redirect_uri => ApplicationController::REDIRECT_URI ,:resource => ApplicationController::RESOURCE)
    #  end
    #else
    #  token = client.auth_code.get_token(code, :redirect_uri => ApplicationController::REDIRECT_URI ,:resource => ApplicationController::RESOURCE)
    #end
    token = client.auth_code.get_token(code, :redirect_uri => ApplicationController::REDIRECT_URI ,:resource => ApplicationController::RESOURCE)

    # username = JWT.decode(token.token, nil, false)['unique_name']
    profile = JWT.decode(token.token, nil, false)
    username = profile['unique_name']
    if User.find_by_email(username).nil?
      @teacher = Teacher.new
      @teacher.password="edutor"
      @teacher.email= profile['unique_name']
      @teacher.is_activated = true
      @teacher.institution_id = 130120
      @teacher.center_id = 130122
      @teacher.academic_class_id = 130124
      @teacher.section_id = 130125
      @teacher.is_group = false
      @teacher.is_class_teacher = true
      @teacher.role_id = 5
      @teacher.save
      first_name = profile['given_name']
      last_name = profile['family_name']
      @teacher.create_profile(:firstname=>first_name,:surname=>last_name)
    end
    #a = Base64.decode64 token.token.split('.')[1]
    #b = JSON.load a
    #username = b['unique_name']
    cookies['_auth_name'] = Base64.encode64 username
    cookies['_auth_ses']= ApplicationController::CLIENT_ID+ 'XXX' + session_state
    #flash[:error] = code
    respond_to do |format|
      format.html { redirect_to root_path}
    end
  end

  def landing_page

    render :layout=>false

  end

  def download_page

    render :layout => false

  end

  def index
    if user_signed_in?

      @inst = Institution.includes(:academic_class,:section,:profile).find(current_user.institution_id) if !current_user.institution_id.nil?

      @cent = Center.includes(:profile).find(current_user.center_id) if !current_user.center_id.nil?

      @a_class = AcademicClass.includes(:profile).find(current_user.academic_class_id)  if !current_user.academic_class_id.nil?

      @sec = Section.includes(:profile).find(current_user.section_id) if !current_user.section_id.nil?



      if current_user.is?("IA") or current_user.is?("MOE") or current_user.is? ("EO")
        begin
          # @cents = @inst.centers
          # # container 1 data
          #
          # center_names = @cents.map(&:name)
          # insti_teachers = @inst.teachers.map(&:id)
          # insti_books_count = ContentAccessPermission.includes(:user).where("users.institution_id=? and accessed_content_type=?",@inst.id,"book").group(:accessed_content_guid).count.count
          # center_students = []
          # center_teachers = []
          # center_books = []
          # @cents.each do |center|
          #   center_students << center.students.count
          #   center_teachers << center.teachers.count
          #   center_books << ContentAccessPermission.includes(:user).where("users.center_id=? and accessed_content_type=?",center.id,"book").group(:accessed_content_guid).count.count
          #
          # end
          # @temporary_info_c1t1 = [@cents.count,@inst.students.count,@inst.teachers.count,insti_books_count]
          # # @temporary_info_c1t1 = [@cents.count,@inst.students.count,@inst.teachers.count,@inst.teachers.map{|a| a.ibooks.count}.inject(0,:+)]
          # @temporary_info_c1t2 = [center_names,center_students,center_teachers, center_books]
          #
          # # container 2 data
          # @tlm = UserUsage.includes(:user).where("users.institution_id=?",@inst.id)
          # total_learning_minutes = @tlm.sum(:duration).to_i/60
          # total_active_students = @tlm.where(" start_time > ?",4.weeks.ago.to_i).group(:user_id).having("sum(duration) > 3600").count.count
          # centerwise_tlm = @cents.map{|center|
          #   @tlm.where("users.center_id=?", center.id).sum(:duration).to_i/60
          # }
          # centerwise_active_students = @cents.map{|center|
          #   @tlm.where("users.center_id=? and  start_time > ? ",center.id,4.weeks.ago.to_i  ).group(:user_id).having("sum(duration) > 3600").count.count
          # }
          # @lm_container_info_t1 = [total_learning_minutes, total_active_students]
          # @lm_container_info_t2 = [center_names, centerwise_tlm, centerwise_active_students]
          #
          # #container 3 data
          # @usages = UserUsage.includes(:user).where("users.institution_id=? and start_time > ? ",@inst.id,4.weeks.ago.to_i)
          # total_videos = @usages.where("class_type=?",'videolecture').count
          # @total_questions = QuizQuestionAttempt.includes(:user).where("users.institution_id=? and attempted_at >?",@inst.id, 4.weeks.ago.to_i)
          # total_questions = @total_questions.count
          # total_ios =  @usages.count
          # centerwise_videos = []
          # centerwise_ques = []
          # centerwise_ios = []
          # @cents.map{|center|
          #   centerwise_videos << @usages.where("users.center_id=? and class_type=?",center.id,'videolecture')
          #   centerwise_ques <<  @total_questions.where("users.center_id=?",center.id)
          #   centerwise_ios << @usages.where("users.center_id=?",center.id)
          # }
          #
          # @se_container_info_t1 = [total_videos, total_questions, total_ios]
          # @se_container_info_t2 = [center_names, centerwise_videos, centerwise_ques, centerwise_ios]
          #
          # # container 4 data
          # a = []
          # @cents.each do |center|
          #   cent_teachers =  center.teachers.map(&:id)
          #   a << [center.name, User.active_teacher_tests_assets_consolidated(cent_teachers) ]
          # end
          # centers_c4t2 = []
          # active_teachers_c4t2 = []
          # tests_c4t2 = []
          # lo_c4t2 = []
          # a.each do |k|
          #   centers_c4t2 << k[0]
          #   active_teachers_c4t2 << k[1][:active_teachers]
          #   tests_c4t2 << k[1][:tests_published]
          #   lo_c4t2 << k[1][:assets_published]
          # end
          # @teacher_container_info_t1 = User.active_teacher_tests_assets_consolidated(insti_teachers)
          # @teacher_container_info_t2 = [centers_c4t2, active_teachers_c4t2, tests_c4t2, lo_c4t2]
          landing_page_data = DashboardData.where(user_id:current_user.id).last.nil? ? DashboardData.populate_user_dashboard_data(current_user.id) : DashboardData.where(user_id:current_user.id).last
          all_landing_data = landing_page_data.mainpage_data rescue landing_page_data
          @temporary_info_c1t1 = all_landing_data[:temporary_info_c1t1]
          @temporary_info_c1t2 = all_landing_data[:temporary_info_c1t2]
          @teacher_container_info_t1 = all_landing_data[:teacher_container_info_t1]
          @teacher_container_info_t2 = all_landing_data[:teacher_container_info_t2]
          @lm_container_info_t1 = all_landing_data[:lm_container_info_t1]
          @lm_container_info_t2 = all_landing_data[:lm_container_info_t2]
          @se_container_info_t1 = all_landing_data[:se_container_info_t1]
          @se_container_info_t2 = all_landing_data[:se_container_info_t2]

          if current_user.institution.user_configuration.use_tags
            @publisher_question_banks = current_user.institution.publisher_question_banks
          end
        rescue
          render :text=>"Sorry something went wrong! we are working on it and get it fixed as soon as we can",:layout => "abcd_top_menu"
          return
        end

      end


      if current_user.is?("CR")

      end

      if current_user.is?("ET")
        begin
          #Teacher_login Container1

          # teacher_books = Ibook.where(:id=>current_user.ibooks.map(&:id))
          #
          # #subjects = teacher_books.group("subject,form").map{|book| [book.form, book.subject]}
          # subjects = teacher_books.group_by{|book| [book.form, book.subject]}.keys
          #
          # # sections = current_user.groups.where(type:"Section")
          # need_array = {}
          # sections_usages = []
          #
          # subjects.each do |s|
          #   need_array[s] = []
          #   m = 0
          #   teacher_books.where(subject:s[1],form:s[0]).each do |p|
          #     section_ids = User.includes(:content_access_permissions).select("users.section_id").where("center_id=? and users.rc=? and content_access_permissions.accessed_content_guid=?", @cent.id, "ES", p.ibook_id ).map(&:section_id).uniq
          #     #need_array[s] << [p.id,p.metadata["displayName"],[],[],[],[],[],[],[]] unless section_ids.empty?
          #     unless section_ids.empty?
          #       need_array[s] << [p.id,p.metadata["displayName"],[],[],[],[],[],[],[]]
          #     sections = Section.where(id:section_ids)
          #     sections.each do |sec|
          #       c_per = ContentAccessPermission.includes(:user).where("users.section_id=? and users.rc=? and accessed_content_guid=?",sec.id, "ES" ,p.ibook_id).group(:user_id).count
          #       stu_ids = c_per.keys
          #       c = c_per.count
          #       need_array[s][m][2] << sec.name
          #       need_array[s][m][3] << c
          #       duration = UserUsage.includes(:user).where("users.section_id = ? and users.id IN (?) and start_time > ? and book_id=?",sec.id, stu_ids ,4.weeks.ago.to_i,p.ibook_id)
          #       total_duration = duration.sum(:duration)
          #       need_array[s][m][4] << total_duration.to_i/60
          #       need_array[s][m][5]  << (total_duration.to_i/(sec.students.count*60))
          #       # vdo_usage = duration.where("class_type=?",'videolecture')
          #       # test_usage = duration.where("class_type IN (?)",["assessment-insti-tests","assessment-practice-tests"])
          #       # need_array[s][m][6] << vdo_usage.count
          #       # need_array[s][m][7] << test_usage.count
          #       need_array[s][m][8] << duration.count
          #     end
          #       m = m+1
          #     end
          #   end
          # end
          landing_page_data = DashboardData.where(user_id:current_user.id).last.nil? ? DashboardData.populate_user_dashboard_data(current_user.id) : DashboardData.where(user_id:current_user.id).last
          all_landing_data = landing_page_data.mainpage_data rescue landing_page_data
          @need_array = all_landing_data[:need_array].delete_if { |k, v| v.empty? }
          @need_array_books_count = @need_array.values.inject(0){|sum, x| sum + x.count}

          #teacher_login container3
          # quizzes_info = []
          # teacher_sections = current_user.groups.where(type:"Section").map(&:id)
          # latest_quizzes = Quiz.joins(:quiz_targeted_groups).where("createdby=? and timecreated>=? and quiz_targeted_groups.recipient_id IS NULL",current_user.id, 4.weeks.ago.to_i ).last(3)
          # latest_quizzes.each_with_index do |quiz,i|
          #   quizzes_info << [quiz.name,quiz.questions.count,[]]
          #   quiz.quiz_targeted_groups.where("recipient_id IS NULL").each do |qtb|
          #     quizzes_info[i][2] << [User.find(qtb.group_id).name ,Quiz.get_students_count_below_required_score(qtb)]
          #   end
          # end
          quizzes_info = all_landing_data[:quizzes_info]
          @quizzes_array = quizzes_info
          @quiz_graph_array = []
          i = 0
          quizzes_info.each do |k|
            @quiz_graph_array << [{:sections=>[], :a=>[],:b=>[],:c=>[]}]
            k[2].each do |m|
              @quiz_graph_array[i][0][:sections] << m[0]
              @quiz_graph_array[i][0][:a] << m[1][0]
              @quiz_graph_array[i][0][:b] << m[1][1]
              @quiz_graph_array[i][0][:c] << m[1][2]
            end
            i = i+1
          end
         rescue
           render :text=>"Sorry something went wrong! we are working on it and get it fixed as soon as we can",:layout => "abcd_top_menu"
           return
         end



        # @num_of_assessments = Quiz.where(createdby:current_user.id).count - Quiz.where(createdby:current_user.id).where(format_type:7).count
        #
        # quick_tests_unpublished = []
        #
        # Quiz.where(createdby:current_user.id).where(format_type:7).each{|p| quick_tests_unpublished << p.quiz_targeted_groups }
        #
        # @num_of_published_assessments = QuizTargetedGroup.where(published_by:current_user).count - quick_tests_unpublished.flatten.uniq.count
        #
        # @num_of_assets = current_user.user_assets.count
        #
        # @assigned_sections = current_user.sections.collect { |p| p.name }.to_s.gsub('[','').gsub(']','').gsub('"','')

      end

      if current_user.is?("ES")

      end

      if current_user.is?("ECP")
        redirect_to dashboard_publisher_url(current_user)
        return
        @publisher_question_banks = current_user.publisher_question_banks
      end
      render :layout => "abcd_top_menu"
      #@role = Role.find(current_user.role_id).name
    else
      #  redirect_to "/user/user_login"
      render template: 'errors/error_404',  status: 404, layout:false
    end
  end
  def datewise_quiz
    @date = params[:date]
    @final_quiz_data_page2 = []
    quiz_data = NgiQuizData.order('created_at DESC').all.collect{|p| {"date"=>p.quiz_date,"published_id"=>p.publish_id}}
    present_user = current_user
    quiz_data.select{|data| data["date"] == @date}.each do |refined_data|
      quiz_targeted_group_id = refined_data["published_id"]
      date = refined_data["date"]
      q_data = Quiz.ngi_home_page_data(present_user,quiz_targeted_group_id,date)
      @final_quiz_data_page2 << q_data
    end
    respond_to do |format|
      format.js { render partial: 'date_wise_quiz_data', :locals=>{:date=>@date,:data=>@final_quiz_data_page2} }
    end
  end

  #used for global search.
  def search
    if params[:mode] and params[:term].present?
      term = "%#{params[:term]}%"
      @search_term = params[:term]
      case params[:mode]
        when "User"
          case current_user.rc
            when 'EA'
              @users = params[:mode].constantize.students.by_profile_first_name_or_surname_or_roll_no_or_edutor_id(term).page(params[:page])
            when 'IA'
              @users = current_user.institution.students.by_profile_first_name_or_surname_or_roll_no_or_edutor_id(term).page(params[:page])
            when 'CR'
              @users = current_user.center.students.by_profile_first_name_or_surname_or_roll_no_or_edutor_id(term).page(params[:page])
            when 'ET'
              @users = current_user.academic_class.students.by_profile_first_name_or_surname_or_roll_no_or_edutor_id(term).page(params[:page])
          end
          render 'users/index'
        when "Institution"
          case current_user.rc
            when 'EA'
              @institutions = params[:mode].constantize.by_profile_first_name(term).page(params[:page])
          end
          render 'institutions/index'
        when "Center"
          case current_user.rc
            when 'EA'
              @centers = params[:mode].constantize.by_profile_first_name(term).page(params[:page])
            when 'IA'
              @centers = current_user.centers.by_profile_first_name(term).page(params[:page])
          end
          render 'centers/index'
        when "Device"
          case current_user.rc
            when 'EA'
              @devices = Device.by_device_or_mac_or_android_id(term).page(params[:page])
            when 'CR'
              @devices = current_user.center.center_devices.by_device_id(term).page(params[:page])
            when 'IA'
              @devices =  current_user.institution.institution_devices.by_device_or_mac_or_android_id(term).page(params[:page])
            else
              @devices =  current_user.center.center_devices.by_device_id(term).page(params[:page])
          end

          render 'devices/index'
        when "Teacher"
          case current_user.rc
            when 'EA'
              #@teachers = Teacher.all.limit(10).page(params[:page])
              @teachers = Teacher.includes(:profile).by_profile_first_name_or_surname_or_roll_no_or_edutor_id(term).page(params[:page])
              logger.info "=================================rohit"
            when 'IA'
              @teachers = current_user.institution.teachers.by_profile_first_name_or_surname_or_roll_no_or_edutor_id(term).page(params[:page])
          end

          render 'teachers/index'
      end
    else
      respond_to do |format|
        format.html { redirect_to :back }
        format.json { head :no_content }
      end
    end
  end


  def result

  end

  #used for filter search by checkboxes in users list page.
  def filter_search
    case current_user.rc
      when 'EA'
        case params[:mode]
          when "institution"
            @centers = Center.includes(:profile).where(institution_id: params[:institution_ids])
            @users = get_users({institution_id: params[:institution_ids]},params[:page])
          when 'center'
            @academic_classes = AcademicClass.includes(:profile).where(institution_id: params[:institution_ids],center_id: params[:center_ids])
            @users = params[:center_ids].present? ? get_users({institution_id: params[:institution_ids],center_id: params[:center_ids]},params[:page]) : get_users({institution_id: params[:institution_ids]},params[:page])
          when 'academic_class'
            @sections = Section.includes(:profile).where(institution_id: params[:institution_ids],center_id: params[:center_ids],academic_class_id: params[:academic_class_ids])
            @users = params[:academic_class_ids].present? ? get_users({institution_id: params[:institution_ids],center_id: params[:center_ids],academic_class_id: params[:academic_class_ids]},params[:page]) : get_users({institution_id: params[:institution_ids],center_id: params[:center_ids]},params[:page])
          when 'section'
            @users = params[:section_ids].present? ? get_users({institution_id: params[:institution_ids],center_id: params[:center_ids],academic_class_id: params[:academic_class_ids],section_id: params[:section_ids]},params[:page]) : get_users({institution_id: params[:institution_ids],center_id: params[:center_ids],academic_class_id: params[:academic_class_ids]},params[:page])
        end
      when 'IA'
        case params[:mode]
          when 'center'
            @academic_classes = AcademicClass.includes(:profile).where(institution_id: current_user.institution,center_id: params[:center_ids])
            @users = get_users({institution_id: current_user.institution,center_id: params[:center_ids]},params[:page])
          when 'academic_class'
            @sections = Section.includes(:profile).where(institution_id: current_user.institution,center_id: params[:center_ids],academic_class_id: params[:academic_class_ids])
            @users = params[:academic_class_ids].present? ? get_users({institution_id: current_user.institution,center_id: params[:center_ids],academic_class_id: params[:academic_class_ids]},params[:page]) : get_users({institution_id: current_user.institution,center_id: params[:center_ids]},params[:page])
          when 'section'
            @users = params[:section_ids].present? ? get_users({institution_id: current_user.institution,center_id: params[:center_ids],academic_class_id: params[:academic_class_ids],section_id: params[:section_ids]},params[:page]) : get_users({institution_id: current_user.institution,center_id: params[:center_ids],academic_class_id: params[:academic_class_ids]},params[:page])
        end
      when 'CR'
        case params[:mode]
          when 'academic_class'
            @sections = Section.includes(:profile).where(institution_id: current_user.institution,center_id: current_user.center,academic_class_id: params[:academic_class_ids])
            @users = get_users({institution_id: current_user.institution,center_id: current_user.center,academic_class_id: params[:academic_class_ids]},params[:page])
          when 'section'
            @users = params[:section_ids].present? ? get_users({institution_id: current_user.institution,center_id: current_user.center,academic_class_id: params[:academic_class_ids],section_id: params[:section_ids]},params[:page]): get_users({institution_id: current_user.institution,center_id: current_user.center,academic_class_id: params[:academic_class_ids]},params[:page])
        end
      when 'ET'
        case params[:mode]
          when 'academic_class'
            @sections = Section.includes(:profile).where(institution_id: current_user.institution,center_id: current_user.center,academic_class_id: params[:academic_class_ids])
            @users = get_users({institution_id: current_user.institution,center_id: current_user.center,academic_class_id: params[:academic_class_ids]},params[:page])
          when 'section'
            @users = params[:section_ids].present? ? get_users({institution_id: current_user.institution,center_id: current_user.center,academic_class_id: params[:academic_class_ids],section_id: params[:section_ids]},params[:page]): get_users({institution_id: current_user.institution,center_id: current_user.center,academic_class_id: params[:academic_class_ids]},params[:page])
        end
    end

  end

  def upload_users
    if !(current_user.is?("EA") or current_user.is?("IA"))
      redirect_to root_path
    end
  end

  def csv_upload
    # 0 institution_id,	1 center_id, 2 academic_class_id,	3 section_id,	4 email, 5 Surname,
    # 6 Middlename,	7 FirstName,	8 Gender,	 9 Address,	10 Parent Email,	11 Parent Mobile,
    # 12 Device Screen Name, 13 DOB,	14 SchoolTag,	15 deviceid,	16 paid,
    # 17 password, 18 abstract group name
    if current_user.is?("EA") or current_user.is?("IA")
      if params[:csv_file]
        begin
          Student.transaction do
            results = CsvMapper.import(params[:csv_file].tempfile, :type => :io) do
              map_to Student # Map to the Person ActiveRecord class (defined above) instead of the default OpenStruct.
              after_row lambda{|row, user|
                          user.date_of_birth = row[13].gsub(':','-') unless row[13].blank?
                          # row[17] password
                          if row[17].blank?
                            password = '4123'
                          else
                            password = row[17]
                          end
                          user.password = password
                          # user.role_id=4
                          user.school_uid=row[14] # School Tag
                          user.is_activated=1
                          user.is_enrolled = true
                          user.rollno = row[12] unless row[12].blank?
                          user.plain_password = password

                          if user.save!
                            Message.create(sender_id: 1,recipient_id: user.id,subject: "Enroll",message_type: "Control Message") #sending ctrl message and enrolling the user automatically by callback
                            user.update_email
                            user.create_profile(:surname=>row[5],:middlename=>row[6],:firstname=>row[7],:gender=>row[8],:address=>row[9],:parent_email=>row[10],:parent_mobile=>row[11],:device_screen_name=>row[12])
                          end
                          # row[15] deviceID
                          unless row[15].blank?
                            deviceid = Device.find_by_deviceid(row[15])
                            unless deviceid
                              devise = Device.create(:deviceid=>row[15],:institution_id=>user.institution_id,:center_id=>user.center_id,:status=>'Assigned')
                              user.device_ids = [devise.id]
                            else
                              user.device_ids = [deviceid.id]
                            end
                          end
                          # row[18] abstract group name
                          # An abstract group is a group which spans students across the whole institute
                          puts row
                          unless row[18].blank?
                            email = row[18].lstrip.rstrip+"_"+user.institution_id.to_s+"@abcd.com"
                            puts email
                            # Check if any abstract group with that name already exists
                            student_group = StudentGroup.includes(:profile).where("email= ? and institution_id = ? and profiles.firstname = ? ", email, user.institution_id, row[18].lstrip.rstrip).first
                            if student_group.nil?
                              # Create an institute level abstract group
                              student_group = StudentGroup.new(:institution_id => user.institution_id, :center_id => nil, :academic_class_id => nil, :password => "edutor", :email => email)
                              student_group.build_profile
                              student_group.build_build_info(build_number: "5.0")
                              student_group.profile.firstname = row[18].lstrip.rstrip
                              student_group.save
                            end
                            puts student_group.id
                            UserGroup.create(:user_id=>user.id,:group_id=>student_group.id)
                            user.update_base_groups
                          end

                        }  # Call this lambda and save each r
              start_at_row 1
              [institution_id,center_id,academic_class_id,section_id,email]
            end
          end
          redirect_to users_path
        rescue Exception => e
          puts e.message
          logger.info e.message
          logger.info  e.backtrace
          flash[:error] = "Something went wrong.Please check the CSV file.#{e.message}"
          redirect_to :back
        end
      end
    else
      redirect_to :root_path
    end
  end
  def bulk_teachers_upload_interface
    if !(current_user.is?("EA") or current_user.is?("IA"))
      redirect_to root_path
    end

  end
  def post_bulk_teachers_upload
    # 0 institution_id,	1 center_id, 2 academic_class_id,	3 section_id,	4 email, 5 Surname,
    # 6 Middlename,	7 FirstName,	8 Gender,	 9 Address,
    # 10 DOB, 11 password,12 rollno, 13 user_group_ids(comma seperated string)
    if current_user.is?("EA") or current_user.is?("IA")
      if params[:csv_file]
        begin
          Teacher.transaction do
            results = CsvMapper.import(params[:csv_file].tempfile, :type => :io) do
              map_to Teacher # Map to the Person ActiveRecord class (defined above) instead of the default OpenStruct.
              after_row lambda{|row, user|
                          if row[11].blank?
                            password = 'abcde123'
                          else
                            password = row[11]
                          end
                          user.password = password
                          # user.role_id=4
                          user.is_activated=1
                          user.is_enrolled = true
                          user.rollno = row[12] unless row[12].blank?
                          user.plain_password = password
                          user.email = row[4] unless row[4].blank?

                          if user.save!
                            user.update_attribute(:password, password)
                            Message.create(sender_id: 1,recipient_id: user.id,subject: "Enroll",message_type: "Control Message") #sending ctrl message and enrolling the user automatically by callback
                            user.create_profile(:surname=>row[5],:middlename=>row[6],:firstname=>row[7],:gender=>row[8],:address=>row[9])
                          end
                          puts row
                          unless row[13].blank?
                            row[13].split(",").each do |group_id|
                            UserGroup.create(:user_id=>user.id,:group_id=>group_id)
                            user.update_base_groups
                            end
                          end

                        }  # Call this lambda and save each r
              start_at_row 1
              [institution_id,center_id,academic_class_id,section_id,email]
            end
          end
          redirect_to users_path
        rescue Exception => e
          puts e.message
          logger.info e.message
          logger.info  e.backtrace
          flash[:error] = "Something went wrong.Please check the CSV file.#{e.message}"
          redirect_to :back
        end
      end
    else
      redirect_to :root_path
    end

  end

  def get_users(params,page)
    User.students.search_includes.where(params).search_select.page(page)
  end

  #used for assiging users to a particular group...used in groups form pages
  def users_token_search
    if params[:term].present?
      term = "%#{params[:term]}%"
      @users =case current_user.rc
                when 'EA'
                  User.where(:is_group=>false).by_profile_first_name_or_surname_or_roll_no_or_edutor_id(term).limit(20)
                when 'IA'
                  current_user.institution.users.where(:is_group=>false).by_profile_first_name_or_surname_or_roll_no_or_edutor_id(term).limit(20)
                when 'CR'
                  current_user.center.users.where(:is_group=>false).by_profile_first_name_or_surname_or_roll_no_or_edutor_id(term).limit(20)
              end
    end
    respond_to do |format|
      format.json { render json: @users.map{|u| Hash[id: u.id, name: u.profile.autocomplete_display_name]} }
    end
  end

  #Device specific control message form
  def device_control_message
    @message = Message.new
    @message.assets.build
  end



  #Message download attempts
  def message_download
    @message  = Message.find(params[:id])
    ext = request.url.split('.').last
    respond_to do |f|
      if @message
        @message_download = MessageUserDownload.new
        @message_download.message_id= @message.id
        if current_user
          @message_download.user_id= current_user.id
        else
          @message_download.user_id = 0
        end
        @message_download.save
        url = "/messages/#{params[:sender_id]}/#{params[:time]}/#{params[:name]}.#{ext}"
        # redirect_to url
        if File.exists?  @message.assets.last.attachment.path #"#{Rails.root}/public"+url
          # redirect_to url
          send_file @message.assets.last.attachment.path ,:disposition=>'inline',:type=>"application/octet-stream",:x_sendfile=>true
        else
          render :nothing=>true, :status=>404,:layout=>false
        end
      else
        render :nothing=>true,:status=>404,:layout=>false
      end
      return
    end
  end


  def test_mqtt
    MQTT::Client.connect('localhost:3000/test_mqtt') do |c|
      # If you pass a block to the get method, then it will loop
      #c.get('test') do |topic,message|
      #  puts "#{topic}: #{message}"
      #end
      puts "=========",c
    end
  end



  def user_communication
    if request.post?
      user_ids = params[:user_communication][:user_ids].split(',')
      command_ids = params[:user_communication][:message_type]- [""]
      user_ids.each do |i|
        user =  User.find(i)
        command_ids.each do |c|
          command ="mosquitto_pub -p 3333 -t #{user.edutorid} -m #{c}  -i Edeployer -q 2 -h 173.255.254.228"
          system(command)
        end
      end
      flash[:notice] = "Communication sent successfully."
      redirect_to user_communication_path
    end
  end


  # TODO add column filepath and column for usages and use gem to show the duration

  def user_activities
    @activities = UserActivity.includes(:user).order('created_at DESC').page(params[:page])
  end


  def user_usages
    @usages = UserUsage.includes(:user).order('end_time DESC').page(params[:page])
  end


  def get_user_usage
    @usages = UserUsage.where(:user_id=>params[:id]).order('end_time DESC').page(params[:page])
  end

  def user_migrate
    if request.post? && params[:file].present?
      infile = params[:file].read
      n, errs = 0, []
      CSV.parse(infile) do |row|
        n += 1
        if n == 1 or row.join.blank?
          @header = row
          next
        end
        logger.info"=======usermigrate=#{row[0]}==="
        user = User.find_by_edutorid(row[0])
        Device.where(:deviceid=>row[3]).update_all(:mac_id=>nil,:android_id=>nil)
        DeviceMessage.where('deviceid=? OR group_id IN (?)',row[3],user.group_ids).destroy_all
        #DeviceMessage.where(:deviceid=>row[3],:group_id=>user.group_ids).destroy_all
        if user
          user.academic_class_id = row[4]
          user.section_id = row[5]
          user.group_ids = nil
          user.save(:validate=>false)
        else
          errs << row
        end
      end
      if errs.any?
        errFile ="errors_#{Date.today.strftime('%d%b%y')}.csv"
        errs.insert(0, @header)
        errCSV = CSV.generate do |csv|
          errs.each {|row| csv << row}
        end
        send_data errCSV,
                  :type => 'text/csv; charset=iso-8859-1; header=present',
                  :disposition => "attachment; filename=#{errFile}.csv"
      else
        flash[:notice] = 'User Migrated Successfully'
        redirect_to user_migrate_path
      end
    end
  end

  #Attendence app requesting the class and section details
  def get_class_details
    if params[:center_id]
      @user = User.find_by_id(params[:center_id])
    elsif params[:section_id]
      @user = User.find_by_id(params[:section_id])
    end
    @data = nil
    unless @user.nil?
      if @user.type == 'Center'
        #@center = Center.find(params[:center_id])
        @data =  @user.academic_classes.collect{|i|{:id=>i.id,:name=>i.name,:sections=>i.sections.collect{|s|{:id=>s.id,:name=>s.name}}}}
      elsif @user.type == 'Section'
        @data =  @user.students.collect{|i|{:edutorid=>i.edutorid, :surname=>i.profile.surname, :middlename=>i.profile.middlename, :firstname=>i.profile.firstname, :email=>i.email, :parent_email=>i.profile.parent_email, :created_at=>i.profile.created_at, :updated_at=>i.profile.updated_at, :rollno=>i.rollno, :extras=>i.extras, :date_of_birth=>i.date_of_birth}}
      end
    end
    respond_to do |format|
      format.json{render json: @data}
    end
  end

  #Junior Activity
  def juniortabstats
    activity_score =  params[:activityscore]
    steps_record =  params[:stepsrecord]
    activity_status = JSON.load(parms[:activityusagestats])

    activityscore = []
    stepsrecord = []
    activityusagestats = []


    logger.info "===#{activity_score}==#{steps_record}===#{activity_status}"

    activity_score.each do |d|
      d['client_id'] = d['id']
      activity_score = JuniorActivityScore.find_by_user_id_and_label(d['user_id'],d['label'])
      if activity_score.nil?
        JuniorActivityScore.create(d)
        activityscore << d['id']
      else
        activity_score.update_attributes(d)
        activityscore << d['id']
      end
    end

    steps_record.each do |s|
      s['client_id'] = s['id']
      JuniorRecordStep.create(s)
      stepsrecord << s['id']
    end

    activity_status.each do |a|
      a['client_id'] = a['id']
      JuniorActivityUsage.create(a)
      activityusagestats << a['id']
    end

    @response = {:activityscore=>activityscore,:stepsrecord=>stepsrecord,:activityscore=>activityusagestats}

    respond_to do |format|
      format.json { render json:@response }
    end

  end


  def junior_activity_usages
    result = []
    @scores =  JuniorActivityScore.all
    @scores.each do |s|
      duration = JuniorActivityUsage.select('sum(end_time - start_time) as usage_duration').where(:user_id=>s.user_id,:activity_name=>s.activity_name)
      success_true = JuniorRecordStep.where(:user_id=>s.user_id,:activity_name=>s.activity_name,:success=>'true').count
      success_false = JuniorRecordStep.where(:user_id=>s.user_id,:activity_name=>s.activity_name,:success=>'false').count
      result << [s.user_id,s.label,s.completion_rate,(success_true.to_f/(success_true.to_f+success_false.to_f))*100,duration.first.usage_duration.to_f/(60*1000)]
      logger.info "===========#{result}"
    end
    csv_data = FasterCSV.generate do |csv|
      csv << 'User Id,Label,Completion rate,Success rate,Duration'.split(',')
      result.each do |c|
        csv << c
      end
    end
    file_name =  ("juniour_tab_usage_report_#{Time.now.to_i}.csv").gsub(" ","").to_s
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"
  end


  def pearson_usage
    @users = User.includes(:user_usages).where(:institution_id=>1020,:role_id=>4).order('id desc').limit(10)
  end


  def get_pearson_usage
    @usages = UserUsage.where(:user_id=>params[:user_id]).order('end_time DESC').page(params[:page])
  end

  def pearson_csv_user_upload

  end

  def pearson_user_upload_save
    if current_user.is?("EA") or current_user.is?("IA")
      if params[:csv_file]
        begin
          User.transaction do
            results = CsvMapper.import(params[:csv_file].tempfile, :type => :io) do
              set_email = false
              map_to User # Map to the Person ActiveRecord class (defined above) instead of the default OpenStruct.
              after_row lambda{|row, user|
                          user.password = row[9]
                          if row[4].blank?
                            user.email =  Time.now.to_i.to_s+"@myedutor.com"
                            set_email = true
                          else
                            user.email = row[4]
                          end
                          user.role_id=4
                          user.is_activated=1
                          user.is_enrolled = true
                          user.rollno = row[8]
                          user.plain_password = row[9]
                          if user.save!
                            if set_email
                              user.update_attribute(:email, user.edutorid + "@myedutor.com")
                            end
                            user.create_profile(:surname=>row[6],:middlename=>row[7],:firstname=>row[7],:gender=>"M")
                          end
                        }  # Call this lambda and save each r
              start_at_row 1
              [institution_id,center_id,academic_class_id,section_id]
            end
          end
          redirect_to users_path
        rescue Exception => e
          puts e.message
          logger.info e.message
          logger.info  e.backtrace
          flash[:error] = "Something went wrong.Please check the CSV file.#{e.message}"
          redirect_to :back
        end
      end
    else
      redirect_to :root_path
    end

  end

  def usage_file_downloads
    @user = current_user
    @new_user_usages
  end

  def post_usage_file_downloads
    file = Time.now.to_i.to_s+ "_" +(current_user.id).to_s
#    csv_headers = UserUsage.column_names.join("','")

    if !params[:report_start_date].empty? and !params[:report_end_date].empty?
      time_query = "start_time \> #{params[:report_start_date].to_datetime.to_i}" + " and " + "end_time \< #{params[:report_end_date].to_datetime.next.to_i}"
    else
      time_query = "end_time \< #{Time.now.to_i}"
    end
    if !params[:new_user_usages][:institution_id].empty?
      if !params[:new_user_usages][:center_id].empty?
        if !params[:new_user_usages][:academic_class_id].empty?
          if !params[:new_user_usages][:section_id].empty?
            query = "users.section_id=#{params[:new_user_usages][:section_id]} and"
          else
            query = "users.academic_class_id=#{params[:new_user_usages][:academic_class_id]} and"
          end
        else
          query = "users.center_id=#{params[:new_user_usages][:center_id]} and"
        end
      else
        query = "users.institution_id=#{params[:new_user_usages][:institution_id]} and"
      end
    else
      query = ""
    end
    db_config   = Rails.configuration.database_configuration
    database = db_config[Rails.env]["database"]
    username = db_config[Rails.env]["username"]
    password = db_config[Rails.env]["password"]


    csv_headers = "id','uri','uid','start_time','end_time','user_id','device_id','app_name','created_at','updated_at','file_path', 'book_id', 'duration', 'class_type', 'file_type', 'time_zone', 'launched_from"
      csv_headers = csv_headers +"\',\'rollno" +"\',\'Institution_id"
      command1 = "SELECT \'#{csv_headers}\' Union "
      command2 = "user_usages.id,uri,uid,FROM_UNIXTIME(start_time),FROM_UNIXTIME(end_time),user_id,device_id,app_name,FROM_UNIXTIME(user_usages.created_at),FROM_UNIXTIME(user_usages.updated_at),file_path,book_id,duration,class_type,file_type, time_zone,launched_from,users.rollno, users.institution_id "
      command3 = "#{Rails.root.to_s}\/tmp\/#{file}.csv"
      #system(command1)
      command = "mysql -u #{username} -p#{password} -D #{database} -e " + "\"#{command1} " + "SELECT #{command2} FROM user_usages INNER JOIN users ON users.id = user_usages.user_id WHERE (#{query} #{time_query}) into OUTFILE \'#{command3}\' fields terminated by ',' enclosed by '\\\"' lines terminated by '\\n'\" "


    logger.info"=====#{command}"
#logger.info"=====#{command1}"

      if system(command)
        send_file "#{command3}",:disposition=>'inline',:type=>"text/csv"
      else
        redirect_to :back, :notice => "No data found"
      end

  end

  def get_user_caricature
    @user = params[:user]
    if File.exists? "#{Rails.root.to_s}/user_caricatures/#{@user}.zip"
      send_file "#{Rails.root.to_s}/user_caricatures/#{@user}.zip" ,:disposition=>'inline',:x_sendfile=>true
    else
      respond_to do |format|
        format.json { render :json=>{:status=>404} }
      end
    end
  end


  def upload_user_caricature

    if !params[:user_caricature].blank?
      name = params[:user_caricature].original_filename
      directory = "#{Rails.root.to_s}/user_caricatures/"
      path = File.join(directory, name)
      File.open(path, "wb") { |f| f.write(params[:user_caricature].read) }
      flash[:notice] = "Caricature file uploaded successfully"
    end
  end


  def update_user_groups
    if current_user.is?("EA")
      if request.post? && params[:file].present?
        infile = params[:file].read
        n, errs = 0, []
        CSV.parse(infile) do |row|
          n += 1
          if n == 1 or row.join.blank?
            @header = row
            next
          end
          user = User.find_by_edutorid(row[0])
          unless user.nil?
            student_group = StudentGroup.includes(:profile).where("institution_id = ? and profiles.firstname = ? ", user.institution_id, row[1].lstrip.rstrip).first
            unless student_group.nil?
              user.group_ids = []
              UserGroup.create(:user_id=>user.id,:group_id=>student_group.id)
              user.update_base_groups
            else
              row[2] = "group not found"
              errs << row
            end
          else
            row[2] = "user not found"
            errs << row
          end
        end
        if errs.any?
          errFile ="errors_#{Date.today.strftime('%d%b%y')}.csv"
          errs.insert(0, @header)
          errCSV = CSV.generate do |csv|
            errs.each {|row| csv << row}
          end
          send_data errCSV,
                    :type => 'text/csv; charset=iso-8859-1; header=present',
                    :disposition => "attachment; filename=#{errFile}.csv"
        else
          flash[:notice] = 'User groups updated Successfully'
          redirect_to update_user_groups_path
        end
      end
    else
      redirect_to root_path
    end
  end

  def privacy_policy
    render :layout=>false
  end


  def bulk_user_deactivate
    if current_user.is?("EA")
      if request.post? && params[:file].present?
        infile = params[:file].read
        n, errs = 0, []
        CSV.parse(infile) do |row|
          n += 1
          if n == 1 or row.join.blank?
            @header = row
            next
          end
          user = User.find_by_edutorid(row[0])
          unless user.nil?
            user.update_attribute(:is_activated,false)
            user.user_devices.destroy_all    
          else
            row[2] = "user not found"
            errs << row
          end
        end
        if errs.any?
          errFile ="errors_#{Date.today.strftime('%d%b%y')}.csv"
          errs.insert(0, @header)
          errCSV = CSV.generate do |csv|
            errs.each {|row| csv << row}
          end
          send_data errCSV,
                    :type => 'text/csv; charset=iso-8859-1; header=present',
                    :disposition => "attachment; filename=#{errFile}.csv"
        else
          flash[:notice] = 'Deactivated Successfully'
          redirect_to bulk_user_deactivate_path
        end
      end
    else
      flash[:error] = "Page doesn't exist"
      redirect_to root_path
    end
  end



  def bulk_user_data_update
    if current_user.is?("EA")
      if request.post? && params[:file].present?
        infile = params[:file].read
        n, errs = 0, []
        CSV.parse(infile) do |row|
          n += 1
          if n == 1 or row.join.blank?
            @header = row
            next
          end
          @user = User.find_by_edutorid(row[0])
          unless @user.nil?
            begin
              @profile = @user.profile
              ActiveRecord::Base.transaction do
                unless row[1].blank?
                  @user.email = row[1]
                end
                unless row[2].blank?
                  @profile.parent_email= row[2]
                end
                unless row[3].blank?
                  @profile.parent_mobile = row[3]
                end
                unless row[4].blank?
                  @profile.phone = row[4]
                end
                unless row[5].blank?
                  @profile.firstname = row[5]
                end
                unless row[6].blank?
                  @user.school_uid = row[6]
                end
                unless row[7].blank?
                  @user.password = row[7]
                end
                unless row[8].blank?
                  @user.rollno = row[8]
                end
                unless @user.save and @profile.save
                  row[row.size-1] = "Data not updated"
                  errs << row
                end
              end
            rescue
              row[row.size-1] = "Data not updated"
              errs << row
              next
            end
          else
            row[row.size-1] = "user not found"
            errs << row
          end
        end
        if errs.any?
          errFile ="errors_#{Date.today.strftime('%d%b%y')}.csv"
          errs.insert(0, @header)
          errCSV = CSV.generate do |csv|
            errs.each {|row| csv << row}
          end
          send_data errCSV,
                    :type => 'text/csv; charset=iso-8859-1; header=present',
                    :disposition => "attachment; filename=#{errFile}.csv"
        else
          flash[:notice] = 'User data Updated Successfully'
          redirect_to bulk_user_data_update_path
        end
      end
    else
      flash[:error] = "Page doesn't exist"
      redirect_to root_path
    end
  end
  def ngi_quiz_data_upload
    if request.post? && params[:file].present?
      infile = params[:file].read
      quiz_data = []
      n, errs = 0, []
      CSV.parse(infile, :headers => true , :encoding => 'ISO-8859-1') do |row|
        quiz_data << row.to_hash
      end
      quiz_data.each do |data|
        entry =  NgiQuizData.new(quiz_date:data["date"],publish_id:data["published_id"])
        entry.save
      end
      flash[:notice] = "Quiz data uploaded successfully"
      redirect_to ngi_quiz_data_upload_path
    end
  end
  def download_datewise_quiz_data
    date = params["date"]
    section_name = params["class"]
    quiz_name = params["quiz_name"]
    present_user = current_user
    quiz_data = NgiQuizData.where(quiz_date: date).order('created_at DESC')
    @final_quiz_data_page2 = []
    quiz_data.each do |data|
      quiz_targeted_group_id = data.publish_id
      date = data.quiz_date
      q_data = Quiz.ngi_home_page_csv_data(present_user,quiz_targeted_group_id,date)
      @final_quiz_data_page2 << q_data
    end
    csv_header = "Date,Class_name,Assessment_name,not_submitted_User_name,rollno".split(",")
    file_name = Time.now.to_i.to_s+ "_" +date+"_"+section_name+"_"+quiz_name+ ".csv"
    csv_data = FasterCSV.generate do |csv|
      csv << csv_header
      p = []
      @final_quiz_data_page2.first[date].each do |l|
        if l.first[0] == section_name
          p << l
        end
      end
      a = []
      p[0][section_name][:not_submitted].each{ |l| a << [date,section_name.split("_").first,quiz_name,l[0],l[1]]}  if p[0][section_name][:not_submitted].count !=0
      a.each{|c| csv << c} if a.count !=0

    end
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"
  end

  def download_datewise_quiz_data_full
    date = params["date"]
    quiz_data = NgiQuizData.where(quiz_date: date).order('created_at DESC')
    @final_quiz_data_page1 = {}
    @final_quiz_data_page2 = []
    present_user = current_user
    quiz_data.each do |data|
      quiz_targeted_group_id = data.publish_id
      date = data.quiz_date
      q_data = Quiz.ngi_home_page_csv_data(present_user,quiz_targeted_group_id,date)
      @final_quiz_data_page2 << q_data
      #@final_quiz_data_page1[date] = {:published=>[],:downloaded=>[],:submitted=>[],:not_submitted=>[]}
    end

    csv_header = "Date,Class_name,Assessment_name,not_submitted_User_name,rollno".split(",")
    file_name = Time.now.to_i.to_s+ "_" +(present_user.id).to_s+ ".csv"
    csv_data = FasterCSV.generate do |csv|
      csv << csv_header
      @final_quiz_data_page2.each do |p|
        a = []
        p.first[1].each do |k|
          k.first[1][:not_submitted].each{ |l| a << [p.first[0],k.first[0].split("_").first,k.first[1][:quiz_name],l[0],l[1]]} if k.first[1][:not_submitted].size !=0

        end
        a.each{|c| csv << c} if a.size !=0
      end

    end
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"
  end

  def download_institute_wise_students_results_csv
    if request.post? && params[:file].present?
      assess_data = []
      final_array = []
      final_array2 = []
      infile = params[:file].read
      n, errs = 0, []
      CSV.parse(infile, :headers => true , :encoding => 'ISO-8859-1') do |row|
        assess_data << row.to_hash
      end
      assess_data.each do |data|
        get_qtg1 = QuizTargetedGroup.where(id: data["published_id"]).first
        group_id1 = get_qtg1.group_id
        student_ids1  = User.find(group_id1).students.map(&:id)
        message1 = MessageQuizTargetedGroup.find_by_quiz_targeted_group_id(data["published_id"])
        if message1
          message_id1 = message1.message_id
          downloaded_students1 = UserMessage.where(message_id: message_id1, user_id: student_ids1,sync: false).map(&:user_id)
        end
        attempted1 = (get_qtg1.quiz_attempts.select(:user_id).group(:user_id).collect{|i|i.user_id} & student_ids1)
        not_submitted_1 =  downloaded_students1 - attempted1

        # get_qtg2 = QuizTargetedGroup.where(id: data["published_id2"]).first
        # group_id2 = get_qtg2.group_id
        # student_ids2  = User.find(group_id2).students.map(&:id)
        # message2 = MessageQuizTargetedGroup.find_by_quiz_targeted_group_id(data["published_id2"])
        # if message2
        #   message_id2 = message2.message_id
        #   downloaded_students2 = UserMessage.where(message_id: message_id2, user_id: student_ids2,sync: false).map(&:user_id)
        # end
        # attempted2 = (get_qtg2.quiz_attempts.select(:user_id).group(:user_id).collect{|i|i.user_id} & student_ids2)
        # not_submitted_2 =  downloaded_students2 - attempted2

        downloaded_students1.each do |id1|
          final_array << [data["published_id"], id1, User.find(id1).name]
        end
        # downloaded_students2.each do |id2|
        #   final_array << [data["published_id"], id2, User.find(id2).name]
        # end
        not_submitted_1.each do |id1|
          final_array2 << [data["published_id"], id1,User.find(id1).name]
        end
        # not_submitted_2.each do |id2|
        #   final_array2 << [data["published_id2"], id2, User.find(id2).name]
        # end
      end
      csv_header1 = "Published_id,student_id,downloaded_student_name".split(",")
      csv_header2 =  "Published_id,student_id,not_submitted_student_name".split(",")
      file_name1 = Time.now.to_i.to_s+ "_" +(current_user.id).to_s + ".csv"
      csv_data1 = FasterCSV.generate do |csv|
        csv << csv_header1
        final_array.each do |row|
          csv << [row[0], row[1], row[2]]
        end
        csv << csv_header2
        final_array2.each do |row|
          csv << [row[0], row[1], row[2]]
        end
      end
      send_data csv_data1, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name1}"
    end
  end
  def get_insti_students_data
    user_id = params[:id]
    @inst = Institution.find(User.find(user_id).institution_id)
    @student_ids = @inst.students.map(&:id)

    @needed_data = []

    @student_ids.each do |stu|
      student = Student.find(stu)
      last_sign_in_time = student.last_sign_in_at.nil? ? "" : Time.at(student.last_sign_in_at).strftime("%Y-%m-%d")

      @needed_data << [student.name,student.edutorid,student.rollno,student.center.name,student.academic_class.name, last_sign_in_time]

    end
    csv_header = "Student Name,ES ID,RollNO,Center Name,Class,Last Sign IN".split(",")
    file_name = Time.now.to_i.to_s+ "_" +(current_user.id).to_s+ ".csv"
    csv_data = FasterCSV.generate do |csv|
      csv << csv_header
      @needed_data.each do |p|
        csv << [p[0], p[1], p[2], p[3], p[4], p[5]]
      end
    end
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"

  end
  def get_insti_teachers_data
    user_id = params[:id]
    @inst = Institution.find(User.find(user_id).institution_id)
    @teacher_ids = @inst.teachers.map(&:id)

    @needed_data = []

    @teacher_ids.each do |teach|
      teacher = User.find(teach)
      last_sign_in_time = teacher.last_sign_in_at.nil? ? "" : Time.at(teacher.last_sign_in_at).strftime("%Y-%m-%d")

      @needed_data << [teacher.name,teacher.edutorid,teacher.rollno,teacher.center.name,teacher.academic_class.name, last_sign_in_time]

    end
    csv_header = "Teacher Name,ET ID,RollNO,Center Name,Class,Last Sign IN".split(",")
    file_name = Time.now.to_i.to_s+ "_" +(current_user.id).to_s+ ".csv"
    csv_data = FasterCSV.generate do |csv|
      csv << csv_header
      @needed_data.each do |p|
        csv << [p[0], p[1], p[2], p[3], p[4], p[5]]
      end
    end
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"

  end

  def get_students_deployment_data
    user_id = params[:user_id]
    rc = params[:rc] #rc should be ES or ET
    @final_array = DashboardData.stu_books_deployment_data(user_id, rc)
    csv_header = "Book_name,Book ID,Collection_id,ES_id,Rollno,Student_name,Center_name,Form,Section".split(",") if rc == "ES"
    csv_header = "Book_name,Book ID,Collection_id,ET_id,Rollno,Teacher_name,Center_name,Form,Section,extra_added_forms,custom_created_groups".split(",") if rc == "ET"
    file_name = Time.now.to_i.to_s+ "_" +(user_id).to_s+ "#{rc}.csv"
    csv_data = FasterCSV.generate do |csv|
      csv << csv_header
      if rc == "ES"
        @final_array.each do |p|
          csv << [p[0], p[1], p[2], p[3], p[4], p[5],p[6],p[7],p[8]]
        end
      elsif rc == "ET"
        @final_array.each do |p|
          csv << [p[0], p[1], p[2], p[3], p[4], p[5],p[6],p[7],p[8],"not_available","not_available"]
        end
      end
    end
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"
  end

  def get_teachers_deployment_data
    user_id = params[:id]
  end


  def refund_policy
    render :layout=>false
  end

  def terms_of_use
    render :layout=>false
  end
end


