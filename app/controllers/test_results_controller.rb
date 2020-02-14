class TestResultsController < ApplicationController
  authorize_resource :only=>[:edit, :index, :new, :show]
  #caches_action :index
  skip_before_filter :authenticate_user!, :only=>[:get_class_scores,:get_service_tab_results]
  def index
    @test_results = TestResult.page(params[:page])
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @test_results }
    end
  end

  def test_results
    @test_results = get_results(params[:test_config_id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @test_results }
    end
  end


  def get_results(test_conf)
    @test_configuration = TestConfiguration.find(test_conf)
    tc_end_time = Time.at(@test_configuration.end_time).to_i rescue nil
    if @test_configuration.is_practice_test?
      @test_results = TestResult.joins(:user=>:user_groups).where('uri = ? and submission_time <= ? and (user_groups.group_id=? or test_results.user_id=?)',@test_configuration.uri,tc_end_time,@test_configuration.group_id,@test_configuration.group_id).group('test_results.user_id').order('submission_time desc,marks desc').page(params[:page])
      #@test_results = TestResult.where('uri = ? and submission_time <= ?',@test_configuration.uri,tc_end_time).group('test_results.user_id desc').joins(:user=>:user_groups).where('user_groups.group_id=?',@test_configuration.group_id).order('submission_time desc,marks desc').page(params[:page])
    else
      @test_results = TestResult.joins(:user=>:user_groups).where('uri = ? and submission_time <= ? and (user_groups.group_id=? or test_results.user_id=?)',@test_configuration.uri,tc_end_time,@test_configuration.group_id,@test_configuration.group_id).group('test_results.user_id').order('submission_time desc,marks desc').page(params[:page])
      #@test_results = TestResult.where('uri = ? and submission_time <= ?',@test_configuration.uri,tc_end_time).group('test_results.user_id desc').joins(:user=>:user_groups).where('user_groups.group_id=?',@test_configuration.group_id).order('submission_time desc,marks desc').page(params[:page])
    end

  end

  def download_csv
    results = get_results(params[:test_config_id])
    filename ="test_results_#{Date.today.strftime('%d%b%y')}"
    csv_data = FasterCSV.generate do |csv|
      csv << TestResult.csv_header
      results.each do |c|
        csv << c.to_csv
      end
    end
    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present', :disposition => "attachment; filename=#{filename}.csv"
  end


  # GET /test_results/1
  # GET /test_results/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @test_result }
    end
  end

  # GET /test_results/new
  # GET /test_results/new.json
  def new
    @test_result = TestResult.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @test_result }
    end
  end

  # GET /test_results/1/edit
  def edit

  end

  def get_service_tab_results
    attempt_result_ids = []
    string = request.body.read
    results =  ActiveSupport::JSON.decode(string)
    results.each do |result|
      attempt_result_ids <<  get_attempts_from_tab(result)
    end
    @uresponse = {}
    respond_to do |format|
      @uresponse['success'] = true
      @uresponse.merge({:ids=>attempt_result_ids})
      format.json { render json: @uresponse }
      #return
    end
  end

  # POST /test_results
  # POST /test_results.json
  def create
    @result = {}
    test_result_ids = []
    string = request.body.read
    # string attempt format --------------------------------------------
    # question_id.selected_option_id for mcq/tf
    # question_id.[ans1, ans2] for fib
    # question_id.0 if not answered for mcq/tf
    # question_id.[] if not answered for fib
    # -------------------------------------------------------------------

    #string = '{"attempt":"21423.81669;21424.81673;21425.81677;21426.81681;21427.81685;21428.81689;21429.81693;21430.81697;21431.81700;21432.;21433.81708;21434.81712;21435.81716;21436.81720;21437.;","attempt_order":"21423.1339853769;21424.1339853769;21425.1339853770;21426.1339853770;21427.1339853771;21428.1339853771;21429.1339853772;21430.1339853772;21431.1339853772;21432.1339853773;21433.1339853773;21434.1339853773;21435.1339853774;21436.1339853774;21437.0;","extras1":"0","uri":"/Curriculum/Assessment/meridian/9th Class/practice-tests/Mathematics/Number Systems/Practice Test 1","uid":"2266","time_taken_per_question":"21423.2;21424.1;21425.1;21426.1;21427.1;21428.1;21429.1;21430.1;21431.1;21432.1;21433.1;21434.1;21435.1;21436.1;21437.1;","play_order":"1.21423;2.21424;3.21425;4.21426;5.21427;6.21428;7.21429;8.21430;9.21431;10.21432;11.21433;12.21434;13.21435;14.21436;15.21437;","test_type":"assessment-practice-tests","user_id":2390,"version_number":2.0,"submission_time":1339853776,"marks":5.0,"percentage":33.0}'
    #string = "[{uid:6,publish_id:4,user_id:'1',start_time:'',end_time:'',attempt:'1.4;2.3',time_taken:'1.3;4.6',attempted_at:'1.3456;3.5678',question_appearance_order:'1,3,5'}]"
    #string = '[{"version_number":"2.0","uid":"6","publish_id":"7","user_id":"1","submission_time":"1339853776","attempt":"15.10;16.14;21.24","time_taken_per_question":"15.10;16.5;21.20","attempt_order":"15.1339853769;21.1339853900;16.1339854200","play_order":"1.15;2.21;3.16"}]'
    results =  ActiveSupport::JSON.decode(string)
    puts "=========================Request from Tablet========================="
    #json hash from tablet [{"archive_id"=>"0", "attempt"=>"", "content_id"=>"/educhip/curriculum/tests/02_cb/10/practice/ma/10_cb_ma_1.xml", "display_name"=>"Some Applications of Trigonometry", "test_type"=>"1", "submission_time"=>"10 Feb 2012 11:35:47 GMT", "marks"=>0.0, "percentage"=>0.0, "user_id"=>24},            {"archive_id"=>"0", "attempt"=>"1.C;8.B,C;9.C;11.B,C;12.C,D;13.C;14.C", "content_id"=>"/educhip/curriculum/tests/02_cb/9/practice/ma/cb_9_Maths_2_1.xml", "display_name"=>"Polynomials", "test_type"=>"1", "submission_time"=>"10 Feb 2012 11:35:47 GMT", "marks"=>3.0, "percentage"=>21.0, "user_id"=>24}]
    logger.info "Result size #{results.length}----------------------------------."
    results.each do |result|
      # for tests on fly creation.
      begin
        # checking for version older version=1.0 and previous
        if !result['uri'].blank? and (!result['version_number'].present? or result['version_number'].to_s.eql?('1.0'))
          test_type = get_test_type(result['test_type'])
          user = User.find(result['user_id']) rescue nil


          #checking if assessment exists in all assessment types if not in Assessment type also
          #assessment = test_type.constantize.where('uri =?',result['uri'])
          #assessment = Assessment.where('uri =?',result['uri']) if assessment.empty?
          assessment = Content.assessment_types.where(:uri=>result['uri'])   #checking the uri in the whole contents table instead of type

          teacher_for_user = find_teacher_by_user_section_board_and_subject_uri(user,result['uri'],assessment.try(:first))
          teacher_for_user||=user.center.try(:center_admins).try(:first).try(:id) #if no teacher then center is assigned


          unless result['test_type'].eql?'assessment-quiz' #skip creating of assessment and test config if test-type is assessment-quiz and save only testresults.
            if assessment.empty?
              board = user.section.boards.try(:first) rescue nil
              if board.nil? # if board from user section is nil then parsing uri to get the board by board name in the uri
                board = Board.find_by_name(uri.split('/')[3]) rescue nil
              end
              new_assessment = test_type.constantize.new(:name=>result['uri'].split('/').last,
                                                         :board_id=>board.try(:id),
                                                         :content_year_id=>get_ac_class_from_uri(board,result['uri']),
                                                         :subject_id=>get_subject_from_uri(board,result['uri']),
                                                         :type=>test_type,
                                                         :uri=>result['uri'],
                                                         :assessment_type=>(result['test_type'].split('assessment-')[1]),
                                                         :status=>4)

              puts "CREATING ON FLY ASSESSMENT============== #{new_assessment.errors.full_messages}"

              new_assessment.build_asset
              new_assessment.asset.attachment =  File.open("#{Rails.root.to_s}/readme.doc","rb")
              new_assessment.asset.publisher_id = teacher_for_user
              new_assessment.save

              assessment = [new_assessment]
            end

            #creating of test configuration
            unless assessment.empty?
              check_test_config_with_user = TestConfiguration.find_by_content_id_and_uri_and_group_id(assessment.try(:first).try(:id),assessment.try(:first).try(:uri),user.try(:id))
              #checking the test configs as if test config is already created for him individually
              if check_test_config_with_user.nil?
                TestConfiguration.find_or_create_by_content_id_and_uri_and_group_id(assessment.try(:first).try(:id),assessment.try(:first).try(:uri),user.try(:section).try(:id),:test_type=>result['uri'].split('/').last ,:created_by=>teacher_for_user,:start_time=>Time.now.beginning_of_day,:end_time=>Time.now.beginning_of_day+15.day,:status=>2,:published=>1)
              end
            end
          end
          if result['extras1'] == 0
            result['extras1'] = nil
          end
          #inserting the test results
          test_result_present = TestResult.where(result)
          if !test_result_present.nil?
            test_result = TestResult.new(result)
            if test_result.save
              logger.info "Test results was successfully created."
            else
              logger.info "Errors in creating test result: #{test_result.errors.full_messages}"
            end
            test_result_ids << result['uid'].to_s+'$$'+result['submission_time'].to_s
          end
        elsif !result['uri'].blank? and result['version_number'].present? and result['version_number'].to_s.eql?('2.0')
          logger.info "Running get attemt------------------------------------------ "
          test_result_ids << get_attempts_from_tab(result)
          @result_present = TestResult.where(result)
          if !@result_present.nil?
            @test_result = TestResult.new(result)
            if @test_result.save
              logger.info "Test results was successfully created."
            else
              logger.info "Errors in creating test result: NO URI RECEIVED FROM TABLET FOR TEST RESULT"
            end
            test_result_ids << result['uid'].to_s+'$$'+result['submission_time'].to_s
          end
          logger.info"===================#{test_result_ids}"
        end

        #@result_present = TestResult.where(result)
        #if !@result_present.nil?
        #  @test_result = TestResult.new(result)
        #  if @test_result.save
        #    logger.info "Test results was successfully created."
        #  else
        #    logger.info "Errors in creating test result: NO URI RECEIVED FROM TABLET FOR TEST RESULT"
        #  end
        #  test_result_ids << result['uid'].to_s+'$$'+result['submission_time'].to_s
        #end
      rescue Exception => e
        logger.info "Exception in creating assessment on-fly #{e} "
        logger.info "BackTrace in creating assessment on-fly #{e.backtrace} "
        logger.info "Error Message in creating assessment on-fly #{e.message} "
        TestResult.create(result)
      # test_result_ids << result['uid'].to_s+'$$'+result['submission_time'].to_s
      end

    end
    test_result_ids = test_result_ids - [nil]
    logger.info"============#{test_result_ids}"
    respond_to do |format|
      format.json { render json: test_result_ids }
    end

  end


  def test_reports
    test_type = get_test_type(params[:type])
    assessment_type = params[:type].split('-')[1] rescue ""
    assessments = request.xhr? ? current_user.assessments.where('type like ? or assessment_type like ? or name like ? or extras like ?',"%#{test_type}%","%#{assessment_type}%","%#{assessment_type}%","%#{assessment_type}%") :  current_user.assessments
    #test_config_ids = assessments.map{|assessment|assessment.test_configurations.where('group_id IN (?)',current_user.get_groups).map(&:id) }

    unless params[:user_id].present? # for all users
                                     #getting the test-configs by section i.e group_id
      @all_test_configs = params[:group_id].present? ? current_user.test_configurations_by_assessments(assessments.map(&:id)).where(:group_id=>params[:group_id]) : current_user.test_configurations_by_assessments(assessments.map(&:id))
      all_user_ids =[]
      @all_test_configs.each do |test_config|
        unless test_config.group.type.nil?
          all_user_ids << test_config.group.students.map(&:id)
        else
          all_user_ids << test_config.group.id
        end
      end

      all_user_ids.flatten!
      all_user_ids.uniq!
      @all_users = User.includes(:profile).select('users.id,users.type,profiles.firstname').where(:id=>all_user_ids).page(params[:page])
    else # for specific user
      @all_test_configs = current_user.test_configurations_by_assessments(assessments.map(&:id))
      all_user_ids =[]
      @all_test_configs.each do |test_config|
        unless test_config.group.type.nil?
          all_user_ids << test_config.group.students.where(:id=>params[:user_id]).map(&:id)  #test_configs posted to groups i.e here group is section
        else
          all_user_ids << test_config.group.try(:id) if test_config.group.try(:id)== params[:user_id].to_i #test_configs posted to individuals i.e here group is user
        end
      end
      @all_users = User.includes(:profile).select('users.id,users.type,profiles.firstname').where(:id=>all_user_ids).page(params[:page])
    end

    if request.xhr?
      respond_to do |format|
        format.js
      end

    end
  end

  # PUT /test_results/1
  # PUT /test_results/1.json
  def update
    respond_to do |format|
      if @test_result.update_attributes(params[:test_result])
        format.html { redirect_to @test_result, notice: 'Test configuration was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @test_result.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /test_results/1
  # DELETE /test_results/1.json
  def destroy
    @test_result.update_attribute('status',3)
    respond_to do |format|
      format.html { redirect_to test_results_url }
      format.json { head :ok }
    end
  end

  def get_class_scores
    if params[:user_id] and params[:device_id] and params[:content_id]
      user = User.find(params[:user_id])  rescue nil
      test_result = []
      if user and !user.academic_class.nil?
        test_result = TestResult.find_all_by_user_id_and_rank_status(user.academic_class.students,true)
      end
      #if params[:user_id].blank? or params[:device_id].blank? or test_result.empty?
      if params[:user_id].blank? or params[:device_id].blank?
        @result =  {status: :unprocessable_entity ,message: "Failed to get class scores."}
      else
        #@result = Hash[class_avg: test_result.sum(:percentage).to_f,topper_score: test_result.maximum(:percentage).to_f,my_score: TestResult.find_by_user_id(params[:user_id]).percentage.to_f]
        @result = Hash[class_avg: 100.0,topper_score: 20.0,my_score: 10.0]
      end
    end

    respond_to do |format|
      format.json {render json: @result}
    end
  end

  # protected
  def find_test_result
    @test_result = TestResult.find(params[:id])
  end

  def get_subject_from_uri(board,uri)
    subject_name = uri.split('/')[6] rescue ""
    puts "SUBJECT NAME #{subject_name}"
    content_year = get_ac_class_from_uri(board,uri)
    Subject.where(:board_id=>board, :content_year_id=>content_year,:name=>subject_name).try(:first).try(:id)
  end

  def get_ac_class_from_uri(board,uri)
    year_name = uri.split("/")[4] rescue ""
    puts "Year NAME #{year_name}"
    ContentYear.where(:board_id=>board,:name=>year_name).try(:first).try(:id)
  end


  def find_teacher_by_user_section_board_and_subject_uri(user,uri,assessment)
    board = assessment.try(:board) || user.section.boards.try(:first)
    if board.nil? # if board from user section is nil then parsing uri to get the board by board name in the uri
      board = Board.find_by_name(uri.split('/')[3]) rescue nil
    end
    content_id = assessment.try(:subject_id) || get_subject_from_uri(board,uri)
    subject_teachers = ClassRoom.where(:teacher_id=>user.section.teachers.map(&:id),:content_id=>content_id)
    puts subject_teachers.inspect,"SUBJECT TEACHERS======================="
    teacher = nil
    if subject_teachers.empty?
      puts "Assigned to class teacher"
      content_year_id = assessment.try(:content_year_id) || get_ac_class_from_uri(board,uri)
      teacher = ClassRoom.where(:teacher_id=>user.section.teachers.map(&:id),:content_id=>content_year_id).try(:first).try(:teacher_id)
    else
      puts "Assigned to subject teacher"
      teacher = subject_teachers.try(:first).try(:teacher_id)
    end
    teacher
  end

  def get_test_type(test_type)
    case test_type
      when 'assessment-insti-tests'
        "AssessmentInstiTest"
      when 'assessment-practice-tests'
        "AssessmentPracticeTest"
      when 'assessment-home-work'
        "AssessmentHomeWork"
      when 'assessment-inclass'
        "AssessmentInclass"
      when 'assessment-olympiad'
        "AssessmentOlympiad"
      when 'assessment-iit'
        "AssessmentIit"
      else
        "Assessment"
    end
  end

  def remove_last_name_from_uri(uri)
    split_ary = uri.split('/')
    after_delete_last_name_arry = split_ary.pop
    split_ary.join('/')
  end

  # New method to take input from tabs for version =2.0
  def get_attempts_from_tab(result)
    attempt_result_id= nil
    begin
      # string attempt format --------------------------------------------
      # question_id.selected_option_id for mcq/tf
      # question_id.[ans1, ans2] for fib
      # question_id.0 if not answered for mcq/tf
      # question_id.[] if not answered for fib
      # -------------------------------------------------------------------
      
      #string = request.body.read
      #string = '[{edit:"Paused",uid:"6",publish_id:"7",user_id:"1",submission_time:"1339853776",attempt:"15.10;16.14;21.24",time_taken_per_question:"15.10;16.5;21.20",attempt_order:"15.1339853769;21.1339853900;16.1339854200",play_order:"1.15;2.21;3.16"}]'
      #string = '{"attempt":"21423.81669,81698;21424.81673;21425.81677;21426.81681;21427.81685;21428.81689;21429.81693;21430.81697;21431.81700;21432.;21433.81708;21434.81712;21435.81716;21436.81720;21437.;","attempt_order":"21423.1339853769;21424.1339853769;21425.1339853770;21426.1339853770;21427.1339853771;21428.1339853771;21429.1339853772;21430.1339853772;21431.1339853772;21432.1339853773;21433.1339853773;21434.1339853773;21435.1339853774;21436.1339853774;21437.0;","extras1":"0","uri":"/Curriculum/Assessment/meridian/9th Class/practice-tests/Mathematics/Number Systems/Practice Test 1","uid":"2266","time_taken_per_question":"21423.2;21424.1;21425.1;21426.1;21427.1;21428.1;21429.1;21430.1;21431.1;21432.1;21433.1;21434.1;21435.1;21436.1;21437.1;","play_order":"1.21423;2.21424;3.21425;4.21426;5.21427;6.21428;7.21429;8.21430;9.21431;10.21432;11.21433;12.21434;13.21435;14.21436;15.21437;","test_type":"assessment-practice-tests","user_id":2390,"version_number":2.0,"submission_time":1339853776,"marks":5.0,"percentage":33.0}'
      #result =  ActiveSupport::JSON.decode(string)
      #logger.debug(result.inspect)
      #attempts =  ActiveSupport::JSON.decode(string)
      #.strip
      #attempts = {}
      #attempts[0] = 1
      #attempts.each do |attempt|
      log_error("Assessment","test_user_results",(result['uid'].to_s+';'+result['user_id'].to_s+';'+result['marks'].to_s).to_s)
      if !result['edit'].nil? && result['edit'].to_s == "Paused"
        return
      end
      quiz_id = result['uid']
      publish_id = result['publish_id']
      if publish_id.blank? || publish_id.nil?
        publish = QuizTargetedGroup.find_last_by_quiz_id(quiz_id)
        publish_id = publish.try(:id)
      end
      #edutor_id = 'EA-001'
      user_id = result['user_id']
      timestart = 0
      timefinish = result['submission_time']

      #@quiz = Quiz.where(:id=>quiz_id).first
      @quiz = Quiz.includes(:quiz_question_instances).find(quiz_id)
      if !@quiz
        log_error("Assessment_id #{quiz_id} does not exist","test_results",result.to_s)
        return
      end

      #@user = User.where("edutorid = ?",edutor_id).first
      @user = User.find(user_id)
      if !@user
        log_error("User #{user_id} does not exist","test_results",result.to_s)
        return
      end

      quiz_a = QuizAttempt.where(:quiz_id=>@quiz.id,:publish_id=>publish_id,:user_id=>@user.id,:timefinish=>timefinish)
      if !quiz_a.empty?
        attempt_result_id = result['uid'].to_s+'$$'+result['submission_time'].to_s
        return attempt_result_id
      end

      prev_quiz_attempt = QuizAttempt.find_by_sql("SELECT max(attempt) as m FROM quiz_attempts WHERE publish_id=#{publish_id} AND quiz_id=#{@quiz.id} AND user_id=#{@user.id}")
      @attempt_no = 1
      if prev_quiz_attempt.size > 0 && !prev_quiz_attempt.first.m.nil?
        @attempt_no = prev_quiz_attempt.first.m+1
      end
      ActiveRecord::Base.transaction do
        @quiz.increment!(:attempts)
        @quiz_attempt = QuizAttempt.new
        @quiz_attempt.quiz_id = quiz_id
        @quiz_attempt.publish_id = publish_id
        @quiz_attempt.user_id = @user.id
        @quiz_attempt.attempt = @attempt_no
        @quiz_attempt.timestart = timestart
        @quiz_attempt.timefinish = timefinish
        @quiz_attempt.save

        @quiz_publish_instance = QuizTargetedGroup.find(publish_id)
        @quiz_publish_instance.increment!(:total_attempts)

        question_data = {}
        attempt_data = {}
        time_taken_data = {}
        attempt_order_data = {}
        play_order_data = {}
        #question_data[:questions] = {}
        #question_data[0] =0
        #q_attempts = '15.10;16.14;21.24'
        @total_attempts = 0
        q_attempts = result['attempt']
        q_attempts = q_attempts.split(';')
        q_attempts.each do |qa|
          @total_attempts = @total_attempts + 1
          qaa = qa.split('.')
          question_id = qaa[0].to_i
          if qaa[1].match(']') or qaa[1].match('\[')
            #option_id = qaa[1]
            option_id = qa.gsub(qaa[0]+'.','')
          else
            option_id = qaa[1].split(',')
          end
          #option_id = qaa[1].to_i
          #option_id.delete_at 0
          attempt_data[question_id] = option_id
          #option_ids = qaa[1].split(',')
          #attempt_data[question_id] = option_ids
        end
        log_error("attempt_data","test_results",attempt_data.inspect)

        #q_time_taken = '15.10;16.5;21.20'
        q_time_taken = result['time_taken_per_question']
        q_time_taken = q_time_taken.split(';')
        if q_time_taken.length !=0
          q_time_taken.each do |qt|
            qtt = qt.split('.')
            question_id = qtt[0].to_i
            time_taken = qtt[1].to_i
            time_taken_data[question_id] = time_taken
          end
        end
        log_error("time_taken_data","test_results",time_taken_data.inspect)

        #q_attempted_at = '15.1338201587;16.1338201587;21.1338201587'
        q_attempted_at = result['attempt_order']
        q_attempted_at = q_attempted_at.split(';')
        q_attempted_at.each do |qat|
          qatt = qat.split('.')
          question_id = qatt[0].to_i
          attempted_at = qatt[1].to_i
          attempt_order_data[question_id] = attempted_at
        end
        log_error("attempt_order_data","test_results",attempt_order_data.inspect)

        #q_app_order = '16,15,21'
        if result['test_type'] !='bitsat_mock' && result['test_type'] !='open_format'
          q_app_order = result['play_order']
          q_app_order = q_app_order.split(';')
          q_app_order.each do |v|
            vo = v.split('.')
            play_order_data[vo[1].to_i] = vo[0].to_i
          end
          log_error("play_order_data","test_results",play_order_data.inspect)
        end

        @total_marks = 0
        attempt_data.each do |key,value|
          #if @quiz.quiz_question_instances.map(&:question_id).include? key
          @quiz_question_attempt = QuizQuestionAttempt.new
          @quiz_question_attempt.quiz_id = @quiz.id
          @quiz_question_attempt.quiz_attempt_id = @quiz_attempt.id
          @quiz_question_attempt.question_id = key
          @quiz_question_attempt.user_id = @user.id

          if result['test_type'] =='bitsat_mock' || result['test_type'] =='open_format'
            @quiz_question_attempt.appearance_order = key
          else
            @quiz_question_attempt.appearance_order = play_order_data[key] ? play_order_data[key] :'empty'
          end

          @quiz_question_attempt.time_taken = time_taken_data[key].nil? ? 0 : time_taken_data[key]
          @quiz_question_attempt.attempted_at = attempt_order_data[key]
          @question = Question.includes(:question_answers,:question_fill_blanks).find(key)
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

            if value.length ==1 && value[0] == "0"
              logger.info "value length"
              @quiz_question_attempt.correct = false
              @quiz_question_attempt.marks = 0
            end

            #@question_answer = @question.question_answers.where("question_answers.id = ?",value).first
            #@quiz_question_instance = @quiz.quiz_question_instances.where("question_id = ?",key).first
            #if @question_answer && @question_answer.fraction == 1
            # @quiz_question_attempt.correct = true
            #@quiz_question_attempt.marks = @quiz_question_instance.grade
            #elsif @question_answer && @question_answer.fraction == 0
            # @quiz_question_attempt.correct = false
            # @quiz_question_attempt.marks = (- @quiz_question_instance.penalty)
            #else
            # @quiz_question_attempt.correct = false
            # @quiz_question_attempt.marks = 0
            #end

            #@question_answer = @question.question_answers.where(:id => value,:fraction =>1)
            #@quiz_question_instance = @quiz.quiz_question_instances.where("question_id = ?",key).first
            #if @question_answer.size > 0
            # @quiz_question_attempt.correct = true
            # @quiz_question_attempt.marks = @quiz_question_instance.grade
            #else
            # @quiz_question_attempt.correct = false
            # @quiz_question_attempt.marks = (- @quiz_question_instance.penalty)
            #end
            @quiz_question_attempt.save

            @total_marks = @total_marks + @quiz_question_attempt.marks
            @quiz_attempt.sumgrades = @total_marks
            @quiz_attempt.save

            value.each do |v|
              if v.to_i != 0
                @mcq_question_attempt = McqQuestionAttempt.new
                @mcq_question_attempt.quiz_question_attempt_id = @quiz_question_attempt.id
                @mcq_question_attempt.question_answer_id = v.to_i
                @mcq_question_attempt.selected = true
                @mcq_question_attempt.attempted_at = attempt_order_data[key]
                @mcq_question_attempt.save
              end
            end
            #if @question_answer
            # @mcq_question_attempt = McqQuestionAttempt.new
            #@mcq_question_attempt.quiz_question_attempt_id = @quiz_question_attempt.id
            #@mcq_question_attempt.question_answer_id = @question_answer.id
            #@mcq_question_attempt.selected = true
            #@mcq_question_attempt.attempted_at = attempt_order_data[key]
            #@mcq_question_attempt.save
            #end
          #end
          elsif @question.qtype =='fib'
            @quiz_question_attempt.qtype = @question.qtype
            @quiz_question_instance = @quiz.quiz_question_instances.where("question_id = ?",key).first
            @fill_blanks = @question.question_fill_blanks.collect{|i|[i.answer,i.case_sensitive]}
            f = 0
            @fill_marks = @quiz_question_instance.grade/@question.question_fill_blanks.count.to_f

            @result_marks = []
            logger.info"===========#{value}"
            JSON.load(value.to_s).each do |i|
              if @fill_blanks[f][1] # if case sensitive
                logger.info "===============#{i}"
                logger.info "===============#{@fill_blanks[f][0]}"
                if @fill_blanks[f][0].split(',').collect{|j|j.to_s.lstrip.rstrip}.include?(i.to_s.lstrip.rstrip)
                  @result_marks << @fill_marks
                end
              else # if not case sensitive
                if @fill_blanks[f][0].split(',').collect{|j|j.to_s.lstrip.rstrip.downcase}.include?(i.to_s.lstrip.rstrip.downcase)
                  @result_marks << @fill_marks
                end
              end
              f = f+1
            end
            if !@result_marks.empty?
              @quiz_question_attempt.correct = @question.question_fill_blanks.count == @result_marks.count ? true :false
              @quiz_question_attempt.marks =  @question.question_fill_blanks.count == @result_marks.count ? @quiz_question_instance.grade : @quiz_question_instance.penalty * -1
            else
              @quiz_question_attempt.correct = false
              @quiz_question_attempt.marks =  @quiz_question_instance.penalty * -1
            end

            if value == ["0"] or value == [] or value == "[]"
              @quiz_question_attempt.correct = false
              @quiz_question_attempt.marks = 0
            end

            @quiz_question_attempt.save

            @total_marks = @total_marks + @quiz_question_attempt.marks
            @quiz_attempt.sumgrades = @total_marks
            @quiz_attempt.save

            if value != ["0"] or value != "[]"
              JSON.load(value.to_s).each do |fib_attempted_answer|
                @fib_question_attempt = FibQuestionAttempt.new
                @fib_question_attempt.quiz_question_attempt_id = @quiz_question_attempt.id
                @fib_question_attempt.fib_question_answer = fib_attempted_answer
                @fib_question_attempt.selected = true
                @fib_question_attempt.attempted_at = attempt_order_data[key]
                @fib_question_attempt.save
              end
            else
                @fib_question_attempt = FibQuestionAttempt.new
                @fib_question_attempt.quiz_question_attempt_id = @quiz_question_attempt.id
                @fib_question_attempt.fib_question_answer = 0
                @fib_question_attempt.selected = false
                @fib_question_attempt.attempted_at = attempt_order_data[key]
                @fib_question_attempt.save
            end
          else
            @quiz_question_attempt.qtype = @question.qtype
            @quiz_question_attempt.correct = false
            @quiz_question_attempt.marks = 0
            @quiz_question_attempt.save
            @total_marks = @total_marks + @quiz_question_attempt.marks
            @quiz_attempt.sumgrades = @total_marks
            @quiz_attempt.save


          end
          #end
        end
        attempt_result_id = result['uid'].to_s+'$$'+result['submission_time'].to_s
        logger.info"=================#{attempt_result_id}"
      end
      #end
      if user_id.to_i == 7556 || user_id.to_i == 7126
        send_report(@quiz_attempt.id)
      end
      if @quiz_publish_instance.extras == "institute"  or  @quiz_publish_instance.assessment_type == 3
        send_results_acknowledgement(@quiz,@quiz_publish_instance,@user)
      end
    rescue Exception => e
      logger.info "Exception in getting assessment attempt on-fly #{e} "
      logger.info "BackTrace in gettting assessment attempt on-fly #{e.backtrace} "
      logger.info "Error Message in getting assessment attempt on-fly #{e.message} "
      log_error("#{e.message}","test_results",result.to_s)
    # attempt_result_id = result['uid'].to_s+'$$'+result['submission_time'].to_s
    end
    return attempt_result_id
  end

  def send_report(quiz_attempt_id)
    begin
      @quiz_attempt = QuizAttempt.where(:id=>quiz_attempt_id)
      @publish = QuizTargetedGroup.find(@quiz_attempt.first.publish_id)
      @question_attempts = QuizQuestionAttempt.where(:quiz_attempt_id=>quiz_attempt_id)
      @quiz = Quiz.includes(:quiz_question_instances).find(@question_attempts.first.quiz_id)
      @total_marks = @quiz.quiz_question_instances.sum(:grade)
      @user = @question_attempts.first.user
      @total = QuizAttempt.where(:publish_id=>@question_attempts.first.quiz_attempt.publish_id,:attempt=>1)
      @total_students = QuizAttempt.where(:publish_id=>@question_attempts.first.quiz_attempt.publish_id,:attempt=>1).map(&:user_id).uniq
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
      path = Rails.root.to_s+"/tmp/cache"
      file = File.new(path+"/"+"#{Time.now.to_i}_"+"#{@quiz.name}.pdf", "w+")
      File.open(file,'wb') do |f|
        f << pdf
      end
      @message = Message.new
      @message_asset = @message.assets.build
      @message_asset.attachment = File.open(file,"rb")
      @message.recipient_id = @user.id
      @message.sender_id = 1
      @message.message_type = "Report"
      @message.label =  "Report"
      @message.body =    "Assessment Report"
      @message.subject = "Assessment Report for #{@quiz.name}"
      @message.save
      UserMailer.send_test_report(quiz_attempt_id,pdf).deliver
    rescue Exception => e
      logger.info "Attempt for User:#{@user.id} could not be mailed successfully."
      return
    end
  end

  def send_results_acknowledgement(quiz,publish,user)
    begin
      message_text = "Attempt for #{quiz.name} posted to server successfully."
      @user_message = Message.new
      @user_message.sender_id = 1
      @user_message.subject = message_text
      @user_message.body = message_text
      @user_message.message_type = 'Alert'
      @user_message.severity = 1
      @user_message.label = ""
      @user_message.recipient_id = user.id
      @user_message.save
    rescue Exception => e
      logger.info "Attempt for Publish_id:#{publish.id} for User:#{user.edutorid} could not be posted to server successfully."
      return
    end
  end


  # Tab requesting the test results
  def get_test_results
    @user = User.find_by_id(params[:user_id])
    if @user and @user.test_results.any?
      @results = @user.test_results
    else
      @results = nil
    end
    respond_to do |format|
      format.json { render json: @results }
    end
  end



end
