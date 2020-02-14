class QuizzesController < ApplicationController
  include ApplicationHelper
  authorize_resource :expect=>[:get_teacher_quiz,:get_teacher_quiz1,:get_teacher_feedback,:get_test_zip,:rubric_publish]
  skip_before_filter :authenticate_user!, :only=>[:get_teacher_quiz,:get_teacher_quiz1,:get_teacher_feedback,:get_test_zip,:rubric_publish,:download_catchall]
  EDUTOR = 1
  # GET /quizzes
  # GET /quizzes.json
  def index
    if current_user.id == EDUTOR
      @filter_center = 0
    elsif current_user.is?'IA'
      @filter_center = 'IA'
    else
      @filter_center = current_user.center_id
    end
    if params[:filter_center].present?
      @filter_center = params[:filter_center]
    end
    @centers = get_centers
    logger.info"===#{@centers.inspect}"
    #@quizzes = Quiz.find(:all,:order=>'id DESC').page(params[:page])
    #@quizzes = Quiz.order("id DESC").all.page(params[:page])
    if @filter_center == 0
      @quizzes = Quiz.where("id > ? AND format_type != ?",0,7).order('id DESC').page(params[:page])
    elsif @filter_center == 'IA'
      @quizzes = Quiz.where("id > ? AND (institution_id=? OR center_id IN (?)) AND format_type != ?",0,current_user.institution_id,current_user.centers.map(&:id), 7).order('id DESC').page(params[:page])
    else
      @quizzes = Quiz.where("id > ? AND center_id = ? AND format_type != ?",0,@filter_center, 7).order('id DESC').page(params[:page])
    end
    if @filter_center.to_i == 1
      @main_heading = "Edutor Assessments"
    elsif @filter_center.to_i ==0
      @main_heading = "All Assessments"
    else
      @main_heading = Center.find(@filter_center).profile.firstname+' Assessments'
    end

    respond_to do |format|
      format.html { render "index"}
      format.json { render json: @quizzes }
    end
  end

  def filter
    if current_user.id == EDUTOR
      @filter_center = 0
    elsif current_user.is?'IA'
      @filter_center = 'IA'
    else
      @filter_center = current_user.center_id
    end
    if params[:filter_center].present?
      @filter_center = params[:filter_center]
    end
    @centers = get_centers
    #@quizzes = Quiz.find(:all,:order=>'id DESC').page(params[:page])
    #@quizzes = Quiz.order("id DESC").all.page(params[:page])
    if @filter_center.to_i == 0
      @quizzes = Quiz.where("id > ? AND format_type != ?",0,7).order('id DESC').page(params[:page])
    elsif @filter_center == 'IA'
      @quizzes = Quiz.where("id > ? AND (institution_id=? OR center_id (IN) ?) AND format_type != ?",0,current_user.institution_id,current_user.centers.map(&:id), 7 ).order('id DESC').page(params[:page])
    else
      @quizzes = Quiz.where("id > ? AND center_id = ? AND format_type != ?",0,@filter_center, 7).order('id DESC').page(params[:page])
    end
    if @filter_center.to_i ==1
      @main_heading = "Edutor Assessments"

    elsif @filter_center.to_i == 0
      @main_heading = "All Assessments"
    else
      @main_heading = Center.find(@filter_center).profile.firstname+' Assessments'
    end

    respond_to do |format|
      format.html { render "index"}
      format.json { render json: @quizzes }
    end
  end

  def get_centers
    if current_user.id == 1
      d = {}
      d[1] = "Edutor"
      Center.all.each do |i|
        d[i.id] = i.profile.firstname
      end
      return d
    end
    d = {}
    d[1] = "Edutor"  if current_user.is?"EA"#unless current_user.is?"EA" or current_user.id == 9251 or current_user.institution_id == 14289
    Institution.where(:id=>current_user.institution_id).first.centers.each do |i|
      d[i.id] = i.profile.firstname
    end
    return d
  end

  def all_other_assessments
    #if current_user.id != EDUTOR
    # redirect_to :action => "my_institutes_assessments"
    #return
    #end
    if current_user.id == EDUTOR
      @filter_center = 1
    else
      @filter_center = current_user.center_id
    end
    if params[:filter_center].present?
      @filter_center = params[:filter_center]
    end
    @centers = get_centers
    @quizzes = Quiz.where("institution_id != ? AND format_type != ? ",EDUTOR, 7).order('id DESC').page(params[:page])
    @main_heading = 'All Other Assessments'
    respond_to do |format|
      format.html { render "index"}
      format.json { render json: @quizzes }
    end
  end

  def my_institutes_assessments
    @quizzes = Quiz.where("institution_id = ? AND format_type != ? ",current_user.institution_id, 7).order('id DESC').page(params[:page])
    @main_heading = Institution.find(current_user.institution_id).profile.firstname+' Assessments'
    respond_to do |format|
      format.html { render "index"}
      format.json { render json: @quizzes }
    end
  end

  def edutor_assessments
    @quizzes = Quiz.where("institution_id = ? AND format_type != ?",EDUTOR, 7).order('id DESC').page(params[:page])
    @main_heading = 'Edutor Assessments'
    respond_to do |format|
      format.html { render "index"}
      format.json { render json: @quizzes }
    end
  end

  def see_student_results
    if current_user.institution_id.nil?
      createdby = current_user.id
    else
      createdby = current_user.institution_id
    end
    @quizzes = Quiz.joins(:quiz_attempts).where("institution_id = ? OR institution_id = ? AND quiz_attempts.user_id=?",createdby,EDUTOR,params[:id]).order('quiz_attempts.id DESC').page(params[:page])
    @main_heading = 'All Attempted Assessments By '+User.find(params[:id]).profile.try(:firstname)
    respond_to do |format|
      format.html { render "index"}
      format.json { render json: @quizzes }
    end
  end

  def publish_to
    @quiz = Quiz.find(params[:id])
    if @quiz.id >= 302 && @quiz.id <= 3219 #Will enable once these assessments are cleaned up (classes, subjects filled)
      respond_to do |format|
        format.html { redirect_to @quiz, notice: 'This Assessment cannot be published at this point of time....' }
        format.json { render json: @quiz, status: :created, location: @quiz }
      end
      return
    end
    if @quiz.questions.count ==0
      respond_to do |format|
        format.html { redirect_to @quiz, notice: 'Assessment cannot be published without questions. Please add some questions.' }
        format.json { render json: @quiz, status: :created, location: @quiz }
      end
      return
    end
    @target = QuizTargetedGroup.new
    if !@quiz.publish_access(current_user.id)
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
      return
    end

    respond_to do |format|
      format.html
      format.json { render json: @quiz.errors, status: :unprocessable_entity }
    end
  end

  def publish
    @quiz = Quiz.find(params[:id])
    if @quiz.publish_access(current_user.id)
      logger.info"================innn"
      params[:quiz_targeted_group][:quiz_id] = @quiz.id
      params[:quiz_targeted_group][:published_by] = current_user.id
      if params[:quiz_targeted_group][:extras] == 'institute'
        params[:quiz_targeted_group][:pause] = 0
      end
      recipients = params[:message][:multiple_recipient_ids].split(",") if params[:message][:multiple_recipient_ids]

      if params[:quiz_targeted_group][:to_group].to_i == 0
        #logger.info"=========================1"
        if recipients.empty?
          #logger.info"=====================2"
          @target = QuizTargetedGroup.new(params[:quiz_targeted_group])
          respond_to do |format|
            @target.errors.add :recipient_id, "Please select atleast one individual user"
            format.html { render action: "publish_to"}
            format.json { render json: @quiz.errors, status: :unprocessable_entity }
          end
          return
        end
        params[:quiz_targeted_group][:group_id] = nil
        params[:quiz_targeted_group][:to_group] = false
        ActiveRecord::Base.transaction do
          recipients.each do |rep|
            params[:quiz_targeted_group][:recipient_id] = rep
            @target = QuizTargetedGroup.new(params[:quiz_targeted_group])
            if @target.save
              if @quiz.format_type == 3
                logger.info"=================test===#{@quiz.format_type}"
                create_message_openformat_multiple(true,@quiz.id,@target.id)
              else
                create_message(true,@quiz.id,@target.id)
              end
            else
              respond_to do |format|
                format.html { render action: "publish_to" }
                format.json { render json: @quiz.errors, status: :unprocessable_entity }
              end
              return
            end
          end
        end
        respond_to do |format|
          format.html { redirect_to @quiz, notice: 'Assessment was successfully published.' }
          format.json { render json: @quiz.errors, status: :unprocessable_entity }
        end
        return
      else
        params[:quiz_targeted_group][:to_group] = true
        ActiveRecord::Base.transaction do
          @target = QuizTargetedGroup.new(params[:quiz_targeted_group])
          if @target.save
            if @quiz.format_type == 3
              create_message_openformat_multiple(false,@quiz.id,@target.id)
            else
              create_message(false,params[:id], @target.id)
            end
            respond_to do |format|
              format.html { redirect_to @quiz, notice: 'Assessment was successfully published.' }
              format.json { render json: @quiz.errors, status: :unprocessable_entity }
            end
          else
            respond_to do |format|
              format.html { render action: "publish_to" }
              format.json { render json: @quiz.errors, status: :unprocessable_entity }
            end
          end
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to action: "index",notice: 'Assessment was not successfully published.'  }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    end
  end

  #Publishing the quiz to the individuals
  def publish_to_individual
    @target = QuizTargetedGroup.find(params[:id])
    @quiz = Quiz.find(@target.quiz_id)
  end

  #Searching the user in the published group
  def individual_user_group
    like= "%".concat(params[:term].concat("%"))
    students = UserGroup.where(:group_id=>params[:group_id]).map(&:user_id)
    users =  Profile.includes(:user).where('users.id'=>students).where("surname like ? or firstname like ? or users.edutorid like ? ",like,like,like)
    list = users.empty? ? users : users.map {|u| Hash[id: u.user_id, label: u.autocomplete_display_name, name: u.autocomplete_display_name]}
    render json: list
  end


  #saving the individual publish assessment
  def save_publish_individual
    @publish = QuizTargetedGroup.find(params[:id])
    @quiz = Quiz.find(@publish.quiz_id)
    recipients = params[:message][:multiple_recipient_ids].split(",")
    if @quiz.format_type == 3
      messages_ids = UserOpenformatQuizCode.where(:quiz_id=>@quiz.id,:publish_id=>@publish.id).map(&:message_id).uniq
      recipients.each do |r|
        message_id = messages_ids.sample
        @test_code =  OpenformatQuizFile.find_by_message_id_and_publish_id(message_id,@publish.id)
        UserMessage.create(:user_id=>r,:message_id=>message_id)
        UserOpenformatQuizCode.create(:user_id=>r,:quiz_id=>@quiz.id,:publish_id=>@publish.id,:test_code=>@test_code.test_code,:message_id=>message_id,:openformat_quiz_file_id=>@test_code.id)
      end
      respond_to do |format|
        format.html { redirect_to @quiz, notice: 'Assessment was successfully published.' }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
      return
    end
    message = MessageQuizTargetedGroup.where(:quiz_targeted_group_id=>@publish.id)
    if !message.first.nil?
      m = message.first.message_id
      old_message = Message.find(m)
      recipients.each do |user|
        message = Message.new(old_message.serializable_hash)
        message.recipient_id = user
        message.sender_id = current_user.id
        message.group_id = nil
        message_assets = message.assets.build
        message_assets.attachment = old_message.assets.first.attachment
        message_assets.src = old_message.assets.first.src
        message.save
        MessageQuizTargetedGroup.create(:message_id=>message.id,:quiz_targeted_group_id=>@publish.id)
      end
      respond_to do |format|
        format.html { redirect_to @quiz, notice: 'Assessment was successfully published.' }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    else
      respond_to do |format|
        format.html { redirect_to @quiz, notice: 'Cannot publish to individual' }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    end


  end




  def show_attempts
    @publish = QuizTargetedGroup.find(params[:id])
    @quiz = Quiz.find(@publish.quiz_id)
    group_id = @publish.group_id
    if !@publish.to_group?
      group_id = @publish.recipient_id
    end
    logger.info "==================#{group_id}"
    #@attempts = QuizAttempt.where(:quiz_id=>@quiz.id,:publish_id=>@publish.id).order("sumgrades DESC")
    @first_attempts = QuizAttempt.find_by_sql("SELECT qa.*,ug.user_id FROM quiz_attempts qa INNER JOIN user_groups ug on qa.user_id=ug.user_id WHERE qa.quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND ug.group_id=#{group_id} AND (qa.attempt=1) group by qa.user_id")
    @attempts = QuizAttempt.find_by_sql("SELECT qa.*,ug.user_id FROM quiz_attempts qa INNER JOIN user_groups ug on qa.user_id=ug.user_id WHERE qa.quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND ug.group_id=#{group_id}")
    @other_group_attempts = QuizAttempt.find_by_sql("SELECT * FROM quiz_attempts qa1 WHERE quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND id NOT IN (SELECT qa.id FROM quiz_attempts qa INNER JOIN user_groups ug on qa.user_id=ug.user_id WHERE qa.quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND ug.group_id=#{group_id})")
    @total_marks = @quiz.quiz_question_instances.sum(:grade)
    @g_attempts = @attempts.map(&:user_id)
    @user_in_group = QuizAttempt.find_by_sql("SELECT user_id FROM user_groups inner join users on users.id=user_groups.user_id WHERE group_id=#{group_id} and users.edutorid like 'ES-%'").map(&:user_id)
    @not_attempted = @user_in_group-@g_attempts
    if (@quiz.accessible(current_user.id, current_user.institution_id))
      respond_to do |format|
        format.html
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    else
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    end
  end


  #displaying all attempts
  def show_all_attempts
    @publish = QuizTargetedGroup.find(params[:id])
    @quiz = Quiz.find(@publish.quiz_id)
    @attempts = QuizAttempt.where(:quiz_id=>@quiz.id,:publish_id=>@publish.id).order("sumgrades DESC")
    if (@quiz.accessible(current_user.id, current_user.institution_id))
      respond_to do |format|
        format.html
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    else
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    end
  end

  def show_question_attempts
    @quiz_attempt_id = params[:id]
    @question_attempts = QuizQuestionAttempt.where(:quiz_attempt_id=>params[:id])
    @quiz = Quiz.find(@question_attempts.first.quiz_id)
    @total_marks = @quiz.quiz_question_instances.sum(:grade)
    @user = @question_attempts.first.user
    @total = QuizAttempt.where(:publish_id=>@question_attempts.first.quiz_attempt.publish_id,:attempt=>1)
    @total_average = @total.average(:sumgrades)
    @publish_id = @question_attempts.first.quiz_attempt.publish_id
    @quiz_attempt = QuizAttempt.where(:publish_id=>@publish_id,:attempt=>1,:user_id=>@user.id)
    @total_students = QuizAttempt.where(:publish_id=>@publish_id,:attempt=>1).map(&:user_id).uniq
    @top_score = @total.maximum(:sumgrades)
    @total_questions = @quiz.questions.count
    @correct_attempts = @question_attempts.where(:correct=>true).count
   # @wrong_attempts = @question_attempts.where(:correct=>false).count
   # @not_attempts = @total_questions - (@correct_attempts+@wrong_attempts)
 @not_attempts = @total_questions - (McqQuestionAttempt.where(:quiz_question_attempt_id=>@question_attempts).map(&:quiz_question_attempt_id).uniq.count+FibQuestionAttempt.where(:quiz_question_attempt_id=>@question_attempts.map(&:id),:fib_question_answer=>0).count)
    @wrong_attempts = @total_questions - (@correct_attempts+@not_attempts)
    #@quiz_attempt_id = params[:id]
    #@quiz_attempt = QuizAtempt.includes(:quiz).find(params[:id])


    if (@quiz.accessible(current_user.id, current_user.institution_id))
      respond_to do |format|
        format.html
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
        format.pdf do
          render :pdf => "#{@user.name}",
                 :disposition => 'attachment',
                 :template=>"quizzes/quiz_attempt_report.pdf.html",
                 #:show_as_html=>true,
                 :disable_external_links => true,
                 :print_media_type => true

        end

      end
    else
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_message(type,quiz_id,publish_id)
    @quiz = Quiz.find(quiz_id)
    @publish = QuizTargetedGroup.find(publish_id)
    images = []

    if @quiz
      if @quiz.format_type == 0
        @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.testpaper(:id=>@quiz.id.to_s,:version=>"2.0",:publish_id=>@publish.id.to_s){
            xml.test_password(:value=>(@publish.password.length > 0) ? @publish.password : "")
            xml.show_solutions_after(:value=>(@publish.show_answers_after).to_s)
            xml.show_score_after(:value=>(@publish.show_score_after).to_s)
            xml.pause(:value=>(@publish.pause) ? '1' : '0')
            xml.shuffleoptions(:value=>(@publish.shuffleoptions?) ? "1" : "0")
            xml.shufflequestions(:value=>(@publish.shufflequestions?) ? "1" : "0")
            xml.start_time(:value=>@publish.timeopen.to_i.to_s)
            xml.end_time(:value=>@publish.timeclose.to_i.to_s)
            xml.guidelines(:value=>@quiz.intro.to_s)
            xml.requisites(:value=>"")
            if @quiz.timelimit > 0
              xml.time(:value=>@quiz.timelimit.to_s)
            else
              xml.time(:value=>"-1")
            end
            xml.level(:value=>@quiz.difficulty.to_s)
            if @quiz.quiz_sections.empty?
              @instance = QuizQuestionInstance.where("quiz_id = ?",quiz_id).each do |i|
                quiz_questions(xml,i,q=nil)
              end

            else
              @quiz.quiz_sections.each do |section|
                xml.section(:name=>section.name){
                  section.quiz_question_instances.each do |i|
                    quiz_questions(xml,i,q=nil)
                  end
                }
              end
            end
          }
        end
      else
        @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.testpaper(:id=>@quiz.id.to_s,:version=>"2.0",:publish_id=>@publish.id.to_s){
            xml.exam_format_type(:value=>"open_format")
            xml.test_password(:value=>(@publish.password.length > 0) ? @publish.password : "")
            xml.show_solutions_after(:value=>(@publish.show_answers_after).to_s)
            xml.show_score_after(:value=>(@publish.show_score_after).to_s)
            xml.pause(:value=>(@publish.pause) ? '1' : '0')
            xml.end_time(:value=>@publish.timeclose.to_i.to_s)
            xml.start_time(:value=>@publish.timeopen.to_i.to_s)
            xml.guidelines(:value=>@quiz.intro.to_s)
            xml.requisites(:value=>"")
            xml.examtype(:value=>"bitsat_mock")
            if !@quiz.asset.nil?
              xml.testpaper_source(:value=>@quiz.asset.attachment_file_name)
            end
            if @quiz.timelimit > 0
              xml.examtime(:value=>@quiz.timelimit.to_s)
            else
              xml.examtime(:value=>"-1")
            end
            @quiz.questions.each do |question|
              qqi = QuizQuestionInstance.where(:quiz_id=>@quiz.id,:question_id=>question.id).first
              xml.question_set(:id=>question.id,:multi_answer=>@publish.allow_multiple_options){
                xml.section_number{
                  xml.cdata question.section
                }
                xml.q_num{
                  xml.cdata question.tag
                }
                xml.qtype{
                  xml.cdata question.qtype
                }
                question.question_answers.each do |answer|
                  xml.option(:tag=>answer.tag,:answer=>answer.fraction? ? true : false, :id=>answer.id )
                end
                xml.score{
                  xml.cdata qqi.grade
                }
                xml.question_wrong_negative_score{
                  xml.cdata qqi.penalty
                }
                xml.question_subject{
                  xml.cdata @quiz.context.subject.name
                }
                xml.question_page_num{
                  xml.cdata question.page_no
                }
                xml.question_page_location{
                  xml.cdata question.inpage_location
                }

              }
            end
          }
        end
      end
      uri = create_uri(@quiz.context)
      logger.info"============#{uri}"
      @message = Message.new
      @message.sender_id = current_user.id
      if type
        @message.recipient_id = @publish.recipient_id
      else
        @message.group_id = @publish.group_id
      end
      @message.subject = @publish.subject
      #@message.body = @publish.body+"\n"+"Test Location: Crack the Test > #{@publish.get_assessment_ncx} > #{@quiz.context.content_year.name} > #{@quiz.context.subject.name}"
      @message.body = @publish.body+"$:#{uri}"
      #@message.body = @publish.body
      @message.message_type = "Assessment"
      @message.severity = 1
      @message.label = @publish.subject
      @message.save!

      xml_string =  @builder.to_xml.to_s
      #begin
      FileUtils.mkdir_p Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}"
      File.open(Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}/assessment_#{@message.id}.etx",  "w+b", 0644) do |f|
        #f.write(xml_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
        f.write(xml_string.to_s)
      end


      #File.open(Rails.root.to_s+"/etx_files"+"/#{@quiz.name}.etx",  "w+b", 0644) do |f|
      #  #f.write(xml_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
      #  f.write(xml_string.to_s)
      #end
      #
      #@return_etx=Rails.root.to_s+"/etx_files"+"/#{@quiz.name}.etx"



      path = "/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}.zip"

      logger.info"=====================#{path}===path"
      #size = File.size(Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/"+ filename)
      #rescue Exception => e
    end
    # Insert in assets
    @assets = Asset.new
    @assets.archive_id = @message.id
    @assets.archive_type = 'Message'
    @assets.attachment_content_type = "application/zip"
    @assets.attachment_file_name = "assessment_#{@message.id}.zip"
    @assets.attachment_file_size = 0
    @assets.created_at = @message.updated_at
    @assets.src = path.gsub("/messages/","/message_download/#{@message.id}/")
    @assets.message_id = @message.message_id
    @assets.save
    MessageQuizTargetedGroup.create(:message_id=>@message.id,:quiz_targeted_group_id=>@publish.id)


    #xml_string =  @builder.to_xml.to_s
    #file = File.new("/home/praveen/Desktop/newetx/"+"index.xml", "w+")
    #File.open(file,'w') do |f|
    # f.write(xml_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
    #end

    #create ncx
=begin
      @ncx = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.navMap{
          xml.navPoint(:id=>"Curriculum",:class=>"curriculum"){
            xml.content(:src=>"curriculum")
            xml.navPoint(:id=>"Assessment",:class=>"assessment"){
              xml.content(:src=>"assessments")
              xml.navPoint(:id=>@quiz.context.board.name.to_s,:class=>"course"){
                xml.content(:src=>"cb_02")
                xml.navPoint(:id=>@quiz.context.content_year.name.to_s,:class=>"academic-class"){
                  xml.content(:src=>@quiz.context.content_year.name.to_s)
                  xml.navPoint(:id=>@publish.get_assessment_ncx,:class=>"assessment-category"){
                    xml.content(:src=>"practice")
                    xml.navPoint(:id=>@quiz.context.subject.name.to_s,:class=>"subject"){
                      xml.content(:src=>@quiz.context.subject.code)
                      if !@quiz.context.chapter.nil?
                        xml.navPoint(:id=>@quiz.context.chapter.name.to_s,:class=>"chapter"){
                          xml.content(:src=>"rff")
                          if !@quiz.context.topic.nil?
                            xml.navPoint(:id=>@quiz.context.topic.name.to_s,:class=>"topic"){
                              xml.content(:src=>"")
                              if @publish.password.length > 0
                                xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}",:passwd=>@publish.password){
                                  xml.content(:src=>"/assessment_#{@message.id}.etx")
                                }
                              else
                                xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}"){
                                  xml.content(:src=>"/assessment_#{@message.id}.etx")
                                }
                              end

                            }
                          else
                            if @publish.password.length > 0
                              xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}",:passwd=>@publish.password){
                                xml.content(:src=>"/assessment_#{@message.id}.etx")
                              }
                            else
                              xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}"){
                                xml.content(:src=>"/assessment_#{@message.id}.etx")
                              }
                            end
                          end
                        }
                      else
                        if @publish.password.length > 0
                          xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}",:passwd=>@publish.password){
                            xml.content(:src=>"/assessment_#{@message.id}.etx")
                          }
                        else
                          xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}"){
                            xml.content(:src=>"/assessment_#{@message.id}.etx")
                          }
                        end
                      end
                    }
                  }
                }
              }
            }

          }
        }
      end
