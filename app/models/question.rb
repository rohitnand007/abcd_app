class Question < ActiveRecord::Base
  EDUTOR = 1
  OPTIONS_DIFFICULT=[["Easy",1],["Medium",2],["Hard",3]]
  validates :questiontext, :presence => true
  validates :defaultmark,:penalty, :numericality => {:greater_than_or_equal_to=>0 }
  has_many :question_answers, :foreign_key => "question" ,:dependent=>:destroy
  has_many :question_match_subs, :foreign_key => "question",:dependent=>:destroy
  has_many :question_parajumbles, :foreign_key => "question" ,:dependent=>:destroy
  has_many :question_fill_blanks ,:dependent=>:destroy
  has_many :quiz_question_instances ,:dependent=>:destroy
  has_many :quiz_question_attempts
  has_many :question_images, :dependent=>:destroy
  has_many :taggings,:dependent => :destroy
  has_many :tags,:through => :taggings
  has_many :passage_questions,:foreign_key => 'passage_question_id',:dependent => :destroy
  has_many :questions, :through => :passage_questions
  belongs_to :context
  belongs_to :quiz
  belongs_to :question
  has_and_belongs_to_many  :publisher_question_banks
  validate :validate_context
  validate :validate_question_options
  accepts_nested_attributes_for :question_answers, :allow_destroy=>true, :reject_if => lambda { |question_answer| question_answer[:answer].blank?}
  accepts_nested_attributes_for :context
  accepts_nested_attributes_for :question_match_subs
  accepts_nested_attributes_for :question_parajumbles
  accepts_nested_attributes_for :question_fill_blanks , :allow_destroy=>true,  :reject_if => lambda { |question_fill_blank| question_fill_blank[:answer].blank?}
  accepts_nested_attributes_for :question_images, :allow_destroy=>true, :reject_if => :all_blank
  accepts_nested_attributes_for :passage_questions, :allow_destroy=>true, :reject_if => :all_blank
  accepts_nested_attributes_for :questions, :allow_destroy=>true, :reject_if => lambda { |question| question[:questiontext].blank?}

  attr_accessible :question_fill_blanks_attributes, :context_attributes,
                  :defaultmark, :penalty, :difficulty, :course,
                  :prob_skill, :data_skill, :useofit_skill, :creativity_skill,
                  :listening_skill, :speaking_skill, :grammer_skill, :vocab_skill,
                  :formulae_skill, :comprehension_skill, :knowledge_skill, :application_skill,
                  :questiontext, :generalfeedback, :qtype, :question_fill_blanks_attributes,
                  :tags, :hidden, :createdby, :institution_id, :center_id ,
                  :question_answers_attributes,:question_images_attributes,:passage_questions_attributes,
                  :questions_attributes,:answer_lines,:recommendation_tag,:hint,:actual_answer

  #accepts_nested_attributes_for :quiz_question_instances
  belongs_to :user, :foreign_key => "createdby"
  scope :all_questions ,lambda{|current_user,group_ids|
    where("(createdby =? or createdby IN (?)) AND hidden=?",current_user,group_ids,0)
  }
  before_create :set_defaults
  before_save :img_tag_edits
  after_save :set_defaultmarks
  after_save :set_mcq_tags


  amoeba do
    enable
    include_field :question_answers
    include_field :question_match_subs
    include_field :question_parajumbles

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
    if self.context.chapter_id.nil?
      errors.add :base, 'Please select Chapter.'
    end
  end


  def set_mcq_tags
    ds_qb_ids = [1,2,95,315]
    q_qb = self.publisher_question_banks.collect(&:id)
    ds_ques = !(q_qb.all?{|i| ds_qb_ids.include? i  })
    if self.qtype=="multichoice" and ds_ques
      if self.multiple_answer?
        add_tags('qsubtype', 'mmcq')
      else
        add_tags('qsubtype', 'smcq')
      end
    else
      add_tags('qsubtype', self.qtype)
    end
  end

  def set_defaultmarks
    if self.qtype != 'passage'
      if self.defaultmark.to_i == 0
        update_column(:defaultmark,1)
      end
    end
    self.question_answers.each do |i|
      i.answer = image_edits(i.answer)
      i.save(validate: false)
    end
  end

  def validate_question_options
    if self.qtype != "fib"
      if !self.question_answers.nil?
        valid = false
        self.question_answers.each do |qa|
          if qa.fraction == 1
            valid = true
          end
        end
        if !valid
          errors.add :base, 'Please select one of the options as the correct answer.'
        end
      end
    end
  end

  def set_defaults
    self.questiontextformat = 1
    self.generalfeedbackformat = 1
    self.defaultmark = 1 if self.defaultmark.nil?
    self.penalty = 0  if self.penalty.nil?
    self.length = 1
    self.timecreated = Time.now.to_i
    self.timemodified = Time.now.to_i
    if self.context.present? && self.context.topic_id.nil?
      self.context.topic_id = 0
    end
    self.questiontext = self.questiontext.sub('question_images','.')
    self.generalfeedback = self.generalfeedback.sub('question_images','.')
    # self.questiontext = image_edits(self.questiontext.sub('question_images','.'))
    # self.generalfeedback = image_edits(self.generalfeedback.sub('question_images','.'))
    # self.question_answers.each do |i|
    #   i.answer = image_edits(i.answer)
    #   i.save(validate: false)
    # end
  end

  def img_tag_edits
    self.questiontext = image_edits(self.questiontext)
    self.generalfeedback = image_edits(self.generalfeedback)
  end

  def image_edits(text)
    if [57483, 26718, 57297, 70316].include? self.createdby
     text.gsub("<img", "<img onload=\"this.width/=2;this.onload=null;\" style=\"height: auto;\" ").gsub(/width=\"\d+(px)?\"/, "").gsub(/height=\"\d+(px)?\"/, "")
     else
    text
   end
  end

  def last_used(user_id)

  end

  def skills
    skills = []
    if self.application_skill?
      skills << "Application"
    end
    if self.comprehension_skill?
      skills << "Comprehension"
    end
    if self.creativity_skill?
      skills << "Creativity"
    end
    if self.data_skill?
      skills << "Data Interpretation"
    end
    if self.formulae_skill?
      skills << "Formulae"
    end
    if self.grammer_skill?
      skills << "Grammer"
    end
    if self.knowledge_skill?
      skills << "Knowledge"
    end
    if self.listening_skill?
      skills << "Listening"
    end
    if self.prob_skill?
      skills << "Problem Solving"
    end
    if self.speaking_skill?
      skills << "Speaking"
    end
    if self.vocab_skill?
      skills << "Vocabulary"
    end
    return skills.join(",")
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

  def course_text
    if self.course == 0
      return "Regular"
    end
    if self.course == 1
      return "IIT"
    end
    if self.course == 2
      return "Olympiad"
    end
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

  def questiontext_format
    t = self.questiontext.gsub('src="./','src="')
    t = t.gsub("/question_images", "")
    t = t.gsub("src='./","src='")
    t = t.gsub('src="','src="/question_images/')
    t = t.gsub("src='./","src='/question_images/")
    t = t.gsub('SRC="','SRC="/question_images/')
    #t = t.gsub("src=","src=/question_images/" )
    t = t.gsub('#DASH#',' ___________ ')
    t = t.gsub(/font-size/,' ')
    return t
  end

  def questiontext_format_new
    t = self.questiontext.gsub('src="./','src="')
    t = t.gsub("/question_images", "")
    t = t.gsub("src='./","src='")
    t = t.gsub('src="','src="/question_images/')
    t = t.gsub("src='./","src='/question_images/")
    t = t.gsub('SRC="','SRC="/question_images/')
    t = t.gsub('#DASH#',' ___________ ')
    t = t.gsub(/font-family/,' ')
    t = t.gsub(/font-size/, ' ')
    return t
  end
  def pdf_questiontext_format
    t = self.questiontext.gsub('src="./','src="')
    t = t.gsub("src='./","src='")
    t = t.gsub("/question_images", "")
    t = t.gsub('src="','src="/question_images/')
    t = t.gsub("src='./","src='/question_images/")
    t = t.gsub('SRC="','SRC="/question_images/')
    t = t.gsub('#DASH#',' ___________ ')
    #t = t.gsub(/font-family/,' ')
    #t = t.gsub(/font-size/, ' ')
    t = t.gsub("/question_images/","file://#{Rails.root.to_s}/public/question_images/")
    #t = t.gsub("<img", "<img onload=\"this.width/=2;this.onload=null;\"")
    return t
  end

  def generalfeedback_format
    t = self.generalfeedback.gsub('src="./','src="')
    t = t.gsub("src='./","src='")
    t = t.gsub("/question_images", "")
    t = t.gsub('src="','src="/question_images/')
    t = t.gsub("src='./","src='/question_images/")
    t = t.gsub('SRC="','SRC="/question_images/')
    return t
  end
  def actual_answer_format
    t = self.actual_answer.gsub('src="./','src="')
    t = t.gsub("src='./","src='")
    t = t.gsub("/question_images", "")
    t = t.gsub('src="','src="/question_images/')
    t = t.gsub("src='./","src='/question_images/")
    t = t.gsub('SRC="','SRC="/question_images/')
    return t
  end

  def feedback_format
    t = self.generalfeedback.gsub('src="./','src="')
    t = t.gsub("src='./","src='")
    t = t.gsub("/question_images", "")
    t = t.gsub('src="','src="/question_images/')
    t = t.gsub("src='./","src='/question_images/")
    t = t.gsub('SRC="','SRC="/question_images/')
    t = t.gsub('#DASH#',' ___________ ')
    #t = t.gsub(/font-family/,' ')
    #t = t.gsub(/font-size/, ' ')
    t = t.gsub("/question_images/","file://#{Rails.root.to_s}/public/question_images/")
    #t = t.gsub("<img", "<img onload=\"this.width/=2;this.onload=null;\"")
    return t
  end

  def add_tags(name,value)
    t =  Tag.find_or_create_by_name_and_value(name,value.strip)
    Tagging.find_or_create_by_tag_id_and_question_id(t.id,self.id)
  end

  def remove_tag(name, value)
    tag = Tag.find_by_name_and_value_and_standard(name, value, false)
    if tag.present?
      self.tags -= [tag]
      return true
    end
    return false
  end

  def itags
    tag_list = {}
    Tag.includes(:taggings).where("taggings.question_id=#{self.id}").map do |tag|
      if tag_list.has_key?(tag.name)
        tag_list[tag.name] = tag_list[tag.name]+[tag.value]
      else
        tag_list[tag.name]  = [tag.value]
      end
      tag_list[tag.name] =  tag_list[tag.name].uniq
    end
    tag_list.empty? ? nil : tag_list.map{|k,v| "#{k}:#{v.join(',')}"}.join("\n")
  end

  def is_passage_question?
   if  PassageQuestion.where(:question_id=>self.id).empty?
     return false
   else
     return true
   end
  end

  def passage_question
    passage_questions = PassageQuestion.where(:question_id=>self.id)
    passage_question = Question.find(passage_questions.first.passage_question_id)
    return passage_question
  end

  def human_readable_answer
    if ["multichoice", "truefalse"].include? self.qtype
      self.question_answers.select { |qa| qa.fraction.to_i==1 }.map(&:answer).join(",").gsub(%r{</?[^>]+?>}, '')
    elsif self.qtype=="fib"
      self.question_fill_blanks.map(&:answer).join(" ; ")
    else
      ""
    end
  end

  def changed_answer(qhash)
    if ["multichoice", "truefalse"].include? self.qtype
      new_answer = QuestionAnswer.where(id: qhash[:question_answers]).map(&:answer).join(",").gsub(%r{</?[^>]+?>}, '')
      new_answer.present? ? new_answer : ""
    elsif self.qtype=="fib"
      Rails.logger.debug "---------#{qhash}--------"
      qhash[:question_fill_blanks].map { |k, v| v }.join(";")
    else
      ""
    end
  end

  def multiple_answer?
    if self.multiselect
      return true
    else
      answer_count=0
      self.question_answers.each { |qa| answer_count = answer_count+1 if qa.fraction==1 }
      answer_count > 1 ? true : false
    end
  end

  def update_redis_server_after_question_removal_from_qb(qb_ids)
    qu_id = self.id
    logger.info "********************************qu_id: #{qu_id}"
    logger.info "****************************qb_ids: #{qb_ids}"
      begin
        p = RedisInteract::Plumbing.new
        qb_ids.each { |qb_id| p.update_redis_server_after_question_removal_from_qb(qb_id, qu_id) }
        logger.info "*********************removed questions"
          #   Since redis server may or may not be online at the time of calling this function, we shall prevent excpetions
      rescue Exception => e
        logger.info "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee#{e}eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        return
      end
  end
  # handle_asynchronously :update_redis_server_after_question_removal_from_qb, queue: "reports"

  def has_concept_name_tag
    self.tags.where(:name=>"concept_names")
  end

  def update_redis_server_after_question_creation
    if self.hidden == true
      #Dont add
      return false
    end
    qb_ids = self.publisher_question_bank_ids
    begin
      p = RedisInteract::Plumbing.new
      qb_ids.each { |qb_id| p.update_redis_server_after_question_creation(qb_id, self.id) }
      logger.info "*********************question added"
        #   Since redis server may or may not be online at the time of calling this function, we shall prevent excpetions
    rescue Exception => e
      logger.info "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee#{e}eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
      return
    end
    return true
  end

end
