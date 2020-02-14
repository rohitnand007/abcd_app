class AssessmentPdfJob < BackgroundJob
  belongs_to :assessment_reports_task
  belongs_to :user
  has_one :asset, :as=>:archive, :dependent => :destroy

  include Workflow

  workflow_column :state
  workflow do
    state :pending_status do
      event :being_processed, :transitions_to => :awaiting_result
    end
    state :awaiting_result do
      event :accept, :transitions_to => :accepted
      event :reject, :transitions_to => :rejected
    end
     state :accepted do
      event :report_deliver, :transitions_to => :report_delivered
    end
    state :rejected
    state :report_delivered
  end

  #def generate_pdf_jobs(quiz_targeted_groups_ids, quiz_targeted_group_id)
  #  #@publish_ids = QuizTargetedGroup([4442,4482])
  #  @quiz_targeted_groups = QuizTargetedGroup.where(:id=> quiz_targeted_groups_ids)
  #  @quiz_targeted_group = QuizTargetedGroup.includes(:quiz_attempts=>{:quiz_question_attempts=>[:fib_question_attempts,:mcq_question_attempts]}).find(quiz_targeted_group_id)
  #  unless @quiz_targeted_group.to_group
  #    redirect_to assessment_tool_all_assessments_path
  #    return
  #  end
  #  quiz_id = @quiz_targeted_group.quiz.id
  #  @quiz = Quiz.includes(:quiz_sections=>{:quiz_question_instances=>[:question=>[:question_fill_blanks,:question_answers]]}).find(quiz_id)
  #  @topper = Quiz.get_topper(@quiz_targeted_group)
  #  @common_data = generate_common_assessment_report_data(@quiz,@quiz_targeted_group,@topper)
  #
  #  @quiz_targeted_group.quiz_attempts.each do |quiz_attempt|
  #    job_params = {:common_data => @common_data,
  #                  :quiz_attempt => quiz_attempt.id,
  #                  :quiz_targeted_group => @quiz_targeted_group.id,
  #                  :quiz => @quiz.id,
  #                  :quiz_targeted_groups => @quiz_targeted_groups.map(&:id)}
  #    task = self.scheduled_task
  #    job = task.assessment_pdf_jobs.create
  #
  #    job.delay.generate_pdf(job_params)
  #
  #  end
  #end

  def generate_pdf(quiz_targeted_groups_ids, quiz_targeted_group_id, quiz_attempt_id, task_id)
    #begin
    #  Instance variable were used in this model method because wicked pdf needs to access them.
      self.being_processed! if self.state == "pending_status"
      quiz_attempt = QuizAttempt.find(quiz_attempt_id)
      @quiz_targeted_groups = QuizTargetedGroup.where(:id=> quiz_targeted_groups_ids)
      @quiz_targeted_group = QuizTargetedGroup.includes(:quiz_attempts=>{:quiz_question_attempts=>[:fib_question_attempts,:mcq_question_attempts]}).find(quiz_targeted_group_id)
      quiz_id = @quiz_targeted_group.quiz.id
      @quiz = Quiz.includes(:quiz_sections=>{:quiz_question_instances=>[:question=>[:question_fill_blanks,:question_answers]]}).find(quiz_id)
      @topper = Quiz.get_topper(@quiz_targeted_group)
      @common_data = generate_common_assessment_report_data(@quiz,@quiz_targeted_group,@topper)
      @key = @quiz.user.institution.user_configuration.enable_key_change ? false : true
      @html_key = @quiz.revised_key(@quiz_targeted_group)
      @report_data = generate_final_student_assessment_report_data(@common_data,quiz_attempt,@quiz_targeted_group,@quiz,@quiz_targeted_groups)
      @json_data = @report_data
      @center = @quiz.center_id != 0 ? @quiz.center_id : @quiz.institution_id

      ac = ApplicationController.new
      ac.instance_variable_set("@json_data",@json_data)
      ac.instance_variable_set("@quiz", @quiz)
      ac.instance_variable_set("@key", @key)
      ac.instance_variable_set("@html_key", @html_key)
      ac.instance_variable_set("@center", @center)

      pdf = WickedPdf.new.pdf_from_string(
          ac.render_to_string('assessment_tool/user_assessment_report_pdf.html.erb',
                              :layout => 'pdf.html'),
          :wkhtmltopdf => '/usr/bin/wkhtmltopdf',
          :javascript_delay => 18000,
          :page_size => 'A4',
          :encoding => 'utf',
          :image_quality=> 1,
          :margin => {:top                => 15,
                      :bottom             => 20},
          :footer => {
              :right => '[page]',
              :center => "ABCDE" ,
              :line=> true,
              :spacing=> 5,
          },
          :show_as_html=>false,
          :disable_external_links => true,
          :print_media_type => true
      )

      save_path = Rails.root.join('tmp',"#{quiz_attempt.user.edutorid}.pdf")
      # save_file_path = Rails.root.join('tmp',"#{@quiz.id}_#{@quiz_targeted_group.id}_#{quiz_attempt.user.edutorid}.txt")

      # json_file =  File.open(save_file_path, 'wb') do |file|
      #   file << @json_data.to_json
      # end

      saved_file = File.open(save_path, 'wb') do |file|
        file << pdf
      end

      pdf_file = self.build_asset
      pdf_file.attachment = File.open(save_path)
    pdf_file.archive_type = "AssessmentPdfJob"
    pdf_file.save
    File.delete(save_path) if File.exist?(save_path)
    self.accept! if self.state == "awaiting_result"

    #rescue Exception => e
    #  self.reject! if self.state == "awaiting_result"
    #  self.update_attribute(:error, e.message)
    #end

    task = AssessmentReportsTask.find(task_id)
    @jobs = task.assessment_pdf_jobs.all? {|j| j.state == "accepted"}
    if @jobs == true
      task.accept!
    end


  end

  private
  def generate_common_assessment_report_data(quiz,quiz_targeted_group,topper)
    @quiz = quiz
    @quiz_targeted_group = quiz_targeted_group
    @topper = topper
    @common_data =
        {
            assessmentDetails: Quiz.generate_assessment_details(@quiz),
            sectionDetails: Quiz.generate_section_details(@quiz),
            questionDetails: Quiz.generate_question_details(@quiz),
            aggregateAssessmentSummary: Quiz.generate_aggregate_assessment_summary(@quiz_targeted_group),
            aggregateSectionSummaries: Quiz.generate_aggregate_section_summaries(@quiz_targeted_group, @quiz),
            topperQuizAttemptSummary: Quiz.generate_user_quiz_attempt_summary(@topper, @quiz_targeted_group),
            topperSectionAttemptSummaries: Quiz.generate_user_section_attempt_summaries(@topper, @quiz_targeted_group, @quiz),
            aggregateQuestionSummaries: Quiz.generate_aggregate_question_attempt_summaries(@quiz, @quiz_targeted_group),
            historicalPerformance: Quiz.generate_aggregate_historical_performances(@quiz_targeted_groups)
        }
    return @common_data
  end

  def generate_final_student_assessment_report_data(common_data,quiz_attempt,quiz_targeted_group,quiz,quiz_targeted_groups)
    @report_data = {}
    @common_data = common_data
    @student = quiz_attempt.user
    @quiz_targeted_group = quiz_targeted_group
    @quiz = quiz
    @quiz_targeted_groups = quiz_targeted_groups
    @student_data = generate_student_assessment_report_data(@student, @quiz_targeted_group, @quiz, @quiz_targeted_groups)
    @report_data = @common_data.merge @student_data
    historicalPerformance =[]
    if !@quiz_targeted_groups.empty?
      historicalPerformance = Quiz.generate_historical_performance_from_arrays(@student_data[:historicalPerformance], @common_data[:historicalPerformance])
    end
    @report_data[:historicalPerformance] = historicalPerformance
    return @report_data
  end

  def generate_student_assessment_report_data(student,quiz_targeted_group,quiz,quiz_targeted_groups)
    @student = student
    @quiz_targeted_group = quiz_targeted_group
    @quiz = quiz
    @quiz_targeted_groups = quiz_targeted_groups
    @student_data = {
        heading: Quiz.generate_heading(@student),
        studentProfile: Quiz.generate_student_profile(@student),
        studentRank: Quiz.generate_student_rank(@student, @quiz_targeted_group),
        studentQuizAttemptSummary: Quiz.generate_user_quiz_attempt_summary(@student, @quiz_targeted_group),
        studentSectionAttemptSummaries: Quiz.generate_user_section_attempt_summaries(@student, @quiz_targeted_group, @quiz),
        studentQuestionAttemptSummaries: Quiz.generate_user_question_attempt_summaries(@student, @quiz, @quiz_targeted_group),
        historicalPerformance: []
    }
    if !@quiz_targeted_groups.empty?
      @student_data[:historicalPerformance] = Quiz.generate_user_historical_performances(@quiz_targeted_groups, @student)
    end
    return @student_data
  end

end