=end

    @ncx = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|

      if (!@publish.extras.nil? and @publish.extras.index("homework"))and (@publish.get_assessment_ncx.eql?"practice-tests" or @publish.get_assessment_ncx.eql?"insti-tests" or @publish.get_assessment_ncx.eql?"Quiz")
        xml.navMap{
          xml.navPoint(:id=>"Curriculum",:class=>"curriculum"){
            xml.content(:src=>"curriculum")
            xml.navPoint(:id=>"Content",:class=>"content"){
              xml.content(:src=>"content")
              xml.navPoint(:id=>@quiz.context.board.name.to_s,:class=>"course"){
                xml.content(:src=>"cb_02")
                xml.navPoint(:id=>@quiz.context.content_year.name.to_s,:class=>"academic-class"){
                  xml.content(:src=>@quiz.context.content_year.name.to_s)
                  xml.navPoint(:id=>@quiz.context.subject.name.to_s,:class=>"subject"){
                    xml.content(:src=>@quiz.context.subject.code)
                    if @quiz.context.chapter_id == 0
                      #if @quiz.context.chapter_id == 0 and @quiz.context.topic_id == 0
                      xml.navPoint(:id=>@quiz.name+'_'+@publish.id.to_s,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                        xml.content(:src=>"/assessment_#{@message.id}.etx", :params=>@quiz.context.subject.params)
                      }
                    end
                    if @quiz.context.chapter_id > 0 and @quiz.context.topic_id == 0
                      xml.navPoint(:id=>@quiz.context.chapter.name,:class=>"chapter",:playOrder=>@quiz.context.chapter.play_order){
                        xml.content(:src=>@quiz.context.chapter.try(:assets).last.try(:src), :params=>@quiz.context.chapter.params)
                        xml.navPoint(:id=>@quiz.name+'_'+@publish.id.to_s,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                          xml.content(:src=>"/assessment_#{@message.id}.etx", :params=>@quiz.context.chapter.params)
                        }
                      }
                    end
                    if @quiz.context.chapter_id > 0 and @quiz.context.topic_id > 0
                      xml.navPoint(:id=>@quiz.context.chapter.name,:class=>"chapter",:playOrder=>@quiz.context.chapter.play_order){
                        xml.content(:src=>@quiz.context.chapter.assets.last.try(:src), :params=>@quiz.context.chapter.params)
                        xml.navPoint(:id=>@quiz.context.topic.name,:class=>"topic",:playOrder=>@quiz.context.topic.play_order){
                          xml.content(:src=>@quiz.context.topic.try(:assets).last.try(:src), :params=>@quiz.context.topic.params)
                          xml.navPoint(:id=>@quiz.name+'_'+@publish.id.to_s,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                            xml.content(:src=>"/assessment_#{@message.id}.etx",:params=>@quiz.context.topic.params)
                          }
                        }

                      }
                    end
                  }
                }
              }
            }
            xml.navPoint(:id=>"HomeWork",:class=>"home-work"){
              xml.content(:src=>"homework")
              xml.navPoint(:id=>@quiz.context.board.name.to_s,:class=>"course"){
                xml.content(:src=>"cb_02")
                xml.navPoint(:id=>@quiz.context.content_year.name.to_s,:class=>"academic-class"){
                  xml.content(:src=>@quiz.context.content_year.name.to_s)
                  xml.navPoint(:id=>@quiz.context.subject.name.to_s,:class=>"subject"){
                    xml.content(:src=>@quiz.context.subject.code)
                    if @quiz.context.chapter_id == 0 and @quiz.context.topic_id == 0
                      xml.navPoint(:id=>@quiz.name+'_'+@publish.id.to_s,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:submitTime=>@publish.timeclose.to_i*1000,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                        xml.content(:src=>"/assessment_#{@message.id}.etx")
                      }
                    end
                    if @quiz.context.chapter_id > 0 and @quiz.context.topic_id == 0
                      xml.navPoint(:id=>@quiz.context.chapter.name,:class=>"chapter"){
                        xml.content(:src=>@quiz.context.chapter.try(:assets).last.try(:src))
                        xml.navPoint(:id=>@quiz.name+'_'+@publish.id.to_s,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:prerequiste=>@quiz.context.chapter.uri,:submitTime=>@publish.timeclose.to_i*1000,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                          xml.content(:src=>"/assessment_#{@message.id}.etx")
                        }
                      }
                    end
                    if @quiz.context.chapter_id > 0 and @quiz.context.topic_id > 0
                      xml.navPoint(:id=>@quiz.context.chapter.name,:class=>"chapter"){
                        xml.content(:src=>@quiz.context.chapter.try(:assets).last.try(:src))
                        xml.navPoint(:id=>@quiz.context.topic.name,:class=>"topic"){
                          xml.content(:src=>@quiz.context.topic.try(:assets).last.try(:src))
                          xml.navPoint(:id=>@quiz.name+'_'+@publish.id.to_s,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:prerequiste=>@quiz.context.topic.uri,:submitTime=>@publish.timeclose.to_i*1000,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                            xml.content(:src=>"/assessment_#{@message.id}.etx")
                          }
                        }

                      }
                    end
                  }
                }
              }
            }
          }
        }
      else
        xml.navMap{
          xml.navPoint(:id=>"Curriculum",:class=>"curriculum"){
            xml.content(:src=>"curriculum")
            xml.navPoint(:id=>"Assessment",:class=>"assessment"){
              xml.content(:src=>"assessments")
              xml.navPoint(:id=>@quiz.context.board.name.to_s,:class=>"course"){
                xml.content(:src=>"cb_02")
                xml.navPoint(:id=>@quiz.context.content_year.name.to_s,:class=>"academic-class"){
                  xml.content(:src=>@quiz.context.content_year.name.to_s)
                  xml.navPoint(:id=>@publish.get_assessment_ncx,:class=>"assessment-category"){
                    xml.content(:src=>"practice")
                    xml.navPoint(:id=>@quiz.context.subject.name.to_s,:class=>"subject"){
                      xml.content(:src=>@quiz.context.subject.code)
                      if @quiz.context.chapter_id == 0 and @quiz.context.topic_id == 0
                        xml.navPoint(:id=>@quiz.name+'_'+@publish.id.to_s,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:submitTime=>@publish.timeclose.to_i*1000,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                          xml.content(:src=>"/assessment_#{@message.id}.etx")
                        }
                      end
                      if @quiz.context.chapter_id > 0 and @quiz.context.topic_id == 0
                        xml.navPoint(:id=>@quiz.context.chapter.name,:class=>"chapter"){
                          xml.content(:src=>@quiz.context.chapter.try(:assets).last.try(:src))
                          xml.navPoint(:id=>@quiz.name+'_'+@publish.id.to_s,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:prerequiste=>@quiz.context.subject.uri,:submitTime=>@publish.timeclose.to_i*1000,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                            xml.content(:src=>"/assessment_#{@message.id}.etx")
                          }
                        }
                      end
                      if @quiz.context.chapter_id > 0 and @quiz.context.topic_id > 0
                        xml.navPoint(:id=>@quiz.context.chapter.name,:class=>"chapter"){
                          xml.content(:src=>@quiz.context.chapter.try(:assets).last.try(:src))
                          xml.navPoint(:id=>@quiz.context.topic.name,:class=>"topic"){
                            xml.content(:src=>@quiz.context.topic.try(:assets).last.try(:src))
                            xml.navPoint(:id=>@quiz.name+'_'+@publish.id.to_s,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:prerequiste=>@quiz.context.chapter.uri,:submitTime=>@publish.timeclose.to_i*1000,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                              xml.content(:src=>"/assessment_#{@message.id}.etx")
                            }
                          }

                        }
                      end
                    }
                  }
                }
              }
            }
          }
        }
      end
    end

    ncx_string =  @ncx.to_xml.to_s
    begin

      File.open(Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}/index.ncx",  "w+b", 0644) do |f|
        f.write(ncx_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
      end
      already_folders = []
      already_images = []
      Zip::ZipFile.open(Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}.zip", Zip::ZipFile::CREATE) {
          |zipfile|
        zipfile.add("assessment_#{@message.id}.etx",Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}/assessment_#{@message.id}.etx")
        zipfile.add("index.ncx",Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}/index.ncx")
        if @quiz.format_type == 1
          if File.exist?(@quiz.asset.attachment.path)
            zipfile.add(@quiz.asset.attachment_file_name,@quiz.asset.attachment.path)
          end
        end

        @quiz.questions.each do |q|
          images = images+extract_images(q.questiontext)
          images = images+extract_images(q.generalfeedback)
          options = QuestionAnswer.where("question=?",q.id)
          options.each do |o|
            images = images+extract_images(o.answer)
          end
        end
        images = images - [""]
        images.each do |x|
          logger.info "=========image==#{x}"
          n = x.split('/').last
          x = x.gsub(n,'')
          logger.info "=========image==#{x}"
           if x != ""
          if !already_folders.include? x
            #logger.debug(x)
            #logger.debug(already_folders)
            zipfile.mkdir(x)
            already_folders << x
          end
         end
        end
        images.each do |i|
        logger.info "===================iima==#{i}"
          #i = /question_images/test/image.gif
         # i = i.gsub("question_images/","")
          f = Rails.root.to_s+"/public/question_images/"+i.gsub("question_images/","")
          if File.exist?(f)
            #im = f.split('/')
            #zipfile.add('/question_images/'+im[im.count-1].to_s+'/'+im.last.to_s,f)

            if !already_images.include? i
              zipfile.add(i,f)
              already_images << i
            end
          end
        end
      }
      File.chmod(0644,Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}.zip")
      size = File.size(Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}.zip")
      #rescue Exception => e
      #  logger.info "2 BackTrace in creating assessment on-fly #{e.backtrace} "
      #  logger.info "2 Error Message in creating assessment on-fly #{e.message} "
      #end
      @assets.attachment_file_size = size
      @assets.save

    end
  end

  def create_uri(context)
    if (!@publish.extras.nil? and @publish.extras.index("homework"))
      if context.topic_id !=0
        uri = "/Curriculum/HomeWork/#{context.topic.board.name}/#{context.topic.content_year.name}/#{context.topic.subject.name}/#{context.topic.chapter.name}/#{context.topic.name}/#{@quiz.name}_#{@publish.id.to_s}"
      elsif context.chapter_id !=0# AssessmentInTopicQuiz For Chapter
        uri = "/Curriculum/HomeWork/#{context.chapter.board.name}/#{context.chapter.content_year.name}/#{context.chapter.subject.name}/#{context.chapter.name}/#{@quiz.name}_#{@publish.id.to_s}"
      elsif context.subject_id !=0# AssessmentInTopicQuiz For Subject
        uri = "/Curriculum/HomeWork/#{context.subject.board.name}/#{context.subject.content_year.name}/#{context.subject.name}/#{@quiz.name}_#{@publish.id.to_s}"
      end
    else
      if context.topic_id !=0
        uri = "/Curriculum/Assessment/#{context.topic.board.name}/#{context.topic.content_year.name}/#{@publish.get_assessment_ncx}/#{context.topic.subject.name}/#{context.topic.chapter.name}/#{context.topic.name}/#{@quiz.name}_#{@publish.id.to_s}"
      elsif context.chapter_id !=0# AssessmentInTopicQuiz For Chapter
        uri = "/Curriculum/Assessment/#{context.chapter.board.name}/#{context.chapter.content_year.name}/#{@publish.get_assessment_ncx}/#{context.chapter.subject.name}/#{context.chapter.name}/#{@quiz.name}_#{@publish.id.to_s}"
      elsif context.subject_id !=0# AssessmentInTopicQuiz For Subject
        uri = "/Curriculum/Assessment/#{context.subject.board.name}/#{context.subject.content_year.name}/#{@publish.get_assessment_ncx}/#{context.subject.name}/#{@quiz.name}_#{@publish.id.to_s}"
      end
    end
  end

  def extract_images(string)
    #q = Question.find(3829)
    #string = q.questiontext
    string = string.gsub('src="./','src="')
    string = string.gsub("src='./","src='")
    string = string.gsub('src="/','src="')
    string = string.gsub("src='/","src='")
    string = string.gsub('SRC="./','SRC="')
    string = string.gsub("SRC='./","SRC='")
    string = string.gsub("<image","<img")
    string = string.gsub("</image","</img")
    string = string.gsub("<IMG","<img")
    string = string.gsub("</IMG","</img")
    string = string.gsub("SRC","src")
    #string = string.gsub("../../../../concept_images/", "")
    #string = string.gsub("../../../../","")
    #string = string.gsub('src="','src="/question_images/')
    #string = string.gsub("src='./","src='/question_images/")
    #string = string.gsub('src="../../../../concept_images/"', "src=question_images/")
    #string = string.gsub('src="../"',"src=")
    doc = Nokogiri::HTML(string)
    img_srcs = doc.css('img').map{ |i| i['src'] } # Array of strings
    logger.info "=====================#{img_srcs}"
    #img_srcs1 = doc.css('image').map{ |i| i['src'] }
    #return img_srcs+img_srcs1
    return img_srcs
    #images = []
    #logger.debug(img_srcs)
  end




  def quiz_questions(xml,question,q)
    unless question.nil?
      @question = Question.find(question.question_id)
    else
      @question = Question.find(q)
    end
    xml.question_set(:id=>@question.id.to_s){
      xml.course(:value=>@question.course_text)
      xml.board(:value=>@question.context.board.try(:name))
      xml.class_(:value=>@question.context.content_year.try(:name))
      #xml.send(:"class",@question.context.content_year.name)
      #xml.send(:"class") {
      # xml.text 'hello'
      #}
      xml.subject(:value=>@question.context.subject.try(:name))
      if !@question.context.chapter.nil?
        xml.chapter(:value=>@question.context.chapter.try(:name))
      else
        xml.chapter(:value=>"Chapter")
      end
      xml.time(:value=>"1")
      unless question.nil?
        xml.score(:value=>question.grade.to_s)
      else
        xml.score(:value=>@question.defaultmark.to_s)
      end
      xml.comment_{
        xml.cdata @question.generalfeedback
      }
      unless question.nil?
        xml.negativescore(:value=>question.penalty.to_s)
      else
        xml.negativescore(:value=>@question.penalty.to_s)
      end
      xml.prob_skill(:value=>(@question.prob_skill) ? '1' : '0')
      xml.data_skill(:value=>(@question.data_skill) ? '1' : '0')
      xml.useofit_skill(:value=>(@question.useofit_skill) ? '1' : '0')
      xml.creativity_skill(:value=>(@question.creativity_skill) ? '1' : '0')
      xml.listening_skill(:value=>(@question.listening_skill) ? '1' : '0')
      xml.speaking_skill(:value=>(@question.speaking_skill) ? '1' : '0')
      xml.grammar_skill(:value=>(@question.grammer_skill) ? '1' : '0')
      xml.vocab_skill(:value=>(@question.vocab_skill) ? '1' : '0')
      xml.formulae_skill(:value=>(@question.formulae_skill) ? '1' : '0')
      xml.comprehension_skill(:value=>(@question.comprehension_skill) ? '1' : '0')
      xml.knowledge_skill(:value=>(@question.knowledge_skill) ? '1' : '0')
      xml.application_skill(:value=>(@question.application_skill) ? '1' : '0')
      xml.difficulty(:value=>@question.difficulty.to_s)
      if @question.qtype =="multichoice"
        xml.qtype(:value=>"MCQ")
      elsif @question.qtype =="truefalse"
        xml.qtype(:value=>"TOF")
      elsif @question.qtype == "fib"
        xml.qtype(:value=>"FIB")
      end
      xml.question{
        if @question.qtype =="multichoice" || @question.qtype =="truefalse"
          xml.question_text{
            xml.cdata @question.questiontext
          }
          @options = QuestionAnswer.where("question=?",@question.id)
          i =1
          @options.each do |o|
            tag =""
            if i==1
              tag ="A"
            end
            if i==2
              tag="B"
            end
            if i==3
              tag= "C"
            end
            if i==4
              tag="D"
            end
            if i==5
              tag="E"
            end
            xml.option(:id=>o.id.to_s,:tag=>tag,:answer=>((o.fraction==1)? "true" : "false")){
              xml.option_text{
                xml.cdata o.answer
              }
              xml.feedback{
                xml.cdata o.feedback
              }
            }
            i = i+1
          end

        elsif @question.qtype =="parajumble"

        elsif @question.qtype =="match"

        elsif @question.qtype == "fib"
          xml.question_text{
            xml.cdata @question.questiontext
          }
          @options =  @question.question_fill_blanks

          @options.each do |o|
            xml.options_fib(:ignore_case=>o.case_sensitive ? 0 :1) {
              if o.case_sensitive
                o.answer.split(',').each do |i|
                  xml.option_blank{
                    xml.text i
                  }
                end
              else
                o.answer.split(',').each do |i|
                  xml.option_blank{
                    xml.text i.upcase
                  }
                end
                o.answer.split(',').each do |i|
                  xml.option_blank{
                    xml.text i.downcase
                  }
                end
              end
            }
          end
        end
      }
    }
    # return xml
  end

  def publish_details
    @details = QuizTargetedGroup.find(params[:id])
    if @details
      @quiz = Quiz.find(@details.quiz_id)
      if (@quiz.accessible(current_user.id, current_user.institution_id))
        respond_to do |format|
          format.html
          format.json { render json: @quiz.errors, status: :unprocessable_entity }
        end
      else
        respond_to do |format|
          format.html { redirect_to action: "index" }
          format.json { render json: @quiz.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def myquizzes
    @main_heading = 'My All Assessments'
    @quizzes = Quiz.where("createdby = ? AND format_type != ? AND id IN (SELECT quiz_id FROM `quiz_targeted_groups`) ",current_user.id, 7).order('timecreated DESC').page(params[:page])

    respond_to do |format|
      format.html { render "index"}
      format.json { render json: @quizzes }
    end
  end

  def myunpublishedquizzes
    @main_heading = 'My Unpublished Assessments'
    @quizzes = Quiz.where("createdby = ? AND format_type != ? AND id NOT IN (SELECT quiz_id FROM `quiz_targeted_groups`)",current_user.id, 7).order('timecreated DESC').page(params[:page])

    respond_to do |format|
      format.html { render "index"}
      format.json { render json: @quizzes }
    end
  end

# GET /quizzes/1
# GET /quizzes/1.json
  def show
    @quiz = Quiz.includes(:questions).find(params[:id])
    if !(@quiz.accessible(current_user.id, current_user.institution_id))
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
      return
    end
    @question = @quiz.questions

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @quiz }
    end
  end

# GET /quizzes/new
# GET /quizzes/new.json
  def new
    @quiz = Quiz.new
    @action = 'create'
    #@boards = current_user.class_contents
    #@boards = current_user.institution.boards
    if current_user.is?"EA"
      @boards = Board.all
    else
      @boards = get_boards
    end
    @quiz.build_context
    @quiz.quiz_sections.build

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @quiz }
    end
  end

  def select_method
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @quiz }
    end
  end

  def submit_method
    if params[:method].present?
      method = params[:method]
      if method =="online"
        redirect_to :action=>"new"
        return
      elsif method == "doc"
        redirect_to :action => "create_from_doc"
      end
    else
      flash[:notice] = 'Please select one of the following options.'
      redirect_to :action => "select_method"
    end
  end

  def create_from_doc
    respond_to do |format|
      format.html
      format.json { render json: @quiz }
    end
  end

# GET /quizzes/1/edit
  def edit
    @action = 'update'
    @boards = get_boards
    @quiz = Quiz.find(params[:id])
    if !@quiz.edit_access(current_user.id)
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
      return
    end
  end

