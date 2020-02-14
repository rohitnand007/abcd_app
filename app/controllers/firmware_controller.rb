## This is the controller for processing the firmware upgrade requests from the tab
class FirmwareController < ApplicationController

skip_before_filter:authenticate_user! # Making this link an open link

  ## This is the url that the tab requests for the updates with the device id
  def get_updates
  
   # Params for testing
    #params[:deviceId] = "E010312204098"
    #params[:update] = TRUE
    
    # Basic parameters to be sent in the response
    result = Hash.new
    result["isValid"] = FALSE
    result["errorMessage"] = ''

    # Check if the valid device id is present in the request
    if !params[:deviceId].blank?
    result["deviceId"] = params[:deviceId]
    
    # TODO: Currently if the request has a device id then treating it as a valid request have to implement device validation in the future
    result["isValid"] = TRUE
    
    # The params that are to sent related to the package
      result["updateAvailable"] = FALSE
      result["updatePackageLink"] = ''
      
      # TODO: Currently if they are asking for the update then sending an update In the future have to check if the updates are available from the repository database
      if !params[:update].blank?  && !params[:update]
      
      ## TODO: Currenting sending the dummy data
      result["updateAvailable"] = TRUE
      result["updatePackageLink"] = '/dummy/junk.zip'
      result["updatePackageSize"] = File.size(Rails.root.to_s+"/public/dummy/junk.zip")
      result["updatePackageFileName"] = "junk.zip"
      
      end
    else
    # Device id is not present in the request then sending an error message
    result["errorMessage"] = "Please send a valid device Id"
    end

    # Sending the respose as json array
    respond_to do |format|
      format.json { render :json => result}
    end
  end


  def device_download
    #input params
    #params[:device_id] = 'deviceid'
    #params[:password] = '********'
    #--------------
    @responce =  {}


    if params[:user][:deviceid].blank?
      @responce[:error]= "Device is empty"
      respond_to do |format|
        format.html {render layout:false}
        format.json { render json: @responce }
      end
      return
    end

    if params[:user][:password].blank?
      @responce[:error]= "password is  empty"
      respond_to do |format|
        format.html {render layout:false}
        format.json { render json: @responce }
      end
      return
    end

    unless params[:user][:deviceid].blank?
      @device = Device.where(:deviceid => params[:user][:deviceid])
      if @device.empty?
        @responce[:error]= "invalid device id"
        respond_to do |format|
          format.html {render layout:false}
          format.json { render json: @responce }
        end
        return
      end
    end

    if params[:user][:deviceid] and params[:user][:password]
      password  = Digest::MD5.hexdigest(params[:user][:deviceid]+Edutor::Application.config.device_id_hash_salt)
      if password == params[:user][:password]
        @responce = { sign_in: true}
        #@result = {is_primary: is_primary,sign_in: true,:message=>'Primary device'}
        respond_to do |format|
          format.html {render layout:false}
          format.json { render json: @responce }
        end
        return
         #redirect_to firmware_updates_path({:deviceId=>params[:device_id],:update=>true})
      else
        @responce[:error]= "Authorization failed"
        respond_to do |format|
          format.html {render layout:false}
          format.json { render json: @responce }
        end
        return
      end
    end
    respond_to do |format|
      format.html {render layout:false}
      format.json { render json: @responce }
    end

  end



end