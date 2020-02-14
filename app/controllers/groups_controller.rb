class GroupsController < ApplicationController
 authorize_resource :class=>StudentGroup
  # caches_action :index
  # GET /groups
  # GET /groups.json
  def index
    @groups1 = []
    #@groups = User.where('is_group =? and center_id=? and edutorid like ?',true,current_user.center_id,"%SG-%").page(params[:page])
    if current_user.is?'EA'
      @groups = StudentGroup.includes(:profile).page(params[:page])
    elsif current_user.is?'IA'
      @groups = StudentGroup.includes(:profile).where(:institution_id=>current_user.institution_id).page(params[:page])
    elsif current_user.is? 'EO'
      @groups = current_user.student_groups.page(params[:page])
    elsif current_user.is?'CR'
      @groups = StudentGroup.includes(:profile).where(:institution_id=>current_user.institution_id,:center_id=>current_user.center_id).page(params[:page])
    elsif current_user.is?'ET'
      @groups = current_user.student_groups.page(params[:page])
    else
      @groups = StudentGroup.includes(:profile).where(:institution_id=>current_user.institution_id,:center_id=>current_user.center_id).page(params[:page])
    end

    #below code is used for jquery tokeninput
    if request.xhr?
      if current_user.is?'EA'
        user_ids = User.where("institution_id = ?  and center_id = ? and is_group = ? and type!=?",params[:institution_id],params[:center_id],true,"Center|Institution")
      elsif current_user.is?'IA' or current_user.is? 'EO'
        user_ids = User.where("institution_id = ?  and center_id = ? and is_group = ? and type!=?",params[:institution_id],params[:center_id],true,"Center|Institution")
      else
        user_ids = User.where("center_id = ? and is_group = ? and type!=?",params[:center_id],true,"Center|Institution")
      end
      @groups1 = Profile.where(:user_id => user_ids).where("firstname like ? or surname like ? or middlename like ?","%#{params[:q]}%","%#{params[:q]}%","%#{params[:q]}%")
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @groups1.map{|u| Hash[id: u.user_id, name: u.display_name]} }
    end
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @group = StudentGroup.find(params[:id])
    @users =  @group.users.where(rc:'ES').page(params[:page])
    @teachers = @group.teachers.page(params[:page])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.json
  def new
    @group = StudentGroup.new
    @group.build_profile
    @group.build_build_info
    #@center = current_user.center if current_user.center
    #@institution = current_user.institution if current_user.institution
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = StudentGroup.find(params[:id])
    @students = @group.students
    @teachers = @group.teachers
    @users = @students + @teachers
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = StudentGroup.new(params[:student_group])
    users = []
    #@group.institution_id = current_user.institution.id if current_user.institution
    #@group.center_id = current_user.center.id  if current_user.center
    #@group.role_id = 10 #short_role for SG group
    respond_to do |format|
      if @group.save
        if current_user.is?'ET' or current_user.is? 'EO'
          StudentGroupOwner.create(student_group_id: @group.id, user_id: current_user.id)
        end
        if params["users"].present?
          users = users + params["users"]
        end
        if params["teachers"].present?
          users = users + params["teachers"]
        end
        unless users.empty?
          users.each do |i|
            UserGroup.create(:group_id=>@group.id,:user_id=>i.to_i)
          end
        end
        format.html { redirect_to group_path(@group), notice: 'Group was successfully created.' }
        format.json { render json: @group, status: :created, location: @group }
      else
        format.html { render action: "new" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group = StudentGroup.find(params[:id])
    users= []
    respond_to do |format|
      if @group.update_attributes(params[:student_group])
        if params["users"].present?
          users = users+params["users"]
        end
        if  params["students"].present?
          users = users+params["students"]
        end
        if params["teachers"].present?
          users = users+params["teachers"]
        end
        unless users.empty?
          UserGroup.where(:group_id=>@group.id).destroy_all
          users.uniq.each do |i|
            UserGroup.create(:group_id=>@group.id,:user_id=>i.to_i)
          end
        end
        # @group.profile.update_attributes(params[:user][:profile_attributes]) if params[:user][:profile_attributes]
        #@group.user_group.update_attributes(params[:user][:user_group_attributes]) if params[:user][:user_group_attributes]
        format.html { redirect_to group_path(@group), notice: 'Group was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
    end
  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group = StudentGroup.find(params[:id])
    @group.is_activated? ? @group.update_attribute(:is_activated,false) : @group.update_attribute(:is_activated,true)
    flash[:notice]= 'Group was successfully updated.'
    respond_to do |format|
      format.js {render :nothing => true}
      format.html {  redirect_to :action => 'index' }
      format.json { head :ok }
    end
  end
  #get groups by institution and center
  def get_groups
    users = User.where('is_group =? and institution_id=? and center_id=? and edutorid like ?',true,params[:institution_id],params[:center_id],"%SG-%").select(:id)
    list = Profile.find_all_by_user_id(users).map {|u| Hash[value: u.user_id, name: u.firstname]}
    render json: list
  end


  def list_students
    if  params[:section_id].present?
      puts "##################  Sections"
      @users = User.students.search_includes.where(institution_id: params[:institution_id],
                                                   center_id: params[:center_id],
                                                   academic_class_id: params[:academic_class_id],
                                                   section_id: params[:section_id])
    elsif params[:academic_class_id].present?
      puts "##############  Academic Class"
      @users = User.students.search_includes.where(institution_id: params[:institution_id],
                                                   center_id: params[:center_id],
                                                   academic_class_id: params[:academic_class_id])
    elsif params[:center_id].present?
      puts "########## Center"
      @users = User.students.search_includes.where(:institution_id=>params[:institution_id],
                                                   :center_id=>params[:center_id])

    elsif params[:institution_id].present?
      puts "#######  Institution"
      @users = User.students.search_includes.where(:institution_id=>params[:institution_id])
    end
  end

  def list_teachers
    if params[:center_id].present?
      puts "#######center teachers"
      @teachers = current_user.teachers.where(center_id: params[:center_id])
    else
      puts "all teachers in institution"
      @teachers = current_user.teachers
    end
  end


end
