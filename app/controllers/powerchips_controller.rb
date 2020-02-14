class PowerchipsController < ApplicationController
  authorize_resource :only=>[:edit, :edutor_jobs, :edutor_latest_jobs, :index, :masterchip_details, :masterchip_list, :new, :show, :show_materchip, :user_device_powechip]

  skip_before_filter :authenticate_user!, :except=>[:powerchip_unregister, :powerchip_search]

  # GET /powerchips
  # GET /powerchips.json
  def index
    @powerchips = Powerchip.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @powerchips }
    end
  end

  # GET /powerchips/1
  # GET /powerchips/1.json
  def show
    @powerchip = Powerchip.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @powerchip }
    end
  end

  # GET /powerchips/new
  # GET /powerchips/new.json
  def new
    @powerchip = Powerchip.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @powerchip }
    end
  end

  # GET /powerchips/1/edit
  def edit
    @powerchip = Powerchip.find(params[:id])
  end

  # POST /powerchips
  # POST /powerchips.json
  def create

    device_info = JSON.load(params[:device_info])
    chip_fs_info =JSON.load(params[:chip_fs_info])
    chip_info = JSON.load(params[:chip_info])

    @admin_device = DeviceProperty.where(:mac_id=>device_info['mac_id'])
    if @admin_device.empty?

      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>"Invalid admin device"}}
      end
      logger.info"=========admin"
      return

    end


=begin
    @slot = Slot.where(:cid=>chip_info['cid'])

    if !@slot.empty?
      @slot = @slot.last
      @job = Job.where(:jobid=>@slot.jobid)
      if @job.empty?
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Invalid JobID"}}
        end
        return
      else
        @job = @job.last
        if @job.jobname.split('/').last.split('.') == "Write"
          @pearson_chip = PearsonChip.create(:cid=>@slot.cid,:serial_number=>@slot.serialnum,:capacity=>@slot.capacity,:job_name=>@job.jobname.split('/').last,:host_name=>@job.hostname,:operator=>@job.operator)
        else
          respond_to do |format|
            format.json { render json: {:chip_accepted=>false,:error=>"Invalid Job Name"}}
          end
          return
        end

      end
    end
=end

    @issue_id = params[:masterchip_id]
    @master_chip = Masterchip.find_by_issue_id(@issue_id)

    if @master_chip.nil?
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>"Invalid masterchip id"} }
      end
      logger.info"=========master"
      return

    end

    @master_chip_fs = ChipFsInfo.find(@master_chip.chip_fs_info_id)
    @master_chip_fs = @master_chip_fs.to_json
    @master_chip_fs = JSON.load(@master_chip_fs)
    @master_chip_fs.delete('created_at')
    @master_chip_fs.delete('updated_at')
    @master_chip_fs.delete('id')
    # if !chip_fs_info_are_equal(@master_chip_fs,chip_fs_info)
    #   respond_to do |format|
    #     format.json { render json: {:chip_accepted=>false,:error=>"chip_fs_info doesn't match"} }
    #   end
    #   logger.info"=========chipfs"
    #   return
    # end

    chip_type = chip_info['type']
    chip_info.delete('type')
    chip_info['chip_type'] = chip_type

    m_chip_info = chip_info
    m_chip_info['issue_id'] = params[:masterchip_id]
    m_chip_info.delete('masterchip_id')
    @master_aspchip = Masterchip.where(m_chip_info)

    if !@master_aspchip.empty?
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>"This is Masterchip"} }
      end
      return
    end


    chip_info.delete('issue_id')
    chip_info['masterchip_id'] = params[:masterchip_id]

    logger.info"===================#{chip_info}"
    @pchip_exist = Powerchip.where(chip_info)
    logger.info"===================#{@pchip_exist}"
    @response = {}
    if @pchip_exist.empty?
      logger.info"===========innn========#{@pchip_exist}"
      @pcid =  Powerchip.find_by_cid(chip_info['cid'])
      @pserial = Powerchip.find_by_serial(chip_info['serial'])

      @collision = ''
      if !@pcid.nil?
        @collision = "collison with cid #{@pcid.id}"
      end

      if !@pserial.nil?
        @collision += "collison with serial#{@pserial.id}"
      end
      logger.info "==========Collusion #{@collision} "

      if @collision.length !=0
        @response = {:chip_accepted=>false,:error=>@collision}
        record_chip_errors(@response)
        respond_to do |format|
          format.json { render json: @response }
        end
        return
      else
        logger.info"======increate===pchip"
        @powerchip = Powerchip.new(chip_info)
        respond_to do |format|
          if @powerchip.save
            if @job.nil?
              format.json { render json: {:chip_accepted=>true }  }
            else
              format.json { render json: {:chip_accepted=>true,:keys=>"/powerchips/get_key/#{@powerchip.id}" }  }
            end
          else
            if @powerchip.errors.any?
              record_chip_errors(@powerchip.errors)
            end
            format.json { render json: {:chip_accepted=>false,:error=>@powerchip.errors} }
          end
        end
      end
    else
      logger.info"=========powerchip existed accepted"
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true} }
      end
    end
  end

  # PUT /powerchips/1
  # PUT /powerchips/1.json
  def update
    @powerchip = Powerchip.find(params[:id])

    respond_to do |format|
      if @powerchip.update_attributes(params[:powerchip])
        format.html { redirect_to @powerchip, notice: 'Powerchip was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @powerchip.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /powerchips/1
  # DELETE /powerchips/1.json
  def destroy
    @powerchip = Powerchip.find(params[:id])
    @powerchip.destroy

    respond_to do |format|
      format.html { redirect_to powerchips_url }
      format.json { head :ok }
    end
  end

  def admin_device_register
    device_info = JSON.load(params[:device_info])
    chip_fs_info =JSON.load(params[:chip_fs_info])
    chip_info = JSON.load(params[:chip_info])
    @device_propoerty = DeviceProperty.new(device_info)
    respond_to do |format|
      if @device_propoerty.save
        @response = {:device_accepted=>true}
        format.json { render json: @response }
      else
        if @device_propoerty.errors.any?
          record_chip_errors(@device_propoerty.errors)
        end
        @response = {:device_accepted=>false}
        format.json { render json: @response }
      end
    end


  end

  def masterchip_register
    device_info = JSON.load(params[:device_info])
    chip_fs_info =JSON.load(params[:chip_fs_info])
    chip_info = JSON.load(params[:chip_info])
    chip_info['chip_type'] = chip_info['type']
    chip_info.delete('type')
    @admin_device = DeviceProperty.where(device_info)
    if @admin_device.empty?
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>'unauthorized'} }
      end
      return
    end
    ActiveRecord::Base.transaction do
      @chip_info = ChipFsInfo.create(chip_fs_info)
      chip_info['chip_fs_info_id']= @chip_info.id
      @masterchip = Masterchip.new(chip_info)
      if @masterchip.save
        respond_to do |format|
          format.json { render json: {:chip_accepted=>true,:masterchip_id=>@masterchip.issue_id} }
        end
        return
      else
        if @masterchip.errors.any?
          record_chip_errors(@masterchip.errors)
        end
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>'serial or cid already exist'} }
        end
        return
      end
    end


  end

  def powerchip_validate
    users = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
    device = params[:device_id]
    device_info = JSON.load(params[:device_info])
    logger.info"============#{device}=======#{users}"
    chip_fis_info = JSON.load(params[:chip_info])

    logger.info "============#{chip_fis_info}"

    #N010613301522


    begin
      if device == "N010613301522"
        respond_to do |format|
          format.json { render json:  {:chip_accepted=>true} }
        end
        return
      end
    rescue Exception=>e
      logger.info "Exception ..............#{e.message}"
    end




    begin
      if chip_fis_info['cid'] == "1b534d3030303030101df8f0d400d3c9"
        respond_to do |format|
          format.json { render json:  {:chip_accepted=>true} }
        end
        return
      end
    rescue Exception=>e
      logger.info "Exception ..............#{e.message}"
    end

    @device = Device.find_by_deviceid(device)
    @device_property_exist  = DeviceProperty.find_by_imei_and_mac_id_and_android_id(device_info['imei'],device_info['mac_id'],device_info['android_id'])

    if @device_property_exist.nil?
      @device_property = DeviceProperty.create(device_info)
    else
      @device_property = @device_property_exist
    end



    if @device.nil?
      respond_to do |format|
        format.json {render json: {:chip_accepted=>false,:error=>'Invalid Deviceid'}}
      end
      return
    end

    @user = User.find_by_edutorid(users[0])
    if !@user && !@user.valid_password?(params[:password])
      respond_to do |format|
        format.json {render json: {:chip_accepted=>false,:error=>'Invalid User or Password'}}
      end
      return
    end

    @response = {}
    device_info = JSON.load(params[:device_info])
    chip_fs_info =JSON.load(params[:chip_fs_info])
    chip_info = JSON.load(params[:chip_info])
    @issue_id = params[:masterchip_id]
    @powerchip = Powerchip.where('lower(substr(cid,1,30))=?',"#{chip_info['cid'][0..29]}".downcase).last #Powerchip.find_by_cid(chip_info['cid'])
