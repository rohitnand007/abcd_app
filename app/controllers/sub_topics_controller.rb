class SubTopicsController < ApplicationController
   authorize_resource
  # GET /academic_classes
  # GET /academic_classes.json
  def index
    #unless  current_user.is?"ET"
    #    @sub_topics = SubTopic.page(params[:page])
    #else
    #  logger.info "innnnnnnnnnn"
    #  @sub_topics = current_user.sub_topics.page(params[:page])
    #end
    @sub_topics = case current_user.role.name
                    when 'Edutor Admin'
                      SubTopic.page(params[:page])
                    when 'Institute Admin'
                      #SubTopic.by_boards_and_published_by_assets(current_user.institution.board_ids,current_user.institution.publisher_ids).page(params[:page])
                      SubTopic.where(:board_id=>current_user.institution.board_ids).page(params[:page])
                    when 'Center Representative'
                      #SubTopic.by_boards_and_published_by_assets(current_user.center.board_ids,current_user.institution.publisher_ids).page(params[:page])
                      SubTopic.where(:board_id=>current_user.center.board_ids).page(params[:page])
                    when 'Teacher'
                      current_user.sub_topics.page(params[:page])
                    else
                      SubTopic.page(params[:page])
                  end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sub_topics }
    end
  end

  # GET /academic_classes/1
  # GET /academic_classes/1.json
  def show
    @sub_topic = SubTopic.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @sub_topic }
    end
  end

  # GET /academic_classes/new
  # GET /academic_classes/new.json
  def new
    params_hash = {board_id: params[:board_id],content_year_id: params[:content_year_id],
                   subject_id: params[:subject_id],chapter_id: params[:chapter_id],topic_id: params[:topic_id]}
    @sub_topic = SubTopic.new(params_hash)
    @sub_topic.assets.build
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @sub_topic }
    end
  end

  # GET /academic_classes/1/edit
  def edit
    @sub_topic = SubTopic.find(params[:id])
  end

  # POST /academic_classes
  # POST /academic_classes.json
  def create
    if current_user.is?("ET")
      @content = Content.find(params[:sub_topic][:subject_id])
      params[:sub_topic][:board_id] = @content.board_id
      params[:sub_topic][:content_year_id]= @content.content_year_id
    end
    @sub_topic = SubTopic.new(params[:sub_topic])
    respond_to do |format|
      if @sub_topic.save
        if [".pdf",".swf",".mp4"].include?(File.extname(@sub_topic.assets.first.attachment_file_name))
          @sub_topic.update_attribute(:status,0)
        elsif @sub_topic.status == 1
          # extracting_zip_file(@chapter)
          # reading_and_updating_content(@extract_path)
          Content.send_message_to_est(false,current_user,@sub_topic)
        else
          true
        end
        format.html { redirect_to current_user.is?("ET")? teacher_contents_path(@teacher) : @sub_topic, notice: 'Academic class was successfully created.' }
        format.json { render json: @sub_topic, status: :created, location: @sub_topic }
      else
        format.html { render action: "new" }
        format.json { render json: @sub_topic.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /academic_classes/1
  # PUT /academic_classes/1.json
  def update
    @sub_topic = SubTopic.find(params[:id])
    if current_user.role.id == 7
      params[:sub_topic][:status] = 6
      params[:sub_topic][:vendor_id] = @sub_topic.vendor_id
    end
    respond_to do |format|
      if @sub_topic.update_attributes(params[:sub_topic])
        if @sub_topic.status == 6
          Content.send_message_to_est(@sub_topic.vendor,current_user,@sub_topic)
        end
        format.html { redirect_to @sub_topic, notice: 'Academic class was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @sub_topic.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /academic_classes/1
  # DELETE /academic_classes/1.json
  def destroy
    @sub_topic = SubTopic.find(params[:id])
    @sub_topic.destroy

    respond_to do |format|
      format.js {render :nothing => true}
      format.html { redirect_to sub_topics_url }
      format.json { head :ok }
    end
  end

  # Get populating the academic subjects for a class
  def get_subjects
    @sub_topic = SubTopic.find(params[:id]) unless params[:id].blank?
    list = @sub_topic.subjects.map {|u| Hash[value: u.id, name: u.name]}
    render json: list
  end

end
