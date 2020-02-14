class QuestionAnswer < ActiveRecord::Base
  validates :answer, :presence => true
  has_many :mcq_question_attempts
  before_create :set_defaults
#  belongs_to :question ,:foreign_key => "question"


  def answer_format
    t = self.answer.gsub('src="./','src="')
    t = t.gsub("src='./","src='")
    t = t.gsub('src="','src="/question_images/')
    t = t.gsub("src='./","src='/question_images/")
    t = t.gsub('SRC="','SRC="/question_images/')
    #t = t.gsub(/font-family/,' ')
    t = t.gsub(/font-size/, ' ')
    return t
  end

  def pdf_answer_format
    t = self.answer.gsub('src="./','src="')
    t = t.gsub("src='./","src='")
    t = t.gsub('src="','src="/question_images/')
    t = t.gsub("src='./","src='/question_images/")
    t = t.gsub('SRC="','SRC="/question_images/')
    #t = t.gsub(/font-family/,' ')
    t = t.gsub(/font-size/, ' ')
    t = t.gsub("/question_images/","file://#{Rails.root.to_s}/public/question_images/")
    #t = t.gsub("<img", "<img onload=\"this.width/=2;this.onload=null;\"")
    return t
  end


  def set_defaults
      self.answer = self.answer.sub('question_images','.')
      if self.tag.nil?
        self.tag = ''
      end
  end
end