=begin
    if !@powerchip.nil? and @powerchip.masterchip_id.nil?
      @powerchip.masterchip_id = @issue_id
      @powerchip.update_attribute(:masterchip_id, @issue_id)
    end


    if !@issue_id.nil?
      if @powerchip.nil?
        respond_to do |format|
          format.json { render json:  {:chip_accepted=>false,:error=>"Invalid powerchip"} }
        end
        return
      end
      @master_chip = Masterchip.find_by_issue_id(@issue_id)
    else
      #@master_chip = Masterchip.find_by_issue_id(@issue_id)
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>"No masterchip id"} }
      end
      return
    end
=end
    if @issue_id.nil?
      if @powerchip.nil?
        respond_to do |format|
          format.json { render json:  {:chip_accepted=>false,:error=>"Invalid powerchip"} }
        end
        return
      end
      @master_chip = Masterchip.find_by_issue_id(@powerchip.masterchip_id)
    else
      @master_chip = Masterchip.find_by_issue_id(@issue_id)
    end


    if @master_chip.nil?
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>"Invalid masterchip id"} }
      end
      return
    end
    @key = nil
    if !@master_chip.masterchip_details.nil?
      @key = @master_chip.masterchip_details.masterchip_key
    end

    @master_chip_fs = ChipFsInfo.find(@master_chip.chip_fs_info_id)
    @master_chip_fs = @master_chip_fs.to_json
    @master_chip_fs = JSON.load(@master_chip_fs)
    @master_chip_fs.delete('created_at')
    @master_chip_fs.delete('updated_at')
    @master_chip_fs.delete('id')
    # if !chip_fs_info_are_equal(@master_chip_fs,chip_fs_info)
    #   @response = @response.merge({:chip_accepted=>true,:k => @key,:chip_fs_error=>"chip_fs_info doesn't match"})
    # end

    if @master_chip.masterchip_details.nil?
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>'masterchip details not updated'} }
      end
      return
    end


    #11910
    if @user.section.boards.first.id != @master_chip.masterchip_details.course.to_i
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>"course doesn't match"} }
      end
      return
    end


    @already_asigned = UserDevicePowerchip.find_by_powerchip_id(@powerchip.id)
    if !@already_asigned.nil?
      if @already_asigned.user_id == @user.id
        respond_to do |format|
          format.json { render json: {:chip_accepted=>true,:k => @key,:error=>"Powerchip already assigned}"} }
        end
        return
      else
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Powerchip already assigned to #{@already_asigned.user.edutorid}"} }
        end
        return
      end
    end


    @powerchip_exist = UserDevicePowerchip.where(:user_id=>@user.id,:device_id=>@device.id,:powerchip_id=>@powerchip.id,:device_property_id=>@device_property.id)


    if @powerchip_exist.empty?
      UserDevicePowerchip.create(:user_id=>@user.id,:powerchip_id=>@powerchip.id,:device_id=>@device.id,:device_property_id=>@device_property.id)
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true,:k => @key} }
      end
    else
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true,:k => @key,:error=>'Powerchip already assigned'} }
      end
    end

  end

  def chip_fs_info_are_equal(master_fs,fs)
    ['available_blocks','block_count','block_size','free_blocks'].each do |k|
      unless master_fs[k].to_s == fs[k].to_s
        return false
      end
    end
    true
  end

  def masterchip_list
    @masterchips = Masterchip.order('id desc').page(params[:page])
  end

  def masterchip_delete
    @masterchip = Masterchip.find(params[:id])
    @masterchip.destroy
    redirect_to masterchip_list_path
  end

  def show_masterchip
    @masterchip = Masterchip.find(params[:id])
  end

  def masterchip_details
    @masterchip = Masterchip.find(params[:id])
    @details = MasterchipDetails.new(:masterchip_id=>@masterchip.id)
    if @masterchip.asset.nil?
      @asset =  @masterchip.build_asset
    else
      @asset = @masterchip.asset
    end
    #@asset =  @masterchip.build_asset
    @details = MasterchipDetails.new
    @details_key = @details.build_asset
  end

  def save_masterchip_details
    @masterchip = Masterchip.find(params[:id])
    @details = MasterchipDetails.new(params[:masterchip_details])
    @details.masterchip_id = @masterchip.id
    masterchip_asset = false
    if params[:masterchip]
      file_name =  params[:masterchip][:asset].original_filename
      folder =  Rails.root.to_s+"/public/attachments/enc_keys/"+@masterchip.id.to_s
      FileUtils.mkdir_p folder
      path = File.join(folder, file_name)
      File.open(path,  "w+b", 0644) do |f|
        f.write(params[:masterchip][:asset].read)
      end
      @asset = Asset.new
      @asset.attachment = params[:masterchip][:asset]
      @asset.archive_type = 'Masterchip'
      @asset.archive_id =  @masterchip.id
      @asset.save
      masterchip_asset = true
    end
    respond_to do |format|
      if  masterchip_asset
        if @details.save
          format.html { redirect_to show_masterchip_path(@masterchip), notice: 'Masterchip details successfully created.' }
          format.json { render json: @masterchip, status: :created, location: @content_year }
        end
      else
        format.html { render action: "masterchip_details" }
        format.json { render json: @masterchip.errors, status: :unprocessable_entity }
      end
    end
  end




  def assign_pwerchip
    users = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
    @user = User.find_by_edutorid(users[0])
    if !@user && !@user.valid_password?(params[:password])
      respond_to do |format|
        format.json {render json: {:chip_accepted=>false,:error=>'Invalid User or Password'}}
      end
      return
    end

    device_info = JSON.load(params[:device_info])


    chip_fs_info =JSON.load(params[:chip_fs_info])
    chip_info = JSON.load(params[:chip_info])
    @issue_id = params[:masterchip_id]
    @master_chip = Masterchip.find_by_issue_id(@issue_id)
    @powerchip = Powerchip.find_by_cid(chip_info['cid'])
    @user = User.find_by_edutorid(params[:edutorid])

    @issue_id = params[:masterchip_id]
    if @issue_id.nil?
      if @powerchip.nil?
        respond_to do |format|
          format.json { render json:  {:chip_accepted=>false,:error=>"Invalid powerchip"} }
        end
        return
      end
      @master_chip = Masterchip.find_by_issue_id(@powerchip.masterchip_id)
    else
      @master_chip = Masterchip.find_by_issue_id(@issue_id)
    end


    if @master_chip.nil?
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>"Invalid masterchip id"} }
      end
      return
    end

    @already_asigned = UserDevicePowerchip.where(:powerchip_id=>@powerchip.id)
    if !@already_asigned.empty?
      respond_to do |format|
        format.json { render json: {:powerchip_assign=>false,:error=>"Powerchip already assigned to #{@already_asigned.first.user.edutor.id}"} }
      end
      return
    end

    if @user.devices.empty?
      @powerchip_exist = UserDevicePowerchip.where(:user_id=>@user.id,:powerchip_id=>@powerchip.id)
    else
      @powerchip_exist = UserDevicePowerchip.where(:user_id=>@user.id,:device_id=>@user.devices.first.id,:powerchip_id=>@powerchip.id)
    end


    if @powerchip_exist.empty?
      UserDevicePowerchip.create(:user_id=>@user.id,:powerchip_id=>@powerchip.id,:device_id=>@user.devices.first.id)
      respond_to do |format|
        format.json { render json: {:powerchip_assign=>true} }
      end
    else
      respond_to do |format|
        format.json { render json: {:powerchip_assign=>true,:error=>'Powerchip already assigned'} }
      end
    end

  end


  def user_device_powerchip_list
    @list = UserDevicePowerchip.page(params[:page])
  end

  def delink_user_powerchip
    @chip = UserDevicePowerchip.find(params[:id])
    @chip.destroy
    redirect_to user_powerchip_list_path
  end


  def record_chip_errors(errors)
    file = File.new(Rails.root.to_s+"/public/chip_error.txt", "a+")
    File.open(file,  "a", 0644) do |f|
      f.puts(errors.inspect.to_s)
    end
  end



  def replicate_chip
    @masterchip = Masterchip.find(params[:id])
    @chip_fs_info = ChipFsInfo.find(@masterchip.chip_fs_info_id)
    @chip_fs_info.update_attributes(:available_blocks=>@chip_fs_info.available_blocks.to_i-1,:free_blocks=>@chip_fs_info.free_blocks.to_i-1,:is_replicate=>true)
    redirect_to masterchip_list_path
  end


  def user_device_info_update
    logger.info"===========#{params}"
    #user_device_info_update?mac_id="6C:F3:73:25:EE:0C"&&serialno="c1607305c0f4f21"&&serialnumber="RF2D30E22BY"
    #={"mac_id"=>"\"6C:F3:73:25:EE:0C\"?serialno=\"c1607305c0f4f21\"?serialnumber=\"RF2D30E22BY", "controller"=>"powerchips", "action"=>"user_device_info_update"}
    logger.info"===========#{params['mac_id']}=====#{params['serialno']}"
    device_property = DeviceProperty.find_by_mac_id_and_serial(params['mac_id'],params['serialno'])
    logger.info"===#{device_property}"
    if !device_property.nil?
      device_property.update_attribute(:serialnumber=>params['serialnumber'])
    end
    render :text=>'updated'
  end

  def powerchip_remove
    users = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
    device = params[:device_id]
    device_info = JSON.load(params[:device_info])
    chip_fis_info = JSON.load(params[:chip_info])
    chip_info = JSON.load(params[:chip_info])

    @device = Device.find_by_deviceid(device)
    @device_property_exist  = DeviceProperty.find_by_imei_and_mac_id(device_info['imei'],device_info['mac_id'])

    if @device_property_exist.nil?
      respond_to do |format|
        format.json {render json: {:chip_removed=>false,:error=>'Invalid Admin Device'}}
      end
      return
    end


    #if @device.nil?
    #  respond_to do |format|
    #    format.json {render json: {:chip_removed=>false,:error=>'Invalid Deviceid'}}
    #  end
    #  return
    #end

    #@user = User.find_by_edutorid(users[0])
    #if !@user && !@user.valid_password?(params[:password])
    #  respond_to do |format|
    #    format.json {render json: {:chip_removed=>false,:error=>'Invalid User or Password'}}
    #  end
    #  return
    #end

    @masterchip  = Masterchip.find_by_cid_and_serial(chip_info['cid'],chip_info['serial'])

    if @masterchip
      respond_to do |format|
        format.json { render json:  {:chip_removed=>false,:error=>"This is Masterchip"} }
      end
      return
    end

    @response = {}


