class Quiz < ActiveRecord::Base
  require 'common_code'
  include CommonCode
  EDUTOR = 1
  OPTIONS_DIFFICULT=[["Easy",1],["Medium",2],["Hard",3]]
#  OPTIONS_FORMAT=[["Normal",0],["Catch All",1]]
  OPTIONS_FORMAT=[["MCQ With Evaluation",0],["Open Format With Evaluation",1],["DA Format",3],["MCQ With Out Evaluation",4],["Open Format With Out Evaluation",5]]
  has_one :quiz_detail
  validates :name,:intro, :presence => true
  validates :timelimit, :numericality => { :only_integer => true,:greater_than_or_equal_to=>0 }
  has_many :quiz_question_instances, :foreign_key => "quiz_id", :dependent => :destroy, :order=> "position ASC"
  has_many :questions, :through => :quiz_question_instances, :order=> "position ASC"
  has_many :quiz_targeted_groups, :dependent => :destroy
  has_many :quiz_question_attempts, :dependent => :destroy
  has_many :quiz_sections, :dependent => :destroy
  belongs_to :user, :foreign_key => "createdby"
  belongs_to :context
  has_many :quiz_attempts, :dependent => :destroy
  has_many :assets, :as => :archive, :dependent => :destroy
  has_many :quiz_publishes, dependent: :destroy
  has_one :asset, :foreign_key => "archive_id",:dependent => :destroy,:class_name => 'Asset', :conditions => proc { |c| ['archive_type = ?', 'Quiz'] }
#has_many :assets, :as=>:archive, :dependent=>:destroy
  accepts_nested_attributes_for :assets, :allow_destroy=>true, :reject_if => :all_blank
  accepts_nested_attributes_for :asset, :allow_destroy=>true, :reject_if => :all_blank
  accepts_nested_attributes_for :questions, :allow_destroy=>true, :reject_if => :all_blank
  accepts_nested_attributes_for :context
  accepts_nested_attributes_for :quiz_targeted_groups
  accepts_nested_attributes_for :quiz_detail
  validate :validate_context
  accepts_nested_attributes_for :quiz_question_instances
  accepts_nested_attributes_for :quiz_sections, :allow_destroy=>true, :reject_if => lambda { |section| section[:name].blank?}
  before_create :set_defaults
  composed_of :timeopen,:class_name => 'DateTime',:mapping => %w(timeopen to_i),:constructor => Proc.new{ |item| item },:converter => Proc.new{ |item| item }
  composed_of :timeclose,:class_name => 'DateTime',:mapping => %w(timeclose to_i),:constructor => Proc.new{ |item| item },:converter => Proc.new{ |item| item }
  scope :all_quizzes ,lambda{|current_user,group_ids|
                       where("(createdby =? or createdby IN (?)) AND hidden=?",current_user,group_ids,0)
                     }
  scope :search, lambda {|u| where(["name LIKE ?", "%" + u +"%"])}
  amoeba do
    enable
    include_field :quiz_question_instances

  end
  def set_defaults
    self.timecreated = Time.now.to_i
    self.timemodified = Time.now.to_i
    if self.context.chapter_id.nil?
      self.context.chapter_id = 0
    end
    if self.context.topic_id.nil?
      self.context.topic_id = 0
    end
    if self.center_id.nil?
      self.center_id = 0
    end
    if self.format_type.nil?
      self.format_type = 0
    end
  end

  def validate_context
    if self.context.board_id.nil?
      errors.add :base, 'Please select Board.'
    end
    if self.context.subject_id.nil?
      errors.add :base, 'Please select Subject.'
    end
    if self.context.content_year_id.nil?
      errors.add :base, 'Please select Class.'
    end
  end

  def direct_questions
    passage_questions = self.questions.select { |question| question.qtype=='passage' }
    self.questions - passage_questions.map(&:questions).flatten
  end

  def timeopen
    Time.at(self[:timeopen]) unless self[:timeopen].nil?
  end
  def timeclose
    Time.at(self[:timeclose]) unless self[:timeclose].nil?
  end
  def difficulty_text
    if self.difficulty == 1
      return "Easy"
    end
    if self.difficulty == 2
      return "Medium"
    end
    if self.difficulty == 3
      return "Hard"
    end
  end

  def publish_access(user_id)
    if user_id == EDUTOR
      return true
    end
    if self.createdby == user_id
      return true
    end
    return false
  end

  def edit_access(user_id)
    if user_id == EDUTOR
      return true
    end
    if self.createdby == user_id
      return true
    end
    return false
  end

  def accessible(user_id,institution_id)
    if user_id == EDUTOR
      return true
    end
    if self.createdby == user_id
      return true
    end
    if self.institution_id == institution_id || self.institution_id == EDUTOR
      return true
    end
    return false
  end

  def get_difficulty_options
    return OPTIONS_DIFFICULT
  end

  def get_format_options
    return OPTIONS_FORMAT
  end

#returns total questions number for the quiz
  def total_questions
    self.quiz_question_instances.size - self.no_of_passage_questions
  end

  def no_of_passage_questions
    self.questions.where(:qtype=>"passage").size
  end

# returns total marks for the quiz
  def total_marks
    return self.quiz_question_instances.sum(:grade)
  end


  def quiz_id
    self.id
  end


  def assessment_divisions
    assessment = self
    if assessment.quiz_sections.empty?
      [assessment]
    else
      assessment_division_set = []
      assessment.quiz_sections.each do |quiz_section|
        if quiz_section.children_sections.empty? and quiz_section.parent_id.nil?
          assessment_division_set << quiz_section
        else
          quiz_section.children_sections.each do |child_section|
            assessment_division_set << child_section
          end
        end
      end
      assessment_division_set
    end

  end

  def leaf_sections
    assessment = self
    if assessment.quiz_sections.empty?
      []
    else
      assessment_division_set = []
      assessment.quiz_sections.each do |quiz_section|
        if quiz_section.children_sections.empty? and quiz_section.parent_id.nil?
          assessment_division_set << quiz_section
        else
          quiz_section.children_sections.each do |child_section|
            assessment_division_set << child_section
          end
        end
      end
      assessment_division_set
    end
  end

