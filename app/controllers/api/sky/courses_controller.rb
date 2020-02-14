class Api::Sky::CoursesController < Api::Sky::BaseController
  before_filter :find_course, only: [:show, :update, :destroy]
  # authorize_resource
  # GET /Courses.json
  def index
    # @courses = @api_user.present? ? Course.where(:user_id => @api_user.id) : Course.all
    # removes key and gets only those params which can act as query filters  
    where_params = params.slice(*Course.column_names) 
    where_params[:user_id] = @api_user.id
    @courses = Course.where(where_params) 
    render json: @courses
  end

  # GET /Courses/1.json
  def show
    course_as_hash = @course.as_json(request_host_with_port:request.host_with_port)
    render json: course_as_hash
  end

  # POST /Courses.json
  def create
    @course = Course.new(params[:course])
    @course.guid = SecureRandom.uuid
    @course.user_id = @api_user.id
    @course.store_id = @api_user.store.id    
    @course.ibooks = Ibook.where(ibook_id:params[:book_ids])
    if @course.save
      render json: @course, status: :created, location: @course
    else
      render json: @course.errors, status: :unprocessable_entity
    end
  end

  # PUT /Courses/1.json
  def update
    # Assigns books to course by their database IDs as required by Rails.
    params[:course][:ibook_ids]= Ibook.where(ibook_id:params[:book_ids]).map(&:id)
    if @course.update_attributes(params[:course])
      render json: @course
    else
      render json: @course.errors, status: :unprocessable_entity
    end
  end

  # DELETE /Courses/1.json
  def destroy
    @course.destroy
    render json: :ok
  end

  def find_course
    if is_number? params[:id]
      @course = Course.find(params[:id])
    else
      @course = Course.find_by_guid(params[:id])
    end
  end

  def is_number? string
    true if Float(string) rescue false
  end
end

