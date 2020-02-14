class CdnConfigsController < ApplicationController
  skip_before_filter :authenticate_user!, :only=>[:send_cdn_logs,:send_cdn_metadata,:send_cdn_cache_status,:get_cdn_config,:ping]
  load_and_authorize_resource only: [:new, :create, :index, :show, :edit, :update, :destroy]
  # GET /cdn_configs
  # GET /cdn_configs.json
  def index
    @cdn_configs = CdnConfig.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @cdn_configs }
    end
  end

  # GET /cdn_configs/1
  # GET /cdn_configs/1.json
  def show
    @cdn_config = CdnConfig.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @cdn_config }
    end
  end

  # GET /cdn_configs/new
  # GET /cdn_configs/new.json
  def new
    @cdn_config = CdnConfig.new
    @cdn_config.cdn_centers.build
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @cdn_config }
    end
  end

  # GET /cdn_configs/1/edit
  def edit
    @cdn_config = CdnConfig.find(params[:id])
  end

  # POST /cdn_configs
  # POST /cdn_configs.json
  def create
    @cdn_config = CdnConfig.new(params[:cdn_config])

    respond_to do |format|
      if @cdn_config.save
        @user = @cdn_config.cdn_user
        @response = {user:@user.edutorid,:password=>@user.plain_password,:deviceid=>@user.devices.last.deviceid}
        format.html { redirect_to @cdn_config, notice: 'Cdn config was successfully created.' }
        format.json { render json: @response }
      else
        format.html { render action: "new" }
        format.json { render json: @cdn_config.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /cdn_configs/1
  # PUT /cdn_configs/1.json
  def update
    @cdn_config = CdnConfig.find(params[:id])

    respond_to do |format|
      if @cdn_config.update_attributes(params[:cdn_config])
        format.html { redirect_to @cdn_config, notice: 'Cdn config was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @cdn_config.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cdn_configs/1
  # DELETE /cdn_configs/1.json
  def destroy
    @cdn_config = CdnConfig.find(params[:id])
    @cdn_config.destroy

    respond_to do |format|
      format.html { redirect_to cdn_configs_url }
      format.json { head :ok }
    end
  end

  #Saving the cdn logs from the server
  def send_cdn_logs
    authorize! :manage, CdnLog
    @log_data =  JSON.load(params[:logdata])
    CdnLog.create(@log_data)
    respond_to do |format|
      format.json{ head :ok }
    end
  end

  # browsing cdb logs
  def cdn_logs
    authorize! :manage, CdnLog
    where = ""
    if params[:cdnid].present?
      where = where + "CdnId = '#{params[:cdnid]}'"
    end

    if params[:userid].present?
      if where == ""
        where = "UserId = '#{params[:userid]}'"
      else
        where = where + "and UserID = '#{params[:userid]}'"
      end
    end

    if params[:report].present?
      if where == ""
        where = "ReportType = '#{params[:report]}'"
      else
        where = where + "and ReportType = '#{params[:report]}'"
      end
    end

    if where == ""
      @logs = CdnLog.order('id desc').limit(25).page(params[:page])
    else
      @logs = CdnLog.where(where).page(params[:page])
    end
  end

  def show_cdn_log
    authorize! :manage, CdnLog
    @log = CdnLog.find(params[:id])
  end

  def ping
    authorize! :manage, CdnPing
    device_id = params[:device_id]

     @cdn_ping = CdnPing.find_last_by_device_id(device_id)
   if @cdn_ping.nil?
     @cdn_ping = CdnPing.create({device_id:device_id})
   else
     @cdn_ping.last_ping = @cdn_ping.updated_at
     @cdn_ping.save
   end  
    respond_to do |format|
      format.json{render :json=>@cdn_ping.updated_at}
    end
  end

   # Saving the cdn metadata from the server
  def send_cdn_metadata
    authorize! :manage, CdnMetadata
    @meta_data =  JSON.load(params[:metadata])
    CdnMetadata.create(@meta_data)
    @cdn = CdnMetadata.find_last_by_cdnid(@meta_data['cdnid'])
    if @cdn.nil?
      CdnMetadata.create(@meta_data)
    else
      @cdn.update_attributes(@meta_data)
    end
    respond_to do |format|
      format.json{ head :ok }
    end
  end

 # Saving the cdn cache info from the server
  def send_cdn_cache_status
    authorize! :manage, CdnCacheStatus
    @cachestatus =  JSON.load(params[:cachestatus])
    @cdn = CdnCacheStatus.find_last_by_cdnid(@cachestatus['cdnid'])
    if @cdn.nil?
      CdnCacheStatus.create(@cachestatus)
    else
      @cdn.update_attributes(@cachestatus)
    end
    respond_to do |format|
      format.json{ head :ok }
    end
  end

  def cdn_ping_status
    authorize! :manage, CdnPing
    if params[:device_id].present?
     @cdn_pings = CdnPing.where(:device_id=>params[:device_id]).page(params[:page])
    else
     @cdn_pings = CdnPing.page(params[:page])
    end  
  end  

  def cdn_cache_status
    authorize! :manage, CdnCacheStatus
    if params[:cdnid].present?
     @cdn_cache_status = CdnCacheStatus.where(:cdnid=>params[:cdnid]).page(params[:page])
    else
     @cdn_cache_status = CdnCacheStatus.page(params[:page])
    end  
  end  

  def cdn_metadata
    authorize! :manage, CdnMetadata
    if params[:cdnid].present?
     @cdn_metadata = CdnMetadata.where(:cdnid=>params[:cdnid]).page(params[:page])
    else
     @cdn_metadata = CdnMetadata.page(params[:page])
    end  
  end  
 
 def get_cdn_config
   data = []
   @user = User.find(params[:id])
   @cdn = @user.center.cdn_configs
   if @cdn.empty?
     data = []
   else
     @cdn.each do |cdn|
     data <<  [{:ipaddress=>@cdn.last.cdn_ip,:port=>'80',:priority=>1,:statusUrl=>"",:availablityUrl=>"status",:protocol=>"http"}]
    end
   end
   respond_to do |format|
      format.json {render json: data.flatten}
    end
 end

 def cdn_centers
   @cdn_config = CdnConfig.find(params[:id])
   @cdn_user = @cdn_config.cdn_user
   @centers = @cdn_config.centers
   respond_to do |format|
     format.html
   end
 end
 def cdn_center_books
  @center = Center.find(params[:center_id])
  @cdn_user = CdnUser.find(params[:cdn_user])
  @books_list = @center.get_book_ids.map{|p| Ibook.find_by_ibook_id(p)}
  @cdn_books = CdnContentInfo.where(user_id: @cdn_user.id).map(&:book_id).compact
 end
 def cdn_books_upload
   # get_ibooks = Ibook.where(id:12)
   get_ibooks = Ibook.where(id: params[:book_ids])
   book_ids = []
   asset_guids = []
  unless get_ibooks.empty?
    get_ibooks.each do |book|
      begin
        book_url = book.encrypted_content.path
        content_info = CdnBooksInfo.new
        content_info.user_id = params[:cdn_user]
        content_info.book_id = book.id
        content_info.guid = book.ibook_id
        content_info.md_hash = CdnContentInfo.calculate_md5_hash(book_url)
        content_info.upload_status = false
        if content_info.save
          book_ids << book.id
        end
      rescue
        next
      end
    asset_ids = book.toc_items.map{|p| p.target_guid}.compact
    # asset_ids = UserAsset.last(3).map(&:guid) + QuizTargetedGroup.last(3).map(&:guid)
      assets = UserAsset.where(:guid=>asset_ids)
      qtgs = QuizTargetedGroup.where(:guid=>asset_ids)
      assets.each do |asset|
        unless CdnContentInfo.find_by_guid(asset.guid).present?
          begin
            asset_url = Rails.root.to_s + "/public" + asset.get_attachment_enc_path rescue ""
            content_info = CdnAssetsInfo.new
            content_info.user_id = params[:cdn_user]
            content_info.asset_id = asset.id
            content_info.guid = asset.guid
            content_info.md_hash = CdnContentInfo.calculate_md5_hash(asset_url)
            content_info.upload_status = false
            if content_info.save
              asset_guids << asset.guid
            end
          rescue
            next
          end
        end
      end
      qtgs.each do |qtg|
      unless CdnContentInfo.find_by_guid(qtg.guid).present?
        begin
          qtg_url = Rails.root.to_s + "/public" + qtg.message_quiz_targeted_group.message.assets.first.attachment.url
          content_info = CdnAssetsInfo.new
          content_info.user_id = params[:cdn_user]
          content_info.asset_id = qtg.id
          content_info.guid = qtg.guid
          content_info.md_hash = CdnContentInfo.calculate_md5_hash(qtg_url)
          content_info.upload_status = false
          if content_info.save
            asset_guids << qtg.guid
          end
        rescue
          next
        end
      end
      end
    end
    render json: {success: true, book_ids: book_ids, asset_ids: asset_guids}
  end

 end


end