# calculates the user's rank dynamically with sql query
# expects user object and quiz targeted group object as inputs
# same marks will yield same rank
  def self.user_rank(user,quiz_targeted_group)
    sql =" SELECT user_id, sumgrades , FIND_IN_SET(sumgrades, ( SELECT GROUP_CONCAT( DISTINCT sumgrades ORDER BY sumgrades DESC) sumgrades FROM quiz_attempts where publish_id= #{quiz_targeted_group.id} and attempt = 1 )) as rank FROM quiz_attempts where publish_id= #{quiz_targeted_group.id} and user_id=#{user.id};"
    current_user_attempts = QuizAttempt.find_by_sql(sql)
    # rank is a temporary column to store rank
    # the array "current_user_attempt" will only contain one attempt
    return current_user_attempts.first.rank
  end

  def self.get_topper(quiz_targeted_group)
    quiz_attempts = quiz_targeted_group.quiz_attempts.group(:user_id)
    quiz_attempts.order("sumgrades desc").first.user
  end

  def self.get_quiz_attempts(quiz_targeted_group)
    #selects onlyunique quiz attempts
    quiz_targeted_group.quiz_attempts.uniq_by { |qa| qa.user_id }
  end

  def self.get_quiz_targeted_group_student_size(quiz_targeted_group)
    # gets the number of students in the group to which the quiz is  published
    user = User.find(quiz_targeted_group.group_id)
    (user.respond_to? :students) ? user.students.size : 0
  end

# Generate different kinds of reports depending on the report type requested
  def self.generate_report(quiz_targeted_group,quiz_targeted_groups,user,topper)
    @result = {}
    @publish_ids = QuizTargetedGroup([4442,4482])
    @publish = QuizTargetedGroup.find(4442)
    @quiz = Quiz.find(4440)
    @quiz_targeted_group = QuizTargetedGroup.includes(:quiz_attempts=>{:quiz_question_attempts=>[:fib_question_attempts,:mcq_question_attempts]}).find(id)
    @topper = get_topper(quiz_targeted_group)
    @student = User.find(4012)
    @quiz_targeted_groups = [@quiz_targeted_group, @quiz_targeted_group]
    {
        heading: generate_heading(@student),
        studentProfile: generate_student_profile(@student),
        assessmentDetails: generate_assessment_details(@quiz),
        sectionDetails: generate_section_details(@quiz),
        questionDetails: generate_question_details(@quiz),
        aggregateAssessmentSummary: generate_aggregate_assessment_summary(@quiz_targeted_group),
        aggregateSectionSummaries: generate_aggregate_section_summaries(@quiz_targeted_group,@quiz),
        studentRank: generate_student_rank(@student,@quiz_targeted_group),
        studentQuizAttemptSummary: generate_user_quiz_attempt_summary(@student,@quiz_targeted_group),
        studentSectionAttemptSummaries: generate_user_section_attempt_summaries(@student,@quiz_targeted_group,@quiz),
        topperQuizAttemptSummary: generate_user_quiz_attempt_summary(@topper,@quiz_targeted_group),
        topperSectionAttemptSummaries: generate_user_section_attempt_summaries(@topper,@quiz_targeted_group,@quiz),
        studentQuestionAttemptSummaries: generate_user_question_attempt_summaries(@student,@quiz,@quiz_targeted_group),
        aggregateQuestionSummaries: generate_aggregate_question_attempt_summaries(@quiz,@quiz_targeted_group),
        historicalPerformance: generate_historical_performance(@quiz_targeted_groups,@student)

    }
  end

