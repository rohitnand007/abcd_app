class QuizTargetLocation < ActiveRecord::Base
  belongs_to :quiz_targeted_group
  belongs_to :subject
  belongs_to :board
  belongs_to :content_year
  belongs_to :chapter
  belongs_to :topic
  belongs_to :sub_topic

  before_save :init
  def init
    self.subject_id ||= 0
    self.board_id ||= 0
    self.content_year_id ||= 0
    self.chapter_id ||= 0
    self.topic_id ||= 0
    self.sub_topic_id ||= 0
  end
end
