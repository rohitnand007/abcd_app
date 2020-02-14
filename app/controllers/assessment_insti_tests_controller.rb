class AssessmentInstiTestsController < ApplicationController
  authorize_resource
  # GET /AssessmentInstiTests
  # GET /AssessmentInstiTests.json
  def index
   @assessment_insti_tests =  AssessmentInstiTest.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json:@assessment_insti_tests }
    end
  end

  # GET /AssessmentInstiTests/1
  # GET /AssessmentInstiTests/1.json
  def show
   @assessment_insti_test = AssessmentInstiTest.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json:@assessment_insti_test }
    end
  end

  # GET /AssessmentInstiTests/new
  # GET /AssessmentInstiTests/new.json
  def new
   @assessment_insti_test = AssessmentInstiTest.new
   @assessment_insti_test.build_asset
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json:@assessment_insti_test }
    end
  end

  # GET /AssessmentInstiTests/1/edit
  def edit
   @assessment_insti_test = AssessmentInstiTest.find(params[:id])
  end

  # POST /AssessmentInstiTests
  # POST /AssessmentInstiTests.json
  def create
   @assessment_insti_test = AssessmentInstiTest.new(params[:assessment_insti_test])
    respond_to do |format|
      if@assessment_insti_test.save
        #if@assessment_insti_test.rb.status == 1
          Content.send_message_to_est(false,current_user,@assessment_insti_test)
        #end
        format.html { redirect_to@assessment_insti_test, notice: 'AssessmentInstiTest was successfully created.' }
        format.json { render json:@assessment_insti_test, status: :created, location:@assessment_insti_test }
      else
        format.html { render action: "new" }
        format.json { render json:@assessment_insti_test.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /AssessmentInstiTests/1
  # PUT /AssessmentInstiTests/1.json
  def update
   @assessment_insti_test = AssessmentInstiTest.find(params[:id])
    if current_user.role.id == 7
     params[:assessment_insti_test][:status] = 6
    end
    respond_to do |format|
      if @assessment_insti_test.update_attributes(params[:assessment_insti_test])
        format.html { redirect_to@assessment_insti_test, notice: 'AssessmentInstiTest was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json:@assessment_insti_test.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /AssessmentInstiTests/1
  # DELETE /AssessmentInstiTests/1.json
  def destroy
   @assessment_insti_test = AssessmentInstiTest.find(params[:id])
   @assessment_insti_test.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to assessment_insti_test_url }
      format.json { head :ok }
    end
  end
  

end
