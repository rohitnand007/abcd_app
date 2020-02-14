class TopicsController < ApplicationController
   authorize_resource
  # GET /contents
  # GET /contents.json
  def index
    #unless current_user.is?("ET")
    #  @topics = Topic.page(params[:page])
    #else
    #  @topics = current_user.topics.page(params[:page])
    #end
    @topics = case current_user.role.name
                  when 'Edutor Admin'
                    Topic.page(params[:page])
                  when 'Institute Admin'
                    #Topic.by_boards_and_published_by_assets(current_user.institution.board_ids,current_user.institution.publisher_ids).page(params[:page])
                    Topic.where(:board_id=>current_user.institution.board_ids).page(params[:page])
                  when 'Center Representative'
                    #Topic.by_boards_and_published_by_assets(current_user.center.board_ids,current_user.institution.publisher_ids).page(params[:page])
                    Topic.where(:board_id=>current_user.center.board_ids).page(params[:page])
                  when 'Teacher'
                    current_user.topics.page(params[:page])
                  else
                    Topic.page(params[:page])
                end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @topics }
    end
  end

  # GET /Topics/1
  # GET /Topics/1.json
  def show
    @topic = Topic.find(params[:id])
    @sub_topics = @topic.sub_topics.page(params[:page])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @topic }
    end
  end

  # GET /Topics/new
  # GET /Topics/new.json
  def new
    params_hash = {board_id: params[:board_id],content_year_id: params[:content_year_id],
                   subject_id: params[:subject_id],chapter_id: params[:chapter_id]}
    @topic = Topic.new(params_hash)
    @topic.assets.build 
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @topic }
    end
  end

  # GET /Topics/1/edit
  def edit
    @topic = Topic.find(params[:id])
  end

  # POST /Topics
  # POST /Topics.json
  def create
    if current_user.is?("ET")
      @content = Content.find(params[:topic][:subject_id])
      params[:topic][:board_id] = @content.board_id
      params[:topic][:content_year_id]= @content.content_year_id
    end
    @topic = Topic.new(params[:topic])
    
    respond_to do |format|
      if @topic.save
        if [".pdf",".swf",".mp4"].include?(File.extname(@topic.assets.first.attachment_file_name))
          @topic.update_attribute(:status,0)
        elsif @topic.status == 1
          # extracting_zip_file(@chapter)
          # reading_and_updating_content(@extract_path)
          Content.send_message_to_est(false,current_user,@topic)
        else
          true
        end
         #send_message_to_est(@topic)
        format.html { redirect_to current_user.is?("ET")? teacher_contents_path(@teacher) : @topic, notice: 'Topic was successfully created.' }
        format.json { render json: @topic, status: :created, location: @topic }
      else
        format.html { render action: "new" }
        format.json { render json: @topic.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /Topics/1
  # PUT /Topics/1.json
  def update
    @topic = Topic.find(params[:id])
    if current_user.role.id == 7
     params[:topic][:status] = 6 
     params[:topic][:vendor_id] = @topic.vendor_id 
    end  
    respond_to do |format|
      if @topic.update_attributes(params[:topic])
        if @topic.status == 6
         Content.send_message_to_est(@topic.vendor,current_user,@topic)
        end  
        format.html { redirect_to @topic, notice: 'Topic was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @topic.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /Topics/1
  # DELETE /Topics/1.json
  def destroy
    @topic = Topic.find(params[:id])
    @topic.destroy

    respond_to do |format|
      format.html { redirect_to topics_url }
      format.json { head :ok }
    end
  end
   
   #after creating Topic. The message and email alert is sent to est 
    def send_message_to_est(topic)
        user = User.where('edutorid like ?','%EST-%').first
        message = Message.new
        message.sender_id = current_user.id
        message.recipient_id = user.id
        message.subject = "Topic to be processord"
        message.body = "New Topic is uploaded. Click "+ "#{view_context.link_to Topic.filename,Topic_path(Topic)}"+" to visit the contant "
        message.label = "Topic"
        message.message_type = "Topic process"
        message.save
        UserMailer.Topic_notification(user,Topic)
    end
 

  #Topic download for the EST and status  update
  def est_download
    @topic = Topic.find(params[:id])
    if current_user.role.name.eql?('Support Team')
      @topic.update_attribute(:status,'EST is Processing')
    end
    redirect_to @topic.assets.first.attachment.url
  end   
 
  #get the content code for the selected content year in page
  def get_subtopics
     @topic = Topic.find(params[:id]) 
     list = @topic.sub_topics.map {|u| Hash[value: u.id, name: u.name]}
     render json:list
  end
  
end