# POST /quizzes
# POST /quizzes.json
  def create
    params[:quiz][:createdby] = current_user.id
    params[:quiz][:modifiedby] = current_user.id
    params[:quiz][:institution_id] = current_user.id
    params[:quiz][:center_id] = current_user.id
    if !current_user.institution_id.nil?
      params[:quiz][:institution_id] = current_user.institution_id
    end
    if !current_user.center_id.nil?
      params[:quiz][:center_id] = current_user.center_id
    end
    @quiz = Quiz.new(params[:quiz])
    respond_to do |format|
      if @quiz.save
        if @quiz.format_type == 1 or @quiz.format_type == 5
          format.html { redirect_to  add_catchall_questions_path(@quiz) , notice: 'Assessment was successfully created. Add catch all questions ' }
          format.json { render json: @quiz, status: :created, location: @quiz }
        elsif @quiz.format_type == 3
          format.html { redirect_to  add_openformat_multiple_questions_path(@quiz) , notice: 'Assessment was successfully created. Add catch all questions ' }
          format.json { render json: @quiz, status: :created, location: @quiz }
        else
          format.html { redirect_to @quiz, notice: 'Assessment was successfully created.' }
          format.json { render json: @quiz, status: :created, location: @quiz }
        end
      else
        @boards = get_boards
        format.html { render action: "new" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    end
  end

  def get_boards(institution_id=nil)
    if institution_id.nil?
      if current_user.institution_id.nil?
        institution_id = EDUTOR
      else
        institution_id = current_user.institution_id
      end
    end
    if institution_id.to_i == 1
      logger.info"====#{institution_id}"
      ids = [25009,25906]
      return Board.where(:id=>ids)
    else
      return Institution.where(:id=>institution_id.to_i).first.boards
    end

  end

  def get_all_databases
    if current_user.id == 1
      d = {}
      d[1] = "Edutor"
      Institution.all.each do |i|
        d[i.id] = i.profile.firstname
      end
      return d
    end
    d = {}
    d[1] = "Edutor" unless current_user.id == 9251 or current_user.institution_id == 14289
    d[current_user.institution_id] = Institution.find(current_user.institution_id).profile.firstname
    return d
  end

  def get_my_databases
    d = {}
    if current_user.institution_id.nil?
      d[1] = "Edutor"
    else
      d[current_user.institution_id] = Institution.find(current_user.institution_id).profile.firstname
    end
    return d
  end

  def add_catchall_questions
    @quiz = Quiz.find(params[:id])
    @attachment = @quiz.build_asset
    if @quiz.format_type != 1 and @quiz.format_type != 5
      redirect_to :action =>"edit_questions",:id=>@quiz.id
      return
    end

    respond_to do |format|
      format.html {render "catchall_questions"}
      format.json { render json: @quiz }
    end
  end

  def submit_catchall_questions
    @quiz = Quiz.find(params[:id])
    if @quiz.format_type != 1
      redirect_to :action =>"edit_questions",:id=>@quiz.id
      return
    end
    if params[:asset][:attachment].present?
      @quiz_attachment = Asset.new(:attachment=>params[:asset][:attachment],:archive_type=>"Quiz",:archive_id=>@quiz.id)
      @quiz_attachment.save!
      path = @quiz_attachment.src
      @quiz.update_attribute(:questions_file,path)
    end
    if params[:questions].present?
      ActiveRecord::Base.transaction do
        params[:questions].each do |p|

          q = Question.new
          q.section = p[:section]
          q.tag = p[:tag]
          q.page_no = p[:page_no]
          q.inpage_location = p[:inpage_location]
          q.difficulty = p[:difficulty]
          q.defaultmark = p[:marks]
          q.penalty = p[:penalty].to_i
          q.file = path
          q.qtype = "multichoice" #hard coding the qtype for catch all questions
                                  #q.unset_defaults_flag
          q.save(:validate=>false)

          answers = p[:answer_tags].split(',')
          answer = p[:correct_answer].split(',')
          answers.each do |a|
            qa = QuestionAnswer.new
            qa.question = q.id
            qa.tag = a
            if answer.include? a
              qa.fraction = 1
            else
              qa.fraction = 0
            end
            qa.save(:validate=>false)
          end

          qqi = QuizQuestionInstance.new
          qqi.quiz_id = @quiz.id
          qqi.question_id = q.id
          qqi.grade = p[:marks]
          qqi.penalty = p[:penalty]
          qqi.save
        end
      end
    end

    redirect_to :action=>"show",:id=>@quiz.id
  end

#Catchall format test paper download
  def download_catchall
    @quiz =  Quiz.find(params[:id])
    send_file @quiz.asset.attachment.path,:disposition=>'inline',:type=>'application/pdf'
  end

  def add_questions
    @quiz = Quiz.find(params[:id])
    if @quiz.edit_access(current_user.id) and @quiz.quiz_targeted_groups.empty?
      if !params[:quiz_question_instances].nil? && !params[:quiz_question_instances][:question_id].nil?
        params[:quiz_question_instances][:question_id].each do |question_id|
          QuizQuestionInstance.find_or_create_by_quiz_id_and_question_id(@quiz.id,question_id,:grade=>params[:quiz_question_instances][:grade][question_id],:penalty=>params[:quiz_question_instances][:penalty][question_id],:quiz_section_id=>params[:section])
        end
      end
    else
      respond_to do |format|
        flash[:notice] =  'Questions cannot be removed'
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
      return
    end
    @context = Context.new
    values = {}
    values[:hidden] = 0
    @common_search = ""
    @filter_qtype = ""
    @filter_course = ""
    @filter_difficulty = ""
    @filter_vocab_skill = ""
    @filter_comprehension_skill = ""
    @filter_speaking_skill = ""
    @filter_listening_skill = ""
    @filter_prob_skill = ""
    @filter_data_skill = ""
    @filter_useofit_skill = ""
    @filter_creativity_skill = ""
    @filter_formulae_skill = ""
    @filter_knowledge_skill = ""
    @filter_application_skill = ""
    @filter_grammer_skill = ""
    @filter_myquestions = ""
    @filter_database = EDUTOR
    if params[:filter_database].present?
      @filter_database = params[:filter_database]
    end
    @boards = get_boards(@filter_database)
    @databases = get_all_databases
    values[:institution_id] = @filter_database
    where = "questions.institution_id = :institution_id AND questions.hidden = :hidden AND questions.id NOT IN (SELECT question_id FROM quiz_question_instances WHERE quiz_id = :quiz_id)"
    values[:quiz_id] = @quiz.id
    if params[:context].present?
      if params[:context][:content_year_id].present? && params[:context][:content_year_id] !='0'
        @context.content_year_id = params[:context][:content_year_id]
        values[:content_year_id] = params[:context][:content_year_id]
        where = where+ " AND contexts.content_year_id= :content_year_id"
      end
      if params[:context][:subject_id].present? && params[:context][:subject_id] != '0'
        @context.subject_id = params[:context][:subject_id]
        values[:subject_id] = params[:context][:subject_id]
        where = where+ " AND contexts.subject_id= :subject_id"
      end
      if params[:context][:chapter_id].present? && params[:context][:chapter_id] !='0'
        @context.chapter_id = params[:context][:chapter_id]
        values[:chapter_id] = params[:context][:chapter_id]
        where = where+ " AND contexts.chapter_id= :chapter_id"
      end

      if params[:context][:topic_id].present? && params[:context][:topic_id] !='0'
        @context.topic_id = params[:context][:topic_id]
        values[:topic_id] = params[:context][:topic_id]
        where = where+ " AND contexts.topic_id= :topic_id"
      end
      if params[:context][:board_id].present? && params[:context][:board_id] !='0'
        @context.board_id = params[:context][:board_id]
        values[:board_id] = params[:context][:board_id]
        where = where+ " AND contexts.board_id= :board_id"
      end
      if params[:common_search].present?
        @common_search = params[:common_search]
        where = where+ " AND questions.questiontext LIKE '%#{params[:common_search]}%'"
      end
      if params[:filter_qtype].present?
        @filter_qtype = params[:filter_qtype]
        where = where+ " AND questions.qtype = :qtype"
        values[:qtype] = params[:filter_qtype]
      end
      if params[:filter_course].present?
        @filter_course = params[:filter_course]
        where = where+ " AND questions.course = :course"
        values[:course] = params[:filter_course]
      end
      if params[:filter_difficulty].present?
        @filter_difficulty = params[:filter_difficulty]
        where = where+ " AND questions.difficulty = :difficulty"
        values[:difficulty] = params[:filter_difficulty]
      end
      if params[:filter_vocab_skill].present?
        @filter_vocab_skill = 1
        where = where+ " AND questions.vocab_skill = :vocab_skill"
        values[:vocab_skill] = 1
      end
      if params[:filter_comprehension_skill].present?
        @filter_comprehension_skill = 1
        where = where+ " AND questions.comprehension_skill = :comprehension_skill"
        values[:comprehension_skill] = 1
      end
      if params[:filter_speaking_skill].present?
        @filter_speaking_skill = 1
        where = where+ " AND questions.speaking_skill = :speaking_skill"
        values[:speaking_skill] = 1
      end
      if params[:filter_listening_skill].present?
        @filter_listening_skill = 1
        where = where+ " AND questions.listening_skill = :listening_skill"
        values[:listening_skill] = 1
      end
      if params[:filter_prob_skill].present?
        @filter_prob_skill = 1
        where = where+ " AND questions.prob_skill = :prob_skill"
        values[:prob_skill] = 1
      end
      if params[:filter_data_skill].present?
        @filter_data_skill = 1
        where = where+ " AND questions.data_skill = :data_skill"
        values[:data_skill] = 1
      end
      if params[:filter_useofit_skill].present?
        @filter_useofit_skill = 1
        where = where+ " AND questions.useofit_skill = :useofit_skill"
        values[:useofit_skill] = 1
      end
      if params[:filter_creativity_skill].present?
        @filter_creativity_skill = 1
        where = where+ " AND questions.creativity_skill = :creativity_skill"
        values[:creativity_skill] = 1
      end
      if params[:filter_formulae_skill].present?
        @filter_formulae_skill = 1
        where = where+ " AND questions.formulae_skill = :formulae_skill"
        values[:formulae_skill] = 1
      end
      if params[:filter_knowledge_skill].present?
        @filter_knowledge_skill = 1
        where = where+ " AND questions.knowledge_skill = :knowledge_skill"
        values[:knowledge_skill] = 1
      end
      if params[:filter_application_skill].present?
        @filter_application_skill = 1
        where = where+ " AND questions.application_skill = :application_skill"
        values[:application_skill] = 1
      end
      if params[:filter_grammer_skill].present?
        @filter_grammer_skill = 1
        where = where+ " AND questions.grammer_skill = :grammer_skill"
        values[:grammer_skill] = 1
      end
      if params[:filter_myquestions].present?
        @filter_myquestions = 1
        where = where+ " AND questions.createdby = :createdby"
        values[:createdby] = current_user.id
      end
    end
    @questions = Question.joins(:context).where(where,values).order('questions.id DESC').page(params[:page])

    respond_to do |format|
      format.html { render "create"}
      format.json { render json: @quiz, status: :added, location: @quiz }
    end
  end

  def remove_questions
    @quiz = Quiz.find(params[:id])
    @context = Context.new
    values = {}
    if @quiz.edit_access(current_user.id) and @quiz.quiz_targeted_groups.empty?
      if !params[:quiz_question_instances].nil?
        QuizQuestionInstance.delete_all(:question_id=>params[:quiz_question_instances])
      end
    else
      respond_to do |format|
        flash[:notice] =  'Questions cannot be removed'
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
      return
    end
    values[:hidden] = 0
    @common_search = ""
    @filter_qtype = ""
    @filter_course = ""
    @filter_difficulty = ""
    @filter_vocab_skill = ""
    @filter_comprehension_skill = ""
    @filter_speaking_skill = ""
    @filter_listening_skill = ""
    @filter_prob_skill = ""
    @filter_data_skill = ""
    @filter_useofit_skill = ""
    @filter_creativity_skill = ""
    @filter_formulae_skill = ""
    @filter_knowledge_skill = ""
    @filter_application_skill = ""
    @filter_grammer_skill = ""
    @filter_myquestions = ""
    @filter_database = EDUTOR
    if params[:filter_database].present?
      @filter_database = params[:filter_database]
    end
    @boards = get_boards(@filter_database)
    @databases = get_all_databases
    values[:institution_id] = @filter_database
    where = "questions.institution_id = :institution_id AND questions.hidden = :hidden AND questions.id NOT IN (SELECT question_id FROM quiz_question_instances WHERE quiz_id = :quiz_id)"
    values[:quiz_id] = @quiz.id
    if params[:context].present?
      if params[:context][:content_year_id].present? && params[:context][:content_year_id] !='0'
        @context.content_year_id = params[:context][:content_year_id]
        values[:content_year_id] = params[:context][:content_year_id]
        where = where+ " AND contexts.content_year_id= :content_year_id"
      end
      if params[:context][:subject_id].present? && params[:context][:subject_id] != '0'
        @context.subject_id = params[:context][:subject_id]
        values[:subject_id] = params[:context][:subject_id]
        where = where+ " AND contexts.subject_id= :subject_id"
      end
      if params[:context][:chapter_id].present? && params[:context][:chapter_id] !='0'
        @context.chapter_id = params[:context][:chapter_id]
        values[:chapter_id] = params[:context][:chapter_id]
        where = where+ " AND contexts.chapter_id= :chapter_id"
      end
      if params[:context][:board_id].present? && params[:context][:board_id] !='0'
        @context.board_id = params[:context][:board_id]
        values[:board_id] = params[:context][:board_id]
        where = where+ " AND contexts.board_id= :board_id"
      end
      if params[:context][:topic_id].present? && params[:context][:topic_id] !='0'
        @context.topic_id = params[:context][:topic_id]
        values[:topic_id] = params[:context][:topic_id]
        where = where+ " AND contexts.topic_id= :topic_id"
      end
      if params[:common_search].present?
        @common_search = params[:common_search]
        where = where+ " AND questions.questiontext LIKE '%#{params[:common_search]}%'"
      end
      if params[:filter_qtype].present?
        @filter_qtype = params[:filter_qtype]
        where = where+ " AND questions.qtype = :qtype"
        values[:qtype] = params[:filter_qtype]
      end
      if params[:filter_course].present?
        @filter_course = params[:filter_course]
        where = where+ " AND questions.course = :course"
        values[:course] = params[:filter_course]
      end
      if params[:filter_difficulty].present?
        @filter_difficulty = params[:filter_difficulty]
        where = where+ " AND questions.difficulty = :difficulty"
        values[:difficulty] = params[:filter_difficulty]
      end
      if params[:filter_vocab_skill].present?
        @filter_vocab_skill = 1
        where = where+ " AND questions.vocab_skill = :vocab_skill"
        values[:vocab_skill] = 1
      end
      if params[:filter_comprehension_skill].present?
        @filter_comprehension_skill = 1
        where = where+ " AND questions.comprehension_skill = :comprehension_skill"
        values[:comprehension_skill] = 1
      end
      if params[:filter_speaking_skill].present?
        @filter_speaking_skill = 1
        where = where+ " AND questions.speaking_skill = :speaking_skill"
        values[:speaking_skill] = 1
      end
      if params[:filter_listening_skill].present?
        @filter_listening_skill = 1
        where = where+ " AND questions.listening_skill = :listening_skill"
        values[:listening_skill] = 1
      end
      if params[:filter_prob_skill].present?
        @filter_prob_skill = 1
        where = where+ " AND questions.prob_skill = :prob_skill"
        values[:prob_skill] = 1
      end
      if params[:filter_data_skill].present?
        @filter_data_skill = 1
        where = where+ " AND questions.data_skill = :data_skill"
        values[:data_skill] = 1
      end
      if params[:filter_useofit_skill].present?
        @filter_useofit_skill = 1
        where = where+ " AND questions.useofit_skill = :useofit_skill"
        values[:useofit_skill] = 1
      end
      if params[:filter_creativity_skill].present?
        @filter_creativity_skill = 1
        where = where+ " AND questions.creativity_skill = :creativity_skill"
        values[:creativity_skill] = 1
      end
      if params[:filter_formulae_skill].present?
        @filter_formulae_skill = 1
        where = where+ " AND questions.formulae_skill = :formulae_skill"
        values[:formulae_skill] = 1
      end
      if params[:filter_knowledge_skill].present?
        @filter_knowledge_skill = 1
        where = where+ " AND questions.knowledge_skill = :knowledge_skill"
        values[:knowledge_skill] = 1
      end
      if params[:filter_application_skill].present?
        @filter_application_skill = 1
        where = where+ " AND questions.application_skill = :application_skill"
        values[:application_skill] = 1
      end
      if params[:filter_grammer_skill].present?
        @filter_grammer_skill = 1
        where = where+ " AND questions.grammer_skill = :grammer_skill"
        values[:grammer_skill] = 1
      end
      if params[:filter_myquestions].present?
        @filter_myquestions = 1
        where = where+ " AND questions.createdby = :createdby"
        values[:createdby] = current_user.id
      end
    end
    @questions = Question.joins(:context).where(where,values).order('questions.id DESC').page(params[:page])

    respond_to do |format|
      format.html { render "create"}
      format.json { render json: @quiz, status: :removed, location: @quiz }
    end
  end

  def edit_questions
    @quiz = Quiz.find(params[:id])
    @context = Context.new
    values = {}
    if !@quiz.edit_access(current_user.id)
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
      return
    end
    values[:hidden] = 0
    @common_search = ""
    @filter_qtype = ""
    @filter_course = ""
    @filter_difficulty = ""
    @filter_vocab_skill = ""
    @filter_comprehension_skill = ""
    @filter_speaking_skill = ""
    @filter_listening_skill = ""
    @filter_prob_skill = ""
    @filter_data_skill = ""
    @filter_useofit_skill = ""
    @filter_creativity_skill = ""
    @filter_formulae_skill = ""
    @filter_knowledge_skill = ""
    @filter_application_skill = ""
    @filter_grammer_skill = ""
    @filter_myquestions = ""
    #@filter_database = EDUTOR
    @filter_database = current_user.institution.nil? ? EDUTOR : current_user.institution.id
    if params[:filter_database].present?
      @filter_database = params[:filter_database]
    end
    @boards = get_boards(@filter_database)
    @databases = get_all_databases
    values[:institution_id] = @filter_database
    where = "questions.institution_id = :institution_id AND questions.hidden = :hidden AND questions.id NOT IN (SELECT question_id FROM quiz_question_instances WHERE quiz_id = :quiz_id)"
    values[:quiz_id] = @quiz.id
    if params[:context].present?
      if params[:context][:content_year_id].present? && params[:context][:content_year_id] !='0'
        @context.content_year_id = params[:context][:content_year_id]
        values[:content_year_id] = params[:context][:content_year_id]
        where = where+ " AND contexts.content_year_id= :content_year_id"
      end
      if params[:context][:subject_id].present? && params[:context][:subject_id] != '0'
        @context.subject_id = params[:context][:subject_id]
        values[:subject_id] = params[:context][:subject_id]
        where = where+ " AND contexts.subject_id= :subject_id"
      end
      if params[:context][:chapter_id].present? && params[:context][:chapter_id] !='0'
        @context.chapter_id = params[:context][:chapter_id]
        values[:chapter_id] = params[:context][:chapter_id]
        where = where+ " AND contexts.chapter_id= :chapter_id"
      end
      if params[:context][:board_id].present? && params[:context][:board_id] !='0'
        @context.board_id = params[:context][:board_id]
        values[:board_id] = params[:context][:board_id]
        where = where+ " AND contexts.board_id= :board_id"
      end
      if params[:context][:topic_id].present? && params[:context][:topic_id] !='0'
        @context.topic_id = params[:context][:topic_id]
        values[:topic_id] = params[:context][:topic_id]
        where = where+ " AND contexts.topic_id= :topic_id"
      end
      if params[:common_search].present?
        @common_search = params[:common_search]
        where = where+ " AND questions.questiontext LIKE '%#{params[:common_search]}%'"
      end
      if params[:filter_qtype].present?
        @filter_qtype = params[:filter_qtype]
        where = where+ " AND questions.qtype = :qtype"
        values[:qtype] = params[:filter_qtype]
      end
      if params[:filter_course].present?
        @filter_course = params[:filter_course]
        where = where+ " AND questions.course = :course"
        values[:course] = params[:filter_course]
      end
      if params[:filter_difficulty].present?
        @filter_difficulty = params[:filter_difficulty]
        where = where+ " AND questions.difficulty = :difficulty"
        values[:difficulty] = params[:filter_difficulty]
      end
      if params[:filter_vocab_skill].present?
        @filter_vocab_skill = 1
        where = where+ " AND questions.vocab_skill = :vocab_skill"
        values[:vocab_skill] = 1
      end
      if params[:filter_comprehension_skill].present?
        @filter_comprehension_skill = 1
        where = where+ " AND questions.comprehension_skill = :comprehension_skill"
        values[:comprehension_skill] = 1
      end
      if params[:filter_speaking_skill].present?
        @filter_speaking_skill = 1
        where = where+ " AND questions.speaking_skill = :speaking_skill"
        values[:speaking_skill] = 1
      end
      if params[:filter_listening_skill].present?
        @filter_listening_skill = 1
        where = where+ " AND questions.listening_skill = :listening_skill"
        values[:listening_skill] = 1
      end
      if params[:filter_prob_skill].present?
        @filter_prob_skill = 1
        where = where+ " AND questions.prob_skill = :prob_skill"
        values[:prob_skill] = 1
      end
      if params[:filter_data_skill].present?
        @filter_data_skill = 1
        where = where+ " AND questions.data_skill = :data_skill"
        values[:data_skill] = 1
      end
      if params[:filter_useofit_skill].present?
        @filter_useofit_skill = 1
        where = where+ " AND questions.useofit_skill = :useofit_skill"
        values[:useofit_skill] = 1
      end
      if params[:filter_creativity_skill].present?
        @filter_creativity_skill = 1
        where = where+ " AND questions.creativity_skill = :creativity_skill"
        values[:creativity_skill] = 1
      end
      if params[:filter_formulae_skill].present?
        @filter_formulae_skill = 1
        where = where+ " AND questions.formulae_skill = :formulae_skill"
        values[:formulae_skill] = 1
      end
      if params[:filter_knowledge_skill].present?
        @filter_knowledge_skill = 1
        where = where+ " AND questions.knowledge_skill = :knowledge_skill"
        values[:knowledge_skill] = 1
      end
      if params[:filter_application_skill].present?
        @filter_application_skill = 1
        where = where+ " AND questions.application_skill = :application_skill"
        values[:application_skill] = 1
      end
      if params[:filter_grammer_skill].present?
        @filter_grammer_skill = 1
        where = where+ " AND questions.grammer_skill = :grammer_skill"
        values[:grammer_skill] = 1
      end
      if params[:filter_myquestions].present?
        @filter_myquestions = 1
        where = where+ " AND questions.createdby = :createdby"
        values[:createdby] = current_user.id
      end
    end
    @questions = Question.joins(:context).where(where,values).order('questions.id DESC').page(params[:page])

    respond_to do |format|
      format.html { render "create"}
      format.json { render json: @quiz, status: :created, location: @quiz }
    end
  end

  def update_question_instance
    if params[:quiz][:quiz_question_instances_attributes].present?
      ActiveRecord::Base.transaction do
        params[:quiz][:quiz_question_instances_attributes].each do |instance|
          instance = instance[1]
          @instance = QuizQuestionInstance.find(instance[:id])
          if @instance
            logger.info"=======================1"
            @quiz = Quiz.find(@instance.quiz_id)
            if @quiz.edit_access(current_user.id)
              logger.info"=======================2"
              @instance.update_attributes(:grade=>instance[:grade],:penalty=>instance[:penalty])
              if @quiz.format_type != 0
                logger.info"=======================3"
                question = Question.find(@instance.question_id)
                question.section=instance[:section]
                question.tag=instance[:tag]
                question.difficulty=instance[:difficulty]
                question.page_no=instance[:page_no]
                question.inpage_location=instance[:inpage_location]
                question.penalty=instance[:penalty]
                question.defaultmark=instance[:grade]
                question.save(:validate=>false)
                answers = instance[:options].split(",")
                answer = instance[:answer]
                question.question_answers.delete_all
                answers.each do |a|
                  qa = QuestionAnswer.new
                  qa.question = question.id
                  qa.tag = a
                  if answer.include? a
                    qa.fraction = 1
                  else
                    qa.fraction = 0
                  end
                  qa.save(:validate=>false)
                end

              end

            else
              respond_to do |format|
                format.html { redirect_to action: "index" }
                format.json { render json: @quiz.errors, status: :unprocessable_entity }
              end
            end
          end
        end
      end
    end
    respond_to do |format|
      format.html { redirect_to @quiz, notice: 'Question Marks/Penalty was successfully updated.' }
      format.json { head :ok }
    end
  end

  def copy
    @old_quiz = Quiz.find(params[:id])
    if @old_quiz.format_type==1
      @asset_id = @old_quiz.asset.id
    end
    if !(@old_quiz.accessible(current_user.id, current_user.institution_id))
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
      return
    end
    @quiz = @old_quiz.dup
    @boards = get_boards
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @quiz }
    end
  end

  def copysave
    if !params[:quiz].nil?
      params[:quiz][:createdby] = current_user.id
      params[:quiz][:modifiedby] = current_user.id
      params[:quiz][:institution_id] = current_user.id
      params[:quiz][:center_id] = current_user.id
      if !current_user.institution_id.nil?
        params[:quiz][:institution_id] = current_user.institution_id
      end
      if !current_user.center_id.nil?
        params[:quiz][:center_id] = current_user.center_id
      end
      params[:quiz][:context_attributes].delete(:id)
      @quiz = Quiz.new(params[:quiz])
      respond_to do |format|
        if @quiz.save
          @old_quiz = Quiz.find(params[:old_quiz_id])
          if @old_quiz.quiz_sections.empty?
            sql = "INSERT INTO `quiz_question_instances` (`quiz_id`,`question_id`,`grade`,`penalty`) SELECT #{@quiz.id},question_id,grade,penalty FROM `quiz_question_instances` WHERE quiz_id=#{params[:old_quiz_id]}"
            ActiveRecord::Base.connection.execute(sql)
          else
            @old_quiz.quiz_sections.each do |section|
              @section = QuizSection.create(:name=>section.name,:quiz_id=>@quiz.id)
              section_sql = "INSERT INTO `quiz_question_instances` (`quiz_id`,`question_id`,`grade`,`penalty`,`quiz_section_id`) SELECT #{@quiz.id},question_id,grade,penalty,#{@section.id} FROM `quiz_question_instances` WHERE quiz_id=#{params[:old_quiz_id]} and quiz_section_id=#{section.id}"
              ActiveRecord::Base.connection.execute(section_sql)
            end
          end
          if params[:asset_id].present?
            old_asset = Asset.find(params[:asset_id])
            new_asset = old_asset.dup
            new_asset.archive_id = @quiz.id
            new_asset.save
          end

          format.html { redirect_to @quiz, notice: 'Quiz was successfully copied.' }
          format.json { render json: @quiz, status: :created, location: @quiz }
        else
          @old_quiz = Quiz.find(params[:old_quiz_id])
          @boards = get_boards
          if params[:asset_id].present?
            @asset_id = params[:asset_id]
          end
          #@question.build_context
          format.html { render "copy" }
          format.json { render json: @quiz.errors, status: :unprocessable_entity }
        end
      end
    end
  end



