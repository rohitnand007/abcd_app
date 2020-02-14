require 'content_data'
include ContentData
class Content < ActiveRecord::Base

  #default_scope where('status !=?',7) #default scope for content and its sub classes

  scope :by_boards_and_published_by, lambda{ |board_ids,publisher_ids|
    joins(:asset).where(:board_id=>board_ids).where('assets.publisher_id IN (?)',publisher_ids)
  }
  scope :by_boards_and_published_by_assets, lambda{ |board_ids,publisher_ids|
    joins(:assets).where(:board_id=>board_ids).where('assets.publisher_id IN (?)',publisher_ids)
  }

  scope :default_order, order('created_at DESC')

  # The relation for getting all the children from the Content Path Table
  has_many :children,   :foreign_key => 'ancestor', :class_name => 'ContentPath',  :order => ('depth ASC')

# The relation for getting the parent from the Content Path Table
  has_many :parents,   :foreign_key => 'descendant', :class_name => 'ContentPath', :order => ('depth ASC')

  scope :assessment_types, :conditions=>{:type=>['Assessment','AssessmentInstiTest','AssessmentPracticeTest','AssessmentIit','AssessmentInclass','AssessmentOlympiad','AssessmentHomeWork']}

  #scope :assessment_types_with_homework, :conditions=>{:type=>['Assessment','AssessmentInstiTest','AssessmentPracticeTest','AssessmentIit','AssessmentInclass','AssessmentOlympiad','AssessmentHomeWork']}

  #assing the number of elements per page
  paginates_per 25

  STATUS = ["unpublished", "Under Process", "Processed", "Rejected", "Published", "EST-Processing", "EST-Processed","Masked","New","Evaluated","Publish Later"]

  before_save :create_uri , :if=>Proc.new{|item| item.uri.nil? }
  #before_save :permalink_name

  # The call back for checking if the same uri is present in the database and updating it if duplicates are found
  after_save:update_duplicate_uri

# The call back for creating the content paths after the content is created and also for updating the uid field
#  after_create:generate_content_paths

# The call back for updating the content paths after the content is updated
#  after_update:update_content_paths

# The call back for deleting the content paths before the content is deleted
#  before_destroy:delete_content_paths

  belongs_to :publisher
  belongs_to :user, :foreign_key=>"publisher_id"
  # has_many :content_groups
  has_many :boards , :conditions => {:type => 'Board'}
  has_many :content_years , :conditions => {:type => 'ContentYear'}
  has_many :subjects , :conditions => {:type => 'Subject'}
  has_many :chapters , :conditions => {:type => 'Chapter'}
  has_many :topics , :conditions => {:type => 'Topic'}
  has_many :sub_topics , :conditions => {:type => 'SubTopic'}
  has_many :class_rooms
  has_many :usages,:primary_key=>"uri",:foreign_key=>"uri"
  has_many :test_results ,:primary_key=>"uri",:foreign_key=>"uri"
  has_one :content_profile

  has_many :test_configurations,:foreign_key => 'content_id', :dependent => :destroy

  attr_accessible  :board_id, :content_year_id, :subject_id, :status, :type, :name,:code ,:chapter_id, :topic_id, :sub_topic_id, :paly_order, :is_locked, :is_group, :extras,:uri, :is_profile,:assessment_type,:play_order,:params,:passwd,:pre_requisite,:mime_type
#, :assets_attributes


#after creating content. The message and email alert is sent to est
  def self.send_message_to_est(receiver,current_user,content)
    if receiver
      user = receiver
    else
      user = User.where('edutorid like ?','%EST-%').first
    end
    message = Message.new(sender_id: current_user.id,recipient_id: user.id,
                          subject: Content.get_status(content.status),body: "New Content Uploaded",
                          label: content.type,message_type: "Content process")
    message.save
    UserMailer.content_notification(user,content,message).deliver
  end