# Generate is the prefix used for generating Hashes.
# Get is the prefix used for fetching info

  def self.generate_heading(user)
    institute_url = user.institution.profile.photo(:small)
    institute_url = "file://#{Rails.public_path.to_s + institute_url.to_s}"
    {:ignitorLogoUrl=> "./images/logo.png",:instituteLogoUrl=>institute_url}
  end

  def self.generate_student_profile(student)
    student_profile =
        {:name=> student.name,
         :class=> "NA",
         :Section=> "NA",
         :studentID=> "NA",
         :edutorID=> student.edutorid,
         :schoolID=> "NA",
         :updatedOn=> Time.at(student.updated_at.to_i).strftime(" %d/%b/%Y , %l:%M %p")}
    student_profile[:studentID]= student.rollno unless student.rollno.nil?
    student_profile[:Section]= student.section.name unless student.section.nil?
    student_profile[:class]= student.academic_class.name unless student.academic_class.nil?
    student_profile[:schoolID]= student.institution.id unless student.institution.nil?
    student_profile
  end

  def self.generate_assessment_details(quiz)
    assessment_details = {:testId=>quiz.id,:assessmentName=> quiz.name, :Subject=> "NA",:class=>"NA", :maximumDuration=> "NA", :numberOfQuestions=>0 , :maximumMarks=> 0, :chapter=>"NA"}
    assessment_details.merge!({ :maximumDuration=> (quiz.timelimit*60).to_s, :numberOfQuestions=>quiz.total_questions , :maximumMarks=> quiz.total_marks})
    unless quiz.context.nil?
      assessment_details[:Subject]= quiz.context.subject.name     unless quiz.context.subject.nil?
      assessment_details[:class]= quiz.context.content_year.name  unless quiz.context.content_year.nil?
      assessment_details[:chapter]= quiz.context.chapter.name unless quiz.context.chapter.nil?
    else
      assessment_details[:class]= Tag.find(quiz.quiz_detail.academic_class_tag_id).value  if !quiz.quiz_detail.nil? && !quiz.quiz_detail.academic_class_tag_id.nil?
      assessment_details[:Subject]= Tag.find(quiz.quiz_detail.subject_tag_id).value  if !quiz.quiz_detail.nil? && !quiz.quiz_detail.subject_tag_id.nil?
    end

    return assessment_details
  end



  def self.generate_section_details(quiz)
    section_details = []
    if quiz.leaf_sections==[]
      return section_details
    end
    quiz.leaf_sections.each{ |quiz_section|
      section_quiz_question_instances = quiz_section.quiz_question_instances
      section_details << {
          id: quiz_section.id,
          name: quiz_section.section_name,
          maximumMarks: section_quiz_question_instances.sum(:grade),
          numberOfQuestions:section_quiz_question_instances.size,
          questions: section_quiz_question_instances.map(&:id)
      }
    }
    section_details
  end

  def self.generate_question_details(quiz)
    i = 1
    k = ("a".."z").to_a
    question_details = []
    @question_array = []
    quiz.questions.each do |question|
      if !@question_array.include? question.id
        if question.qtype == "passage"
          x = 0
          question.questions.each do |pcq|
            question_detail = {
                id: QuizQuestionInstance.where(question_id: pcq.id, quiz_id: quiz.id).first.id,
                type: pcq.qtype}
            question_detail[:number] = i.to_s+'.'+(k[x]).to_s
            @question_array << pcq.id
            question_details << question_detail
            x = x+1
          end
          @question_array << question.id
          i = i+1
        else
          question_detail = {
              id: QuizQuestionInstance.where(question_id: question.id, quiz_id: quiz.id).first.id,
              type: question.qtype
          }
          question_detail[:number] = i
          question_details << question_detail
          i = i+1
          @question_array<< question.id
        end
      end
    end
    question_details
  end

  def self.generate_aggregate_assessment_summary(quiz_targeted_group)
    # First computes all the first quiz attempts by students
    quiz_attempts = self.get_quiz_attempts(quiz_targeted_group)
    quiz_question_attempts = quiz_attempts.map{|quiz_attempt| quiz_attempt.valid_quiz_question_attempts}.flatten
    quiz_question_attempts_for_time = quiz_attempts.map{|quiz_attempt| quiz_attempt.quiz_question_attempts}.flatten
    test_taker_number = quiz_attempts.size
    #sum is the extended array method in rails to calculate sum of numerical elements in array
    {
        numberOfStudents: self.get_quiz_targeted_group_student_size(quiz_targeted_group),
        numberOfTestTakers: test_taker_number,
        averageScore: (quiz_attempts.map{|i|i.sumgrades.to_f}.sum)/quiz_attempts.size,
        averageQuestionAttempts: (quiz_question_attempts.size.to_f/test_taker_number),
        averageCorrectQuestionAttempts: (quiz_question_attempts.select{|quiz_question_attempt| quiz_question_attempt.correct == true}.size.to_f/test_taker_number),
        averageTime: quiz_question_attempts_for_time.reduce(0) { |sum, quiz_question_attempt| sum + quiz_question_attempt.time_taken }/test_taker_number
    }
  end


  def self.generate_aggregate_section_summaries(quiz_targeted_group,quiz)
    aggregate_section_summaries =[]
    quiz_attempts = self.get_quiz_attempts(quiz_targeted_group)
    test_taker_number = quiz_attempts.size
    quiz.leaf_sections.each{ |quiz_section|
      section_quiz_question_attempts = quiz_attempts.map{|quiz_attempt| quiz_attempt.valid_quiz_question_attempts.where(question_id:quiz_section.questions.map(&:id))}.flatten
      section_quiz_question_attempts_for_time = quiz_attempts.map{|quiz_attempt| quiz_attempt.quiz_question_attempts.where(question_id:quiz_section.questions.map(&:id))}.flatten
      aggregate_section_summaries << self.generate_aggregate_section_summary(quiz_section,section_quiz_question_attempts,test_taker_number,section_quiz_question_attempts_for_time)
    }
    aggregate_section_summaries
  end

  def self.generate_aggregate_section_summary(quiz_section,quiz_question_attempts,test_taker_number,section_quiz_question_attempts_for_time)
    {
        id: quiz_section.id,
        averageScore: quiz_question_attempts.reduce(0) { |sum, quiz_question_attempt| sum + quiz_question_attempt.marks }/test_taker_number,
        averageQuestionAttempts: (quiz_question_attempts.size/test_taker_number),
        averageCorrectQuestionAttempts: (quiz_question_attempts.select{|quiz_question_attempt| quiz_question_attempt.correct == true}.size/test_taker_number),
        averageTime: section_quiz_question_attempts_for_time.reduce(0) { |sum, quiz_question_attempt| sum + quiz_question_attempt.time_taken }/test_taker_number
    }
  end



  def self.generate_user_quiz_attempt_summary(user,quiz_targeted_group)
    quiz_attempt = quiz_targeted_group.quiz_attempts.where(user_id:user.id).first
    quiz_question_attempts = quiz_attempt.valid_quiz_question_attempts
    {
        # attemptedDate: Time.at(quiz_attempt.timefinish).strftime(" %d/%b/%Y , %l:%M %p"),
        attemptedDate: quiz_attempt.timefinish,
        correctQuestionAttempts: quiz_question_attempts.where(:correct=>true).size,
        questionAttempts: quiz_question_attempts.size,
        score: quiz_question_attempts.sum(:marks),
        timeSpent: quiz_attempt.quiz_question_attempts.sum(:time_taken)
    }
  end

  def self.generate_student_rank(user,quiz_targeted_group)
    self.user_rank(user,quiz_targeted_group)
  end

  def self.generate_user_section_attempt_summaries(user,quiz_targeted_group,quiz)
    user_section_attempt_summaries = []
    quiz_attempt = quiz_targeted_group.quiz_attempts.where(user_id:user.id).first
    quiz.leaf_sections.each{ |quiz_section|
      time_spent = quiz_attempt.quiz_question_attempts.where(question_id:quiz_section.questions.map(&:id)).sum(:time_taken)
      section_quiz_question_attempts = quiz_attempt.valid_quiz_question_attempts.where(question_id:quiz_section.questions.map(&:id))
      user_section_attempt_summaries << self.generate_user_section_attempt_summary(user,quiz_section,section_quiz_question_attempts,time_spent)
    }
    user_section_attempt_summaries
  end

  def self.generate_user_section_attempt_summary(user,quiz_section,quiz_question_attempts,time_spent)
    {
        id: quiz_section.id,
        correctQuestionAttempts: quiz_question_attempts.where(:correct=>true).size,
        questionAttempts: quiz_question_attempts.size,
        score: quiz_question_attempts.sum(:marks),
        timeSpent: time_spent
    }
  end

  def self.generate_user_question_attempt_summaries(user,quiz,quiz_targeted_group)
    user_question_attempt_summaries =[]
    quiz.quiz_question_instances.each { |quiz_question_instance|
      user_question_attempt_summaries << self.generate_user_question_attempt_summary(user,quiz_question_instance,quiz_targeted_group) if quiz_question_instance.question.qtype != "passage"
    }
    user_question_attempt_summaries
  end

  def self.generate_user_question_attempt_summary(user,quiz_question_instance,quiz_targeted_group)
    quiz_attempt = quiz_targeted_group.quiz_attempts.where(user_id:user.id).first
    quiz_question_attempt = quiz_attempt.valid_quiz_question_attempts.where(user_id:user.id, question_id:quiz_question_instance.question_id).first
    quiz_question_attempt_for_time_taken = quiz_attempt.quiz_question_attempts.where(user_id:user.id, question_id:quiz_question_instance.question_id).first
    #id is the id of quiz_question_instance. For the purposes of JSON, it is the unique identifier for the question
    # initally fills with the values for "not attempted"" case
    user_question_attempt_summary = {
        id: quiz_question_instance.id,
        attempt: "N",
        correct: "N",
        answerGiven:"",
        marks:0,
        timeTaken:0
    }
    unless quiz_question_instance.question.qtype == "passage"
      unless quiz_question_attempt_for_time_taken.nil?
        user_question_attempt_summary[:timeTaken] = quiz_question_attempt_for_time_taken.time_taken
      end

      unless quiz_question_attempt.nil?
        user_question_attempt_summary[:attempt] = "Y"
        user_question_attempt_summary[:correct] = quiz_question_attempt.correct ? "Y" : "N"
        user_question_attempt_summary[:answerGiven] = quiz_question_attempt.answer_given
        user_question_attempt_summary[:marks] = quiz_question_attempt.marks.to_f
        user_question_attempt_summary[:timeTaken] = quiz_question_attempt.time_taken
      end
      user_question_attempt_summary
    end
  end

  def self.generate_aggregate_question_attempt_summaries(quiz,quiz_targeted_group)
    aggregate_question_attempt_summaries = []
    quiz_attempts = get_quiz_attempts(quiz_targeted_group)
    quiz_question_attempts = quiz_attempts.map{|quiz_attempt| quiz_attempt.valid_quiz_question_attempts}.flatten
    quiz.quiz_question_instances.each { |quiz_question_instance|
      question_wise_quiz_question_attempts = quiz_question_attempts.select{|quiz_question_attempt| quiz_question_attempt.question_id == quiz_question_instance.question_id }
      aggregate_question_attempt_summaries << self.generate_aggregate_question_attempt_summary(quiz_question_instance,question_wise_quiz_question_attempts)
    }
    aggregate_question_attempt_summaries
  end

  def self.generate_aggregate_question_attempt_summary(quiz_question_instance,quiz_question_attempts)
    {
        id: quiz_question_instance.id,
        correctAttempts: quiz_question_attempts.select{|quiz_question_attempt| quiz_question_attempt.correct == true }.size,
        totalAttempts: quiz_question_attempts.size
    }
  end

  def self.generate_historical_performance(quiz_targeted_groups,user)
    historical_performances = []
    quiz_targeted_groups.each{|quiz_targeted_group|
      quiz = quiz_targeted_group.quiz
      topper = get_topper(quiz_targeted_group)
      historical_performance = {
          id: quiz_targeted_group.id,
          assessmentDetails: self.generate_assessment_details(quiz),
          aggregateAssessmentSummary: self.generate_aggregate_assessment_summary(quiz_targeted_group),
          topperQuizAttemptSummary: self.generate_user_quiz_attempt_summary(topper,quiz_targeted_group)
      }
      unless quiz_targeted_group.quiz_attempts.where(user_id:user.id).empty?
        historical_performance[:studentQuizAttemptSummary] = self.generate_user_quiz_attempt_summary(user,quiz_targeted_group)
      end
      historical_performances << historical_performance
    }
    historical_performances
  end

  def self.generate_aggregate_historical_performances(quiz_targeted_groups)
    historical_performances = []
    quiz_targeted_groups.each{|quiz_targeted_group|
      quiz = quiz_targeted_group.quiz
      topper = get_topper(quiz_targeted_group)
      historical_performances << {
          id: quiz_targeted_group.id,
          assessmentDetails: self.generate_assessment_details(quiz),
          aggregateAssessmentSummary: self.generate_aggregate_assessment_summary(quiz_targeted_group),
          topperQuizAttemptSummary: self.generate_user_quiz_attempt_summary(topper,quiz_targeted_group)
      }
    }
    historical_performances
  end

  def self.generate_user_historical_performances(quiz_targeted_groups,user)
    historical_performances = []
    quiz_targeted_groups.each{|quiz_targeted_group|
      historical_performance = {
          id: quiz_targeted_group.id
      }
      unless quiz_targeted_group.quiz_attempts.where(user_id:user.id).empty?
        historical_performance[:studentQuizAttemptSummary] = self.generate_user_quiz_attempt_summary(user,quiz_targeted_group)
      end
      historical_performances << historical_performance
    }
    historical_performances
  end

