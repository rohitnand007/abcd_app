class TestConfigurationsController < ApplicationController
  authorize_resource :only=>[:edit, :index, :new, :show, :publish_form]
  # GET /test_configurations
  # GET /test_configurations.json
  before_filter :find_test_configuration,:except => [:index,:new,:create,:publish,:publish_form]
  before_filter :students_in_center
  def index
    #@test_configurations = TestConfiguration.where("status !=?",3).page(params[:page])
    @test_configurations =
        case current_user.role.name when "Edutor Admin"
                                      TestConfiguration.includes([:group=>:profile]).page(params[:page])
                                    when "Center Representative"
                                      TestConfiguration.includes([:group=>:profile]).where('created_by = ?',current_user.id).page(params[:page])
                                    when "Institue Admin"
                                      TestConfiguration.includes([:group=>:profile]).where('created_by = ?',current_user.id).page(params[:page])
                                    when "Teacher"
                                      TestConfiguration.includes([:group=>:profile]).where('created_by = ?',current_user.id).page(params[:page])
        end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @test_configurations }
    end
  end

  # GET /test_configurations/1
  # GET /test_configurations/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @test_configuration }
    end
  end

  # GET /test_configurations/new
  # GET /test_configurations/new.json
  def new
    @test_configuration = TestConfiguration.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @test_configuration }
    end
  end

  # GET /test_configurations/1/edit
  def edit

  end

  # POST /test_configurations
  # POST /test_configurations.json
  def create
    @test_configuration = TestConfiguration.new(params[:test_configuration])
    respond_to do |format|
      if @test_configuration.save
         @test_configuration.publish_and_send_message
        #format.html { redirect_to @test_configuration, notice: 'Test configuration was successfully created.' }
        #format.json { render json: @test_configuration, status: :created, location: @test_configuration }
        format.html { redirect_to assessments_path, notice: 'Test was published successfully.' }
        format.json { render json: @test_configuration, status: :created, location: @test_configuration }
      else
        format.html { render action: "new" }
        format.json { render json: @test_configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /test_configurations/1
  # PUT /test_configurations/1.json
  def update
    respond_to do |format|
      if @test_configuration.update_attributes(params[:test_configuration]) and @test_configuration.publish_and_send_message
        format.html { redirect_to @test_configuration, notice: 'Test configuration was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @test_configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /test_configurations/1
  # DELETE /test_configurations/1.json
  def destroy
    @test_configuration.update_attribute('status',4)
    respond_to do |format|
      format.html { redirect_to test_configurations_url }
      format.json { head :ok }
    end
  end

  #GET/test_configurations/1/publish_form
  def publish_form
    @message = Message.new
  end

  #GET/test_configurations/1/publish
  def publish
    #New Code
    @test_configuration = TestConfiguration.find(params[:id])

    unless @test_configuration.assessment.asset.nil?
      asset = @test_configuration.assessment.asset
      @attachments_json_ary = []
      @attachments_json_ary << {:file_info=>{:path=>asset.url,:name=>asset.name,:type=>asset.content_type,:size=>asset.file_size},
                                :test_info=>{:uri=>@test_configuration.assessment.uri,:start_time=>@test_configuration.start_time,:end_time=>@test_configuration.end_time}}

    end

    subject = label = params[:message][:subject]
    group = params[:message][:group_id]
    body = params[:message][:body] #"Submit by #{@test_configuration.end_time.strftime('%Y-' '%m-' '%d' ',%H:' '%M:' '%S')}"
    message = Message.new( sender_id: current_user.id,
                           group_id: group,
                           subject: subject,body: body,message_type: "mocktest",severity: 1,
                           label: label,attachments: @attachments_json_ary)
    if message.save
      @test_configuration.toggle!(:published)
      @test_configuration.update_attribute(:status,2)
      redirect_to test_configurations_path, notice: "Test Published Successfully.!!!"
    else
      redirect_to :back, alert: "Problem occurred while publishing.!!!"
    end



  end

  #GET/test_configurations/1/evaluate
  def evaluate
    #New Code
=begin    tc_end_time = Time.at(@test_configuration.end_time).to_i rescue nil
    @test_results = TestResult.includes(:user=>:user_groups).where('uri = ? and submission_time <= ? and user_groups.group_id=?',@test_configuration.uri,tc_end_time,@test_configuration.group_id).group('test_results.user_id').order('submission_time desc,marks desc')
    class_percentage_list =  @test_results.map(&:percentage)
    topper_mark = @test_results.map(&:marks).max rescue nil
    begin
    class_average = class_percentage_list.reduce(:+).to_f / class_percentage_list.size
    class_average = (class_average.nan? or class_average.infinite?)? 0 : class_average
    rescue
    end

    @test_configuration.update_attributes(topper_mark: topper_mark ,class_average: class_average,status: 3)
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
=end
    @test_configuration.evaluate #evalute the rank,later the above code can be deleted.
    redirect_to new_test_config_result_path(@test_configuration.id), notice: "Test Evaluated Successfully."
  end

  protected
  def find_test_configuration
    @test_configuration = TestConfiguration.find(params[:id])
  end
end