#    @powerchip = Powerchip.find_by_cid(chip_info['cid'])
    @powerchip = Powerchip.where('lower(substr(cid,1,30))=?',"#{chip_info['cid'][0..29]}".downcase).last

    if !@powerchip.nil?
      new_cid = @powerchip.cid+Time.now.to_i.to_s+"DELETED"
      new_serial = @powerchip.serial+Time.now.to_i.to_s+"DELETED"
      @powerchip.serial = new_serial
      @powerchip.cid = new_cid
      respond_to do |format|
#        if @powerchip.save
	if @powerchip.destroy
          format.json { render json:  {:chip_removed=>true} }
        else
          logger.info"====not saved==#{@powerchip.errors}"
          format.json { render json:  {:chip_removed=>false} }
        end
      end
    else
      respond_to do |format|
        format.json { render json:  {:chip_removed=>false,:error=>"Invalid powerchip"} }
      end
    end

    #@issue_id = params[:masterchip_id]
    #if @issue_id.nil?
    #  if @powerchip.nil?
    #    respond_to do |format|
    #      format.json { render json:  {:chip_removed=>false,:error=>"Invalid powerchip"} }
    #    end
    #    return
    #  end
    #  @master_chip = Masterchip.find_by_issue_id(@powerchip.masterchip_id)
    #else
    #  @master_chip = Masterchip.find_by_issue_id(@issue_id)
    #end


    #if @master_chip.nil?
    #  respond_to do |format|
    #    format.json { render json:  {:chip_removed=>false,:error=>"Invalid masterchip id"} }
    #  end
    #  return
    #end

    #@master_chip_fs = ChipFsInfo.find(@master_chip.chip_fs_info_id)
    #@master_chip_fs = @master_chip_fs.to_json
    #@master_chip_fs = JSON.load(@master_chip_fs)
    #@master_chip_fs.delete('created_at')
    #@master_chip_fs.delete('updated_at')
    #@master_chip_fs.delete('id')
    #if !chip_fs_info_are_equal(@master_chip_fs,chip_fs_info)
    #  @response = @response.merge({:chip_removed=>true,:chip_fs_error=>"chip_fs_info doesn't match"})
    #end

    #if @master_chip.masterchip_details.nil?
    #  respond_to do |format|
    #    format.json { render json:  {:chip_removed=>false,:error=>'masterchip details not updated'} }
    #  end
    #  return
    #end


    #11910
    #if @user.section.boards.first.id != @master_chip.masterchip_details.course.to_i
    #  respond_to do |format|
    #    format.json { render json:  {:chip_removed=>false,:error=>"course doesn't match"} }
    #  end
    #  return
    #end


    #@already_asigned = UserDevicePowerchip.find_by_powerchip_id(@powerchip.id)
    #if !@already_asigned.nil?
    #  if @already_asigned.user_id == @user.id
    #    respond_to do |format|
    #      format.json { render json: {:chip_removed=>true,:error=>"Powerchip already assigned}"} }
    #    end
    #    return
    #  else
    #    respond_to do |format|
    #      format.json { render json: {:chip_removed=>false,:error=>"Powerchip already assigned to #{@already_asigned.user.edutorid}"} }
    #    end
    #    return
    #  end
    #end


    #@powerchip_exist = UserDevicePowerchip.where(:user_id=>@user.id,:device_id=>@device.id,:powerchip_id=>@powerchip.id,:device_property_id=>@device_property.id)
    #
    #
    #if @powerchip_exist.empty?
    #  UserDevicePowerchip.create(:user_id=>@user.id,:powerchip_id=>@powerchip.id,:device_id=>@device.id,:device_property_id=>@device_property.id)
    #  respond_to do |format|
    #    format.json { render json: {:chip_removed=>true} }
    #  end
    #else
    #  respond_to do |format|
    #    format.json { render json: {:chip_removed=>true,:error=>'Powerchip already assigned'} }
    #  end
    #end

  end


  def pearson_chip_register
    device_info = JSON.load(params[:device_info])
    chip_fs_info =JSON.load(params[:chip_fs_info])
    chip_info = JSON.load(params[:chip_info])

    @slot = Slot.where(:cid=>chip_info['cid'])

    if @slot.empty?
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>"Invalid CID Not Found"}}
      end
      return
    else
      @slot = @slot.last
      @job = Job.where(:jobid=>@slot.jobid)
      if @job.empty?
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Invalid JobID"}}
        end
        return
      else
        @pearson_chip = PearsonChip.create(:cid=>@slot.cid,:serial_number=>@slot.serialnum,:capacity=>@slot.capacity,:job_name=>@job.jobname.split('/').last,:host_name=>@job.hostname,:operator=>@job.operator)
      end

    end


    @admin_device = DeviceProperty.where(device_info)
    if @admin_device.empty?

      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>"Invalid admin device"}}
      end
      return
    end

    @issue_id = params[:masterchip_id]
    @master_chip = Masterchip.find_by_issue_id(@issue_id)

    if @master_chip.nil?
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>"Invalid masterchip id"} }
      end
      return
    end

    @master_chip_fs = ChipFsInfo.find(@master_chip.chip_fs_info_id)
    @master_chip_fs = @master_chip_fs.to_json
    @master_chip_fs = JSON.load(@master_chip_fs)
    @master_chip_fs.delete('created_at')
    @master_chip_fs.delete('updated_at')
    @master_chip_fs.delete('id')
    # if !chip_fs_info_are_equal(@master_chip_fs,chip_fs_info)
    #   respond_to do |format|
    #     format.json { render json: {:chip_accepted=>false,:error=>"chip_fs_info doesn't match"} }
    #   end
    #   return
    # end

    chip_type = chip_info['type']
    chip_info.delete('type')
    chip_info['chip_type'] = chip_type

    m_chip_info = chip_info
    m_chip_info['issue_id'] = params[:masterchip_id]
    m_chip_info.delete('masterchip_id')
    @master_aspchip = Masterchip.where(m_chip_info)

    if !@master_aspchip.empty?
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>"This is Masterchip"} }
      end
      return
    end


    chip_info.delete('issue_id')
    chip_info['masterchip_id'] = params[:masterchip_id]

    @pchip_exist = Powerchip.where(chip_info)
    @response = {}
    if @pchip_exist.empty?
      @pcid =  Powerchip.find_by_cid(chip_info['cid'])
      @pserial = Powerchip.find_by_serial(chip_info['serial'])

      @collision = ''
      if !@pcid.nil?
        @collision = "collison with cid #{@pcid.id}"
      end

      if !@pserial.nil?
        @collision += "collison with serial#{@pserial.id}"
      end
      if @collision.length !=0
        @response = {:chip_accepted=>false,:error=>@collision}
        record_chip_errors(@response)
        respond_to do |format|
          format.json { render json: @response }
        end
        return
      else
        @powerchip = Powerchip.new(chip_info)
        respond_to do |format|
          if @powerchip.save
            format.json { render json: {:chip_accepted=>true} }
          else
            if @powerchip.errors.any?
              record_chip_errors(@powerchip.errors)
            end
            format.json { render json: {:chip_accepted=>false,:error=>@powerchip.errors} }
          end
        end
      end
    else
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true} }
      end
    end
  end


  def get_keys
    @powerchip = Powerchip.find(params[:id])
    @chip = Masterchip.find(@powerchip.masterchip_id)
    @asset = Masterchip.asset.attachment.path
    send_file @asset,:disposition=>'inline',:type=>'application/txt'
  end

  def powerchip_validate_pearson
    users = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
    device = params[:device_id]
    device_info = JSON.load(params[:device_info])
    chip_fis_info = JSON.load(params[:chip_info])


    @device = Device.find_by_deviceid(device)

    @device_property_exist  = DeviceProperty.find_by_imei_and_mac_id_and_android_id(device_info['imei'],device_info['mac_id'],device_info['android_id'])

    if @device_property_exist.nil?
      @device_property = DeviceProperty.create(device_info)
    else
      @device_property = @device_property_exist
    end



    if @device.nil?
      respond_to do |format|
        format.json {render json: {:chip_accepted=>false,:error=>'Invalid Deviceid'}}
      end
      return
    end

    @user = User.find_by_edutorid(users[0])
    if !@user && !@user.valid_password?(params[:password])
      respond_to do |format|
        format.json {render json: {:chip_accepted=>false,:error=>'Invalid User or Password'}}
      end
      return
    end

    @response = {}
    device_info = JSON.load(params[:device_info])
    chip_fs_info =JSON.load(params[:chip_fs_info])
    chip_info = JSON.load(params[:chip_info])

    @powerchip = Powerchip.find_by_cid_and_serial(chip_info['cid'],chip_info['serial'])


    if( ['0353445355303247800f56974e00b600','1b534d3030303030102e648cea00a400','1501004d414732474103c70bcd7f21a1'].include? chip_info['cid'])
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>true,:error=>"Powerchip Registered"} }
      end
      return
    end


    @issue_id = params[:masterchip_id]
    if @issue_id.nil?
      if @powerchip.nil?
        respond_to do |format|
          format.json { render json:  {:chip_accepted=>false,:error=>"Invalid powerchip"} }
        end
        return
      end
      @master_chip = Masterchip.find_by_issue_id(@powerchip.masterchip_id)
    else
      @master_chip = Masterchip.find_by_issue_id(@issue_id)
    end


    if @master_chip.nil?
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>"Invalid masterchip id"} }
      end
      return
    end

    @master_chip_fs = ChipFsInfo.find(@master_chip.chip_fs_info_id)
    @master_chip_fs = @master_chip_fs.to_json
    @master_chip_fs = JSON.load(@master_chip_fs)
    @master_chip_fs.delete('created_at')
    @master_chip_fs.delete('updated_at')
    @master_chip_fs.delete('id')


    # if !chip_fs_info_are_equal(@master_chip_fs,chip_fs_info)
    #   @response = @response.merge({:chip_accepted=>true,:chip_fs_error=>"chip_fs_info doesn't match"})
    # end


    if @master_chip.masterchip_details.nil?
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>'masterchip details not updated'} }
      end
      return
    end




    @already_asigned = UserDevicePowerchip.find_by_powerchip_id(@powerchip.id)
    if !@already_asigned.nil?
      if @already_asigned.user_id == @user.id
        #user_devices = UserDevicePowerchip.where(:powerchip_id=>@powerchip.id,:user_id=>@user.id)
        #if @already_asigned.device_id != @device.id and user_devices.map(&:device_id).uniq.count < 3
        #  UserDevicePowerchip.where(:user_id=>@user.id,:device_id=>@device.id,:powerchip_id=>@powerchip.id,:device_property_id=>@device_property.id)
        #  respond_to do |format|
        #    format.json { render json: {:chip_accepted=>false,:error=>"Maximum devices}"} }
        #  end
        #  return
        #end
        respond_to do |format|
          format.json { render json: {:chip_accepted=>true,:error=>"Powerchip already assigned}"} }
        end
        return
      else
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Powerchip already assigned to #{@already_asigned.user.edutorid}"} }
        end
        return
      end
    end


    @powerchip_exist = UserDevicePowerchip.where(:user_id=>@user.id,:device_id=>@device.id,:powerchip_id=>@powerchip.id,:device_property_id=>@device_property.id)


    if @powerchip_exist.empty?
      UserDevicePowerchip.create(:user_id=>@user.id,:powerchip_id=>@powerchip.id,:device_id=>@device.id,:device_property_id=>@device_property.id)
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true} }
      end
    else
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true,:error=>'Powerchip already assigned'} }
      end
    end

  end


  def powerchip_validate_pearson_production
    users = ActionController::HttpAuthentication::Basic::user_name_and_password(request)

    @user = User.find_by_edutorid(users[0])

    if @user.center_id == 27019
      logger.info "===IN Rivonia Center"
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true} }
      end
      return
    end

    device = params[:device_id]
    device_info = JSON.load(params[:device_info])
    chip_fis_info = JSON.load(params[:chip_info])

