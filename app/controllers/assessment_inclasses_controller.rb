class AssessmentInclassesController < ApplicationController
  authorize_resource
  # GET /AssessmentInclasss
  # GET /AssessmentInclasss.json
  def index
   @assessment_inclasses =  AssessmentInclass.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json:@assessment_inclasses }
    end
  end

  # GET /AssessmentInclasss/1
  # GET /AssessmentInclasss/1.json
  def show
   @assessment_inclass = AssessmentInclass.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json:@assessment_inclass }
    end
  end

  # GET /AssessmentInclasss/new
  # GET /AssessmentInclasss/new.json
  def new
   @assessment_inclass = AssessmentInclass.new
   @assessment_inclass.build_asset
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json:@assessment_inclass }
    end
  end

  # GET /AssessmentInclasss/1/edit
  def edit
   @assessment_inclass = AssessmentInclass.find(params[:id])
  end

  # POST /AssessmentInclasss
  # POST /AssessmentInclasss.json
  def create
   @assessment_inclass = AssessmentInclass.new(params[:assessment_inclass])
    respond_to do |format|
      if@assessment_inclass.save
        #if@assessment_inclass.rb.status == 1
          Content.send_message_to_est(false,current_user,@assessment_inclass)
        #end
        format.html { redirect_to@assessment_inclass, notice: 'AssessmentInclass was successfully created.' }
        format.json { render json:@assessment_inclass, status: :created, location:@assessment_inclass }
      else
        format.html { render action: "new" }
        format.json { render json:@assessment_inclass.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /AssessmentInclasss/1
  # PUT /AssessmentInclasss/1.json
  def update
   @assessment_inclass = AssessmentInclass.find(params[:id])
    if current_user.role.id == 7
     params[:assessment_inclass][:status] = 6
    end
    respond_to do |format|
      if @assessment_inclass.update_attributes(params[:assessment_inclass])
        format.html { redirect_to@assessment_inclass, notice: 'AssessmentInclass was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json:@assessment_inclass.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /AssessmentInclasss/1
  # DELETE /AssessmentInclasss/1.json
  def destroy
   @assessment_inclass = AssessmentInclass.find(params[:id])
   @assessment_inclass.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to assessment_inclasses_url }
      format.json { head :ok }
    end
  end
  

end
