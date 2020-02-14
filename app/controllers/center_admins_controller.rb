class CenterAdminsController < ApplicationController
  authorize_resource
  # GET /center_admins
  # GET /center_admins.json
  def index
    @center_admins = case current_user.rc
                       when 'EA'
                         CenterAdmin.includes(:profile).page(params[:page])
                       when 'IA'
                         current_user.center_admins.page(params[:page])
                     end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @center_admins }
    end
  end

  # GET /center_admins/1
  # GET /center_admins/1.json
  def show
    @center_admin = CenterAdmin.includes(:profile).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @center_admin }
    end
  end

  # GET /center_admins/new
  # GET /center_admins/new.json
  def new
    @center_admin = CenterAdmin.new
    @center_admin.build_profile

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @center_admin }
    end
  end

  # GET /center_admins/1/edit
  def edit
    @center_admin = CenterAdmin.find(params[:id])
  end

  # POST /center_admins
  # POST /center_admins.json
  def create
    @center_admin = CenterAdmin.new(params[:center_admin])
    respond_to do |format|
      if @center_admin.save
        format.html { redirect_to @center_admin, notice: 'CenterAdmin was successfully created.' }
        format.json { render json: @center_admin, status: :created, location: @center_admin }
      else
        # @center_admin.build_profile unless @center_admin.profile_loaded?
        format.html { render action: "new" }
        format.json { render json: @center_admin.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /center_admins/1
  # PUT /center_admins/1.json
  def update
    @center_admin = CenterAdmin.find(params[:id])

    respond_to do |format|
      if @center_admin.update_attributes(params[:center_admin])
        format.html { redirect_to @center_admin, notice: 'CenterAdmin was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @center_admin.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /center_admins/1
  # DELETE /center_admins/1.json
  def destroy
    @center_admin = CenterAdmin.find(params[:id])
    @center_admin.is_activated? ? @center_admin.update_attribute(:is_activated,false) : @center_admin.update_attribute(:is_activated,true)
    flash[:notice]= 'CenterAdmin was successfully updated.'
    respond_to do |format|
      format.js {render :nothing => true}
      format.html {  redirect_to :back }
      format.json { head :ok }
    end

  end

end
