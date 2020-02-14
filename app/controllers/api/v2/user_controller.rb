class Api::V2::UserController < Api::V2::BaseController


  def last_content_purchased
    # current_user.last_content_purchased = 1446280033
    render :json => {user_id: current_user.id, last_content_purchased: current_user.last_content_purchased}
  end
  #
  # def accessible_content
  #   render :json => {"courses" => [{"id" => "acb4df1f-7ba0-41cc-b8dc-eeeed22673f0", "name" => "GRE", "starts" => 363464646, "ends" => 567567576, "books" => [{"id" => "77847faa-40b1-4f3a-a929-f76a84ff821c", "infoUrl" => ""}, {"id" => "83368d7f-8b51-450a-96aa-ddda9bda48a2", "infoUrl" => ""}]}, {"id" => "30b4df1f-7ba0-41cc-b8dc-eeeed22673f0", "name" => "IIT", "starts" => 363464646, "ends" => 567567576, "books" => [{"id" => "77847faa-40b1-4f3a-a929-f76a84ff821c", "infoUrl" => ""}, {"id" => "5874dcdd-57ef-4663-92c0-e92e0e406d78", "infoUrl" => ""}]}], "books" => [{"id" => "77847faa-40b1-4f3a-a929-f76a84ff821c", "starts" => -1, "ends" => -1, "infoUrl" => "", "items" => [{"id" => "acb4df1f-7ba0-41cc-b8dc-eeeed22673f0", "start_date" => 1442041500, "end_date" => 1473836640, "start_position" => 0, "end_position" => 0, "number_of_times" => -1, "type" => "chapter"}, {"id" => "xy4df1f-7ba0-41cc-b8dc-eeeed22673f0", "start_date" => 1442041500, "end_date" => 1473836640, "start_position" => 0, "end_position" => 0, "number_of_times" => -1, "type" => "chapter"}]}, {"id" => "ad3c4dd2-baeb-499a-bc2c-161194425601", "starts" => 363464646, "ends" => 567567576, "infoUrl" => ""}, {"id" => "999508b7-a9d9-4042-a8ce-17bfa8c6e0a0", "starts" => 363464646, "ends" => 5675675794, "infoUrl" => "", "items" => [{"id" => "3454df1f-7ba0-41cc-b8dc-yuyfd22673f0", "start_date" => 1442041500, "end_date" => 1473836640, "start_position" => 0, "end_position" => 0, "number_of_times" => -1, "type" => "chapter"}]}]}
  # end

  def accessible_content
    user_id = current_user.id

    # accessed_content = ContentAccessPermission.where("user_id=? and ends > ? ", user_id, Time.now)
    # Shows all licences instead of only present
    # accessed_content = ContentAccessPermission.where(user_id:user_id).group(:accessed_content_guid).having("ends = MAX(ends)")
    accessed_content = ContentAccessPermission.get_latest_records(user_id)
    accessed_content = accessed_content.sort_by(&:id).reverse

    content_json = {"courses"=>[],"books"=>[]}

    # Populate courses
    accessible_courses = accessed_content.select{|ai| ai.accessed_content_type=='course' }
    accessible_courses.each do |item|
      begin
        content_type = item.accessed_content_type
        content_fetch = Course.where(guid:item.accessed_content_guid).first
        # Adds course to the courses list along with permissions
        content_json["courses"] << {"guid" => content_fetch.guid, 
          "name" => content_fetch.name, "updatedAt"=>content_fetch.updated_at.to_s,
          "starts" => item.starts, "ends" => item.ends, 
          "books" => [], "assignedVia" => item.assignedVia, 
          "onStore" => item.on_store?}
        # Fills details of the books present in the course
        content_fetch.ibooks.each do |book_data|
          content_json["courses"].find{|course|course["guid"]==content_fetch.guid}["books"] << {"guid"=>book_data.ibook_id,"infoUrl"=>book_data.get_ibook_info_file_url, "updatedAt"=>book_data.updated_at.to_s,}
        end
      rescue
        logger.info "==issue with==#{item.id}==#{item.accessed_content_guid}==#{item.accessed_content_type}"
        next
      end
    end


    # Populate books
    accessible_books = accessed_content.select{|ai| ai.accessed_content_type=='book' }
    accessible_books.each do |item|
      begin
        content_type = item.accessed_content_type
        content_fetch = Ibook.where(ibook_id:item.accessed_content_guid).first
        # Adds book to the books list along with book permissions
        content_json["books"] << {"guid" => content_fetch.ibook_id, 
          "name" => content_fetch.title, "updatedAt"=>content_fetch.updated_at.to_s,
          "starts" => item.starts, "ends" => item.ends, 
          "infoUrl" => content_fetch.get_ibook_info_file_url, 
          "items" => [], "assignedVia" => item.assignedVia, "onStore" => item.on_store?}
      rescue
        logger.info "==issue with==#{item.id}==#{item.accessed_content_guid}==#{item.accessed_content_type}"
        next
      end
    end


    # Populate chapters / toc_items
    accessible_toc_items = accessed_content.select{|ai| ai.accessed_content_type=='toc_item' }
    accessible_toc_items.each do |item|
      begin
        content_type = item.accessed_content_type
        content_fetch = TocItem.where(guid:item.accessed_content_guid).first
        parent_book = Ibook.find_by_ibook_id(content_fetch.book_guid)
        # Creates a dummy book entry if the book entry already doesn't exist
        if content_json["books"].find { |book| book["guid"]==content_fetch.book_guid }.nil?
          content_json["books"] << {"guid" => content_fetch.book_guid, 
            "name" => parent_book.title,"updatedAt"=>parent_book.updated_at.to_s,
            "starts" => -1, "ends" => -1, 
            "infoUrl" => parent_book.get_ibook_info_file_url, 
            "items" => [], "assignedVia" => item.assignedVia} 
        end
        # Finds the corresponding book entry and pushes the chapter/toc-item into the book entry's "items" array
        content_json["books"].find{|book|book["guid"]==content_fetch.book_guid}["items"] << { "guid"=>item.accessed_content_guid,
                                                                                              "starts"=>item.starts,
                                                                                              "ends"=>item.ends,
                                                                                              "startposition"=>item.start_position,
                                                                                              "endposition"=>item.end_position,
                                                                                              "numberoftimes"=>item.number_of_times,
                                                                                              "type" => content_fetch.content_type,
                                                                                              "onStore" => item.on_store?,
                                                                                              "assignedVia" => item.assignedVia
        }


      rescue
        logger.info "==issue with==#{item.id}==#{item.accessed_content_guid}==#{item.accessed_content_type}"
        next
      end
    end

    render json: content_json
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
      if user_asset.attachment_content_type == "application/pdf"
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

  def download_info_child_assets
    guid = params[:guid]
    info = TocItem.toc_item_download_info(guid,current_user)
    respond_to do |format|
      format.json {render json: info}
    end
  end

  def get_store_url
    url = current_user.get_store_url
    if url.present?
      render json: {url: url}
    else
      render json: {url: ''}
    end
  end

  def set_video_view_count
    render json: {status: "Not Implemented"}
  end

  def get_ignitor_web_url
    url = current_user.get_ignitor_web_url
    if url.present?
      render json: {url: url}
    else
      render json: {url: ''}
    end
  end

end