#    logger.info"======powerchip-user==========#{users}=============#{chip_info['cid']}"
    @device = Device.find_by_deviceid(device)
    @device_property_exist  = DeviceProperty.find_by_imei_and_mac_id_and_android_id(device_info['imei'],device_info['mac_id'],device_info['android_id'])

    if @device_property_exist.nil?
      @device_property = DeviceProperty.create(device_info)
    else
      @device_property = @device_property_exist
    end



    if @device.nil?
      respond_to do |format|
        format.json {render json: {:chip_accepted=>false,:error=>'Invalid Deviceid'}}
      end
      return
    end



    @user = User.find_by_edutorid(users[0])
    if !@user && !@user.valid_password?(params[:password])
      respond_to do |format|
        format.json {render json: {:chip_accepted=>false,:error=>'Invalid User or Password'}}
      end
      return
    end

    @response = {}
    device_info = JSON.load(params[:device_info])
    chip_fs_info =JSON.load(params[:chip_fs_info])
    chip_info = JSON.load(params[:chip_info])
    logger.info"======powerchip-user==========#{users}=============#{chip_info['cid']}"
# @slot = Slot.where(:cid=>chip_info['cid'])
    @slots =  Slot.where("lower(substr(cid,1,30))=?","#{chip_info['cid'][0..29]}".downcase).order('jobid desc')
