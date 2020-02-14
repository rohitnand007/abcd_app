class ErrorsController < ApplicationController
  #before_filter :check_downloads
  skip_filter :check_downloads
  def error_404
    #@not_found_path = params[:not_found]
    # render :status=>404
    respond_to do |format|
      format.html { render template: 'errors/error_404',  status: 404, layout:false }
      format.all { render nothing: true, status: 404 }
    end
  end

  def error_500
    #@error =
    render :status=>500
  end

  def check_downloads
    logger.info"==========#{Rails.env}========="
    if Rails.env.eql?("development")
      host = "http://"+request.host+":"+request.port.to_s
    else
      host = "http://"+request.host
    end
    logger.info"==========#{host}========="
    url = request.url.split(host).last
    logger.info"==========#{url}========="
    url_split = url.split("/")
    logger.info"==========#{url_split}========="
    if url_split.include?('message_download')
      logger.info"==========in========="
      @message  = Message.find(url_split[2])
      ext = request.url.split('.').last
      if @message
        @message_download = MessageUserDownload.new
        @message_download.message_id= @message.id
        if current_user
          @message_download.user_id= current_user.id
        else
          @message_download.user_id = 0
        end
        @message_download.save
        url = "/messages/#{url_split[3]}/#{url_split[4]}/#{url_split[5]}"
        redirect_to url
      else
        render :status=>404
      end
    elsif  [".zip",".mp4","pdf",".apk"].include?(File.extname(url.split("/").last))
      if File.exist?(Rails.root.to_s+"/public1/"+url)
        send_file Rails.root.to_s+"/public1/"+url
      else
        render :action=>:error_404
      end
    else
      render :action=>:error_404
    end
  end

end
