class QuizTargetedGroup < ActiveRecord::Base
  has_one :quiz_target_location, :dependent => :destroy
  accepts_nested_attributes_for :quiz_target_location, :reject_if => lambda { |d| d[:content_year_id].blank? }
  validates :subject,:body,:extras, :assessment_type ,:presence => true
  validates :show_score_after,:show_answers_after, :numericality => { :only_integer => true,:greater_than_or_equal_to=>0 }
  has_many :assessment_reports_tasks, :as => :parent_obj, :dependent => :destroy
  has_many :assessment_reevaluation_tasks, :as => :parent_obj, :dependent => :destroy
  belongs_to :quiz
  composed_of :timeopen,:class_name => 'Time',:mapping => %w(timeopen to_i),:constructor => Proc.new{ |item| item },:converter => Proc.new{ |item| item }
  composed_of :timeclose,:class_name => 'Time',:mapping => %w(timeclose to_i),:constructor => Proc.new{ |item| item },:converter => Proc.new{ |item| item }
  before_create :set_defaults
  validate :validate_fields
  has_one :message_quiz_targeted_group
  has_many :quiz_attempts,:foreign_key=>'publish_id'
  has_many :openformat_quiz_files,:foreign_key=>'publish_id'
  has_one :quiz_ibook_location, :dependent => :destroy
  accepts_nested_attributes_for :quiz_ibook_location
  serialize :serialized_key
  #validates :recipient_id, :presence => {:unless => "group_id", :message => "You must enter atleast one recipient or group"}
  #validates_presence_of :recipient_id, :unless => lambda { self.group_id.blank? } ,:message=>"please select any individual or group"
  #validates :recipient_id, :unless => proc{|obj| obj.group_id.blank?} ,:presence=>true


  ASSESSMENT_TYPE = [["quiz",1],["practice-tests",2],["Institute-Test",3],["Assignment",4],["Inclass",5],["Regular",6],["HOT/IIT",7],["Olympiad",8],["insti-tests",9]]
  #ASSESSMENT_TYPE = [["Institute-Test",3]]
  ASSESSMENT_NCX = [{"1"=>"Quiz"},{"2"=>"practice-tests"},{"3"=>"insti-tests"},{"4"=>"home-work"},{"5"=>"assignment"}]
  
  def set_defaults
    self.published_on = Time.now.to_i
    self.guid = SecureRandom.uuid
  end



  def validate_fields
    if self[:timeclose].to_i <= Time.now.to_i
      #errors.add :base, 'End Time should be a future time.'
      errors.add :timeclose, "End Time should be a future time."
    end
    if self.timeclose.to_i <= self.timeopen.to_i
      errors.add(:timeopen, "End Time should be greater than Start Time.")
    end
    logger.info "=================#{self.group_id}=#{self.recipient_id}"
    if !self.to_group and self.recipient_id.nil?
      errors.add :recipient_id, "Please select atleast one individual or group"
    end
  end



  def get_assessment_type
    return ASSESSMENT_TYPE
  end

  def get_assessment_ncx
    if self.assessment_type == 1
      return "quiz"
    end
    if self.assessment_type == 2
      return "practice-tests"
    end
    if self.assessment_type == 3
      return "insti-tests"
    end
    if self.assessment_type == 4
      return "inclass"
    end
    if self.assessment_type == 5
      return "iit"
    end
    if self.assessment_type == 6
      return "olympiad"
    end
  end

  def accessible(user_id)
    #for students
    if self.timeclose < Time.now.to_i
      return false
    else
      published_group = self.group_id
      recipient_id = self.recipient_id
      user_belongs_to_groups = User.find(user_id).groups.map(&:id)
      if (user_belongs_to_groups.include? self.group_id) || (user_id==recipient_id)
        return true
      end
      return false
    end
  end

  def key_change?
    self.serialized_key.present? && self.serialized_key[:key_updates][:questions].present?
  end

  def reevaluate
    if self.key_change?
      # Rails.logger.debug """""""""""""""Serialized key present"""""""""""""
        ActiveRecord::Base.transaction do
          question_changes = self.serialized_key[:key_updates][:questions]
          question_changes.each do |question_id, change|
            question = Question.find(question_id)
            question_type = question.qtype
            quiz_question_instance = QuizQuestionInstance.where(quiz_id: self.quiz_id, question_id: question_id).first
            question_grade = quiz_question_instance.present? ? quiz_question_instance.grade : question.defaultmark
            question_penalty = quiz_question_instance.present? ? quiz_question_instance.penalty : question.penalty
            quiz_question_attempts = QuizQuestionAttempt.where({question_id: question_id, quiz_attempt_id: self.quiz_attempt_ids})
            quiz_question_attempts.each do |qqa|
              if ["multichoice", "truefalse"].include? question_type
                attempted_answer_ids = qqa.mcq_question_attempts.select { |mqa| mqa.selected==true }.map(&:question_answer_id)
                correct_answer_ids = change[:question_answers].map(&:to_i)
                if change[:flag].present?
                  case change[:flag]
                    when 'full'
                      #   Award full marks
                      qqa.update_attributes({:marks => question_grade, :correct => true})
                    when 'zero'
                      #   Award zero marks
                      qqa.update_attributes({:marks => 0, :correct => false})
                    when 'or'
                      #   Conditionally award marks based on the choice
                      if change[:question_answers].present?
                        if question.multiple_answer?
                          #   Do nothing
                        else
                          # This is a normal single answer multiple choice question.
                          # Reevaulation is neglected if question is not attempted
                          if attempted_answer_ids.size>1
                            # Attempted more than one answer when maximum permitted number of answers are 1
                            qqa.update_attributes({:marks => (-1*question_penalty.to_f), :correct => false})
                          elsif attempted_answer_ids.size==1
                            # Evaluate marks using or condition
                            if correct_answer_ids.include? attempted_answer_ids.first
                              qqa.update_attributes({:marks => question_grade, :correct => true})
                            else
                              qqa.update_attributes({:marks => (-1*question_penalty.to_f), :correct => false})
                            end
                          end
                        end
                      end
                  end
                else
                  #   Original correct answer key was wrong.
                  #  So they changed it. Reevaluate accordingly.
                  if change[:question_answers].present?
                    if question.multiple_answer?
                      if correct_answer_ids.sort==attempted_answer_ids.sort
                        # Attempted right
                        qqa.update_attributes({:marks => question_grade, :correct => true})
                      else
                        if attempted_answer_ids.present?
                          #   Answered wrong
                          qqa.update_attributes({:marks => (-1*question_penalty.to_f), :correct => false})
                        else
                          # Didn't attempt
                          qqa.update_attributes({:marks => 0, :correct => false})
                        end
                      end
                    else
                      # This is a normal single answer multiple choice question.
                      # Neglect if question is not attempted
                      if attempted_answer_ids.size>1
                        # Attempted more than one answer when maximum permitted number of answers are 1
                        qqa.update_attributes({:marks => (-1*question_penalty.to_f), :correct => false})
                      elsif attempted_answer_ids.size==1
                        if correct_answer_ids.size==1
                          # update only if one correct answer is provided
                          if correct_answer_ids.include? attempted_answer_ids.first
                            qqa.update_attributes({:marks => question_grade, :correct => true})
                          else
                            qqa.update_attributes({:marks => (-1*question_penalty.to_f), :correct => false})
                          end
                        end
                      end
                    end
                  end
                end
              elsif ["fib"].include? question_type
                correct_fill_blanks = change[:question_fill_blanks]
                if change[:flag].present?
                  case change[:flag]
                    when 'full'
                      #   Award full marks
                      qqa.update_attributes({:marks => question_grade, :correct => true})
                    when 'zero'
                      #   Award zero marks
                      qqa.update_attributes({:marks => 0, :correct => false})
                  end
                else
                  if correct_fill_blanks.present?
                    attempted = false
                    qqa.fib_question_attempts.each { |fqa| attempted=true if fqa.selected==true }
                    # Do reevaluation only if the student attempted the question. Else neglect.
                    if attempted
                      correct = true
                      correct_fill_blanks.sort.each_with_index do |answer_choice_pair, i|
                        answer_provided = qqa.fib_question_attempts[i].fib_question_answer.squeeze(" ").strip
                        correct_possibilities = answer_choice_pair[1].split(",").map { |answer| answer.squeeze(" ").strip }
                        if QuestionFillBlank.find(answer_choice_pair[0]).case_sensitive
                          correct = false unless correct_possibilities.include? answer_provided
                        else
                          correct = false unless correct_possibilities.map(&:downcase).include? answer_provided.downcase
                        end
                      end
                      if correct
                        qqa.update_attributes({:marks => question_grade, :correct => true})
                      else
                        qqa.update_attributes({:marks => (-1*question_penalty.to_f), :correct => false})
                      end
                    end
                  end
                end
              end
            end
          end
          self.quiz_attempts.each { |qa| qa.update_attribute(:sumgrades, qa.quiz_question_attempts.sum(:marks)) }
        end
    end
  end

  def initial_analytic_students_list

    a = self.group_id
    dynamic_array = []
  if a.nil?
    p = self.recipient_id
    q = User.find(p)
    r = self.message_quiz_targeted_group.message_id

    v = QuizAttempt.where(["publish_id = ? and user_id = ?", "#{self.id}", "#{q.id}"])

    w = UserMessage.where(["message_id = ? and user_id = ?", "#{r}", "#{q.id}"]).first

    if (v.empty?) && (w.sync == true)

      dynamic_array << {id:q.edutorid , name: q.name, downloaded: "n", taken: "n", score: "NA"}

    elsif (v.empty?) && (w.sync == false)

      dynamic_array << {id:q.edutorid , name: q.name, downloaded: "y", taken: "n", score: "NA"}

    else

      dynamic_array << {id:q.edutorid , name: q.name, downloaded: "y", taken: "y", score: v.first.sumgrades.to_f}

    end

   elsif a == 1
      
    QuizAttempt.includes(:user).where(:publish_id=>self.id).group(:user_id).each do |attempt|
      dynamic_array << {id:attempt.user.edutorid , name: attempt.user.name, downloaded: "y", taken: "y", score: attempt.sumgrades.to_i}
    end     

  else

    a = self.group_id
    b = User.find(a).students
    c = self.message_quiz_targeted_group.message_id

    b.each do |p|

      v = QuizAttempt.where(["publish_id = ? and user_id = ?", "#{self.id}", "#{p.id}"])

      w = UserMessage.where(["message_id = ? and user_id = ?", "#{c}", "#{p.id}"]).first
     
      if w.nil?
 
        dynamic_array << {id:p.edutorid , name: p.name, downloaded: "n", taken: "n", score: "NA"}

      elsif (v.empty?) && (w.sync == true)

        dynamic_array << {id:p.edutorid , name: p.name, downloaded: "n", taken: "n", score: "NA"}

      elsif (v.empty?) && (w.sync == false)

        dynamic_array << {id:p.edutorid , name: p.name, downloaded: "y", taken: "n", score: "NA"}

      else

        dynamic_array << {id:p.edutorid , name: p.name, downloaded: "y", taken: "y", score: v.first.sumgrades.to_f}

      end
    end
    end

    return dynamic_array
  end

  def generate_student_attempt_data_xml
    questions = self.quiz.ordered_questions
    question_count = questions.size
    quiz_attempts = self.quiz_attempts.uniq_by { |qa| qa.user_id }
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml| xml.EXAM {
      if questions.present? && quiz_attempts.present?
        quiz_attempts.each do |quiz_attempt|
          question_attempts = quiz_attempt.valid_quiz_question_attempts
          xml.STUDENT {
            attempt_string = ""
            xml.ADMNO { xml.text User.find(quiz_attempt.user_id).try(:rollno).to_s }
            if question_attempts.present?
              questions.each do |question|
                if ["multichoice", "truefalse"].include?(question.qtype) && question_attempts.map(&:question_id).include?(question.id)
                  question_attempt = question_attempts.select { |qa| qa.question_id==question.id }.first
                  # Since invalid question attempts were already filtered out, only really attempted questions will be left
                  # That means we are assuming at least one options is selected by the user
                  attempt_string+="#{question_attempt.answer_given.gsub(',', '')},"
                else
                  attempt_string+=" ,"
                end
              end
            else
              attempt_string = " ,"*question_count
            end
            xml.DATA { xml.text attempt_string.chop }
          }
        end
      end
    } }
    builder.to_xml
  end

  alias generate_ngi_xml generate_student_attempt_data_xml

  def generate_guid
    self.update_attribute('guid', SecureRandom.uuid)
  end
end
