class EducationOfficersController < ApplicationController
  authorize_resource
  # GET /education_officers
  # GET /education_officers.json
  def index
    @education_officers = case current_user.rc
                          when 'EA'
                            EducationOfficer.includes(:profile).page(params[:page])
                          when 'IA'
                            EducationOfficer.includes(:profile).where(:id=>current_user.id).page(params[:page])
                          when 'EO'
                            EducationOfficer.includes(:profile).where(:id=>current_user.id).page(params[:page])
                        end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @education_officers }
    end
  end

  # GET /education_officers/1
  # GET /education_officers/1.json
  def show
    @education_officer = EducationOfficer.includes(:profile).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @education_officer }
    end
  end

  # GET /education_officers/new
  # GET /education_officers/new.json
  def new
    @education_officer = EducationOfficer.new
    @education_officer.build_profile

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @education_officer }
    end
  end

  # GET /education_officers/1/edit
  def edit
    @education_officer = EducationOfficer.find(params[:id])
  end



  # POST /education_officers
  # POST /education_officers.json
  def create
    @education_officer = EducationOfficer.new(params[:education_officer])

    respond_to do |format|
      if @education_officer.save
        # createuser @institute_admins
        #creategroupuser @institute_admins
        format.html { redirect_to @education_officer, notice: 'EducationOfficer was successfully created.' }
        format.json { render json: @education_officer, status: :created, location: @education_officers }
      else
        # @education_officers.build_profile unless @institute_admin.profile_loaded?
        format.html { render action: "new" }
        format.json { render json: @education_officer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /education_officers/1
  # PUT /education_officers/1.json
  def update
    @education_officer = EducationOfficer.find(params[:id])
    respond_to do |format|
      if @education_officer.update_attributes(params[:education_officer])
        format.html { redirect_to @education_officer, notice: 'EducationOfficer was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @education_officer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /education_officers/1
  # DELETE /education_officers/1.json
  def destroy
    @education_officer = EducationOfficer.find(params[:id])
    @education_officer.is_activated? ? @education_officer.update_attribute(:is_activated,false) : @education_officer.update_attribute(:is_activated,true)
    flash[:notice]= 'EducationOfficer was successfully updated.'
    respond_to do |format|
      format.js {render :nothing => true}
      format.html {  redirect_to :back }
      format.json { head :ok }
    end
  end

end