# intentionally written to do this otherwise client side job on server side

  def self.generate_historical_performance_from_arrays(user_historical_performances,aggregate_historical_performances)
    user_historical_performances.map{|user_historical_performance|
      aggregate_historical_performance = aggregate_historical_performances
                                             .detect {|aggregate_historical_performance| aggregate_historical_performance[:id] == user_historical_performance[:id] }
      aggregate_historical_performance||={}
      user_historical_performance.merge aggregate_historical_performance

    }
  end

  def self.generate_enhanced_assessment_details(quiz)
    self.generate_assessment_details(quiz).merge self.publish_stats(quiz)
  end

  def self.publish_stats(quiz)
    publish_stats  = {noOfPublishes:0,lastPublished:"NA"}
    unless quiz.quiz_targeted_groups.empty?
      no_of_publishes = quiz.quiz_targeted_groups.size
      last_published = quiz.quiz_targeted_groups.last.published_on
      publish_stats[:noOfPublishes] = no_of_publishes
      publish_stats[:lastPublished]= Time.at(last_published).strftime(" %d/%b/%Y , %l:%M %p")
    end
    publish_stats
  end

  def self.generate_static_publish_details(quiz_targeted_group)
    static_publish_details = {section:"NA",totalRecipients:"1"}
    static_publish_details[:publishedOn] = Time.at(quiz_targeted_group.published_on).strftime(" %d/%b/%Y , %l:%M %p")
    static_publish_details[:publishedBy]= User.find(quiz_targeted_group.published_by).name
    static_publish_details[:publishId] = quiz_targeted_group.id
    static_publish_details[:password] = quiz_targeted_group.password
    if quiz_targeted_group.to_group
      student_group = User.find(quiz_targeted_group.group_id)
      static_publish_details[:section] = student_group.name
      static_publish_details[:totalRecipients] = student_group.id == 1 ? 1 : student_group.students.size
    end
    static_publish_details
  end


  def self.generate_dynamic_publish_info(quiz_targeted_group)
    dynamic_publish_info = { downloaded:0,takenTest:0,lowestScore:0,highestScore:0,averageScore:0,
                             noOfStudentsWithLowestScore:0,
                             noOfStudentsWithHighestScore:0,
                             studentWiseRecords: quiz_targeted_group.initial_analytic_students_list.to_json,
                             topperNames: []
    }
    if quiz_targeted_group.to_group
      dynamic_publish_info[:downloaded]= self.get_downloaded_count(quiz_targeted_group)
      taken_test = self.get_taken_test_count(quiz_targeted_group)
      dynamic_publish_info[:takenTest] = taken_test
      if taken_test > 0
        dynamic_publish_info[:lowestScore]= self.get_lowest_score(quiz_targeted_group)
        dynamic_publish_info[:highestScore]= self.get_highest_score(quiz_targeted_group)
        dynamic_publish_info[:averageScore]= self.get_average_score(quiz_targeted_group)
        dynamic_publish_info[:noOfStudentsWithLowestScore]= self.get_count_students_with_lowest_score(quiz_targeted_group)
        dynamic_publish_info[:noOfStudentsWithHighestScore]= self.get_count_students_with_highest_score(quiz_targeted_group)
        dynamic_publish_info[:topperNames] = self.get_topper_names(quiz_targeted_group)
        # dynamic_publish_info[:attempted_studnet_info] = self.attempted_student_info(quiz_targeted_group)
        # dynamic_publish_info[:studentWiseRecords] = self.student_wise_records
      end
    end
    dynamic_publish_info
  end

  def self.get_topper_names(quiz_targeted_group)
    topper_names = []
    quiz_attempt_ids = self.get_user_first_attempts(quiz_targeted_group).map(&:id)
    quiz_attempts = QuizAttempt.where(id:quiz_attempt_ids).order("sumgrades DESC").limit(3)
    topper_names = quiz_attempts.map{|quiz_attempt| quiz_attempt.user.name}
    topper_names
  end

  def self.get_count_students_with_highest_score(quiz_targeted_group)
    score = self.get_highest_score(quiz_targeted_group)
    QuizAttempt.where(:publish_id => quiz_targeted_group.id, sumgrades: score, attempt: 1).map(&:user_id).count
  end

  def self.get_count_students_with_lowest_score(quiz_targeted_group)
    score = self.get_lowest_score(quiz_targeted_group)
    QuizAttempt.where(:publish_id => quiz_targeted_group.id, sumgrades: score, attempt: 1).map(&:user_id).count
  end

  def self.get_average_score(quiz_targeted_group)
    average_score = 0
    quiz_attempts = self.get_quiz_attempts(quiz_targeted_group)
    average_score = (quiz_attempts.map{|i|i.sumgrades.to_f}.sum)/quiz_attempts.size
    average_score
  end

  def self.get_lowest_score(quiz_targeted_group)
    lowest_score = 0
    quiz_attempts = get_user_first_attempts(quiz_targeted_group)
    lowest_score = quiz_attempts.order("sumgrades asc").first.sumgrades
    lowest_score
  end

  def self.get_user_first_attempts(quiz_targeted_group)
    quiz_attempts = quiz_targeted_group.quiz_attempts.where(:attempt => 1).group(:user_id)
    #quiz_attempts = quiz_targeted_group.quiz_attempts.where(:attempt => 1).group_by{|i|i.user_id}.values.flatten
  end

  def self.get_highest_score(quiz_targeted_group)
    highest_score = 0
    quiz_attempts = get_user_first_attempts(quiz_targeted_group)
    highest_score = quiz_attempts.order("sumgrades desc").first.sumgrades
    highest_score
  end
  def self.get_students_count_below_required_score(quiz_targeted_group)
    total_score = quiz_targeted_group.quiz.total_marks.to_i
    # start_score = (start_score * total_score)/100
    # end_score = (end_score * total_score)/100
    quiz_attempts = get_user_first_attempts(quiz_targeted_group)
    students_beloq_avg = []
    students_avg = []
    students_above_avg = []
    quiz_attempts.each do |q_a|
      if (0 <= q_a.sumgrades.to_i and q_a.sumgrades.to_i < (0.33*total_score))
        students_beloq_avg << q_a.user_id
      elsif ((0.33*total_score) <= q_a.sumgrades.to_i and q_a.sumgrades.to_i < (0.77*total_score))
        students_avg << q_a.user_id
      else
        students_above_avg << q_a.user_id
      end
    end
    students_in_score_range = [students_beloq_avg.count,students_avg.count, students_above_avg.count ]
  end


  def self.get_downloaded_count(quiz_targeted_group)
    downloaded_count = 0
    taken_test_count = self.get_taken_test_count(quiz_targeted_group)
    downloaded_count_by_messages = self.get_downloaded_count_by_messages(quiz_targeted_group)
    if downloaded_count_by_messages > taken_test_count
      downloaded_count = downloaded_count_by_messages
    else
      downloaded_count = taken_test_count
    end
    downloaded_count
  end

  def self.get_downloaded_count_by_messages(quiz_targeted_group)
    message = MessageQuizTargetedGroup.find_by_quiz_targeted_group_id(quiz_targeted_group.id)
    if message
      message_id = message.message_id
      student_ids = quiz_targeted_group.group_id == 1 ? 1 : User.find(quiz_targeted_group.group_id).students.map(&:id)
      return UserMessage.where(message_id: message_id, user_id: student_ids,sync: false).count
    else
      return 0
    end
  end


  def self.get_taken_test_count(quiz_targeted_group)
    self.get_quiz_attempts(quiz_targeted_group).count
  end

  def self.attempted_student_info(quiz_targeted_group)
    info = []
    if quiz_targeted_group.to_group
      published_users = User.includes(:user_groups).where("user_groups.group_id =#{quiz_targeted_group.group_id} and role_id=4").collect{|i| i.id}
      attempted_users =  quiz_targeted_group.quiz_attempts.select(:user_id).group(:user_id).collect{|i|i.user_id}
      not_attempted_users = published_users - attempted_users
      attempted_users_info =  User.where(:id=>attempted_users).collect{|i| i.name+"(#{i.edutorid})"}
      not_attempted_users_info = User.where(:id=>not_attempted_users).collect{|i| i.name+"(#{i.edutorid})"}
      return info = [attempted_users_info.join(", "),not_attempted_users_info.join(", ")]
    else
      []
    end
  end
  def assessment_key
    @quiz = self
    @keys = []
    @question_array = []
    @sections1 = self.quiz_sections.select{|sec| sec.questions.present?}
    @sections1.each do |sec|
      sec.questions.each do |qu|
        if !@question_array.include? qu.id
          if qu.qtype == "passage"
            qu.questions.each do |pcq|
              if ["multichoice", "truefalse"].include? pcq.qtype
                @key << [{section_id:sec.id, questions:[{ques_id:pcq.id, type:pcq.qtype, gf:pcq.feedback_format.html_safe ,
                                                         answers: pcq.question_answers.each_with_index.map{|ans,i| ans.fraction==1 ? [answer_id: "#{ans.id}", position: "#{i+1}" , value: "#{ans.answer}"] : next}.compact.flatten}]}]
              elsif pcq.qtype == "FIB"
                @key << [{section_id:sec.id, questions:[{ques_id:pcq.id, type:pcq.qtype, gf:pcq.feedback_format.html_safe ,answers:[
                                                            ({answer_id: pcq.question_fill_blanks.map(&:id).join.to_i, position: "" , value: pcq.question_fill_blanks.map { |ans| ans.answer.split(",").first }.join(',') })]}]}]


              else
                @key <<  [{section_id: sec.id, questions:[{ques_id:pcq.id, type:pcq.qtype, answers:[({answer_id:"", position:"" , value: pcq.feedback_format.html_safe })]}]}]
              end
              @question_array<< pcq.id
            end

          elsif !(@question_array.include? qu.id) && (["multichoice", "truefalse"].include? qu.qtype)
            @key << [{section_id:sec.id, questions:[{ques_id:qu.id, type:qu.qtype, gf:qu.feedback_format.html_safe ,
                                                     answers: qu.question_answers.each_with_index.map{|ans,i| ans.fraction==1 ? [answer_id: "#{ans.id}", position: "#{i+1}" , value: "#{ans.answer}"] : next}.compact.flatten}]}]

          elsif qu.qtype == "fib"
            @key << [{section_id:sec.id, questions:[{ques_id:qu.id, type:qu.qtype, gf:qu.feedback_format.html_safe ,answers:[
                                                        ({answer_id: qu.question_fill_blanks.map(&:id).join.to_i, position: "" , value: qu.question_fill_blanks.map { |ans| ans.answer.split(",").first }.join(',') })]}]}]


          else
            @key <<   [{section_id: sec.id, questions:[{ques_id:qu.id, type:qu.qtype, answers:[({answer_id:"", position:"" , value: qu.feedback_format.html_safe })]}]}]

          end
          @question_array<< qu.id
        end
      end
    end
    return @keys
  end

  def html_key
    @quiz = self
    @key1 = []

    i = 1
    k = ("a".."z").to_a
    @question_array = []
    @sections1 = self.quiz_sections.select{|sec| sec.questions.present?}
    if @sections1.count != 0
      @sections1.each do |sec|
        section_questions = []
        @key1 << [sec.section_name, section_questions]
        sec.questions.each do |qu|

          if !@question_array.include? qu.id
            if qu.qtype == "passage"
              x = 0
              qu.questions.each do |pcq|


                if ["multichoice", "truefalse"].include? pcq.qtype
                  section_questions << {id: pcq.id, no: i.to_s+'.'+(k[x]).to_s, gf: pcq.feedback_format.html_safe, answers: pcq.question_answers.each_with_index.map { |ans, i| ans.fraction==1 ? k["#{i}".to_i] : next }.compact.flatten }

                elsif pcq.qtype == "fib"
                  section_questions << {id: pcq.id, no: i.to_s+'.'+(k[x]).to_s, gf: pcq.feedback_format.html_safe, answers: pcq.question_fill_blanks.map { |ans| ans.answer.split(",").first }.join(',')}
                else
                  section_questions << {id: pcq.id, no: i.to_s+'.'+(k[x]).to_s, gf: pcq.feedback_format.html_safe, answers: [pcq.feedback_format.html_safe]}
                end
                x = x+1
                @question_array<< pcq.id
              end


            elsif !(@question_array.include? qu.id) && (["multichoice", "truefalse"].include? qu.qtype)
              section_questions << {id: qu.id, no: i, gf: qu.feedback_format.html_safe, answers: qu.question_answers.each_with_index.map { |ans, i| ans.fraction==1 ? k["#{i}".to_i] : next }.compact.flatten}

            elsif qu.qtype == "fib"
              section_questions << {id: qu.id, no: i, gf: qu.feedback_format.html_safe, answers: qu.question_fill_blanks.map { |ans| ans.answer.split(",").first }.join(',')}
            else
              section_questions << {id: qu.id, no: i, gf: qu.feedback_format.html_safe, answers: [qu.feedback_format.html_safe]}
            end
            @question_array<< qu.id
            i = i+1
          end


        end
      end
    else
      self.questions.each do |qu|
        if !@question_array.include? qu.id
          if qu.qtype == "passage"
            x = 0
            qu.questions.each do |pcq|


              if ["multichoice", "truefalse"].include? pcq.qtype
                @key1 << {id: pcq.id, no: i.to_s+'.'+(k[x]).to_s, gf: pcq.feedback_format.html_safe, answers: pcq.question_answers.each_with_index.map { |ans, i| ans.fraction==1 ? k["#{i}".to_i] : next }.compact.flatten}

              elsif pcq.qtype == "fib"
                @key1 << {id: pcq.id, no: i.to_s+'.'+(k[x]).to_s, gf: pcq.feedback_format.html_safe, answers: pcq.question_fill_blanks.map { |ans| ans.answer.split(",").first }.join(',')}
              else
                @key1 << {id: pcq.id, no: i.to_s+'.'+(k[x]).to_s, gf: pcq.feedback_format.html_safe, answers: [pcq.feedback_format.html_safe]}
              end
              x = x+1
              @question_array<< pcq.id
            end


          elsif !(@question_array.include? qu.id) && (["multichoice", "truefalse"].include? qu.qtype)
            @key1 << {id: qu.id, no: i, gf: qu.feedback_format.html_safe, answers: qu.question_answers.each_with_index.map { |ans, i| ans.fraction==1 ? k["#{i}".to_i] : next }.compact.flatten}

          elsif qu.qtype == "fib"
            @key1 << {id: qu.id, no: i, gf: qu.feedback_format.html_safe, answers: qu.question_fill_blanks.map { |ans| ans.answer.split(",").first }.join(',')}
          else
            @key1 << {id: qu.id, no: i, gf: qu.feedback_format.html_safe, answers: [qu.feedback_format.html_safe]}
          end
          @question_array<< qu.id
          i = i+1
        end
      end
    end
    return @key1
  end

  def revised_key(quiz_targeted_group)
    if quiz_targeted_group.serialized_key.present? && quiz_targeted_group.serialized_key[:received_key][:questions].present?
      original_key = self.html_key
      key_changes = quiz_targeted_group.serialized_key[:received_key][:questions]
      # TODO write logic to update according to changed key.
      k = ("a".."z").to_a
      k = ("a".."z").to_a

      key_changes.each do |p|
        original_key.each do |a|
          if p.first == a.first.last.to_s

            c = Question.find(p.first)
            if c.qtype == "fib"
              c = c.question_fill_blanks.first.id.to_s
              a[:answers] = p.last["question_fill_blanks"][c]


            else
              c = c.question_answers
              v = []
              p.last["question_answers"].each do |f|
                f = f.to_i
                v << c.each_with_index.map {|ans, i| ans.id== f ? k["#{i}".to_i] : next }.compact.flatten
              end
              a[:answers] = v

            end

          end
        end
      end
      return original_key
    else
      self.html_key

    end
  end

  def ordered_questions
    identify_non_passage_questions = Proc.new { |q| q.qtype!="passage" }
    if self.leaf_sections.present?
      questions = []
      self.leaf_sections.each do |section|
        if section.questions.select { |q| identify_non_passage_questions.call(q) }.present?
          section.questions.select { |q| identify_non_passage_questions.call(q) }.each do |question|
            questions << question
          end
        end
      end
    else
      questions = self.questions.select { |q| identify_non_passage_questions.call(q) }
    end
    questions
  end

  def self.publish_to_ecp(current_user,quiz_id)
    CommonCode.publish_ecp(quiz_id,current_user)
  end

