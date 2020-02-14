class Asset < ActiveRecord::Base
  scope :get_assessments_by_publisher_id, lambda{|publisher_id| where(:publisher_id=>publisher_id,:archive_type =>['Assessment','AssessmentInstiTest','AssessmentPracticeTest','AssessmentIit','AssessmentInclass','AssessmentOlympiad'] )}
  belongs_to :archive, :polymorphic => true
  belongs_to :quiz
  belongs_to :publisher
  belongs_to :teacher
  #belongs_to :assessment,:foreign_key=>"archive_id", :conditions=>["archive_type=?","Assessment"]
  belongs_to :assessment,:foreign_key => "archive_id",
             :conditions=>['archive_type like ? or archive_type like ? or archive_type like ? or archive_type like ? ','Assessment','AssessmentInstiTest','AssessmentPracticeTest','AssessmentHomeWork']
  belongs_to :assessment_category,:foreign_key=>"archive_id", :conditions=>["archive_type=?","AssessmentCategory"]
  belongs_to :chapter,:foreign_key=>"archive_id", :conditions=>["archive_type=?","Chapter"]
  belongs_to :topic,:foreign_key=>"archive_id", :conditions=>["archive_type=?","Topic"]
  belongs_to :sub_topic,:foreign_key=>"archive_id", :conditions=>["archive_type=?","SubTopic"]
  belongs_to :user,:foreign_key=>"publisher_id"
  belongs_to :content,:foreign_key=>"archive_id"
  belongs_to :masterchip
  belongs_to :assessment_pdf_job, :foreign_key => "archive_id"

  before_save :set_src  , :if=>Proc.new{|item| item.src.nil? }
  #before_save :permalink_src

  before_save :set_content_type , :if=>Proc.new{|item| item.attachment.nil? }



  def set_content_type
    self.attachment_content_type = MIME::Types.type_for(self.attachment_file_name).first.to_s
  end

  #def attachment=(data)
  #  data.content_type = MIME::Types.type_for(data.original_filename).to_s
  #  puts "test test test"
  #end

  def update_original_class
    unless self.archive.class.name.eql?("Message")
      self.archive_type = self.archive.type
    end

  end

  def update_original_path
    attachment.update_attribute('attachment_file_original_path',self.url)
  end


  Paperclip.interpolates 'created_user' do |attachment, style|
    attachment.instance.archive.sender_id if attachment.instance.archive.instance_of?(Message)
  end

  #  Paperclip.interpolates 'timestamp' do |attachment, style|
  #    attachment.instance.archive.created_at.strftime("%Y%m%d%H%M%S")  if attachment.instance.archive.instance_of?(Message)
  #  end
  #
  #  Paperclip.interpolates 'board' do |attachment, style|
  #    attachment.instance.archive.board.name if attachment.instance.archive.instance_of?(Content)
  #  end
  #
  #  Paperclip.interpolates 'academic_class' do |attachment, style|
  #    attachment.instance.archive.academic_class.name if attachment.instance.archive.instance_of?(Content)
  #  end

  #   Paperclip.interpolates 'subject' do |attachment, style|
  #    attachment.instance.archive.subject.name if attachment.instance.archive.instance_of?(Content)
  #  end

  Paperclip.interpolates :path_url do |attachment, style|
    @name = attachment.instance.archive
    @string_name = attachment.instance.archive.class.name
    @display_name = attachment.instance

    #status = attachment.instance.archive.status unless attachment.instance.archive.class.name.eql?("Message")
    if @display_name.src.blank?
      puts "===============setting the url"
      if @string_name.eql?("Message")
        return "/archives/#{@name.sender_id}/#{@name.created_at}/:basename_:id" + ".:extension"
        #elsif status == 1 or status == 3 or status == 5 or status == 6
        # return "/archives/#{Content::STATUS[@name.status]}/#{@name.board.name}/#{@name.content_year.name.match(/(\d+)/)[0]}/#{@name.subject.name}/:basename_:id" + ".:extension"
      else
        case @string_name
          when "Content"
            return "/curriculum/content/#{@name.board.code}/#{@name.academic_class.name}/#{@name.subject.name}/:basename_:id" + ".:extension"
          when "Message"
            return "/messages/#{@name.sender_id}/#{@name.created_at}/:basename_:id" + ".:extension"
          when "ContentYear"
            return "/curriculum/content/#{@name.board.code}_#{@display_name.publisher_id}/#{@name.name}/:basename" + ".:extension"
          when "Subject"
            return "/curriculum/content/#{@name.board.code}_#{@display_name.publisher_id}/#{@name.content_year.code}/#{@name.name}/:basename" + ".:extension"
          when "Chapter"
            return "/curriculum/content/#{@name.board.code}_#{@display_name.publisher_id}/#{@name.content_year.code}/#{@name.subject.code}/#{@name.name}/:basename" + ".:extension"
          when "Topic"
            return "/curriculum/content/#{@name.board.code}_#{@display_name.publisher_id}/#{@name.content_year.code}/#{@name.subject.code}/#{@name.chapter.name}/#{@name.name}/:basename" + ".:extension"
          when "SubTopic"
            return "/curriculum/content/#{@name.board.code}_#{@display_name.publisher_id}/#{@name.content_year.code}/#{@name.subject.code}/#{@name.chapter.name}/#{@name.topic.name}/#{@name.name}/:basename" + ".:extension"
          when "Assessment"
            if @name.subject
              return  "/curriculum/assessments/#{@name.subject.board.code}_#{@display_name.publisher_id}/#{@name.subject.content_year.code}/practice/#{@name.subject.code}/#{@name.name}/:basename" + ".:extension"
            elsif @name.chapter
              return  "/curriculum/assessments/#{@name.chapter.board.code}_#{@display_name.publisher_id}/#{@name.chapter.content_year.code}/practice/#{@name.chapter.subject.code}/#{@name.chapter.name}/#{@name.name}/:basename" + ".:extension"
            elsif @name.topic
              return  "/curriculum/assessments/#{@name.topic.board.code}_#{@display_name.publisher_id}/#{@name.topic.content_year.code}/practice/#{@name.topic.subject.code}/#{@name.topic.chapter.name}/#{@name.topic.name}/#{@name.name}/:basename" + ".:extension"
            elsif @name.sub_topic
              return  "/curriculum/assessments/#{@name.sub_topic.board.code}_#{@display_name.publisher_id}/#{@name.sub_topic.content_year.code}/practice/#{@name.sub_topic.subject.code}/#{@name.sub_topic.chapter.name}/#{@name.sub_topic.topic.name}/#{@name.sub_topic.name}/#{@name.name}/:basename" + ".:extension"
            end
          when "AssessmentCategory"
            if @name.subject
              return  "/curriculum/assessments/#{@name.subject.board.code}_#{@display_name.publisher_id}/#{@name.subject.content_year.code}/#{@name.subject.code}/#{@name.name}/:basename" + ".:extension"
            elsif @name.chapter
              return  "/curriculum/assessments/#{@name.chapter.board.code}_#{@display_name.publisher_id}/#{@name.chapter.content_year.code}/#{@name.chapter.subject.code}/#{@name.chapter.name}/#{@name.name}/:basename" + ".:extension"
            elsif @name.topic
              return  "/curriculum/assessments/#{@name.topic.board.code}_#{@display_name.publisher_id}/#{@name.topic.content_year.code}/#{@name.topic.subject.code}/#{@name.topic.chapter.name}/#{@name.topic.name}/#{@name.name}/:basename" + ".:extension"
            elsif @name.sub_topic
              return  "/curriculum/assessments/#{@name.sub_topic.board.code}_#{@display_name.publisher_id}/#{@name.sub_topic.content_year.code}/#{@name.sub_topic.subject.code}/#{@name.sub_topic.chapter.name}/#{@name.sub_topic.topic.name}/#{@name.sub_topic.name}/#{@name.name}/:basename" + ".:extension"
            end
          when "AssessmentPracticeTest"
            if @name.subject
              return  "/curriculum/assessments/#{@name.subject.board.code}_#{@display_name.publisher_id}/#{@name.subject.content_year.code}/practice/#{@name.subject.code}/#{@name.name}/:basename" + ".:extension"
            elsif @name.chapter
              return  "/curriculum/assessments/#{@name.chapter.board.code}_#{@display_name.publisher_id}/#{@name.chapter.content_year.code}/practice/#{@name.chapter.subject.code}/#{@name.chapter.name}/#{@name.name}/:basename" + ".:extension"
            elsif @name.topic
              return  "/curriculum/assessments/#{@name.topic.board.code}_#{@display_name.publisher_id}/#{@name.topic.content_year.code}/practice/#{@name.topic.subject.code}/#{@name.topic.chapter.name}/#{@name.topic.name}/#{@name.name}/:basename" + ".:extension"
            elsif @name.sub_topic
              return  "/curriculum/assessments/#{@name.sub_topic.board.code}_#{@display_name.publisher_id}/#{@name.sub_topic.content_year.code}/practice/#{@name.sub_topic.subject.code}/#{@name.sub_topic.chapter.name}/#{@name.sub_topic.topic.name}/#{@name.sub_topic.name}/#{@name.name}/:basename" + ".:extension"
            end
          when "ConceptMap"
            if @name.subject
              return  "/curriculum/conceptmaps/#{@name.subject.board.code}_#{@display_name.publisher_id}/#{@name.subject.content_year.code}/#{@name.subject.code}/#{@name.name}/:basename" + ".:extension"
            elsif @name.chapter
              return  "/curriculum/conceptmaps/#{@name.chapter.board.code}_#{@display_name.publisher_id}/#{@name.chapter.content_year.code}/#{@name.chapter.subject.code}/#{@name.chapter.name}/#{@name.name}/:basename" + ".:extension"
            elsif @name.topic
              return  "/curriculum/conceptmaps/#{@name.topic.board.code}_#{@display_name.publisher_id}/#{@name.topic.content_year.code}/#{@name.topic.subject.code}/#{@name.topic.chapter.name}/#{@name.topic.name}/#{@name.name}/:basename" + ".:extension"
            elsif @name.sub_topic
              return  "/curriculum/conceptmaps/#{@name.sub_topic.board.code}_#{@display_name.publisher_id}/#{@name.sub_topic.content_year.code}/#{@name.sub_topic.subject.code}/#{@name.sub_topic.chapter.name}/#{@name.sub_topic.topic.name}/#{@name.sub_topic.name}/#{@name.name}/:basename" + ".:extension"
            end
          when "AssessmentPdfJob"
            "/system/pdfs/#{@name.scheduled_task.parent_obj.class.name}/#{@name.scheduled_task.parent_obj.id}/#{@name.scheduled_task.id}/:basename" + ".:extension"
          else
            "/system/#{@name.type}/#{@name}/:basename" + ".:extension"
        end
      end
    else
      if @string_name.eql?'ContentYear' or @string_name.eql? 'Subject' or @string_name.eql? 'AssessmentCategory'
        if @display_name.attachment?
          puts "===in attachment src"
          return @display_name.src+"/:basename" + ".:extension"
        else
          return @display_name.src
        end
      elsif @string_name.eql?'Message'
        return @display_name.src.gsub(@display_name.src.split("/").last,"").gsub("/message_download/#{@display_name.archive.id}/","/messages/")+":basename" + ".:extension"
      else
        src_url = @display_name.src.gsub(@display_name.src.split("/").last,"")
        if @display_name.attachment?
          puts "===in attachment src_url"
          return src_url+":basename" + ".:extension"
        else
          return src_url
        end
      end
    end
  end


  Paperclip.interpolates :set_attachment_path do |attachment, style|
    if attachment.instance.archive_type == "Quiz"
      return ":rails_root/catch_all:path_url"
    elsif attachment.instance.archive_type == "Masterchip"
      return ":rails_root/keys:path_url"
    else
      return ":rails_root/public:path_url"
    end
  end

  has_attached_file :attachment,
                    :url => ":path_url",
                    :path => ":set_attachment_path"
  #before_post_process :rename_attachment

  validates_attachment_presence :attachment  , :if=>Proc.new{|item| item.src.nil? }

  def rename_attachment
    extension = File.extname(attachment_file_name).downcase
    self.attachment.instance_write :file_name, Time.now.to_i.to_s+extension
  end
  #src is updated
  def set_src
    if self.src.nil? or !self.new_record?
      @name = self.archive
      case self.archive.class.name
        when "ContentYear"
          self.src = "/curriculum/content/#{@name.board.code}_#{self.publisher_id}/#{@name.name}"
        when "Subject"
          self.src = "/curriculum/content/#{@name.board.code}_#{self.publisher_id}/#{@name.content_year.code}/#{@name.name}"
        when "Message"
          self.src = "/message_download/#{@name.id}/#{@name.sender_id}/#{@name.created_at}/#{self.attachment_file_name}"
        when "Chapter"
          self.src = "/curriculum/content/#{@name.board.code}_#{self.publisher_id}/#{@name.content_year.code}/#{@name.subject.code}/#{@name.name}/#{self.attachment_file_name}"
        when "Topic"
          self.src = "/curriculum/content/#{@name.board.code}_#{self.publisher_id}/#{@name.content_year.code}/#{@name.subject.code}/#{@name.chapter.name}/#{@name.name}/#{self.attachment_file_name}"
        when "SubTopic"
          self.src = "/curriculum/content/#{@name.board.code}_#{self.publisher_id}/#{@name.content_year.code}/#{@name.subject.code}/#{@name.chapter.name}/#{@name.topic.name}/#{@name.name}/#{self.attachment_file_name}"
        when "Assessment"
          #assessment_type = self.archive.try(:assessment_type).split('-').first rescue 'practice'
          #assessment_type = 'practice'
          assessment_type = (self.archive.assessment_type.eql?'practice-tests') ? "practice" : "insti"
          if self.archive.sub_topic_id
            self.src = "/curriculum/assessments/#{@name.sub_topic.board.code}_#{self.publisher_id}/#{@name.sub_topic.content_year.code}/#{assessment_type}/#{@name.sub_topic.subject.code}/#{@name.sub_topic.chapter.name}/#{@name.sub_topic.topic.name}/#{@name.sub_topic.name}/#{@name.name}/#{self.attachment_file_name}"
          elsif self.archive.topic_id
            self.src = "/curriculum/assessments/#{@name.topic.board.code}_#{self.publisher_id}/#{@name.topic.content_year.code}/#{assessment_type}/#{@name.topic.subject.code}/#{@name.topic.chapter.name}/#{@name.topic.name}/#{@name.name}/#{self.attachment_file_name}"
          elsif self.archive.chapter_id
            self.src = "/curriculum/assessments/#{@name.chapter.board.code}_#{self.publisher_id}/#{@name.chapter.content_year.code}/#{assessment_type}/#{@name.chapter.subject.code}/#{@name.chapter.name}/#{@name.name}/#{self.attachment_file_name}"
          elsif self.archive.subject_id
            self.src = "/curriculum/assessments/#{@name.subject.board.code}_#{self.publisher_id}/#{@name.subject.content_year.code}/#{assessment_type}/#{@name.subject.code}/#{@name.name}/#{self.attachment_file_name}"
          else
            self.src = "/curriculum/assessments/#{self.publisher_id}/#{@name.name}/#{self.attachment_file_name}"
          end
        when "AssessmentHomeWork"
          if self.archive.sub_topic_id
            self.src = "/curriculum/homework/#{@name.sub_topic.board.code}_#{self.publisher_id}/#{@name.sub_topic.content_year.code}/#{@name.sub_topic.subject.code}/#{@name.sub_topic.chapter.name}/#{@name.sub_topic.topic.name}/#{@name.sub_topic.name}/#{@name.name}/#{self.attachment_file_name}"
          elsif self.archive.topic_id
            self.src = "/curriculum/homework/#{@name.topic.board.code}_#{self.publisher_id}/#{@name.topic.content_year.code}/#{@name.topic.subject.code}/#{@name.topic.chapter.name}/#{@name.topic.name}/#{@name.name}/#{self.attachment_file_name}"
          elsif self.archive.chapter_id
            self.src = "/curriculum/homework/#{@name.chapter.board.code}_#{self.publisher_id}/#{@name.chapter.content_year.code}/#{@name.chapter.subject.code}/#{@name.chapter.name}/#{@name.name}/#{self.attachment_file_name}"
          elsif self.archive.subject_id
            self.src = "/curriculum/homework/#{@name.subject.board.code}_#{self.publisher_id}/#{@name.subject.content_year.code}/#{@name.subject.code}/#{@name.name}/#{self.attachment_file_name}"
          else
            self.src = "/curriculum/homework/#{self.publisher_id}/#{@name.name}/#{self.attachment_file_name}"
          end
        when "DeviceMessage"
          self.src = "/device_messages/#{@name.sender_id}/#{@name.created_at}/#{self.attachment_file_name}"
        when "Quiz"
          self.src = "/attachments/#{@name.createdby}/#{Time.now.to_i}/#{self.attachment_file_name}"
        when "Masterchip"
          self.src = "/attachments/enc_keys/#{@name.id}/#{self.attachment_file_name}"
        when "MasterchipDetails"
          self.src = "/attachments/keys_db/#{@name.id}/#{Time.now.to_i}/#{self.attachment_file_name}"
        when "AssessmentPdfJob"
          "/system/pdfs/#{@name.scheduled_task.parent_obj.class.name}/#{@name.scheduled_task.parent_obj.id}/#{@name.scheduled_task.id}/:basename" + ".:extension"
        else
          self.src = "/system/#{@name.type}/#{self.publisher_id}/#{@name.name}/#{self.attachment_file_name}"
      end
    end
  end



  def permalink_src
    unless self.src.blank?
      self.src = self.src.gsub(/[ \-]+/i,   '-')
    end
  end

  def url(*args)
    attachment.url(*args)
  end

  def name
    attachment_file_name
  end

  def content_type
    attachment_content_type
  end

  def file_size
    attachment_file_size
  end


  #download attemps src
  def asset_download(message)
    self.src.gsub("messages/","message_downloads_#{message}/")
  end


end