# @slot = Slot.where('lower(cid)=?',chip_info['cid'].downcase)
#@slot =  Slot.where("lower(substr(cid,1,30))=?","#{chip_info['cid'][0..29]}".downcase)
#logger.info"=================#{@slot.inspect}"
    if !@slots.empty?
      #@slot = @slot.last
      #@job = Job.where(:jobid=>@slot.jobid)
=begin
      @slots.each do |j|
        @new_job = Job.where("jobid = #{j.jobid} and jobname like '%WriteProtect.mlj'")
        if !@new_job.empty?
          @slot = j
          break
        end
      end
      @job = @new_job
      if @job.empty?
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Invalid JobID"}}
        end
        return
      else
        @job = @job.last

       # if @job.jobname.split('/').last == "WriteProtect.mlj"
        #  if @slot.message != 'Passed'
            #@pearson_chip = PearsonChip.create(:cid=>@slot.cid,:serial_number=>@slot.serialnum,:capacity=>@slot.capacity,:job_name=>@job.jobname.split('/').last,:host_name=>@job.hostname,:operator=>@job.operator)
            #else
         #   respond_to do |format|
          #    format.json { render json: {:chip_accepted=>false,:error=>"Invalid Slot"}}
         #   end
         #   return
        #  end
       # else
       #   respond_to do |format|
       #     format.json { render json: {:chip_accepted=>false,:error=>"Invalid Powerchip"}}
       #   end
       #   return
       # end

      end
