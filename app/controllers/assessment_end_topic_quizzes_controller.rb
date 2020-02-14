class AssessmentEndTopicQuizzesController < ApplicationController
  authorize_resource
  # GET /AssessmentEndTopicQuizs
  # GET /AssessmentEndTopicQuizs.json
  def index
   @assessment_end_topic_quizzes =  AssessmentEndTopicQuiz.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json:@assessment_end_topic_quizzes }
    end
  end

  # GET /AssessmentEndTopicQuizs/1
  # GET /AssessmentEndTopicQuizs/1.json
  def show
   @assessment_end_topic_quiz = AssessmentEndTopicQuiz.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json:@assessment_end_topic_quiz }
    end
  end

  # GET /AssessmentEndTopicQuizs/new
  # GET /AssessmentEndTopicQuizs/new.json
  def new
   @assessment_end_topic_quiz = AssessmentEndTopicQuiz.new
   @assessment_end_topic_quiz.build_asset
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json:@assessment_end_topic_quiz }
    end
  end

  # GET /AssessmentEndTopicQuizs/1/edit
  def edit
   @assessment_end_topic_quiz = AssessmentEndTopicQuiz.find(params[:id])
  end

  # POST /AssessmentEndTopicQuizs
  # POST /AssessmentEndTopicQuizs.json
  def create
   @assessment_end_topic_quiz = AssessmentEndTopicQuiz.new(params[:assessment_end_topic_quiz])
    respond_to do |format|
      if@assessment_end_topic_quiz.save
        #if@assessment_end_topic_quiz.rb.status == 1
          Content.send_message_to_est(false,current_user,@assessment_end_topic_quiz)
        #end
        format.html { redirect_to@assessment_end_topic_quiz, notice: 'AssessmentEndTopicQuiz was successfully created.' }
        format.json { render json:@assessment_end_topic_quiz, status: :created, location:@assessment_end_topic_quiz }
      else
        format.html { render action: "new" }
        format.json { render json:@assessment_end_topic_quiz.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /AssessmentEndTopicQuizs/1
  # PUT /AssessmentEndTopicQuizs/1.json
  def update
   @assessment_end_topic_quiz = AssessmentEndTopicQuiz.find(params[:id])
    if current_user.role.id == 7
     params[:assessment_end_topic_quiz][:status] = 6
    end
    respond_to do |format|
      if @assessment_end_topic_quiz.update_attributes(params[:assessment_end_topic_quiz])
        format.html { redirect_to@assessment_end_topic_quiz, notice: 'AssessmentEndTopicQuiz was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json:@assessment_end_topic_quiz.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /AssessmentEndTopicQuizs/1
  # DELETE /AssessmentEndTopicQuizs/1.json
  def destroy
   @assessment_end_topic_quiz = AssessmentEndTopicQuiz.find(params[:id])
   @assessment_end_topic_quiz.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to assessment_end_topic_quizzes_url }
      format.json { head :ok }
    end
  end
  

end
