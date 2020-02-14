class Api::Sky::BookController < Api::Sky::BaseController
  def get_toc
    book_id = params[:book_guid]
     if Ibook.find_by_ibook_id(book_id)
       toc_data = Ibook.find_by_ibook_id(book_id).build_toc
     else
       toc_data = {}
     end
    render :json => toc_data
  end

  def get_metadata
    book_id = params[:book_guid]
    metadata ={}
    if Ibook.find_by_ibook_id(book_id)
      metadata = Ibook.find_by_ibook_id(book_id).get_metadata
    end
    render :json => metadata
  end
end