class AssessmentInTopicQuizzesController < ApplicationController
  authorize_resource
  # GET /AssessmentInTopicQuizs
  # GET /AssessmentInTopicQuizs.json
  def index
   @assessment_in_topic_quizzes =  AssessmentInTopicQuiz.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json:@assessment_in_topic_quizzes }
    end
  end

  # GET /AssessmentInTopicQuizs/1
  # GET /AssessmentInTopicQuizs/1.json
  def show
   @assessment_in_topic_quiz = AssessmentInTopicQuiz.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json:@assessment_in_topic_quiz }
    end
  end

  # GET /AssessmentInTopicQuizs/new
  # GET /AssessmentInTopicQuizs/new.json
  def new
   @assessment_in_topic_quiz = AssessmentInTopicQuiz.new
   @assessment_in_topic_quiz.build_asset
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json:@assessment_in_topic_quiz }
    end
  end

  # GET /AssessmentInTopicQuizs/1/edit
  def edit
   @assessment_in_topic_quiz = AssessmentInTopicQuiz.find(params[:id])
  end

  # POST /AssessmentInTopicQuizs
  # POST /AssessmentInTopicQuizs.json
  def create
   @assessment_in_topic_quiz = AssessmentInTopicQuiz.new(params[:assessment_in_topic_quiz])
    respond_to do |format|
      if@assessment_in_topic_quiz.save
        #if@assessment_in_topic_quiz.rb.status == 1
          Content.send_message_to_est(false,current_user,@assessment_in_topic_quiz)
        #end
        format.html { redirect_to@assessment_in_topic_quiz, notice: 'AssessmentInTopicQuiz was successfully created.' }
        format.json { render json:@assessment_in_topic_quiz, status: :created, location:@assessment_in_topic_quiz }
      else
        format.html { render action: "new" }
        format.json { render json:@assessment_in_topic_quiz.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /AssessmentInTopicQuizs/1
  # PUT /AssessmentInTopicQuizs/1.json
  def update
   @assessment_in_topic_quiz = AssessmentInTopicQuiz.find(params[:id])
    if current_user.role.id == 7
     params[:assessment_in_topic_quiz][:status] = 6
    end
    respond_to do |format|
      if @assessment_in_topic_quiz.update_attributes(params[:assessment_in_topic_quiz])
        format.html { redirect_to@assessment_in_topic_quiz, notice: 'AssessmentInTopicQuiz was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json:@assessment_in_topic_quiz.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /AssessmentInTopicQuizs/1
  # DELETE /AssessmentInTopicQuizs/1.json
  def destroy
   @assessment_in_topic_quiz = AssessmentInTopicQuiz.find(params[:id])
   @assessment_in_topic_quiz.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to assessment_in_topic_quizzes_url }
      format.json { head :ok }
    end
  end
  

end
