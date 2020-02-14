class Api::Panacea::UserController < Api::Panacea::ApiBaseController

 respond_to :json 
 before_filter :find_user, only: [:show, :update]
 
  before_filter only: :create do
    unless @json.has_key?('user') && @json['city'].present? && @json['course'].present? && @json['user']['rollno'].present? && @json['user']['password'].present?
      render nothing: true, status: :bad_request
    end
  end

  before_filter only: :update do
    unless @json.has_key?('user')
      render nothing: true, status: :bad_request
    end
  end

  before_filter only: :create do
    @user = User.find_by_rollno(@json['user']['rollno'])
  end

  def index
    render json: User.where(:institution_id=> @api_user.institution_id)
  end

  def show
    render json: @user
  end

  def create
    if @user.present?
      render json: @user, status: :conflict
    else
      @user = User.new
      @user.build_profile
      @user.institution_id = @api_user.institution_id
      @user.center_id = get_center_id(@json['city'])
      academic_class_id = get_academic_class_id(@json['city'],@json['course'])
      @user.academic_class_id = academic_class_id
      @user.section_id = get_section_id(academic_class_id, @json['city'],@json['course'])
      @user.role_id = 4
      @user.profile.firstname = @json["name"]
      @user.assign_attributes(@json['user'])
      if @user.save!
        @user.update_email
        render json: @user
      else
        render nothing: true, status: :bad_request
      end
   end
  end

  def update
    @user.assign_attributes(@json['user'])
    if @user.save
        render json: @user
    else
        render nothing: true, status: :bad_request
    end
  end


  private
   def find_user
     @user = User.find_by_rollno(@json[:user][:rollno])
     render nothing: true, status: :not_found unless @user.present? && @user == @api_user
   end

   def get_center_id(center_name)
     @email = center_name+"_"+@api_user.id.to_s+"@"+@api_user.email.split("@").last
      @center = Center.includes(:profile).where("institution_id=? and profiles.firstname=? and email=?",@api_user.institution_id,center_name,@email)
    if @center.empty?
     center = Center.new
     center.build_profile
     center.institution_id = @api_user.institution_id
     center.email = center_name+"_"+@api_user.id.to_s+"@"+@api_user.email.split("@").last
     center.password = "edutor"
     center.profile.firstname = center_name
     center.save
     return center.id
    else
     @center.first.id
    end    

   end

   def get_academic_class_id(center_name,course_name)
     logger.info "====#{@user.center_id}"
     @name = center_name+"_"+course_name
     @email = course_name+"_"+center_name+"_"+@api_user.id.to_s+"@"+@api_user.email.split("@").last
     @academic = AcademicClass.includes(:profile).where("institution_id=? and center_id=? and profiles.firstname=? and email=?",@api_user.institution_id,@user.center_id,@name,@email)
    if @academic.empty?
      academic = AcademicClass.new
      academic.build_profile
      academic.institution_id= @api_user.institution_id
      academic.center_id= @user.center_id
      academic.email = @email
      academic.password  = "edutor"
      academic.profile.firstname = @name
      academic.save
      return academic.id
    else
      @academic.first.id
    end    
  end  
     def get_section_id(academic_class_id,center_name,course_name)
    @name = center_name+"_"+course_name
    @email = course_name+"_"+center_name+"_"+@api_user.id.to_s+"_"+academic_class_id.to_s+"@"+@api_user.email.split("@").last
    @section = Section.where("academic_class_id=?",academic_class_id)
    if @section.empty?
      section = Section.new
      section.build_profile
      section.institution_id= @api_user.institution_id
      section.center_id= @user.center_id
      section.academic_class_id= academic_class_id
      section.email = @email
      section.password  = "edutor"
      section.profile.firstname = @name
      section.save
      return section.id
    else
      @section.first.id
    end
end
end