#after processing content. The message and email alert is sent to respective teacher.
  def self.send_message_to_teacher(receiver,current_user,content,message)

    user = receiver
    message = Message.new(sender_id: current_user.id,recipient_id: user.id,
                          subject: Content.get_status(content.status),body: message,
                          label: content.type,message_type: "Content processed")
    message.save
    UserMailer.content_notification(user,content,message).deliver
  end

  def self.get_status(status)
    case status
      when  1
        "Content to be processerd"
      when  3
        "Content rejected"
      when  6
        "EST processed the content"
    end
  end

  #before creating content the uri is set
  def create_uri
    # unless self.board_id.nil?
    case self.type
      when "Board"
        self.uri = "Curriculum/Content/#{self.name}"
      when "ContentYear"
        self.uri = "/Curriculum/Content/#{self.board.name}/#{self.name}"

      when "Subject"
        if !self.subject_id.nil? # The code for handling if the subject has a subject as a parent
          self.uri = "/Curriculum/Content/#{self.board.name}/#{self.content_year.name}/#{self.parent_subject.name}"
        else
          self.uri = "/Curriculum/Content/#{self.board.name}/#{self.content_year.name}/#{self.name}"
        end

      when "Chapter"
        if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
          self.uri = "/Curriculum/Content/#{self.board.name}/#{self.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}/#{self.name}"
        else
          self.uri = "/Curriculum/Content/#{self.board.name}/#{self.content_year.name}/#{self.subject.name}/#{self.name}"
        end

      when "Topic"
        if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
          self.uri = "/Curriculum/Content/#{self.board.name}/#{self.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}/#{self.chapter.name}/#{self.name}"
        else
          self.uri = "/Curriculum/Content/#{self.board.name}/#{self.content_year.name}/#{self.subject.name}/#{self.chapter.name}/#{self.name}"
        end

      when "SubTopic"
        if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
          self.uri = "/Curriculum/Content/#{self.board.name}/#{self.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}/#{self.chapter.name}/#{self.topic.name}/#{self.name}"
        else
          self.uri = "/Curriculum/Content/#{self.board.name}/#{self.content_year.name}/#{self.subject.name}/#{self.chapter.name}/#{self.topic.name}/#{self.name}"
        end

      when "Assessment"

        if (!self.extras.nil? and self.extras.index("homework"))#self.extras == "homework" # The case if the assessment is given as a home work

          if self.sub_topic_id # Assessment Home Work For Sub Topic
            if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
              self.uri = "/Curriculum/HomeWork/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
            else
              self.uri = "/Curriculum/HomeWork/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
            end

          elsif self.topic_id  # Assessment Home Work For Topic
            if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
              self.uri = "/Curriculum/HomeWork/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}/#{self.name}"
            else
              self.uri = "/Curriculum/HomeWork/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}/#{self.name}"
            end

          elsif self.chapter_id # Assessment Home Work For Chapter
            if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
              self.uri = "/Curriculum/HomeWork/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}/#{self.name}"
            else
              self.uri = "/Curriculum/HomeWork/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}/#{self.name}"
            end

          elsif self.subject_id # Assessment Home Work For Subject
            if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
              self.uri = "/Curriculum/HomeWork/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}/#{self.name}"
            else
              self.uri = "/Curriculum/HomeWork/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}/#{self.name}"
            end
          end

        else

          if self.sub_topic_id # Assessment For Sub Topic
            if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
              self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.assessment_type}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
            else
              self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.assessment_type}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
            end

          elsif self.topic_id # Assessment For Topic
            if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
              self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.assessment_type}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}/#{self.name}"
            else
              self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.assessment_type}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}/#{self.name}"
            end

          elsif self.chapter_id # Assessment For Chapter
            if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
              self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.assessment_type}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}/#{self.name}"
            else
              self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.assessment_type}/#{self.chapter.subject.name}/#{self.chapter.name}/#{self.name}"
            end

          elsif self.subject_id # Assessment For Subject
            if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
              self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.assessment_type}/#{self.subject.parent_subject.name}/#{self.subject.name}/#{self.name}"
            else
              self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.assessment_type}/#{self.subject.name}/#{self.name}"
            end
          end
        end

      when "AssessmentCategory"

        if self.subject_id # AssessmentCategory For Subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}"
          end

        elsif self.chapter_id # AssessmentCategory For Chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          end

        elsif self.topic_id # AssessmentCategory For Topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          end

        elsif self.sub_topic_id # AssessmentCategory For Sub Topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end
        end

      when "AssessmentEndChapterQuiz"

        if self.subject_id # AssessmentEndChapterQuiz For Subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}"
          end

        elsif self.chapter_id # AssessmentEndChapterQuiz For Chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          end

        elsif self.topic_id # AssessmentEndChapterQuiz For Topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          end

        elsif self.sub_topic_id # AssessmentEndChapterQuiz For Sub Topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end
        end

      when "AssessmentEndTopicQuiz"

        if self.subject_id # AssessmentEndTopicQuiz For Subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}"
          end

        elsif self.chapter_id # AssessmentEndTopicQuiz For Chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          end

        elsif self.topic_id # AssessmentEndTopicQuiz For Topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          end

        elsif self.sub_topic_id # AssessmentEndTopicQuiz For Sub Topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end
        end

      when "AssessmentHomeWork"

        if self.sub_topic_id # AssessmentHomeWork For Sub Topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/HomeWork/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/HomeWork/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end

        elsif self.topic_id # AssessmentHomeWork For Topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/HomeWork/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/HomeWork/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}/#{self.name}"
          end

        elsif self.chapter_id # AssessmentHomeWork For Chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/HomeWork/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}/#{self.name}"
          else
            self.uri = "/Curriculum/HomeWork/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}/#{self.name}"
          end

        elsif self.subject_id # AssessmentHomeWork For Subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/HomeWork/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}/#{self.name}"
          else
            self.uri = "/Curriculum/HomeWork/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}/#{self.name}"
          end
        end

      when "AssessmentInTopicQuiz"

        if self.subject_id # AssessmentInTopicQuiz For Subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}"
          end

        elsif self.chapter_id # AssessmentInTopicQuiz For Chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          end

        elsif self.topic_id # AssessmentInTopicQuiz For Topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          end

        elsif self.sub_topic_id # AssessmentInTopicQuiz For Sub Topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end
        end

      when "AssessmentIit"

        if self.subject_id # AssessmentIit For Subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}"
          end

        elsif self.chapter_id # AssessmentIit For Chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          end

        elsif self.topic_id # AssessmentIit For Topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          end

        elsif self.sub_topic_id # AssessmentIit For Sub Topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end
        end

      when "AssessmentInclass"

        if self.subject_id # AssessmentInclass For Subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}"
          end

        elsif self.chapter_id # AssessmentInclass For Chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          end

        elsif self.topic_id # AssessmentInclass For Topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          end

        elsif self.sub_topic_id # AssessmentInclass For Sub Topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end
        end

      when "AssessmentInstiTest"

        if self.subject_id # AssessmentInstiTest For Subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}"
          end

        elsif self.chapter_id # AssessmentInstiTest For Chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          end

        elsif self.topic_id # AssessmentInstiTest For Topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          end

        elsif self.sub_topic_id # AssessmentInstiTest For Sub Topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end
        end

      when "AssessmentOlympiad"

        if self.subject_id # Assessment Olympiad for subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}"
          end

        elsif self.chapter_id # Assessment Olympiad for chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          end

        elsif self.topic_id # Assessment Olympiad for topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          end

        elsif self.sub_topic_id # Assessment Olympiad for sub topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end
        end

      when "AssessmentPracticeTest"

        if self.subject_id # Assessment practice test for subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/practice/#{self.subject.parent_subject.name}/#{self.subject.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/practice/#{self.subject.name}"
          end

        elsif self.chapter_id # Assessment practice test for chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/practice/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/practice/#{self.chapter.subject.name}/#{self.chapter.name}"
          end

        elsif self.topic_id # Assessment practice test for topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/practice/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/practice/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          end

        elsif self.sub_topic_id # Assessment practice test for sub topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/practice/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/practice/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end
        end

      when "Toc"

        if self.subject_id # TOC for subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}"
          end

        elsif self.chapter_id # TOC for chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          end

        elsif self.topic_id # TOC for topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          end

        elsif self.sub_topic_id # TOC for sub topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Assessment/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end
        end

      when "ConceptMap"

        if self.sub_topic_id # Content Map For Sub Topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Content/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Content/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end

        elsif self.topic_id # Content Map For Topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Content/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          else
            self.uri = "/Curriculum/Content/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}"
          end

        elsif self.chapter_id # Content Map For Chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Content/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          else
            self.uri = "/Curriculum/Content/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}"
          end

        elsif self.subject_id # Content Map For Subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Content/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}"
          else
            self.uri = "/Curriculum/Content/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}"
          end
        end
      else
        if self.sub_topic_id # Content Map For Sub Topic
          if !self.sub_topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Content/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.parent_subject.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Content/#{self.sub_topic.board.name}/#{self.sub_topic.content_year.name}/#{self.sub_topic.subject.name}/#{self.sub_topic.chapter.name}/#{self.sub_topic.topic.name}/#{self.sub_topic.name}/#{self.name}"
          end

        elsif self.topic_id # Content Map For Topic
          if !self.topic.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Content/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.parent_subject.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Content/#{self.topic.board.name}/#{self.topic.content_year.name}/#{self.topic.subject.name}/#{self.topic.chapter.name}/#{self.topic.name}/#{self.name}"
          end

        elsif self.chapter_id # Content Map For Chapter
          if !self.chapter.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Content/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.parent_subject.name}/#{self.chapter.subject.name}/#{self.chapter.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Content/#{self.chapter.board.name}/#{self.chapter.content_year.name}/#{self.chapter.subject.name}/#{self.chapter.name}/#{self.name}"
          end

        elsif self.subject_id # Content Map For Subject
          if !self.subject.subject_id.nil? # The code for handling if the subject has a subject as a parent
            self.uri = "/Curriculum/Content/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.parent_subject.name}/#{self.subject.name}/#{self.name}"
          else
            self.uri = "/Curriculum/Content/#{self.subject.board.name}/#{self.subject.content_year.name}/#{self.subject.name}/#{self.name}"
          end
        end

    end
    # end
  end

  #Removing spaces in the name attribute
  def permalink_name
    name.to_s.gsub!(/[^\x00-\x7F]+/, '') # Remove anything non-ASCII entirely (e.g. diacritics).
    name.to_s.gsub!(/[^\w_ \-]+/i,   '') # Remove unwanted chars.
    name.to_s.gsub!(/[ \-]+/i,      '-') # No more than one of the separator in a row.
    name.to_s.gsub!(/^\-|\-$/i,      '') # Remove leading/trailing separator.
  end

  #overriding delete method to Soft delete i.e content will not de deleted only the status is updated
  def destroye
    self.update_attribute(:status,7)
  end

  #displaying the configure link if assessment is published or est processed or evaluated and assessment asset not having readme.doc attachment.
  def is_configurable?
    (self.status == 4 or self.status == 6 or self.status == 9) and !self.try(:asset).try(:name).eql?('readme.doc')
  end

  # This method checks if the uri is duplicate if so it appends the uri with a random number
  def update_duplicate_uri
    # Checking if multiple content are present with the same uri the updating the uri
    duplicate_entries = Content.where(:uri=>self.uri)

    # Only change the uri if more than one entry is found for the current uri
    if duplicate_entries.length > 1
      old_uri = self.uri
      new_uri = old_uri+'_'+rand(100000).to_s

      # Updating the current uri with the newly generated uri
      self.update_attributes(:uri => new_uri)
    end
    # End of code for handling the content with same uri
  end

  # This is the method for generating the content path entries after the content entry is created
  def generate_content_paths

    # This code for updating the uid field with the id (primary key)
    self.update_attributes(:uid => self.id)

    # The first entry with the self parent
    first = ContentPath.new
    first.ancestor = self.id
    first.descendant = self.id
    first.depth = 0
    first.save

    # Getting the parent id of the content
    parent_id = ContentData.get_parent_id(self.id)

    # If a parent is found then putting all the Content Path Entries
    if parent_id > 0

      # Getting the parent id data
      parent = Content.find(parent_id)
      # Getting all the parents of the parent (NOTE: This also contains the current parent id)
      parent_parents = parent.parents
      if(parent_parents.length > 0)
        parent_parents.each do |p|

          # Creating the new content paths
          path = ContentPath.new
          path.ancestor = p["ancestor"]
          path.descendant = self.id
          path.depth = p["depth"]+1
          path.save
        end
      end
    end

  end

  # This is the method for updating the content path entries after the content is updated
  def update_content_paths

    # Checking if the parent id has changed for the current content have to change the content paths table only if parent id is changed
    new_parent_id = ContentData.get_parent_id(self.id)

    # Getting the old parent data from the content path table
    old_parent_id = 0
    old_parent = ContentPath.where(:descendant => self.id, :depth => 1)
    # If there are any parents found with the getting the old parent id
    if old_parent.length > 0
      old_parent_id = old_parent.first.ancestor
    end

    # If the parent id is changed then update the content path structure
    if new_parent_id != old_parent_id

      # Refer to the article "http://www.mysqlperformanceblog.com/2011/02/14/moving-subtrees-in-closure-table/" for the logic
      # Detach the node from the old parent    
      delete_query = "DELETE a FROM content_paths AS a JOIN content_paths AS d ON a.descendant = d.descendant LEFT JOIN content_paths AS x ON x.ancestor = d.ancestor AND x.descendant = a.ancestor WHERE d.ancestor = '"+self.id.to_s+"' AND x.ancestor IS NULL"
      ActiveRecord::Base.connection.execute(delete_query)

      # Attach the node to the new parent
      insert_query = "INSERT INTO content_paths (ancestor, descendant, depth) SELECT supertree.ancestor, subtree.descendant, supertree.depth+subtree.depth+1 FROM content_paths AS supertree JOIN content_paths AS subtree WHERE subtree.ancestor = '"+self.id.to_s+"' AND supertree.descendant = '"+new_parent_id.to_s+"'"
      ActiveRecord::Base.connection.execute(insert_query)

      ## The code for changing the childrens data of the edited node with the new parent data
      ## Getting the data of the new parent
      new_parent_data = Content.find(new_parent_id)

      ## Board is at the top level no need to change the children data
      if self.type == 'Board'

        ## Content year parent is changed  update all the children with the current board id
      elsif self.type == 'ContentYear'
        if self.children.map(&:descendant).length > 1
          Content.where(:id => self.children.map(&:descendant)).update_all(:board_id => self.board_id)
        end

        ## Subject parent is changed update all the children with the curent board id and content year id
      elsif self.type == 'Subject'
        if self.children.map(&:descendant).length > 1
          Content.where(:id => self.children.map(&:descendant)).update_all(:board_id => self.board_id, :content_year_id => self.content_year_id)
        end

        ## Chapter parent is changed update all the children with the current board id , content year id and subject id
      elsif self.type == 'Chapter'
        if self.children.map(&:descendant).length > 1
          Content.where(:id => self.children.map(&:descendant)).update_all(:board_id => self.board_id, :content_year_id => self.content_year_id, :subject_id => self.subject_id)
        end

        ## Topic parent is changed update all the children with the current board id, content year id, subject id and chapter id
      elsif self.type == 'Topic'
        if self.children.map(&:descendant).length > 1
          Content.where(:id => self.children.map(&:descendant)).update_all(:board_id => self.board_id, :content_year_id => self.content_year_id, :subject_id => self.subject_id, :chapter_id => self.chapter_id)
        end

        ## Subtopic parent is changed update all the children with the current board id, content year id, subject id, chapter id and topic id
      elsif self.type == 'SubTopic'
        if self.children.map(&:descendant).length > 1
          Content.where(:id => self.children.map(&:descendant)).update_all(:board_id => self.board_id, :content_year_id => self.content_year_id, :subject_id => self.subject_id, :chapter_id => self.chapter_id, :topic_id => self.topic_id)
        end
      end

      ## End of code for changing the childrens data

    end
  end

  # This is the method for deleting the content path entries before the content is deleted
  def delete_content_paths

    # Delete all the paths with the ancestor as the current id
    ContentPath.delete_all(:ancestor => self.id)

    # Delete all the paths with the descendant as the current id
    ContentPath.delete_all(:descendant => self.id)
  end

end
