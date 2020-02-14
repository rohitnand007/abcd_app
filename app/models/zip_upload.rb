class ZipUpload < ActiveRecord::Base
  require "redis_interact"
  attr_accessor :publish,:publish_group
  attr_accessible :asset, :check

  has_attached_file :asset
  #validates_attachment_content_type :asset, :content_type => 'application/zip'

  has_many :etx_files

  # Make sure that redis server is running while running this command. Else it will produce inconsitent redis server
  def process_etx(etx_file, cur_user, publisher_question_bank_id, hidden=false)
    @user = User.find(cur_user)
    @publisher_question_bank = PublisherQuestionBank.find(publisher_question_bank_id)
    ins_id = !@user.institution_id.nil? ? @user.institution_id : 1
    center_id = !@user.center_id.nil? ? @user.center_id : "nil"
    @etx_file = EtxFile.where(:filename => etx_file).first
    ques_no = []
    begin
      ActiveRecord::Base.transaction do
        @etx_file.being_processed!
        file = File.open(@etx_file.filename)
        etx = Nokogiri::XML(file)
        test_paper = etx.xpath("/ignitor_questions")

        test_paper.xpath("group_questions").each do |group_ques|
          group_question_set = create_group_question(center_id, group_ques, ins_id,publisher_question_bank_id, hidden)
          group_question_set.each do |q|
            ques_no << q.id
          end
          @publisher_question_bank.questions << group_question_set.first
        end
        test_paper.xpath("question_set").each do |ques|
          q = create_simple_question(center_id, ins_id, ques,publisher_question_bank_id, hidden)
          @publisher_question_bank.questions << q
          ques_no << q.id
        end
        @etx_file.accept!
        @etx_file.update_attribute(:ques_no, ques_no.join(','))
        unless hidden
          begin
            p = RedisInteract::Plumbing.new
            ques_no.each { |qu_id| p.update_redis_server_after_question_creation(publisher_question_bank_id, qu_id) }
          rescue Exception => e
            Rails.logger.debug ".......#{e}........"
          end
        end

      end
    rescue Exception => e
      @etx_file.reject!
      @etx_file.update_attribute(:error, e.message)
      logger.info "Exception in etx uploading....#{e.message}"
    end

  end

  def create_group_question(center_id, group_ques, ins_id,publisher_question_bank_id, hidden=false)
    questions_collected_from_group = []
    @q = Question.new
    @q.questiontext = group_ques.xpath("instruction").inner_text
    @q.qtype = group_ques.xpath("instruction").attr("qtype").to_s
    unless @q.qtype.present?
      @q.qtype = "passage"
    end
    @q.institution_id = ins_id
    @q.center_id = center_id
    @q.createdby = @user.id
    @q.defaultmark = 0
    @q.hidden = hidden
    @q.save(:validate => false)
    questions_collected_from_group << @q

    @tag_ids = []
    group_ques.xpath("itags/itag").each do |tag|
      name = tag.attr("name").to_s
      value = tag.attr("value").to_s
      if ["course", "academic_class", "subject", "chapter", "concept_names"].include? name
        @tag_ids << @q.add_tags(name, value).tag_id
      else
        if name == "subjective_lines"
          @q.answer_lines = value
          @q.save(:validate => false)
        elsif name == "qsubtype" and ["1","95"].all?{|i| [publisher_question_bank_id].include? i }
          q.add_tags("qsubtype", q.qtype)
        else
          @q.add_tags(name, value)
        end
      end
    end
    @q.add_tags("qsubtype", @q.qtype) unless @q.tags.select { |tag| tag.name=="qsubtype" }.present?
    @tag_ids.each do |t|
      @tag_ids.each do |i|
        if i != t
          Tag.add_ref_tags(i, t, @user.institution_id, @user.center_id, @publisher_question_bank.id)
        end
      end
    end
    child_questions = []
    group_ques.xpath("question_set").each do |ques|
      q = create_simple_question(center_id, ins_id, ques, publisher_question_bank_id, hidden)
      child_questions << q
    end
    # The following creates an association between parent and child questions in a passage question.
    # PassageQuestion is not really a passage question. It is a join model.
    child_questions.each do |q|
      pq = PassageQuestion.new
      pq.passage_question_id = @q.id
      pq.question_id = q.id
      pq.save
      questions_collected_from_group << q
    end
    questions_collected_from_group
  end

  def create_simple_question(center_id, ins_id, ques,publisher_question_bank_id, hidden=false)
    q = Question.new
    q.recommendation_tag = ques.xpath("recommend_tags").attr("value").to_s if ques.xpath("recommend_tags").present?
    qtype = ques.xpath("qtype").attr("value").to_s.downcase
    q.qtype = get_qtype(qtype)
    q.hidden = hidden
    if !ques.xpath("score").attr("value").nil?
      q.defaultmark = ques.xpath("score").attr("value").to_s.to_i
    end
    if ques.xpath("penalty").present?
      q.penalty = ques.xpath("penalty").attr("value").to_s.to_i
    end
    q.generalfeedback = ques.xpath("question/solution").inner_text
    if ["saq", "laq", "project", "vsaq", "activity", "vsaq-fib"].include? ques.xpath("qtype").attr("value").to_s.downcase
      ques.xpath("question/solution").each do |solution|
        q.generalfeedback = solution.inner_text
      end
    end
    multi_select = ques.xpath("qtype").attr("multi_select")
    q.multiselect = (multi_select.to_s.downcase == "true" ? true : false) if !multi_select.nil?
    q.questiontext = ques.xpath("question/question_text").inner_text
    q.institution_id = ins_id
    q.center_id = center_id
    q.createdby = @user.id
    q.actual_answer = ques.xpath("question/actual_answer").inner_text if ques.xpath("question/actual_answer").present?
    q.hint = ques.xpath("question/hint").inner_text if ques.xpath("question/hint").present?
    q.save(:validate => false)

    if ["mcq", "tof"].include? ques.xpath("qtype").attr("value").to_s.downcase
      fraction = ques.xpath("question/answer").attr("value").to_s.split(",") if !ques.xpath("question/answer").nil?
      ques.xpath("question/option").each_with_index do |option, index|
        qa = synthesize_question_answer(fraction, index, option, q)
        qa.save(:validate => false)
      end
    end

    if ques.xpath("qtype").attr("value").to_s.downcase == "fib"
      ques.xpath("question/options_fib").each do |option|
        qa = QuestionFillBlank.new
        qa.question_id = q.id
        c = 1
        qa.answer = ""
        option.xpath("option_blank").each do |option_blank|
          qa.answer = option_blank.inner_text if c == 1
          qa.answer = qa.answer + "," + option_blank.inner_text
          c = c+1
        end
        qa.case_sensitive = option.attr("value").to_s.to_i
        qa.fraction = 1

        qa.save(:validate => false)
      end
    end

    @meta = Hash.new
    @tag_ids = []
    ques.xpath("itags/itag").each do |tag|
      name = tag.attr("name").to_s
      value = tag.attr("value").to_s
      if ["course", "academic_class", "subject", "chapter", "concept_names"].include? name
        @tag_ids << q.add_tags(name, value).tag_id
      else
        if name == "subjective_lines"
          q.answer_lines = value
          q.save(:validate => false)
        elsif name == "qsubtype" and ["1","95"].all?{|i| [publisher_question_bank_id].include? i }
          q.add_tags("qsubtype", q.qtype)
        else
          q.add_tags(name, value).tag_id
        end
      end
    end
    q.add_tags("qsubtype", q.qtype) unless q.tags.select { |tag| tag.name=="qsubtype" }.present?
    q
  end

  def process_assessment_etx(etx_file_id, cur_user_id, publisher_question_bank_id)
    @user = User.find(cur_user_id)
    @publisher_question_bank = PublisherQuestionBank.find(publisher_question_bank_id)
    ins_id = !@user.institution_id.nil? ? @user.institution_id : 1
    center_id = !@user.center_id.nil? ? @user.center_id : "nil"
    @etx_file = EtxFile.find(etx_file_id)
    question_ids = []
    begin
    ActiveRecord::Base.transaction do
      @etx_file.being_processed!
      file = File.open(@etx_file.filename)
      etx = Nokogiri::XML(file)
      etx.css("assessment").each do |assessment|
        Quiz.skip_callback(:create, :before, :set_defaults)
        @assessment = Quiz.new(get_assessment_metadata(assessment, cur_user_id))
        @assessment.build_quiz_detail
        @assessment.save(validate: false)
        if (direct_child_sections = assessment.css('>section')).empty?
          #   look for question_sets and process
          questions = create_child_questions(center_id, ins_id, assessment,publisher_question_bank_id)
          questions.each do |question|
            @assessment.questions << question
            @publisher_question_bank.questions << question
            question_ids << question.id
            end
        else
          direct_child_sections.each do |direct_child_section|
            @section = @assessment.quiz_sections.build(get_section_metadata(direct_child_section))
            @section.save
            if (sub_sections = direct_child_section.css('>section')).empty?
              #   look for question_sets and process
              questions = create_child_questions(center_id, ins_id, direct_child_section,publisher_question_bank_id)
              questions.each do |question|
                QuizQuestionInstance.create(:quiz_id => @assessment.id, :quiz_section_id => @section.id, :question_id => question.id)
                @publisher_question_bank.questions << question
                question_ids << question.id
              end
              else
                sub_sections.each do |subsection|
                  @subsection = QuizSection.new(get_section_metadata(subsection))
                  @subsection.quiz_id = @assessment.id
                  @subsection.parent_id = @section.id
                  @subsection.save
                  #   look for question_sets and process
                  questions = create_child_questions(center_id, ins_id, subsection,publisher_question_bank_id)
                  questions.each do |question|
                    QuizQuestionInstance.create(:quiz_id => @assessment.id, :quiz_section_id => @subsection.id, :question_id => question.id)
                    @publisher_question_bank.questions << question
                    question_ids << question.id
                  end
                end
              end
            end
          end
        end
        @etx_file.accept!
      @etx_file.update_attribute(:ques_no, question_ids.join(','))
        begin
          p = RedisInteract::Plumbing.new
          question_ids.each { |qu_id| p.update_redis_server_after_question_creation(publisher_question_bank_id, qu_id) }
        rescue Exception => e
          Rails.logger.debug ".......#{e}........"
        end
      end
    rescue Exception => e
      @etx_file.reject!
      @etx_file.update_attribute(:error, e.backtrace)
      logger.info "Exception in etx uploading....#{e.backtrace}"
    end
  end

  def extract_zip
    @zip_upload = ZipUpload.find(self.id)
    puts self.id
    input_file = @zip_upload.asset
    puts "input_file_path: #{input_file.path}"
    FileUtils.mkdir_p Rails.root.to_s+'/public/pdf_reports/'+"#{@zip_upload.id}"
    Zip::ZipFile.open(input_file.path) do |zip_file|
      zip_file.each do |f|
        puts "#{'-'* 50}"
        if f.directory?
          puts "#{f} is a directory. Size is #{f.size}"
        elsif f.file?
          puts "#{f} is a file. Size is #{f.size}"
          puts "#{f} extension #{File.extname(f.to_s)}"
          if File.extname(f.to_s)=='.pdf'
            zip_file.extract(f, Rails.root.to_s+'/public/pdf_reports/'+"#{@zip_upload.id}/#{File.basename(f.to_s)}")
          end
        else
          puts "None"
        end
      end
    end
    send_reports(@zip_upload.id)
  end
  private

  def synthesize_question_answer(fraction, index, option, q)
    puts "fraction", fraction
    qa = QuestionAnswer.new
    qa.question = q.id
    qa.answer = option.xpath("option_text").inner_text
    qa.feedback = option.xpath("feedback").inner_text
    qa.answerformat="1"
    qa.feedbackformat="1"
    if fraction.length == 1
      qa.fraction = option_is_correct?(index, fraction.first) ? 1 : 0
    else
      if fraction.include?(%w(A B C D E)[index]) or fraction.include?(%w(1 2 3 4 5)[index])
        qa.fraction = 1
      else
        qa.fraction = 0
      end
    end
    qa
  end

  def option_is_correct?(index,fraction)
    case index+1
      when 1 then true if (fraction == "A" or fraction == "1")
      when 2 then true if (fraction == "B" or fraction == "2")
      when 3 then true if (fraction == "C" or fraction == "3")
      when 4 then true if (fraction == "D" or fraction == "4")
      when 5 then true if (fraction == "E" or fraction == "5")
      else
        false
    end
  end

  def get_qtype(qtype)
    if qtype == "mcq"
      "multichoice"
    elsif qtype == "fib"
      "fib"
    elsif qtype == "tof"
      "truefalse"
    elsif qtype == "saq"
      "saq"
    elsif qtype == "laq"
      "laq"
    elsif qtype == "vsaq"
      "vsaq"
    elsif qtype == "project"
      "project"
    elsif qtype == "activity"
      "activity"
    end
  end

  def get_assessment_metadata(assessment, current_user_id)
    {
        name: assessment.at_css(">name").try(:content),
        sumgrades: assessment.at_css(">marks").try(:content),
        timelimit: assessment.at_css(">time").try(:content),
        intro: assessment.at_css(">instructions").try(:content),
        createdby: current_user_id,
        modifiedby: current_user_id,
        format_type: 8,
        institution_id: User.find(current_user_id).institution_id,
        timecreated: Time.now,
        timemodified: Time.now
    }
  end

  def get_section_metadata(section)
    {
        name: section.at_css(">name").try(:content),
        intro: section.at_css(">instructions").try(:content)
    }
  end

  def create_child_questions(center_id, ins_id, assessment_unit,publisher_question_bank_id)
    questions = []
    assessment_unit.css(">question_set, group_questions").each do |question|
      if question.name=='question_set'
        # it is a simple question
        questions << create_simple_question(center_id, ins_id, question,publisher_question_bank_id)
      else
        # it is a grouped question
        question_group = create_group_question(center_id, question, ins_id,publisher_question_bank_id)
        question_group.each do |ques|
          questions << ques
        end
      end
    end
    questions
  end

  public

  # handle_asynchronously :extract_zip, queue: "reports"

  def send_reports(zip_upload_id)
    #report name format rollno_date_assessmentname
    path = Rails.root.to_s+'/public/pdf_reports/'+"#{zip_upload_id}"
    Dir.glob(path+"/**/*").each do |f|
      begin
        file_name = File.basename(f, ".pdf")
        roll_no = file_name.split("_")[0]
        #puts file_name
        puts roll_no
        user = User.find_by_rollno("NGI-"+roll_no) unless roll_no.nil?
        puts user.id
        unless user.nil?
           @message = Message.new
           @message.body = file_name.split("_")[1]
           @asset = @message.assets.build
           @asset.attachment = File.open(f)
           @message.recipient_id = user.id
           @message.subject = "#{file_name.split("_")[1..-1].join(" ")}"
           @message.message_type = "Report"
           @message.sender_id = 1
           @message.save
        end
      rescue
        next
      end
      #puts a.read
      #a.close
      #extract student id

      #send report to students
    end
  end
end
