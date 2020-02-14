class UserAssetsController < ApplicationController

  skip_before_filter :authenticate_user!, :only => [:download_asset, :download_asset_by_guid]
  before_filter :load_tags, :only => [:single_asset_upload_interface, :package_details, :my_assets_interface, :edit_asset_catalog]
  # GET /user_assets
  # GET /user_assets.json
  authorize_resource
  def index
    if params.has_key? :p
      @p = params[:p]
    else
      @p = 0
    end
    @asset_id = params[:asset_id]
    @controller = self.class.to_s
    @user_asset = UserAsset.new
    @ibooks = current_user.ignitor_books
    @user_assets = UserAsset.where(user_id: current_user.id).order("created_at DESC")
    @content_deliveries = ContentDelivery.where(user_id: current_user.id).order("created_at DESC")
    if current_user.is? "ET"
      @class_type =[["Assessment","assessment-practice-tests"], ["Audio", "audio"], ["Video", "video-lecture"], ["Web Link", "weblink"], ["Apk", "thirdparty"],["Ign","animation"]]
    else
      @class_type =[["Animation","animation"],["Textbook","text-book"],["Assessment","assessment-practice-tests"],["Concept Map", "concept-map"], ["Audio", "audio"], ["Video", "video-lecture"], ["Web Link", "weblink"], ["Apk", "thirdparty"],["Ign","animation"]]
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @user_asset }
    end
  end

  # GET /user_assets/1
  # GET /user_assets/1.json
  def show
    @user_asset = UserAsset.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user_asset }
    end
  end

  # GET /user_assets/new
  # GET /user_assets/new.json
  def new
    @user_asset = UserAsset.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user_assets }
    end
  end

  # GET /user_assets/1/edit
  def edit
    @user_asset = UserAsset.find(params[:id])
  end

  # POST /user_assets
  # POST /user_assets.json
  def create
    @user_asset = UserAsset.new(params[:user_asset])
    @user_asset.user_id = current_user.id
    @commit = params[:commit]
    @user_asset.guid = generate_guid

    respond_to do |format|
      # if @controller == "UserAssetsController"
      if @user_asset.save
        if @user_asset.asset_type != "weblink"
          @user_asset.extract_uploaded_zip
          @launch_file_status = set_launch_file
          @user_asset.encrypt_and_zip unless @launch_file_status
        end
        # if !@launch_file_status
        #   @user_asset.delay.encrypt_files
        # end

        format.html { redirect_to "/user_assets", notice: 'User asset was successfully created.' }
        format.json { render json: @user_asset, status: :created, location: @user_asset }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @user_asset.errors, status: :unprocessable_entity }
        format.js { render 'errors'}
      end

    end
  end
  # PUT /user_assets/1
  # PUT /user_assets/1.json

  def update
    @user_asset = UserAsset.find(params[:id])
    respond_to do |format|
      if @user_asset.update_attributes(params[:user_asset])
        @user_asset.encrypt_and_zip
        format.html { redirect_to user_assets_path, notice: 'User asset was successfully updated.' }
        format.json { head :ok }
        format.js
      else
        format.html { render action: "edit" }
        format.json { render json: @user_asset.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_assets/1
  # DELETE /user_assets/1.json
  def destroy
    @user_asset = UserAsset.find(params[:id])
    @user_asset.destroy

    respond_to do |format|
      format.html { redirect_to user_assets_url }
      format.json { head :ok }
    end
  end

  def get_publisher_assets
    @user = current_user
    qtg = QuizTargetedGroup.where("guid is not null").where(:published_by=>current_user.id).order("published_on desc")
    videos = UserAsset.where("guid is not null").where(user_id: @user.id).where(asset_type: "mp4").order("updated_at desc")
    pdfs = UserAsset.where("guid is not null").where(user_id: @user.id).where(asset_type: "pdf").order("updated_at desc")
    weblinks = UserAsset.where("guid is not null").where(user_id: @user.id).where(asset_type: "weblink").order("updated_at desc")
    audios = UserAsset.where("guid is not null").where(user_id:@user.id).where(asset_type:"mp3").order("updated_at desc")
    apks = UserAsset.where("guid is not null").where(user_id:@user.id).where(asset_type:"thirdparty").order("updated_at desc")
    igns = UserAsset.where("guid is not null").where(user_id:@user.id).where(asset_type:"animation").order("updated_at desc")
    html_assets = UserAsset.where("guid is not null").where(user_id: @user.id).where(asset_type: "html5").order("updated_at desc") + LearningActivity.where("guid is not null").where(user_id: @user.id).order("updated_at desc")


    @quizzes =[]
    qtg.each do |quiz|
      q = Hash.new
      q[:name]=quiz.quiz.name
      q[:guid]=quiz.guid
      q[:asset_type]="assessment"
      @quizzes << q
    end

    @videos =[]
    videos.each do |video|
      v = Hash.new
      v[:name]=video.asset_name
      v[:guid]=video.guid
      v[:asset_type]="video"
      @videos << v
    end

    @pdfs =[]
    pdfs.each do |pdf|
      p = Hash.new
      p[:name]=pdf.asset_name
      p[:guid]=pdf.guid
      p[:asset_type]="pdf"
      @pdfs << p
    end
    @weblinks =[]
    weblinks.each do |link|
      w = Hash.new
      w[:name]=link.asset_name
      w[:guid]=link.guid
      w[:asset_type]="weblink"
      @weblinks << w
    end
    @audios = []
    audios.each do |audio|
      a = Hash.new
      a[:name]=audio.asset_name
      a[:guid]=audio.guid
      a[:asset_type]="audio"
      @audios << a
    end
    @apks = []
    apks.each do |apk|
      ap = Hash.new
      ap[:name]=apk.asset_name
      ap[:guid]=apk.guid
      ap[:asset_type]="thirdparty"
      @apks << ap
    end
    @igns = []
    igns.each do |ig|
      ap = Hash.new
      ap[:name]=ig.asset_name
      ap[:guid]=ig.guid
      ap[:asset_type]="animation"
      @igns << ap
    end
    @html5_assets = []
    html_assets.each do |html_asset|
      h = Hash.new
      h[:name] = html_asset.asset_name rescue html_asset.name
      h[:guid] = html_asset.guid
      h[:asset_type] = "html5"
      @html5_assets << h
    end

    # @quizzes = [{name:qtg[0].quiz.name,guid:qtg[0].guid,asset_type:"assessment"},{name:qtg[1].quiz.name,guid:qtg[1].guid,asset_type:"assessment"},{name:qtg[2].quiz.name,guid:qtg[2].guid,asset_type:"assessment"}] #QuizTargetedGroup.last(4)

    # @videos = [{name:videos[0].asset_name,guid:videos[0].guid,asset_type:"videocipher"},{name:videos[1].asset_name,guid:videos[1].guid,asset_type:"videocipher"},{name:videos[2].asset_name,guid:videos[2].guid,asset_type:"videocipher"}] #UserAsset.where(asset_type:"videocipher").last(4)
    # @pdfs = [{name:pdfs[0].asset_name,guid:pdfs[0].guid,asset_type:"pdf"},{name:pdfs[1].asset_name,guid:pdfs[1].guid,asset_type:"pdf"},{name:pdfs[2].asset_name,guid:pdfs[2].guid,asset_type:"pdf"}] #UserAsset.where(asset_type:"pdf").last(4)
  end

  #builk upload mp4 video files with csv file having meta data
  def bulk_upload_assets_interface
    user_id = current_user.id
    if !(UsersTagsDb.find_by_user_id(user_id).present?)
      logger.info "#{'*'*30}No Tags Db Assigned."
      redirect_to :back, notice: "No Tags DB is assigned."
      return
    end
    db = UsersTagsDb.find_by_user_id(current_user.id).tags_db
    logger.info "Unavailable Meta Tags Session: #{session[:unavailable_meta_tags]}"
    flash[:notice] = params[:notice] if params[:notice].present?
    @vdo_upload = VdoUpload.new
  end


  def bulk_upload_assets
    @vdo_upload = VdoUpload.new(params[:vdo_upload])
    @vdo_upload.user_id = current_user.id
    logger.info "#{'*'*20}#{File.extname(@vdo_upload.attachment.path)}#{'*'*30}"
    if File.extname(@vdo_upload.attachment.path)!=".zip"
      # redirect_to "/user_assets/bulk_upload_assets_interface", notice: "Upload a valid zip file"
      url = "/user_assets/bulk_upload_assets_interface"
      message = "Upload a valid zip file."
      # return {url: "/user_assets/bulk_upload_assets_interface", notice: "Upload a valid zip file"}
    else
      @vdo_upload.save
      @vdo_upload.extract_package
      package_details = @vdo_upload.verify_package
      logger.info "#{'*'*20}#{package_details}#{'*'*30}"
      if package_details[:status] == "Valid Package"
        logger.info "#{'*'*20}#{package_details[:message]}#{'*'*30}"
        @vdo_upload.update_package_status
        url = "/user_assets/package_details/#{@vdo_upload.id}"
        message = package_details[:message]
        # redirect_to "/user_assets/package_details/#{@vdo_upload.id}", notice: package_details[:message]
      else
        url = "/user_assets/bulk_upload_assets_interface"
        message = package_details[:message]
        # redirect_to "/user_assets/bulk_upload_assets_interface", notice: package_details[:message]
      end
    end
    render json: {url: url, message: message}
  end

  def package_details
    flash[:notice] = params[:notice] if params[:notice].present?
    @vdo_upload = VdoUpload.find(params[:package_id])
    @package_files = Array.new
    user_id = current_user.id
    db = UsersTagsDb.find_by_user_id(user_id).tags_db
    # m = MetaTag.where(tags_db_id: db.id)
    # @class_tags = m.where("class_id is not null").map(&:class_tag).uniq
    # @subject_tags = m.where("subject_id is not null").map(&:subject_tag).uniq
    @class_tags = Tag.where(name: 'academic_class', tags_db_id: db.id, standard: true)
    @subject_tags = Tag.where(name: 'subject', tags_db_id: db.id, standard: true)
    @concept_tags = Tag.where(name: 'concept_name', tags_db_id: db.id, standard: true)
    if @vdo_upload.package_status == "All Approved"
      redirect_to "/user_assets/bulk_upload_assets_interface", notice: 'All files in this package have been approved.'
    else
      assets_list = @vdo_upload.get_assets_list
      assets_list.each do |a|
        @package_files << @vdo_upload.get_asset_info(a)
      end
    end
  end

  def update_package_details
    @vdo_upload = VdoUpload.find(params[:package_id])
    asset_name = params[:asset_name]
    ac_id = params[:tags][:academic_class_id]
    su_id = params[:tags][:subject_id]
    co_id = params[:tags][:concept_id]
    tags = Hash.new
    tags["academic_class"] = Tag.find(ac_id).value
    tags["subject"] = Tag.find(su_id).value
    tags["concept"] = Tag.find(co_id).value
    @vdo_upload.update_csv(asset_name, tags)
    redirect_to "/user_assets/package_details/#{@vdo_upload.id}"
  end

  def approve_asset
    @vdo_upload = VdoUpload.find(params[:package_id])
    asset_name = params[:asset_name]
    @vdo_upload.approve_asset(asset_name, request.base_url)
    redirect_to "/user_assets/package_details/#{@vdo_upload.id}"
  end

  def single_asset_upload_interface
    flash[:notice] = params[:notice] if params[:notice].present?
    logger.info request.host
    #to upload a single pdf or a video
    user_id = current_user.id
    if !(UsersTagsDb.find_by_user_id(user_id).present?)
      logger.info "#{'*'*30}No Tags Db Assigned."
      redirect_to :back, notice: "No Tags DB is assigned."
      return
    end

  end

  def create_single_asset
    @user_asset = UserAsset.new(params[:user_asset])
    @launch_file_setter = false
    if params[:weblink_box].present?
      weblink_box =  "on"
      @user_asset.asset_type = "weblink"
    else
      weblink_box = "off"
    end
    @user_asset.user_id = current_user.id
    @user_asset.guid = generate_guid
    url = "/user_assets/single_asset_upload_interface"
    if weblink_box == "off"
      attachment_ext = File.extname(@user_asset.attachment.path)
      puts "request url: #{request.base_url} "
      if attachment_ext == '.mp4' && @user_asset.save
        @user_asset.update_attribute("asset_type", "mp4")
        @user_asset.extract_uploaded_zip
        @launch_file_setter = set_launch_file
        @user_asset.encrypt_and_zip
        @user_asset.tag_mappings.create(tag_id: params[:tag][:class_id])
        @user_asset.tag_mappings.create(tag_id: params[:tag][:subject_id])
        @user_asset.tag_mappings.create(tag_id: params[:tag][:concept_id])
        # @user_asset.upload_attachment_to_vdo_cipher(request.base_url)
        message = 'Video was successfully created.'
        # format.html { redirect_to "/user_assets/single_asset_upload_interface", notice: 'Video was successfully created.' }
      elsif attachment_ext == '.apk' && @user_asset.save
        @user_asset.update_attribute("asset_type", "thirdparty")
        @user_asset.extract_uploaded_zip
        @launch_file_setter = set_launch_file
        @user_asset.encrypt_and_zip
        @user_asset.tag_mappings.create(tag_id: params[:tag][:class_id])
        @user_asset.tag_mappings.create(tag_id: params[:tag][:subject_id])
        @user_asset.tag_mappings.create(tag_id: params[:tag][:concept_id])
        message = 'Apk was successfully created.'
      elsif attachment_ext == '.mp3' && @user_asset.save
        @user_asset.update_attribute("asset_type", "mp3")
        @user_asset.extract_uploaded_zip
        @launch_file_setter = set_launch_file
        @user_asset.encrypt_and_zip
        @user_asset.tag_mappings.create(tag_id: params[:tag][:class_id])
        @user_asset.tag_mappings.create(tag_id: params[:tag][:subject_id])
        @user_asset.tag_mappings.create(tag_id: params[:tag][:concept_id])
        message = 'Audio was successfully created.'
      elsif attachment_ext == '.pdf' && @user_asset.save
        @user_asset.update_attribute("asset_type", "pdf")
        @user_asset.extract_uploaded_zip
        @launch_file_setter = set_launch_file
        @user_asset.encrypt_and_zip
        @user_asset.tag_mappings.create(tag_id: params[:tag][:class_id])
        @user_asset.tag_mappings.create(tag_id: params[:tag][:subject_id])
        @user_asset.tag_mappings.create(tag_id: params[:tag][:concept_id])
        message = 'PDF was successfully created.'
        # format.html { redirect_to "/user_assets/single_asset_upload_interface", notice: 'PDF was successfully created.' }
      elsif attachment_ext == '.zip' && @user_asset.save
        asset_type = @user_asset.determine_asset_type
        @user_asset.update_attribute("asset_type", asset_type)
        @user_asset.extract_uploaded_zip
        @launch_file_setter = set_launch_file
        @user_asset.encrypt_and_zip
        @user_asset.tag_mappings.create(tag_id: params[:tag][:class_id])
        @user_asset.tag_mappings.create(tag_id: params[:tag][:subject_id])
        @user_asset.tag_mappings.create(tag_id: params[:tag][:concept_id])
        message = 'zip_file was successfully uploaded.'
      elsif (attachment_ext != ".mp3" || attachment_ext != '.pdf' || attachment_ext != '.mp4' || attachment_ext != '.apk' || attachment_ext != '.zip')
        message = 'Please upload a valid file.'
        # format.html { redirect_to "/user_assets/single_asset_upload_interface", notice: 'Please upload a valid file.'}
      else
        message = 'User asset was not successfully created.'
        # format.html { redirect_to "/user_assets/single_asset_upload_interface", notice: 'User asset was not successfully created.'}
      end
    elsif weblink_box == "on" && @user_asset.save
      @user_asset.tag_mappings.create(tag_id: params[:tag][:class_id])
      @user_asset.tag_mappings.create(tag_id: params[:tag][:subject_id])
      @user_asset.tag_mappings.create(tag_id: params[:tag][:concept_id])
      message = "Weblink successfully uploaded"
    end
    render json: {url: url, message: message, launch_file: @launch_file_setter, asset_id:@user_asset.id}
  end

  def launch_file_setter
    @user_asset = UserAsset.find(params[:id])
     path = @user_asset.attachment.path.split("/")
    path.pop
    @files = Dir.entries(path.join("/") + "_extract").select{|file| File.extname(file) != ""}
    # if params[:user_asset].present?
    # @launcher = params[:user_asset][:launch_file]
    # @user_asset.update_attribute(:launch_file,@launcher)
    # end
    # respond_to do |format|
    #   format.html {redirect_to "/user_assets/single_asset_upload_interface" ,:notice => "Zip_file_uploaded_successsfully"}
    # end
  end
  def launcher
    @user_asset = UserAsset.find(params[:id])
    @launcher = params[:user_asset][:launch_file]
    @user_asset.update_attribute(:launch_file,@launcher)
    respond_to do |format|
      format.html {redirect_to "/user_assets/single_asset_upload_interface"}
    end

  end

  def download_asset
    @user_asset = UserAsset.find(params[:id])
    unextracted_path = @user_asset.attachment.path
    x = unextracted_path.split("/")
    file_name = x.pop
    actual_path = x.join("/")+"_extract/"+file_name
    # path = "/home/krishna/Desktop/EdutorDev/edutor-dev/public/system/user_assets/attachments/14_extract/video.mp4"
    send_file @user_asset.get_attachment_extract_path ,:type=>"application/octet-stream",:x_sendfile=>true
  end

  def download_asset_by_guid
    result = {}
    guid = params[:guid]
    user_assets = UserAsset.where(guid: guid)
    qtgs = QuizTargetedGroup.where(guid: guid)
    if user_assets.present?
      user_asset = UserAsset.find_by_guid(guid)
      # path = "/home/krishna/Desktop/EdutorDev/edutor-dev/public/system/user_assets/attachments/14_extract/video.mp4"
      #send_file user_asset.get_attachment_extract_path ,:type=>"application/octet-stream",:x_sendfile=>true
      if user_asset.asset_type == "pdf"
        result = result.merge({:type =>"pdf",:url=>user_asset.get_attachment_enc_path})
      else
        result = result.merge({:type =>"vdocipherVideo",:url=>user_asset.vdocipher_id})
      end
    elsif qtgs.present?
      qtg = qtgs.first
      file_path = qtg.message_quiz_targeted_group.message.assets.first.attachment.path
      #send_file file_path ,:type=>"application/octet-stream",:x_sendfile=>true
      result = result.merge({:type =>"assessment",:url=>qtg.message_quiz_targeted_group.message.assets.first.attachment.url})
    end
    respond_to do |format|
      format.json  { render json: result }
    end
  end

  def show_asset_details
    @user_asset = UserAsset.find(params[:id])
    @asset_details = @user_asset.get_vdo_cipher_details
    respond_to do |format|
      format.html
      format.json  { render json: @asset_details }
    end
  end

  def my_assets
    user_assets = UserAsset.where(user_id: current_user.id).order("created_at desc")
    tag_mappings = TagMapping.where(taggable_id: user_assets.map(&:id), taggable_type: "UserAsset")
    page_no = params[:page_no].to_i
    assets_per_page = 5
    #find by ids
    if params[:asset_type].present? && params[:asset_type] !='html5'
      user_assets = user_assets.where(asset_type: params[:asset_type])
      # user_assets = user_assets.where(asset_type: params[:asset_type]) + LearningActivity.where("guid is not null").where(user_id: current_user.id).order("updated_at desc") if params[:asset_type] == "html5"
    end
    if params[:guid].present?
      guids = params[:guid].split(';').map{|g| g.lstrip.rstrip}
      user_assets_guid = user_assets.where(guid: guids)
    elsif params[:name].present?
      #find by name
      names = params[:name].split(';').map{|n| n.lstrip.rstrip}
      user_assets_name = user_assets.where(asset_name: names)
    else
      #find by tags
      user_assets_class = user_assets.where(id: tag_mappings.where(tag_id: params[:academic_class]).map(&:taggable_id)) if params[:academic_class].present?
      user_assets_subject = user_assets.where(id: tag_mappings.where(tag_id: params[:subject]).map(&:taggable_id)) if params[:subject].present?
      user_assets_concept_name = user_assets.where(id: tag_mappings.where(tag_id: params[:concept_name]).map(&:taggable_id)) if params[:concept_name].present?
    end
    if params[:asset_type].present? && params[:asset_type] =='html5'
      #user_assets = user_assets.where(asset_type: params[:asset_type])
      user_assets = user_assets.select{|u| u.asset_type == 'html5'}
      user_assets += LearningActivity.where("guid is not null").where(user_id: current_user.id).order("updated_at desc")
    end
    final_user_assets = user_assets
    final_user_assets = final_user_assets & user_assets_guid if params[:guid].present?
    final_user_assets = final_user_assets & user_assets_name if params[:name].present?
    final_user_assets = final_user_assets & user_assets_class if params[:academic_class].present?
    final_user_assets = final_user_assets & user_assets_subject if params[:subject].present?
    final_user_assets = final_user_assets & user_assets_concept_name if params[:concept_name].present?
    videos = []

    start_index = (page_no-1) * assets_per_page
    end_index = page_no * assets_per_page
    final_user_assets[start_index .. end_index-1].each do |u|
      video = Hash.new
      video["name"] = u.asset_name rescue u.name
      video["academic_class"] = u.academic_class.join(",") rescue ""
      video["subject"] = u.subject.join(",") rescue ""
      video["concept_name"] = u.concept_name.join(",") rescue ""

      video["duration"] = ""
      video["size"] = ""
      video["resolution"] = ""
      video["guid"] = u.guid

      video["uploaded_date"] = Time.at(u.created_at).strftime("%d/%m/%Y")
      begin
        if u.asset_type == "pdf"
          video["status"] = "Ready"
          video["no_of_views"] = 0
          video["asset_type"] = "PDF"
        elsif u.asset_type == "mp4"
          video_details = u.get_vdo_cipher_details
          video["status"] = video_details["statusText"].titleize
          video["no_of_views"] = video_details["viewCount"]
          video["asset_type"] = "Video"
        elsif u.asset_type == "mp3"
          video["status"] = "Ready"
          video["no_of_views"] = 0
          video["asset_type"] = "Audio"
        elsif u.asset_type == "thirdparty"
          video["status"] = "Ready"
          video["no_of_views"] = 0
          video["asset_type"] = "Apk"
        elsif u.asset_type == "animation"
          video["status"] = "Ready"
          video["no_of_views"] = 0
          video["asset_type"] = "Ign"
        elsif u.asset_type == "html5"
          video["status"] = "Ready"
          video["no_of_views"] = 0
          video["asset_type"] = "Html5 Asset"
        elsif u.asset_type == "weblink"
          video["status"] = "Ready"
          video["no_of_views"] = 0
          video["asset_type"] = "weblink"
        else
          video["status"] = "Ready"
          video["no_of_views"] = 0
          video["asset_type"] = "others"
        end
      rescue  NoMethodError
        video["status"] = "Ready"
        video["no_of_views"] = 0
        video["asset_type"] = "Html5 Asset(learning Activity)"
      end

      video["no_of_downloads"] = ""
      video["total_count"] = final_user_assets.count
      videos << video
    end
    respond_to do |format|
      format.json { render json: videos}
    end
  end

  def my_assets_interface
    user_id = current_user.id
    if !(UsersTagsDb.find_by_user_id(user_id).present?)
      logger.info "#{'*'*30}No Tags Db Assigned."
      redirect_to :back, notice: "No Tags DB is assigned."
      return
    end
    @asset_types = [["Video", "mp4"], ["PDF", "pdf"],["HTML5","html5"],["Audio","mp3"],["Links","weblink"],["Apks","thirdparty"], ["Igns", "animation"]]
  end

  def my_assets_csv
    file_path = Rails.root.to_s + "/tmp/my_assets_#{Time.now.to_i}.csv"
    assets = current_user.user_assets.includes(:tags)
    FasterCSV.open(file_path, "w") do |csv|
      csv << ['Name', 'Asset-Type', 'GUID', 'Class', 'Subject', 'Concept Name', 'Created At', 'Updated At']

      assets.each do |a|
        csv << [a.asset_name, a.asset_type, a.guid, a.tags.where(name: 'academic_class').map(&:value).join(' '), a.tags.where(name: 'subject').map(&:value).join(' '), a.tags.where(name: 'concept_name').map(&:value).join(' '), Time.at(a.created_at).strftime("%d-%b-%Y"), Time.at(a.updated_at).strftime("%d-%b-%Y")]
      end
    end
    send_file file_path, x_sendfile:true
  end

  def edit_asset_catalog
    user_id = current_user.id
    db = UsersTagsDb.find_by_user_id(current_user.id).tags_db
    m = MetaTag.where(tags_db_id: db.id)
    asset_info = Hash.new
    asset = UserAsset.find_by_guid(params[:guid])
    asset_info["name"] = asset.asset_name
    asset_info["class_tags"] = @class_tags
    asset_info["subject_tags"] = @subject_tags
    asset_info["concept_tags"] = @concept_tags
    respond_to do |format|
      format.json { render json: asset_info}
    end
  end

  def update_asset_catalog
    user_id = current_user.id
    status = "failed"
    begin
      user_asset = UserAsset.find_by_guid(params[:guid])
      tag_mappings = user_asset.tag_mappings
      tag_mappings.destroy_all
      user_asset.tag_mappings.create(tag_id: params[:academic_class])
      user_asset.tag_mappings.create(tag_id: params[:subject])
      user_asset.tag_mappings.create(tag_id: params[:concept_name])
      user_asset.asset_name = params[:name]
      user_asset.save
      status = "successfull"
    rescue Exception => e
      logger.info "Exception while updating asset #{e}"
    end
    respond_to do |format|
      format.json { render json: {status: status}}
    end
  end

  def package_template
    send_file Rails.root.to_s+"/public/templates/asset_package_template.csv",:type=>"application/octet-stream",:x_sendfile=>true
  end

  def load_tags
    user_id = current_user.id
    # db = UsersTagsDb.find_by_user_id(user_id).tags_db
    db = current_user.tags_db
    if db.present?
      tags = current_user.my_tags
      @class_tags = tags['class_tags']
      @subject_tags = tags['subject_tags']
      @concept_tags = tags['concept_tags']
    else
      redirect_to :back, notice: "No Tags DB is assigned."
    end
  rescue ActionController::RedirectBackError
    redirect_to root_path, notice: "No Tags DB is assigned."
  end

  private

  def set_launch_file
    if @user_asset.asset_type != "weblink"
      path = @user_asset.attachment.path.split("/")
      path.pop
      @files = Dir.entries(path.join("/") + "_extract").select{|file| File.extname(file) != ""}
    else
      @files = [nil]
    end
    if @files.size > 1
      true
    else
      @user_asset.update_attribute(:launch_file,@files.first)
      false
    end
  end

  def generate_guid
    SecureRandom.uuid
  end

end
