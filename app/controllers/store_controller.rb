class StoreController < ApplicationController
  #authorize_resource
  # This is the method for displaying the store for the web
  def index
    generate_content_store_data
  end

  # This is the method for displaying the store for the tab
  def tab
    generate_content_store_data
    respond_to do |format|
      format.html { render :layout => FALSE }
    end
  end

  # This is the method for downloading the content from the store
  def download
    @content = Content.find(params[:id])
    # send_file process_zip(@content,@content.assets.first)
    # flash[:notice] = "This content will be downloaded to your device shortly"
    # redirect_to :back
    file = process_zip(@content,@content.assets.first)
    sent_to_user = send_content_to_user(@content,file)

    # If the message is sent to user show a success message
    if sent_to_user
        flash[:notice] = "This content will be downloaded to your device shortly"
        redirect_to :back
    else
      # Content is not sent to user showing an error message
        flash[:error] = "An error occured is sending the content to your device. Please try later"
        redirect_to :back
    end
  end

  # This is the method for downloading the content from the store from the store
  def download_tab
    @content = Content.find(params[:id])
    file = process_zip(@content,@content.assets.first)
    sent_to_user = send_content_to_user(@content,file)

    @message = Hash.new

    # If the message is sent to user show a success message
    if sent_to_user
        @message["notice"] = "This content will be downloaded to your device shortly"
    else
      # Content is not sent to user showing an error message
        @message["error"] = "An error occured is sending the content to your device. Please try later"
    end
    respond_to do |format|
      format.html { render :layout => FALSE }
    end
  end

  private

  # This is the method for creating the zip
  def process_zip(content,asset)
    path = Rails.root.to_s+"/tmp/cache/downloads/assessment_#{content.id}"
    src = asset.src
    src = src.gsub(asset.attachment_file_name,"")
    folder_path = path+src
    file_path = Rails.root.to_s+"/public"+src
    FileUtils.mkdir_p folder_path
    FileUtils.cp_r "#{file_path}/.",folder_path
    generate_ncx(content,path)
  end

  # This is the method for sending the content to the user
  def send_content_to_user(content,file)
    # TODO: Currently only allowing the student to download the content
    if current_user.rc != 'ES'
      return FALSE
    end
    @message = Message.new()
    @message_asset = @message.assets.build
    @message_asset.attachment = File.open(file,"rb")
    @message.sender_id = 1
    @message.recipient_id = current_user.id
    @message.message_type = "Content"
    @message.label = "Store Content"
    @message.subject =  "Edutor Store :: "+content.name
    @message.body = "Thank you for downloading the content from the Edutor Content Store"
    @message.save

    # Processing the attachment to be sent for the message
    @attachments_json_ary = []
    @attachments_json_ary << {:file_info=>{:path=>@message.assets.first.url,:name=>@message.assets.first.name,:type=>content.type,:size=>@message.assets.first.file_size}}
    @message.attachments = @attachments_json_ary
    saved = @message.save

    # Removing the file from the cache
    FileUtils.remove_dir(Rails.root.to_s+"/tmp/cache/downloads/assessment_#{content.id}",:force=>true)
    FileUtils.rm(Rails.root.to_s+"/tmp/cache/downloads/assessment_#{content.id}.zip",:force=>true)
    
    return saved
  end

  ## This is the method for generating the data for the content store
  def generate_content_store_data
    @contents = Content.where(:is_profile=>true).includes(:content_profile).page(params[:page])
    conditions = Hash.new
    @params =  params[:board] || params[:year] || params[:subject] || params[:chapter] || params[:topic] || params[:sub_topic]
    # If any parameters are defined then get the contents by the parameters
    if @params
      board = []
      year = []
      subject = []
      chapter = []
      topic = []
      sub_topic = []
      if params[:board]
        board << params[:board].to_i
      end
      if params[:year]
        year << params[:year].to_i
      end
      if params[:subject]
        subject <<  params[:subject].to_i
      end
      if params[:chapter]
        chapter <<  params[:chapter].to_i
      end
      if params[:topic]
        topic <<  params[:topic].to_i
      end
      if params[:sub_topic]
        sub_topic <<  params[:sub_topic].to_i
      end
      #@filter_content = Content.find_all_by_id(subject+year+board+chapter+topic+sub_topic)
      conditions[:subject_id] = subject.uniq unless subject.empty?
      conditions[:board_id] = board.uniq unless board.empty?
      conditions[:content_year_id] = year.uniq unless year.empty?
      conditions[:chapter_id] = chapter.uniq unless chapter.empty?
      conditions[:topic_id] = topic.uniq unless topic.empty?
      conditions[:sub_topic_id] = sub_topic.uniq unless sub_topic.empty?
      conditions[:is_profile] = true
      @show_contents = Content.where(conditions).includes(:content_profile).page(params[:page])
    else
      # If no filters are there then show all the contents
      conditions[:is_profile] = true
      @show_contents = Content.where(conditions).includes(:content_profile).page(params[:page])
    end

    # The code for getting the filter levels
    @filter_level = 'store'
    @filter_depth = 0
    @filter_id = 0
    if params[:board]
      @filter_level = 'board'
      @filter_depth = 1
      @filter_id = params[:board].to_i
    else
      if params[:year]
        @filter_level = 'year'
        @filter_depth = 2
        @filter_id = params[:year].to_i
      else
        if params[:subject]
          @filter_level = 'subject'
          @filter_depth = 3
          @filter_id = params[:subject].to_i
        else
          if params[:chapter]
            @filter_level = 'chapter'
            @filter_depth = 4
            @filter_id = params[:chapter].to_i
          else
            if params[:topic]
              @filter_level = 'topic'
              @filter_depth = 5
              @filter_id = params[:topic].to_i
            else
              if params[:sub_topic]
                @filter_level = 'sub_topic'
                @filter_depth = 6
                @filter_id = params[:sub_topic].to_i
              end
            end
          end
        end
      end
    end
    # End of code for getting the filter levels

    # The code for making the side panels of the store
    @side_panel_filter = []
    @side_panel_browse = []
    @side_panel_filter_head = ''
    @side_panel_browse_head = ''

    case @filter_level
    when "store"
      @side_panel_filter_head = 'Filter By Board'
      @boards = Content.find_all_by_id(@contents.map(&:board_id).uniq)
      @boards.each do |b|
        @side_panel_filter << [b.name,'?board='+b.id.to_s]
      end
    when "board"
      @side_panel_filter_head = 'Filter By Class'
      @years = Content.where(:id=>@contents.map(&:content_year_id).uniq,:board_id=>@filter_id)
      @years.each do |y|
        @side_panel_filter << [y.name,'?year='+y.id.to_s]
      end
      @side_panel_browse_head = 'Browse By Board'
      @boards = Content.find_all_by_id(@contents.map(&:board_id).uniq)
      @boards.each do |b|
        if b.id != @filter_id
          @side_panel_browse << [b.name,'?board='+b.id.to_s]
        else
          @side_panel_browse << [b.name,'']
        end
      end
    when "year"
      @side_panel_filter_head = 'Filter By Subject'
      @subjects = Content.where(:id=>@contents.map(&:subject_id).uniq,:content_year_id=>@filter_id)
      @subjects.each do |s|
        @side_panel_filter << [s.name,'?subject='+s.id.to_s]
      end
      @class_data = Content.find(@filter_id)
      @side_panel_browse_head = 'Browse By Class'
      @years = Content.where(:id=>@contents.map(&:content_year_id).uniq,:board_id=>@class_data.board.id)
      @years.each do |y|
        if y.id != @filter_id
          @side_panel_browse << [y.name,'?year='+y.id.to_s]
        else
          @side_panel_browse << [y.name,'']
        end
      end
    when "subject"
      @side_panel_filter_head = 'Filter By Chapter'
      @chapters = Content.where(:id=>@contents.map(&:chapter_id).uniq,:subject_id=>@filter_id)
      @chapters.each do |c|
        @side_panel_filter << [c.name,'?chapter='+c.id.to_s]
      end
      @subject_data = Content.find(@filter_id)
      @side_panel_browse_head = 'Browse By Subject'
      @subjects = Content.where(:id=>@contents.map(&:subject_id).uniq,:content_year_id=>@subject_data.content_year.id)
      @subjects.each do |s|
        if s.id != @filter_id
          @side_panel_browse << [s.name,'?subject='+s.id.to_s]
        else
          @side_panel_browse << [s.name,'']
        end
      end
    when "chapter"
      @side_panel_filter_head = 'Filter By Topic'
      @topics = Content.where(:id=>@contents.map(&:topic_id).uniq,:chapter_id=>@filter_id)
      @topics.each do |t|
        @side_panel_filter << [t.name,'?topic='+t.id.to_s]
      end
      @chapter_data = Content.find(@filter_id)
      @side_panel_browse_head = 'Browse By Chapter'
      @chapters = Content.where(:id=>@contents.map(&:chapter_id).uniq,:subject_id=>@chapter_data.subject.id)
      @chapters.each do |c|
        if c.id != @filter_id
          @side_panel_browse << [c.name,'?chapter='+c.id.to_s]
        else
          @side_panel_browse << [c.name,'']
        end
      end
    when "topic"
      @side_panel_filter_head = 'Filter By Sub Topic'
      @sub_topics = Content.where(:id=>@contents.map(&:sub_topic_id).uniq,:topic_id=>@filter_id)
      @sub_topics.each do |st|
        @side_panel_filter << [st.name,'?sub_topic='+st.id.to_s]
      end
      @topic_data = Content.find(@filter_id)
      @side_panel_browse_head = 'Browse By Topic'
      @topics = Content.where(:id=>@contents.map(&:topic_id).uniq,:chapter_id=>@topic_data.chapter.id)
      @topics.each do |t|
        if t.id != @filter_id
          @side_panel_browse << [t.name,'?topic='+t.id.to_s]
        else
          @side_panel_browse << [t.name,'']
        end
      end
    when "sub_topic"
      @sub_topic_data = Content.find(@filter_id)
      @side_panel_browse_head = 'Browse By Sub Topic'
      @sub_topics = Content.where(:id=>@contents.map(&:sub_topic_id).uniq,:topic_id=>@sub_topic_data.topic.id)
      @sub_topics.each do |st|
        if st.id != @filter_id
          @side_panel_browse << [st.name,'?sub_topic='+st.id.to_s]
        else
          @side_panel_browse << [st.name,'']
        end
      end
    end

    # End of code for making the side panels of the store

    if @filter_id > 0
      @filter_data = Content.find(@filter_id)
    end

    ## The code for handling the bread crumbs
    @breadcrumbs = []
    if @filter_depth > 0
      @breadcrumbs << ['Home','/','']
      if @filter_depth == 1
        @breadcrumbs << [@filter_data.name,'',' > ']
      end
      if @filter_depth > 1
        @breadcrumbs << [@filter_data.board.name,'?board='+@filter_data.board.id.to_s,' > ']
        if @filter_depth == 2
          @breadcrumbs << [@filter_data.name,'',' > ']
        end
        if @filter_depth > 2
          @breadcrumbs << [@filter_data.content_year.name,'?year='+@filter_data.content_year.id.to_s,' > ']
          if @filter_depth == 3
            @breadcrumbs << [@filter_data.name,'',' > ']
          end
          if @filter_depth > 3
            @breadcrumbs << [@filter_data.subject.name,'?subject='+@filter_data.subject.id.to_s,' > ']
            if @filter_depth == 4
              @breadcrumbs << [@filter_data.name,'',' > ']
            end
            if @filter_depth > 4
              @breadcrumbs << [@filter_data.chapter.name,'?chapter='+@filter_data.chapter.id.to_s,' > ']
              if @filter_depth == 5
                @breadcrumbs << [@filter_data.name,'',' > ']
              end
              if @filter_depth > 5
                @breadcrumbs << [@filter_data.topic.name,'?topic='+@filter_data.topic.id.to_s,' > ']
                if @filter_depth == 6
                  @breadcrumbs << [@filter_data.name,'',' > ']
                end
              end
            end
          end
        end
      end
    end
    ## End of code for handling the bread crumbs
  end

end
