class Usage < ActiveRecord::Base
  #default_scope :order=>'last_used_time DESC'
  validates :uri,:presence => true
  validates_presence_of :user_id, :unless => :deviceid?
  belongs_to :user
  belongs_to :content,:foreign_key=>"uri"

  #attr_accessor :id, :content_id, :duration, :user_id, :count, :last_used_time, :last_used_duration, :created_at, :updated_at, :uri, :uid, :_id

  def self.csv_header
    "id,content_id,duration,user_id,count,last_used_time,last_used_duration,created_at,updated_at,uri,uid".split(",")
  end

  def to_csv
    [id, content_id, duration, user_id, count, last_used_time, last_used_duration, created_at, updated_at, uri, uid]
  end


  def self.analytics_usages
    User.students.each do |user|
      last_analytic_usage_for_user = user.analytics_usages.last
      total_usage_count_in_mins = user.usages.sum(:duration)/60 rescue 1
      total_usage_count_in_mins = 1 if total_usage_count_in_mins == 0
      unless last_analytic_usage_for_user.nil?
        if total_usage_count_in_mins > last_analytic_usage_for_user.total_usage
          today_usage = total_usage_count_in_mins -last_analytic_usage_for_user.total_usage
          #for attribute today_usage will be in seconds ans total_usage will be in minutes
          user.analytics_usages.build(usage_date: Date.today.to_time.to_i,
                                      total_usage: total_usage_count_in_mins,
                                      today_usage: today_usage*60).save
          logger.info "--------Today's Analytics for user:#{user.id}, today_usage: #{today_usage*60}, total_usage_in_mins: #{total_usage_count_in_mins}, Date:#{Date.today}-----------"
          puts "--------Today's Analytics for user:#{user.id}, today_usage: #{today_usage*60}, total_usage_in_mins: #{total_usage_count_in_mins}, Date:#{Date.today}-----------"
        end
      else
        first_analytic_entry_to_user = user.usages.last
        if !first_analytic_entry_to_user.nil? and last_analytic_usage_for_user.nil?
          #for attribute today_usage will be in seconds ans total_usage will be in minutes
          user.analytics_usages.build(usage_date: Date.today.to_time.to_i,
                                      total_usage: total_usage_count_in_mins,
                                      :today_usage=>total_usage_count_in_mins*60).save
          logger.info "===== First Entry for the user: #{user.id}=========="
          puts "===== First Entry for the user: #{user.id}=========="
        else
          logger.info "No usages for user "
          puts  "No usages for user/Already entry for analytic usage "
        end
      end
    end
  end

  def self.daily_usage
    UserMailer.daily_student_analytics_usages.deliver
  end


  def self.daily_students_content_test_consumed
    UserMailer.daily_students_content_test_consumed.deliver
  end

  def self.daily_contents_touched
    UserMailer.daily_contents_students_consumed.deliver
  end

  def self.daily_message_sent
    UserMailer.daily_messages_sent.deliver
  end

  def self.all_institutions_test_results
    #@contexts =  Context.joins(:quiz=>:quiz_attempts)
    @attempts = QuizAttempt.all
    results = []
    @attempts.each do |attempt|
       results  << [(attempt.user.edutorid rescue ""),(attempt.user.name rescue "NA"),(attempt.user.institution.try(:name)if attempt.user.institution rescue "NA"),(attempt.user.center.try(:name) if attempt.user.center rescue "NA"),(attempt.user.academic_class.try(:name) if attempt.user.academic_class rescue "NA"),(attempt.user.section.try(:name) if attempt.user.section rescue "NA"),(attempt.quiz.context.subject.try(:name) if attempt.quiz.context.subject rescue "NA"),(attempt.quiz.context.chapter.try(:name) if attempt.quiz.context.chapter rescue "NA"),(attempt.quiz.context.topic.try(:name) if attempt.quiz.context.topic rescue "NA"),(attempt.quiz.try(:name) if attempt.quiz rescue ""),(attempt.sumgrades.to_i),(attempt.attempt),(attempt.quiz.quiz_question_instances.sum(:grade).to_i if attempt.quiz rescue ""),(Time.at(attempt.timefinish).to_time)]
    end
    filename = "All_test_results.csv"
    csv_data = FasterCSV.generate do |csv|
      #csv << "Name,EdutorID,Institution,Center,Class,Section".split(",")
      csv << "EdutorID,Name,Institution,Center,Class,Section,Subject,chapter,Topic,Test,Sum Grades,Attempt,Total Marks,Submit Time".split(",")
      results.each do |c|
        csv << c
      end
    end
    path = Rails.root.to_s+"/tmp/cache/"
    file = File.new(path+"/"+filename, "w+")
    File.open(file,'wb') do |f|
      f.write(csv_data)
    end
  end



end
