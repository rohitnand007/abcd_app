class BooksController < ApplicationController
  authorize_resource :only=>[:edit, :index, :new, :show]
  # GET /books
  # GET /books.json
  def index
    @books = Book.order('id desc')
    if request.xhr?
      @books = Book.where("name like ?","%#{params[:term]}%")
    end
    respond_to do |format|
      format.html # index.html.erb
      unless request.xhr?
        format.json { render json: @books }
      else
        format.json { render json: @books.map{|d| Hash[id: d.id,name: d.name]} }
      end

    end
  end

  # GET /books/1
  # GET /books/1.json
  def show
    @book = Book.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @book }
    end
  end

  # GET /books/new
  # GET /books/new.json
  def new
    @book = Book.new
    @book.build_book_cover
    @book.build_book_asset
    @book.build_book_key

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @book }
    end
  end

  # GET /books/1/edit
  def edit
    @book = Book.find(params[:id])
  end

  # POST /books
  # POST /books.json
  def create
    save = false
    @book = Book.new(params[:book])
    # book_file_name = @book.book_asset.attachment_file_name.split('.')[0] unless @book.book_asset.nil?
    book_file_name_ext = @book.book_asset.attachment_file_name unless @book.book_asset.nil?
    book_file_name = book_file_name_ext.split('.')[0] unless @book.book_asset.nil?
    key_file_name = @book.book_key.attachment_file_name.split('.')[0]    unless @book.book_key.nil?
    if @book.book_type == true
      save = true
      @book.book_asset.attachment_file_name = book_file_name
      book_size = @book.book_asset.attachment_file_size
      @book.book_asset.attachment = nil
      params[:book][:book_asset_attributes] = nil
      @book.book_asset.attachment_file_size = book_size
    end
    unless @book.book_asset.nil? || @book.book_key.nil? || @book.book_type == true
      if key_file_name == Digest::MD5.hexdigest(book_file_name)
        save = true
      end
    end
    respond_to do |format|
      if save and @book.save
        if @book.book_type == true
          @book.book_asset.update_attribute(:attachment_file_name,book_file_name_ext)
        end
        if @book.book_type == false
          @book.book_asset.update_attribute(:md5_hash,Digest::MD5.hexdigest(File.read(@book.book_asset.attachment.path)) )
        end
        @book.book_key.update_attribute(:md5_hash,Digest::MD5.hexdigest(File.read(@book.book_key.attachment.path)) )
        format.html { redirect_to @book, notice: 'Book was successfully created.' }
        format.json { render json: @book, status: :created, location: @book }
      else
        unless save
          @book.errors.add(:attachment_file_name, "Uploading wrong key for the book")
        end
        format.html { render action: "new" }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /books/1
  # PUT /books/1.json
  def update
    @book = Book.find(params[:id])

    respond_to do |format|
      if @book.update_attributes(params[:book])
        format.html { redirect_to @book, notice: 'Book was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1
  # DELETE /books/1.json
  def destroy
    @book = Book.find(params[:id])
    @book.destroy

    respond_to do |format|
      format.html { redirect_to books_url }
      format.json { head :ok }
    end
  end

  def get_pearson_books

  end


  #User Requesting For The Book Collection
  def user_book_collection
    @result = []
    @books = []
    @user = User.find_by_edutorid(params[:user_id])
    if !@user.nil?
      @user_collection = UserBookCollection.where(:user_id=>@user.group_ids+[@user.id])
      if @user_collection.empty?
        respond_to do |format|
          format.json { render json: {:error=>'No collection found for the user'} }
        end
        return
      else
        @user_collection.each do |c|
          if !c.collection.books.empty?
            @books << c.collection.book_ids
          end
        end
        Book.includes(:book_asset).where(:id=>@books.uniq).where("book_assets.attachment_file_name like '%epub'").each do |b|
          begin
            if b.book_type == false
              book_hash = Digest::MD5.hexdigest(File.read(b.book_asset.attachment.path))
              book_url = nil#get_user_book_url(@user,b)
              book_size = b.book_asset.attachment_file_size
            else
              book_hash = nil
              book_url = nil
              book_size = b.book_asset.attachment_file_size
            end
            book_key_hash = Digest::MD5.hexdigest(File.read(b.book_key.attachment.path))
            @result << {:book_name=>b.book_asset.attachment_file_name,:book_url=>book_url,:book_hash=>book_hash,:book_size=>book_size,:book_key_url=>get_book_key_url(b),:book_key_hash=>book_key_hash,:book_key_size=>b.book_key.attachment_file_size,:book_key_name=>b.book_key.attachment_file_name}
          rescue
            next
          end
        end
      end
    end
    respond_to do |format|
      format.json { render json: {:books=>@result} }
    end
    return
  end

  def user_book_collection_all
    @result = []
    @books = []
    @user = User.find_by_edutorid(params[:user_id])
    if !@user.nil?
      @user_collection = UserBookCollection.where(:user_id=>@user.group_ids+[@user.id])
      if @user_collection.empty?
        respond_to do |format|
          format.json { render json: {:error=>'No collection found for the user'} }
        end
        return
      else
        @user_collection.each do |c|
          if !c.collection.books.empty?
            @books << c.collection.book_ids
          end
        end
        Book.where(:id=>@books.uniq).each do |b|
          begin
            if b.book_type == false
              #book_hash = Digest::MD5.hexdigest(File.read(b.book_asset.attachment.path))
              book_hash = b.book_asset.md5_hash
              book_url = get_user_book_url(@user,b)
              book_size = b.book_asset.attachment_file_size
            else
              book_hash = nil
              book_url = nil
              book_size = b.book_asset.attachment_file_size
            end
            #book_key_hash = Digest::MD5.hexdigest(File.read(b.book_key.attachment.path))
            book_key_hash = b.book_key.md5_hash
            @result << {:book_name=>b.book_asset.attachment_file_name,:book_url=>book_url,:book_hash=>book_hash,:book_size=>book_size,:book_key_url=>get_book_key_url(b),:book_key_hash=>book_key_hash,:book_key_size=>b.book_key.attachment_file_size,:book_key_name=>b.book_key.attachment_file_name}
          rescue
            next
          end
        end
      end
    end
    respond_to do |format|
      format.json { render json: {:books=>@result} }
    end
    return
  end

  #Downloading the requested book
  def get_book
    # logger.info "==========#{request.headers['range']}=="
    @book = Book.find(params[:id])
     
    if @book.id == 169 #and current_user.id.in?  [26644, 49422, 26642]
     redirect_to 'https://192.168.1.210/9780321775658_habitat_pxe_basic.epub', status: 302
     # redirect_to 'https://10.142.71.210/9780321775658_habitat_pxe_basic.epub', status: 302
      return
    end
 
    if current_user.center_id == 26700
     send_file @book.book_asset.attachment.path ,:disposition=>'inline',:type=>"application/octet-stream",:x_sendfile=>true
     return
    end   

    
    book_ids =  [43, 46, 176, 48, 347, 258, 249, 84, 85, 259, 185, 260, 186, 86, 261, 276, 49, 50, 57, 177, 305, 306, 307, 308, 309, 323, 310, 55, 56, 169, 87, 88, 89, 90, 288, 289, 290, 91, 59, 106, 107, 277, 108, 311, 312, 313, 332, 314, 326, 325, 343, 348, 180, 92, 93, 94, 95, 352, 97, 351, 199, 195, 198, 321, 262, 263, 264, 265, 339, 251, 250, 340, 219, 266, 267, 109, 110, 268, 269, 270, 335, 327, 160, 280, 281, 282, 283, 284, 285, 286, 163, 178, 333, 153, 324, 174, 272, 254, 278, 223, 225, 226, 227, 228, 231, 232, 229, 230, 234, 273, 233, 236, 240, 237, 238, 274, 239, 342, 320, 319, 318, 317, 316, 315, 98, 99, 345, 346, 336, 341, 337, 166, 338, 167, 242, 243, 244, 245, 350, 349, 247] 

 #    if !book_ids.include? @book.id
 #      response.header["Accept-Ranges"] = "bytes"
 #      send_file  "#{Rails.root}/public/404.html", :type => 'text/html; charset=utf-8', :status => 404
 # #book.book_asset.attachment.path ,:disposition=>'inline',:type=>"application/octet-stream",:x_sendfile=>true
 #      return
 #    else
 #     send_file "#{Rails.root}/public/404.html", :type => 'text/html; charset=utf-8', :status => 404
 #    end
    #send_file @book.book_asset.attachment.path ,:disposition=>'inline',:type=>"application/octet-stream",:x_sendfile=>true
    if File.exists? @book.book_asset.attachment.path
      send_file @book.book_asset.attachment.path ,:disposition=>'inline',:type=>"application/octet-stream",:x_sendfile=>true
    else
      send_file "#{Rails.root}/public/404.html", :type => 'text/html; charset=utf-8', :status => 404
    end
    #send_file "#{Rails.root}/public/404.html", :type => 'text/html; charset=utf-8', :status => 404
   end

  #Downloading the requested book key
  def get_book_key
    #  logger.info "==========#{request.headers['range']}=="
    @book = Book.find(params[:id])
    response.header["Accept-Ranges"] = "bytes"
    send_file @book.book_key.attachment.path ,:disposition=>'inline',:type=>"application/octet-stream",:x_sendfile=>true
  end

  #User Books In Tab
  def user_books
    @user = User.find(params[:user_id])
    @books  = params[:_json]
    if !@books.nil?
      UserBook.where(:user_id=>@user.id).destroy_all
      @books.each do |b|
        # user_book = UserBook.where(:user_id=>@user.id,:book_name=>b)
        #if user_book.empty?
        UserBook.create(:user_id=>@user.id,:book_name=>b)
      end
    end
    respond_to do |format|
      format.json { render json: true }
    end
  end

  #Getting The Apps In Device
  def pearson_device_apps
    device_id = params['device_id']
    #string = request.body.read
    #config =  ActiveSupport::JSON.decode(string)
    logger.info"====#{config}"
    @apps = PearsonUserApp.find_by_deviceid(device_id)
    if @apps.nil?
      @config = PearsonUserApp.new
      @config.config = params['config']
      @config.workspace_apps = params['workspace_apps']
      @config.firewall = params['firewall']
      @config.apps = params['apps']
      @config.deviceid = device_id
      @config.mdm = params['MDM']
      @config.ignitor = params['IGNITOR']
      @config.save
    else
      @apps.update_attributes(:config=>params['config'],:workspace_apps=>params['workspace_apps'],:firewall=>params['firewall'],:apps=>params['apps'],:mdm=>params['MDM'],:ignitor=>params['IGNITOR'])
    end
    respond_to do |format|
      format.json {render json: true}
    end
  end

 def get_user_book_url(user,book)
   @cdn = user.center.cdn_configs
 #  book_ids =  [43, 46, 176, 48, 347, 258, 249, 84, 85, 259, 185, 260, 186, 86, 261, 276, 49, 50, 57, 177, 305, 306, 307, 308, 309, 323, 310, 55, 56, 169, 87, 88, 89, 90, 288, 289, 290, 91, 59, 106, 107, 277, 108, 311, 312, 313, 332, 314, 326, 325, 343, 348, 180, 92, 93, 94, 95, 352, 97, 351, 199, 195, 198, 321, 262, 263, 264, 265, 339, 251, 250, 340, 219, 266, 267, 109, 110, 268, 269, 270, 335, 327, 160, 280, 281, 282, 283, 284, 285, 286, 163, 178, 333, 153, 324, 174, 272, 254, 278, 223, 225, 226, 227, 228, 231, 232, 229, 230, 234, 273, 233, 236, 240, 237, 238, 274, 239, 342, 320, 319, 318, 317, 316, 315, 98, 99, 345, 346, 336, 341, 337, 166, 338, 167, 242, 243, 244, 245, 350, 349, 247]
  # if !book_ids.include? book.id
     if @cdn.empty?
       return get_book_url(book)
     else
       return @cdn.first.cdn_ip+get_book_path(book)+"?edutor_id=#{user.edutorid}"
     end 
   #else
   #  return nil
  # end
 end

end
