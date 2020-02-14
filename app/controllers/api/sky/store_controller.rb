class Api::Sky::StoreController < Api::Sky::BaseController
  before_filter :set_store, :except => [:get_product_tags]

  def available_books_list
     publishers = @store.publishers
     available_books = publishers.map{|publisher| publisher.ibooks.select{|ibook| {book_id:ibook.ibook_id,publisher_id:ibook.publisher_id} if  ibook.version==2}}.flatten
    
    book_list= available_books.map do |ibook|
      metadata = ibook.get_metadata
      image_url = ibook.book_image_url(request.host_with_port)
      {book_id: ibook.ibook_id,
       publisher_id: ibook.publisher_id,
       description: metadata["description"],
       image_url: image_url,
       author: metadata["author"],
       publisher: metadata["publisher"],
       isbn: metadata["isbn"],
       subject: metadata["subject"],
       academicClass: metadata["academicClass"],
       name: metadata["displayName"]}
    end
                   .uniq
    # book_list = [{:book_id => "acb4df1f-7ba0-41cc-b8dc-eeeed22673f0", :publisher_id => "1"},
    #              {:book_id => "77847faa-40b1-4f3a-a929-f76a84ff821c", :publisher_id => "2"}]
    render :json => book_list
  end

  def get_store_id
    if @api_user.respond_to? :store
      render :json => @api_user.store.id
    else
      render :json => 0
    end
  end

  def set_store
    store_admin = @api_user
    @store = store_admin.store
  end

  def get_product_tags
    #parsms[:guid] is sent
    if product_type(params[:guid]) == "Course"
      tags = Course.find_by_guid(params[:guid]).get_tags
    elsif product_type(params[:guid]) == "Ibook"
      tags = Ibook.find_by_ibook_id(params[:guid]).get_tags
    else
    end
    render :json => tags
  end

  private
  def product_type(guid)
    if Course.find_by_guid(guid).present?
      "Course"
    elsif Ibook.find_by_ibook_id(guid)
      "Ibook"
    elsif TocItem.find_by_guid(guid)
      "TocItem"
    else
      ""
    end
  end
end