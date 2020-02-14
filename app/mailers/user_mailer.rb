class UserMailer < ActionMailer::Base
  default :from => "admin_studyzone@ignitorlearning.com"

  def password_notification(user, random_password)
    @user = user
    @random_password = random_password
    to = []
    to << user.email
    to << user.profile.parent_email if user.profile.parent_email.present?
    to << "support1@ignitorlearning.com"
    if user.institution.user_configuration.deliver_reset_password_email
      to << user.center.center_admins.first.email
    end
    subject = "New Password for"+user.name+"(#{user.edutorid})"
    subject += ", rollno: #{user.rollno}" if user.rollno.present?
    mail(:to => to, :subject => subject)
    #mail(:to => user.profile.parent_email, :subject => "New Password") if user.profile.parent_email.present?
    #mail(:to => "support@edutor.in", :subject => "New Password")
  end

  def content_notification(user,content,message)
    @content = content
    @user = user
    @message = message
    mail(:to =>@user.email , :subject => "New content is uploaded for process")
  end


  def daily_student_analytics_usages
    results = []
    AnalyticsUsage.where("user_id is NOT NULL").where(:usage_date=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).each do |usage|
      results << [usage.user.try(:name),(usage.user.edutorid rescue ""),(usage.user.school_uid rescue ""),(usage.user.center.try(:name) if usage.user.center rescue ""),(usage.user.academic_class.try(:name) if usage.user.academic_class rescue ""),(usage.user.section.try(:name) rescue ""),(usage.today_usage/60 rescue 0),Time.at(usage.usage_date).to_datetime.strftime("%d-%b-%Y")]
    end
    filename = "Total_usage_on_#{Date.yesterday}.csv"
    csv_data = FasterCSV.generate do |csv|
      csv << "Name,Edutorid,school-uid,Center,Class,Section,total-usage-in-minutes,date".split(",")
      results.each do |c|
        csv << c
      end
    end
    path = Rails.root.to_s+"/tmp/cache"
    file = File.new(path+"/"+"#{Time.now.to_i}"+"_usage.csv", "w+")
    File.open(file,'w') do |f|
      f.write(csv_data)
    end
    attachments[filename] =  File.open(file.path, 'rb'){|f| f.read}
    mail(
        :subject=>"Content Usage data for #{Date.today}",
        :to => "dailyreports@myedutor.com"
    )
  end


  def daily_students_content_test_consumed
    results = []
    users = []
    users << Usage.where("user_id is NOT NULL").where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    users << AnalyticsUsage.where("user_id is NOT NULL").where(:usage_date=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    users << QuizAttempt.where("user_id is NOT NULL").where(:timefinish=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    #users << TestResult.where("user_id is NOT NULL").where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    users = users.uniq
    User.where(:id=>users).each do |user|
      total_test_minutes = 0
      total_usage = 0
      contents_touched = 0
      total_tests = 0
      total_usage = AnalyticsUsage.where(:usage_date=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).sum(:today_usage)
      contents_touched = Usage.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).map(&:uri).count
      tests = QuizAttempt.where(:timefinish=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id)
      #practice_test = TestResult.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).group(:uri).map(&:id)
      total_tests = tests.count
      tests.each do  |test|
        total_test_minutes = total_test_minutes+test.quiz_question_attempts.sum(:time_taken)
      end
      results << [user.try(:name),(user.edutorid rescue ""),(user.school_uid rescue ""),(user.center.try(:name) if user.center rescue ""),(user.academic_class.try(:name) if user.academic_class rescue ""),(user.section.try(:name) rescue ""),(total_usage/60 rescue 0),(contents_touched),(total_tests),(total_test_minutes/60 rescue 0)]
    end
    filename = "Total_tests_contents_usage_on_#{Date.yesterday}.csv"
    csv_data = FasterCSV.generate do |csv|
      csv << "Name,Edutorid,School-Uid,Center,Class,Section,total-usage-in-minutes,Contents consumed,Total tests taken,Tests taken time".split(",")
      results.each do |c|
        csv << c
      end
    end
    path = Rails.root.to_s+"/tmp/cache"
    file = File.new(path+"/"+"#{Time.now.to_i}"+"_test_content_usage.csv", "w+")
    File.open(file,'w') do |f|
      f.write(csv_data)
    end
    attachments[filename] =  File.open(file.path, 'rb'){|f| f.read}
    mail(
        :subject=>" Daily_user_engagement_data #{Date.today}",
        :to => "dailyreports@myedutor.com"
    )
  end

  def daily_contents_students_consumed
    results = []
    uris =  Usage.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:uri).uniq
    uris.each do |uri|
      content = Content.find_by_uri(uri)
      usage_uri = Usage.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:uri=>uri)
      content_students_consumed_count = usage_uri.count
      content_students_duration_count = usage_uri.sum(:duration)
      if content
        content_name = content.name
        content_type =  content.type
        #content_src = Asset.find_by_archive_id_and_archive_type(content.id,content.type).src
      else
        content_name = ""
        content_type =  ""
      end
      results  << [uri,content_name,content_type,content_students_consumed_count,(content_students_duration_count/60 rescue 0)]
    end

    filename = "Total_content_consumed_on_#{Date.yesterday}.csv"
    csv_data = FasterCSV.generate do |csv|
      csv << "content,Content name,Content type,Students consumed,Content consumed duration".split(",")
      results.each do |c|
        csv << c
      end
    end
    path = Rails.root.to_s+"/tmp/cache"
    file = File.new(path+"/"+"#{Time.now.to_i}"+"_test_content_usage.csv", "w+")
    File.open(file,'w') do |f|
      f.write(csv_data)
    end
    attachments[filename] =  File.open(file.path, 'rb'){|f| f.read}
    mail(
        :subject=>" Daily_new_content_tests_consumed #{Date.today}",
        :to => "dailyreports@myedutor.com"
    )
  end


  def daily_contents_students_consumed_all
    results = []
    user_ids = Institution.find(9248).students.map(&:id)
    #uris =  Usage.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:uri).uniq
    #urises =  Usage.where('user_id is NOT NULL and user_id != 0').map(&:uri).uniq
    urises =  Usage.where(:user_id=>user_ids).map(&:uri).uniq
    i = 0
    #urises.in_groups(20,false) do |uris|
      urises.each do |uri|
        Usage.where(:uri=>uri).each do |usage|
          #begin
          content = Content.find_by_uri(usage.uri)
          user = User.includes(:institution=>(:profile),:center=>(:profile),:academic_class=>(:profile),:section=>(:profile)).find_by_id(usage.user_id)
          if user
            duration = usage.duration/60
            if duration == 0
              duration = 1
            end
            if content
              content_name = content.name
              content_type =  content.type
              content_src = Asset.find_by_archive_id_and_archive_type(content.id,content.type).src
            else
              content_name = ""
              content_type =  ""
            end
            results  << [(user.name rescue ""),(user.edutorid rescue ""),(user.institution.try(:name)if user.institution rescue ""),(user.center.try(:name) if user.center rescue ""),(user.academic_class.try(:name) if user.academic_class rescue ""),(user.section.try(:name) if user.section rescue ""),usage.uri,content_src,duration,Time.at(usage.created_at).to_date]
          end
        end
      end
      #end
      i = i+1
      puts "=================",i
      #users =  User.where(:edutorid=>DeviceResponse.where("data like?","%wrong password%").where(:created_at=>100.days.ago.to_i..Time.now.to_i).map(&:edutor_id)).map(&:id).uniq
      #users.each do |u|
      #  user = User.includes(:institution=>(:profile),:center=>(:profile),:academic_class=>(:profile),:section=>(:profile)).find_by_id(u)
      #  results  << [(user.name rescue ""),(user.edutorid rescue ""),(user.institution.try(:name)if user.institution rescue ""),(user.center.try(:name) if user.center rescue ""),(user.academic_class.try(:name) if user.academic_class rescue ""),(user.section.try(:name) if user.section rescue "")]
      #end
      filename = "Total_content_consumed_on_#{Time.now}.csv"
      puts "=================", filename
      csv_data = FasterCSV.generate do |csv|
        #csv << "Name,EdutorID,Institution,Center,Class,Section".split(",")
        csv << "Name,EdutorID,Institution,Center,Class,Section,uri,src,duration,date".split(",")
        results.each do |c|
          csv << c
        end
      end
      path = Rails.root.to_s+"/tmp/cache/usages"
      file = File.new(path+"/"+"#{Time.now.to_i}"+"_total_usage.csv", "w+")
      File.open(file,'wb') do |f|
        f.write(csv_data)
      end
      #UserMailer.send_email(file,filename).deliver
      #attachments[filename] =  File.open(file.path, 'rb'){|f| f.read}
      #mail(:subject=>"Content consumed data for #{Date.today}",:to => "dilip.bv@myedutor.com")
      #rescue Exception => e
      #  next
      #end



    #end
  end

  def send_email(file,filename)
    attachments[filename] =  File.open(file.path, 'rb'){|f| f.read}
    mail(:subject=>"Content consumed data for #{Date.today}",:to => "dilip.bv@myedutor.com")
  end

  def daily_messages_sent
    results = []
    message_types = Message.group("message_type").map(&:message_type)
    message_types = message_types - [nil]
    message_types.each do |message_type|
      message_count = Message.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:message_type=>message_type).count
      results << [message_type,message_count]
    end
    filename = "Total_message_sent_on_#{Date.yesterday}.csv"
    csv_data = FasterCSV.generate do |csv|
      csv << "Message Type,Message count".split(",")
      results.each do |c|
        csv << c
      end
    end
    path = Rails.root.to_s+"/tmp/cache"
    file = File.new(path+"/"+"#{Time.now.to_i}"+"_test_content_usage.csv", "w+")
    File.open(file,'w') do |f|
      f.write(csv_data)
    end
    attachments[filename] =  File.open(file.path, 'rb'){|f| f.read}
    mail(
        :subject=>"Total messages sent data on #{Date.today}",
        :to => "dailyreports@myedutor.com"
    )
  end


  #Emailing the quiz pdf report to the users parent email
  def send_quiz_report(user,pdf,quiz)
    @user = user
    @quiz = quiz
    attachments['Report.pdf'] = pdf
    mail(:to => @user.profile.parent_email, :subject => "Assessment report: #{@quiz.name}")
  end

  def mail_message(to,subject,message_body)
    @message = message_body
    mail(:to =>to , :subject => subject)
  end

  def mail_message_template(to,subject,receipient,center_name,center)
    @to_a = receipient
    @c_name = center_name
    @center = center
    mail(:to =>to , :subject => subject)
  end

  def mail_message_help(to,subject,center_name,center)
    @c_name = center_name
    @center = center
    mail(:to =>to , :subject => subject)
  end

  def send_test_report(quiz_attempt_id,pdf)
    @quiz_attempt_id = quiz_attempt_id
    @question_attempts = QuizQuestionAttempt.where(:quiz_attempt_id=>quiz_attempt_id)
    @quiz = Quiz.find(@question_attempts.first.quiz_id)
    @total_marks = @quiz.quiz_question_instances.sum(:grade)
    @user = @question_attempts.first.user
    
    @total = QuizAttempt.where(:publish_id=>@question_attempts.first.quiz_attempt.publish_id,:attempt=>1)
    @total_average = @total.average(:sumgrades)
    @quiz_attempt = QuizAttempt.where(:id=>@quiz_attempt_id)
    @top_score = @total.maximum(:sumgrades)
    attachments['Report.pdf'] = pdf
    mail(:to =>'ram@myedutor.com',:cc=>'praveen@myedutor.com' , :subject => "Assessment Report")
  end

  def aakash_usage_report
    user_ids = Institution.find(703).students.map(&:id)
    results = []
    users = []
    users << Usage.where(:user_id=>user_ids,:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    users << AnalyticsUsage.where(:user_id=>user_ids,:usage_date=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    users << QuizAttempt.where(:user_id=>user_ids,:timefinish=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    users << TestResult.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user_ids).map(&:user_id)
    users = users.uniq
    User.where(:id=>users).each do |user|
      total_test_minutes = 0
      total_usage = 0
      contents_touched = 0
      total_tests = 0
      total_usage = AnalyticsUsage.where(:usage_date=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).sum(:today_usage)
      contents_touched = Usage.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).map(&:uri).count
      tests = QuizAttempt.where(:timefinish=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id)
      practice_test = TestResult.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).group(:uri).map(&:id)
      #total_usage = Usage.where(:user_id=>user.id).sum(:duration)
      #contents_touched = Usage.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).map(&:uri).count
      #tests = QuizAttempt.where(:user_id=>user.id)
      total_tests = tests.count + practice_test.count
      #tests.each do  |test|
      #  total_test_minutes = total_test_minutes+test.quiz_question_attempts.sum(:time_taken)
      #end
      results << [user.try(:name),(user.edutorid rescue ""),(user.center.try(:name) if user.center rescue ""),(user.academic_class.try(:name) if user.academic_class rescue ""),(user.section.try(:name) rescue ""),(total_usage/60 rescue 0),(contents_touched),(total_tests)]
    end
    filename = "Total_tests_contents_usage_on_#{Date.yesterday}.csv"
    csv_data = FasterCSV.generate do |csv|
      csv << "Name,Edutorid,Center,Class,Section,total-usage-in-minutes,Contents consumed,Total tests taken".split(",")
      results.each do |c|
        csv << c
      end
    end
    path = Rails.root.to_s+"/tmp/cache"
    file = File.new(path+"/"+"#{Time.now.to_i}"+"_test_content_usage.csv", "w+")
    File.open(file,'w') do |f|
      f.write(csv_data)
    end
    attachments[filename] =  File.open(file.path, 'rb'){|f| f.read}
    mail(
        :subject=>"Content and Tests Usage data for Aakash DLP and Aakash Sales Center for #{Date.today}",
        :to => "aakash@aesl.in,vineesh@aesl.in"
    )

  end

  def Kumarans_usage_report
    user_ids = Institution.find(9248).students.map(&:id)
    results = []
    users = []
    #users << Usage.where(:user_id=>user_ids,:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    ##users << AnalyticsUsage.where(:user_id=>user_ids,:usage_date=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    #users << QuizAttempt.where(:user_id=>user_ids,:timefinish=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    #users << TestResult.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user_ids).map(&:user_id)
    #users = users.uniq
    users << Usage.where(:user_id=>user_ids).map(&:user_id)
    users << AnalyticsUsage.where(:user_id=>user_ids).map(&:user_id)
    users << QuizAttempt.where(:user_id=>user_ids).map(&:user_id)
    users << TestResult.where(:user_id=>user_ids).map(&:user_id)
    users = users.uniq
    User.where(:id=>users).each do |user|
      total_test_minutes = 0
      total_usage = 0
      contents_touched = 0
      total_tests = 0
      #total_usage = AnalyticsUsage.where(:usage_date=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).sum(:today_usage)
      #contents_touched = Usage.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).map(&:uri).count
      #tests = QuizAttempt.where(:timefinish=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id)
      #practice_test = TestResult.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).group(:uri).map(&:id)
      total_usage = AnalyticsUsage.where(:user_id=>user.id).sum(:today_usage)
      contents_touched = Usage.where(:user_id=>user.id).map(&:uri).count
      tests = QuizAttempt.where(:user_id=>user.id)
      practice_test = TestResult.where(:user_id=>user.id).group(:uri).map(&:id)
      #total_usage = Usage.where(:user_id=>user.id).sum(:duration)
      #contents_touched = Usage.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).map(&:uri).count
      #tests = QuizAttempt.where(:user_id=>user.id)
      total_tests = tests.count + practice_test.count
      #tests.each do  |test|
      #  total_test_minutes = total_test_minutes+test.quiz_question_attempts.sum(:time_taken)
      #end
      results << [user.try(:name),(user.edutorid rescue ""),(user.center.try(:name) if user.center rescue ""),(user.academic_class.try(:name) if user.academic_class rescue ""),(user.section.try(:name) rescue ""),(total_usage/60 rescue 0),(contents_touched),(total_tests)]
    end
    filename = "Total_tests_contents_usage_on_#{Date.yesterday}.csv"
    csv_data = FasterCSV.generate do |csv|
      csv << "Name,Edutorid,Center,Class,Section,total-usage-in-minutes,Contents consumed,Total tests taken".split(",")
      results.each do |c|
        csv << c
      end
    end
    path = Rails.root.to_s+"/tmp/cache"
    file = File.new(path+"/"+"#{Time.now.to_i}"+"_test_content_usage.csv", "w+")
    File.open(file,'w') do |f|
      f.write(csv_data)
    end
    attachments[filename] =  File.open(file.path, 'rb'){|f| f.read}
    mail(
        :subject=>"Content and Tests Usage data for Aakash DLP and Aakash Sales Center for #{Date.today}",
        :to => "dilip.bv@myedutor.com"#:to => "aakash@aesl.in,vineesh@aesl.in"
    )

  end


  def weekly_students_content_test_consumed
     results = []
    users = []
    users << Usage.where("user_id is NOT NULL").where(:created_at=>(7.days.ago.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    users << AnalyticsUsage.where("user_id is NOT NULL").where(:usage_date=>(7.days.ago.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    users << QuizAttempt.where("user_id is NOT NULL").where(:timefinish=>(7.days.ago.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    #users << TestResult.where("user_id is NOT NULL").where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i)).map(&:user_id)
    users = users.uniq
    User.where(:id=>users).each do |user|
      total_test_minutes = 0
      total_usage = 0
      contents_touched = 0
      total_tests = 0
      total_usage = AnalyticsUsage.where(:usage_date=>(7.days.ago.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).sum(:today_usage)
      contents_touched = Usage.where(:created_at=>(7.days.ago.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).map(&:uri).count
      tests = QuizAttempt.where(:timefinish=>(7.days.ago.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id)
      #practice_test = TestResult.where(:created_at=>(Date.yesterday.to_time.to_i)..(Date.today.to_time.to_i),:user_id=>user.id).group(:uri).map(&:id)
      total_tests = tests.count
      tests.each do  |test|
        total_test_minutes = total_test_minutes+test.quiz_question_attempts.sum(:time_taken)
      end
      results << [user.try(:name),(user.edutorid rescue ""),(user.school_uid rescue ""),(user.center.try(:name) if user.center rescue ""),(user.academic_class.try(:name) if user.academic_class rescue ""),(user.section.try(:name) rescue ""),(total_usage/60 rescue 0),(contents_touched),(total_tests),(total_test_minutes/60 rescue 0)]
    end
    csv_data = FasterCSV.generate do |csv|
      csv << "Name,Edutorid,School-Uid,Center,Class,Section,total-usage-in-minutes,Contents consumed,Total tests taken,Tests taken time".split(",")
      results.each do |c|
        csv << c
      end
    end
    path = Rails.root.to_s+"/tmp/cache"
    file = File.new(path+"/"+"#{Time.now.to_i}"+"_test_content_usage.csv", "w+")
    File.open(file,'w') do |f|
      f.write(csv_data)
    end
    filename = "Total_tests_contents_usage_for_week_#{Date.yesterday}.csv"
    attachments[filename] =  File.open(file.path, 'rb'){|f| f.read}
    mail(
        :subject=>" Weekly_user_engagement_data #{Date.yesterday}",
        :to => "dailyreports@myedutor.com"#"dilip.bv@myedutor.com"#
    )
  end

  
  def send_pdf_report(user,pdf,start_date,end_date)
    @user = user
    filename = "#{@user.name}_#{@user.edutorid}_#{Time.now.to_i.to_s}.pdf"
    attachments[filename] = pdf
    @start_date = start_date
    @end_date = end_date
    mail(:to=>@user.profile.parent_email, :subject=>"User Monthly Report")
    #mail(:to=>"dilip.bvd@gmail.com", :subject=>"User Monthly Report")
    file = File.new(Rails.root.to_s+"/public/mail_sent.txt", "a+")
    File.open(file,  "a", 0644) do |f|
      f.puts(@user.id.to_s+':')
    end
  end



def send_message(email,message,subject)
    @message = message
    mail(:to =>email , :subject => subject)
end  


end
