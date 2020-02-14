class QuestionUploadsController < ApplicationController
  after_filter :load_tags
  # skip_before_filter :authenticate_user!
  def index
    @question_uploads = QuestionUpload.where(user_id: current_user.id)
  end

  def new
  	flash[:notice] = params[:notice] if params[:notice].present?
    logger.info "Headers: #{request.headers['Content-Type']}"
  end

  def create
  	url = "/question_uploads"
  	message = "Uploaded Successfully."

  	# redirect_to new_question_upload_path, notice: "Uploaded Successfully."
  	@question_upload = QuestionUpload.new(params[:question_upload])
  	@question_upload.user_id = current_user.id
  	@question_upload.guid = SecureRandom.uuid
    @question_upload.publisher_question_bank_id = 18
  	attachment_ext = File.extname(@question_upload.attachment.path)
    puts "Base URL: #{request.base_url}"
  	if attachment_ext == ".doc" || attachment_ext == ".docx ||" || attachment_ext == ".zip"
  		@question_upload.save
      @question_upload.send_to_windows_server_to_convert request.base_url
  	else
  		message = "Upload a vaild file."
  	end
  	render json: {url: url, message: message}
  end

  def edit
  end

  def show
  end

  def update
  end

  def destroy
  end

  def download_attachment
  	guid = params[:id]
  	@question_upload = QuestionUpload.find_by_guid(guid)
  	send_file @question_upload.attachment.path ,:type=>"application/octet-stream",:x_sendfile=>true
    # file_path = "/home/krishna/Desktop/SendDataTest.txt"
    # file = File.open(file_path, 'rb')
    # data = file.read
    # file.close
    # send_data data, :filename => "my_file.txt" 
  end

  def windows_server_acknowledgement
    guid = params[:guid]
    download_link = params[:download_link]
    @question_upload = QuestionUpload.find_by_guid(guid)
    @question_upload.update_attribute("etx_download_link", download_link)
    @question_upload.download_etx_from_windows_server
    @question_upload.init_status_after_etx_download
    render json: {status: "Successful"}
  end

  def test_windows
    render json: {status: "Successful"}
  end

  def package_details
    @question_upload = QuestionUpload.find(params[:id])
    @questions = Question.where(id: @question_upload.questions_status['question_ids'])
    @question_ids = @question_upload.questions_status["question_ids"]
    @page_no = params[:page].present? ? (params[:page].to_i - 1) : 0
    @per_count = 5
    @question_ids = Kaminari.paginate_array(@question_ids).page(params[:page]).per(@per_count)
    user_id = current_user.id
    # db = UsersTagsDb.find_by_user_id(user_id).tags_db
    db = current_user.tags_db
    if db.present?
      tags = current_user.my_tags
      @class_tags = tags['class_tags']
      @subject_tags = tags['subject_tags']
      @concept_tags = tags['concept_tags']
    else
      redirect_to :back, notice: "No Tags DB is assigned."
    end
  end

  def update_question_tags
    @question_upload = QuestionUpload.find(params[:id])
    new_tags = [] 
    params[:tags].each do |name, value|
      x = Hash.new
      x['name'] = name
      x['value'] = value
      new_tags << x
    end
    @question_upload.update_question_tags_and_status(params[:question_id], new_tags)
    redirect_to :back #action: 'package_details', id: params[:id]
  end

  def approve_question
    question_id = params[:question_id]
    @question_upload = QuestionUpload.find(params[:id])
    @question_upload.approve_question_id(question_id)
    redirect_to action: 'package_details', id: params[:id]
  end

  def load_tags
    user_id = current_user.id
    # db = UsersTagsDb.find_by_user_id(user_id).tags_db
    db = current_user.tags_db
    if db.present?
      tags = current_user.my_tags
      @class_tags = tags['class_tags']
      @subject_tags = tags['subject_tags']
      @concept_tags = tags['concept_tags']
    else
      redirect_to :back, notice: "No Tags DB is assigned."
    end
  rescue ActionController::RedirectBackError
    redirect_to root_path, notice: "No Tags DB is assigned."
  end

end
