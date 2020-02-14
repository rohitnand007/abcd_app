class QuestionsController < ApplicationController
  authorize_resource
  EDUTOR = 1
  # GET /questions
  # GET /questions.json
  # GET /questionbank
  def index
    values = {}
    @context = Context.new
    #@boards = current_user.institution.boards
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
    @filter_database = current_user.institution.nil? ? EDUTOR : current_user.institution.id
    logger.info"=====#{@filter_database}"
    if params[:filter_database].present?
      @filter_database = params[:filter_database]
    end
    @boards = get_boards(@filter_database)
    @databases = get_all_databases
    #logger.debug(@databases.inspect)
    values[:institution_id] = @filter_database
    where = "questions.institution_id = :institution_id AND questions.hidden = :hidden"
    if params[:context]
      if params[:context][:content_year_id].present?
        @context.content_year_id = params[:context][:content_year_id]
        values[:content_year_id] = params[:context][:content_year_id]
        where = where+ " AND contexts.content_year_id= :content_year_id"
      end
      if params[:context][:subject_id].present?
        @context.subject_id = params[:context][:subject_id]
        values[:subject_id] = params[:context][:subject_id]
        where = where+ " AND contexts.subject_id= :subject_id"
      end
      if params[:context][:chapter_id].present?
        @context.chapter_id = params[:context][:chapter_id]
        values[:chapter_id] = params[:context][:chapter_id]
        where = where+ " AND contexts.chapter_id= :chapter_id"
      end
      if params[:context][:board_id].present?
        @context.board_id = params[:context][:board_id]
        values[:board_id] = params[:context][:board_id]
        where = where+ " AND contexts.board_id= :board_id"
      end
      if params[:context][:topic_id].present?
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
    @questions = Question.joins(:context).where(where,values).order('id DESC')
    @x = @questions.size
    @questions = @questions.page(params[:page])
    @main_heading = 'Question Bank'
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @questions }
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
      #return Board.all
      #ids = [25001,25005,25009,25906]
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
    d[1] = "Edutor"  if current_user.id == 26720 # or current_user.institution_id == 14289
    d[current_user.institution_id] = Institution.find(current_user.institution_id).profile.firstname
    return d
  end

  def createimage
    t = Time.now.to_i
    if params[:save]
      type = params[:type]
      if params[:name].present? && (type=="JPG" || type=="PNG")
        img = Base64.decode64(params[:image])
        FileUtils.mkdir_p Rails.root.to_s+"/public/question_images/"+current_user.id.to_s+"_#{t}"
        File.open(Rails.root.to_s+"/public/question_images/"+current_user.id.to_s+"_#{t}/#{params[:name].to_s}.#{type}",  "w+b", 0644) do |f|
          f.write(img)
        end
        #render :text => "http://localhost:3000/question_images/"+current_user.id.to_s+"_#{t}/#{params[:name].to_s}.#{type}"
        render :text => "/question_images/"+current_user.id.to_s+"_#{t}/#{params[:name].to_s}.#{type}"
      end
    end
  end

  def image_upload
  end

  def submit_image
    t = Time.now.to_i
    if params[:image].present?
      uploaded_io = params[:image]
      FileUtils.mkdir_p Rails.root.to_s+"/public/question_images/"+current_user.id.to_s+"_#{t}"
      File.open(Rails.root.to_s+"/public/question_images/"+current_user.id.to_s+"_#{t}/#{uploaded_io.original_filename}",  "w+b", 0644) do |f|
        f.write(uploaded_io.read)
      end
    end
    @filename = current_user.id.to_s+"_#{t}/#{uploaded_io.original_filename}"
    respond_to do |format|
      format.html  { render "image_upload" }
      #format.json { render json: @question }
    end
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


  # GET /questions/1
  # GET /questions/1.json
  def show
    @question = Question.find(params[:id])
    #if !(@question.accessible(current_user.id, current_user.institution_id))
    #  respond_to do |format|
    #    format.html  { redirect_to action: "index" }
    #    #format.json { render json: @question }
    #  end
    #  return
    #end
    @listed_tags = ["concept_names", "academic_class", "chapter", "blooms_taxonomy", "subject", "course", "qsubtype", "specialCategory", "difficulty_level"]
    @edit_copy = 'copy'
    if (@question.edit_access(current_user.id))
      @edit_copy = 'edit'
    end
    #@can_delete =  @question.join(:quiz_question_instances).join(:quiz_targeted_groups)
    values = {}
    where = "quiz_question_instances.question_id = :question_id"
    values[:question_id] = params[:id]
    @used = nil #Quiz.select("quizzes.id,quizzes.name").joins(:quiz_question_instances).select("quiz_question_instances.grade").joins(:quiz_targeted_groups).select("published_on,published_by").where(where,values).order('quizzes.timecreated DESC')
    respond_to do |format|
      format.html { render "show_"+@question.qtype}
      format.json { render json: @question }
    end
  end

  def history
    @question = Question.find(params[:id])
    if !(@question.accessible(current_user.id, current_user.institution_id))
      respond_to do |format|
        format.html  { redirect_to action: "index" }
        #format.json { render json: @question }
      end
      return
    end
    @filter_history= ""
    values = {}
    where = "quiz_question_instances.question_id = :question_id"
    values[:question_id] = params[:id]

    if params[:filter_history].present? && params[:filter_history] == 'usedbyme'
      @filter_history= params[:filter_history]
      where = where+" AND quizzes.createdby = :createdby"
      values[:createdby] = current_user.id
    else
      where = where+" AND quizzes.institution_id = :institution_id"
      if current_user.institution_id.nil?
        values[:institution_id] = current_user.id
      else
        values[:institution_id] = current_user.institution_id
      end
    end
    @used = Quiz.select("quizzes.id,quizzes.name").joins(:quiz_question_instances).select("quiz_question_instances.grade").joins(:quiz_targeted_groups).select("published_on,published_by").where(where,values).order('quizzes.timecreated DESC')
  end

  # GET /questions/new
  # GET /questions/new.json
  def new
    @question = Question.new
    respond_to do |format|
      format.html # new.html.erb
                  #format.json { render json: @question }
    end
  end

  # GET /questions/1/edit
  def edit
    @action = "update"
    @question = Question.find(params[:id])
    if !(@question.edit_access(current_user.id))
      respond_to do |format|
        format.html  { redirect_to action: "index" }
        #format.json { render json: @question }
      end
      return
    end
    @boards = get_boards
    if @question
      respond_to do |format|
        format.html  { render @question.qtype.to_s }
        #format.json { render json: @question }
      end
    end
  end

  # POST /questions
  # POST /questions.json
  def create
    @action = "save"
    if params[:qtype].nil?
      flash[:notice] = "Please select the format of the question you want to create."
      respond_to do |format|
        format.html { redirect_to action: "new" }
        #format.json { render json: @question }
      end
      return
    end

    @question = Question.new
    @boards = get_boards
    @question.build_context

    if params[:qtype]=='multichoice'
      @question.qtype = 'multichoice'
      @qtype = 'New MCQ Question'
      (1..4).each do
        @question.question_answers.build
      end
      #@choices = Array.new(3) { @question.question_multichoice.build }
      respond_to do |format|
        format.html  { render "multichoice" }
        #format.json { render json: @question }
      end
    end

    if params[:qtype]=='truefalse'
      @question.qtype = 'truefalse'
      @qtype = 'New True/False Question'
      @question.question_answers_attributes = [{:answer=>'True'},{:answer=>'False'}]
      respond_to do |format|
        format.html  { render "truefalse" }
        #format.json { render json: @question }
      end
    end

    if params[:qtype]=='match'
      @question.qtype = 'match'
      @qtype = 'New Match the Following Question'
      (1..4).each do
        @question.question_match_subs.build
      end
      respond_to do |format|
        format.html  { render "match" }
        #format.json { render json: @question }
      end
    end

    if params[:qtype]=='parajumble'
      @question.qtype = 'parajumble'
      @qtype = 'New Parajumble Question'
      @question.question_parajumbles_attributes = [{:order=>1},{:order=>2},{:order=>3},{:order=>4}]
      respond_to do |format|
        format.html  { render "parajumble" }
        #format.json { render json: @question }
      end
    end

    if params[:qtype]=='fib'
      @question.qtype = "fib"
      @qtype = "New Fill In The Blank Question"
      @question.question_fill_blanks.build
      respond_to do |format|
        format.html {render "fib"}
      end
    end


    return
    respond_to do |format|
      format.html  { render action: "new" }
      #format.json { render json: @question }
    end
    return
    @question = Question.new(params[:question])

    respond_to do |format|
      if @question.save
        format.html { redirect_to @question, notice: 'Question was successfully created.' }
        format.json { render json: @question, status: :created, location: @question }
      else
        format.html { render action: "new" }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  def save
    if !params[:question].nil?
      saveq
    end
  end

  def saveq
    params[:question][:createdby] = current_user.id
    params[:question][:institution_id] = current_user.id
    params[:question][:center_id] = current_user.id
    if !current_user.institution_id.nil?
      params[:question][:institution_id] = current_user.institution_id
    end
    if !current_user.center_id.nil?
      params[:question][:center_id] = current_user.center_id
    end
    @question = Question.new(params[:question])

    respond_to do |format|
      if @question.save!
        format.html { redirect_to @question, notice: 'Question was successfully created.' }
        format.json { render json: @question, status: :created, location: @question }
      else
        @action = 'save'
        @boards = get_boards
        format.html { render params[:question][:qtype].to_s }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  def myquestions
    values = {}
    @context = Context.new
    #@boards = current_user.institution.boards
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
    @filter_database = ""
    if current_user.institution_id.nil?
      @filter_database = current_user.id
    else
      @filter_database = current_user.institution_id
    end
    @boards = get_boards(@filter_database)
    @databases = get_my_databases
    values[:createdby] = current_user.id
    where = "questions.createdby = :createdby AND questions.hidden = :hidden"
    if params[:context]
      if params[:context][:content_year_id].present?
        @context.content_year_id = params[:context][:content_year_id]
        values[:content_year_id] = params[:context][:content_year_id]
        where = where+ " AND contexts.content_year_id= :content_year_id"
      end
      if params[:context][:subject_id].present?
        @context.subject_id = params[:context][:subject_id]
        values[:subject_id] = params[:context][:subject_id]
        where = where+ " AND contexts.subject_id= :subject_id"
      end
      if params[:context][:chapter_id].present?
        @context.chapter_id = params[:context][:chapter_id]
        values[:chapter_id] = params[:context][:chapter_id]
        where = where+ " AND contexts.chapter_id= :chapter_id"
      end
      if params[:context][:board_id].present?
        @context.board_id = params[:context][:board_id]
        values[:board_id] = params[:context][:board_id]
        where = where+ " AND contexts.board_id= :board_id"
      end
      if params[:context][:topic_id].present?
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
    @questions = Question.joins(:context).where(where,values).order('id DESC').page(params[:page])
    @main_heading = 'Question Bank'
    respond_to do |format|
      format.html  { render action: "index" }
      format.json { render json: @questions }
    end
  end

  def mydraftedquestions
    values = {}
    @context = Context.new
    #@boards = current_user.institution.boards
    values[:hidden] = 1
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
    @filter_database = ""
    if current_user.institution_id.nil?
      @filter_database = current_user.id
    else
      @filter_database = current_user.institution_id
    end
    @boards = get_boards(@filter_database)
    @databases = get_my_databases
    values[:createdby] = current_user.id
    where = "questions.createdby = :createdby AND hidden= :hidden"
    if params[:context]
      if params[:context][:content_year_id].present?
        @context.content_year_id = params[:context][:content_year_id]
        values[:content_year_id] = params[:context][:content_year_id]
        where = where+ " AND contexts.content_year_id= :content_year_id"
      end
      if params[:context][:subject_id].present?
        @context.subject_id = params[:context][:subject_id]
        values[:subject_id] = params[:context][:subject_id]
        where = where+ " AND contexts.subject_id= :subject_id"
      end
      if params[:context][:chapter_id].present?
        @context.chapter_id = params[:context][:chapter_id]
        values[:chapter_id] = params[:context][:chapter_id]
        where = where+ " AND contexts.chapter_id= :chapter_id"
      end
      if params[:context][:board_id].present?
        @context.board_id = params[:context][:board_id]
        values[:board_id] = params[:context][:board_id]
        where = where+ " AND contexts.board_id= :board_id"
      end
      if params[:context][:topic_id].present?
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
    @questions = Question.joins(:context).where(where,values).order('id DESC').page(params[:page])
    @main_heading = 'Question Bank'
    respond_to do |format|
      format.html  { render action: "index" }
      format.json { render json: @questions }
    end
  end

  # PUT /questions/1
  # PUT /questions/1.json
  def update
    @question = Question.find(params[:id])
    if !(@question.edit_access(current_user.id))
      #logger.debug("--------------------------------------redirected")
      respond_to do |format|
        format.html  { redirect_to action: "index" }
        #format.json { render json: @question }
      end
      return
    end

    respond_to do |format|
      if @question.update_attributes(params[:question])
        format.html { redirect_to @question, notice: 'Question was successfully updated.' }
        format.json { head :ok }
      else
        @boards = get_boards
        @action = "update"
        format.html { render action: @question.qtype.to_s }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /questions/1
  # DELETE /questions/1.json
  def destroy
    @question = Question.find(params[:id])
    if (@question.edit_access(current_user.id) and Question.joins(:quiz_question_instances=>[:quiz=>:quiz_targeted_groups]).where(:id=>params[:id]).empty?)
      @question.destroy
      respond_to do |format|
        format.html { redirect_to questions_url }
        format.json { head :ok }
      end
    else
      respond_to do |format|
        flash[:notice] = "Question cannot be deleted"
        format.html  { redirect_to action: "index" }
        #format.json { render json: @question }
      end
    end

  end

  def copy
    @old_question = Question.find(params[:id])
    @action = "copysave"
    if !(@old_question.accessible(current_user.id, current_user.institution_id))
      respond_to do |format|
        format.html  { redirect_to action: "index" }
        #format.json { render json: @question }
      end
    end
    @boards = get_boards
    @question = @old_question.dup
    #@question.context_attributes = [{:board_id=>@old_question.context.board_id},{:content_year_id=>@old_question.context.content_year_id,:subject_id=>@old_question.context.subject_id,:chapter_id=>@old_question.context.chapter_id,:topic_id=>@old_question.context.topic_id,:id=>nil}]
    if @old_question
      respond_to do |format|
        format.html  { render @old_question.qtype.to_s }
        #format.json { render json: @question }
      end
    end
  end

  def copysave
    if !params[:question].nil?
      params[:question][:createdby] = current_user.id
      params[:question][:institution_id] = current_user.id
      params[:question][:center_id] = current_user.id
      if !current_user.institution_id.nil?
        params[:question][:institution_id] = current_user.institution_id
      end
      if !current_user.center_id.nil?
        params[:question][:center_id] = current_user.center_id
      end
      params[:question][:context_attributes].delete(:id)
      @question = Question.new(params[:question])
      respond_to do |format|
        if @question.save
          format.html { redirect_to @question, notice: 'Question was successfully created.' }
          format.json { render json: @question, status: :created, location: @question }
        else
          @action = 'copysave'
          @boards = get_boards
          #@question.build_context
          #logger.debug(@question.errors)
          format.html { render params[:question][:qtype].to_s }
          format.json { render json: @question.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def pdf_download
    @context = Context.new
    values = {}
    if params[:context][:board_id].present?
      @context.board_id = params[:context][:board_id]
      values[:board_id] = params[:context][:board_id]
      where = "contexts.board_id= :board_id"
    end
    if params[:context][:content_year_id].present?
      @context.content_year_id = params[:context][:content_year_id]
      values[:content_year_id] = params[:context][:content_year_id]
      where = where+ " AND contexts.content_year_id= :content_year_id"
    end
    if params[:context][:subject_id].present?
      @context.subject_id = params[:context][:subject_id]
      values[:subject_id] = params[:context][:subject_id]
      where = where+ " AND contexts.subject_id= :subject_id"
    end
    if params[:context][:chapter_id].present?
      @context.chapter_id = params[:context][:chapter_id]
      values[:chapter_id] = params[:context][:chapter_id]
      where = where+ " AND contexts.chapter_id= :chapter_id"
    end
    if params[:context][:topic_id].present?
      @context.topic_id = params[:context][:topic_id]
      values[:topic_id] = params[:context][:topic_id]
      where = where+ " AND contexts.topic_id= :topic_id"
    end
    @questions = Question.joins(:context).where(where,values).order('id DESC')
    respond_to do |format|
      format.pdf do
        render :pdf => "Test",
               :disposition => 'attachment',
               :template=>"questions/pdf_download.html.erb",
               :header => { :right => '[page] of [topage]' } ,
               :footer => {
                   :left => "Rectores Lideres Transformadores",
                   :right => "#{Time.now}",
                   :font_size => 5,
                   :center => '[page] de [topage]'},
               :show_as_html=>false,
               :disable_external_links => true,
               :print_media_type => true
      end
      #pdf = render_to_string :pdf => "some_file_name",
      #                       :disposition => 'attachment',
      #                       :template=>"questions/pdf_download.html.erb",
      #                       :disable_external_links => true,
      #                       :print_media_type => true
      #path = Rails.root.to_s+"/tmp/cache"
      #file = File.new(path+"/"+"#{Time.now.to_i}_"+"test.pdf", "w+")
      #File.open(file,'wb') do |f|
      #  f << pdf
      #end
    end
  end

  def questions_download
    @context = Context.new

  end

  def question_ids
    questions = Question.where(:id=>params[:term])
    render json: questions.map{|q| Hash[id: q.id,name: q.id.to_s]}
  end


  def new_questions_download
    @context = Context.new
  end


  def new_pdf_download
    @context = Context.new
    values = {}
    if params[:context][:board_id].present?
      @context.board_id = params[:context][:board_id]
      values[:board_id] = params[:context][:board_id]
      where = "contexts.board_id= :board_id"
    end
    if params[:context][:content_year_id].present?
      @context.content_year_id = params[:context][:content_year_id]
      values[:content_year_id] = params[:context][:content_year_id]
      where = where+ " AND contexts.content_year_id= :content_year_id"
    end
    if params[:context][:subject_id].present?
      @context.subject_id = params[:context][:subject_id]
      values[:subject_id] = params[:context][:subject_id]
      where = where+ " AND contexts.subject_id= :subject_id"
    end
    if params[:context][:chapter_id].present?
      @context.chapter_id = params[:context][:chapter_id]
      values[:chapter_id] = params[:context][:chapter_id]
      where = where+ " AND contexts.chapter_id= :chapter_id"
    end
    if params[:context][:topic_id].present?
      @context.topic_id = params[:context][:topic_id]
      values[:topic_id] = params[:context][:topic_id]
      where = where+ " AND contexts.topic_id= :topic_id"
    end
    @questions = Question.joins(:context).where(where,values).order('id DESC')
    respond_to do |format|
      format.pdf do
        render :pdf => "Test",
               :disposition => 'attachment',
               :template=>"questions/new_pdf_download.html.erb",
               :header => { :right => '[page] of [topage]' } ,
               :footer => {
                   :left => "Ignitor",
                   :right => "#{Date.today}",
                   :font_size => 5,
                   :url      => 'www.ignitor.com',
                   :center => '[page] of [topage]'},
               #:margin => { :bottom => 30 },
               :password => 'edutor',
               :layout => 'pdf.html',
               :header => { :right => '[page] of [topage]' } ,
               :show_as_html=>false,
               :disable_external_links => true,
               :print_media_type => true

      end
    end
  end

  def question_tag_search
    tags = {:skills=>'rails',:activity=>'rails'} #params[:tags]
    tags.each do ||

    end
  end

end
