class AssessmentIitsController < ApplicationController
  authorize_resource
  # GET /AssessmentIits
  # GET /AssessmentIits.json
  def index
   @assessment_iits =  AssessmentIit.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json:@assessment_iits }
    end
  end

  # GET /AssessmentIits/1
  # GET /AssessmentIits/1.json
  def show
   @assessment_iit = AssessmentIit.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json:@assessment_iit }
    end
  end

  # GET /AssessmentIits/new
  # GET /AssessmentIits/new.json
  def new
   @assessment_iit = AssessmentIit.new
   @assessment_iit.build_asset
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json:@assessment_iit }
    end
  end

  # GET /AssessmentIits/1/edit
  def edit
   @assessment_iit = AssessmentIit.find(params[:id])
  end

  # POST /AssessmentIits
  # POST /AssessmentIits.json
  def create
   @assessment_iit = AssessmentIit.new(params[:assessment_iit])
    respond_to do |format|
      if@assessment_iit.save
        #if@assessment_iit.rb.status == 1
          Content.send_message_to_est(false,current_user,@assessment_iit)
        #end
        format.html { redirect_to@assessment_iit, notice: 'AssessmentIit was successfully created.' }
        format.json { render json:@assessment_iit, status: :created, location:@assessment_iit }
      else
        format.html { render action: "new" }
        format.json { render json:@assessment_iit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /AssessmentIits/1
  # PUT /AssessmentIits/1.json
  def update
   @assessment_iit = AssessmentIit.find(params[:id])
    if current_user.role.id == 7
     params[:assessment_iit][:status] = 6
    end
    respond_to do |format|
      if @assessment_iit.update_attributes(params[:assessment_iit])
        format.html { redirect_to@assessment_iit, notice: 'AssessmentIit was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json:@assessment_iit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /AssessmentIits/1
  # DELETE /AssessmentIits/1.json
  def destroy
   @assessment_iit = AssessmentIit.find(params[:id])
   @assessment_iit.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to assessment_iits_url }
      format.json { head :ok }
    end
  end
  

end
