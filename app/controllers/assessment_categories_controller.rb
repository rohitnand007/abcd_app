class AssessmentCategoriesController < ApplicationController
  authorize_resource
   # GET /assessments
  # GET /assessments.json
  def index
    @assessment_categories =  AssessmentCategory.page(params[:page])
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @assessment_categories }
    end
  end

  # GET /assessments/1
  # GET /assessments/1.json
  def show
    @assessment_category = AssessmentCategory.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @assessment_category }
    end
  end

  # GET /assessments/new
  # GET /assessments/new.json
  def new
    @assessment_category = AssessmentCategory.new
    @assessment_category.build_asset
    @assessment_category.test_configurations.build
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @assessment_category }
    end
  end

  # GET /assessments/1/edit
  def edit
    @assessment_category = AssessmentCategory.find(params[:id])
  end

  # POST /assessments
  # POST /assessments.json
  def create
    @assessment_category = AssessmentCategory.new(params[:assessment_category])
    respond_to do |format|
      if @assessment_category.save
        #if @assessment_category.status == 1
          Content.send_message_to_est(false,current_user,@assessment_category)
        #end
        format.html { redirect_to @assessment_category, notice: 'AssessmentCategory was successfully created.' }
        format.json { render json: @assessment_category, status: :created, location: @assessment_category }
      else
        format.html { render action: "new" }
        format.json { render json: @assessment_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /assessments/1
  # PUT /assessments/1.json
  def update
    @assessment_category = AssessmentCategory.find(params[:id])
    if current_user.role.id == 7
     params[:assessment][:status] = 6 
     params[:assessment][:publisher_id] = @assessment_category.publisher_id
    end  
    respond_to do |format|
      if @assessment_category.update_attributes(params[:assessment])
        if @assessment_category.status == 6
         Content.send_message_to_est(@assessment_category.vendor,current_user,@assessment_category)
        end  
        format.html { redirect_to @assessment_category, notice: 'AssessmentCategory was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @assessment_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /assessments/1
  # DELETE /assessments/1.json
  def destroy
    @assessment_category = AssessmentCategory.find(params[:id])
    @assessment_category.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to assessment_url }
      format.json { head :ok }
    end
  end
  
end
