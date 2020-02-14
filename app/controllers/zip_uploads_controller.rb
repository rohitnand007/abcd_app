require 'common_code'
class ZipUploadsController < ApplicationController
include CommonCode

  authorize_resource #:only=>[:edit, :index, :new, :show]
  # GET /zip_uploads
  # GET /zip_uploads.json
  EDUTOR = 1
  def index
    @zip_uploads = ZipUpload.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @zip_uploads }
    end
  end

  # GET /zip_uploads/1
  # GET /zip_uploads/1.json
  def show
    @zip_upload = ZipUpload.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @zip_upload }
    end
  end

  # GET /zip_uploads/new
  # GET /zip_uploads/new.json
  def new
    @zip_upload = ZipUpload.new
    values = {}
    @context = Context.new
    #@boards = current_user.institution.boards
    values[:hidden] = 0
    @filter_database = EDUTOR
    #if params[:filter_database].present?
    # @filter_database = params[:filter_database]
    #end

    @boards = get_boards(@filter_database)
    @databases = get_all_databases
    #logger.debug(@databases.inspect)
    values[:institution_id] = @filter_database
    where = "questions.institution_id = :institution_id AND questions.hidden = :hidden"
    if params[:context]
      if params[:context][:board_id].present?
        @i=1
        @context.board_id = params[:context][:board_id]
        values[:board_id] = params[:context][:board_id]
        where = where+ " AND contexts.board_id= :board_id"
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

    end
    #@boards = Content.where(:type=>"Board").map(&:name)
    #@content_year = Content.where(:type=>"ContentYear").map(&:name)
    #@subject = Content.where(:type=>"Subject").map(&:name)
    #@chapter = Content.where(:type=>"Chapter").map(&:name)
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @zip_upload }
    end
  end

  # GET /zip_uploads/1/edit
  def edit
    @zip_upload = ZipUpload.find(params[:id])
  end

  # POST /zip_uploads
  # POST /zip_uploads.json
  def create
    @zip_upload = ZipUpload.new(params[:zip_upload])
    if params[:zip_upload] != nil
      @group_id = params[:zip_upload][:group_id]
      @publish_permission = params[:zip_upload][:publish]

    end

    @context = Context.new(params[:context])
    if @context.board_id!=nil
      @context.save
      @i="got"
    end

    respond_to do |format|
      if @zip_upload.save
        format.html { redirect_to zipaction_path(zip_upload_id: @zip_upload,context_id: @context,i: @i,:group_id=>@group_id,:publish=>@publish_permission) , notice: 'Zip upload was successfully created.' }
        format.json { render json: @zip_upload, status: :created, location: @zip_upload }
      else
        format.html { render action: "new" }
        format.json { render json: @zip_upload.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /zip_uploads/1
  # PUT /zip_uploads/1.json
  def update
    @zip_upload = ZipUpload.find(params[:id])
    respond_to do |format|
      if @zip_upload.update_attributes(params[:zip_upload])
        format.html { redirect_to @zip_upload, notice: 'Zip upload was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @zip_upload.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /zip_uploads/1
  # DELETE /zip_uploads/1.json
  def destroy
    @zip_upload = ZipUpload.find(params[:id])
    @zip_upload.destroy

    respond_to do |format|
      format.html { redirect_to zip_uploads_url }
      format.json { head :ok }
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
      return Board.all
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
    d[1] = "Edutor"
    d[current_user.institution_id] = Institution.find(current_user.institution_id).profile.firstname
    return d
  end

  def zip_upload_question
    if current_user.is?"IA" or current_user.is? "ECP"
    @publisher_question_banks = []
    if current_user.is? "IA"
      @publisher_question_banks = current_user.institution.publisher_question_banks
    elsif current_user.is? "ECP"
      @publisher_question_banks = current_user.publisher_question_banks
    end
    else
      redirect_to :back , flash:{error:"You don't have permission to access this page"}
    end
  end

  def post_zip_upload_question
    @zip_upload = ZipUpload.new(params[:zip_upload])
    publisher_question_bank_id = params[:publisher_question_bank_id]

    if @zip_upload.save
      file_name = @zip_upload.asset_file_name
      full_file_name = @zip_upload.asset.path
      dir = @zip_upload.asset.path.gsub("/#{@zip_upload.asset_file_name}", "")
      Archive::Zip.extract(full_file_name, dir)
      destfile="#{Rails.root.to_s}"+"/public"+"/question_images"
      FileUtils.cp_r Dir[dir+"/*"], destfile
      if (Dir[dir+"/"+'/*.etx'])!=[]
        Dir[dir+"/"+'/*.etx'].each do |etxfile|
          etx_file = @zip_upload.etx_files.create(:filename => etxfile)
          @zip_upload.delay.process_etx etx_file.filename, current_user.id, publisher_question_bank_id, false
        end
      end
    end

    respond_to do |format|
      format.html { redirect_to etx_list_path(id: @zip_upload.id)}
      format.json { render json: @zip_upload.errors, status: :unprocessable_entity }
    end

  end

  def etx_list
    @zip_upload = ZipUpload.find(params[:id])
    @quiz = Quiz.new
    @quiz.build_quiz_detail
    @quiz.build_context
    render 'etx_list'
  end

  def etx_to_assessment
    @zip_upload = ZipUpload.find(params[:id])
    @etxquestions = []
    @zip_upload.etx_files.each do |e|

     next if e.ques_no.nil?
    @etxquestions = e.ques_no.split(",")
    @quiz = Quiz.new(params[:quiz])
    @quiz.name = e.filename.split('/').last.gsub('.etx','')
    @quiz.createdby = current_user.id
    @quiz.modifiedby = current_user.id
    @quiz.timecreated = Time.now
    @quiz.timemodified = Time.now
    @quiz.format_type = 8
    @quiz.timelimit = 0
    if current_user.institution_id
      @quiz.institution_id = current_user.institution_id
    else
      @quiz.institution_id = Institution.first.id
    end
    Quiz.skip_callback(:create,:before,:set_defaults)
    @quiz.save(:validate => false)

    assessment_div_id = @quiz.id
    quiz_id = @quiz.id
    @assessment_div = Quiz.find(assessment_div_id)
    @etxquestions.flatten.each {|question_id|
      if !@quiz.question_ids.include? question_id.to_i
        QuizQuestionInstance.create({question_id:question_id, quiz_id:quiz_id})
        @question = Question.find(question_id)
        if @question.qtype == "passage"
          @question.questions.each do |q|
            QuizQuestionInstance.create({question_id:q.id,quiz_id:quiz_id})
          end
        end
      end
    }
      publish(@quiz.id)
    end

  respond_to do |format|
      if params[:commit] == "Download Etx_links"
        format.html {redirect_to sent_message_path(current_user)}
      else
        format.html {redirect_to assessment_tool_publish_path(format: @quiz.id)}
      end
      end
  end

  def assessment_upload
    if (current_user.is? "IA") || (current_user.is? "CR")
      @publisher_question_banks = current_user.institution.publisher_question_banks
    end
  end

  def save_uploaded_assessment
    @zip_upload = ZipUpload.new(params[:zip_upload])
    publisher_question_bank_id = params[:publisher_question_bank_id]
    if @zip_upload.save
      full_file_name = @zip_upload.asset.path
      dir = @zip_upload.asset.path.gsub("/#{@zip_upload.asset_file_name}", "")
      Archive::Zip.extract(full_file_name, dir)
      destfile="#{Rails.root.to_s}"+"/public"+"/question_images"
      FileUtils.cp_r Dir[dir+"/*"], destfile
      if (Dir[dir+"/"+'/*.etx'])!=[]
        Dir[dir+"/"+'/*.etx'].each do |etxfile_name|
          etx_file = @zip_upload.etx_files.create(:filename => etxfile_name)
          @zip_upload.delay.process_assessment_etx etx_file.id, current_user.id, publisher_question_bank_id
        end
      end
    end
    @no_quiz = true
    respond_to do |format|
      format.html { redirect_to etx_list_path(id: @zip_upload.id) }
      format.json { render json: @zip_upload.errors, status: :unprocessable_entity }
    end
  end

  def new_reports_upload
    @zip_upload = ZipUpload.new
  end

  def save_reports_upload
    @zip_upload = ZipUpload.new(params[:zip_upload])
    @zip_upload.save
    # input_file = @zip_upload.asset
    # puts "input_file_path: #{input_file.path}"
    # FileUtils.mkdir_p Rails.root.to_s+'/public/pdf_reports/'+"#{@zip_upload.id}"
    # Zip::ZipFile.open(input_file.path) do |zip_file|
    #   zip_file.each do |f|
    #     puts "#{'-'* 50}"
    #     if f.directory?
    #       puts "#{f} is a directory. Size is #{f.size}"
    #     elsif f.file?
    #       puts "#{f} is a file. Size is #{f.size}"
    #       zip_file.extract(f, Rails.root.to_s+'/public/pdf_reports/'+"#{@zip_upload.id}/#{File.basename(f.to_s)}")
    #     else
    #       puts "None"
    #     end
    #   end
    # end
    flash[:notice] = "Reports Uploaded Successfully"
    @zip_upload.delay.extract_zip
    respond_to do |format|
      format.html { redirect_to action: "new_reports_upload"}
    end
  end
end