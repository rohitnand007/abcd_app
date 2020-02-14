class QuizSection < ActiveRecord::Base
  belongs_to :quiz
  has_many :quiz_question_instances ,:dependent=>:destroy, :order=> "position ASC"
  has_many :questions, :through=>:quiz_question_instances, :order=> "position ASC"

  has_many :children_sections, class_name: "QuizSection", foreign_key: "parent_id"
  belongs_to :parent_section, class_name: "QuizSection" , foreign_key: "parent_id"
  accepts_nested_attributes_for :children_sections
  before_create :set_quiz_id

  def set_quiz_id
    if self.parent_section
      self.quiz_id = self.parent_section.quiz_id
    end
  end

  def direct_questions
    passage_questions = self.questions.select { |question| question.qtype=='passage' }
    self.questions - passage_questions.map(&:questions).flatten
  end

  def all_quiz_question_instances
    all_quiz_question_instances=[]
    if !self.children_sections.empty?
      children_sections = self.children_sections
      children_sections.each do  |sub_section|
        all_quiz_question_instances  = all_quiz_question_instances + sub_section.quiz_question_instances
     end
    else
      all_quiz_question_instances = all_quiz_question_instances + self.quiz_question_instances
    end
    return all_quiz_question_instances
  end

  def section_name
    self.parent_section ? self.parent_section.name+"/"+self.name :  self.name
  end
  def total_questions
    self.questions.size - self.no_of_passage_questions
  end

  def no_of_passage_questions
    self.questions.where(:qtype=>"passage").size
    end
end
