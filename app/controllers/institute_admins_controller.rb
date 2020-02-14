class InstituteAdminsController < ApplicationController
  authorize_resource
  # GET /institute_admins
  # GET /institute_admins.json
  def index
    @institute_admins = case current_user.rc
                          when 'EA'
                            InstituteAdmin.includes(:profile).page(params[:page])
                          when 'IA'
                            InstituteAdmin.includes(:profile).where(:id=>current_user.institute_admin).page(params[:page])
                        end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @institute_admins }
    end
  end

  # GET /institute_admins/1
  # GET /institute_admins/1.json
  def show
    @institute_admin = InstituteAdmin.includes(:profile).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @institute_admin }
    end
  end

  # GET /institute_admins/new
  # GET /institute_admins/new.json
  def new
    @institute_admin = InstituteAdmin.new
    @institute_admin.build_profile

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @institute_admin }
    end
  end

  # GET /institute_admins/1/edit
  def edit
    @institute_admin = InstituteAdmin.find(params[:id])
  end



  # POST /institute_admins
  # POST /institute_admins.json
  def create
    @institute_admin = InstituteAdmin.new(params[:institute_admin])

    respond_to do |format|
      if @institute_admin.save
        # createuser @institute_admins
        #creategroupuser @institute_admins
        format.html { redirect_to @institute_admin, notice: 'InstituteAdmin was successfully created.' }
        format.json { render json: @institute_admin, status: :created, location: @institute_admins }
      else
        # @institute_admins.build_profile unless @institute_admin.profile_loaded?
        format.html { render action: "new" }
        format.json { render json: @institute_admin.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /institute_admins/1
  # PUT /institute_admins/1.json
  def update
    @institute_admin = InstituteAdmin.find(params[:id])
    respond_to do |format|
      if @institute_admin.update_attributes(params[:institute_admin])
        format.html { redirect_to @institute_admin, notice: 'InstituteAdmin was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @institute_admin.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /institute_admins/1
  # DELETE /institute_admins/1.json
  def destroy
    @institute_admin = InstituteAdmin.find(params[:id])
    @institute_admin.is_activated? ? @institute_admin.update_attribute(:is_activated,false) : @institute_admin.update_attribute(:is_activated,true)
    flash[:notice]= 'InstituteAdmin was successfully updated.'
    respond_to do |format|
      format.js {render :nothing => true}
      format.html {  redirect_to :back }
      format.json { head :ok }
    end
  end

end
