class WorkSpaceAppsController < ApplicationController
  authorize_resource #:only=>[:edit, :index, :new, :show]
  # GET /work_space_apps
  # GET /work_space_apps.json
  def index
    @work_space_apps = WorkSpaceApp.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @work_space_apps }
    end
  end

  # GET /work_space_apps/1
  # GET /work_space_apps/1.json
  def show
    @work_space_app = WorkSpaceApp.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @work_space_app }
    end
  end

  # GET /work_space_apps/new
  # GET /work_space_apps/new.json
  def new
    @work_space_app = WorkSpaceApp.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @work_space_app }
    end
  end

  # GET /work_space_apps/1/edit
  def edit
    @work_space_app = WorkSpaceApp.find(params[:id])
  end

  # POST /work_space_apps
  # POST /work_space_apps.json
  def create
    if params[:apk].present?
      apk_file_name =  params[:apk].original_filename
      if File.extname(apk_file_name) == '.apk'
        directory = "#{Rails.root.to_s}/apk_files"
        path = File.join(directory, apk_file_name)
        File.open(path, "wb") { |f| f.write(params[:apk].read) }
        #@apk = AndroidApk.analyze(path)
        #logger.info"===#{@apk.package_name}"
        apk = Android::Apk.new(path)
        @name = Nokogiri::XML(apk.manifest.to_xml).xpath('manifest').attr('package').value
      end
    else
      render action: "new"
      flash[:error] = "File can't be blank."
    end
    user_ids = params[:work_space_app][:multiple_recipient_ids].split(',')
    unless user_ids.empty?
      user_ids.each do |i|
        @work_space_app = WorkSpaceApp.new(params[:work_space_app])
        @work_space_app.package_name = @name
        @work_space_app.apk_name = apk_file_name
        @work_space_app.user_id =  i
        @work_space_app.save
        @user = User.find(i)
        @user.devices.where(:device_type=>'Primary').each do |device|
          @device_message = DeviceMessage.new
          @asset = @device_message.assets.build
          @asset.attachment =  File.open(path,'rb')
          @device_message.deviceid= device.deviceid
          @device_message.message_type = 'Control Message'
          @device_message.subject = 'APK'
          @device_message.sender_id = current_user.id
          @device_message.label = params[:work_space_app][:app_location]
          @device_message.save
          command ="mosquitto_pub -p 3333 -t #{@user.edutorid} -m 16  -i Edeployer -q 2 -h 173.255.254.228"
          system(command)
        end
      end
    end
    respond_to do |format|
      if
      format.html { redirect_to @work_space_app, notice: 'Work space app was successfully created.' }
        format.json { render json: @work_space_app, status: :created, location: @work_space_app }
      else
        format.html { render action: "new" }
        format.json { render json: @work_space_app.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /work_space_apps/1
  # PUT /work_space_apps/1.json
  def update
    @work_space_app = WorkSpaceApp.find(params[:id])

    respond_to do |format|
      if @work_space_app.update_attributes(params[:work_space_app])
        format.html { redirect_to @work_space_app, notice: 'Work space app was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @work_space_app.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /work_space_apps/1
  # DELETE /work_space_apps/1.json
  def destroy
    @work_space_app = WorkSpaceApp.find(params[:id])
    @work_space_app.destroy

    respond_to do |format|
      format.html { redirect_to work_space_apps_url }
      format.json { head :ok }
    end
  end
end