=end
    else
      file = File.new(Rails.root.to_s+"/public/pearson_invalid_cids.txt", "a+")
      File.open(file,  "a", 0644) do |f|
        f.puts("#{chip_info['cid']}--#{@user.rollno}--#{@user.edutorid}")
      end
     # respond_to do |format|
      #  format.json { render json: {:chip_accepted=>false,:error=>"Powerchip entry not found"}}
     # end
     # return
    end



#    @powerchip = Powerchip.find_by_cid(chip_info['cid'])
@powerchip = Powerchip.where('lower(substr(cid,1,30))=?',"#{chip_info['cid'][0..29]}".downcase).last

    if @powerchip.nil?
      #@powerchip = Powerchip.create(chip_info)
      @powerchip = Powerchip.new(chip_info)
      if !@powerchip.save
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Unable to process powerchip"}}
        end
        return
      end
    end
=begin
    @issue_id = params[:masterchip_id]
    if @issue_id.nil?
      if @powerchip.nil?
        respond_to do |format|
          format.json { render json:  {:chip_accepted=>false,:error=>"Invalid powerchip"} }
        end
        return
      end
      @master_chip = Masterchip.find_by_issue_id(@powerchip.masterchip_id)
    else
      @master_chip = Masterchip.find_by_issue_id(@issue_id)
    end


    if @master_chip.nil?
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>"Invalid masterchip id"} }
      end
      return
    end

    @master_chip_fs = ChipFsInfo.find(@master_chip.chip_fs_info_id)
    @master_chip_fs = @master_chip_fs.to_json
    @master_chip_fs = JSON.load(@master_chip_fs)
    @master_chip_fs.delete('created_at')
    @master_chip_fs.delete('updated_at')
    @master_chip_fs.delete('id')


    if @master_chip.masterchip_details.nil?
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>'masterchip details not updated'} }
      end
      return
    end