#Below method is for cr's of NGI
  #the below method provides data for home page and date wise quiz segregation
  def self.ngi_home_page_data(current_user,quiz_targeted_group_id,date)

    final_output_data = Hash.new
    final_output_data[date] = []
    get_qtg = QuizTargetedGroup.includes(:quiz,:message_quiz_targeted_group,:quiz_attempts).find(quiz_targeted_group_id)
    get_qtg_group_id = get_qtg.group_id
    relevent_quiz = get_qtg.quiz.name
    message = get_qtg.message_quiz_targeted_group
    users_in_group = UserGroup.where("group_id=#{get_qtg_group_id}").map(&:user_id)
    sections_in_center = current_user.sections
    sections_in_center.each do |section|
      if get_qtg.group_id.present?
        intersected_student_ids = User.select(:id).where("id IN (?) and section_id=#{section.id} and role_id=4", users_in_group).map(&:id)
        published_users = intersected_student_ids.count
        if published_users != 0
        #downloaded_students_count
        if message
          message_id = message.message_id
          downloaded_students = UserMessage.where(message_id: message_id, user_id: intersected_student_ids,sync: false).count
        end
        #submitted_students_count
        attempted_users =  (get_qtg.quiz_attempts.group(:user_id).collect{|i|i.user_id} & intersected_student_ids).count
        #not_submitted_students_count
        not_attempted_users = downloaded_students - attempted_users
        #final_output_data[date][quiz_targeted_group_id][:not_submitted] = not_attempted_users

      final_output_data[date] << {section.name=>{:publish_id=>quiz_targeted_group_id,:quiz_name=>relevent_quiz,:published=>published_users,:downloaded=>downloaded_students,:submitted=>attempted_users,:not_submitted=>not_attempted_users}}
    end
    end
    end
    final_output_data
  end
  #below method is for the data, that is to be inserted in the csv file for the cr to download
  def self.ngi_home_page_csv_data(current_user,quiz_targeted_group_id,date)
    final_output_data = Hash.new
    final_output_data[date] = []
    get_qtg = QuizTargetedGroup.includes(:quiz,:message_quiz_targeted_group,:quiz_attempts).find(quiz_targeted_group_id)
    get_qtg_group_id = get_qtg.group_id
    relevent_quiz = get_qtg.quiz.name
    message = get_qtg.message_quiz_targeted_group
    users_in_group = UserGroup.where("group_id=#{get_qtg_group_id}").map(&:user_id)
    sections_in_center = current_user.sections
    sections_in_center.each do |section|
      if get_qtg.group_id.present?
        intersected_student_ids = User.select(:id).where("id IN (?) and section_id=#{section.id} and role_id=4", users_in_group).map(&:id)
        #downloaded_students_count
        if message
          message_id = message.message_id
          downloaded_students = UserMessage.where(message_id: message_id, user_id: intersected_student_ids,sync: false).map(&:user_id)
        end
        #submitted_students_count
        #published_users = intersected_student_ids
        attempted_users =  (get_qtg.quiz_attempts.group(:user_id).collect{|i|i.user_id} & intersected_student_ids)
        #not_submitted_students_count
        not_attempted_users = downloaded_students - attempted_users
        not_attempted_users_names = not_attempted_users.map{|user_id| [User.find(user_id).name,User.find(user_id).rollno]}
      end
      final_output_data[date] << {section.name=>{:publish_id=>quiz_targeted_group_id,:quiz_name=>relevent_quiz,:not_submitted=>not_attempted_users_names}}
    end
    final_output_data
  end
  def self.ngi_institute_wise_data(current_user, quiz_targeted_group_id, date)
    get_qtg = QuizTargetedGroup.includes(:quiz,:message_quiz_targeted_group,:quiz_attempts).find(quiz_targeted_group_id)
    get_qtg_group_id = get_qtg.group_id
    relevent_quiz = get_qtg.quiz.name
    message = get_qtg.message_quiz_targeted_group
    users_in_group = UserGroup.where("group_id=#{get_qtg_group_id}").map(&:user_id)
    #published_users_count
    published_users = users_in_group.count
    #downloaded_users_count
    if message
      message_id = message.message_id
      downloaded_students = UserMessage.where(message_id: message_id, user_id: users_in_group,sync: false).count
    end
    #submitted_users_count
    attempted_users =  (get_qtg.quiz_attempts.group(:user_id).collect{|i|i.user_id} & users_in_group).count
    #not_submitted_users_count
    not_attempted_users = downloaded_students - attempted_users
    final_output_data = {:published=> published_users,:downloaded=>downloaded_students,:submitted=>attempted_users, :not_submitted=>not_attempted_users}
  end

end

