class DashboardData < ActiveRecord::Base
  # attr_accessible :title, :body
  validates_uniqueness_of :mainpage_data, scope: :user_id
  serialize :mainpage_data

  def self.populate_user_dashboard_data(user_id)
    begin
      present_user = User.find(user_id)

      if present_user.rc == "ET"
        #for teacher_container 1 and 2
        @cent = present_user.center
        teacher_books = Ibook.where(:id=>present_user.ibooks.map(&:id))

        #subjects = teacher_books.group("subject,form").map{|book| [book.form, book.subject]}
        subjects = teacher_books.group_by{|book| [book.form, book.subject]}.keys

        # sections = current_user.groups.where(type:"Section")
        need_array = {}
        sections_usages = []

        subjects.each do |s|
          need_array[s] = []
          m = 0
          teacher_books.where(subject:s[1],form:s[0]).each do |p|
            section_ids = User.includes(:content_access_permissions).select("users.section_id").where("center_id=? and users.rc=? and content_access_permissions.accessed_content_guid=?", @cent.id, "ES", p.ibook_id ).map(&:section_id).uniq
            #need_array[s] << [p.id,p.metadata["displayName"],[],[],[],[],[],[],[]] unless section_ids.empty?
            unless section_ids.empty?
              need_array[s] << [p.id,p.metadata["displayName"],[],[],[],[],[],[],[]]
              sections = Section.where(id:section_ids)
              sections.each do |sec|
                c_per = ContentAccessPermission.includes(:user).where("users.section_id=? and users.rc=? and accessed_content_guid=?",sec.id, "ES" ,p.ibook_id).group(:user_id).count
                stu_ids = c_per.keys
                c = c_per.count
                need_array[s][m][2] << sec.name
                need_array[s][m][3] << c
                duration = UserUsage.includes(:user).where("users.section_id = ? and users.id IN (?) and start_time > ? and book_id=?",sec.id, stu_ids ,4.weeks.ago.to_i,p.ibook_id)
                total_duration = duration.sum(:duration)
                need_array[s][m][4] << total_duration.to_i/60
                need_array[s][m][5]  << (total_duration.to_i/(sec.students.count*60))
                # vdo_usage = duration.where("class_type=?",'videolecture')
                # test_usage = duration.where("class_type IN (?)",["assessment-insti-tests","assessment-practice-tests"])
                # need_array[s][m][6] << vdo_usage.count
                # need_array[s][m][7] << test_usage.count
                need_array[s][m][8] << duration.count
              end
              m = m+1
            end
          end
        end
        # for teacher_container 3
        quizzes_info = []
        teacher_sections = present_user.groups.where(type:"Section").map(&:id)
        latest_quizzes = Quiz.joins(:quiz_targeted_groups).where("createdby=? and timecreated>=? and quiz_targeted_groups.recipient_id IS NULL",present_user.id, 4.weeks.ago.to_i ).last(3)
        latest_quizzes.each_with_index do |quiz,i|
          quizzes_info << [quiz.name,quiz.questions.count,[]]
          quiz.quiz_targeted_groups.where("recipient_id IS NULL").each do |qtb|
            quizzes_info[i][2] << [User.find(qtb.group_id).name ,Quiz.get_students_count_below_required_score(qtb)]
          end
        end
        full_et_data_hash = {:need_array=>need_array,:quizzes_info=>quizzes_info}

        return full_et_data_hash


        # self.create(user_id:user_id,mainpage_data:{:need_array=>need_array,:quizzes_info=>quizzes_info})

      elsif (present_user.rc == "MOE" or present_user.rc == "IA" or present_user.rc == "EO")

        @inst = Institution.includes(:academic_class,:section,:profile).find(present_user.institution_id) if !present_user.institution_id.nil?
        @cents = @inst.centers
        # container 1 data

        center_names = @cents.map(&:name)
        insti_teachers = @inst.teachers.map(&:id)
        insti_books_count = ContentAccessPermission.includes(:user).where("users.institution_id=? and accessed_content_type=?",@inst.id,"book").group(:accessed_content_guid).count.count
        center_students = []
        center_teachers = []
        center_books = []
        @cents.each do |center|
          center_students << center.students.count
          center_teachers << center.teachers.count
          center_books << ContentAccessPermission.includes(:user).where("users.center_id=? and accessed_content_type=?",center.id,"book").group(:accessed_content_guid).count.count

        end
        @temporary_info_c1t1 = [@cents.count,@inst.students.count,@inst.teachers.count,insti_books_count]
        # @temporary_info_c1t1 = [@cents.count,@inst.students.count,@inst.teachers.count,@inst.teachers.map{|a| a.ibooks.count}.inject(0,:+)]
        @temporary_info_c1t2 = [center_names,center_students,center_teachers, center_books]

        # container 2 data
        @tlm = UserUsage.includes(:user).where("users.institution_id=?",@inst.id)
        total_learning_minutes = @tlm.sum(:duration).to_i/60
        total_active_students = @tlm.where(" start_time > ?",4.weeks.ago.to_i).group(:user_id).having("sum(duration) > 3600").count.count
        centerwise_tlm = @cents.map{|center|
          @tlm.where("users.center_id=?", center.id).sum(:duration).to_i/60
        }
        centerwise_active_students = @cents.map{|center|
          @tlm.where("users.center_id=? and  start_time > ? ",center.id,4.weeks.ago.to_i  ).group(:user_id).having("sum(duration) > 3600").count.count
        }
        @lm_container_info_t1 = [total_learning_minutes, total_active_students]
        @lm_container_info_t2 = [center_names, centerwise_tlm, centerwise_active_students]

        #container 3 data
        @usages = UserUsage.includes(:user).where("users.institution_id=? and start_time > ? ",@inst.id,4.weeks.ago.to_i)
        total_videos = @usages.where("class_type=?",'videolecture').count
        @total_questions = QuizQuestionAttempt.includes(:user).where("users.institution_id=? and attempted_at >?",@inst.id, 4.weeks.ago.to_i)
        total_questions = @total_questions.count
        total_ios =  @usages.count
        centerwise_videos = []
        centerwise_ques = []
        centerwise_ios = []
        @cents.each do |center|
          centerwise_videos << @usages.where("users.center_id=? and class_type=?",center.id,'videolecture').count
          centerwise_ques << @total_questions.where("users.center_id=?",center.id).count
          centerwise_ios << @usages.where("users.center_id=?",center.id).count
        end
        @se_container_info_t1 = [total_videos, total_questions, total_ios]
        @se_container_info_t2 = [center_names, centerwise_videos, centerwise_ques, centerwise_ios]

        # container 4 data
        a = []
        @cents.each do |center|
          cent_teachers =  center.teachers.map(&:id)
          a << [center.name, User.active_teacher_tests_assets_consolidated(cent_teachers) ]
        end
        centers_c4t2 = []
        active_teachers_c4t2 = []
        tests_c4t2 = []
        lo_c4t2 = []
        a.each do |k|
          centers_c4t2 << k[0]
          active_teachers_c4t2 << k[1][:active_teachers]
          tests_c4t2 << k[1][:tests_published]
          lo_c4t2 << k[1][:assets_published]
        end
        @teacher_container_info_t1 = User.active_teacher_tests_assets_consolidated(insti_teachers)
        @teacher_container_info_t2 = [centers_c4t2, active_teachers_c4t2, tests_c4t2, lo_c4t2]
        full_moe_data_hash = {:temporary_info_c1t1=>@temporary_info_c1t1,:temporary_info_c1t2=>@temporary_info_c1t2,
                              :teacher_container_info_t1=>@teacher_container_info_t1,
                              :teacher_container_info_t2=>@teacher_container_info_t2,
                              :lm_container_info_t1=>@lm_container_info_t1, :lm_container_info_t2=>@lm_container_info_t2,
                              :se_container_info_t1=>@se_container_info_t1, :se_container_info_t2=>@se_container_info_t2 }
        return full_moe_data_hash
        # self.create(user_id:user_id,mainpage_data:full_moe_data_hash)

      end
    end
  end

  def self.populate_all_users_dashboard_data
    relevent_user_ids = User.where("rc IN (?)", ["MOE","IA","EO","ET"]).map(&:id)
    relevent_user_ids.each do |user_id|
      present_data =  populate_user_dashboard_data(user_id)
      previous_data = DashboardData.where(user_id:user_id).last.nil? ? {} : DashboardData.where(user_id:user_id).last.mainpage_data
      unless present_data == previous_data
        self.create(user_id:user_id, mainpage_data:present_data)
      end
    end
  end

  def self.stu_books_deployment_data(user_id,rc)
      present_user = User.find(user_id)
      @inst = Institution.find(present_user.institution_id) if !present_user.institution_id.nil?
      @cents = @inst.centers
      @cent_books = []
      @final_pre_info = []
      @cents.each do |cent|
        @cent_books << {cent.id => ContentAccessPermission.includes(:user).where("users.center_id=? and accessed_content_type=?", cent.id, "book").map(&:accessed_content_guid).uniq}
      end
      @cent_books.each do |center_books_hash|
        begin
          center_books_hash.each do |k,v|
            v.each do |book_id|
              book = Ibook.find_by_ibook_id(book_id) if Ibook.find_by_ibook_id(book_id).present?
              # ipacks = book.ipacks.where(center_id: k).first.nil? ? book.ipacks.first : book.ipacks.where(center_id: k).first if book.ipacks.present?
              # ipack_ids = Ibook.includes(ipacks: :license_sets).where("ibooks.ibook_id=? and license_sets.institution_id=?",book_id,@inst.id).map(&:ipack_ids)
              license_set_ids = book.license_sets.where(institution_id:@inst.id).map(&:id)
              user_ids = ContentAccessPermission.includes(:user).where("users.center_id=? and users.rc=? and accessed_content_guid=?", k, rc, book_id).map(&:user_id)
              unless user_ids.nil?
                user_ids.each do |user_id|
                  user = User.find(user_id)
                  @final_pre_info << [book.metadata["displayName"] +" - #{book.form} Form ", book.ibook_id, license_set_ids, user.edutorid, user.rollno, user.name, user.center.name, user.academic_class.name, user.section.name]
                end
              end
            end
          end
        rescue
          next
        end
      end
    return @final_pre_info
  end

  def self.teachers_books_deployment_data(user_id)
    present_user = User.find(user_id)
  end

  end
