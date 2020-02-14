class ContentDeliveriesController < ApplicationController
  # GET /content_deliveries
  # GET /content_deliveries.json
  authorize_resource
  def index
    @content_deliveries = ContentDelivery.where(user_id: current_user.id).order("created_at DESC")

    @ibooks = current_user.ibooks
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @content_deliveries }
    end
  end

  # GET /content_deliveries/1
  # GET /content_deliveries/1.json
  def show
    @content_delivery = ContentDelivery.find(params[:id])
    if @content_delivery.to_group == true
      p = @content_delivery.group_id
      @students = User.find(p).students
    else
      p = @content_delivery.recipients.split(",") #this needs to be checked later by publishing once to single and multiple individuals
      @students = User.find(p)
    end
    user_id = @content_delivery.user_id
    message_id = @content_delivery.message_id

    @usu_array = []

    @students.each do |stu|
      w = UserMessage.where(["message_id = ? and user_id = ?", "#{message_id}", "#{stu.id}"]).first
      if w.nil?

        @usu_array << {id:stu.edutorid ,name:stu.name, downloaded:"Not yet Published"}

      elsif w.sync == false

        @usu_array << {id:stu.edutorid ,name:stu.name, downloaded:"Yes"}

      elsif w.sync == true

        @usu_array << {id:stu.edutorid ,name:stu.name, downloaded:"No"}


      end
    end


    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @usu_array }
    end
  end

  # GET /content_deliveries/new
  # GET /content_deliveries/new.json
  def new
    @content_delivery = ContentDelivery.new
    if params[:asset_id]
      @user_asset = UserAsset.find(params[:asset_id])
    else
      @user_asset = UserAsset.new
    end
    @ibook = Ibook.find(params[:id])
    @toc_tree = @ibook.get_toc_tree
    @new_book = @ibook.toc_items.present?
    @latest_toc_tree = @new_book ? @ibook.toc_items.where("content_type not like?","live-page") : []
    @chapter_arr = []
    @topic_arr ={}
    @sub_arr ={}
    @controller = self.class.to_s
    if current_user.is? "ET"
      @class_type =[["Assessment","assessment-practice-tests"], ["Audio", "audio"], ["Video", "video-lecture"], ["Web Link", "weblink"]]
    else
      @class_type =[["Animation","animation"],["Textbook","text-book"],["Assessment","assessment-practice-tests"],["Concept Map", "concept-map"], ["Audio", "audio"], ["Video", "video-lecture"], ["Web Link", "weblink"]]
    end    # "topic,chapter,animation,assessmentpracticetests,assessmentiittests,textbook,tsp,assessmentquiz,weblink,conceptmap,homework,activity,audio,glossary,question,videolecture,imagegallery,powerpoint,summary,knowdiscovery,learnobjectives,additionalresource,worksheet"
    @toc_tree["chapters"].each do |chapter|
      topic_hash = {}
      if @new_book
        chapter_info = @latest_toc_tree.where(uri:chapter["uri"]).first
        @chapter_arr << [chapter["name"], chapter["uri"], chapter_info.guid, chapter_info.parent_guid]
      else
        @chapter_arr << [chapter["name"], chapter["uri"]]
      end
      if chapter["topics"].present?
        chapter["topics"].each do |topic|
          sub_hash = {}
          if @new_book
            topic_info = @latest_toc_tree.where(uri:"#{topic["uri"]}").first
            topic_hash["#{topic["name"]}"] = "#{topic["uri"]}" "$" "#{topic_info.guid}" "$" "#{topic_info.parent_guid}"
          else
            topic_hash["#{topic["name"]}"] = "#{topic["uri"]}"
          end

          if topic["sub-topics"].present?
            topic["sub-topics"].each do |sub|
              if @new_book
                sub_topic_info = @latest_toc_tree.where(uri:"#{sub["uri"]}").first
                # binding.pry if sub_topic_info.nil?

                sub_hash["#{sub["name"]}"] = "#{sub["uri"]}" "$" "#{sub_topic_info.guid}" "$" "#{sub_topic_info.parent_guid}"
              else
                sub_hash["#{sub["name"]}"] = "#{sub["uri"]}"
              end

            end

          end
          @sub_arr["#{topic["name"]}"] = sub_hash
        end
        @topic_arr["#{chapter["name"]}"] = topic_hash
      end
    end
    @user_assets =  UserAsset.where(user_id: current_user.id)
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @content_delivery }
    end
  end

  # GET /content_deliveries/1/edit
  # GET /content_deliveries/1/edit
  def edit
    @content_delivery = ContentDelivery.find(params[:id])
  end

  # POST /content_deliveries
  # POST /content_deliveries.json
  def create
    @content_delivery = ContentDelivery.new(params[:content_delivery])
    @ibook = Ibook.find(params[:book_id])
    if params[:uri3].present?
      @target_uri = params[:uri3].split("$")[0] +"/"+ params[:name] + "_" + Time.now.to_i.to_s
    elsif params[:uri2].present?
      @target_uri = params[:uri2].split("$")[0] +"/"+ params[:name] + "_" + Time.now.to_i.to_s
    else params[:uri1].present?
    @target_uri = params[:uri1].split("$")[0] +"/"+ params[:name] + "_" + Time.now.to_i.to_s
    end
    @user_asset = UserAsset.find(params[:asset_id])
    ActiveRecord::Base.transaction do
      @content_delivery.ibook_id = @ibook.id
      @content_delivery.user_id = current_user.id
      @content_delivery.uri = @target_uri
      @content_delivery.user_asset_id = @user_asset.id
      @content_delivery.published_as = @user_asset.asset_type
      @content_delivery.is_content = params[:is_content?].present? ? true:false
      @content_delivery.is_assessment = params[:is_assessment?].present? ? true:false
      @content_delivery.is_homework = params[:is_homework?].present? ? true:false
      @content_delivery.show_in_live_page = params[:show_in_live_page].present? ? true:false
      @content_delivery.show_in_toc = params[:show_in_toc].present? ? true : false
      @content_delivery.display_name = params[:name]
      if @ibook.toc_items.present?
        if params[:uri3].present?
          unique_info = params[:uri3].split("$")
          @content_delivery.guid = @content_delivery.user_asset.guid #unique_info[-2].lstrip.rstrip
          @content_delivery.parent_guid = unique_info[-2].lstrip.rstrip #unique_info[-1].lstrip.rstrip
        elsif params[:uri2].present?
          unique_info = params[:uri2].split("$")
          @content_delivery.guid = @content_delivery.user_asset.guid #unique_info[-2].lstrip.rstrip
          @content_delivery.parent_guid = unique_info[-2].lstrip.rstrip #unique_info[-1].lstrip.rstrip
        else params[:uri1].present?
        unique_info = params[:uri1].split("$")
        @content_delivery.guid = @content_delivery.user_asset.guid #unique_info[-2].lstrip.rstrip
        @content_delivery.parent_guid = unique_info[-2].lstrip.rstrip #unique_info[-1].lstrip.rstrip
        end
      end


      if params[:group_id].present?
        @content_delivery.group_id = params[:group_id]
      else
        @content_delivery.to_group = false
        @content_delivery.recipients = params[:message][:multiple_recipient_ids]
      end

      respond_to do |format|
        if @content_delivery.save
          format.html { redirect_to user_assets_path(:p => 2), notice: 'Content is being delivered.' }
          format.json { render json: @content_delivery, status: :created, location: @content_delivery }
        else
          format.html { render action: "new" }
          format.json { render json: @content_delivery.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PUT /content_deliveries/1
  # PUT /content_deliveries/1.json
  def update
    @content_delivery = ContentDelivery.find(params[:id])

    respond_to do |format|
      if @content_delivery.update_attributes(params[:content_delivery])
        format.html { redirect_to @content_delivery, notice: 'Content delivery was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @content_delivery.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /content_deliveries/1
  # DELETE /content_deliveries/1.json
  def destroy
    @content_delivery = ContentDelivery.find(params[:id])
    @content_delivery.destroy

    respond_to do |format|
      format.html { redirect_to content_deliveries_url }
      format.json { head :ok }
    end
  end
end
