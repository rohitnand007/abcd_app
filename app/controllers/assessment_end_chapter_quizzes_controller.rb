class AssessmentEndChapterQuizzesController < ApplicationController
  authorize_resource
  # GET /AssessmentEndChapterQuizs
  # GET /AssessmentEndChapterQuizs.json
  def index
   @assessment_end_chapter_quizzes =  AssessmentEndChapterQuiz.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json:@assessment_end_chapter_quizzes }
    end
  end

  # GET /AssessmentEndChapterQuizs/1
  # GET /AssessmentEndChapterQuizs/1.json
  def show
   @assessment_end_chapter_quiz = AssessmentEndChapterQuiz.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json:@assessment_end_chapter_quiz }
    end
  end

  # GET /AssessmentEndChapterQuizs/new
  # GET /AssessmentEndChapterQuizs/new.json
  def new
   @assessment_end_chapter_quiz = AssessmentEndChapterQuiz.new
   @assessment_end_chapter_quiz.build_asset
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json:@assessment_end_chapter_quiz }
    end
  end

  # GET /AssessmentEndChapterQuizs/1/edit
  def edit
   @assessment_end_chapter_quiz = AssessmentEndChapterQuiz.find(params[:id])
  end

  # POST /AssessmentEndChapterQuizs
  # POST /AssessmentEndChapterQuizs.json
  def create
   @assessment_end_chapter_quiz = AssessmentEndChapterQuiz.new(params[:assessment_end_chapter_quiz])
    respond_to do |format|
      if@assessment_end_chapter_quiz.save
        #if@assessment_end_chapter_quiz.rb.status == 1
          Content.send_message_to_est(false,current_user,@assessment_end_chapter_quiz)
        #end
        format.html { redirect_to@assessment_end_chapter_quiz, notice: 'AssessmentEndChapterQuiz was successfully created.' }
        format.json { render json:@assessment_end_chapter_quiz, status: :created, location:@assessment_end_chapter_quiz }
      else
        format.html { render action: "new" }
        format.json { render json:@assessment_end_chapter_quiz.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /AssessmentEndChapterQuizs/1
  # PUT /AssessmentEndChapterQuizs/1.json
  def update
   @assessment_end_chapter_quiz = AssessmentEndChapterQuiz.find(params[:id])
    if current_user.role.id == 7
     params[:assessment_end_chapter_quiz][:status] = 6
    end
    respond_to do |format|
      if @assessment_end_chapter_quiz.update_attributes(params[:assessment_end_chapter_quiz])
        format.html { redirect_to@assessment_end_chapter_quiz, notice: 'AssessmentEndChapterQuiz was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json:@assessment_end_chapter_quiz.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /AssessmentEndChapterQuizs/1
  # DELETE /AssessmentEndChapterQuizs/1.json
  def destroy
   @assessment_end_chapter_quiz = AssessmentEndChapterQuiz.find(params[:id])
   @assessment_end_chapter_quiz.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to assessment_end_chapter_quizzes_url }
      format.json { head :ok }
    end
  end
  

end
