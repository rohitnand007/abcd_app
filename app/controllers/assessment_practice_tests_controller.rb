class AssessmentPracticeTestsController < ApplicationController
  authorize_resource
  # GET /AssessmentPracticeTests
  # GET /AssessmentPracticeTests.json
  def index
   @assessment_practice_tests =  AssessmentPracticeTest.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json:@assessment_practice_tests }
    end
  end

  # GET /AssessmentPracticeTests/1
  # GET /AssessmentPracticeTests/1.json
  def show
   @assessment_practice_test = AssessmentPracticeTest.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json:@assessment_practice_test }
    end
  end

  # GET /AssessmentPracticeTests/new
  # GET /AssessmentPracticeTests/new.json
  def new
   @assessment_practice_test = AssessmentPracticeTest.new
   @assessment_practice_test.build_asset
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json:@assessment_practice_test }
    end
  end

  # GET /AssessmentPracticeTests/1/edit
  def edit
   @assessment_practice_test = AssessmentPracticeTest.find(params[:id])
  end

  # POST /AssessmentPracticeTests
  # POST /AssessmentPracticeTests.json
  def create
   @assessment_practice_test = AssessmentPracticeTest.new(params[:assessment_practice_test])
    respond_to do |format|
      if@assessment_practice_test.save
        #if@assessment_practice_test.rb.status == 1
          Content.send_message_to_est(false,current_user,@AssessmentPracticeTest)
        #end
        format.html { redirect_to@assessment_practice_test, notice: 'AssessmentPracticeTest was successfully created.' }
        format.json { render json: @assessment_practice_test, status: :created, location: @assessment_practice_test }
      else
        format.html { render action: "new" }
        format.json { render json:@assessment_practice_test.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /AssessmentPracticeTests/1
  # PUT /AssessmentPracticeTests/1.json
  def update
   @assessment_practice_test = AssessmentPracticeTest.find(params[:id])
    if current_user.role.id == 7
     params[:assessment_practice_test][:status] = 6
    end
    respond_to do |format|
      if@assessment_practice_test.update_attributes(params[:assessment_practice_test])
        format.html { redirect_to@assessment_practice_test, notice: 'AssessmentPracticeTest was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json:@assessment_practice_test.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /AssessmentPracticeTests/1
  # DELETE /AssessmentPracticeTests/1.json
  def destroy
   @assessment_practice_test = AssessmentPracticeTest.find(params[:id])
   @assessment_practice_test.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to AssessmentPracticeTest_url }
      format.json { head :ok }
    end
  end
  

end