=end


    @already_asigned = UserDevicePowerchip.find_by_powerchip_id(@powerchip.id)
    if !@already_asigned.nil?
      if @already_asigned.user_id == @user.id
        respond_to do |format|
          format.json { render json: {:chip_accepted=>true,:error=>"Powerchip already assigned}"} }
        end
        return
      else
       file = File.new(Rails.root.to_s+"/public/pearson_reassign_cids.txt", "a+")
      File.open(file,  "a", 0644) do |f|
        f.puts("#{chip_info['cid']}--#{@user.rollno}--#{@user.edutorid}--old-user--#{@already_asigned.user.edutorid}")
      end
      @already_asigned.destroy
       # respond_to do |format|
       #   format.json { render json: {:chip_accepted=>false,:error=>"Powerchip already assigned to #{@already_asigned.user.edutorid}"} }
       # end
       # return
      end
    end


    @powerchip_exist = UserDevicePowerchip.where(:user_id=>@user.id,:device_id=>@device.id,:powerchip_id=>@powerchip.id,:device_property_id=>@device_property.id)


    if @powerchip_exist.empty?
      UserDevicePowerchip.create(:user_id=>@user.id,:powerchip_id=>@powerchip.id,:device_id=>@device.id,:device_property_id=>@device_property.id)
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true} }
      end
    else
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true,:error=>'Powerchip already assigned'} }
      end
    end

  end

  #pearson SD card job search
  def pearson_job_search

  end

  #Pearson SD card jobs list view
  def jobs
    if params[:start_date] and params[:end_date]
      @jobs = Job.where("startdate > :s and enddate < :e and hostname = :h and jobname != :n", :s=>params[:start_date].to_datetime,:e=>params[:end_date].to_datetime.next,:h=>"M6650M453",:n=>'Get Iddrive').order('jobid desc')
    else
      @jobs = latest_jobs
    end
  end

  #Latest jobs
  def latest_jobs
    @jobs = Job.where("hostname='M6600M285' and jobname !='Get Iddrive'").order('jobid desc').limit(10)
  end

  #Pearson SD card jobs list view
  def edutor_jobs
    if params[:start_date] and params[:end_date]
      @jobs = Job.where("startdate > :s and enddate < :e and hostname = :h", :s=>params[:start_date].to_datetime,:e=>params[:end_date].to_datetime.next,:h=>"M6650M453").order('jobid desc')
    else
      @jobs = edutor_latest_jobs
    end
  end

  # Pearson_dgstore_jobs SD card jobs list view
  def dgstore_jobs
    if params[:start_date] and params[:end_date]
      @jobs = Job.where("startdate > :s and enddate < :e and hostname = :h", :s=>params[:start_date].to_datetime,:e=>params[:end_date].to_datetime.next,:h=>"M6600M284").order('jobid desc')
    else
      @jobs = Job.where(:hostname=>'M6600M284').order('jobid desc').limit(10)
    end
    render :layout=>'global'
  end

  def dgstore1_jobs
    if params[:start_date] and params[:end_date]
      @jobs = Job.where("startdate > :s and enddate < :e and hostname = :h", :s => params[:start_date].to_datetime, :e => params[:end_date].to_datetime.next, :h => "M6600M495").order('jobid desc')
    else
      @jobs = Job.where(:hostname => 'M6600M495').order('jobid desc').limit(10)
    end
    render :layout => 'global'
  end

  def usbchips_jobs
    if params[:start_date] and params[:end_date]
      @jobs = Job.where("startdate > :s and enddate < :e and hostname = :h", :s => params[:start_date].to_datetime, :e => params[:end_date].to_datetime.next, :h => "M5116M062").order('jobid desc')
    else
      @jobs = Job.where(:hostname => 'M5116M062').order('jobid desc').limit(10)
    end
    render :layout => 'global'
  end

  #Latest jobs
  def edutor_latest_jobs
    @jobs = Job.where(:hostname=>'M6650M453').order('jobid desc').limit(10)
  end

  #Getting slots for a jobs
  def job_slots
    @slots = Slot.where(:jobid=>params[:id])
    render :layout=>'global'
  end

  #Ignatior chip register
  def ignitor_chip_register

    users = ActionController::HttpAuthentication::Basic::user_name_and_password(request)

    @user = User.find_by_edutorid(users[0])

    device = params[:device_id]
    device_info = JSON.load(params[:device_info])
    chip_fs_info =JSON.load(params[:chip_fs_info])
    chip_info = JSON.load(params[:chip_info])

    if device.nil?
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>"Device ID not sent"}}
      end
      return
    end

    @device = Device.find_by_deviceid(device)
    @device_property_exist  = DevicePropertyIgnitor.find_by_imei_and_mac_id_and_android_id(device_info['imei'],device_info['mac_id'],device_info['android_id'])

    if @device_property_exist.nil?
      @device_property = DevicePropertyIgnitor.create(device_info)
    else
      @device_property = @device_property_exist
    end


    @job = []
    @slots = Slot.find_record_by_cid(chip_info['cid']).order('jobid desc')
    #@slot = Slot.where('lower(cid)=?',chip_info['cid'].downcase)
    if !@slots.empty?
      #@slot = @slot.last
      @slots.each do |j|
        @new_job = Job.where("jobid = #{j.jobid} and jobname like '%WriteProtect.mlj'")
        if !@new_job.empty?
          @slot = j
          break
        end
      end
      if @new_job.empty?
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Invalid JobID"}}
        end
        return
      end
      @job = @new_job
    end

    if @job.empty?
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>"Invalid JobID"}}
      end
      return
    end


    @issue_id = params[:masterchip_id]
    @master_chip = Masterchip.find_by_issue_id(@issue_id)

    if @master_chip.nil?
      respond_to do |format|
        format.json { render json:  {:chip_accepted=>false,:error=>"Invalid masterchip id"} }
      end
      return
    end

    #@master_chip_fs = ChipFsInfo.find(@master_chip.chip_fs_info_id)
    #@master_chip_fs = @master_chip_fs.to_json
    #@master_chip_fs = JSON.load(@master_chip_fs)
    #@master_chip_fs.delete('created_at')
    #@master_chip_fs.delete('updated_at')
    #@master_chip_fs.delete('id')

    chip_type = chip_info['type']
    chip_info.delete('type')
    chip_info['chip_type'] = chip_type

    m_chip_info = chip_info
    m_chip_info['issue_id'] = params[:masterchip_id]
    m_chip_info.delete('masterchip_id')
    @master_aspchip = Masterchip.where(m_chip_info)

    if !@master_aspchip.empty?
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>"This is Masterchip"} }
      end
      return
    end

    if !@master_chip.masterchip_details.nil?
      @key = @master_chip.masterchip_details.masterchip_key
      if @key.nil?
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Masterchip key details not found"} }
        end
        return
      end
    else
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>"Masterchip details not found"} }
      end
      return
    end

    chip_info.delete('issue_id')
    chip_info['masterchip_id'] = params[:masterchip_id]


   # @powerchip = Powerchip.find_by_cid(chip_info['cid'])
    @powerchip = Powerchip.where('lower(substr(cid,1,30))=?',"#{chip_info['cid'][0..29]}".downcase).last
    if @powerchip.nil?
      #@powerchip = Powerchip.create(chip_info)
      @powerchip = Powerchip.new(chip_info)
      if !@powerchip.save
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Unable to process powerchip"}}
        end
        return
      end
    end


    @already_asigned = UserDevicePowerchip.find_by_powerchip_id(@powerchip.id)
    if !@already_asigned.nil?
      if @already_asigned.user_id == @user.id
        respond_to do |format|
          format.json { render json: {:chip_accepted=>true,:error=>"Powerchip already assigned",:k=>@key} }
        end
        return
      else
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Powerchip already assigned to #{@already_asigned.user.edutorid}"} }
        end
        return
      end
    end


    @powerchip_exist = UserDevicePowerchip.where(:user_id=>@user.id,:device_id=>@device.id,:powerchip_id=>@powerchip.id,:device_property_ignitor_id=>@device_property.id)

    if @powerchip_exist.empty?
      UserDevicePowerchip.create(:user_id=>@user.id,:powerchip_id=>@powerchip.id,:device_id=>@device.id,:device_property_ignitor_id=>@device_property.id)
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true,:k=>@key} }
      end
    else
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true,:k=>@key,:error=>'Powerchip already assigned'} }
      end
    end

  end


  def ignitor_usb_chip_register


    @user = User.find_by_edutorid(params[:user_id])
    @device = Device.find_by_deviceid(params[:device_id])
    if @user.nil?
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>'Invalid User'} }
      end
      return
    end

    if @device.nil?
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>'Invalid Device'} }
      end
      return
    end

    @usb_chip = UsbChip.find_by_chipid(params[:pnpdeviceid])
    if @usb_chip.nil?
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>'chip not whitelisted'} }
      end
      return
    end


    @chip_present = IgnitorUserChip.find_by_pnpdeviceid(params[:pnpdeviceid])

    if !@chip_present.nil?
      if @chip_present.user_id == @user.id
        respond_to do |format|
          format.json { render json: {:chip_accepted=>true,:error=>'Already Assigned'} }
        end
        return
      else
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Chip Already Assigned to #{@chip_present.user_id}"} }
        end
        return
      end
    end

    @chip = IgnitorUserChip.new
    @chip.user_id = @user.id
    @chip.device_id = @device.id
    @chip.pnpdeviceid = params[:pnpdeviceid]
    if @chip.save
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true} }
      end
    else
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>@chip.errors} }
      end
    end

  end


  # Powerchip unregister to the user by given edutorid or cid of the chip
  def powerchip_search
    @cids = params[:cids] == '' ? false : true
    @edutorids = params[:edutorids] == '' ? false : true

    @cids_array = params[:cids].split(',') if params[:cids]
    @edutorids_array = params[:edutorids].split(',')
    @edutorids1 = params[:edutorids].split('-').last.to_i

    if @cids and @edutorids
      @powerchips= Powerchip.where(:cid=>@cids_array)
      @users = User.where(:edutorid=>@edutorids_array)
      @user_powerchips = UserDevicePowerchip.where("user_id IN (?) or powerchip_id IN (?)",@powerchips.map(&:id),@users.map(&:id))
    elsif @cids
      @powerchips= Powerchip.where(:cid=>@cids_array)
      @user_powerchips = UserDevicePowerchip.where("powerchip_id IN (?)",@powerchips.map(&:id))
    elsif @edutorids
      @users = User.where(:edutorid=>@edutorids_array)
      @user_powerchips = UserDevicePowerchip.where("user_id IN (?)",@users.map(&:id))
      @user_ignitorchips = IgnitorUserChip.where("user_id IN (?)",@users.map(&:id))


    end


    respond_to do |format|
      format.js
    end



  end

  # Delete user user device powerchip entry
  def delete_user_powerchip
    @row_ids = []
    if params[:chips]["UserDevicePowerchip"].present?
      @user_device_powerchips = UserDevicePowerchip.where(:id=>params[:chips]["UserDevicePowerchip"])
      @user_device_powerchips.each do |chip|
        @row_ids << "chip_"+chip.class.to_s+chip.id.to_s
        chip.destroy
      end
    elsif params[:chips]["IgnitorUserChip"].present?
      @ignitor_user_chips = IgnitorUserChip.where(:id=>params[:chips]["IgnitorUserChip"])
      @ignitor_user_chips.each do |chip|
        @row_ids << "chip_"+chip.class.to_s+chip.id.to_s
        chip.destroy
      end
    end
    respond_to do |format|
      format.js
    end

  end

  def powerchip_unregister
  end

  def powerchip_slots
  end

  def powerchip_check_add
    chip_id = params[:chip_id]

    # Find if slots exist
    mode = params[:mode]
    @slots = []
    if mode =='chip'
      # we check cid
      @slots = Slot.find_record_by_cid(chip_id).order('jobid desc') # basically a 'where' condition
    else # we check serial id
      @slots = Slot.where(:serialnum => chip_id).order("jobid desc")
    end

    # if @slots are empty, create record and push it to @slots
    if @slots.empty?
      @slots = []
      slot = Slot.new
      if mode=='chip'
        slot.cid= chip_id
      else
        slot.serialnum = chip_id
      end
      slot.jobid = 3
      slot.message = 'Passed'
      slot.save
      @slots << slot
      status = 'new'
    else
      status = 'existing'
    end

    # populate records array
    records = @slots.map { |slot| [slot.cid, slot.serialnum, slot.vid, slot.pid] }

    render json: {status: status, header: ["CID", "Serial No.", "VID", "PID"], records: records}
  end

