class AssessmentOlympiadsController < ApplicationController
  authorize_resource
  # GET /AssessmentOlympiads
  # GET /AssessmentOlympiads.json
  def index
   @assessment_olympiads =  AssessmentOlympiad.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json:@assessment_olympiads }
    end
  end

  # GET /AssessmentOlympiads/1
  # GET /AssessmentOlympiads/1.json
  def show
   @assessment_olympiad = AssessmentOlympiad.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json:@assessment_olympiad }
    end
  end

  # GET /AssessmentOlympiads/new
  # GET /AssessmentOlympiads/new.json
  def new
   @assessment_olympiad = AssessmentOlympiad.new
   @assessment_olympiad.build_asset
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json:@assessment_olympiad }
    end
  end

  # GET /AssessmentOlympiads/1/edit
  def edit
   @assessment_olympiad = AssessmentOlympiad.find(params[:id])
  end

  # POST /AssessmentOlympiads
  # POST /AssessmentOlympiads.json
  def create
   @assessment_olympiad = AssessmentOlympiad.new(params[:assessment_olympiad])
    respond_to do |format|
      if@assessment_olympiad.save
        #if@assessment_olympiad.rb.status == 1
          Content.send_message_to_est(false,current_user,@assessment_olympiad)
        #end
        format.html { redirect_to@assessment_olympiad, notice: 'AssessmentOlympiad was successfully created.' }
        format.json { render json:@assessment_olympiad, status: :created, location:@assessment_olympiad }
      else
        format.html { render action: "new" }
        format.json { render json:@assessment_olympiad.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /AssessmentOlympiads/1
  # PUT /AssessmentOlympiads/1.json
  def update
   @assessment_olympiad = AssessmentOlympiad.find(params[:id])
    if current_user.role.id == 7
     params[:assessment_olympiad][:status] = 6
    end
    respond_to do |format|
      if @assessment_olympiad.update_attributes(params[:assessment_olympiad])
        format.html { redirect_to@assessment_olympiad, notice: 'AssessmentOlympiad was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json:@assessment_olympiad.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /AssessmentOlympiads/1
  # DELETE /AssessmentOlympiads/1.json
  def destroy
   @assessment_olympiad = AssessmentOlympiad.find(params[:id])
   @assessment_olympiad.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to assessment_olympiads_url }
      format.json { head :ok }
    end
  end
  

end