# PUT /quizzes/1
# PUT /quizzes/1.json
  def update
    @quiz = Quiz.find(params[:id])
    if !@quiz.edit_access(current_user.id)
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    end
    respond_to do |format|
      if @quiz.update_attributes(params[:quiz])
        format.html { redirect_to @quiz, notice: 'Assessment was successfully updated.' }
        format.json { head :ok }
      else
        @boards = get_boards
        format.html { render action: "edit" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    end
  end

# DELETE /quizzes/1
# DELETE /quizzes/1.json
  def destroy
    @quiz = Quiz.find(params[:id])
    if !@quiz.edit_access(current_user.id)
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    end
    @quiz.destroy

    respond_to do |format|
      format.html { redirect_to quizzes_url }
      format.json { head :ok }
    end
  end

  def get_teacher_quiz
    string = request.body.read
    results =  ActiveSupport::JSON.decode(string)
    result = results.first
    logger.debug(result.to_s)
    @uresponse = {}
    @uresponse['success'] = false
    if !result['file'].present? || !result['device_id'].present? || !result['password'].present?
      logger.info(@uresponse)
      render json: @uresponse
      return
    end
    file = result['file']
    key = "dwefefeklnkv"
    hash = Digest::MD5.hexdigest(result['device_id']+key)
    if result['password'] != hash
      logger.debug("Hash is --------:"+hash)
      @uresponse['message'] = "Authentication failure"
      logger.info(@uresponse)
      render json: @uresponse
      return
    end
    identifier = Digest::MD5.hexdigest(result['device_id']+key+Time.now.to_i.to_s)
    tmp_filename = Rails.root.to_s+"/public/teacher_tests/"+identifier.to_s+"/#{Time.now.to_i}.etx"
    FileUtils.mkdir_p Rails.root.to_s+"/public/teacher_tests/"+identifier.to_s
    File.open(tmp_filename,  "w+b", 0644) do |f|
      #f.write(file.read)
      f.write(file)
    end

    teacher_file = TeacherTest.new
    teacher_file.identifier = identifier
    teacher_file.filename = tmp_filename
    teacher_file.file = file
    teacher_file.save

    @uresponse['success'] = true
    @uresponse['identifier'] = identifier
    render json: @uresponse
  end

  def get_teacher_feedback
    string = '[{"teacherid":"E0103122040955","pwd":"98f0c7af0658101d04fd9ee53b45fe55","activity_name":"",
"student_info":[
        {"edutor_id": "dwsdef4566","message":"skills text"},
        {"edutor_id": "dwsdef4566","message":"skills text"}
    ]}]'

    string = request.body.read
    results =  ActiveSupport::JSON.decode(string)
    result = results.first
    logger.debug(result.to_s)
    @uresponse = {}
    @uresponse['success'] = false
    if !result['teacherid'].present? || !result['pwd'].present? || !result['student_info'].present?
      @uresponse['message'] = "Wrong format"
      logger.info(@uresponse)
      render json: @uresponse
      return
    end
    student_info = result['student_info']
    key = "dwefefeklnkv"
    hash = Digest::MD5.hexdigest(result['teacherid']+key)
    if result['pwd'] != hash
      logger.debug("Hash is --------:"+hash)
      @uresponse['message'] = "Authentication failure"
      logger.info(@uresponse)
      render json: @uresponse
      return
    end
    #user = User.where(:edutorid=>result['teacherid']).first
    user = User.where(:edutorid=>'EA-001').first

    if user.nil?
      @uresponse['message'] = "Invalid sender"
      logger.info(@uresponse)
      render json: @uresponse
      return
    end

    student_info.each do |s|
      recipient = User.where(:edutorid=>s['edutor_id']).first
      if !recipient.nil?
        @message = Message.new
        @message.sender_id = user.id
        @message.recipient_id = recipient.id
        subject = "Grades for #{s['activity_name']}"
        @message.subject = subject
        @message.body = s['message']
        #@message.body = @publish.body
        @message.message_type = "Message"
        @message.severity = 1
        @message.label = subject
        @message.save
      else
        logger.info("Recipient #{s['edutor_id']} does not exist.")
      end
    end

    @uresponse['success'] = true
    @uresponse['message'] = 'Messages sent successfully'
    render json: @uresponse
  end


  def rubric_publish
    string = request.body.read
    result =  ActiveSupport::JSON.decode(string)
    result = result.first
    board_ids =  User.find_by_edutorid(result['adminid']).institution.boards.map(&:id)
    logger.info "======================#{result['_subject']}"
    subject_ids = Subject.where(:board_id=>board_ids).where("name like?","%#{result['_subject']}%").map(&:id)
    logger.info"===============#{subject_ids}"
    class_rooms = ClassRoom.where(:content_id=>subject_ids)
    logger.info"================#{class_rooms.map(&:teacher_id)}"
    class_rooms.each do |c|
      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.rubric{
          xml.activity(:name=>result['activity_name'])
          result['skill_list'].each do |s|
            xml.skill(:value=>s['value'],:name=>s['name'],:grades=>s['grade'])
          end
          User.find(c.group_id).students.each do |u|
            xml.student(:device_id=>u.edutorid,:name=>u.name,:grade=>'')
          end
        }
      end
      file =  File.new(Rails.root.to_s+"/tmp/cache/rubric_#{Time.now.to_i}.erx", "w+")
      xml_string = @builder.to_xml.to_s
      File.open(file,  "w+b", 0644) do |f|
        f.write(xml_string.to_s)
      end
      @message = Message.new
      @message.message_type = 'Rubric'
      @message.subject = result['activity_name']
      @message.body = "Rubric update"
      @asset = @message.assets.build
      @asset.attachment = File.open(file)
      @message.recipient_id = c.teacher_id
      @message.sender_id = 1
      @message.save
    end
  end



  def create_test
    if !params[:identifier].present?
      logger.debug("No identifier received in the request")
      redirect_to quizzes_path
    end
    identifier = params[:identifier]
    teacher_file = TeacherTest.where(:identifier=>identifier).first
    if !teacher_file
      logger.debug("No identifier in db found")
      redirect_to quizzes_path
      return
    end
    tmp_filename = teacher_file.filename
    begin
      @doc = Nokogiri::XML(File.open(tmp_filename))
      @testpaper = @doc.xpath("//testpaper")
      guidelines = @testpaper.xpath("guidelines").attr("value").to_s
      requisites = @testpaper.xpath("requisites").attr("value").to_s
      time = @testpaper.xpath("time").attr("value").to_s
      difficulty = @testpaper.xpath("level").attr("value").to_s
      subject = @testpaper.xpath("testsubject").attr("value").to_s.to_i
      content_year = @testpaper.xpath("testclass").attr("value").to_s.to_i

      #con = Context.first
      #con = Context.new
      board = 8015
      ActiveRecord::Base.transaction do
        @quiz = Quiz.new
        @quiz.createdby = current_user.id
        @quiz.modifiedby = current_user.id
        @quiz.institution_id = current_user.institution_id
        @quiz.center_id = current_user.center_id
        @quiz.name = @testpaper.attr("name").to_s
        @quiz.intro = guidelines
        if guidelines.blank?
          @quiz.intro = "Please take this test"
        end
        @quiz.difficulty = difficulty.to_i
        @quiz.timeopen = 0
        @quiz.timeclose = 0
        @quiz.timelimit = time
        if time.to_i < 0
          @quiz.timelimit = 0
        end

        con = Context.new
        con.subject_id = subject
        con.content_year_id = content_year
        con.board_id = 8015
        con.save
        @quiz.context_id = con.id

        if @quiz.save
          #qut = QuizTemp.new
          #qut.quiz_id = @quiz.id
          #qut.requisites = requisites
          #qut.save

          @testpaper.xpath("//question_set").each do |q|
            author = q.attr("author").to_s
            if author == "edutor"
              question_id = q.attr("id").to_s.to_i
              qqi = QuizQuestionInstance.new
              qqi.quiz_id = @quiz.id
              qqi.question_id = question_id
              if q.xpath("score") && q.xpath("score").attr("value")
                qqi.grade = q.xpath("score").attr("value").to_s.to_i
              else
                qqi.grade = 0
              end
              if q.xpath("negativescore") && q.xpath("negativescore").attr("value")
                qqi.penalty = q.xpath("negativescore").attr("value").to_s.to_i
              else
                qqi.penalty = 0
              end
              if !qqi.save
                logger.debug(qqi.errors.messages)
              end
            else
              question = Question.new
              question.createdby = current_user.id
              question.institution_id = current_user.institution_id
              question.center_id = current_user.center_id
              question.name = ""
              question.questiontext = clean(q.xpath("question").xpath("question_text").inner_text)
              if !q.xpath("question").xpath("question_text").empty?
                q.xpath("question").xpath("question_text").first.content = question.questiontext
              else
                question.questiontext = "Attempt it"
              end
              question.generalfeedback = clean(q.xpath("question").xpath("comment").inner_text)
              if !q.xpath("question").xpath("comment").empty?
                q.xpath("question").xpath("comment").first.content = question.generalfeedback
              end
              if q.xpath("qtype").attr("value").to_s =="MCQ"
                question.qtype = "multichoice"
              elsif q.xpath("qtype").attr("value").to_s == "MTF"
                question.qtype = "match"
              elsif q.xpath("qtype").attr("value").to_s == "TOF"
                question.qtype = "truefalse"
              elsif q.xpath("qtype").attr("value").to_s == "SS"
                question.qtype = "parajumble"
              end
              question.defaultmark = q.xpath("score").attr("value").to_s
              question.penalty = q.xpath("negativescore").attr("value").to_s
              if !q.xpath("difficulty").empty?
                question.difficulty = q.xpath("difficulty").attr("value").to_s.to_i
              else
                question.difficulty = 1
              end
              question.prob_skill = q.xpath("prob_skill").attr("value").to_s
              question.data_skill = q.xpath("data_skill").attr("value").to_s
              question.useofit_skill = q.xpath("useofit_skill").attr("value").to_s
              question.creativity_skill = q.xpath("creativity_skill").attr("value").to_s
              question.listening_skill = q.xpath("listening_skill").attr("value").to_s
              question.speaking_skill = q.xpath("speaking_skill").attr("value").to_s
              question.grammer_skill = q.xpath("grammar_skill").attr("value").to_s
              question.vocab_skill = q.xpath("vocab_skill").attr("value").to_s
              question.formulae_skill = q.xpath("formulae_skill").attr("value").to_s
              question.comprehension_skill = q.xpath("comprehension_skill").attr("value").to_s
              question.knowledge_skill = q.xpath("knowledge_skill").attr("value").to_s
              question.application_skill = q.xpath("application_skill").attr("value").to_s
              question.context_id = con.id

              #options_count = q.xpath("question//option").size

              if !question.save(:validate=>false)
                logger.debug(question.errors.messages)
              end

              if question.qtype == "multichoice" || question.qtype=="truefalse"
                z = q.xpath("question//option")
                q.xpath("question//option").each do |o|
                  #question.question_answers.build

                  answer = o.xpath("option_text").inner_text
                  feedback = o.xpath("feedback").inner_text

                  #question.question_answers.first.answer = o.xpath("option_text").inner_text
                  #question.question_answers[z.index(o)].answer = "erreer"
                  logger.debug(o.xpath("option_text").inner_text+"jjjjjjjjjjjjjjjj")
                  #question.question_answers[z.index(o)].feedback = o.xpath("feedback").inner_text
                  if o.attr("answer").to_s.eql?"true"
                    #question.question_answers[z.index(o)].fraction = 1
                    fraction = 1
                    logger.debug("yesssssssssssssssss")
                  else
                    logger.debug("noooooooooooooooo")
                    #question.question_answers[z.index(o)].fraction = 0
                    fraction = 0
                  end

                  question.question_answers.create(answer: answer,feedback: feedback,fraction: fraction)
                end
              end

              qqi = QuizQuestionInstance.new
              qqi.quiz_id = @quiz.id
              qqi.question_id = question.id
              qqi.grade = question.defaultmark
              qqi.penalty = question.penalty
              if !qqi.save
                logger.debug(qqi.errors.messages)
              end
            end
          end
          redirect_to :action=>"publish_to",:id=>@quiz.id
          return
        else
          logger.debug(@quiz.errors.messages)
          redirect_to quizzes_path
          return
        end
      end
    rescue Exception => e
      logger.info "Exception in accepting assessment from teacher tab () #{e} "
      logger.info "BackTrace in creating assessment on-fly #{e.backtrace} "
      logger.info "Error Message in creating assessment on-fly #{e.message} "
      flash[:error] = "Some error occured, please try again"
      redirect_to quizzes_path
    end
  end

  def import
    z=1
    Dir.glob('/home/praveen/Desktop/output_etx/**/*.etx').each do |etx_file|
      #begin
      #ActiveRecord::Base.transaction do
      test = TestImportLog.where("name = ?",etx_file)
      if test.exists?
        next
      end
      a = etx_file
      l = a.length
      filename = a[0,l-5]

      basename = File.basename(etx_file)
      if basename.scan("DAD").present?
        next
      end
      b = basename
      lb = b.length
      basename1 = b[0,lb-4]
      @doc = Nokogiri::XML(File.open(etx_file))
      #@doc = Nokogiri::XML(File.open("/home/praveen/Desktop/cb_6_Science_12_1.xml"))

      File.open("/home/praveen/Desktop/newetx/status", "a+", 0644) {|f| f.write "processing..."+etx_file+"\n"}
      @testpaper = @doc.xpath("//testpaper")
      guidelines = @testpaper.xpath("guidelines").attr("value").to_s
      requisites = @testpaper.xpath("requisites").attr("value").to_s
      time = @testpaper.xpath("time").attr("value").to_s
      difficulty = @testpaper.xpath("level").attr("value").to_s

      start_time_node = Nokogiri::XML::Node.new('start_time',@doc)
      @testpaper.children.first.add_previous_sibling(start_time_node)
      start_time_node.set_attribute("value","0")

      end_time_node = Nokogiri::XML::Node.new('end_time',@doc)
      @testpaper.children.first.add_previous_sibling(end_time_node)
      end_time_node.set_attribute("value","0")

      shufflequestions_node = Nokogiri::XML::Node.new('shufflequestions',@doc)
      @testpaper.children.first.add_previous_sibling(shufflequestions_node)
      shufflequestions_node.set_attribute("value","0")

      shuffleoptions_node = Nokogiri::XML::Node.new('shuffleoptions',@doc)
      @testpaper.children.first.add_previous_sibling(shuffleoptions_node)
      shuffleoptions_node.set_attribute("value","0")

      pause_node = Nokogiri::XML::Node.new('pause',@doc)
      @testpaper.children.first.add_previous_sibling(pause_node)
      pause_node.set_attribute("value","0")

      show_score_after_node = Nokogiri::XML::Node.new('show_score_after',@doc)
      @testpaper.children.first.add_previous_sibling(show_score_after_node)
      show_score_after_node.set_attribute("value","0")

      show_solutions_after_node = Nokogiri::XML::Node.new('show_solutions_after',@doc)
      @testpaper.children.first.add_previous_sibling(show_solutions_after_node)
      show_solutions_after_node.set_attribute("value","0")


      @quiz = Quiz.new
      @quiz.createdby = 1
      @quiz.modifiedby = 1
      @quiz.institution_id = 1
      @quiz.center_id =1
      @quiz.name = basename1
      @quiz.intro = guidelines
      @quiz.difficulty = difficulty.to_i
      @quiz.timeopen = 0
      @quiz.timeclose = 0
      @quiz.timelimit = time

      #@context = @quiz.context
      #@context.board_id = 0
      #@context.subject_id = 0
      #@context.content_year_id = 0
      if @quiz.save
        qut = QuizTemp.new
        qut.quiz_id = @quiz.id
        qut.requisites = requisites
        qut.save

        @testpaper.first.set_attribute('id', @quiz.id.to_s)
        @testpaper.first.set_attribute('version',"2")
        @testpaper.xpath("//question_set").each do |q|
          question = Question.new
          question.createdby = 1
          question.institution_id = 1
          question.center_id = 1
          question.name = ""
          question.questiontext = clean(q.xpath("question").xpath("question_text").inner_text)
          if !q.xpath("question").xpath("question_text").empty?
            q.xpath("question").xpath("question_text").first.content = question.questiontext
          else
            question.questiontext = "Attempt it"
          end
          question.generalfeedback = clean(q.xpath("question").xpath("comment").inner_text)
          if !q.xpath("question").xpath("comment").empty?
            q.xpath("question").xpath("comment").first.content = question.generalfeedback
          end
          if q.xpath("qtype").attr("value").to_s =="MCQ"
            question.qtype = "multichoice"
          elsif q.xpath("qtype").attr("value").to_s == "MTF"
            question.qtype = "match"
          elsif q.xpath("qtype").attr("value").to_s == "TOF"
            question.qtype = "truefalse"
          elsif q.xpath("qtype").attr("value").to_s == "SS"
            question.qtype = "parajumble"
          end
          question.defaultmark = q.xpath("score").attr("value").to_s
          question.penalty = q.xpath("negativescore").attr("value").to_s
          if !q.xpath("difficulty").empty?
            question.difficulty = q.xpath("difficulty").attr("value").to_s.to_i
          else
            question.difficulty = 1
          end
          question.prob_skill = q.xpath("prob_skill").attr("value").to_s
          question.data_skill = q.xpath("data_skill").attr("value").to_s
          question.useofit_skill = q.xpath("useofit_skill").attr("value").to_s
          question.creativity_skill = q.xpath("creativity_skill").attr("value").to_s
          question.listening_skill = q.xpath("listening_skill").attr("value").to_s
          question.speaking_skill = q.xpath("speaking_skill").attr("value").to_s
          question.grammer_skill = q.xpath("grammar_skill").attr("value").to_s
          question.vocab_skill = q.xpath("vocab_skill").attr("value").to_s
          question.formulae_skill = q.xpath("formulae_skill").attr("value").to_s
          question.comprehension_skill = q.xpath("comprehension_skill").attr("value").to_s
          question.knowledge_skill = q.xpath("knowledge_skill").attr("value").to_s
          question.application_skill = q.xpath("application_skill").attr("value").to_s
          question.save

          context = ContextTemp.new
          context.question_id = question.id
          context.board = q.xpath("board").attr("value").to_s
          context.content_year = q.xpath("class").attr("value").to_s
          context.subject = q.xpath("subject").attr("value").to_s
          if !q.xpath("chapter").empty?
            context.chapter = q.xpath("chapter").attr("value").to_s
          end
          context.course = q.xpath("course").attr("value").to_s
          context.time = q.xpath("time").attr("value").to_s
          context.save

          q.set_attribute('id', question.id.to_s)
          i = 1
          if question.qtype == "multichoice" || question.qtype=="truefalse"
            q.xpath("question//option").each do |o|

              qa = QuestionAnswer.new
              qa.question = question.id
              qa.answer = clean(o.xpath("option_text").inner_text)
              o.xpath("option_text").first.content = qa.answer
              qa.feedback = clean(o.xpath("feedback").inner_text)
              if !o.xpath("feedback").empty?
                o.xpath("feedback").first.content = qa.feedback
              end
              if i==1
                o.set_attribute("tag","A")
              end
              if i==2
                o.set_attribute("tag","B")
              end
              if i==3
                o.set_attribute("tag","C")
              end
              if i==4
                o.set_attribute("tag","D")
              end
              if q.xpath("question//answer").first.attr("value").to_s == "A"
                if i==1
                  qa.fraction = 1
                  o.set_attribute("answer","true")
                else
                  qa.fraction = 0
                  o.set_attribute("answer","false")
                end
              end
              if q.xpath("question//answer").first.attr("value").to_s == "B"
                if i==2
                  qa.fraction = 1
                  o.set_attribute("answer","true")
                else
                  qa.fraction = 0
                  o.set_attribute("answer","false")
                end
              end
              if q.xpath("question//answer").first.attr("value").to_s == "C"
                if i==3
                  qa.fraction = 1
                  o.set_attribute("answer","true")
                else
                  qa.fraction = 0
                  o.set_attribute("answer","false")
                end
              end
              if q.xpath("question//answer").first.attr("value").to_s == "D"
                if i==4
                  qa.fraction = 1
                  o.set_attribute("answer","true")
                else
                  qa.fraction = 0
                  o.set_attribute("answer","false")
                end
              end
              i = i +1
              qa.save
              o.set_attribute("id",qa.id.to_s)
            end
          elsif question.qtype=="match"
            q.xpath("question//mtf_pair").each do |o|
              qm = QuestionMatchSub.new
              qm.question = question.id
              qm.questiontext = clean(o.xpath("lhs").inner_text)
              o.xpath("lhs").first.content = qm.questiontext
              qm.answertext = clean(o.xpath("rhs").inner_text)
              o.xpath("rhs").first.content = qm.answertext
              qm.save
              o.set_attribute("id",qm.id.to_s)
            end
          elsif question.qtype =="parajumble"
            q.xpath("question//step").each do |o|
              qp = QuestionParajumble.new
              qp.question = question.id
              qp.questiontext = clean(o.inner_text)
              o.content = qp.questiontext
              if o.attr("order").to_s == "1"
                qp.order = 1
              elsif o.attr("order").to_s == "2"
                qp.order = 2
              elsif o.attr("order").to_s == "3"
                qp.order = 3
              elsif o.attr("order").to_s == "4"
                qp.order = 4
              elsif o.attr("order").to_s == "5"
                qp.order = 5
              elsif o.attr("order").to_s == "6"
                qp.order = 6
              elsif o.attr("order").to_s == "7"
                qp.order = 7
              elsif o.attr("order").to_s == "8"
                qp.order = 8
              elsif o.attr("order").to_s == "9"
                qp.order = 9
              elsif o.attr("order").to_s == "10"
                qp.order = 10
              end
              qp.save
              o.set_attribute("id",qp.id.to_s)
            end
          end

          qqi = QuizQuestionInstance.new
          qqi.quiz_id = @quiz.id
          qqi.question_id = question.id
          qqi.grade = question.defaultmark
          qqi.penalty = question.penalty
          qqi.save

        end
      else
        #logger.debug(@quiz.errors.messages)
      end
      #end
      z = z+1
      #rescue
      #end
      File.open(etx_file, "w+b") {|f| f.write @doc}
      test = TestImportLog.new
      test.name=etx_file
      test.save
      #File.open("/home/praveen/Desktop/newetx/6th/"+basename, "w+b") {|f| f.write @doc}
    end
  end

  def clean(text)
    text.gsub!('<p class="MsoNormal">','')
    text.gsub!('<notp>','')
    text.gsub!('<notp class="MsoNormal">','')
    return text
  end

  def export
    Question.all.each do |q|
      if q.qtype != 'multichoice'
        next
      end

    end

  end

  def export_institute_test_results
    quiz_ids = params[:quiz_id]
    all_attempts = []
    quiz_ids.each do |q|
      QuizTargetedGroup.where(:quiz_id=>q.to_i).each do |qt|
        #published_to = User.find(qt.group_id).profile.firstname
        #center = User.find(qt.group_id).try(:center).try(:name)
        mode = 1
        subq = ' FROM quiz_attempts qa '
        if mode.to_i==1
          subq = " FROM (SELECT user_id,min(timefinish) AS timefinish FROM quiz_attempts WHERE publish_id=#{qt.id} group by user_id) qa1 INNER JOIN quiz_attempts qa ON qa1.user_id=qa.user_id AND qa.timefinish=qa1.timefinish "
        elsif mode.to_i ==2
          subq = " FROM (SELECT user_id,max(timefinish) AS timefinish FROM quiz_attempts WHERE publish_id=#{qt.id} group by user_id) qa1 INNER JOIN quiz_attempts qa ON qa1.user_id=qa.user_id AND qa.timefinish=qa1.timefinish "
        end
        sql = "SELECT u.id as id1,u.section_id as section_id,u.academic_class_id,u.center_id as center_id,u.edutorid AS edutorid,p.firstname AS name,q.tag as tag, qqa.marks AS marks ,qa.timefinish AS time #{subq} INNER JOIN profiles p on qa.user_id=p.user_id INNER JOIN users u on u.id=qa.user_id inner join quiz_question_attempts qqa on qqa.quiz_attempt_id=qa.id INNER JOIN questions q on q.id = qqa.question_id WHERE qa.publish_id=#{qt.id}"

        attempts = QuizAttempt.find_by_sql(sql)
        attempts.each do |a|
          center = Profile.where(:user_id=>a.center_id).first.firstname
          cl = Profile.where(:user_id=>a.academic_class_id).first.firstname
          section = Profile.where(:user_id=>a.section_id).first.firstname
          all_attempts << [center,cl,section,a.edutorid,a.name,a.tag,a.marks,Time.at(a.time).to_datetime.strftime("%d-%b-%Y %I:%M %p")]
        end
      end
    end
    csv_data = FasterCSV.generate do |csv|
      csv << "Center,Class,Section,Edutorid,Student Name,Question,Marks,Submit Time".split(",")
      all_attempts.each do |c|
        csv << c
      end
    end
    file_name =  ("#{Time.now.to_i}.csv").gsub(" ","").to_s
    logger.info "=-========================filename:#{file_name}"
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"

  end

  def show_institute_tests
    @quizzes = Quiz.where("quizzes.institution_id= ? AND format_type != ? ",current_user.institution_id, 7).order("id DESC")
  end

  def export_student_results
    publish_id = params[:id]
    @details = QuizTargetedGroup.find(params[:id])
    if @details.to_group
      published_to = User.find(@details.group_id).profile.firstname
    else
      published_to = User.find(@details.recipient_id).profile.firstname
    end
    @quiz = Quiz.find(@details.quiz_id)
    assessment_name = @quiz.name #Quiz.find(@details.quiz_id).name
    if params[:export_type] == "Export as CSV"
      mode = params[:mode]
      subq = ' FROM quiz_attempts qa '
      if mode.to_i==1
        subq = " FROM (SELECT user_id,min(timefinish) AS timefinish FROM quiz_attempts WHERE publish_id=#{publish_id} group by user_id) qa1 INNER JOIN quiz_attempts qa ON qa1.user_id=qa.user_id AND qa.timefinish=qa1.timefinish "
      elsif mode.to_i ==2
        subq = " FROM (SELECT user_id,max(timefinish) AS timefinish FROM quiz_attempts WHERE publish_id=#{publish_id} group by user_id) qa1 INNER JOIN quiz_attempts qa ON qa1.user_id=qa.user_id AND qa.timefinish=qa1.timefinish "
      end
      sql = "SELECT u.id,u.edutorid AS edutorid,CONCAT(p.firstname,' ',p.surname) AS name,qa.sumgrades AS marks ,qa.timefinish AS time #{subq} INNER JOIN profiles p on qa.user_id=p.user_id INNER JOIN users u on u.id=qa.user_id WHERE publish_id=#{publish_id}"
      attempts = QuizAttempt.find_by_sql(sql)
      logger.info"=======#{attempts.map(&:id)}"
      logger.debug(attempts.size)
      all_attempts = []
      attempts.each do |a|
        user = User.find(a.id)
        all_attempts << [a.edutorid,user.school_uid,user.name,(user.academic_class.name rescue ""),(user.section.name rescue ""),a.marks,Time.at(a.time).to_datetime.strftime("%d-%b-%Y %I:%M %p")]
      end
      csv_data = FasterCSV.generate do |csv|
        csv << ['Institution:',User.find(@quiz.institution_id).name]
        #csv << ['Center:',User.find(@quiz.center_id).name]
        csv << ['Assessment Name:',@quiz.name]
        #csv << ['Subject:', @quiz.context.subject.try(:name)]
        if @details.to_group
          csv << ['Published to:',User.find(@details.group_id).name]
        else
          csv << ['Published to:',User.find(@details.recipient_id).name]
        end
        csv << ['Total Questions:',@quiz.questions.count]
        csv << ['Total Marks:',@quiz.quiz_question_instances.sum(:grade)]
        csv << ['Published on:',display_date_time(@details.published_on)]
        csv << [" "]
        csv << "Edutorid,Admission,Student Name,Class,Section,Marks,Submit Time".split(",")
        all_attempts.each do |c|
          csv << c
        end
      end
      file_name =  (assessment_name+"_"+published_to+".csv").gsub(" ","").to_s
      logger.info "=-========================filename:#{file_name}"
      send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"
    elsif params[:export_type] == "Export (Questionwise table) csv"
      mode = params[:mode]
      subq = ' FROM quiz_attempts qa '
      if mode.to_i==1
        subq = " FROM (SELECT user_id,min(timefinish) AS timefinish FROM quiz_attempts WHERE publish_id=#{publish_id} group by user_id) qa1 INNER JOIN quiz_attempts qa ON qa1.user_id=qa.user_id AND qa.timefinish=qa1.timefinish "
      elsif mode.to_i ==2
        subq = " FROM (SELECT user_id,max(timefinish) AS timefinish FROM quiz_attempts WHERE publish_id=#{publish_id} group by user_id) qa1 INNER JOIN quiz_attempts qa ON qa1.user_id=qa.user_id AND qa.timefinish=qa1.timefinish "
      end
      sql = "SELECT u.id,u.edutorid AS edutorid,p.firstname AS name,q.tag as tag, qqa.marks AS marks ,qa.timefinish AS time #{subq} INNER JOIN profiles p on qa.user_id=p.user_id INNER JOIN users u on u.id=qa.user_id inner join quiz_question_attempts qqa on qqa.quiz_attempt_id=qa.id INNER JOIN questions q on q.id = qqa.question_id WHERE qa.publish_id=#{publish_id}"

      attempts = QuizAttempt.find_by_sql(sql)
      all_attempts = []
      questions_count = @quiz.questions.count
      i = 1
      if @quiz.format_type == 0
        attempts.each do |a|
          if i > questions_count
            i = 1
          end
          user = User.find(a.id)
          all_attempts << [a.edutorid,user.school_uid,a.name,(user.academic_class.name rescue ""),(user.section.name rescue ""),a.marks,Time.at(a.time).to_datetime.strftime("%d-%b-%Y %I:%M %p")]
          i = i+1
        end
      else
        attempts.each do |a|
          user = User.find(a.id)
          all_attempts << [a.edutorid,user.school_uid,a.name,(user.academic_class.name rescue ""),(user.section.name rescue ""),a.marks,Time.at(a.time).to_datetime.strftime("%d-%b-%Y %I:%M %p")]
        end
      end

      csv_data = FasterCSV.generate do |csv|
        #csv << ""
        csv << ['Institution:',User.find(@quiz.institution_id).name]
        #csv << ['Center:',User.find(@quiz.center_id).name]
        csv << ['Assessment Name:',@quiz.name]
        #csv << ['Subject:', @quiz.context.subject.try(:name)]
        if @details.to_group
          csv << ['Published to:',User.find(@details.group_id).name]
        else
          csv << ['Published to:',User.find(@details.recipient_id).name]
        end
        csv << ['Total Questions:',@quiz.questions.count]
        csv << ['Total Marks:',@quiz.quiz_question_instances.sum(:grade)]
        csv << ['Published on:',display_date_time(@details.published_on)]
        csv << [" "]
        csv << "Edutorid,Admission,Student Name,Class,Section,Marks,Submit Time".split(",")
        all_attempts.each do |c|
          csv << c
        end
      end
      file_name =  (assessment_name+"_"+published_to+".csv").gsub(" ","").to_s
      logger.info "=-========================filename:#{file_name}"
      send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"
    else
      mode = params[:mode]
      subq = ' FROM quiz_attempts qa '
      if mode.to_i==1
        subq = " FROM (SELECT user_id,min(timefinish) AS timefinish FROM quiz_attempts WHERE publish_id=#{publish_id} group by user_id) qa1 INNER JOIN quiz_attempts qa ON qa1.user_id=qa.user_id AND qa.timefinish=qa1.timefinish "
      elsif mode.to_i ==2
        subq = " FROM (SELECT user_id,max(timefinish) AS timefinish FROM quiz_attempts WHERE publish_id=#{publish_id} group by user_id) qa1 INNER JOIN quiz_attempts qa ON qa1.user_id=qa.user_id AND qa.timefinish=qa1.timefinish "
      end
      sql = "SELECT qa.id AS qa_id, u.id,u.edutorid AS edutorid,p.firstname AS name,q.tag as tag, qqa.marks AS marks ,qa.timefinish AS time #{subq} INNER JOIN profiles p on qa.user_id=p.user_id INNER JOIN users u on u.id=qa.user_id inner join quiz_question_attempts qqa on qqa.quiz_attempt_id=qa.id INNER JOIN questions q on q.id = qqa.question_id WHERE qa.publish_id=#{publish_id}"

      attempts = QuizAttempt.find_by_sql(sql)
      #logger.info"========#{attempts.map(&:id)}"
      all_attempts = []
      questions_count = @quiz.questions.count
      i = 1
      @attempts = []
      @attempt_ids = attempts.map(&:qa_id)
      #if @quiz.format_type == 0
      @attempt_ids.each do |qa|
        #attempts.where(:quiz_attempt_id).each_slice(questions_count).each do |a|
        q_attempt = QuizQuestionAttempt.where(:quiz_attempt_id=>qa)
        quiz_attempt = QuizAttempt.find(qa)
        marks =  q_attempt.collect{|i|  i.marks.to_f}
        user_id =    q_attempt.first.user_id
        user = User.includes(:academic_class,:section).find(user_id)
        @attempts << [user.edutorid,user.school_uid,user.name,(user.academic_class.name rescue ""),(user.section.name rescue "")]+marks+[marks.sum.to_f,Time.at(quiz_attempt.timefinish).to_datetime.strftime("%d-%b-%Y %I:%M %p")]
        #end
      end

      #attempts.each do |a|
      #  if i > questions_count
      #    i = 1
      #  end
      #  user = User.find(a.id)
      #  all_attempts << [a.edutorid,a.name,(user.academic_class.name rescue ""),(user.section.name rescue ""),i,a.marks,Time.at(a.time).to_datetime.strftime("%d-%b-%Y %I:%M %p")]
      #  i = i+1
      #end
      #else
      #  attempts.each do |a|
      #    user = User.find(a.id)
      #    all_attempts << [a.edutorid,a.name,(user.academic_class.name rescue ""),(user.section.name rescue ""),a.tag,a.marks,Time.at(a.time).to_datetime.strftime("%d-%b-%Y %I:%M %p")]
      #  end
      #end


      csv_data = FasterCSV.generate do |csv|
        csv << ['Institution:',User.find(@quiz.institution_id).name]
        #csv << ['Center:',User.find(@quiz.center_id).name]
        csv << ['Assessment Name:',@quiz.name]
        #csv << ['Subject:', @quiz.context.subject.try(:name)]
        if @details.to_group
          csv << ['Published to:',User.find(@details.group_id).name]
        else
          csv << ['Published to:',User.find(@details.recipient_id).name]
        end
        csv << ['Total Questions:',@quiz.questions.count]
        csv << ['Total Marks:',@quiz.quiz_question_instances.sum(:grade)]
        csv << ['Published on:',display_date_time(@details.published_on)]
        csv << [" "]
        #csv << "Edutorid,Student Name,class,section,Question,Marks,Submit Time".split(",")
        csv << "Edutorid,Admission,Student Name,Class,Section,#{(1..questions_count).collect{|i|i}.join(',')},Total,submit Time".split(",")
        @attempts.uniq.each do |c|
          csv << c
        end
      end
      file_name =  (assessment_name+"_"+published_to+".csv").gsub(" ","").to_s
      logger.info "=-========================filename:#{file_name}"
      send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"
    end
  end



  def export_student_question_results
    publish_id = params[:id]
    @details = QuizTargetedGroup.find(params[:id])
    published_to = User.find(@details.group_id).profile.firstname
    assessment_name = Quiz.find(@details.quiz_id).name
    #subq = " FROM (SELECT user_id,min(timefinish) AS timefinish FROM quiz_attempts WHERE publish_id=#{publish_id} group by user_id) qa1 INNER JOIN quiz_attempts qa ON qa1.user_id=qa.user_id AND qa.timefinish=qa1.timefinish "
    sql = "SELECT u.edutorid AS edutorid,CONCAT(p.firstname,' ',p.surname) AS name,q.tag as tag, qqa.marks AS marks ,qa.timefinish AS time FROM (SELECT user_id,min(timefinish) AS timefinish FROM quiz_attempts WHERE publish_id=#{publish_id} group by user_id) qa1 INNER JOIN quiz_attempts qa ON qa1.user_id=qa.user_id AND qa.timefinish=qa1.timefinish INNER JOIN profiles p on qa.user_id=p.user_id INNER JOIN users u on u.id=qa.user_id inner join quiz_question_attempts qqa on qqa.quiz_attempt_id=qa.id INNER JOIN questions q on q.id = qqa.question_id WHERE publish_id=#{publish_id}"
    attempts = QuizAttempt.find_by_sql(sql)
    all_attempts = []
    attempts.each do |a|
      user = User.find_by_edutorid(a)
      all_attempts << [a.edutorid,a.name,a.tag,a.marks,Time.at(a.time).to_datetime.strftime("%d-%b-%Y %I:%M %p")]
    end
    csv_data = FasterCSV.generate do |csv|
      csv << "Edutorid,Student Name,Question,Marks,Submit Time".split(",")
      all_attempts.each do |c|
        csv << c
      end
    end
    file_name =  (assessment_name+"_"+published_to+".csv").gsub(" ","").to_s
    logger.info "=-========================filename:#{file_name}"
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"
  end

  def student_attempted_assessments
    group_ids = current_user.groups.map(&:id)
    group_ids << current_user.id
    group_ids = group_ids.join(",")
    #@publish = QuizTargetedGroup.find_by_sql("SELECT * from quiz_targeted_groups qtg INNER JOIN quiz_attempts qa on qa.publish_id=qtg.id WHERE group_id IN (#{group_ids}) OR recipient_id=#{current_user.id} AND qa.user_id=#{current_user.id} group by qa.publish_id order by qtg.id DESC")
    @publish = QuizTargetedGroup.find_by_sql("SELECT * from quiz_targeted_groups qtg WHERE (group_id IN (#{group_ids}) OR recipient_id=#{current_user.id}) AND id IN (SELECT publish_id FROM quiz_attempts qa WHERE qa.user_id=#{current_user.id}) order by qtg.id DESC")
    @publish = Kaminari.paginate_array(@publish).page(params[:page])
  end

  def student_not_attempted_assessments
    group_ids = current_user.groups.map(&:id)
    group_ids << current_user.id
    group_ids = group_ids.join(",")
    @publish = QuizTargetedGroup.find_by_sql("SELECT * from quiz_targeted_groups qtg WHERE (group_id IN (#{group_ids}) OR recipient_id=#{current_user.id}) AND id NOT IN (SELECT publish_id FROM quiz_attempts qa WHERE qa.user_id=#{current_user.id}) order by qtg.id DESC")
    @publish = Kaminari.paginate_array(@publish).page(params[:page])
    #authorize! :student_not_attempted_assessments, current_user
  end

  def start_assessment
    @publish = QuizTargetedGroup.find(params[:id])
    @marked_q = {}
    if !@publish.nil?
      @quiz = Quiz.find(@publish.quiz_id)
      check = OnlineQuizAttempt.find_by_sql("SELECT status as m FROM online_quiz_attempts WHERE quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND user_id=#{current_user.id} AND saved_at=(SELECT max(saved_at) FROM online_quiz_attempts WHERE quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND user_id=#{current_user.id}) limit 1")
      if check.size !=0 && check.first.m ==1
        redirect_to :action => "ask_to_resume_assessment",:id=>params[:id]
        return
      end

      now_time = Time.now.to_i
      #if (@publish.timeopen.to_i > now_time || @publish.timeclose.to_i < now_time)
      if (@publish.timeopen.to_i > now_time)
        respond_to do |format|
          format.html { render "cannot_start_assessment" }
          format.json { render json: @quiz.errors, status: :unprocessable_entity }
        end
        return
      end

      if @publish.password.length > 1
        if !params[:password].present?
          @message = "This assessment requires password. Please enter the password to continue."
          respond_to do |format|
            format.html { render "ask_password" }
            format.json { render json: @quiz.errors, status: :unprocessable_entity }
          end
          return
        end
        if params[:password] != @publish.password
          @message = "You have entered wrong password. Please try again"
          respond_to do |format|
            format.html { render "ask_password" }
            format.json { render json: @quiz.errors, status: :unprocessable_entity }
          end
          return
        end
      end

      @time_left = @quiz.timelimit*60
      if @quiz.timelimit == 0
        @time_left = -1
      end
      if @quiz.format_type == 1
        respond_to do |format|
          format.html { render "take_openformat_assessment2",:layout=>false }
          format.json { render json: @quiz.errors, status: :unprocessable_entity }
        end
      elsif @quiz.format_type == 8
        respond_to do |format|
          format.html { redirect_to start_assessment_path(quiz: @quiz.id, publish: @publish.id) }
        end
      else
        @question = @quiz.questions.first
        @first = true
        @last = false
        @option_ids = []
        @attempted_question_ids = ''
        respond_to do |format|
          format.html { render "take_normal_assessment" }
          format.json { render json: @quiz.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def online_next_question
    if params[:question_id].present?
      save_normal_assessment_question_attempt
      quiz_id = params[:quiz_id]
      question_id = get_next_question(params[:question_id], quiz_id)
      @question = Question.find(question_id)
      @last = false
      if get_next_question(question_id, quiz_id).nil?
        @last = true
      end
      @attempt = OnlineQuizAttempt.where(:user_id=>current_user.id,:quiz_id=>params[:quiz_id],:publish_id=>params[:publish_id],:question_id=>question_id,:status=>1)
      @option_ids = []
      if @attempt
        @attempt.each do |a|
          @option_ids << a.option_id
        end
      else
        @option_ids = nil
      end
      @attempted_question_ids = online_get_questions_attempted(params[:quiz_id],params[:publish_id])
    end
  end

  def online_previous_question
    if params[:question_id].present?
      save_normal_assessment_question_attempt
      quiz_id = params[:quiz_id]
      question_id = get_previous_question(params[:question_id], quiz_id)
      @question = Question.find(question_id)
      @first = false
      if get_previous_question(question_id, quiz_id).nil?
        @first = true
      end
      @attempt = OnlineQuizAttempt.where(:user_id=>current_user.id,:quiz_id=>params[:quiz_id],:publish_id=>params[:publish_id],:question_id=>question_id,:status=>1)
      @option_ids = []
      if @attempt
        @attempt.each do |a|
          @option_ids << a.option_id
        end
      else
        @option_ids = nil
      end
      @attempted_question_ids = online_get_questions_attempted(params[:quiz_id],params[:publish_id])
      respond_to do |format|
        format.js { render "online_next_question" }
      end
    end
  end

  def online_get_questions_attempted(quiz_id,publish_id)
    q = OnlineQuizAttempt.find_by_sql("SELECT DISTINCT(question_id) FROM online_quiz_attempts WHERE quiz_id=#{quiz_id} AND user_id=#{current_user.id} AND publish_id=#{publish_id} AND status=1 AND option_id !=0")
    @a = []
    q.each do |qa|
      @a << qa.question_id
    end
    return @a.join(",")
  end

  def online_show_question
    if params[:id].present?
      save_normal_assessment_question_attempt
      quiz_id = params[:quiz_id]
      question_id = params[:id]
      @question = Question.find(question_id)
      @first = false
      @last = false
      if get_previous_question(question_id, quiz_id).nil?
        @first = true
      end
      if get_next_question(question_id, quiz_id).nil?
        @last = true
      end
      @attempt = OnlineQuizAttempt.where(:user_id=>current_user.id,:quiz_id=>params[:quiz_id],:publish_id=>params[:publish_id],:question_id=>question_id,:status=>1)
      @option_ids = []
      if @attempt
        @attempt.each do |a|
          @option_ids << a.option_id
        end
      else
        @option_ids = nil
      end
      @attempted_question_ids = online_get_questions_attempted(params[:quiz_id],params[:publish_id])
      respond_to do |format|
        format.js { render "online_next_question" }
      end
    end
  end

  def get_next_question(question_id,quiz_id)
    instance = Quiz.find_by_sql("SELECT q.question_id FROM quiz_question_instances q, quiz_question_instances q1 WHERE q1.quiz_id=#{quiz_id} AND q1.question_id=#{question_id} AND q.quiz_id=q1.quiz_id AND q.id > q1.id limit 1")
    if instance.size > 0
      instance.first.question_id
    else
      nil
    end
  end
  def get_previous_question(question_id,quiz_id)
    instance = Quiz.find_by_sql("SELECT q.question_id FROM quiz_question_instances q, quiz_question_instances q1 WHERE q1.quiz_id=#{quiz_id} AND q1.question_id=#{question_id} AND q.quiz_id=q1.quiz_id AND q.id < q1.id order by q.id DESC limit 1")
    if instance.size > 0
      instance.first.question_id
    else
      nil
    end
  end

  def ask_to_resume_assessment
    @publish_id = params[:id]
  end

  def resume_assessment
    @publish = QuizTargetedGroup.find(params[:id])
    if !@publish.nil?
      @quiz = Quiz.find(@publish.quiz_id)
      if @quiz.format_type == 1
        autofill = OnlineQuizAttempt.find_by_sql("SELECT question_id,option_id,time_left,extras FROM online_quiz_attempts WHERE quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND user_id=#{current_user.id} AND status=1 AND saved_at= (SELECT max(saved_at) FROM online_quiz_attempts WHERE quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND user_id=#{current_user.id})")
        @attempts = {}
        @marked_q = []
        autofill.each do |a|
          if @attempts[a.question_id].nil?
            @attempts[a.question_id] = []
          end
          @attempts[a.question_id] << a.option_id
        end
        @time_left = @quiz.timelimit
        if autofill.size > 0
          @time_left = autofill.first.time_left
          @marked_q = autofill.first.extras.split(',')
        end

        respond_to do |format|
          format.html { render "take_openformat_assessment2",:layout=>false }
          format.json { render json: @quiz.errors, status: :unprocessable_entity }
        end
        return
      else
        @marked_q = []

        t = OnlineQuizAttempt.find_by_sql("SELECT question_id,time_left,extras FROM online_quiz_attempts WHERE user_id=#{current_user.id} AND quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND status=1 order by id DESC limit 1")
        @time_left = @quiz.timelimit
        if t.size > 0
          @time_left = t.first.time_left
          @marked_q = t.first.extras.split(',')
          @question = Question.find(t.first.question_id)
          @first = false
          @last = false
          if get_previous_question(@question.id, @quiz.id).nil?
            @first = true
          end
          if get_next_question(@question.id, @quiz.id).nil?
            @last = true
          end
        else
          @question = @quiz.questions.first
          @first = true
          @last = false
        end
        @attempt = OnlineQuizAttempt.where(:user_id=>current_user.id,:quiz_id=>@quiz.id,:publish_id=>@publish.id,:question_id=>@question.id,:status=>1)
        @option_ids = []
        if @attempt
          @attempt.each do |a|
            @option_ids << a.option_id
          end
        else
          @option_ids = nil
        end
        @attempted_question_ids = online_get_questions_attempted(@quiz.id,@publish.id)
        respond_to do |format|
          format.html { render "take_normal_assessment" }
          format.json { render json: @quiz.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def restart_assessment
    OnlineQuizAttempt.update_all("status = 0","status=1 AND publish_id= #{params[:id]} AND user_id=#{current_user.id}")
    redirect_to :action => "start_assessment",:id=>params[:id]
    return
  end

  def submit_assessment
    @publish = QuizTargetedGroup.find(params[:id])
    @quiz = Quiz.find(@publish.quiz_id)

    OnlineQuizAttempt.update_all("status = 0","publish_id= #{params[:id]} AND user_id=#{current_user.id}")

    prev_quiz_attempt = QuizAttempt.find_by_sql("SELECT max(attempt) as m FROM quiz_attempts WHERE publish_id=#{@publish.id} AND quiz_id=#{@quiz.id} AND user_id=#{current_user.id}")
    @attempt_no = 1
    if prev_quiz_attempt.size > 0 && !prev_quiz_attempt.first.m.nil?
      @attempt_no = prev_quiz_attempt.first.m+1
    end
    ActiveRecord::Base.transaction do
      @quiz.increment!(:attempts)
      @quiz_attempt = QuizAttempt.new
      @quiz_attempt.quiz_id = @quiz.id
      @quiz_attempt.publish_id = @publish.id
      @quiz_attempt.user_id = current_user.id
      @quiz_attempt.attempt = @attempt_no
      @quiz_attempt.timestart = 0
      @quiz_attempt.timefinish = Time.now.to_i
      @quiz_attempt.save

      @publish.increment!(:total_attempts)

      @total_attempts = 0
      @total_marks = 0
      @answers = {}
      if params[:answers].present?
        params[:answers].each do |key,value|
          @answers[key.to_i] = value
        end
      end
      @quiz.questions.each do |q|
        if @answers[q.id].nil?
          @answers[q.id] = []
          @answers[q.id] << 0
        end
      end
      @answers.each do |key,value|
        @quiz_question_attempt = QuizQuestionAttempt.new
        @quiz_question_attempt.quiz_id = @quiz.id
        @quiz_question_attempt.quiz_attempt_id = @quiz_attempt.id
        @quiz_question_attempt.question_id = key
        @quiz_question_attempt.user_id = current_user.id
        @quiz_question_attempt.appearance_order = key

        @quiz_question_attempt.time_taken = 0
        @quiz_question_attempt.attempted_at = 0


        @question = Question.find(key)
        if @question.qtype == "multichoice" || @question.qtype == "truefalse"
          @quiz_question_attempt.qtype = @question.qtype
          @quiz_question_instance = @quiz.quiz_question_instances.where("question_id = ?",key).first
          @question_answer = @question.question_answers.where("fraction = ?",1)

          correct_answers = []
          @question_answer.each do |qans|
            correct_answers << qans.id
          end

          if correct_answers.length != value.length
            @quiz_question_attempt.correct = false
            @quiz_question_attempt.marks = (- @quiz_question_instance.penalty)
          else
            @quiz_question_attempt.correct = true
            @quiz_question_attempt.marks = @quiz_question_instance.grade
            value.each do |v|
              if !correct_answers.include? v.to_i
                @quiz_question_attempt.correct = false
                @quiz_question_attempt.marks = (- @quiz_question_instance.penalty)
              end
            end
          end

          if value.length ==1 && (value[0] == "0" || value[0] == 0)
            #logger.info "value length"
            @quiz_question_attempt.correct = false
            @quiz_question_attempt.marks = 0
          end

          @quiz_question_attempt.save
          @total_marks = @total_marks + @quiz_question_attempt.marks
          @quiz_attempt.sumgrades = @total_marks
          @quiz_attempt.save

          value.each do |v|
            @mcq_question_attempt = McqQuestionAttempt.new
            @mcq_question_attempt.quiz_question_attempt_id = @quiz_question_attempt.id
            @mcq_question_attempt.question_answer_id = v.to_i
            @mcq_question_attempt.selected = true
            @mcq_question_attempt.attempted_at = 0
            @mcq_question_attempt.save
          end
        end
      end
      redirect_to action: "show_student_attempts",:id=>@publish.id
    end
  end

  def submit_normal_assessment
    @publish = QuizTargetedGroup.find(params[:id])
    @quiz = Quiz.find(@publish.quiz_id)
    save_normal_assessment_question_attempt

    prev_quiz_attempt = QuizAttempt.find_by_sql("SELECT max(attempt) as m FROM quiz_attempts WHERE publish_id=#{@publish.id} AND quiz_id=#{@quiz.id} AND user_id=#{current_user.id}")
    @attempt_no = 1
    if prev_quiz_attempt.size > 0 && !prev_quiz_attempt.first.m.nil?
      @attempt_no = prev_quiz_attempt.first.m+1
    end
    ActiveRecord::Base.transaction do
      @quiz.increment!(:attempts)
      @quiz_attempt = QuizAttempt.new
      @quiz_attempt.quiz_id = @quiz.id
      @quiz_attempt.publish_id = @publish.id
      @quiz_attempt.user_id = current_user.id
      @quiz_attempt.attempt = @attempt_no
      @quiz_attempt.timestart = 0
      @quiz_attempt.timefinish = Time.now.to_i
      @quiz_attempt.save

      @publish.increment!(:total_attempts)

      @total_attempts = 0
      @total_marks = 0
      @answers = {}
      @time_taken = {}
      @attempted_at = {}
      a = OnlineQuizAttempt.where(:status=>1,:quiz_id=>@quiz.id,:publish_id=>@publish.id,:user_id=>current_user.id)

      a.each do |k|
        if k.question_id.to_i ==0
          next
        end
        if @answers[k.question_id.to_i].nil?
          @answers[k.question_id.to_i] = []
        end
        @answers[k.question_id.to_i] << k.option_id
        @time_taken[k.question_id.to_i] = k.time_taken
        @attempted_at[k.question_id.to_i] = k.saved_at
      end
      @quiz.questions.each do |q|
        if @answers[q.id].nil?
          @answers[q.id] = []
          @answers[q.id] << 0
        end
      end
      @answers.each do |key,value|
        @quiz_question_attempt = QuizQuestionAttempt.new
        @quiz_question_attempt.quiz_id = @quiz.id
        @quiz_question_attempt.quiz_attempt_id = @quiz_attempt.id
        @quiz_question_attempt.question_id = key
        @quiz_question_attempt.user_id = current_user.id
        @quiz_question_attempt.appearance_order = key


        @quiz_question_attempt.time_taken = 0
        if !@time_taken[key].nil?
          @quiz_question_attempt.time_taken = @time_taken[key]
        end
        @quiz_question_attempt.attempted_at = 0
        if !@attempted_at[key].nil?
          @quiz_question_attempt.attempted_at = @attempted_at[key]
        end


        @question = Question.find(key)
        if @question.qtype == "multichoice" || @question.qtype == "truefalse"
          @quiz_question_attempt.qtype = @question.qtype
          @quiz_question_instance = @quiz.quiz_question_instances.where("question_id = ?",key).first
          @question_answer = @question.question_answers.where("fraction = ?",1)

          correct_answers = []
          @question_answer.each do |qans|
            correct_answers << qans.id
          end

          if correct_answers.length != value.length
            @quiz_question_attempt.correct = false
            @quiz_question_attempt.marks = (- @quiz_question_instance.penalty)
          else
            @quiz_question_attempt.correct = true
            @quiz_question_attempt.marks = @quiz_question_instance.grade
            value.each do |v|
              if !correct_answers.include? v.to_i
                @quiz_question_attempt.correct = false
                @quiz_question_attempt.marks = (- @quiz_question_instance.penalty)
              end
            end
          end

          if value.length ==1 && (value[0] == "0" || value[0] == 0)
            #logger.info "value length"
            @quiz_question_attempt.correct = false
            @quiz_question_attempt.marks = 0
          end

          @quiz_question_attempt.save
          @total_marks = @total_marks + @quiz_question_attempt.marks
          @quiz_attempt.sumgrades = @total_marks
          @quiz_attempt.save

          value.each do |v|
            @mcq_question_attempt = McqQuestionAttempt.new
            @mcq_question_attempt.quiz_question_attempt_id = @quiz_question_attempt.id
            @mcq_question_attempt.question_answer_id = v.to_i
            @mcq_question_attempt.selected = true
            @mcq_question_attempt.attempted_at = 0
            @mcq_question_attempt.save
          end
        end
      end
      OnlineQuizAttempt.update_all("status = 0","publish_id= #{params[:id]} AND user_id=#{current_user.id}")
      redirect_to action: "show_student_attempts",:id=>@publish.id
    end
  end

  def save_assessment_state
    @status = {}
    saved_at = Time.now.to_i
    if params[:answers].present?
      params[:answers].each do |key,value|
        value.each do |option|
          oqa = OnlineQuizAttempt.new
          oqa.status = 1
          oqa.publish_id = params[:publish_id]
          oqa.quiz_id = params[:quiz_id]
          oqa.question_id = key.to_i
          oqa.option_id = option.to_i
          oqa.saved_at = saved_at
          oqa.time_left = params[:time_left]
          oqa.user_id = current_user.id
          oqa.extras = params[:marked_questions]
          oqa.save
        end
      end
      @status['status'] = 'ok'
    else
      oqa = OnlineQuizAttempt.new
      oqa.status = 1
      oqa.publish_id = params[:publish_id]
      oqa.quiz_id = params[:quiz_id]
      oqa.question_id = 0
      oqa.option_id = 0
      oqa.saved_at = saved_at
      oqa.time_left = params[:time_left]
      oqa.user_id = current_user.id
      oqa.extras = params[:marked_questions]
      oqa.save
    end
    respond_to do |format|
      format.json { render json: @status,:layout=>false }
      format.html { render json: @status,:layout=>false }
    end
    return
  end

  def pause_assessment_state
    @status = {}
    saved_at = Time.now.to_i
    if params[:answers].present?
      params[:answers].each do |key,value|
        value.each do |option|
          oqa = OnlineQuizAttempt.new
          oqa.status = 1
          oqa.publish_id = params[:publish_id]
          oqa.quiz_id = params[:quiz_id]
          oqa.question_id = key.to_i
          oqa.option_id = option.to_i
          oqa.saved_at = saved_at
          oqa.time_left = params[:time_left]
          oqa.user_id = current_user.id
          oqa.extras = params[:marked_questions]
          oqa.save
        end
      end
      @status['status'] = 'ok'
    else
      oqa = OnlineQuizAttempt.new
      oqa.status = 1
      oqa.publish_id = params[:publish_id]
      oqa.quiz_id = params[:quiz_id]
      oqa.question_id = 0
      oqa.option_id = 0
      oqa.saved_at = saved_at
      oqa.time_left = params[:time_left]
      oqa.user_id = current_user.id
      oqa.extras = params[:marked_questions]
      oqa.save
    end
    respond_to do |format|
      format.json { render json: @status,:layout=>false }
      format.html { render json: @status,:layout=>false }
    end
    return
  end

  def save_normal_assessment_state
    @status = {}
    save_normal_assessment_question_attempt
    respond_to do |format|
      format.json { render json: @status,:layout=>false }
      format.html { render json: @status,:layout=>false }
    end
    return
  end

  def pause_normal_assessment_state
    @status = {}
    save_normal_assessment_question_attempt
    respond_to do |format|
      format.json { render json: @status,:layout=>false }
      format.html { render json: @status,:layout=>false }
    end
    return
  end

  def save_normal_assessment_question_attempt
    if params[:question_id].present?
      saved_at = Time.now.to_i
      if params[:answers].present?
        params[:answers].each do |key,value|
          value.each do |option|
            oqa = OnlineQuizAttempt.where(:question_id=>params[:question_id],:quiz_id=>params[:quiz_id],:user_id=>current_user.id,:publish_id=>params[:publish_id],:status=>1,:option_id=>0)
            if oqa.size == 0
              oqa = OnlineQuizAttempt.where(:question_id=>params[:question_id],:quiz_id=>params[:quiz_id],:user_id=>current_user.id,:publish_id=>params[:publish_id],:status=>1,:option_id=>option.to_i)
              if oqa.size ==0
                oqa = OnlineQuizAttempt.new
                oqa.time_taken = params[:time_taken]
              else
                oqa = OnlineQuizAttempt.find(oqa.first.id)
                oqa.time_taken = oqa.time_taken.to_i+params[:time_taken].to_i
              end
            else
              oqa = OnlineQuizAttempt.find(oqa.first.id)
              oqa.time_taken = oqa.time_taken.to_i+params[:time_taken].to_i
            end
            oqa.time_left = params[:time_left]
            oqa.status = 1
            oqa.publish_id = params[:publish_id]
            oqa.quiz_id = params[:quiz_id]
            oqa.question_id = params[:question_id]
            oqa.option_id = option.to_i
            oqa.saved_at = saved_at

            oqa.user_id = current_user.id
            oqa.extras = params[:marked_questions]
            oqa.save
          end
        end
      else
        saved_at = Time.now.to_i
        oqa = OnlineQuizAttempt.where(:question_id=>params[:question_id],:quiz_id=>params[:quiz_id],:user_id=>current_user.id,:publish_id=>params[:publish_id],:status=>1)
        if oqa.size == 0
          oqa = OnlineQuizAttempt.new
          oqa.time_taken = params[:time_taken]
        else
          oqa = OnlineQuizAttempt.find(oqa.first.id)
          oqa.time_taken = oqa.time_taken.to_i+params[:time_taken].to_i
        end
        oqa.time_left = params[:time_left]
        oqa.status = 1
        oqa.publish_id = params[:publish_id]
        oqa.quiz_id = params[:quiz_id]
        oqa.question_id = params[:question_id]
        oqa.option_id = 0
        oqa.saved_at = saved_at
        oqa.user_id = current_user.id
        oqa.extras = params[:marked_questions]
        oqa.save
      end
    end

  end

  def show_student_attempts
    @publish = QuizTargetedGroup.find(params[:id])
    @quiz = Quiz.find(@publish.quiz_id)
    @attempts = QuizAttempt.includes(:user, :quiz_question_attempts).where(:quiz_id=>@quiz.id,:publish_id=>@publish.id,:user_id=>current_user.id).order("timefinish desc")
    @total_marks = @quiz.quiz_question_instances.sum(:grade)
    @machine = QuizQuestionInstance.includes([:quiz, :question]).where("quizzes.id= ? and (questions.qtype='multichoice' or questions.qtype='fib' or questions.qtype='truefalse')", @quiz.id).sum(:grade)
    if (@quiz.accessible(current_user.id, current_user.institution_id))
      respond_to do |format|
        format.html
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    else
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    end
  end

  def show_student_question_attempts
    @question_attempts = QuizQuestionAttempt.where(:quiz_attempt_id=>params[:id])
    @quiz = Quiz.find(@question_attempts.first.quiz_id)
    @total_marks = @quiz.quiz_question_instances.sum(:grade)
    if (@quiz.accessible(current_user.id, current_user.institution_id))
      respond_to do |format|
        format.html
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    else
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_qcontext
    ContextTemp.all.each do |ct|
      b = Content.where(:type=>"Board",:name=>ct.board).first
      cl = Content.where(:type=>"ContentYear",:name=>ct.content_year,:board_id=>b.id).first
      s = Content.where(:type=>"Subject",:name=>ct.subject,:board_id=>b.id,:content_year_id=>cl.id).first
      ch = Content.where(:type=>"Chapter",:name=>ct.chapter,:board_id=>b.id,:content_year_id=>cl.id,:subject_id=>s.id).first
      con = Context.new
      con.board_id = b.id
      con.content_year_id = cl.id
      con.subject_id = s.id
      con.chapter_id = ch.id
      con.topic_id = 0
      con.save
      q = Question.find(ct.question_id)
      q.context_id = con.id
      q.save
    end
  end

  def create_db
    ContextTemp.group(:board).each do |b|
      bn = Content.new
      bn.type = "Board"
      bn.name = b.board
      bn.save(:validate=>false)
      ContextTemp.where(:board=>b.board).group(:content_year).each do |cy|
        cyn = Content.new
        cyn.type = "ContentYear"
        cyn.name = cy.content_year
        cyn.board_id = bn.id
        cyn.save(:validate=>false)
        ContextTemp.where(:board=>b.board,:content_year=>cy.content_year).group(:subject).each do |s|
          sn = Content.new
          sn.type = "Subject"
          sn.name = s.subject
          sn.board_id = bn.id
          sn.content_year_id = cyn.id
          sn.save(:validate=>false)
          ContextTemp.where(:board=>b.board,:content_year=>cy.content_year,:subject=>s.subject).group(:chapter).each do |c|
            cn = Content.new
            cn.type = "Chapter"
            cn.name = c.chapter
            cn.board_id = bn.id
            cn.content_year_id = cyn.id
            cn.subject_id = sn.id
            cn.save(:validate=>false)
          end
        end
      end
    end
  end

  def import2
    z=1
    Dir.glob('/home/praveen/Desktop/DB3/**/*.etx').each do |etx_file|
      #begin
      #ActiveRecord::Base.transaction do
      test = TestImportLog.where("name = ?",etx_file)
      if test.exists?
        next
      end
      a = etx_file
      l = a.length
      filename = a[0,l-5]

      basename = File.basename(etx_file)
      if basename.scan("DAD").present?
        next
      end
      b = basename
      lb = b.length
      basename1 = b[0,lb-4]
      @doc = Nokogiri::XML(File.open(etx_file))
      #@doc = Nokogiri::XML(File.open("/home/praveen/Desktop/cb_6_Science_12_1.xml"))

      File.open("/home/praveen/Desktop/status", "a+", 0644) {|f| f.write "processing..."+etx_file+"\n"}
      @testpaper = @doc.xpath("//testpaper")
      guidelines = @testpaper.xpath("guidelines").attr("value").to_s
      requisites = @testpaper.xpath("requisites").attr("value").to_s
      time = @testpaper.xpath("time").attr("value").to_s
      difficulty = @testpaper.xpath("level").attr("value").to_s

      start_time_node = Nokogiri::XML::Node.new('start_time',@doc)
      @testpaper.children.first.add_previous_sibling(start_time_node)
      start_time_node.set_attribute("value","0")

      end_time_node = Nokogiri::XML::Node.new('end_time',@doc)
      @testpaper.children.first.add_previous_sibling(end_time_node)
      end_time_node.set_attribute("value","0")

      shufflequestions_node = Nokogiri::XML::Node.new('shufflequestions',@doc)
      @testpaper.children.first.add_previous_sibling(shufflequestions_node)
      shufflequestions_node.set_attribute("value","0")

      shuffleoptions_node = Nokogiri::XML::Node.new('shuffleoptions',@doc)
      @testpaper.children.first.add_previous_sibling(shuffleoptions_node)
      shuffleoptions_node.set_attribute("value","0")

      pause_node = Nokogiri::XML::Node.new('pause',@doc)
      @testpaper.children.first.add_previous_sibling(pause_node)
      pause_node.set_attribute("value","0")

      show_score_after_node = Nokogiri::XML::Node.new('show_score_after',@doc)
      @testpaper.children.first.add_previous_sibling(show_score_after_node)
      show_score_after_node.set_attribute("value","0")

      show_solutions_after_node = Nokogiri::XML::Node.new('show_solutions_after',@doc)
      @testpaper.children.first.add_previous_sibling(show_solutions_after_node)
      show_solutions_after_node.set_attribute("value","0")

      ActiveRecord::Base.transaction do
        @quiz = Quiz.new
        @quiz.createdby = 1
        @quiz.modifiedby = 1
        @quiz.institution_id = 1
        @quiz.center_id =1
        @quiz.name = basename1
        @quiz.intro = guidelines
        @quiz.difficulty = difficulty.to_i
        @quiz.timeopen = 0
        @quiz.timeclose = 0
        @quiz.timelimit = time

        #@context = @quiz.context
        #@context.board_id = 0
        #@context.subject_id = 0
        #@context.content_year_id = 0
        if @quiz.save(:validate=>false)
          qut = QuizTemp.new
          qut.quiz_id = @quiz.id
          qut.requisites = requisites
          qut.save

          @testpaper.first.set_attribute('id', @quiz.id.to_s)
          @testpaper.first.set_attribute('version',"2")
          @testpaper.xpath("//question_set").each do |q|
            question = Question.new
            question.createdby = 1
            question.institution_id = 1
            question.center_id = 1
            question.name = ""
            question.questiontext = clean(q.xpath("question").xpath("question_text").inner_text)
            if !q.xpath("question").xpath("question_text").empty?
              q.xpath("question").xpath("question_text").first.content = question.questiontext
            else
              question.questiontext = "Attempt it"
            end
            question.generalfeedback = clean(q.xpath("question").xpath("comment").inner_text)
            if !q.xpath("question").xpath("comment").empty?
              q.xpath("question").xpath("comment").first.content = question.generalfeedback
            end
            if q.xpath("qtype").empty?
              next
            end
            if q.xpath("qtype").attr("value").to_s =="MCQ"
              question.qtype = "multichoice"
            elsif q.xpath("qtype").attr("value").to_s == "MTF"
              question.qtype = "match"
            elsif q.xpath("qtype").attr("value").to_s == "TOF"
              question.qtype = "truefalse"
            elsif q.xpath("qtype").attr("value").to_s == "SS"
              question.qtype = "parajumble"
            else
              next
            end

            question.defaultmark = q.xpath("score").attr("value").to_s
            question.penalty = q.xpath("negativescore").attr("value").to_s
            if !q.xpath("difficulty").empty?
              question.difficulty = q.xpath("difficulty").attr("value").to_s.to_i
            else
              question.difficulty = 1
            end
            if q.xpath("prob_skill").empty?
              question.prob_skill = 0
            else
              question.prob_skill = q.xpath("prob_skill").attr("value").to_s
            end
            if q.xpath("data_skill").empty?

              question.data_skill = 0
            else
              question.data_skill = q.xpath("data_skill").attr("value").to_s
            end
            if q.xpath("useofit_skill").empty?
              question.useofit_skill = 0
            else
              question.useofit_skill = q.xpath("useofit_skill").attr("value").to_s
            end
            if q.xpath("creativity_skill").empty?
              question.creativity_skill = 0
            else
              question.creativity_skill = q.xpath("creativity_skill").attr("value").to_s
            end
            if q.xpath("listening_skill").empty?
              question.listening_skill = 0
            else
              question.listening_skill = q.xpath("listening_skill").attr("value").to_s
            end
            if q.xpath("speaking_skill").empty?
              question.speaking_skill = 0
            else
              question.speaking_skill = q.xpath("speaking_skill").attr("value").to_s
            end
            if q.xpath("grammar_skill").empty?
              question.grammer_skill = 0
            else
              question.grammer_skill = q.xpath("grammar_skill").attr("value").to_s
            end

            if q.xpath("vocab_skill").empty?
              question.vocab_skill = 0
            else
              question.vocab_skill = q.xpath("vocab_skill").attr("value").to_s
            end
            if q.xpath("formulae_skill").empty?
              question.formulae_skill = 0
            else
              question.formulae_skill = q.xpath("formulae_skill").attr("value").to_s
            end
            if q.xpath("comprehension_skill").empty?
              question.comprehension_skill = 0
            else
              question.comprehension_skill = q.xpath("comprehension_skill").attr("value").to_s
            end

            if q.xpath("knowledge_skill").empty?
              question.knowledge_skill = 0
            else
              question.knowledge_skill = q.xpath("knowledge_skill").attr("value").to_s
            end
            if q.xpath("application_skill").empty?
              question.application_skill = 0
            else
              question.application_skill = q.xpath("application_skill").attr("value").to_s
            end

            question.save(:validate=>false)

            context = ContextTemp.new
            context.question_id = question.id
            if q.xpath("board").empty?
              next
            end
            context.board = q.xpath("board").attr("value").to_s
            if q.xpath("class").empty?
              next
            end
            context.content_year = q.xpath("class").attr("value").to_s
            if q.xpath("subject").empty?
              next
            end
            context.subject = q.xpath("subject").attr("value").to_s
            if !q.xpath("chapter").empty?
              context.chapter = q.xpath("chapter").attr("value").to_s
            end
            #context.course = q.xpath("course").attr("value").to_s
            context.course ="Regular"
            context.time = q.xpath("time").attr("value").to_s
            context.save

            q.set_attribute('id', question.id.to_s)
            i = 1
            if question.qtype == "multichoice" || question.qtype=="truefalse"
              q.xpath("question//option").each do |o|

                qa = QuestionAnswer.new
                qa.question = question.id
                qa.answer = clean(o.xpath("option_text").inner_text)
                o.xpath("option_text").first.content = qa.answer
                qa.feedback = clean(o.xpath("feedback").inner_text)
                if !o.xpath("feedback").empty?
                  o.xpath("feedback").first.content = qa.feedback
                end
                if i==1
                  o.set_attribute("tag","A")
                end
                if i==2
                  o.set_attribute("tag","B")
                end
                if i==3
                  o.set_attribute("tag","C")
                end
                if i==4
                  o.set_attribute("tag","D")
                end
                if q.xpath("question//answer").first.attr("value").to_s == "A"
                  if i==1
                    qa.fraction = 1
                    o.set_attribute("answer","true")
                  else
                    qa.fraction = 0
                    o.set_attribute("answer","false")
                  end
                end
                if q.xpath("question//answer").first.attr("value").to_s == "B"
                  if i==2
                    qa.fraction = 1
                    o.set_attribute("answer","true")
                  else
                    qa.fraction = 0
                    o.set_attribute("answer","false")
                  end
                end
                if q.xpath("question//answer").first.attr("value").to_s == "C"
                  if i==3
                    qa.fraction = 1
                    o.set_attribute("answer","true")
                  else
                    qa.fraction = 0
                    o.set_attribute("answer","false")
                  end
                end
                if q.xpath("question//answer").first.attr("value").to_s == "D"
                  if i==4
                    qa.fraction = 1
                    o.set_attribute("answer","true")
                  else
                    qa.fraction = 0
                    o.set_attribute("answer","false")
                  end
                end
                i = i +1
                qa.save
                o.set_attribute("id",qa.id.to_s)
              end
            elsif question.qtype=="match"
              q.xpath("question//mtf_pair").each do |o|
                qm = QuestionMatchSub.new
                qm.question = question.id
                qm.questiontext = clean(o.xpath("lhs").inner_text)
                o.xpath("lhs").first.content = qm.questiontext
                qm.answertext = clean(o.xpath("rhs").inner_text)
                o.xpath("rhs").first.content = qm.answertext
                qm.save
                o.set_attribute("id",qm.id.to_s)
              end
            elsif question.qtype =="parajumble"
              q.xpath("question//step").each do |o|
                qp = QuestionParajumble.new
                qp.question = question.id
                qp.questiontext = clean(o.inner_text)
                o.content = qp.questiontext
                if o.attr("order").to_s == "1"
                  qp.order = 1
                elsif o.attr("order").to_s == "2"
                  qp.order = 2
                elsif o.attr("order").to_s == "3"
                  qp.order = 3
                elsif o.attr("order").to_s == "4"
                  qp.order = 4
                elsif o.attr("order").to_s == "5"
                  qp.order = 5
                elsif o.attr("order").to_s == "6"
                  qp.order = 6
                elsif o.attr("order").to_s == "7"
                  qp.order = 7
                elsif o.attr("order").to_s == "8"
                  qp.order = 8
                elsif o.attr("order").to_s == "9"
                  qp.order = 9
                elsif o.attr("order").to_s == "10"
                  qp.order = 10
                end
                qp.save
                o.set_attribute("id",qp.id.to_s)
              end
            end

            qqi = QuizQuestionInstance.new
            qqi.quiz_id = @quiz.id
            qqi.question_id = question.id
            qqi.grade = question.defaultmark
            qqi.penalty = question.penalty
            qqi.save

          end
        else
          #logger.debug(@quiz.errors.messages)
        end
      end
      #end
      z = z+1
      #rescue
      #end
      File.open(etx_file, "w+b") {|f| f.write @doc}
      test = TestImportLog.new
      test.name=etx_file
      test.save
      #File.open("/home/praveen/Desktop/newetx/6th/"+basename, "w+b") {|f| f.write @doc}
    end
  end

  def clean(text)
    text.gsub!('<p class="MsoNormal">','')
    text.gsub!('<notp>','')
    text.gsub!('<notp class="MsoNormal">','')
    return text
  end

  def export2
    folder = "/home/praveen/Desktop/QB4/"
    Question.all.each do |q|
      if q.qtype != 'multichoice'
        next
      end
      @c = ContextTemp.where(:question_id=>q.id).first
      if !@c
        next
      end
      qiii = QuestionIndex.where(:question_id =>q.id).first
      if qiii
        next
      end
      ct = ChapterTemp.where(:chapter=>@c.chapter).first
      dir = folder+"#{@c.course.downcase}/#{@c.board.downcase}/#{@c.content_year.to_i}/#{@c.subject.downcase}/#{ct.id}"
      if !File.directory?(dir)
        FileUtils.mkdir_p dir
      end
      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.question_set(:id=>q.id.to_s){
          xml.course(:value=>@c.course)
          xml.board(:value=>@c.board)
          xml.class_(:value=>@c.content_year)
          xml.subject(:value=>@c.subject)
          xml.chapter(:value=>@c.chapter)
          xml.time(:value=>@c.time.to_s)
          xml.score(:value=>q.defaultmark.to_s)
          xml.negativescore(:value=>q.penalty.to_s)
          xml.prob_skill(:value=>(q.prob_skill) ? '1' : '0')
          xml.data_skill(:value=>(q.data_skill) ? '1' : '0')
          xml.useofit_skill(:value=>(q.useofit_skill) ? '1' : '0')
          xml.creativity_skill(:value=>(q.creativity_skill) ? '1' : '0')
          xml.listening_skill(:value=>(q.listening_skill) ? '1' : '0')
          xml.speaking_skill(:value=>(q.speaking_skill) ? '1' : '0')
          xml.grammar_skill(:value=>(q.grammer_skill) ? '1' : '0')
          xml.vocab_skill(:value=>(q.vocab_skill) ? '1' : '0')
          xml.formulae_skill(:value=>(q.formulae_skill) ? '1' : '0')
          xml.comprehension_skill(:value=>(q.comprehension_skill) ? '1' : '0')
          xml.knowledge_skill(:value=>(q.knowledge_skill) ? '1' : '0')
          xml.application_skill(:value=>(q.application_skill) ? '1' : '0')
          xml.difficulty(:value=>q.difficulty.to_s)
          xml.qtype(:value=>"MCQ")
          xml.comment_{
            xml.cdata q.generalfeedback
          }
          xml.question{
            xml.question_text{
              xml.cdata q.questiontext
            }
            @options = QuestionAnswer.where("question=?",q.id)
            if @options.size ==0
              next
            end
            i =1
            @options.each do |o|
              tag =""
              if i==1
                tag ="A"
              end
              if i==2
                tag="B"
              end
              if i==3
                tag= "C"
              end
              if i==4
                tag="D"
              end
              xml.option(:id=>o.id.to_s,:tag=>tag,:answer=>((o.fraction==1)? "true" : "false")){
                xml.option_text{
                  xml.cdata o.answer
                }
                xml.feedback{
                  xml.cdata o.feedback
                }
              }
              i = i+1
            end
          }
        }
      end
      xml_string =  @builder.to_xml.to_s
      File.open(dir+"/#{q.id.to_s}.etx",  "w+b", 0644) do |f|
        f.write(xml_string.to_s)
      end
      dir = folder+"#{@c.course.downcase}/#{@c.board.downcase}/#{@c.content_year.to_i}/#{@c.subject.downcase}/#{ct.id}"
      filename = "/master.etx"
      if !File.exist?(dir+filename)
        @builder1 = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.root{
            xml.question(:id=>q.id.to_s){
              xml.question_text{
                xml.cdata q.questiontext
              }
            }
          }
        end
      else
        @builder1 = Nokogiri::XML(File.open(dir+filename))
        @testpaper = @builder1.xpath("root")
        question = Nokogiri::XML::Node.new('question',@builder1)
        @testpaper.children.first.add_previous_sibling(question)
        question.set_attribute("id",q.id.to_s)
        tmp = Nokogiri::XML::Document.new

        question_text = Nokogiri::XML::Node.new('question_text',@builder1)
        question_text.content = tmp.create_cdata(q.questiontext)
        question.add_child(question_text)
      end
      xml_string =  @builder1.to_xml.to_s
      File.open(dir+filename,  "w+", 0644) do |f|
        f.write(xml_string.to_s)
      end
      qi = QuestionIndex.new
      qi.question_id = q.id
      qi.save
    end

  end

  def set_qc
    Institution.all.each do |i|
      i.boards.each do |b|
        be = BoardName.where(:name=>b.name,:institution_id=>i.id).first
        if !be
          BoardName.create(:name=>b.name,:enabled=>1,:institution_id=>i.id)
        end
        b.content_years.each do |cy|
          cye = ClassName.where(:name=>cy.name,:institution_id=>i.id).first
          if !cye
            ClassName.create(:name=>cy.name,:enabled=>1,:institution_id=>i.id)
          end
          cy.subjects.each do |s|
            se = SubjectName.where(:name=>s.name,:institution_id=>i.id).first
            if !se
              SubjectName.create(:name=>s.name,:enabled=>1,:institution_id=>i.id)
            end
            s.chapters.each do |c|
              ce = ChapterName.where(:name=>c.name,:institution_id=>i.id).first
              if !ce
                ChapterName.create(:name=>c.name,:enabled=>1,:institution_id=>i.id)
              end
              c.topics.each do |t|
                te = TopicName.where(:name=>t.name,:institution_id=>i.id).first
                if !te
                  TopicName.create(:name=>t.name,:enabled=>1,:institution_id=>i.id)
                end
              end
            end
          end
        end
      end
    end
  end

  def set_qcg
    ContextTemp.all.each do |i|
      i.boards.each do |b|
        be = BoardName.where(:name=>b.name,:institution_id=>i.id).first
        if !be
          BoardName.create(:name=>b.name,:enabled=>1,:institution_id=>i.id)
        end
        b.content_years.each do |cy|
          cye = ClassName.where(:name=>cy.name,:institution_id=>i.id).first
          if !cye
            ClassName.create(:name=>cy.name,:enabled=>1,:institution_id=>i.id)
          end
          cy.subjects.each do |s|
            se = SubjectName.where(:name=>s.name,:institution_id=>i.id).first
            if !se
              SubjectName.create(:name=>s.name,:enabled=>1,:institution_id=>i.id)
            end
            s.chapters.each do |c|
              ce = ChapterName.where(:name=>c.name,:institution_id=>i.id).first
              if !ce
                ChapterName.create(:name=>c.name,:enabled=>1,:institution_id=>i.id)
              end
              c.topics.each do |t|
                te = TopicName.where(:name=>t.name,:institution_id=>i.id).first
                if !te
                  TopicName.create(:name=>t.name,:enabled=>1,:institution_id=>i.id)
                end
              end
            end
          end
        end
      end
    end
  end

#Pdf report for the quiz attempt users parent
  def send_report_parent
    if params[:id]
      @question_attempts = QuizQuestionAttempt.where(:quiz_attempt_id=>params[:id])
      @quiz = Quiz.find(@question_attempts.first.quiz_id)
      @publish_id = @question_attempts.first.quiz_attempt.publish_id
      @total_marks = @quiz.quiz_question_instances.sum(:grade)
      @user = @question_attempts.first.user
      @total = QuizAttempt.where(:publish_id=>@publish_id,:attempt=>1)
      @total_students = QuizAttempt.where(:publish_id=>@publish_id,:attempt=>1).map(&:user_id).uniq
      @total_average = @total.average(:sumgrades)
      @top_score = @total.maximum(:sumgrades)
      @total_questions = @quiz.questions.count
      @correct_attempts = @question_attempts.where(:correct=>true).count
      @not_attempts = @total_questions - (McqQuestionAttempt.where(:quiz_question_attempt_id=>@question_attempts).map(&:quiz_question_attempt_id).uniq.count+FibQuestionAttempt.where(:quiz_question_attempt_id=>@question_attempts.map(&:id),:fib_question_answer=>0).count)
      @wrong_attempts = @total_questions - (@correct_attempts+@not_attempts)
      @quiz_attempt = QuizAttempt.where(:publish_id=>@question_attempts.first.quiz_attempt.publish_id,:attempt=>1,:user_id=>@user.id)
      pdf = render_to_string :pdf => "some_file_name",
                             :disposition => 'attachment',
                             :template=>"quizzes/quiz_attempt_report.pdf.html",
                             :disable_external_links => true,
                             :print_media_type => true
      if params[:type] == "message"
        path = Rails.root.to_s+"/tmp/cache"
        file = File.new(path+"/"+"#{Time.now.to_i}_"+"#{@quiz.name}.pdf", "w+")
        File.open(file,'wb') do |f|
          f << pdf
        end
        @message = Message.new
        @message_asset = @message.assets.build
        @message_asset.attachment = File.open(file,"rb")
        @message.recipient_id = @user.id
        @message.sender_id = current_user.id
        @message.message_type = "Report"
        @message.label =  "Report"
        @message.body =    "please download the detailed report of perfornamce in the assessment #{@quiz.name}"
        @message.subject = "Assessment report #{@quiz.name}"
        @message.save
      elsif  params[:type] == "email"
        UserMailer.send_quiz_report(@user,pdf,@quiz).deliver
      end

      flash[:notice] = 'Report sent sucessfully'
      redirect_to  :action => "show_question_attempts",:id=>params[:id]
    else

      #ajax request

      if request.xhr?
        logger.info "===================ajax request"
        #@quiz_attempts = params[:attempt_ids].split(',')
        select_all= params[:select_all]
        @publish = QuizTargetedGroup.find(params[:publish])
        @quiz = Quiz.find(@publish.quiz_id)
        @quiz_attempts = QuizQuestionAttempt.where(:quiz_attempt_id=>params[:attempt_ids].split(',')).group(:user_id).map(&:quiz_attempt_id)
        #logger.info"===========#{@quiz_attempts}"
        @attempts = QuizAttempt.find_by_sql("SELECT qa.*,ug.user_id FROM quiz_attempts qa INNER JOIN user_groups ug on qa.user_id=ug.user_id WHERE qa.quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND ug.group_id=#{@publish.group_id}")
        @other_group_attempts = QuizAttempt.find_by_sql("SELECT * FROM quiz_attempts WHERE quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND id NOT IN (SELECT qa.id FROM quiz_attempts qa INNER JOIN user_groups ug on qa.user_id=ug.user_id WHERE qa.quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND ug.group_id=#{@publish.group_id})")
        @g_attempts = @attempts.map(&:user_id)
        @user_in_group = QuizAttempt.find_by_sql("SELECT user_id FROM user_groups inner join users on users.id=user_groups.user_id WHERE group_id=#{@publish.group_id} and users.edutorid like 'ES-%'").map(&:user_id)
        @not_attempted = @user_in_group-@g_attempts

        type = params[:type]
        users = []
        invalid_users = []
        begin
          @quiz_attempts.each do |q|
            @question_attempts = QuizQuestionAttempt.where(:quiz_attempt_id=>q)
            #@quiz = Quiz.find(@question_attempts.first.quiz_id)
            @total_marks = @quiz.quiz_question_instances.sum(:grade)
            @user = @question_attempts.first.user
            @publish_id = @question_attempts.first.quiz_attempt.publish_id
            #sql = QuizAttempt.where(:publish_id=>@publish_id,:attempt=>1,:user_id=>@user.id).to_sql
            @quiz_attempt = QuizAttempt.where(:publish_id=>@publish_id,:attempt=>1,:user_id=>@user.id)
            @total = QuizAttempt.where(:publish_id=>@publish_id,:attempt=>1)
            @total_students = QuizAttempt.where(:publish_id=>@publish_id,:attempt=>1).map(&:user_id).uniq
            @total_average = @total.average(:sumgrades)
            @top_score = @total.maximum(:sumgrades)
            @total_questions = @quiz.questions.count
            @correct_attempts = @question_attempts.where(:correct=>true).count
            @not_attempts = @total_questions - (McqQuestionAttempt.where(:quiz_question_attempt_id=>@question_attempts).map(&:quiz_question_attempt_id).uniq.count+FibQuestionAttempt.where(:quiz_question_attempt_id=>@question_attempts.map(&:id),:fib_question_answer=>0).count)
            @wrong_attempts = @total_questions - (@correct_attempts+@not_attempts)
            pdf = render_to_string :pdf => "some_file_name",
                                   :disposition => 'attachment',
                                   :template=>"quizzes/quiz_attempt_report.pdf.html",
                                   :disable_external_links => true,
                                   :print_media_type => true

            if type == "message"
              path = Rails.root.to_s+"/tmp/cache"
              file = File.new(path+"/"+"#{Time.now.to_i}_"+"#{@quiz.name}_#{q}.pdf", "w+")
              File.open(file,'wb') do |f|
                f << pdf
              end
              @message = Message.new
              @message_asset = @message.assets.build
              @message_asset.attachment = File.open(file,"rb")
              @message.recipient_id = @user.id
              @message.sender_id = current_user.id
              @message.message_type = "Report"
              @message.label =  "Report"
              @message.body =    "please download the detailed report of perfornamce in the assessment #{@quiz.name}"
              @message.subject = "Assessment report #{@quiz.name}"
              @message.save
              users << @user.name
            elsif type =="email"
              if @user.profile.parent_email.present?
                UserMailer.send_quiz_report(@user,pdf,@quiz).deliver
                users << @user.name
              else
                invalid_users << @user.name
              end
            end
          end
        rescue Exception => e
          @error = "#{e.message} for #{e.try(:record).try(:class).try(:name)}"
        end


        #sending report for not attempted users
        #logger.info "=================#{select_all}"
        #logger.info "=================#{@not_attempted}"
=begin
        if select_all == true
          logger.info"==================#nor attempted"
          begin
            not_attempt_pdf = render_to_string :pdf => "some_file_name",
              :disposition => 'attachment',
              :template=>"quizzes/quiz_attempt_report.pdf.html",
              :disable_external_links => true,
              :print_media_type => true
            path = Rails.root.to_s+"/tmp"
            not_attempt_file = File.new(path+"/"+"#{Time.now.to_i}_"+"#{@quiz.name}.pdf", "w+")
            File.open(file,'wb') do |f|
              f << not_attempt_pdf
            end
            logger.info"=========================not attempted"
            logger.info "=================#{@not_attempted}"
            @not_attempted.each do |user|
              @message = Message.new
              @message_asset = @message.assets.build
              @message_asset.attachment = File.open(not_attempt_file,"rb")
              @message.recipient_id = user
              @message.sender_id = current_user.id
              @message.message_type = "Report"
              @message.label =  "Report"
              @message.body =    "please download the detailed report of performance in the assessment #{@quiz.name}"
              @message.subject = "Assessment report #{@quiz.name}"
              @message.save
            end
          rescue Exception => e
            @not_error = "#{e.message} for #{e.try(:record).try(:class).try(:name)}"
          end
        end
=end
        #logger.info"===========#{@error }"
        #logger.info"===========#{@not_error }"
        @not_size =  invalid_users.size
        @not_sent = "Report not sent to #{invalid_users.join(", ")}"
        if users.size > 0
          @sent_message = "Report sent successfully to #{users.join(", ")}"
        else
          @sent_message = "Report not sent"
        end
        respond_to do |format|
          format.js
        end
      end
    end

  end

  def get_test_zip
    string = request.body.read
    results =  ActiveSupport::JSON.decode(string)
    result = results.first
    @uresponse = {}
    @uresponse['success'] = false
    if !result['test_id'].present? || !result['password'].present?
      @uresponse['error'] = "Test_Id/password missing"
      render json: @uresponse
      return
    end
    key = "dwefefeklnkv"
    hash = Digest::MD5.hexdigest(result['test_id']+key)
    if result['password'] != hash
      logger.debug("Hash is --------:"+hash)
      @uresponse['error'] = "Authentication failure"
      logger.info(@uresponse)
      render json: @uresponse
      return
    end

    #@publish = QuizTargetedGroup.find(result['test_id'].to_i)
    m = MessageQuizTargetedGroup.where(:quiz_targeted_group_id=>result['test_id'].to_i)
    if m.size < 1
      @uresponse['error'] = "No message exists."
      render json: @uresponse
      return
    end

    message_id = m.first.message_id
    a = Asset.where(:archive_id=>message_id,:archive_type=>"Message")
    if a.size < 1
      @uresponse['error'] = "No attachment exists."
      render json: @uresponse
      return
    end
    @uresponse['success'] = true
    @uresponse['src'] = a.first.src
    render json: @uresponse
  end


#Downloading questions of the quiz in pdf format
  def download_questions
    @quiz = Quiz.find(params[:id])
    #if !(@quiz.accessible(current_user.id, current_user.institution_id))
    #  respond_to do |format|
    #    format.html { redirect_to action: "index" }
    #    format.json { render json: @quiz.errors, status: :unprocessable_entity }
    #  end
    #  return
    #end
    @questions = @quiz.questions
    respond_to do |format|
      #format.html
      format.pdf do
        render :pdf => "#{@quiz.name}",
               :disposition => 'attachment',
               #:show_as_html=>true,
               :template=>"quizzes/download_questions.html",
               :disable_external_links => true,
               :print_media_type => true
      end
    end
  end

  def remove_catchall_question
    if params[:id].present?
      @i = QuizQuestionInstance.find(params[:id])
      quiz_id = @i.quiz_id
      @i.destroy
      @quiz = Quiz.find(quiz_id)
      redirect_to @quiz, notice: 'Question was removed successfully.'
    end
  end


#intern created the zip uploaded having etx files.

  def zip_action
    #require 'rubygems'
    #require 'archive-zip'

    @zip_upload = ZipUpload.find(params[:zip_upload_id])
    if params[:i]=="got"
      @context = Context.find(params[:context_id])
    end
    @publish_assessment = false
    name1=@zip_upload.asset.original_filename.split('.')[0].to_s
    directory = @zip_upload.asset.path.gsub("/#{@zip_upload.asset_file_name}","")
    filename = directory+"/#{@zip_upload.asset_file_name}"
    destfile="#{Rails.root.to_s}"+"/public"+"/question_images"
    Archive::Zip.extract(filename, directory)
    srcfile=directory+"/"
    @etxname=""
    @rtn_etx=""
    @n = 0
    @etx_files = Rails.root.to_s+"/etx_files/"+Time.now.to_s
    FileUtils.mkdir(@etx_files)
    respond_to do |format|
      if (Dir[directory+"/"+'/*.etx'])!=[]
        begin
          ActiveRecord::Base.transaction do
            zipfiles=Dir[srcfile+'/*']
            FileUtils.cp_r zipfiles, destfile
            Dir[directory+"/"+'/*.etx'].each do |etxfile|
              basename = File.basename(etxfile)
              b = basename
              lb = b.length
              basename1 = b[0,lb-4]

              @etxname=@etxname+basename1+', '

              file = File.new(etxfile)
              @file = etxfile
              @etx = Nokogiri::XML(file)

              @testpaper = @etx.xpath("//testpaper")
              guidelines = @testpaper.xpath("guidelines").attr("value").to_s
              requisites = @testpaper.xpath("requisites").attr("value").to_s
              time = @testpaper.xpath("time").attr("value").to_s unless @testpaper.xpath("time").empty?
              difficulty = @testpaper.xpath("level").attr("value").to_s  unless @testpaper.xpath("level").empty?
              pause = @testpaper.xpath("can_pause").attr("value").to_s unless @testpaper.xpath("can_pause").empty?

              @var=ZipUpload.find(params[:zip_upload_id])

              if @var.check==1
                @quiz = Quiz.new
                @quiz.createdby = current_user.id
                @quiz.modifiedby = current_user.id
                @quiz.name = basename1
                @quiz.intro = guidelines
                @quiz.difficulty = difficulty.to_i
                @quiz.timeopen = 0
                @quiz.timeclose = 0
                @quiz.timelimit = time
                @quiz.introformat = 0
                @quiz.attempts = 0
                @quiz.attemptonlast = 0
                @quiz.grademethod = 1
                @quiz.decimalpoints = 2
                @quiz.questiondecimalpoints = -2
                @quiz.reviewattempt = 0
                @quiz.reviewcorrectness = 0
                @quiz.reviewmarks = 0

                qct=@etx.xpath("//question_set")
                if @context==nil
                  cxt=Context.new
                  cxt.board_id=Board.find_by_name(qct.xpath("board").attr("value").to_s).id
                  if ContentYear.find_by_board_id_and_name(cxt.board_id,qct.xpath("class").attr("value").to_s)!=nil
                    cxt.content_year_id=ContentYear.find_by_board_id_and_name(cxt.board_id,qct.xpath("class").attr("value").to_s).id
                  else
                    cntnt=Content.new
                    cntnt.board_id=Board.find_by_name(qct.xpath("board").attr("value").to_s).id
                    cntnt.type="ContentYear"
                    cntnt.name=qct.xpath("class").attr("value").to_s
                    cntnt.uri="/Curriculum/Content/"+qct.xpath("board").attr("value").to_s+"/"+qct.xpath("class").attr("value").to_s
                    clscode=qct.xpath("class").attr("value").to_s
                    cntnt.code=clscode.to_i
                    cntnt.save(:validate=>false)
                    cxt.content_year_id=ContentYear.find_by_board_id_and_name(cxt.board_id,qct.xpath("class").attr("value").to_s).id
                    #cxt.content_year_id="1"
                  end
                  if Subject.find_by_board_id_and_content_year_id_and_name(cxt.board_id,cxt.content_year_id,qct.xpath("subject").attr("value").to_s)!=nil
                    cxt.subject_id=Subject.find_by_board_id_and_content_year_id_and_name(cxt.board_id,cxt.content_year_id,qct.xpath("subject").attr("value").to_s).id
                  else
                    cntnt=Content.new
                    cntnt.board_id=Board.find_by_name(qct.xpath("board").attr("value").to_s).id
                    cntnt.content_year_id=ContentYear.find_by_board_id_and_name(cxt.board_id,qct.xpath("class").attr("value").to_s).id
                    cntnt.type="Subject"
                    cntnt.name=qct.xpath("subject").attr("value").to_s

                    cntnt.uri="/Curriculum/Content/"+qct.xpath("board").attr("value").to_s+"/"+qct.xpath("class").attr("value").to_s+"/"+qct.xpath("subject").attr("value").to_s
                    sjcode=qct.xpath("subject").attr("value").to_s
                    sjcode=sjcode[0,2]
                    cntnt.code=sjcode.downcase
                    cntnt.save(:validate=>false)
                    cxt.subject_id=Subject.find_by_board_id_and_content_year_id_and_name(cxt.board_id,cxt.content_year_id,qct.xpath("subject").attr("value").to_s).id

                    #cxt.subject_id="1"
                  end
                  if Chapter.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,qct.xpath("chapter").attr("value").to_s)!=nil
                    cxt.chapter_id=Chapter.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,qct.xpath("chapter").attr("value").to_s).id
                  else
                    cntnt=Content.new
                    cntnt.board_id=Board.find_by_name(qct.xpath("board").attr("value").to_s).id
                    cntnt.content_year_id=ContentYear.find_by_board_id_and_name(cxt.board_id,qct.xpath("class").attr("value").to_s).id
                    cntnt.subject_id=Subject.find_by_board_id_and_content_year_id_and_name(cxt.board_id,cxt.content_year_id,qct.xpath("subject").attr("value").to_s).id
                    cntnt.type="Chapter"
                    cntnt.name=qct.xpath("chapter").attr("value").to_s
                    cntnt.uri="/Curriculum/Content/"+qct.xpath("board").attr("value").to_s+"/"+qct.xpath("class").attr("value").to_s+"/"+qct.xpath("subject").attr("value").to_s+"/"+qct.xpath("chapter").attr("value").to_s

                    cntnt.save(:validate=>false)
                    cxt.chapter_id=Chapter.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,qct.xpath("chapter").attr("value").to_s).id

                    #cxt.chapter_id="1"
                  end
                  if !qct.xpath("topic").empty?
                    if Topic.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,cxt.chapter_id,qct.xpath("topic").attr("value").to_s)!=nil

                      cxt.topic_id=Topic.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,cxt.chapter_id,qct.xpath("topic").attr("value").to_s).id
                    else
                      cntnt=Content.new
                      cntnt.board_id=Board.find_by_name(qct.xpath("board").attr("value").to_s).id
                      cntnt.content_year_id=ContentYear.find_by_board_id_and_name(cxt.board_id,qct.xpath("class").attr("value").to_s).id
                      cntnt.subject_id=Subject.find_by_board_id_and_content_year_id_and_name(cxt.board_id,cxt.content_year_id,qct.xpath("subject").attr("value").to_s).id
                      cntnt.chapter_id=Chapter.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,qct.xpath("chapter").attr("value").to_s).id
                      cntnt.type="Topic"
                      cntnt.name=qct.xpath("topic").attr("value").to_s
                      cntnt.uri="/Curriculum/Content/"+qct.xpath("board").attr("value").to_s+"/"+qct.xpath("class").attr("value").to_s+"/"+qct.xpath("subject").attr("value").to_s+"/"+qct.xpath("chapter").attr("value").to_s+"/"+qct.xpath("topic").attr("value").to_s

                      cntnt.save(:validate=>false)
                      #cxt.topic_id=Topic.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,cxt.chapter_id,qct.xpath("topic").attr("value").to_s).id
                      cxt.topic_id=""
                    end
                  end
                  cxt.save
                else
                  cxt=Context.new
                  cxt.board_id=@context.board_id

                  cxt.content_year_id=@context.content_year_id
                  cxt.subject_id=@context.subject_id
                  if @context.chapter_id==0
                    if !qct.xpath("chapter").empty?
                      if Chapter.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,qct.xpath("chapter").attr("value").to_s) != nil
                        cxt.chapter_id=Chapter.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,qct.xpath("chapter").attr("value").to_s).id
                      end
                    end
                  else
                    cxt.chapter_id=@context.chapter_id
                  end
                  cxt.save
                end
                @q_institutions = Institution.where(:id=>cxt.board.user_ids)
                if !@q_institutions.empty?
                  @q_institution = @q_institutions.first
                end
                @q_centers = Center.where(:id=>cxt.board.user_ids)
                if !@q_centers.empty?
                  @q_center = @q_centers.first
                end
                unless current_user.institution_id.nil?
                  @quiz.institution_id = current_user.institution_id
                else
                  if !@q_institution.nil?
                    @quiz.institution_id = @q_institution.id
                  else
                    @quiz.institution_id = 1
                  end
                end
                unless current_user.center_id.nil?
                  @quiz.center_id = current_user.center_id
                else
                  if !@q_center.nil?
                    @quiz.center_id = @q_center.id
                  else
                    @quiz.center_id = 1
                  end
                end

                @quiz.context_id=cxt.id
                @quiz.reviewspecificfeedback = 0
                @quiz.reviewgeneralfeedback = 0
                @quiz.reviewoverallfeedback = 0
                @quiz.questionsperpage = 0
                @quiz.shufflequestions = 0
                @quiz.shuffleanswers = 0
                @quiz.sumgrades = 0.00000
                @quiz.grade = 0.00000
                @quiz.delay1 = 0
                @quiz.delay2 = 0
                @quiz.showuserpicture = 0
                @quiz.showblocks = 0
                @quiz.save(:validate=>false)
                #
                #@trgtgrp=QuizTargetedGroup.new
                #@trgtgrp.quiz_id=@quiz.id
                #@trgtgrp.group_id=4
                #@trgtgrp.to_group=1
                #@trgtgrp.published_by=1
                #@trgtgrp.save(:validate=>false)
              end
              j = 0
              @sections = {}
              questions = []
              @is_section = false
              @etx.xpath("//question_set").each do |q|
                if q.parent.name == "section"
                  if @quiz
                    @section = QuizSection.find_or_create_by_name_and_quiz_id(q.parent.attr("name"),@quiz.id)
                  end
                  @section_name = q.parent.attr("name").to_s
                  @sections[@section_name] = []
                  @is_section = true
                end
                question = Question.new
                question.createdby = current_user.id
                question.name = ""
                question.questiontext = clean(q.xpath("question").xpath("question_text").inner_text)
                question.generalfeedback = clean(q.xpath("question").xpath("comment").inner_text)
                if q.xpath("qtype").empty?
                  next
                end
                if q.xpath("qtype").attr("value").to_s =="MCQ"
                  question.qtype = "multichoice"
                elsif q.xpath("qtype").attr("value").to_s == "MTF"
                  question.qtype = "match"
                elsif q.xpath("qtype").attr("value").to_s == "TOF"
                  question.qtype = "truefalse"
                elsif q.xpath("qtype").attr("value").to_s == "SS"
                  question.qtype = "parajumble"
                else
                  next
                end
                score = q.xpath("score").attr("value").to_s.to_f
                question.defaultmark =  score.to_s.length == 0 ? 1 : score
                question.penalty = q.xpath("negativescore").attr("value").to_s
                if !q.xpath("course").empty?
                  question.difficulty = q.xpath("course").attr("value").to_s.to_i
                else
                  question.difficulty = "Regular"
                end
                if !q.xpath("difficulty").empty?
                  question.difficulty = q.xpath("difficulty").attr("value").to_s.to_i
                else
                  question.difficulty = 1
                end
                if q.xpath("prob_skill").empty?
                  question.prob_skill = 0
                else
                  question.prob_skill = q.xpath("prob_skill").attr("value").to_s
                end
                if q.xpath("data_skill").empty?

                  question.data_skill = 0
                else
                  question.data_skill = q.xpath("data_skill").attr("value").to_s
                end
                if q.xpath("useofit_skill").empty?
                  question.useofit_skill = 0
                else
                  question.useofit_skill = q.xpath("useofit_skill").attr("value").to_s
                end
                if q.xpath("creativity_skill").empty?
                  question.creativity_skill = 0
                else
                  question.creativity_skill = q.xpath("creativity_skill").attr("value").to_s
                end
                if q.xpath("listening_skill").empty?
                  question.listening_skill = 0
                else
                  question.listening_skill = q.xpath("listening_skill").attr("value").to_s
                end
                if q.xpath("speaking_skill").empty?
                  question.speaking_skill = 0
                else
                  question.speaking_skill = q.xpath("speaking_skill").attr("value").to_s
                end
                if q.xpath("grammar_skill").empty?
                  question.grammer_skill = 0
                else
                  question.grammer_skill = q.xpath("grammar_skill").attr("value").to_s
                end

                if q.xpath("vocab_skill").empty?
                  question.vocab_skill = 0
                else
                  question.vocab_skill = q.xpath("vocab_skill").attr("value").to_s
                end
                if q.xpath("formulae_skill").empty?
                  question.formulae_skill = 0
                else
                  question.formulae_skill = q.xpath("formulae_skill").attr("value").to_s
                end
                if q.xpath("comprehension_skill").empty?
                  question.comprehension_skill = 0
                else
                  question.comprehension_skill = q.xpath("comprehension_skill").attr("value").to_s
                end

                if q.xpath("knowledge_skill").empty?
                  question.knowledge_skill = 0
                else
                  question.knowledge_skill = q.xpath("knowledge_skill").attr("value").to_s
                end
                if q.xpath("application_skill").empty?
                  question.application_skill = 0
                else
                  question.application_skill = q.xpath("application_skill").attr("value").to_s
                end
                question.questiontextformat=""
                question.generalfeedbackformat=""
                question.length="0"
                question.stamp=""
                question.version=""
                question.hidden="0"
                #question.tags=""

                question.timecreated=""
                question.timemodified=""
                question.modifiedby=""
                if @context==nil
                  cxt=Context.new
                  cxt.board_id=Board.find_by_name(q.xpath("board").attr("value").to_s).id
                  if ContentYear.find_by_board_id_and_name(cxt.board_id,q.xpath("class").attr("value").to_s)!=nil

                    cxt.content_year_id=ContentYear.find_by_board_id_and_name(cxt.board_id,q.xpath("class").attr("value").to_s).id
                  else
                    cxt.content_year_id="1"
                  end
                  if Subject.find_by_board_id_and_content_year_id_and_name(cxt.board_id,cxt.content_year_id,q.xpath("subject").attr("value").to_s)!=nil
                    cxt.subject_id=Subject.find_by_board_id_and_content_year_id_and_name(cxt.board_id,cxt.content_year_id,q.xpath("subject").attr("value").to_s).id
                  else
                    cxt.subject_id="1"
                  end
                  if Chapter.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,q.xpath("chapter").attr("value").to_s)!=nil
                    cxt.chapter_id=Chapter.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,q.xpath("chapter").attr("value").to_s).id
                  else
                    cxt.chapter_id="1"
                  end
                  if !q.xpath("topic").empty?
                    if Topic.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,cxt.chapter_id,q.xpath("topic").attr("value").to_s)!=nil

                      cxt.topic_id=Topic.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,cxt.chapter_id,q.xpath("topic").attr("value").to_s).id
                    else
                      cxt.topic_id=""
                    end
                  end

                  cxt.save
                else
                  cxt=Context.new
                  cxt.board_id=@context.board_id
                  cxt.content_year_id=@context.content_year_id
                  cxt.subject_id=@context.subject_id
                  if @context.chapter_id==0
                    if !q.xpath("chapter").empty?
                      if Chapter.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,q.xpath("chapter").attr("value").to_s) != nil
                        cxt.chapter_id=Chapter.find_by_board_id_and_content_year_id_and_subject_id_and_name(cxt.board_id,cxt.content_year_id,cxt.subject_id,q.xpath("chapter").attr("value").to_s).id
                      end
                    end
                  else
                    cxt.chapter_id=@context.chapter_id
                  end
                  cxt.save
                end
                @institutions = Institution.where(:id=>cxt.board.user_ids)
                if !@institutions.empty?
                  @institution = @institutions.first
                end
                @centers = Center.where(:id=>cxt.board.user_ids)
                if !@centers.empty?
                  @center = @centers.first
                end
                question.context_id=cxt.id
                unless current_user.institution_id.nil?
                  question.institution_id = current_user.institution_id
                else
                  if !@institution.nil?
                    question.institution_id = @institution.id
                  else
                    question.institution_id = 1
                  end
                end
                unless current_user.center_id.nil?
                  question.center_id = current_user.center_id
                else
                  if !@center.nil?
                    question.center_id  = @center.id
                  else
                    question.center_id = 1
                  end

                end
                question.save(:validate=> false)
                if @is_section
                  @sections[@section_name] << question.id
                else
                  questions << question.id
                end

                q.set_attribute('id', question.id.to_s)
                i = 1
                apl =  ["A","B","C","D","E"]
                num =  ["1","2","3","4","5"]
                q.xpath("question//option").each do |o|
                  qa = QuestionAnswer.new
                  qa.question = question.id
                  qa.answer = clean(o.xpath("option_text").inner_text)
                  qa.feedback = clean(o.xpath("feedback").inner_text)
                  qa.answerformat="1"
                  qa.feedbackformat="1"
                  if !q.xpath("question//answer").empty?
                    if !q.xpath("question//answer").first.attr("value").nil?
                      question_options = q.xpath("question//answer").first.attr("value").split(',')
                    end
                  end
                  if question_options.count == 1
                    if q.xpath("question//answer").first.attr("value").to_s == "A" or q.xpath("question//answer").first.attr("value").to_s == "1"
                      if i==1
                        qa.fraction = 1
                      else
                        qa.fraction = 0
                      end
                    end
                    if q.xpath("question//answer").first.attr("value").to_s == "B" or q.xpath("question//answer").first.attr("value").to_s == "2"
                      if i==2
                        qa.fraction = 1
                      else
                        qa.fraction = 0
                      end
                    end
                    if q.xpath("question//answer").first.attr("value").to_s == "C" or q.xpath("question//answer").first.attr("value").to_s == "3"
                      if i==3
                        qa.fraction = 1
                      else
                        qa.fraction = 0
                      end
                    end
                    if q.xpath("question//answer").first.attr("value").to_s == "D" or q.xpath("question//answer").first.attr("value").to_s == "4"
                      if i==4
                        qa.fraction = 1
                      else
                        qa.fraction = 0
                      end
                    end
                    if q.xpath("question//answer").first.attr("value").to_s == "E" or q.xpath("question//answer").first.attr("value").to_s == "5"
                      if i==5
                        qa.fraction = 1
                      else
                        qa.fraction = 0
                      end
                    end
                  else
                    if question_options.include?apl[i-1] or question_options.include?num[i-1]
                      qa.fraction = 1
                    else
                      qa.fraction = 0
                    end
                  end
                  i = i +1

                  qa.save(:validate=>false)
                  o.set_attribute("id",qa.id.to_s)
                end
                if @var.check==1
                  qqi = QuizQuestionInstance.new
                  qqi.quiz_id = @quiz.id
                  qqi.question_id = question.id
                  qqi.grade = question.defaultmark
                  qqi.penalty = question.penalty
                  qqi.quiz_section_id = @section.id if @is_section
                  qqi.save(:validate=>false)
                end

              end

              if (@var.check == 1) && (params[:publish] == "1")
                if params[:group_id] != nil
                  @target = QuizTargetedGroup.new
                  @target.quiz_id = @quiz.id
                  @target.group_id = params[:group_id]
                  @target.pause = pause ? 1 : 0
                  @target.assessment_type = 2
                  @target.extras = 'practice'
                  @target.published_by = current_user.id
                  @target.to_group = true
                  @target.save(:validate=>false)
                  create_message(false,@quiz.id,@target.id)
                  @publish_assessment = true
                end
              end

              images = []
              @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
                xml.testpaper(@publish_assessment ? {:id=>@quiz.id.to_s,:version=>"2.0",:publish_id=>@target.id.to_s} :''){
                  xml.guidelines(:value=>"")
                  xml.requisites(:value=>"")
                  xml.pause(:value=> pause ? 1 :0)
                  xml.time(:value=>"-1")
                  xml.level(:value=>3)
                  if @var.check == 1
                    if @quiz.quiz_sections.empty?
                      @instance = QuizQuestionInstance.where("quiz_id = ?",@quiz.id).each do |i|
                        quiz_questions(xml,i,q=nil)
                      end
                    else
                      @quiz.quiz_sections.each do |section|
                        xml.section(:value=>section.name){
                          section.quiz_question_instances.each do |i|
                            quiz_questions(xml,i,q=nil)
                          end
                        }
                      end
                    end
                  elsif @is_section
                    @sections.each do |key,value|
                      xml.section(:value=>key){
                        value.each do |q|
                          quiz_questions(xml,i=nil,q)
                        end
                      }
                    end
                  else
                    questions.each do |q|
                      quiz_questions(xml,i=nil,q)
                    end
                  end

                }
              end

              xml_string =  @builder.to_xml.to_s
              @etxname.split(',')[@n]
              File.open(@etx_files+"/"+(@etxname.split(',')[@n]).strip+".etx",  "w+b", 0644) do |f|
                #f.write(xml_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
                f.write(xml_string.to_s)
              end

              @n = @n+1
            end
            @etxzip= Rails.root.to_s+'/tmp/cache/'+'etx_'+Time.current.to_i.to_s+".zip"
            #rtn_etx=@etx_file.split('~')
            Dir[@etx_files+"/"+'/*.etx'].each do |a|
              Archive::Zip.archive(@etxzip, a)
            end
          end
          format.html {render :action => "zip_action_successful"}
        rescue Exception => e
          puts "Exception in etx uploading...............#{e.message.pretty_inspect}"
          logger.info "Exception in etx uploading....#{e.backtrace}.....#{@file}......#{e.message}"
          flash[:error] = "#{e.message}=======#{@file}"
          format.html { redirect_to quizzes_zip_upload_path }
        end

      else
        @zip_upload.destroy
        FileUtils.rm_rf srcfile
        flash[:notice]=   "EXT is not found in the uploaded zip file"
        format.html {  redirect_to quizzes_zip_upload_path}
      end
    end
  end

  def download
    @etxzip = params[:etx]
    send_file(@etxzip, :type=>"application/zip") and return

  end

  def download_students_reports
    @publish = QuizTargetedGroup.find(params[:publish_id])
    if !@publish.to_group?
      group_id = @publish.recipient_id
    else
      group_id = @publish.group_id
    end
    @quiz = Quiz.find(@publish.quiz_id)
    @quiz_attempts =  QuizAttempt.find_by_sql("SELECT qa.*,ug.user_id FROM quiz_attempts qa INNER JOIN user_groups ug on qa.user_id=ug.user_id WHERE qa.quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND ug.group_id=#{group_id} AND (qa.attempt=1) group by qa.user_id").map(&:id)
    #@quiz_attempts = QuizQuestionAttempt.where(:quiz_attempt_id=>@attempts).group(:user_id).map(&:quiz_attempt_id)
    path = Rails.root.to_s+"/tmp/cache/#{Time.now.to_i.to_s}"
    #path = "/tmp/#{Time.now.to_i.to_s}"
    FileUtils.mkdir_p path
    begin
      @quiz_attempts.each do |q|
        @question_attempts = QuizQuestionAttempt.where(:quiz_attempt_id=>q)
        #@quiz = Quiz.find(@question_attempts.first.quiz_id)
        @total_marks = @quiz.quiz_question_instances.sum(:grade)
        @user = @question_attempts.first.user
        @publish_id = @question_attempts.first.quiz_attempt.publish_id
        #sql = QuizAttempt.where(:publish_id=>@publish_id,:attempt=>1,:user_id=>@user.id).to_sql
        @quiz_attempt = QuizAttempt.where(:publish_id=>@publish_id,:attempt=>1,:user_id=>@user.id)
        @total = QuizAttempt.where(:publish_id=>@publish_id,:attempt=>1)
        @total_students = QuizAttempt.where(:publish_id=>@publish_id,:attempt=>1).map(&:user_id).uniq
        @total_average = @total.average(:sumgrades)
        @top_score = @total.maximum(:sumgrades)
        @total_questions = @quiz.questions.count
        @correct_attempts = @question_attempts.where(:correct=>true).count
        @not_attempts = @total_questions - (McqQuestionAttempt.where(:quiz_question_attempt_id=>@question_attempts).map(&:quiz_question_attempt_id).uniq.count+FibQuestionAttempt.where(:quiz_question_attempt_id=>@question_attempts.map(&:id),:fib_question_answer=>0).count)
        @wrong_attempts = @total_questions - (@correct_attempts+@not_attempts)
        pdf = render_to_string :pdf => "some_file_name",
                               :disposition => 'attachment',
                               :template=>"quizzes/quiz_attempt_report.pdf.html",
                               :disable_external_links => true,
                               :print_media_type => true
        file = File.new(path+"/"+"#{@quiz.name}_#{@user.name}.pdf", "w+")
        File.open(file,'wb') do |f|
          f << pdf
        end
      end
    rescue Exception => e
      @error = "#{e.message} for #{e.try(:record).try(:class).try(:name)}"
    end
    @zip= "#{path}/#{@quiz.name.gsub(' ','_')}_#{Time.current.to_i.to_s}.zip"
    Dir[path+"/"+'/*.pdf'].each do |a|
      Archive::Zip.archive(@zip, a)
    end
    send_file @zip
  end

  def recent_assessments
    #@quizzes = Quiz.where(:id=>@recent.map(&:quiz_id))
    if current_user.id == EDUTOR
      @filter_group = 0
    end
    if params[:filter_group].present?
      @filter_group = params[:filter_group]
    end
    groups = view_context.asign_groups(current_user)
    @groups = {}
    @groups[1] = "Edutor"
    groups.each do |i|
      @groups[i.id] = i.firstname
    end

    if @filter_group.to_i == 0
      @quizzes =  QuizTargetedGroup.includes(:quiz).order('id desc').group(:quiz_id).limit(5)
    else
      @quizzes =  QuizTargetedGroup.includes(:quiz).where(:group_id=>@filter_group).order('id desc').group(:quiz_id).limit(5)
    end
  end

  def recent_results
    @publish = QuizTargetedGroup.find(params[:publisher_id])
    @quiz = Quiz.find(@publish.quiz_id)
    group_id = @publish.group_id
    if !@publish.to_group?
      group_id = @publish.recipient_id
    end
    @attempts = QuizAttempt.find_by_sql("SELECT qa.*,ug.user_id FROM quiz_attempts qa INNER JOIN user_groups ug on qa.user_id=ug.user_id WHERE qa.quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND ug.group_id=#{group_id}")
  end


  def show_questions
    @quiz = Quiz.find(params[:id])
    if params[:question]
      @questions = Question.includes(:question_answers).where(:id=>params[:question][:multiple_ids].split(','))
      @questions.each do |q|
        QuizQuestionInstance.find_or_create_by_quiz_id_and_question_id(@quiz.id,q.id,:grade=>q.defaultmark,:penalty=>q.penalty)
      end
      #@quiz.question_ids = (qids+@questions.map(&:id)).uniq
      redirect_to quiz_path(@quiz)
    end
  end


  def teacher_quizzes
    @quiz_start = 0
    if current_ea
      _temp = Quiz.joins(:quiz_attempts,:quiz_targeted_groups).includes(:quiz_targeted_groups,:context).where('quiz_targeted_groups.to_group=? && format_type=?',true,0).order('quiz_targeted_groups.id desc').limit(10)
    else
      _temp = Quiz.joins(:quiz_attempts,:quiz_targeted_groups).includes(:quiz_targeted_groups,:context).where('quiz_targeted_groups.to_group=? && center_id=?',true,current_user.center_id).order('quiz_targeted_groups.id desc')
    end
    @quizzes = _temp
    @quiz_pages = _temp.page.count
    subjects = @quizzes.collect{|i|i.context.subject_id if i.context.subject_id!= 0}
    users = @quizzes.collect{|i|i.quiz_targeted_groups.collect{|j| j.group_id if j.to_group}}
    @groups = {}
    User.where(:id=>users,:center_id=>current_user.center_id).each do |i|
      @groups[i.id] = i.name
    end
    @subjects = {}
    Subject.where(:id=>subjects).each do |i|
      @subjects[i.id] = (i.content_year.name+i.name).gsub('Class',' ')
    end
    @sg = {}
    Subject.where(:id=>subjects).each do |i|
      quizzes =   Quiz.includes(:quiz_targeted_groups,:context).where('contexts.subject_id=?',i)
      groups = quizzes.collect{|i|i.quiz_targeted_groups.collect{|j| j.group_id if j.to_group}}
      quiz_groups = User.where(:id=>groups,:center_id=>current_user.center_id).collect{|i|[i.id,i.name]}
      @sg = @sg.merge("#{i.id}"=>quiz_groups)
    end
    @sg = @sg.to_s

    logger.info "==quizzes.count=======#{@quizzes.count}"
    #@sg = @sg.to_json
    #@quizzes = Quiz.order("id DESC").all.page(params[:page])
    #@quizzes = Quiz.joins(:quiz_attempts).includes(:quiz_targeted_groups).where('quiz_targeted_groups.to_group=? && format_type=?',true,0).order('quiz_targeted_groups.id desc').limit(10)
    #@quizzes = Quiz.joins(:quiz_attempts).includes(:quiz_targeted_groups,:context).where('quiz_targeted_groups.to_group=? && format_type=? && contexts.content_year_id =? && contexts.subject_id =?',true,0,10841,10842).order('quiz_targeted_groups.id desc')
    logger.info"==================#{@quizzes.count}"
    respond_to do |format|
      format.html { render "teacher_quizzes" ,:layout=>false}
    end

  end



  def get_teacher_quizzes

    if request.xhr?
      if (params[:subject].to_s.eql?("") ) and (params[:group].to_s.eql?("") )
        _temp = Quiz.joins(:quiz_attempts,:quiz_targeted_groups).includes(:quiz_targeted_groups,:context).where('quiz_targeted_groups.to_group=? && center_id=?',true,current_user.center_id).order('quiz_targeted_groups.id desc')
      elsif params[:subject] and ( params[:group].to_s.eql?("") )
        _temp = Quiz.includes(:context,:quiz_targeted_groups).where('contexts.subject_id=?' ,params[:subject])
      elsif params[:group] and ( params[:subject].to_s.eql?("")  )
        _temp = Quiz.includes(:context,:quiz_targeted_groups).where('quiz_targeted_groups.group_id=?',params[:group])
      elsif params[:group] and params[:subject]
        _temp = Quiz.includes(:context,:quiz_targeted_groups).where('contexts.subject_id=? && quiz_targeted_groups.group_id=?',params[:subject],params[:group])
      else
        _temp = Quiz.joins(:quiz_attempts,:quiz_targeted_groups).includes(:quiz_targeted_groups,:context).where('quiz_targeted_groups.to_group=? && center_id=?',true,current_user.center_id).order('quiz_targeted_groups.id desc')
      end
      @quizzes = _temp
      logger.info "===***********@quizzes.count**************======#{@quizzes.count}"
      @quiz_pages = _temp.page.count
      @quiz_pages1 = _temp.page.count
    end
    respond_to do |format|
      format.js
    end
  end




  def teacher_show_attempts
    @publish = QuizTargetedGroup.find(params[:id])
    @quiz = Quiz.find(@publish.quiz_id)
    @publish_class = User.find(@publish.group_id)
    group_id = @publish.group_id
    if !@publish.to_group?
      group_id = @publish.recipient_id
    end
    logger.info "=======1111111111111111111===========#{group_id}"
    logger.info "=======2222222222222222222222===========#{@publish.id}"
    #@attempts = QuizAttempt.where(:quiz_id=>@quiz.id,:publish_id=>@publish.id).order("sumgrades DESC")
    #@all_first_attempts = QuizAttempt.find_by_sql("SELECT qa.*,ug.user_id FROM quiz_attempts qa INNER JOIN user_groups ug on qa.user_id=ug.user_id WHERE qa.quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND (qa.attempt=1) group by qa.user_id")
    @first_attempts = QuizAttempt.find_by_sql("SELECT qa.*,ug.user_id FROM quiz_attempts qa INNER JOIN user_groups ug on qa.user_id=ug.user_id WHERE qa.quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND ug.group_id=#{group_id} AND (qa.attempt=1) group by qa.user_id")
    @attempts = QuizAttempt.find_by_sql("SELECT qa.*,ug.user_id FROM quiz_attempts qa INNER JOIN user_groups ug on qa.user_id=ug.user_id WHERE qa.quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND (qa.attempt=1) group by qa.user_id")
    @other_group_attempts = QuizAttempt.find_by_sql("SELECT * FROM quiz_attempts qa1 WHERE quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND id NOT IN (SELECT qa.id FROM quiz_attempts qa INNER JOIN user_groups ug on qa.user_id=ug.user_id WHERE qa.quiz_id=#{@quiz.id} AND publish_id=#{@publish.id} AND ug.group_id=#{group_id})")
    @total_marks = @quiz.quiz_question_instances.sum(:grade)
    @g_attempts = @attempts.map(&:user_id)
    @user_in_group = QuizAttempt.find_by_sql("SELECT user_id FROM user_groups inner join users on users.id=user_groups.user_id WHERE group_id=#{group_id} and users.edutorid like 'ES-%'").map(&:user_id)
    @not_attempted = @user_in_group-@g_attempts
    if (@quiz.accessible(current_user.id, current_user.institution_id))
      respond_to do |format|
        format.html {render :layout=>false}
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    else
      respond_to do |format|
        format.html { redirect_to action: "index" }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
    end
  end





  def new_openformat_multiple_quiz
    @quiz = Quiz.new
    @action = 'create'
    if current_user.is?"EA"
      @boards = Board.all
    else
      @boards = get_boards
    end
    @quiz.build_context
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @quiz }
    end
  end

  def add_openformat_multiple_questions
    @quiz = Quiz.find(params[:id])
    @attachments = @quiz.assets.build
    if @quiz.format_type != 3
      redirect_to :action =>"edit_questions",:id=>@quiz.id
      return
    end

    respond_to do |format|
      format.html #{render "catchall_questions"}
      format.json { render json: @quiz }
    end
  end

  def submit_openformat_multiple_questions
    @quiz = Quiz.find(params[:id])
    if @quiz.format_type != 3
      redirect_to :action =>"edit_questions",:id=>@quiz.id
      return
    end
    if params[:quiz].present?
      @quiz.update_attributes(params[:quiz])
      logger.info"=============#{@quiz}"
      #@assets = @quiz.assets.create(params[:quiz])
      #@quiz_attachment = Asset.new(:attachment=>params[:asset][:attachment],:archive_type=>"Quiz",:archive_id=>@quiz.id)
      #@quiz_attachment.save!
      #path = @quiz_attachment.src
      #@quiz.update_attribute(:questions_file,path)
    end



    if params[:questions].present?
      ActiveRecord::Base.transaction do
        params[:questions].each do |p|

          q = Question.new
          q.section = p[:section]
          q.tag = p[:tag]
          q.page_no = p[:page_no]
          q.inpage_location = p[:inpage_location]
          q.difficulty = p[:difficulty]
          q.defaultmark = p[:marks]
          q.penalty = p[:penalty].to_i
          q.file = '/public'
          q.qtype = "multichoice" #hard coding the qtype for catch all questions
                                  #q.unset_defaults_flag
          q.save(:validate=>false)

          answers = p[:answer_tags].split(',')
          answer = p[:correct_answer].split(',')
          answers.each do |a|
            qa = QuestionAnswer.new
            qa.question = q.id
            qa.tag = a
            if answer.include? a
              qa.fraction = 1
            else
              qa.fraction = 0
            end
            qa.save(:validate=>false)
          end

          qqi = QuizQuestionInstance.new
          qqi.quiz_id = @quiz.id
          qqi.question_id = q.id
          qqi.grade = p[:marks]
          qqi.penalty = p[:penalty]
          qqi.save
        end
      end
    end

    redirect_to :action=>"show",:id=>@quiz.id
  end




  def create_message_openformat_multiple(type,quiz_id,publish_id)
    logger.info"=======#{quiz_id}"
    @quiz = Quiz.find(quiz_id)
    @publish = QuizTargetedGroup.find(publish_id)
    uri = create_uri(@quiz.context)
    messages = []
    if @quiz
      @quiz.assets.each do |q|
        logger.info"=============#{q.src}"
        @message = Message.new
        @message.sender_id = current_user.id
        if type
          @message.recipient_id = @publish.recipient_id
        else
          @message.group_id = @publish.group_id
        end
        @message.subject = @publish.subject
        @message.body = @publish.body+"$:#{uri}"
        @message.message_type = "Assessment"
        @message.severity = 10
        @message.label = @publish.subject
        @message.save!
        #images = []
        @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.testpaper(:id=>@quiz.id.to_s,:version=>"2.0",:publish_id=>@publish.id.to_s){
            xml.exam_format_type(:value=>"open_format")
            xml.test_password(:value=>(@publish.password.length > 0) ? @publish.password : "")
            xml.show_solutions_after(:value=>(@publish.show_answers_after).to_s)
            xml.show_score_after(:value=>(@publish.show_score_after).to_s)
            xml.pause(:value=>(@publish.pause) ? '1' : '0')
            xml.end_time(:value=>@publish.timeclose.to_i.to_s)
            xml.start_time(:value=>@publish.timeopen.to_i.to_s)
            xml.guidelines(:value=>@quiz.intro.to_s)
            xml.requisites(:value=>"")
            xml.examtype(:value=>"bitsat_mock")
            xml.evaluation_policy(:value=>false)
            xml.testpaper_source(:value=>q.attachment_file_name)
            if @quiz.timelimit > 0
              xml.examtime(:value=>@quiz.timelimit.to_s)
            else
              xml.examtime(:value=>"-1")
            end
            @quiz.questions.each do |question|
              qqi = QuizQuestionInstance.where(:quiz_id=>@quiz.id,:question_id=>question.id).first
              xml.question_set(:id=>question.id,:multi_answer=>false){
                xml.section_number{
                  xml.cdata question.section
                }
                xml.q_num{
                  xml.cdata question.tag
                }
                xml.qtype{
                  xml.cdata question.qtype
                }
                question.question_answers.each do |answer|
                  xml.option(:tag=>answer.tag,:answer=>answer.fraction? ? true : false, :id=>answer.id )
                end
                xml.score{
                  xml.cdata qqi.grade
                }
                xml.question_wrong_negative_score{
                  xml.cdata qqi.penalty
                }
                xml.question_subject{
                  xml.cdata @quiz.context.subject.name
                }
                xml.question_page_num{
                  xml.cdata question.page_no
                }
                xml.question_page_location{
                  xml.cdata question.inpage_location
                }

              }
            end
          }
        end

        xml_string =  @builder.to_xml.to_s
        #begin
        FileUtils.mkdir_p Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}"
        File.open(Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}/assessment_#{@message.id}.etx",  "w+b", 0644) do |f|
          #f.write(xml_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
          f.write(xml_string.to_s)
        end

        path = "/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}.zip"

        logger.info"=====================#{path}===path"
        #size = File.size(Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/"+ filename)
        #rescue Exception => e

        # Insert in assets


        @ncx = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|

          if (!@publish.extras.nil? and @publish.extras.index("homework"))and (@publish.get_assessment_ncx.eql?"practice-tests" or @publish.get_assessment_ncx.eql?"insti-tests" or @publish.get_assessment_ncx.eql?"Quiz")
            xml.navMap{
              xml.navPoint(:id=>"Curriculum",:class=>"curriculum"){
                xml.content(:src=>"curriculum")
                xml.navPoint(:id=>"Content",:class=>"content"){
                  xml.content(:src=>"content")
                  xml.navPoint(:id=>@quiz.context.board.name.to_s,:class=>"course"){
                    xml.content(:src=>"cb_02")
                    xml.navPoint(:id=>@quiz.context.content_year.name.to_s,:class=>"academic-class"){
                      xml.content(:src=>@quiz.context.content_year.name.to_s)
                      xml.navPoint(:id=>@quiz.context.subject.name.to_s,:class=>"subject"){
                        xml.content(:src=>@quiz.context.subject.code)
                        if @quiz.context.chapter_id == 0
                          #if @quiz.context.chapter_id == 0 and @quiz.context.topic_id == 0
                          xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                            xml.content(:src=>"/assessment_#{@message.id}.etx", :params=>@quiz.context.subject.params)
                          }
                        end
                        if @quiz.context.chapter_id > 0 and @quiz.context.topic_id == 0
                          xml.navPoint(:id=>@quiz.context.chapter.name,:class=>"chapter",:playOrder=>@quiz.context.chapter.play_order){
                            xml.content(:src=>@quiz.context.chapter.try(:assets).last.try(:src), :params=>@quiz.context.chapter.params)
                            xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                              xml.content(:src=>"/assessment_#{@message.id}.etx", :params=>@quiz.context.chapter.params)
                            }
                          }
                        end
                        if @quiz.context.chapter_id > 0 and @quiz.context.topic_id > 0
                          xml.navPoint(:id=>@quiz.context.chapter.name,:class=>"chapter",:playOrder=>@quiz.context.chapter.play_order){
                            xml.content(:src=>@quiz.context.chapter.assets.last.try(:src), :params=>@quiz.context.chapter.params)
                            xml.navPoint(:id=>@quiz.context.topic.name,:class=>"topic",:playOrder=>@quiz.context.topic.play_order){
                              xml.content(:src=>@quiz.context.topic.try(:assets).last.try(:src), :params=>@quiz.context.topic.params)
                              xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                                xml.content(:src=>"/assessment_#{@message.id}.etx",:params=>@quiz.context.topic.params)
                              }
                            }

                          }
                        end
                      }
                    }
                  }
                }
                xml.navPoint(:id=>"HomeWork",:class=>"home-work"){
                  xml.content(:src=>"homework")
                  xml.navPoint(:id=>@quiz.context.board.name.to_s,:class=>"course"){
                    xml.content(:src=>"cb_02")
                    xml.navPoint(:id=>@quiz.context.content_year.name.to_s,:class=>"academic-class"){
                      xml.content(:src=>@quiz.context.content_year.name.to_s)
                      xml.navPoint(:id=>@quiz.context.subject.name.to_s,:class=>"subject"){
                        xml.content(:src=>@quiz.context.subject.code)
                        if @quiz.context.chapter_id == 0 and @quiz.context.topic_id == 0
                          xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:submitTime=>@publish.timeclose.to_i*1000,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                            xml.content(:src=>"/assessment_#{@message.id}.etx")
                          }
                        end
                        if @quiz.context.chapter_id > 0 and @quiz.context.topic_id == 0
                          xml.navPoint(:id=>@quiz.context.chapter.name,:class=>"chapter"){
                            xml.content(:src=>@quiz.context.chapter.try(:assets).last.try(:src))
                            xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:prerequiste=>@quiz.context.chapter.uri,:submitTime=>@publish.timeclose.to_i*1000,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                              xml.content(:src=>"/assessment_#{@message.id}.etx")
                            }
                          }
                        end
                        if @quiz.context.chapter_id > 0 and @quiz.context.topic_id > 0
                          xml.navPoint(:id=>@quiz.context.chapter.name,:class=>"chapter"){
                            xml.content(:src=>@quiz.context.chapter.try(:assets).last.try(:src))
                            xml.navPoint(:id=>@quiz.context.topic.name,:class=>"topic"){
                              xml.content(:src=>@quiz.context.topic.try(:assets).last.try(:src))
                              xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:prerequiste=>@quiz.context.topic.uri,:submitTime=>@publish.timeclose.to_i*1000,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                                xml.content(:src=>"/assessment_#{@message.id}.etx")
                              }
                            }

                          }
                        end
                      }
                    }
                  }
                }
              }
            }
          else
            xml.navMap{
              xml.navPoint(:id=>"Curriculum",:class=>"curriculum"){
                xml.content(:src=>"curriculum")
                xml.navPoint(:id=>"Assessment",:class=>"assessment"){
                  xml.content(:src=>"assessments")
                  xml.navPoint(:id=>@quiz.context.board.name.to_s,:class=>"course"){
                    xml.content(:src=>"cb_02")
                    xml.navPoint(:id=>@quiz.context.content_year.name.to_s,:class=>"academic-class"){
                      xml.content(:src=>@quiz.context.content_year.name.to_s)
                      xml.navPoint(:id=>@publish.get_assessment_ncx,:class=>"assessment-category"){
                        xml.content(:src=>"practice")
                        xml.navPoint(:id=>@quiz.context.subject.name.to_s,:class=>"subject"){
                          xml.content(:src=>@quiz.context.subject.code)
                          if @quiz.context.chapter_id == 0 and @quiz.context.topic_id == 0
                            xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:submitTime=>@publish.timeclose.to_i*1000,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                              xml.content(:src=>"/assessment_#{@message.id}.etx")
                            }
                          end
                          if @quiz.context.chapter_id > 0 and @quiz.context.topic_id == 0
                            xml.navPoint(:id=>@quiz.context.chapter.name,:class=>"chapter"){
                              xml.content(:src=>@quiz.context.chapter.try(:assets).last.try(:src))
                              xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:prerequiste=>@quiz.context.subject.uri,:submitTime=>@publish.timeclose.to_i*1000,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                                xml.content(:src=>"/assessment_#{@message.id}.etx")
                              }
                            }
                          end
                          if @quiz.context.chapter_id > 0 and @quiz.context.topic_id > 0
                            xml.navPoint(:id=>@quiz.context.chapter.name,:class=>"chapter"){
                              xml.content(:src=>@quiz.context.chapter.try(:assets).last.try(:src))
                              xml.navPoint(:id=>@quiz.context.topic.name,:class=>"topic"){
                                xml.content(:src=>@quiz.context.topic.try(:assets).last.try(:src))
                                xml.navPoint(:id=>@quiz.name,:class=>"assessment-#{@publish.get_assessment_ncx}",:container_type => @publish.extras,:prerequiste=>@quiz.context.chapter.uri,:submitTime=>@publish.timeclose.to_i*1000,:passwd=>(@publish.password.length > 0) ? @publish.password : ""){
                                  xml.content(:src=>"/assessment_#{@message.id}.etx")
                                }
                              }

                            }
                          end
                        }
                      }
                    }
                  }
                }
              }
            }
          end
        end

        ncx_string =  @ncx.to_xml.to_s
        begin

          File.open(Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}/index.ncx",  "w+b", 0644) do |f|
            f.write(ncx_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
          end
          already_folders = []
          already_images = []
          @file_path = "/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}.zip"
          Zip::ZipFile.open(Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}.zip", Zip::ZipFile::CREATE) {
              |zipfile|
            zipfile.add("assessment_#{@message.id}.etx",Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}/assessment_#{@message.id}.etx")
            zipfile.add("index.ncx",Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}/index.ncx")
            if @quiz.format_type == 3
              if File.exist?(q.attachment.path)
                zipfile.add(q.attachment_file_name,q.attachment.path)
              end
            end
          }
          File.chmod(0644,Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}.zip")
          size = File.size(Rails.root.to_s+"/public/messages/"+current_user.id.to_s+"/#{@message.updated_at.to_s}/assessment_#{@message.id}.zip")
          #rescue Exception => e
          #  logger.info "2 BackTrace in creating assessment on-fly #{e.backtrace} "
          #  logger.info "2 Error Message in creating assessment on-fly #{e.message} "
          #end
          @assets = Asset.new
          @assets.archive_id = @message.id
          @assets.archive_type = 'Message'
          @assets.attachment_content_type = "application/zip"
          @assets.attachment_file_name = "assessment_#{@message.id}_#{q.attachment_file_name.to_s}.zip"
          @assets.attachment_file_size = 0
          @assets.created_at = @message.updated_at
          @assets.src = path.gsub("/messages/","/message_download/#{@message.id}/")
          @assets.message_id = @message.message_id
          @assets.attachment_file_size = size
          @assets.save
          OpenformatQuizFile.create(:quiz_id=>@quiz.id,:publish_id=>@publish.id,:file_path=>@file_path,:message_id=>@message.id,:test_code=>q.attachment_file_name.split('.')[0].to_s)
          MessageQuizTargetedGroup.create(:message_id=>@message.id,:quiz_targeted_group_id=>@publish.id)
          messages << @message.id
        end
      end
      if type
        message_id = messages.sample
        @test_code =  OpenformatQuizFile.find_by_message_id_and_publish_id(message_id,@publish.id)
        UserMessage.create(:user_id=>@publish.recipient_id,:message_id=>message_id)
        UserOpenformatQuizCode.create(:user_id=>@publish.recipient_id,:quiz_id=>@quiz.id,:publish_id=>@publish.id,:test_code=>@test_code.test_code,:message_id=>message_id,:openformat_quiz_file_id=>@test_code.id)
      else
        UserGroup.joins(:user).includes(:user).where(:group_id=>@publish.group_id).each do |user|
          message_id = messages.sample
          @test_code =  OpenformatQuizFile.find_by_message_id_and_publish_id(message_id,@publish.id)
          UserMessage.create(:user_id=>user.user_id,:message_id=>message_id)
          UserOpenformatQuizCode.create(:user_id=>user.user_id,:quiz_id=>@quiz.id,:publish_id=>@publish.id,:test_code=>@test_code.test_code,:message_id=>message_id,:openformat_quiz_file_id=>@test_code.id)
        end
      end
    end

  end

  def send_test_results_to_kumurans
    require 'net/http'
    @publish = QuizTargetedGroup.find(params[:id])
    @quiz =  @publish.quiz
    sql = "select min(id) as id from test_results where publish_id=#{@publish.id} and uid=#{@quiz.id} group by user_id"
    tids = TestResult.find_by_sql(sql).map(&:id)
    @results = TestResult.where(:id=>tids)
    #@results = TestResult.where(:uid=>@quiz.id,:publish_id=>@publish.id).group(:user_id)
    result = []
    @results.each do |r|
      attempt = []
      r.attempt.split(';').each do |a|
        if a.split('.')[1].to_i != 0
          attempt << QuestionAnswer.find(a.split('.')[1]).tag.upcase
        else
          attempt << 0
        end
      end
      logger.info"=======#{r.inspect}"
      code = UserOpenformatQuizCode.find_by_quiz_id_and_publish_id_and_user_id(r.uid,r.publish_id,r.user_id)
      if !code.nil?
        logger.info"======string==========#{r.user_id},#{code.test_code},#{attempt.join}"
        user = User.find(r.user_id)
        if !user.rollno.empty?
          result << ["#{user.rollno},#{code.test_code},#{attempt.join}"]
        end
        if @download
          download_result << [user.name,user.edutorid,"#{user.rollno},#{code.test_code},#{attempt.join}"]
        end
      end
    end

    data_string = ''
    l = ''
    result.each do |i|
      data_string = data_string+l
      data_string = data_string+i.join.to_s
      l = '~'
    end
    error_result = []
    correct_result = []
    logger.info"==========http://www.educationalinitiatives.com/detailed_assessment/edutor_response.php?Totalstudents=#{result.size}&data=#{data_string}========="
    result.each do |r|
      #request = Net::HTTP::Post.new("http://www.educationalinitiatives.com/detailed_assessment/edutor_response.php?Totalstudents=#{r.size}&data=#{append_string}")
      result = Net::HTTP.get(URI.parse("http://www.educationalinitiatives.com/detailed_assessment/edutor_responses.php?Totalstudents=1&data=#{r.join}"))
      logger.info"======#{result}"
      if result != "SUCCESS"
        error_result  << r
      else
        correct_result << r
      end
    end
    csv_data = FasterCSV.generate do |csv|
      #csv << ['string']
      csv << ['Data sent:']
      correct_result.each do |c|
        csv << c
      end
      if error_result.any?
        csv << ['Error in sending the following data:']
        error_result.each do |c|
          csv << c
        end
      end
    end
    file_name =  ("submited_result_of#{@quiz.name}#{Time.now.to_i}.csv").gsub(" ","").to_s
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"

  end


  def download_kumarans_da_results
    @publish = QuizTargetedGroup.find(params[:id])
    @quiz =  @publish.quiz
    sql = "select min(id) as id from test_results where publish_id=#{@publish.id} and uid=#{@quiz.id} group by user_id"
    tids = TestResult.find_by_sql(sql).map(&:id)
    @results = TestResult.where(:id=>tids)
    #@results = TestResult.where(:uid=>@quiz.id,:publish_id=>@publish.id).group(:user_id)
    result = []
    @results.each do |r|
      attempt = []
      r.attempt.split(';').each do |a|
        if a.split('.')[1].to_i != 0
          attempt << QuestionAnswer.find(a.split('.')[1]).tag
        else
          attempt << 0
        end
      end
      code = UserOpenformatQuizCode.find_by_quiz_id_and_publish_id_and_user_id(r.uid,r.publish_id,r.user_id)
      if !code.nil?
        user = User.find(r.user_id)
        if !user.rollno.empty?
          result <<  [user.name,user.edutorid,"#{user.rollno},#{code.test_code},#{attempt.join}"]
        end
      end
    end
    csv_data = FasterCSV.generate do |csv|
      csv << ['User','Edutorid','ResultString']
      result.each do |c|
        csv << c
      end
    end
    file_name =  ("Test_result_of_#{@quiz.name}#{Time.now.to_i}.csv").gsub(" ","").to_s
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{file_name}"
  end


  def down_submitted_options
    @publish = QuizTargetedGroup.find(params[:id])
    @quiz =  @publish.quiz
    #sql = "select min(id) as id from test_results where publish_id=#{@publish.id} and uid=#{@quiz.id} group by user_id"
    #tids = TestResult.find_by_sql(sql).map(&:id)
    #subq = " FROM (SELECT user_id,min(timefinish) AS timefinish FROM quiz_attempts WHERE publish_id=#{@publish_id} group by user_id) qa1 INNER JOIN quiz_attempts qa ON qa1.user_id=qa.user_id AND qa.timefinish=qa1.timefinish "
    #@results = TestResult.where(:id=>tids)
    ##@results = TestResult.where(:uid=>@quiz.id,:publish_id=>@publish.id).group(:user_id)
    #result = []
    #@results.each do |r|
    #  attempt = []
    #  r.attempt.split(';').each do |a|
    #    if a.split('.')[1].to_i != 0
    #      attempt << QuestionAnswer.find(a.split('.')[1]).tag
    #    else
    #      attempt << 0
    #    end
    #  end
    #  user =  User.find(r.user_id)
    #  result <<  [user.name,user.edutorid,attempt.join(',')]
    #subq = " FROM (SELECT id,user_id,min(timefinish) AS timefinish FROM quiz_attempts WHERE publish_id=#{@publish.id} group by user_id) qa1 INNER JOIN quiz_attempts qa ON qa1.user_id=qa.user_id AND qa.timefinish=qa1.timefinish "
    #sql = "SELECT qa1.id as quiz_attempt_id,u.id,u.edutorid AS edutorid,p.firstname AS name,q.tag as tag, q.id as questionid,qqa.id as quiz_question_attempt_id ,qqa.marks AS marks ,qa.timefinish AS time #{subq} INNER JOIN profiles p on qa.user_id=p.user_id INNER JOIN users u on u.id=qa.user_id inner join quiz_question_attempts qqa on qqa.quiz_attempt_id=qa.id INNER JOIN questions q on q.id = qqa.question_id WHERE qa.publish_id=#{@publish.id}"

    sql = "select min(id) as id from quiz_attempts where publish_id=#{@publish.id} and quiz_id=#{@quiz.id} group by user_id"
    aids = QuizAttempt.find_by_sql(sql).map(&:id)
    attempts = QuizAttempt.where(:id=>aids)
    all_attempts = []
    i = 1
    @attempts = []
    options = {0=>'A',1=>'B',2=>"C",3=>"D"}
    @question_ids = @quiz.questions.where("qtype != 'passage'").map(&:id).sort
    @questions = Question.where(:id=>@question_ids)
    @question_texts = @questions.collect{|q|q.questiontext.gsub(/<\/?[^>]*>/, "").gsub(',','').gsub(/#DASH#/, '_______')}
    @ans = @questions.map do |q|
      if q.qtype == 'multichoice' || q.qtype == 'truefalse'
        options[q.question_answer_ids.index(q.question_answers.where(:fraction => 1.0).first.id)]
      elsif q.qtype == 'fib'
        correct_answer = []
        q.question_fill_blanks.each do |b|
          if b.case_sensitive
            correct_answer << b.answer.split(',').join(' or ')
          else
            correct_answer << "#{b.answer.upcase.split(',').join(' or ')} (or) #{b.answer.downcase.split(',').join(' or ')}"
          end
        end
        correct_answer.join(' ')
      else
        nil
      end
    end
    @ans.compact!

    questions_count = @question_ids.count
    #if @quiz.format_type == 0
    attempts.each do |a|
      #marks =  a.collect{|i|  i.marks.to_f}
      ans = []
      a.quiz_question_attempts.order('question_id').each do |qqa|
        mcq_attempts =  McqQuestionAttempt.where(:quiz_question_attempt_id=>qqa.id)
        fib_attempts = FibQuestionAttempt.where(:quiz_question_attempt_id=>qqa.id)
        if mcq_attempts.empty? && fib_attempts.empty?
          ans << "NA"
        elsif fib_attempts.present?
          ans << qqa.fib_question_attempts.map(&:fib_question_answer).join(',')
        elsif mcq_attempts.first.question_answer_id == 0
          ans << "NA"
        else
          #qans = QuestionAnswer.find(mcq_attempts.first.question_answer_id)
          qans = QuestionAnswer.where(:id => mcq_attempts.map(&:question_answer_id))
          answer_ids = Question.find(qans.first.question).question_answer_ids
          options_select = mcq_attempts.map{|i| options[answer_ids.index(i.question_answer_id)]}
          ans << options_select.join(',')
          #question_answer = Question.find(qans.question).question_answer_ids.index(mcq_attempts.first.question_answer_id)
          #ans << options[question_answer]
        end
      end
      user = User.includes(:academic_class,:section).find(a.user_id)
      @attempts << [user.name,user.edutorid]+ans+[a.sumgrades.to_i]
    end

    csv_data = FasterCSV.generate do |csv|
      csv << "User,Edutorid,#{@question_ids.join(',')},Marks".split(',')
      #csv << " '','',#{[1..@question_ids.count]} "
      csv << " '','',#{@ans.join(',')}".split(',')
      csv << " '','',#{@question_texts.join(',')}".split(',')
      @attempts.uniq.each do |c|
        csv << c
      end
    end
    file_name =  ("Test_options_of_#{@quiz.name}_#{@publish.id}_#{Time.now.to_i}.csv").gsub(" ","").to_s
    send_data csv_data, :type => 'text/csv;', :disposition => "attachment; filename=#{file_name}"
  end



  def get_quiz_message
    @message = Message.find(params[:message_id])
    @quiz = Quiz.find(params[:quiz_id])
    @publish = QuizTargetedGroup.find(params[:publish_id])
    if current_user
      @code  = UserOpenformatQuizCode.find_by_message_id_and_quiz_id_and_publish_id_and_user_id(@message.id,@quiz.id,@publish.id,current_user.id)
      if @code.nil?
        @test_code =  OpenformatQuizFile.find(@publish.openformat_quiz_files.map(&:id).sample)
        UserOpenformatQuizCode.create(:user_id=>current_user.id,:quiz_id=>@quiz.id,:publish_id=>@publish.id,:test_code=>@test_code.test_code,:message_id=>@message.id,:openformat_quiz_file_id=>@test_code.id)
        send_file Rails.root.to_s+'/public'+@test_code.file_path,:disposition=>'inline',:type=>'application/zip'
      else
        #@test_code =  OpenformatQuizFile.find(@code.)
        send_file Rails.root.to_s+'/public'+@code.openformat_quiz_file.file_path,:disposition=>'inline',:type=>'application/zip'
      end
    else
      render :status=>404
      return
    end

  end

  def practice_assessments
    if current_user.institution_id
      @quizzes =  Quiz.includes(:quiz_targeted_groups,:quiz_attempts=>[:user]).where("users.institution_id=#{current_user.institution_id} AND quiz_targeted_groups.extras='practice' AND format_type != 7 ").page(params[:page])
    end
  end


  def show_practice_assessment
    @quiz =  Quiz.find(params[:id])
    @total_marks = @quiz.quiz_question_instances.sum(:grade)
    #@attempts = QuizAttempt.find_by_sql("SELECT qa.*,ug.user_id FROM quiz_attempts qa INNER JOIN users ug on qa.user_id=ug.id WHERE ug.institution_id=#{current_user.institution_id}")
    @attempts = QuizAttempt.includes(:user).where("users.institution_id=#{current_user.institution_id} AND quiz_id=#{@quiz.id}")
  end

  def user_tab_correction_DA

  end

  def post_user_tab_correction_DA
    logger.info"--- #{params[:openformat_quiz_file]}"
    @valid_users = []
    @invalid_users = []
    @users = User.where(:id=>params[:openformat_quiz_file][:student_ids].split(','))
    @publish_id = QuizTargetedGroup.find_by_id(params[:openformat_quiz_file][:test_id])
    if @publish_id.nil?
      flash[:error] = "Please Enter correct test-id"
      redirect_to tab_correction_path
      #render action: "user_tab_correction_DA"
      return
    end

    if @publish_id.quiz.format_type == 3
      @users.each do |u|
        if u.group_ids.include?(@publish_id.group_id)
          f = OpenformatQuizFile.where(:publish_id => @publish_id.id).first
          UserOpenformatQuizCode.where(:user_id=> u.id,:publish_id=> @publish_id.id).update_all(:message_id=> f.message_id,:test_code=> f.test_code,:openformat_quiz_file_id=> f.id)

          @valid_users << u.edutorid
        else
          @invalid_users << u.edutorid
        end
      end
      if !@invalid_users.empty?
        flash[:error] = "Following users didn't take this test #{@invalid_users.join(',')}"
      end
      flash[:notice] = "Following users test details updated successfully #{@valid_users.join(',')}"
      redirect_to tab_correction_path
      #render action:  "user_tab_correction_DA"
      return
    else
      flash[:error] = "Test-id entered is not DA test"
      redirect_to tab_correction_path
      #render action:  "user_tab_correction_DA"
      return
    end
  end



end


