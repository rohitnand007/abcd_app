class Api::Ops::ContentRequestController < Api::Ops::BaseController

  def request_not_uploaded_books
    ibook_ids = CdnBooksInfo.where(user_id: @api_user, upload_status: false).map{|p| p.guid}
    book_asset_details = Ibook.book_asset_details_for_ops(ibook_ids)
    render json: {success: true, book_asset_info: book_asset_details}
  end

  def send_ibook_file
    @ibook = Ibook.find(params["book_id"])
    if @ibook.encrypted_content.present?
      response.header["Accept-Ranges"] = "bytes"
      send_file @ibook.encrypted_content.path, :disposition => 'inline', :type => "application/octet-stream", :x_sendfile => true
    else
      render nothing:true, status:404,layout:false
      return
    end
  end

  def send_ibook_info_file
    @ibook = Ibook.find(params["book_id"])
    if @ibook.info_file.present?
      response.header["Accept-Ranges"] = "bytes"
      send_file @ibook.info_file.path, :disposition => 'inline', :type => "application/octet-stream", :x_sendfile => true
    else
      render nothing:true, status:404,layout:false
      return
    end
  end


  def update_cdn_content_status
    book_md5_hash = JSON.parse(params["book_md5"])
    puts "#{book_md5_hash}"
    status = []
    book_md5_hash.each do |k,v|
      cdn_content_info =  CdnContentInfo.where(guid:k, user_id:@api_user.id).first
     unless cdn_content_info.nil?
       residual_md5 =  cdn_content_info.md_hash
       if residual_md5 == v
         cdn_content_info.update_attribute(:upload_status,true)
         status << "success"
       else
         cdn_content_info.update_attribute(:upload_errors,"Book/Asset Upload Failed")
         status << "failed"
       end
     else
       status << "Book/Asset not found"
     end
    end
    render json: {success:true, status:status}
  end

end