# Windows usb chip checking whitelist and linking the user,device and chip
def usbchip_validate_register
    @user = User.find_by_edutorid(params[:user_id])
    @device = Device.find_by_deviceid(params[:device_id])
    if @user.nil?
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>'Invalid User'} }
      end
      return
    end

    if @device.nil?
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>'Invalid Device'} }
      end
      return
    end 

    @slots =  Slot.where(:serialnum=>params["serial"]).order("jobid desc")
    if @slots.empty?
      respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Invalid JobID"}}
        end
        return      
    end

   
   if @user.institution_id != 51827
    if !@slots.empty?
        @job = Job.where("jobid = #{@slots.first.jobid} and jobname like '%WriteProtect.mlj'")
        
      if @job.empty?
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Invalid JobID"}}
        end
        return
      end
    end
 end
 if @user.institution_id != 51827
  @chip_present = IgnitorUserChip.find_by_serialnum(params["serial"])

    if !@chip_present.nil?
      if @chip_present.user_id == @user.id
        respond_to do |format|
          format.json { render json: {:chip_accepted=>true,:error=>'Already Assigned'} }
        end
        return
      else
        respond_to do |format|
          format.json { render json: {:chip_accepted=>false,:error=>"Chip Already Assigned to #{@chip_present.user_id}"} }
        end
        return
      end
    end
 end

    @chip = IgnitorUserChip.new
    @chip.user_id = @user.id
    @chip.device_id = @device.id
    @chip.serialnum = params["serial"]
    @chip.pid = params["pid"]
    @chip.vid = params["vid"]
    if @chip.save
      respond_to do |format|
        format.json { render json: {:chip_accepted=>true} }
      end
    else
      respond_to do |format|
        format.json { render json: {:chip_accepted=>false,:error=>@chip.errors} }
      end
    end
 
end  

end
