class TestConfiguration < ActiveRecord::Base
  scope :default_order, order('created_at DESC')

  belongs_to :assessment,:foreign_key => 'content_id'
  belongs_to :group ,:foreign_key => :group_id ,:class_name => "User"

  belongs_to :content
  #before_update { |record| self.status = 2  unless self.status == 2}

  attr_reader :subject,:receiver_name,:recipient_id
  attr_accessor :subject,:receiver_name,:recipient_id

  composed_of :start_time,:class_name => 'Time',:mapping => %w(start_time to_i),:constructor => Proc.new{ |item| item },:converter => Proc.new{ |item| item }
  composed_of :end_time,:class_name => 'Time',:mapping => %w(end_time to_i),:constructor => Proc.new{ |item| item },:converter => Proc.new{ |item| item }

  before_save :append_subject_to_body_message,:set_group_id
  after_create :set_uri

  def set_uri
    self.update_attribute(:uri,self.content.uri) unless self.content.nil?
  end

  def set_group_id
    self.group_id ||= self.recipient_id unless self.recipient_id.nil?
  end
  #Validations
  #--------------------------------------------------------------------------------
  #validates :body_message,:test_type,:presence => true
  #--------------------------------------------------------------------------------

  def start_time
    Time.at(self[:start_time]).to_i unless self[:start_time].nil?
  end

  def end_time
    Time.at(self[:end_time]).to_i  unless self[:end_time].nil?
  end

  def append_subject_to_body_message
    if (!self.body_message.blank? and !self.subject.blank?)
      self.body_message = self.subject + ":" + self.body_message.split(':').last
    end
  end


  def publish_and_send_message
    logger.info "=======In test config publish and send message method===="
    unless self.assessment.asset.nil?
      @attachments_json_ary = []
      asset =  self.assessment.asset
      @attachments_json_ary << {:file_info=>{:path=>asset.url,:name=>asset.name,:type=>assessment.assessment_type,:size=>asset.file_size},
                                :test_info=>{:uri=>self.assessment.uri,:start_time=>self.start_time,:end_time=>self.end_time}}
    end

    subject = label = self.body_message.split(":")[0]
    subject = label ||= 'TEST'
    body = self.body_message+"$:#{self.uri}"
    #group = self.group_id
    group = self.group rescue nil

    #to check whether the assessment posted to user or group if nil=>Individual or 'Section'=>Group
    if group.try(:type).nil?
    message = Message.new( sender_id: self.created_by,
                           recipient_id: group.try(:id),
                           subject: subject,body: body,message_type: assessment.assessment_type,severity: 1,
                           label: label,attachments: @attachments_json_ary)
    else
      message = Message.new( sender_id: self.created_by,
                           group_id: group.try(:id),
                           subject: subject,body: body,message_type: assessment.assessment_type,severity: 1,
                           label: label,attachments: @attachments_json_ary)
    end
    if message.save
      self.toggle!(:published)
      self.update_attribute(:status,2)
    end
    self.assessment.update_attribute(:status,4)
  end

  def current_status
    case status
      when 1 then
        'New'
      when 2 then
        'Published'
      when 3 then
        'Evaluated'
      when 4 then
        'Processed'
      when 5 then
        'Un-Processed'
      when 6 then
        'Rejected'
      when 7 then
        'Ready to publish'
      when 20 then
        'Process and publish by EST'
      else
        'Deleted'
    end
  end


  def evaluate
    #TODO need to call this method from test config controller method evaluate too
    puts "Evaluating....................................."
    tc_end_time = Time.at(self.end_time).to_i rescue nil
   # @test_results to evaluate test result based on published to groups only
   # @test_results = TestResult.includes(:user=>:user_groups).where('uri = ? and submission_time <= ? and user_groups.group_id=?',self.uri,tc_end_time,self.group_id).group('test_results.user_id').order('submission_time desc,marks desc')

    #@test_results to evaluate test result based on published to groups or individuals
     @test_results = TestResult.includes(:user=>:user_groups).where('uri = ? and submission_time <= ? and (user_groups.group_id=? or test_results.user_id=?)',self.uri,tc_end_time,self.group_id,self.group_id).group('test_results.user_id').order('submission_time desc,marks desc')
    class_percentage_list =  @test_results.map(&:percentage)
    topper_mark = @test_results.map(&:marks).max rescue nil
    begin
      class_average = class_percentage_list.reduce(:+).to_f / class_percentage_list.size
      class_average = (class_average.nan? or class_average.infinite?)? 0 : class_average
    rescue
    end

    self.update_attributes(topper_mark: topper_mark ,class_average: class_average,status: 3)
    @rank = 1
    @test_results.map(&:marks).sort.reverse.uniq.each do |result|
      if result > 0
        @results = @test_results.where('marks=?',result)
        unless @results.empty?
          TestResult.transaction do
            @results.each do |rank|
              rank.update_attributes(:rank=>@rank,:rank_status=>true)
            end
          end
          @rank = @rank+1
        end
      end
    end
  end

  def is_practice_test?
    self.content.try(:name).eql?('assessment-practice-tests') or self.content.try(:type).eql?('AssessmentPracticeTest') or self.content.try(:assessment_category).eql?('practice-tests')
  end

  def can_evaluate?
    self.status==2 or self.status == 3
  end

end
