class AssessmentToolController < ApplicationController
  require 'common_code'
  include CommonCode
  require 'redis_interact'
  before_filter :delete_old_tags, :only => [:independently_update_individual_question]
  after_filter :update_redis_server_after_question_updation, :only => :independently_update_individual_question
  after_filter :update_redis_server_after_question_creation, :only => [:create_and_add_individual_question, :create_and_add_passage_question, :create_and_add_multiple_questions]
  #after_filter :update_redis_server_after_question_removal_from_qb, :only => :remove_question
  def all_assessments
    unless (current_user.is? "ET") && (current_user.institution_id == 106509)
      cen = current_user.center_id
      ins = current_user.institution_id
      if cen
        @assessments = Quiz.where(:center_id => cen, :institution_id => ins).order("timemodified desc")  #.page(params[:page]).per(10)
      else
        @assessments = Quiz.where(:institution_id => ins ).order("timemodified desc")  #.page(params[:page]).per(10)
      end
      if current_user.is? "ECP"
        @assessments = Quiz.where(createdby:current_user.id).order("timemodified desc")
      end

      @tag_assessments = []
      @context_assessments = []
      @assessments.each do |a|
        if !a.context.nil?
          @context_assessments << a
        elsif !a.quiz_detail.nil?
          @tag_assessments << a
        end
      end
      if !@tag_assessments.nil?
        @tag_c = {}
        @tag_s = {}

        @tag_assessments.each do |t_a|
          begin
            @tag_c["t_#{Tag.find(t_a.quiz_detail.academic_class_tag_id).id}"] =  Tag.find(t_a.quiz_detail.academic_class_tag_id).value if t_a.quiz_detail.academic_class_tag_id
            @tag_s["t_#{Tag.find(t_a.quiz_detail.subject_tag_id).id}"] =  Tag.find(t_a.quiz_detail.subject_tag_id).value if t_a.quiz_detail.subject_tag_id
          rescue
            next
          end
        end
      end
      if !@context_assessments.nil?
        @a_context_c = {}
        @a_context_s = {}
        @context_assessments.each do |t_a|
          begin
            @a_context_c["c_#{t_a.context.content_year_id}"] =  ContentYear.find(t_a.context.content_year_id).name
            if t_a.context.chapter_id != 0
              @a_context_s["c_f_#{t_a.context.chapter_id}"] =  "#{ContentYear.find(t_a.context.content_year_id).name}__#{Subject.find(t_a.context.subject_id).name}__#{Chapter.find(t_a.context.chapter_id).name}"
            else
              @a_context_s["c_s_#{t_a.context.subject_id}"] =  "#{ContentYear.find(t_a.context.content_year_id).name}__#{Subject.find(t_a.context.subject_id).name}"
            end
            @a_context_s = Hash[@a_context_s.sort_by{|k, v| v}]
          rescue
            next
          end
        end

      end
      @assessments = Kaminari.paginate_array(@assessments).page(params[:page]).per(10)
    else
      redirect_to "/"
    end

  end

  def my_assessments
    cen = current_user.center_id
    ins = current_user.institution_id
    if cen
      @assessments = Quiz.where(:center_id => cen, :institution_id => ins, :createdby => current_user.id).order("timemodified desc")  #.page(params[:page]).per(10)
    else
      @assessments = Quiz.where(:institution_id => ins, :createdby => current_user.id).order("timemodified desc")   #.page(params[:page]).per(10)
    end
    if current_user.is? "ECP"
      @assessments = Quiz.where(createdby:current_user.id).order("timemodified desc")
    end

    @tag_assessments = []
    @context_assessments = []
    @assessments.each do |a|
      if !a.context.nil?
        @context_assessments << a
      elsif !a.quiz_detail.nil?
        @tag_assessments << a
      end
    end
    if !@tag_assessments.nil?
      @tag_c = {}
      @tag_s = {}
      @tag_assessments.each do |t_a|
        begin
          ##Double queries to database. Need to better the code while refactoring. NK
          @tag_c["t_#{Tag.find(t_a.quiz_detail.academic_class_tag_id).id}"] =  Tag.find(t_a.quiz_detail.academic_class_tag_id).value if t_a.quiz_detail.academic_class_tag_id
          @tag_s["t_#{Tag.find(t_a.quiz_detail.subject_tag_id).id}"] =  Tag.find(t_a.quiz_detail.subject_tag_id).value if t_a.quiz_detail.subject_tag_id
        rescue
          next
        end
      end
    end
    if !@context_assessments.nil?
      @a_context_c = {}
      @a_context_s = {}
      @context_assessments.each do |t_a|
        begin
          if t_a.context.content_year_id != 0
            if !Content.find_by_id(t_a.context.content_year_id).nil?
              @a_context_c["c_#{t_a.context.content_year_id}"] =  ContentYear.find(t_a.context.content_year_id).name
              if t_a.context.chapter_id != 0 and t_a.context.subject_id !=0
                @a_context_s["c_f_#{t_a.context.chapter_id}"] =  "#{ContentYear.find(t_a.context.content_year_id).name}__#{Subject.find(t_a.context.subject_id).name}__#{Chapter.find(t_a.context.chapter_id).name}"
              elsif t_a.context.subject_id !=0 and !t_a.context.subject_id.nil?
                @a_context_s["c_s_#{t_a.context.subject_id}"] =  "#{ContentYear.find(t_a.context.content_year_id).name}__#{Subject.find(t_a.context.subject_id).name}"
              end
            end
          end
          @a_context_s = Hash[@a_context_s.sort_by{|k, v| v}]
        rescue
          next
        end
      end

    end

    @assessments = Kaminari.paginate_array(@assessments).page(params[:page]).per(10)

  end

  def assessment_filter
    cen = current_user.center_id
    ins = current_user.institution_id
    my = params["my"] if params["my"]
    where = "" #condition builder for filter form on my assessments tab
    values = {:creator_id=>current_user.id,:ins=>ins,:cen=>cen}
    if params["my"]
      where = "createdby=:creator_id and (format_type=1 or format_type=8) "
    else
      if cen
        where = "center_id=:cen and institution_id=:ins "
      else
        where = "institution_id=:ins "
      end
    end
    if params["ac_class"].present?
      where = where + "and quiz_details.academic_class_tag_id=:ac_class " if params["ac_class"].split("_").first == "t"
      where = where + "and contexts.content_year_id=:ac_class " if params["ac_class"].split("_").first == "c"
      values[:ac_class] = params["ac_class"].split("_").last
    end
    if params["subject"].present?
      where = where + "and quiz_details.subject_tag_id=:sub " if params["subject"].split("_").first == "t"
      where = where + "and contexts.subject_id=:sub " if params["subject"].split("_").first == "c"
      values[:sub] = params[:subject].split("_").last
    end
    if params["a_type"].present?
      if params["a_type"] == "published"
        where = where + "and quiz_targeted_groups.id IS NOT NULL "
      else
        where = where + "and quiz_targeted_groups.id IS NULL "
      end
    end
    if params["assessment_start_date"].present?
      where = where + "and timecreated>=:start_time "
      values[:start_time] = params[:assessment_start_date].to_datetime.to_i
    end
    if params["assessment_end_date"].present?
      where = where + "and timecreated<=:end_time "
      values[:end_time] = params[:assessment_end_date].to_datetime.end_of_day.to_i
    end
    @assessments = Quiz.includes(:quiz_detail,:context,:quiz_targeted_groups).where(where,values).order("timemodified desc")

    # ac_class = params["ac_class"] if params["ac_class"]
    # sub = params["subject"] if params["subject"]
    # a_type= params["a_type"] if params["a_type"]
    # start_date =params[:assessment_start_date].to_datetime.to_i if params[:assessment_start_date].present?
    # end_date = params[:assessment_end_date].present? ? params[:assessment_end_date].to_datetime.end_of_day.to_i : Time.now.to_i
    # my = params["my"] if params["my"]
    # where = ""
    # values = {}
    #
    # cen = current_user.center_id
    # ins = current_user.institution_id
    # if cen
    #   @assessments = Quiz.where(:center_id => cen, :institution_id => ins).order("timemodified desc")  #.page(params[:page]).per(10)
    # else
    #   @assessments = Quiz.where(:institution_id => ins).order("timemodified desc")   #.page(params[:page]).per(10)
    # end
    # if my
    #   @assessments = @assessments.where( :createdby => current_user.id)
    # end
    # if ac_class
    #   if ac_class.split("_").first == "t"
    #     @assessments = @assessments.collect do |a|
    #       if !a.quiz_detail.nil?
    #         if a.quiz_detail.academic_class_tag_id.to_s == ac_class.split("_").last
    #           a
    #         end
    #       end
    #     end
    #     @assessments = @assessments.compact
    #   elsif ac_class.split("_").first == "c"
    #     @assessments = @assessments.collect do |a|
    #       if !a.context.nil?
    #         if a.context.content_year_id.to_s == ac_class.split("_").last
    #           a
    #         end
    #       end
    #     end
    #     @assessments = @assessments.compact
    #   end
    # end
    #
    # if sub
    #   if sub.split("_").first == "t"
    #     @assessments = @assessments.collect do |a|
    #       if !a.quiz_detail.nil?
    #         if a.quiz_detail.subject_tag_id.to_s == sub.split("_").last
    #           a
    #         end
    #       end
    #     end
    #     @assessments = @assessments.compact
    #   elsif sub.split("_").first == "c"
    #     @assessments = @assessments.collect do |a|
    #       if !a.context.nil?
    #         if sub.split("_").include? "f"
    #           if a.context.chapter_id.to_s == sub.split("_").last
    #             a
    #           end
    #         elsif sub.split("_").include? "s"
    #           if a.context.subject_id.to_s == sub.split("_").last
    #             a
    #           end
    #         end
    #       end
    #     end
    #     @assessments = @assessments.compact
    #   end
    # end
    # if a_type
    #   @assessments = @assessments.collect do |a|
    #     if a_type == "published"
    #       if a.quiz_targeted_groups.length != 0
    #         a
    #       end
    #     elsif a_type == "un-published"
    #       if a.quiz_targeted_groups.length == 0
    #         a
    #       end
    #     end
    #   end
    #   @assessments = @assessments.compact
    # end
    # if start_date
    #   @assessments = @assessments.collect do |a|
    #     if a.timecreated >= start_date and a.timecreated <= end_date
    #       a
    #     end
    #   end
    # end
    #   @assessments = @assessments.compact

    @assessments = Kaminari.paginate_array(@assessments).page(params[:page]).per(10)

    if my
      respond_to do |format|
        format.html {render "assessment_tool/my_assessments"}
        format.js { render "assessment_tool/assessment_filter1"}
      end
      return
    end
    respond_to do |format|
      format.html {render "assessment_tool/all_assessments"}
      format.js
    end
  end

  def assessment_filter_publish

  end

  def assessment_reports
    cen = current_user.center_id
    ins = current_user.institution_id
    #quiz_targeted_group_ids = QuizTargetedGroup.where(:published_by => current_user.id).map(&:id)
    @assessment_reports_tasks = AssessmentReportsTask.where(:created_by => current_user.id).order("updated_at desc")
    @assessment_reports_tasks = Kaminari.paginate_array(@assessment_reports_tasks).page(params[:page]).per(10)

    if params[:assessment]
      @assessment = Quiz.find(params[:assessment])
    else
      @assessment = nil
    end
    all_user_ids = User.where(:institution_id => ins, :role_id => [2, 3, 5]).map(&:id)
    #quiz_targeted_group_ids_all = QuizTargetedGroup.where(:published_by => all_user_ids).map(&:id)
    @assessment_reports_tasks_all = AssessmentReportsTask.where(:created_by => all_user_ids).order("updated_at desc")
    @assessment_reports_tasks_all = Kaminari.paginate_array(@assessment_reports_tasks_all).page(params[:page]).per(10)

    @publishes = []

    if @assessment
      @assessment_publishes = @assessment.quiz_targeted_groups.where(:to_group=>true)
    else
      @assessment_publishes = []
    end

    if @assessment and !@assessment_publishes.empty? and !current_user.institution.user_configuration.use_tags

      if !@assessment.context.nil? and @assessment.context.subject_id != 0 and !@assessment.context.subject_id.nil?
        @grouped_publishes = QuizTargetedGroup.includes(:quiz=>:context).where("(contexts.content_year_id=#{@assessment.context.content_year_id} and contexts.subject_id=#{@assessment.context.subject_id})  and group_id IN (#{@assessment_publishes.map(&:group_id).join(',')})")
      else
        @grouped_publishes = QuizTargetedGroup.includes(:quiz=>:context).where("contexts.content_year_id=#{@assessment.context.content_year_id} and group_id IN (#{@assessment_publishes.map(&:group_id).join(',')})")
      end


      @grouped_publishes.each do |qtg|
        if qtg.to_group && !qtg.quiz_attempts.empty?
          @publishes << qtg
        end
      end

    else
      if cen
        @assessments = Quiz.where( :center_id => cen, :institution_id => ins).order("timemodified desc")
      else
        @assessments = Quiz.where( :institution_id => ins).order("timemodified desc")
      end

      @assessments = @assessments.collect do |assessment|
        if !assessment.quiz_targeted_groups.empty?
          assessment
        end
      end
      @assessments = @assessments.compact


      @assessments.collect do |assessment|
        assessment.quiz_targeted_groups.each do |qtg|
          if qtg.to_group && !qtg.quiz_attempts.empty?
            @publishes << qtg
          end
        end
      end
    end

    @publishes = Kaminari.paginate_array(@publishes).page(params[:page]).per(5)

    respond_to do |format|
      format.html
      format.js {render "qtg_create_report_pagination"}
    end

  end

  def qtg_create_report_pagination
    cen = current_user.center_id
    ins = current_user.institution_id
    if cen
      @assessments = Quiz.where( :center_id => cen, :institution_id => ins).order("timemodified desc")
    else
      @assessments = Quiz.where( :institution_id => ins).order("timemodified desc")
    end

    @assessments = @assessments.collect do |assessment|
      if !assessment.quiz_targeted_groups.empty?
        assessment
      end
    end
    @assessments = @assessments.compact

    @publishes = []
    @assessments.collect do |assessment|
      assessment.quiz_targeted_groups.each do |qtg|
        if qtg.to_group && !qtg.quiz_attempts.empty?
          @publishes << qtg
        end
      end
    end

    @publishes = Kaminari.paginate_array(@publishes).page(params[:page]).per(5)

    respond_to do |format|
      format.js
    end
  end

  def gtg_create_report_pagination
    cen = current_user.center_id
    ins = current_user.institution_id
    if cen
      @assessments = Quiz.where( :center_id => cen, :institution_id => ins).order("timemodified desc")
    else
      @assessments = Quiz.where( :institution_id => ins).order("timemodified desc")
    end

    @assessments = @assessments.collect do |assessment|
      if !assessment.quiz_targeted_groups.empty?
        assessment
      end
    end
    @assessments = @assessments.compact

    @publishes = []
    @assessments.collect do |assessment|
      assessment.quiz_targeted_groups.each do |qtg|
        if qtg.to_group && !qtg.quiz_attempts.empty?
          @publishes << qtg
        end
      end
    end

    @publishes = Kaminari.paginate_array(@publishes).page(params[:page]).per(5)

    respond_to do |format|
      format.js
    end
  end

  def edit_question
    @question = Question.find(params[:question_id])
    @quiz = Quiz.find(params[:quiz_id])
    @assessment_div_id = params[:assessment_div_id]
    respond_to do |format|
      format.js
    end
  end

  def independently_edit_question
    @publisher_question_banks = []
    if current_user.is? "ECP"
      @publisher_question_banks = current_user.publisher_question_banks
      @publisher_question_bank = current_user.publisher_question_banks.first
    else
      #if it is an old institution, their views will receive and empty array of publisher question banks which is of no consequence
      # for them tag builder is not even rendered
      if current_user.institution.user_configuration.use_tags
        @publisher_question_banks = current_user.institution.publisher_question_banks
        @publisher_question_bank = current_user.institution.publisher_question_banks.first
      end
    end
    @question = Question.find(params[:question_id])
    @page_number = params[:page_number].present? ? params[:page_number] : "1"

    unless current_user.is? "ECP"
      if !current_user.institution.user_configuration.use_tags
        @boards = current_user.institution.boards
        @board = @question.context.board
        @subject = @question.context.subject
        @content_year = @question.context.content_year
        @topic = @question.context.topic
        @chapter = @question.context.chapter
      end
    end

    @question_tags = Hash.new{|h,k| h[k] = Array.new }
    @question.tags.each do |tag|
      if ["course","subject","difficulty_level","chapter","academic_class"].include? tag.name
        @question_tags[tag.name] = tag.value
      elsif ["blooms_taxonomy","concept_names","specialCategory","qsubtype"].include? tag.name
        @question_tags[tag.name].push(tag.value)
      end
    end
    @recommendation_tag = @question.recommendation_tag unless @question.recommendation_tag.nil?
    respond_to do |format|
      format.js
    end
  end

  def update_individual_question
    @question =  Question.find(params[:question][:id])
    @question.attributes = params[:question]
    @question.save(:validate=>false)
    @quiz = Quiz.find(params[:quiz_id])
    @assessment_div =  if @quiz.quiz_sections.empty? then @quiz else QuizSection.find(params[:assessment_div_id]) end

    respond_to do |format|
      format.js {render "update_assessment_division"}
    end
  end

  def independently_update_individual_question
    question =  Question.find(params[:question][:id])
    question.attributes = params[:question]
    publisher_question_bank_id = params[:publisher_question_bank_id]
    @page_number = params[:page_number]
    @qu_id = nil
    @qb_id = publisher_question_bank_id.to_i
    #@question.save(:validate=>false)
    unless question.questiontext.blank?
      if valid_for_save(question)
        question.save!(:validate => false)
        @qu_id = question.id
        questions = [] << question
        tagset = params[:item]
        if !tagset.nil?
          tag_ids = attach_tags_to_questions(tagset,questions)
          create_tag_references_for_these_tags(tag_ids,publisher_question_bank_id)
        end
      else
        @message = "Question can't be saved because of inappropriate blank values"
        render :template => 'assessment_tool/action_failed.js.erb'
        return
      end
    else
      @message = "Question text can't be blank"
      render :template => 'assessment_tool/action_failed.js.erb'
      return
    end
    respond_to do |format|
      format.js {render "update_manage_questions"}
    end
  end

  def new
    @quiz = Quiz.new
    @instruction = Instruction.new
    @instructions = Instruction.where(user_id:current_user.id)
    @present_instruction = Instruction.where(user_id:current_user.id,is_live:true).first
    @quiz.build_quiz_detail
    @quiz.build_context
    @board = current_user.institution.present? ? current_user.institution.boards.first : 0
    @boards = current_user.institution.present? ? current_user.institution.boards : 0
  end

  # this creates assessment
  def create
    @quiz = Quiz.new(params[:quiz])
    @quiz.createdby = current_user.id
    @quiz.modifiedby = current_user.id
    @quiz.timecreated = Time.now
    @quiz.timemodified = Time.now
    if current_user.institution_id
      @quiz.institution_id = current_user.institution_id
    else
      @quiz.institution_id = Institution.first.id
    end
    if current_user.center_id
      @quiz.center_id = current_user.center_id
    end
    #@quiz.format_type = 8
    Quiz.skip_callback(:create,:before,:set_defaults)
    if @quiz.save(:validate => false)
      if params[:commit]=="Save and Close"
        redirect_to assessment_tool_all_assessments_path
        return
      elsif params[:commit] == "Copy"
        @assessment = Quiz.find(params[:assessment])
        copy_assessment_questions(@quiz,@assessment)
        redirect_to assessment_tool_edit_path(@quiz)
        return
      else
        redirect_to assessment_tool_edit_path(@quiz)
        return
      end
    end
    redirect_to assessment_tool_new_path
  end

  def edit
    @quiz = Quiz.find(params[:format])
    @publisher_question_banks = []
    if current_user.is? "ECP"
      @quiz.build_quiz_detail.save
      @publisher_question_banks = current_user.publisher_question_banks
      @publisher_question_bank = current_user.publisher_question_banks.first
    else
      #if it is an old institution, their views will receive and empty array of publisher question banks which is of no consequence
      # for them tag builder is not even rendered
      if current_user.institution.user_configuration.use_tags
        current_user.institution.create_publisher_question_bank unless current_user.institution.publisher_question_banks.present?
        @publisher_question_banks = current_user.institution(true).publisher_question_banks(true)
        @publisher_question_bank = current_user.institution.publisher_question_banks.first
      end
    end
    @presence = @quiz.questions.collect(&:id)
    if !@quiz.quiz_targeted_groups.empty?
      redirect_to assessment_tool_my_assessments_path, notice: "You Can't Edit The Published Assessment."
      return
    end
    if @quiz.format_type != 1
      @boards = current_user.institution.present? ? current_user.institution.boards : 0
      @board,@qdbs = assign_question_banks
      @tags = ["difficulty_level", "blooms_taxonomy", "specialCategory"]
    else
      @attachment = @quiz.asset.nil? ? @quiz.build_asset : @quiz.asset
      render file:'assessment_tool/edit_openformat_assessment'
      return
    end
    #@tags = Tag.group(:name)
    #@tags = ["academic_class", "subject", "chapter", "concept_names", "difficulty_level", "blooms_taxonomy", "special_category", "data_handling", "grammer"]
    #@tags = ["academic_class", "subject", "chapter", "concept_names", "resource", "difficulty_level", "specialCategory"]
  end

  def assign_question_banks
    # This board is only applicable when the system requires ncx based system. It is required in the views to render
    board = nil
    boards =[]
    qdbs = []
    unless current_user.rc =="ECP"
      boards = current_user.institution.boards unless current_user.institution.user_configuration.use_tags?
      board = current_user.institution.boards.first unless current_user.institution.user_configuration.use_tags?
      #todo This is the legacy version. Questions should be migrated to use publisher_question_banks instead.
      #todo After the migration is complete, boards feature needs to be dropped
      # if !boards.empty?
      #   boards.each do |board|
      #     qdbs << [board.name, board.id, "board"]
      #   end
      # end
      # This is required at present even if the institution uses tags
      # We also assume that independent publishers don't want to use Edutor question bank
      #todo need to migrate all these questions to use edutor publisher question banks instead of edutor board
      # if current_user.institution.user_configuration.edutor_question_db
      #   qdbs << ['Edutor', 25009, "board"]
      # end
    end


    # This is the preferred way of implementing question bank.
    #todo need to assign all the existing board questions to board publisher question banks and scrap the above code
    question_banks = []
    if current_user.rc == "ECP"
      question_banks = current_user.publisher_question_banks
    else
      # Some institute user is logged in
      institution = current_user.institution
      institution.publisher_question_banks.each { |qb| question_banks << qb }
      # institution.question_bank_users.each do |question_bank_user|
      # question_banks << question_bank_user.publisher_question_bank
      # end
      institution.purchased_question_banks.each { |qb| question_banks << qb }
    end
    question_banks = question_banks - [nil]
    if !question_banks.empty?
      question_banks.uniq.each { |question_bank| qdbs << [question_bank.question_bank_name, question_bank.id, "publisher_question_bank"] }
    end
    [board,qdbs]
  end


  # Adding and removing openformat questions
  def update_openformat_assessment
    @quiz = Quiz.find(params[:id])
    if @quiz.format_type != 1
      redirect_to :action =>"edit",:id=>@quiz.id
      return
    end
    if params[:asset].present?
      if params[:asset][:attachment].present?
        if @quiz.asset.nil?
          @quiz_attachment = Asset.new(:attachment=>params[:asset][:attachment],:archive_type=>"Quiz",:archive_id=>@quiz.id)
          @quiz_attachment.save!
          path = @quiz_attachment.src
          @quiz.update_attribute(:questions_file,path)
        else
          @quiz_attachment = @quiz.asset
          @quiz_attachment.attachment = params[:asset][:attachment]
          @quiz_attachment.save!
          path = @quiz_attachment.src
          @quiz.update_attribute(:questions_file,path)
        end
      end

    end

    path = @quiz.asset.nil? ? '' : @quiz.asset.src

    @position = 1
    if params[:quiz].present?
      if params[:quiz][:quiz_question_instances_attributes].present?
        ActiveRecord::Base.transaction do
          params[:quiz][:quiz_question_instances_attributes].each do |instance|
            instance = instance[1]
            @instance = QuizQuestionInstance.find(instance[:id])
            if @instance
              logger.info"=======================1"
              @instance.update_attributes(:grade=>instance[:grade],:penalty=>instance[:penalty],:position=>@position)
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
            @position = @position + 1
          end
        end
      end
    end

    if params[:questions].present?
      ActiveRecord::Base.transaction do
        params[:questions].each do |p|

          q = Question.new
          q.section = 1
          q.tag = p[:tag]
          q.page_no = 1
          q.inpage_location = 1
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
          qqi.position = @position
          qqi.save
          @position = @position + 1
        end
      end
    end


    respond_to do |format|
      format.html { redirect_to assessment_tool_my_assessments_path, notice: 'Assessment was successfully updated.' }
      format.json { render json: @quiz.errors, status: :unprocessable_entity }
    end
  end

  def update_search_filter
    if params[:quiz] != ""
      @quiz = Quiz.find(params[:quiz])
    end
    if params[:question_bank_type]=="publisher_question_bank"
      #todo Porting edutor questions to edutor_publisher_question_bank is  urgent priority
      @publisher_question_bank= PublisherQuestionBank.find(params[:question_bank_id])
      @tags = ["difficulty_level", "blooms_taxonomy", "specialCategory"]
      render :template => 'assessment_tool/update_tag_filter.js.erb'
    else
      @board =  Board.find(params[:question_bank_id])
      render :template => 'assessment_tool/update_ncx_filter.js.erb'
    end
  end

  def save
  end

  def create_and_add_passage_question
    quiz_id = params[:quiz_id]
    assessment_div_id = params[:assessment_div_id]
    passage_question = Question.new(params[:quiz][:question])
    valid_passage_question = passage_question_valid_for_save(passage_question)
    publisher_question_bank_id = params[:publisher_question_bank_id]
    @qu_id = nil
    @qb_id = publisher_question_bank_id.to_i
    if valid_passage_question
      passage_question.save(:validate => false)
      @qu_id = passage_question.id
      #this happens only in case publisher question banks exists
      # We are not saving the individual questions directly to database that means they will not be available in search results even if one searches by tags
      add_question_to_publisher_question_bank(publisher_question_bank_id,passage_question)
      questions = [] << passage_question
      passage_question.questions.each do|child_question|
        child_question.multiselect = true if child_question.multiple_answer?
        child_question.update_attribute(:recommendation_tag, passage_question.recommendation_tag)
        questions << child_question
      end
      # questions += passage_question
      tagsets = params[:item]
      if !tagsets.nil?
        tagsets[:qsubtype] = [passage_question.qtype] if passage_question.qtype != "multichoice"
        tag_ids = attach_tags_to_questions(tagsets,questions)
        logger.info "---------------------------#{tag_ids}------------------------------------"
        create_tag_references_for_these_tags(tag_ids,publisher_question_bank_id)
      end
      @question = passage_question
      @created_questions = [] << passage_question
      @quiz = Quiz.find(quiz_id) if quiz_id
      @assessment_div = create_quiz_question_instances(quiz_id,assessment_div_id,questions) if assessment_div_id
      render :template => 'assessment_tool/update_assessment_division.js.erb'
    else
      @message = "Passage question couldn't be saved because of inappropriate blank values"
      render :template => 'assessment_tool/action_failed.js.erb'
    end
  end

  def create_and_add_multiple_questions
    @created_questions = []
    quiz_id = params[:quiz_id]
    assessment_div_id = params[:assessment_div_id]
    question = Question.new(params[:quiz1][:question])
    question.multiselect = true if question.multiple_answer?
    publisher_question_bank_id = params[:publisher_question_bank_id]
    @qu_id = nil
    @qb_id = publisher_question_bank_id.to_i
    unless question.questiontext.blank?
      if valid_for_save(question)
        question.save(:validate => false)
        @created_questions << question
        @created_questions << question.questions
        @created_questions = @created_questions.flatten
        @qu_id = question.id
        @created_questions.each do |new_question|
        new_question.multiselect = true if new_question.multiple_answer?
        new_question.update_attribute(:recommendation_tag, question.recommendation_tag)
        add_question_to_publisher_question_bank(publisher_question_bank_id,new_question)
        begin
          p = RedisInteract::Plumbing.new
          p.update_redis_server_after_question_creation(publisher_question_bank_id, new_question.id)
            #   Since redis server may or may not be online at the time of calling this function, we shall prevent excpetions
        rescue Exception => e
          logger.info "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee#{e}eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
          return
        end
        end
        # questions = [] << question
        tagset = params[:item]
        if !tagset.nil?
          tagset[:qsubtype] = [question.qtype] if question.qtype != "multichoice"
          tag_ids = attach_tags_to_questions(tagset,@created_questions)
          create_tag_references_for_these_tags(tag_ids,publisher_question_bank_id)
        end
        # @question = question
        delete_wrongly_created_passage_questions = PassageQuestion.where(passage_question_id:@qu_id).each{|k| k.delete}

        @quiz = Quiz.find(quiz_id) if quiz_id
        @assessment_div = create_quiz_question_instances(quiz_id,assessment_div_id,@created_questions) if quiz_id
        render :template => 'assessment_tool/update_assessment_division.js.erb'
      else
        @message = "Question cannot be saved because of inappropriate blank values"
        render :template => 'assessment_tool/action_failed.js.erb'
      end
    else
      @message = "Question text cannot be blank"
      render :template => 'assessment_tool/action_failed.js.erb'
    end
  end

  def create_and_add_individual_question
    quiz_id = params[:quiz_id]
    assessment_div_id = params[:assessment_div_id]
    question = Question.new(params[:quiz2][:question])
    question.multiselect = true if question.multiple_answer?
    publisher_question_bank_id = params[:publisher_question_bank_id]
    @qu_id = nil
    @qb_id = publisher_question_bank_id.to_i
    unless question.questiontext.blank?
      if valid_for_save(question)
        question.save(:validate => false)
        @qu_id = question.id
        add_question_to_publisher_question_bank(publisher_question_bank_id,question)
        questions = [] << question
        tagset = params[:item]
        if !tagset.nil?
          tagset[:qsubtype] = [question.qtype] if question.qtype != "multichoice"
          tag_ids = attach_tags_to_questions(tagset,questions)
          create_tag_references_for_these_tags(tag_ids,publisher_question_bank_id)
        end
        @question = question
        @created_questions = [] << question
        @quiz = Quiz.find(quiz_id) if quiz_id
        @assessment_div = create_quiz_question_instances(quiz_id,assessment_div_id,questions) if quiz_id
        render :template => 'assessment_tool/update_assessment_division.js.erb'
      else
        @message = "Question cannot be saved because of inappropriate blank values"
        render :template => 'assessment_tool/action_failed.js.erb'
      end
    else
      @message = "Question text cannot be blank"
      render :template => 'assessment_tool/action_failed.js.erb'
    end

  end

  #creates quiz question instances and returns assessment object
  def create_quiz_question_instances(quiz_id,assessment_div_id,question_collection)
    quiz = Quiz.find(quiz_id)
    if quiz.quiz_sections.empty?
      # add questions to the quiz directly
      quiz.questions += question_collection
      return quiz
    else
      # add questions to corresponding section
      question_collection.each do |question|
        if !quiz.question_ids.include? question.id
          quiz_question_instance = QuizQuestionInstance.new(:quiz_id=>quiz_id,:question_id=>question.id,:quiz_section_id=>assessment_div_id)
          quiz_question_instance.save
        end
      end
      return QuizSection.find(assessment_div_id)
    end
  end

  # Attach tags to questions if they exist else create new ones and attach.
  def attach_tags_to_questions(tags,questions)
    tag_ids = []
    questions.each do |question|
      # Below line of code is repeated - Beware of the unknown consequences!
      tag_ids << question.add_tags('qsubtype','mmcq').tag_id if question.multiple_answer?
      tags.each do |name,values|
        if values
          values.each {|value|
            tag_ids << question.add_tags(name,value).tag_id
          }
        end
      end
    end
    return tag_ids.uniq
  end

  # this creates links between the tags supplied with the question for search purposes
  def create_tag_references_for_these_tags(tag_ids,publisher_question_bank_id)
    @user = current_user
    tag_ids.each do |t|
      tag_ids.each do |i|
        if i != t
          Tag.add_ref_tags(i,t,@user.institution_id,@user.center_id,publisher_question_bank_id)
        end
      end
    end
    #group all related tags at once place
    #course_tags = tags.where(name:"course")
    #academic_class_tags = tags.where(name:"academic_class")
    #subject_tags = tags.where(name:"subject")
    #chapter_tags = tags.where(name:"chapter")
    #concept_name_tags = tags.where(name:"concept_names")
    #logger.info "------course--#{course_tags}------class-#{academic_class_tags}-----subject--#{subject_tags}--------chapter-#{chapter_tags}-----conceptnames-#{concept_name_tags}--------------------------"
    #create a chainlinks between tag groups
    #
    #unless academic_class_tags.empty? and course_tags.empty?
    #  academic_class_tags.each{|academic_class_tag|
    #    course_tags.each{|course_tag|
    #      Tag.add_ref_tags(course_tag.id,academic_class_tag.id,@user.institution_id,@user.center_id)
    #    }
    #  }
    #end
    #
    #unless subject_tags.empty? and academic_class_tags.empty?
    #  subject_tags.each{|subject_tag|
    #    academic_class_tags.each{|academic_class_tag|
    #      Tag.add_ref_tags(academic_class_tag.id,subject_tag.id,@user.institution_id,@user.center_id)
    #    }
    #  }
    #end
    #
    #unless chapter_tags.empty? and subject_tags.empty?
    #  chapter_tags.each{|chapter_tag|
    #    subject_tags.each{|subject_tag|
    #      Tag.add_ref_tags(subject_tag.id,chapter_tag.id,@user.institution_id,@user.center_id)
    #    }
    #  }
    #end
    #
    #unless concept_name_tags.empty? and chapter_tags.empty?
    #  concept_name_tags.each{|concept_name_tag|
    #    chapter_tags.each{|chapter_tag|
    #      Tag.add_ref_tags(chapter_tag.id,concept_name_tag.id,@user.institution_id,@user.center_id)
    #    }
    #  }
    #end

  end


  #this sets position, marks and penalty marks for quiz question instances for the given assessment division
  def update_question_instances
    # works only on single assessment division's questions
    # updates grade and penalty of quiz question instances
    assessment_div_id = params[:assessment_div_id]
    assessment_div_type = params[:assessment_div_type]
    params[:question_instance].each do |question_instance_id,question_instance_options|
      question_instance = QuizQuestionInstance.find(question_instance_id)
      question_instance.update_attributes(question_instance_options)
    end
    # updates the live document with changed data and presents the same form again
    @assessment_div = assessment_div_type=="simple_quiz" ? Quiz.find(assessment_div_id) : QuizSection.find(assessment_div_id)
    respond_to  do |format|
      format.js
    end
  end

  #deletes particular question instance and removes corresponding division in the document
  def delete_question_instance
    question_instance_id = params[:question_instance_id]
    assessment_div_id = params[:assessment_div_id]
    @quiz = QuizQuestionInstance.find(question_instance_id).quiz
    @assessment_div = @quiz.quiz_sections.empty? ? @quiz : QuizSection.find(assessment_div_id)
    question_instance = QuizQuestionInstance.find(question_instance_id)
    @deleted_question = question_instance.question_id
    #if it is a passage question, it deletes any children  questions found in the quiz
    if question_instance.question.qtype=="passage"
      child_questions = question_instance.question.questions
      QuizQuestionInstance.where(quiz_id:@quiz.id ,question_id:child_questions.map(&:id)).destroy_all
    end
    question_instance.destroy
    respond_to  do |format|
      format.js {render "update_assessment_division"}
    end
  end


  #this adds new quiz question instances to a given assessment division
  #or just returns the assessment division content if no new content is added
  def update_assessment_division
    assessment_div_id = params[:assessment_division_id]
    quiz_id = ""
    quiz_section_id = nil
    if params[:assessment_division_type]=="simple_test"
      @assessment_div = Quiz.find(assessment_div_id)
      quiz_id = @assessment_div.id

    else
      @assessment_div = QuizSection.find(assessment_div_id)
      quiz_id = @assessment_div.quiz_id
      quiz_section_id = @assessment_div.id
    end
    @quiz = Quiz.find(quiz_id)
    #this adds new quiz question instances to a given assessment division if any questions are selected
    if params[:selected_questions]
      questions_array = params[:selected_questions].split("-")
      questions_array.each{ |question_id|
        if !@quiz.question_ids.include? question_id.to_i
          QuizQuestionInstance.create({question_id:question_id,quiz_id:quiz_id,quiz_section_id:quiz_section_id})
          @question = Question.find(question_id)
          if @question.qtype  == "passage"
            @question.questions.each do |q|
              QuizQuestionInstance.create({question_id:q.id,quiz_id:quiz_id,quiz_section_id:quiz_section_id})
            end
          end
        end
      }
    end
    @quiz = Quiz.find(quiz_id)
    respond_to  do |format|
      format.js
    end
  end


  def get_questions_by_tags
    @outside_assessment = params[:outside_assessment]
    @preference = Quiz.find(params[:quiz_id]).questions.collect(&:id) if params[:quiz_id].present?
    question_ids = params[:tag_list][:search_by_id]
    unless question_ids==""
      question_id_array = question_ids.split(",")
      @questions = Question.where(id:question_id_array).group('questions.id').order("timemodified desc").page(params[:page]).per(10)
    else
      search_params = params[:tag_list]#[{'skills'=>'ruby'},{'subject'=>'maths'},{'academic_class'=>'8'}]
      search = " "
      args = search_params.collect{|q| q if q[1]!=''} - [nil]
      c = args.count
      logger.info "=====args===========#{args.count}"
      tag_search_ids = []
      args.each do |s|
        tag_search_ids << s[1]
      end

      tag_ids = []
      tag_ids = tag_ids + tag_search_ids
      values = {}
      logger.info "====search==#{search}==#{tag_search_ids}===#{search.blank?}"
      if params[:publisher_question_bank_id]==""
        where = 'questions.institution_id IN (:institution_id)'
        values[:institution_id] = [current_user.institution_id]
      else
        publisher_question_bank_id = params[:publisher_question_bank_id]
        where = 'questions.id IN (:question_id)'
        values[:question_id] = PublisherQuestionBank.find(publisher_question_bank_id).questions.map(&:id)
      end
      if params[:qtype] != 'All'
        where = where+ ' AND questions.qtype = :qtype'
        values[:qtype] = params[:qtype]
      end

      if !tag_ids.empty?
        where = where+ ' AND taggings.tag_id IN (:tag_ids)'
        values[:tag_ids] = tag_ids
      end

      if tag_ids.empty?
        @questions = Question.where(where,values).group('questions.id').order("questions.id desc").page(params[:page]).per(10)
      else
        @questions = Question.includes(:taggings).where(where,values).group('questions.id').having('COUNT(*) >= ?', tag_ids.count).order("questions.id desc").page(params[:page]).per(10)
      end

    end

    #@questions = Question.includes(:tags=>:taggings).where(search).group('taggings.question_id').having('COUNT(*) > ?', c).order("timemodified desc").page(params[:page]).per(10)
    #logger.info "====search==#{@questions.count}"
    respond_to  do |format|
      format.js
    end
  end

  def get_questions_by_live_tags
    @outside_assessment = params[:outside_assessment]
    @preference = Quiz.find(params[:quiz_id]).questions.collect(&:id) if params[:quiz_id].present?
    @quiz = Quiz.find(params[:quiz_id]) if params[:quiz_id].present?
    @question_ids = params[:tag_list][:search_by_id]
    unless @question_ids==""
      question_id_array = @question_ids.split(",")
      @questions = Question.where(id: question_id_array.uniq).page(params[:page]).per(10)
      @all_questions_ids = Question.where(id: question_id_array.uniq).collect { |p| p.id }
    else
      tag_ids = []
      search_params = params[:tag_list] #[{'skills'=>'ruby'},{'subject'=>'maths'},{'academic_class'=>'8'}]
      tag_ids = search_params.map { |key, value| value if (["ac", "su", "ch", "co", "dl", "bl", "sc", "ty"].include?(key) && value.present?) }.compact
      logger.info "=====args===========#{tag_ids.inspect}"
      publisher_question_bank_id = params[:publisher_question_bank_id]
      r = RedisInteract::Reading.new
      @questions = Question.where(id: r.search_questions(publisher_question_bank_id, tag_ids)).order("questions.id desc").page(params[:page]).per(10)
      @all_questions_ids = Question.where(id: r.search_questions(publisher_question_bank_id, tag_ids)).collect { |p| p.id }
      @publisher_question_bank_id = publisher_question_bank_id
      @dl_tg_ids = r.all_qb_tg_groups_tgs(publisher_question_bank_id)[:dl_tg_ids]
      @dl_segregated_ques_ids = []
      @dl_tg_ids.each do |tag|
        @dl_segregated_ques_ids << {Tag.find(tag).value=>Question.where(id: r.search_questions(publisher_question_bank_id, [tag])).collect { |p| p.id }}
      end
      @dl_segregated_ques_ids = @dl_segregated_ques_ids.reduce Hash.new, :merge
      @final_arrray_of_ques_ids = []
      @dl_segregated_ques_ids.keys.each do |dl_tag_name|
        @final_arrray_of_ques_ids << {dl_tag_name => (@dl_segregated_ques_ids[dl_tag_name] & @all_questions_ids)}
      end
      @final_hash_of_ques_ids = @final_arrray_of_ques_ids.reduce Hash.new, :merge


      respond_to do |format|
        format.js
      end
    end
  end

  def get_questions_by_content
    @outside_assessment = params[:outside_assessment]
    @preference = Quiz.find(params[:quiz_id]).questions.collect(&:id) if params[:quiz_id].present?
    question_ids = params[:tag_list][:search_by_id]
    unless question_ids==""
      question_id_array = question_ids.split(",")
      @questions = Question.where(id:question_id_array).group('questions.id').order("timemodified desc").page(params[:page]).per(10)
    else
      search_params = params[:tag_list]
      args = search_params.collect{|q| q if q[1]!=''} - [nil]
      logger.info "======#{args}"
      if current_user.institution.user_configuration.edutor_question_db
        where = "questions.institution_id IN (#{current_user.institution_id},1)"
      else
        where = "questions.institution_id = #{current_user.institution_id}"
      end
      if !args.empty?
        args.each do |a|
          where = where+ " AND " + "contexts."+"#{a[0]} = #{a[1]}"
        end
      end
      if params[:qtype] != 'All'
        where = where+ " AND questions.qtype =  '#{params[:qtype]}'"
      end
      @questions = Question.includes(:context).where(where).page(params[:page]).per(10)
    end
    respond_to  do |format|
      format.js
    end
  end

  def show
    @quiz = Quiz.find(params[:format])
    @center = @quiz.center_id != 0 ? @quiz.center_id : @quiz.institution_id
    if User.find(@center).name.include? "DS"
      @name = "DS Digital Pvt. Ltd."
    else
      @name = User.find(@center).name
    end
  end

  def publish_to
    @quiz = Quiz.find(params[:format])
    @target = QuizTargetedGroup.new
    @target.build_quiz_ibook_location
    @ibooks = current_user.ignitor_books
    if !current_user.institution.user_configuration.use_tags
      @target.build_quiz_target_location
      @boards = current_user.institution.boards
      @board = @quiz.context.board
    end
  end

  def publish
    @quiz = Quiz.find(params[:id])
    recipients = params[:message][:multiple_recipient_ids].split(",") if params[:message][:multiple_recipient_ids]
    @publish_to_ibook = "2" if params[:quiz_targeted_group][:group_id].split("|").last == "4.0"
    if params[:quiz_targeted_group][:group_id].split("|").last == "5.0" and params["publish_to_ibook"] != "0"
      # if params[:build] == "5.0"
      new_info = params[:quiz_targeted_group][:quiz_ibook_location_attributes ][:uri].split("$")
      params[:quiz_targeted_group][:quiz_ibook_location_attributes ][:guid] = "#{new_info[-2]}"
      params[:quiz_targeted_group][:quiz_ibook_location_attributes ][:parent_guid] = "#{new_info[-1]}"
      # end
    end

    if params[:quiz_targeted_group][:to_group].to_i == 0 and !recipients.empty?
      if params[:build] == "4.0"
        @publish_to_ibook = "2"
      elsif params[:build] == "5.0" and params["publish_to_ibook"] != "0"
        @publish_to_ibook = params["publish_to_ibook"]
        new_info = params[:quiz_targeted_group][:quiz_ibook_location_attributes ][:uri].split("$")
        params[:quiz_targeted_group][:quiz_ibook_location_attributes ][:guid] = "#{new_info[-2]}"
        params[:quiz_targeted_group][:quiz_ibook_location_attributes ][:parent_guid] = "#{new_info[-1]}"
        # elsif params[:build] == "5.0" and params["publish_to_ibook"] == "0"

      end
    end


    params[:quiz_targeted_group][:quiz_id] = @quiz.id
    params[:quiz_targeted_group][:published_by] = current_user.id

    if params[:quiz_targeted_group][:to_group].to_i == 0
      if recipients.empty?
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
          if @target.save!(:validate=>false)
            create_message

            #return
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
        format.html { redirect_to assessment_tool_my_assessments_path, notice: 'Assessment was successfully published.' }
        format.json { render json: @quiz.errors, status: :unprocessable_entity }
      end
      return
    else
      params[:quiz_targeted_group][:to_group] = true

      params[:quiz_targeted_group][:group_id] = params[:quiz_targeted_group][:group_id].split("|").first
      ActiveRecord::Base.transaction do
        @target = QuizTargetedGroup.new(params[:quiz_targeted_group])
        if @target.save!(:validate=>false)
          create_message
          respond_to do |format|
            format.html { redirect_to assessment_tool_my_assessments_path, notice: 'Assessment was successfully published.' }
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

  end

  def download_questions_pdf
    @quiz = Quiz.find(params[:quiz_id])
    @html_key = @quiz.html_key
    if params[:key] == "true"
      @key = true
    end
    @center = @quiz.center_id != 0 ? @quiz.center_id : @quiz.institution_id

    if User.find(@center).name.include? "DS"
      @name = "DS Digital Pvt. Ltd."
    else
      @name = User.find(@center).name
    end
    respond_to do |format|
      format.pdf do
        render :pdf => @quiz.name,
               :disposition => 'attachment',
               :wkhtmltopdf => '/usr/bin/wkhtmltopdf', # path to binary
               :template=>"assessment_tool/new_pdf_download.html.erb",
               :javascript_delay => 18000,
               :header => {
                   #:right => User.find(@center).firstname,
               } ,
               :page_size => 'A4',
               :encoding => 'utf',
               #:image_quality=> 1,
               :footer => {
                   :right => '[page]',
                   :center => @name ,
                   :line=> true,
                   :spacing=> 5,
               },
               :margin => {:top                => 15,
                           :bottom             => 20},
               :layout => 'pdf.html',
               :show_as_html=>false,
               :disable_external_links => true,
               :print_media_type => true,
               :disable_smart_shrinking => false
      end
    end
  end



  def create_message
    questions = []
    if @quiz.format_type != 1
      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.testpaper(:id=>@quiz.id.to_s,:version=>"2.0",:publish_id=>@target.id.to_s){
          xml.test_password(:value=>(@target.password.length > 0) ? @target.password : "")
          xml.show_solutions_after(:value=>(@target.show_answers_after).to_s)
          xml.show_score_after(:value=>(@target.show_score_after).to_s)
          xml.pause(:value=>(@target.pause) ? '1' : '0')
          xml.shuffleoptions(:value=>(@target.shuffleoptions?) ? "1" : "0")
          xml.shufflequestions(:value=>(@target.shufflequestions?) ? "1" : "0")
          xml.start_time(:value=>@target.timeopen.to_i.to_s)
          xml.end_time(:value=>@target.timeclose.to_i.to_s)
          xml.guidelines(:value=>@quiz.intro.html_safe)
          xml.requisites(:value=>"")
          if @quiz.timelimit > 0
            xml.time(:value=>@quiz.timelimit.to_s)
          else
            xml.time(:value=>"-1")
          end
          xml.level(:value=>@quiz.difficulty.to_s)
          if @quiz.quiz_sections.empty?
            @quiz.quiz_question_instances.each do |i|
              if !questions.include?(i.question_id)
                @question = Question.find(i.question_id)
                if @question.qtype == 'passage'
                  @passage_questions = get_quiz_passage_questions(@question,@quiz)
                  if !@passage_questions.empty?
                    xml.group_questions{
                      xml.group_instructions(:qtype=>"passage"){
                        xml.cdata @question.questiontext
                      }
                      @passage_questions.each do |question|
                        quiz_questions(xml,question)
                        questions << question.question_id
                      end
                    }
                  end
                  questions << i.question_id
                else
                  quiz_questions(xml,i)
                  questions << i.question_id
                end
              end
            end
          else
            @quiz.leaf_sections.each do |section|
              if  !section.all_quiz_question_instances.empty?
                xml.section(:name=>section.section_name){
                  xml.section_guidelines{
                    xml.cdata section.intro
                  }
                  section.all_quiz_question_instances.each do |i|
                    @question = Question.find(i.question_id)
                    if !questions.include? (i.question_id)
                      if @question.qtype == 'passage'
                        @passage_questions = get_quiz_passage_questions(@question,@quiz)
                        if !@passage_questions.empty?
                          xml.group_questions{
                            xml.group_instructions(:qtype=>"passage"){
                              xml.cdata @question.questiontext
                            }
                            @passage_questions.each do |question|
                              quiz_questions(xml,question)
                              questions << question.question_id
                            end
                          }
                        end
                        questions << i.question_id
                      else
                        quiz_questions(xml,i)
                        questions << i.question_id
                      end
                    end
                  end
                }
              end
            end
          end
        }
      end
    else
      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.testpaper(:id=>@quiz.id.to_s,:version=>"2.0",:publish_id=>@target.id.to_s){
          xml.exam_format_type(:value=>"open_format")
          xml.test_password(:value=>(@target.password.length > 0) ? @target.password : "")
          xml.show_solutions_after(:value=>(@target.show_answers_after).to_s)
          xml.show_score_after(:value=>(@target.show_score_after).to_s)
          xml.pause(:value=>(@target.pause) ? '1' : '0')
          xml.end_time(:value=>@target.timeclose.to_i.to_s)
          xml.start_time(:value=>@target.timeopen.to_i.to_s)
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
            xml.question_set(:id=>question.id,:multi_answer=>@target.allow_multiple_options){
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

    @target_location = @target.quiz_target_location
    @ncx = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.navMap{
        xml.navPoint(:id=>"Curriculum",:class=>"curriculum"){
          xml.content(:src=>"curriculum")
          if !@target_location.nil?
            xml.navPoint(:id=>"Assessment",:class=>"assessment"){
              xml.content(:src=>"assessments")
              xml.navPoint(:id=>@target_location.board.name.to_s,:class=>"course"){
                xml.content(:src=>"cb_02")
                xml.navPoint(:id=>@target_location.content_year.name.to_s,:class=>"academic-class"){
                  xml.content(:src=>@target_location.content_year.name.to_s)
                  xml.navPoint(:id=>@target.get_assessment_ncx,:class=>"assessment-category"){
                    xml.content(:src=>"practice")
                    xml.navPoint(:id=>@target_location.subject.name.to_s,:class=>"subject"){
                      xml.content(:src=>@target_location.subject.code)
                      if @target_location.chapter_id == 0
                        xml.navPoint(:id=>@quiz.name+'_'+@target.id.to_s,:class=>"assessment-#{@target.get_assessment_ncx}",:passwd=>(@target.password.length > 0) ? @target.password : ""){
                          xml.content(:src=>"/#{@quiz.name}_#{@target.id}.etx", :params=>@target_location.page_num)
                        }
                      end
                      if @target_location.chapter_id > 0 and @target_location.topic_id == 0
                        xml.navPoint(:id=>@target_location.chapter.name,:class=>"chapter",:playOrder=>@target_location.chapter.play_order){
                          xml.content(:src=>@target_location.chapter.try(:assets).last.try(:src), :params=>@target_location.chapter.params)
                          xml.navPoint(:id=>@quiz.name+'_'+@target.id.to_s,:class=>"assessment-#{@target.get_assessment_ncx}",:passwd=>(@target.password.length > 0) ? @target.password : ""){
                            xml.content(:src=>"/#{@quiz.name}_#{@target.id}.etx", :params=>@target_location.page_num)
                          }
                        }
                      end
                      if @target_location.chapter_id > 0 and @target_location.topic_id > 0
                        xml.navPoint(:id=>@target_location.chapter.name,:class=>"chapter",:playOrder=>@target_location.chapter.play_order){
                          xml.content(:src=>@target_location.chapter.assets.last.try(:src), :params=>@target_location.chapter.params)
                          xml.navPoint(:id=>@target_location.topic.name,:class=>"topic",:playOrder=>@target_location.topic.play_order){
                            xml.content(:src=>@target_location.topic.try(:assets).last.try(:src), :params=>@target_location.topic.params)
                            xml.navPoint(:id=>@quiz.name+'_'+@target.id.to_s,:class=>"assessment-#{@target.get_assessment_ncx}",:passwd=>(@target.password.length > 0) ? @target.password : ""){
                              xml.content(:src=>"/#{@quiz.name}_#{@target.id}.etx",:params=>@target_location.page_num)
                            }
                          }

                        }
                      end
                    }
                  }
                }
              }
            }
          else
            xml.navPoint(:id=>"Assessment",:class=>"assessment"){
              xml.content(:src=>"assessments")
              xml.navPoint(:id=>"QT",:class=>"course"){
                xml.content(:src=>"qt_02")
                xml.navPoint(:id=>"test",:class=>"academic-class"){
                  xml.content(:src=>"test")
                  xml.navPoint(:id=>@target.get_assessment_ncx,:class=>"assessment-category"){
                    xml.content(:src=>"practice")
                    xml.navPoint(:id=>"test",:class=>"subject"){
                      xml.content(:src=>"test")
                      xml.navPoint(:id=>@quiz.name.to_s + @target.id.to_s ,:class=>"assessment-#{@target.get_assessment_ncx}",:passwd=>(@target.password.length > 0) ? @target.password : ""){
                        xml.content(:src=>"/#{@quiz.name}_#{@target.id}.etx")
                      }
                    }
                  }
                }
              }
            }
          end
        }
      }
    end
    ncx_string =  @ncx.to_xml.to_s

    xml_string =  @builder.to_xml.to_s

    temp_path = Rails.root.to_s+"/public/quick_test/"+current_user.id.to_s+"/#{@quiz.id.to_s}/#{Time.now.to_i.to_s}/#{@quiz.name}_#{@target.id}"
    FileUtils.mkdir_p temp_path
    File.open(temp_path+"/#{@quiz.name}_#{@target.id}.etx",  "w+b", 0644) do |f|
      f.write(xml_string.to_s)
    end

    begin

      File.open(temp_path+"/index.ncx",  "w+b", 0644) do |f|
        f.write(ncx_string.to_s.gsub( "\n", "" ).gsub(/>[ ]*</,'><'))
      end
      images = []
      already_folders = []
      already_images = []
      Zip::ZipFile.open("#{temp_path}.zip", Zip::ZipFile::CREATE) {
          |zipfile|
        zipfile.add("#{@quiz.name}_#{@target.id}.etx",temp_path+"/#{@quiz.name}_#{@target.id}.etx")
        zipfile.add("index.ncx",temp_path+"/index.ncx")

        if @quiz.format_type == 1
          if File.exist?(@quiz.asset.attachment.path)
            zipfile.add(@quiz.asset.attachment_file_name,@quiz.asset.attachment.path)
          end
        else
          @quiz.questions.each do |q|
            #q.question_images.each do |img|
            #  images << img.picture.url.split("?")[0].gsub("/system",'system')
            #end
            images = images+extract_images(q.questiontext) unless q.questiontext.nil?
            images = images+extract_images(q.generalfeedback) unless q.generalfeedback.nil?
            images = images+extract_images(q.actual_answer)   unless q.actual_answer.nil?
            images = images+extract_images(q.hint) unless q.hint.nil?
            options = QuestionAnswer.where("question=?",q.id)
            options.each do |o|
              images = images+extract_images(o.answer) unless o.answer.nil?
            end
          end
          images = images+extract_images(@quiz.intro) unless @quiz.intro.nil?
          images = images - [""]
          images.each do |x|
            n = x.split('/').last
            x = x.gsub(n,'')
            if x != ""
              if !already_folders.include? x
                zipfile.mkdir(x)
                already_folders << x
              end
            end
          end
          images.each do |i|
            f = Rails.root.to_s+"/public/question_images/"+i
            if File.exist?(f)
              if !already_images.include? i
                zipfile.add(i,f)
                already_images << i
              end
            end
          end
        end


      }

    end
    if current_user.is? "ECP"
      ContentDelivery.encrypt_assessment_message(current_user,@target,"#{temp_path}.zip")
    else
      if @publish_to_ibook == '2'
        @message = Message.new
        @asset = @message.assets.build
        @asset.attachment = File.open("#{temp_path}.zip")
        @message.sender_id = current_user.id
        if @target.to_group
          @message.group_id = @target.group_id
        else
          @message.recipient_id = @target.recipient_id
        end
        @message.subject = @target.subject
        if @target_location
          if @target_location.topic_id !=0
            uri = "/Curriculum/Assessment/#{@target_location.topic.board.name}/#{@target_location.topic.content_year.name}/#{@target.get_assessment_ncx}/#{@target_location.topic.subject.name}/#{@target_location.topic.chapter.name}/#{@target_location.topic.name}/#{@quiz.name}_#{@target.id.to_s}"
          elsif @target_location.chapter_id !=0# AssessmentInTopicQuiz For Chapter
            uri = "/Curriculum/Assessment/#{@target_location.chapter.board.name}/#{@target_location.chapter.content_year.name}/#{@target.get_assessment_ncx}/#{@target_location.chapter.subject.name}/#{@target_location.chapter.name}/#{@quiz.name}_#{@target.id.to_s}"
          elsif @target_location.subject_id !=0# AssessmentInTopicQuiz For Subject
            uri = "/Curriculum/Assessment/#{@target_location.subject.board.name}/#{@target_location.subject.content_year.name}/#{@target.get_assessment_ncx}/#{@target_location.subject.name}/#{@quiz.name}_#{@target.id.to_s}"
          end
          @message.body = @target.body+"$:#{uri}"
        else
          @message.body = @target.body+"$:/Curriculum/Assessment/QT/test/#{@target.get_assessment_ncx}/test/#{@quiz.name.to_s + @target.id.to_s}"
        end
        @message.message_type = "Assessment"
        @message.severity = 1
        @message.label = @target.subject
        @message.save
        MessageQuizTargetedGroup.create(:message_id=>@message.id,:quiz_targeted_group_id=>@target.id)
      else
        ContentDelivery.encrypt_assessment_message(current_user,@target,"#{temp_path}.zip")
      end
    end
  end

  def quiz_questions(xml,q)
    @question = Question.find(q.question_id)
    xml.question_set(:id=>@question.id.to_s,:multi_answer=>@question.multiselect){
      xml.course(:value=>'')
      xml.board(:value=>'')
      xml.class_(:value=>'')
      xml.subject(:value=>'')
      xml.chapter(:value=>'')
      xml.time(:value=>"1")
      xml.score(:value=>q.grade.to_s)
      xml.comment_{
        xml.cdata @question.generalfeedback
      }
      xml.negativescore(:value=>q.penalty.to_s)
      xml.prob_skill(:value=> '0')
      xml.data_skill(:value=>'0')
      xml.useofit_skill(:value=> '0')
      xml.creativity_skill(:value=> '0')
      xml.listening_skill(:value=> '0')
      xml.speaking_skill(:value=>'0')
      xml.grammar_skill(:value=>'0')
      xml.vocab_skill(:value=>'0')
      xml.formulae_skill(:value=>'0')
      xml.comprehension_skill(:value=>'0')
      xml.knowledge_skill(:value=>'0')
      xml.application_skill(:value=>'0')
      xml.difficulty(:value=>'1')
      if @question.qtype =="multichoice"
        xml.qtype(:value=>"MCQ", :multi_select=>@question.multiselect)
      elsif @question.qtype =="truefalse"
        xml.qtype(:value=>"TOF")
      elsif @question.qtype == "fib"
        xml.qtype(:value=>"FIB")
      elsif @question.qtype == "saq"
        xml.qtype(:value=>"MCQ")
        xml.subsetqtype(:value=>"SAQ")
      elsif @question.qtype == "laq"
        xml.qtype(:value=>"MCQ")
        xml.subsetqtype(:value=>"LAQ")
      elsif @question.qtype == "vsaq"
        xml.qtype(:value=>"MCQ")
        xml.subsetqtype(:value=>"VSAQ")
      elsif @question.qtype == "project"
        xml.qtype(:value=>"MCQ")
        xml.subsetqtype(:value=>"project")
      elsif @question.qtype == "desc"
        xml.qtype(:value=>"MCQ")
        xml.subsetqtype(:value=>"desc")
      end
      xml.concept_name(:value=>@question.recommendation_tag)

      xml.question{
        xml.actual_answer{
          xml.cdata @question.actual_answer
        }
        xml.hint{
          xml.cdata @question.hint
        }
        xml.solution{
          xml.cdata @question.generalfeedback
        }
        if @question.qtype =="multichoice" || @question.qtype =="truefalse"
          xml.question_text{
            if @question.is_passage_question?
              xml.cdata "<div id='groupQuestion'><p><span style='font-family:&quot;Segoe UI&quot;,&quot;sans-serif&quot;'>#{@question.passage_question.questiontext}</span><br></div>"+@question.questiontext
            else
              xml.cdata @question.questiontext
            end
          }
          @options = QuestionAnswer.where("question=?",@question.id)
          i = 0
          options = ("a".."z").to_a
          @options.each do |o|
            tag =options[i]
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
        elsif @question.qtype == "fib"
          xml.question_text{
            if @question.is_passage_question?
              xml.cdata "<div id='groupQuestion'><p><span style='font-family:&quot;Segoe UI&quot;,&quot;sans-serif&quot;'>#{@question.passage_question.questiontext}</span><br></div>"+@question.questiontext
            else
              xml.cdata @question.questiontext
            end
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
        elsif ['saq','laq','vsaq','project','desc'].include? @question.qtype
          xml.question_text{
            if @question.is_passage_question?
              xml.cdata "<div id='groupQuestion'><p><span style='font-family:&quot;Segoe UI&quot;,&quot;sans-serif&quot;'>#{@question.passage_question.questiontext}</span><br></div>"+@question.questiontext
            else
              xml.cdata @question.questiontext
            end
          }
          i = 0
          options = ("a".."z").to_a
          4.times.each do |o|
            tag =options[i]
            xml.option(:id=>1234.to_s,:tag=>tag,:answer=>"false"){
              xml.option_text{
                xml.cdata ""
              }
              xml.feedback{
                xml.cdata ""
              }
            }
            i = i+1
          end
        end
      }
    }
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

  def get_quiz_passage_questions(passage_question,quiz)
    @quiz.quiz_question_instances.where(:question_id=>passage_question.questions.map(&:id))
  end

  def get_reference_tags
    @tag_ids = params[:id].split(',')
    tag_name = params[:name]
    publisher_question_bank_id = params[:publisher_question_bank_id]
    # @tag_refs = TagReference.where(:institution_id => current_user.institution_id,:tag_id=>@tag_ids).group(:tag_refer_id).having('COUNT(*) = ?', @tag_ids.count)
    @tag_refs = TagReference.where(:publisher_question_bank_id => publisher_question_bank_id,:tag_id=>@tag_ids).group(:tag_refer_id).having('COUNT(DISTINCT tag_id) >= ?', @tag_ids.count)
    @tags = Tag.where(:id=>@tag_refs.map(&:tag_refer_id),:name=>tag_name)
    @list = @tags.map {|u| Hash[value: u.id, name: u.value]}
    render json: @list
  end

  def get_live_tags
    selected_values = params
    puts "-----------------------#{selected_values}---------------"
    logger.info "********************************************************"
    logger.info "*********************#{selected_values}***********************************"
    qb_id = selected_values[:qb_id]
    r = RedisInteract::Reading.new
    live_tags = r.get_live_tags(qb_id, selected_values) # Instead of picking each tag, we are sending the whole hash which also includes qb_id
    data = {
        bl_tgs: r.get_tag_hashes(live_tags[:bl_tg_ids]),
        dl_tgs: r.get_tag_hashes(live_tags[:dl_tg_ids]),
        sc_tgs: r.get_tag_hashes(live_tags[:sc_tg_ids]),
        ty_tgs: r.get_ty_tag_hashes(live_tags[:ty_tg_ids])
    }
    data[:ac_tgs]= r.get_tag_hashes(live_tags[:ac_tg_ids]) if !live_tags[:ac_tg_ids].nil?
    data[:su_tgs]= r.get_tag_hashes(live_tags[:su_tg_ids]) if !live_tags[:su_tg_ids].nil?
    data[:ch_tgs]= r.get_tag_hashes(live_tags[:ch_tg_ids]) if !live_tags[:ch_tg_ids].nil?
    data[:co_tgs]= r.get_tag_hashes(live_tags[:co_tg_ids]) if !live_tags[:co_tg_ids].nil?
    render json: data

  end

  def generate_reports
    respond_to do |format|
      format.pdf do
        render :pdf => @quiz.name,
               :disposition => 'attachment',
               :wkhtmltopdf => '/usr/local/bin/wkhtmltopdf', # path to binary
               :template=>"assessment_tool/new_pdf_download.html.erb",
               :input=>@result.to_json,
               :print_media_type => true
      end
    end
  end

  def generate_assessment_analytics_reports
    quiz_targeted_group_id = params[:quizTargetedGroupId]
    quiz_targeted_groups_ids = params[:quizTargetedGroupscompareIds].split(',')
    @quiz_targeted_group = QuizTargetedGroup.find(quiz_targeted_group_id)
    @quiz_targeted_groups = QuizTargetedGroup.where(:id=>quiz_targeted_groups_ids)
    misc =  quiz_targeted_groups_ids.nil? ?  "" : quiz_targeted_groups_ids.join(',')
    task = @quiz_targeted_group.assessment_reports_tasks.create(:created_by=> current_user.id, :misc => misc)
    task.being_processed!

    @quiz_targeted_group.quiz_attempts.group(:user_id).each do |quiz_attempt|
      job = task.assessment_pdf_jobs.create(:recipient_id => quiz_attempt.user_id, :recipient_type=> quiz_attempt.user.class.name)
      job.delay(:queue => "reports", :priority=>3).generate_pdf quiz_targeted_groups_ids, @quiz_targeted_group.id, quiz_attempt.id, task.id
    end

    respond_to do |format|
      format.html {redirect_to assessment_tool_assessment_reports_path(@quiz_targeted_group.quiz.id)}
    end

  end

  def assessment_statistics
    @quiz = Quiz.find(params[:assessment])
    @json_data = {
        assessmentDetails: Quiz.generate_enhanced_assessment_details(@quiz),
        publishDetails: []
    }
    @quiz.quiz_targeted_groups.order("id desc").each {|quiz_targeted_group|
      publishDetail ={}
      publishDetail[:staticPublishDetails]= Quiz.generate_static_publish_details(quiz_targeted_group)
      publishDetail[:dynamicPublishInfo]= Quiz.generate_dynamic_publish_info(quiz_targeted_group)
      @json_data[:publishDetails] << publishDetail
    }

  end

  def get_dynamic_stat_info
    @quiz_targeted_group = QuizTargetedGroup.find(params[:publish_id])
    dynamic_data = Quiz.generate_dynamic_publish_info(@quiz_targeted_group)
    respond_to do |format|
      format.json {render json: dynamic_data}
    end
  end


  def get_contents

    @content_ids = params[:id].split(',')
    @content_name = params[:name].humanize
    @content_value = params[:value]

    if @content_name == "Content year"
      @contents = ContentYear.where("#{@content_value} IN (?)",@content_ids)
    elsif @content_name == 'Subject'
      @contents = Subject.where("#{@content_value} IN (?)",@content_ids)
    elsif @content_name == 'Chapter'
      @contents = Chapter.where("#{@content_value} IN (?)",@content_ids)
    elsif @content_name == 'Topic'
      @contents = Topic.where("#{@content_value} IN (?)",@content_ids)
    end
    @list = @contents.map {|u| Hash[value: u.id, name: u.name]}
    render json: @list

  end

  def get_view_report_partial
    @task = AssessmentReportsTask.find(params[:task])
    respond_to do |format|
      format.js
    end
  end

  def manage_questions
    if params.has_key? :p
      @p = params[:p]
    else
      @p = 0
    end
    @quiz = Quiz.new
    @quiz.build_quiz_detail
    @quiz.build_context
    @publisher_question_banks = []
    if current_user.is? "ECP"
      @publisher_question_banks = current_user.publisher_question_banks
      @publisher_question_bank = current_user.publisher_question_banks.first
    else
      #if it is an old institution, their views will receive and empty array of publisher question banks which is of no consequence
      # for them tag builder is not even rendered
      if current_user.institution.user_configuration.use_tags
        current_user.institution.create_publisher_question_bank unless current_user.institution.publisher_question_banks.present?
        @publisher_question_banks = current_user.institution(true).publisher_question_banks(true)
        @publisher_question_bank = current_user.institution.publisher_question_banks.first
      end
      @boards = current_user.institution.boards
    end
    @board,@qdbs = assign_question_banks
    @tags = ["difficulty_level", "blooms_taxonomy", "specialCategory"]
  end


  def duplicate_assessment
    @assessment = Quiz.find(params[:quiz])
    @quiz = Quiz.new
    @instruction = Instruction.new
    @instructions = Instruction.where(user_id:current_user.id)
    @present_instruction = Instruction.where(user_id:current_user.id,is_live:true).first
    @quiz.build_quiz_detail
    @quiz.build_context
    @board = current_user.institution.boards.first unless current_user.is? "ECP"
  end


  def copy_assessment_questions(quiz,assessment)
    if assessment.format_type !=1
      sections = []
      if !assessment.quiz_sections.empty?
        assessment.quiz_sections.each do |s|
          if !s.children_sections.empty?  and !sections.include?(s.id)
            quiz_section = QuizSection.create(:name=>s.name,:quiz_id=>quiz.id,:intro=>s.intro)
            s.children_sections.each do |sc|
              if !sc.quiz_question_instances.empty? and !sections.include?(sc.id)
                quiz_child_section = QuizSection.create(:name=>sc.name,:quiz_id=>quiz.id,:intro=>sc.intro,:parent_id=>quiz_section.id)
                sc.quiz_question_instances.each do |q|
                  QuizQuestionInstance.create(:quiz_id=>quiz.id,:quiz_section_id=>quiz_child_section.id,:question_id=>q.question_id,:grade=>q.grade,:penalty=>q.penalty,:position=>q.position)
                end
                sections << sc.id
              end
            end

          else
            if !s.quiz_question_instances.empty? and !sections.include?(s.id)
              quiz_section = QuizSection.create(:name=>s.name,:quiz_id=>quiz.id,:intro=>s.intro)
              s.quiz_question_instances.each do |q|
                QuizQuestionInstance.create(:quiz_id=>quiz.id,:quiz_section_id=>quiz_section.id,:question_id=>q.question_id,:grade=>q.grade,:penalty=>q.penalty,:position=>q.position)
              end
              sections << s.id
            end
          end
        end
      else
        if !assessment.quiz_question_instances.empty?
          assessment.quiz_question_instances.each do |q|
            QuizQuestionInstance.create(:quiz_id=>quiz.id,:question_id=>q.question_id,:grade=>q.grade,:penalty=>q.penalty,:position=>q.position)
          end
        end

      end
    else
      sql = "INSERT INTO `quiz_question_instances` (`quiz_id`,`question_id`,`grade`,`penalty`) SELECT #{quiz.id},question_id,grade,penalty FROM `quiz_question_instances` WHERE quiz_id=#{assessment.id}"
      ActiveRecord::Base.connection.execute(sql)
      if !assessment.asset.nil?
        old_asset = Asset.find(assessment.asset.id)
        new_asset = old_asset.dup
        new_asset.archive_id = quiz.id
        new_asset.save
      end
    end
  end

  def valid_for_save(question)
    return false if question.questiontext.blank?
    if (question.qtype=="multichoice" || question.qtype=="truefalse")
      if question.question_answers.empty?
        return false
      else
        question.question_answers.each {|question_answer|
          return true if question_answer.fraction==1
        }
        return false
      end
    elsif question.qtype=="fib"
      if question.question_fill_blanks.empty?
        return false
      else
        return true
      end
    else
      return true
    end
  end

  def passage_question_valid_for_save(passage_question)
    return false if passage_question.questiontext.blank?
    if passage_question.questions.to_a.count !=0
      passage_question.questions.each{|question|
        if !valid_for_save(question)
          return false
        end
      }
      return true
    else
      logger.info "============#{passage_question.inspect}, ======== bang bang ========== #{passage_question.questions}"
      return true
    end
  end

  def delete_old_tags
    @question = Question.find(params[:question][:id])
    @dtag_ids = @question.tags.where("name = ? or name =? or name =? or name=? or name = ? or name =? or name =? or name=? or name=?", "academic_class", "qsubtype", "subject", "chapter","course", "difficulty_level", "concept_names", "blooms_taxonomy", "specialCategory").map(&:id)
    Tagging.where({tag_id:@dtag_ids,question_id:@question.id}).destroy_all
  end

  def add_qsubtype
    @question = Question.find(params[:question][:id])
    @question.add_tags('qsubtype', @question.qtype)
  end


  def add_question_to_publisher_question_bank(publisher_question_bank_id,question)
    unless publisher_question_bank_id.nil?
      PublisherQuestionBank.find(publisher_question_bank_id).questions << question
    end

  end
  def remove_question
    question_id = params[:id]
    @qu_id = question_id.to_i
    question= Question.find(question_id)
    @qb_ids = []
    if current_user.is? "ECP"
      publisher_question_banks = current_user.publisher_question_banks
    else
      publisher_question_banks = current_user.institution.publisher_question_banks
    end
    unless publisher_question_banks.empty?
      publisher_question_banks.each do |publisher_question_bank|
        publisher_question_bank.questions.delete(question)
        question.update_attribute(:hidden,true)
        @qb_ids << publisher_question_bank.id
      end
    end
    #self.delay.update_redis_server_after_question_removal_from_qb
    if @qu_id.present?
      question.update_redis_server_after_question_removal_from_qb(@qb_ids)
    end
    #Delayed::Job.enqueue update_redis_server_after_question_removal_from_qb, :queue => "reports"
    redirect_to :back , flash:{success:" The question is being removed from all your question banks"}

  end

  def send_assessment_reports
    @reports =  AssessmentPdfJob.where(:id=>params[:reports].split('-'))
    @task = AssessmentReportsTask.find(params[:task])
    @reports.each do |r|
      begin
        @message = Message.new
        @message.body = {publish_id: @task.parent_obj_id}.to_json
        @asset = @message.assets.build
        @asset.attachment = File.open(r.asset.attachment.path)
        @message.recipient_id = r.recipient_id
        @message.subject = "PDF report for assessment #{QuizTargetedGroup.find(@task.parent_obj_id).quiz.name} "
        @message.message_type = "Report"
        @message.sender_id = current_user.id
        @message.save
        r.report_deliver! if r.state == 'accepted'
      rescue Exception => e
        next
      end
    end
    respond_to do |format|
      format.js
    end
  end

  def key_interface
    @publish = QuizTargetedGroup.find(params[:publish_id])
    @assessment = @publish.quiz
    @serialized_key_questions = @publish.serialized_key.present? ? @publish.serialized_key[:received_key][:questions] : false
    @key_update = @publish.serialized_key.present? ? @publish.serialized_key[:key_updates][:questions] : false
  end

  def change_key_and_publish
    # Please note that the received key doesn't contain passage and descriptive questions
    received_key = {publish_id: params[:publish_id], questions: params[:questions]}
    @quiz_targeted_group = QuizTargetedGroup.find(params[:publish_id])
    key_updates = filter_updated_keys(received_key.deep_dup, @quiz_targeted_group)
    @quiz_targeted_group.serialized_key = {received_key: received_key, key_updates: key_updates}
    @quiz_targeted_group.save validate: false
    @reevaluation_task = @quiz_targeted_group.assessment_reevaluation_tasks.create(status: :queued)
    @reevaluation_task.delay.reevaluate(@quiz_targeted_group)
    @message = Message.new
    @message.body = @quiz_targeted_group.serialized_key.to_json
    @message.message_type = 'testkeyupdate'
    @message.subject= "Key got updated for #{@quiz_targeted_group.quiz.name}"
    if @quiz_targeted_group.group_id.present?
      @message.group_id = @quiz_targeted_group.group_id
    else
      @message.recipient_id = @quiz_targeted_group.recipient_id
    end
    @message.sender_id = current_user.id
    @message.save
    redirect_to :back, notice: "Results successfully queued for re-evaluation and updated key published to tabs. The results on the portal will be updated within 24 hours. Please generate reports only after 24 hours."
    # render :json => @quiz_targeted_group.serialized_key
  end

  def upload_solutions
    @publish = QuizTargetedGroup.find(params[:publish_id])
  end

  def send_solutions
    @quiz_targeted_group = QuizTargetedGroup.find(params[:publish_id])
    @message = Message.new
    @message.body = {publish_id: @quiz_targeted_group.id}.to_json
    @asset = @message.assets.build
    @asset.attachment = params[:asset]
    @message.message_type = 'testsolutions'
    @message.subject= "Solutions attached to the assessment: #{@quiz_targeted_group.quiz.name}"
    if @quiz_targeted_group.group_id.present?
      @message.group_id = @quiz_targeted_group.group_id
    else
      @message.recipient_id = @quiz_targeted_group.recipient_id
    end
    @message.sender_id = current_user.id
    @message.save
    redirect_to assessment_tool_publish_path(@quiz_targeted_group.quiz), notice: "Solutions successfully sent"
  end

  def filter_updated_keys(received_key, quiz_targeted_group)
    previous_serialized_key_questions = quiz_targeted_group.serialized_key.present? ? quiz_targeted_group.serialized_key[:received_key][:questions] : false
    received_key[:questions].each do |question_id, qhash|
      key_changed = detect_key_change(question_id, qhash, previous_serialized_key_questions)
      # key is still considered as changed even if key is not changed but flags are present in the html form data
      received_key[:questions].delete question_id unless (qhash.has_key?(:flag) || key_changed)
    end
    received_key
  end

  def detect_key_change(question_id, qhash, previous_serialized_key_questions)
    key_changed = false
    question = Question.find(question_id)
    if previous_serialized_key_questions.present?
      if ["multichoice", "truefalse"].include? question.qtype
        previous_serialized_key_questions[question_id.to_s][:question_answers]||=[]
        qhash[:question_answers]||=[]
        if previous_serialized_key_questions[question_id.to_s][:question_answers].sort!=qhash[:question_answers].sort
          key_changed = true
        end
      elsif question.qtype=="fib"
        if previous_serialized_key_questions[question_id.to_s][:question_fill_blanks].map { |qfbid, value| value }.sort != qhash[:question_fill_blanks].map { |qfbid, value| value }.sort
          key_changed = true
        end
      else
        key_changed = false
      end
    else
      if ["multichoice", "truefalse"].include? question.qtype
        original_correct_choice_ids = question.question_answers.select { |qa| qa.fraction.to_i==1 }.map(&:id)
        if qhash.has_key? :question_answers
          key_changed = true unless original_correct_choice_ids.map(&:to_s).sort==qhash[:question_answers].sort
        end
      elsif question.qtype=="fib"
        original_correct_fill_blanks = question.question_fill_blanks.map(&:answer)
        logger.info "-----------------#{qhash}-----------------------"
        key_changed = true unless original_correct_fill_blanks.sort==qhash[:question_fill_blanks].map { |qfbid, value| value }.sort
      else
        key_changed = false
      end
    end
    key_changed
  end


  def download_attempt_data
    @quiz_targeted_group = QuizTargetedGroup.find(params[:publish_id])
    xml_data = @quiz_targeted_group.generate_student_attempt_data_xml
    send_data xml_data, type: "text/xml; charset=UTF-8;", :disposition => "attachment;filename=AttemptData#{Time.now.to_i}.xml"
    # render xml:xml_data
  end

  #   Redis DB maintenance functions
  def update_redis_server_after_question_creation
    if (@qu_id && @qb_id)
      begin
        p = RedisInteract::Plumbing.new
        p.update_redis_server_after_question_creation(@qb_id, @qu_id)
          #   Since redis server may or may not be online at the time of calling this function, we shall prevent excpetions
      rescue Exception => e
        logger.info "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee#{e}eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        return
      end
    end
  end

  def update_redis_server_after_question_updation
    if (@qu_id)
      qb_ids = Question.find(@qu_id).publisher_question_bank_ids
      if(qb_ids.present?)
        begin
          p = RedisInteract::Plumbing.new
          qb_ids.each {|qb_id| p.update_redis_server_after_question_updation(qb_id, @qu_id)}
            #   Since redis server may or may not be online at the time of calling this function, we shall prevent excpetions
        rescue Exception => e
          logger.info "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee#{e}eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
          return
        end
      end
    end
  end

  def publish_ecp_assessment
    @quiz = Quiz.find(params[:format])
    @target = QuizTargetedGroup.new
    @message = Message.new

    @target.quiz_id = @quiz.id
    @target.published_by = current_user.id
    # params[:message_to] = "individual"
    # params[:quiz_targeted_group][:to_group] = "0"
    #params[:assessment_type] = "2"
    @message.multiple_recipient_ids = "1"
    @message.subject = "This is a Practice Test"
    @message.body = "All the best"
    #params[:timeclose[li]] = "2016"
    # params[:quiz_targeted_group][:timeclose]= params[:quiz_targeted_group][:timeclose].to_datetime.to_i
    recipients = [1]

    # if params[:quiz_targeted_group][:to_group].to_i == 0
    #   #logger.info"=========================1"
    #   if recipients.empty?
    #     #logger.info"=====================2"
    #     @target = QuizTargetedGroup.new(params[:quiz_targeted_group])
    #     respond_to do |format|
    #       @target.errors.add :recipient_id, "Please select atleast one individual user"
    #       format.html { render action: "publish_to"}
    #       format.json { render json: @quiz.errors, status: :unprocessable_entity }
    #     end
    #     return
    #   end
    @target.group_id = nil
    @target.to_group = false
    ActiveRecord::Base.transaction do
      recipients.each do |rep|
        @target.recipient_id = rep
        if @target.save!(:validate=>false)
          create_message
          redirect_to assessment_tool_my_assessments_path(current_user)
          #return
        else
          respond_to do |format|
            format.html { render action: "publish_to" }
            format.json { render json: @quiz.errors, status: :unprocessable_entity }
          end
          return
        end
      end
    end
  end
  # def update_redis_server_after_question_removal_from_qb
  #   if @qu_id.present?
  #     begin
  #       p = RedisInteract::Plumbing.new
  #       @qb_ids.each { |qb_id| p.update_redis_server_after_question_removal_from_qb(qb_id, @qu_id) }
  #         #   Since redis server may or may not be online at the time of calling this function, we shall prevent excpetions
  #     rescue Exception => e
  #       logger.info "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee#{e}eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
  #       return
  #     end
  #   end
  # end
end
