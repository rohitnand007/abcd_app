class CollectionsController < ApplicationController
  authorize_resource :only=>[:edit, :index, :new, :show, :assign_collection, :pearson_user_collection_form ]
  # GET /collections
  # GET /collections.json
  def index
    @collections = Collection.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @collections }
    end
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
    @collection = Collection.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @collection }
    end
  end

  # GET /collections/new
  # GET /collections/new.json
  def new
    @collection = Collection.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @collection }
    end
  end

  # GET /collections/1/edit
  def edit
    @collection = Collection.find(params[:id])
  end

  # POST /collections
  # POST /collections.json
  def create
    @collection = Collection.new(params[:collection])
    @books = params[:collection][:collection_books].split(',')
    respond_to do |format|
      if @collection.save
        @collection.book_ids = @books
        format.html { redirect_to @collection, notice: 'Collection was successfully created.' }
        format.json { render json: @collection, status: :created, location: @collection }
      else
        format.html { render action: "new" }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /collections/1
  # PUT /collections/1.json
  def update
    @collection = Collection.find(params[:id])
    @books = params[:collection][:collection_books].split(',')
    respond_to do |format|
      if @collection.update_attributes(params[:collection])
        @collection.book_ids = @books
        format.html { redirect_to @collection, notice: 'Collection was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /collections/1
  # DELETE /collections/1.json
  def destroy
    @collection = Collection.find(params[:id])
    @collection.destroy

    respond_to do |format|
      format.html { redirect_to collections_url }
      format.json { head :ok }
    end
  end


#Assign a collection to a group or individual
  def assign_collection
    @books = Book.order('id desc')
    @user_book_collection = UserBookCollection.new
    if request.xhr?
      logger.info"==========#{params[:id]}"
      @books = Book.includes(:book_collections).where("book_collections.collection_id=#{params[:id]}")
    end
  end

  def filter_collection
    @books = Book.includes(:book_collections).where("book_collections.collection_id=#{params[:id]}")
  end


  def save_assign_collection
    #@user_collection = UserBookCollection.new(params[:user_book_collection])
    @multiple_user_ids = params[:user_book_collection][:multiple_user_ids].split(',')
    begin
      if params[:user_book_collection][:multiple_user_ids].empty?
        #@user_collection.save
        UserBookCollection.transaction do
          UserGroup.joins(:user).includes(:user).select(:user_id).where(:group_id=>params[:user_book_collection][:user_id]).each do |user|
            UserBookCollection.create(:collection_id=>params[:user_book_collection][:collection_id],:user_id=>user.user_id)
          end
        end
      else
        @multiple_user_ids.each do |u|
          UserBookCollection.create(:collection_id=>params[:user_book_collection][:collection_id],:user_id=>u)
        end
      end
    rescue  Exception => e
      flash[:error] = "Something went wrong.#{e.message}"
      redirect_to :back
    end
    redirect_to collections_url
  end

  def show_user_collection

  end

  def delete_user_collection
    @collection = UserBookCollection.where(:user_id=>params[:user_id],:collection_id=>params[:collection_id])
    @collection.destroy_all
    redirect_to user_path(params[:user_id])
  end


def pearson_application_update
   user = ActionController::HttpAuthentication::Basic::user_name_and_password(request)    
   @result = {}
   @user = User.find_by_edutorid(user[0]) 
    logger.info"=loggg===#{user}==="
    ignitor = JSON.load(params['IGNITOR'])
    mdm = JSON.load(params['MDM'])
    ignitor_update = false
    mdm_update = false
    apk_file_name1 =  "#{Rails.root}/pearson_apps/com.edutor.edm.samsung.apk"
    apk_file_name2 =  "#{Rails.root}/pearson_apps/com.edutor.ignitorwlite.apk"
    logger.info "======#{mdm}=====#{ignitor}"
#  if [27012,27828,27829,27830,27831,27733,538].include? @user.id
#  if [27828,27829,27831].include? @user.id
#  if [27828,27829,27831,66263,66264,66265,66266,66267,66268,66269,66270,66271,66272].include? @user.id
#if [38939, 38940, 38941, 38942, 38943, 38944, 38945, 38946, 38947, 38948, 38949, 54099, 38951, 38953, 38954, 38955, 38956, 38957, 38958, 38959, 38960, 38961, 38963, 38964, 38965, 38967, 50453, 52649, 54097, 54098, 54017, 66673, 38937].include? @user.id
   if [68845,68846,68847,390,64396,27831,68848,68844].include? @user.id
   logger.info"=in==#{@user.id}========="
    if !mdm.nil?
      if File.extname(apk_file_name1) == '.apk'
        apk1 = Android::Apk.new(apk_file_name1)
        xml_data1 = Nokogiri::XML(apk1.manifest.to_xml)
        @package_name1 = xml_data1.xpath('manifest').attr('package').value
        @share_userid1 = xml_data1.xpath('manifest').attr('sharedUserId').value
        @version_code1 = xml_data1.xpath('manifest').attr('versionCode').value
        #logger.info "For Report 1--- id: #{@user.id} version: #{mdm['versionCode'].to_i} rollno: #{@user.rollno}  mdm_filename#{mdm['file_name']} mdm_share#{mdm['shareduserid']}"
        if mdm['file_name'] == @package_name1 and mdm['shareduserid'] == @share_userid1 and mdm['versionCode'].to_i < @version_code1.to_i
          size = File.size(apk_file_name1)
          hash = Digest::MD5.hexdigest(File.read(apk_file_name1))
          name = apk_file_name1.split("/").last
          @result = @result.merge({:ignitor=>[:file_size=>size,:file_hash=>hash,:file_name=>name,:file_url=>get_pearson_update_url(:id=>name) ]})
          mdm_update = true
        else
          @result = @result.merge(:ignitor=>nil)
        end
      end

    end
    if !ignitor.nil?
      if File.extname(apk_file_name2) == '.apk'
        apk2 = Android::Apk.new(apk_file_name2)
        xml_data2 = Nokogiri::XML(apk2.manifest.to_xml)
        @package_name2 = xml_data2.xpath('manifest').attr('package').value
        @share_userid2 = xml_data2.xpath('manifest').attr('sharedUserId').value
        @version_code2 = xml_data2.xpath('manifest').attr('versionCode').value
        #logger.info "For Report 2--- id: #{@user.id} version: #{mdm['versionCode'].to_i} rollno: #{@user.rollno}  mdm_filename#{mdm['file_name']} mdm_share#{mdm['shareduserid']}"

        if ignitor['pkgName'] == @package_name2 and ignitor['sharedUserId'] == @share_userid2 and ignitor['versionCode'].to_i < @version_code2.to_i
          size = File.size(apk_file_name2)
          hash = Digest::MD5.hexdigest(File.read(apk_file_name2))
          name = apk_file_name2.split("/").last
          @result = @result.merge(:ignitor=>[:file_size=>size,:file_hash=>hash,:file_name=>name,:file_url=>get_pearson_update_url(:id=>name)])
          ignitor_update = true
        else
          @result = @result.merge({:ignitor=>nil})
        end
      end
    end
  end
    respond_to do |format|
      if mdm_update || ignitor_update
        format.json { render json: @result }
      else
        format.json { render json: nil }
      end
    end

  end

  def get_pearson_update
    @name = params[:id]
    response.header["Accept-Ranges"] = "bytes"
    send_file "#{Rails.root.to_s}/pearson_apps/#{@name}" ,:disposition=>'inline',:x_sendfile=>true
  end

def pearson_livepage_update
    @result = {}
    ignitor = JSON.load(params['IGNITOR'])

    ignitor_update = false


    apk_file_name2 =  "#{Rails.root}/pearson_livepage/com.edutor.ignitorwlite.apk"
    logger.info "===========#{ignitor}"

    if !ignitor.nil?
      if File.extname(apk_file_name2) == '.apk'
        apk2 = Android::Apk.new(apk_file_name2)
        xml_data2 = Nokogiri::XML(apk2.manifest.to_xml)
        @package_name2 = xml_data2.xpath('manifest').attr('package').value
        @share_userid2 = xml_data2.xpath('manifest').attr('sharedUserId').value
        @version_code2 = xml_data2.xpath('manifest').attr('versionCode').value

        if ignitor['pkgName'] == @package_name2 and ignitor['sharedUserId'] == @share_userid2 and ignitor['versionCode'].to_i < @version_code2.to_i
          size = File.size(apk_file_name2)
          hash = Digest::MD5.hexdigest(File.read(apk_file_name2))
          name = apk_file_name2.split("/").last
          @result = @result.merge(:ignitor=>[:file_size=>size,:file_hash=>hash,:file_name=>name,:file_url=>get_pearson_livepage_update_url(:id=>name)])
          ignitor_update = true
        else
          @result = @result.merge({:ignitor=>nil})
        end
      end
    end
    respond_to do |format|
      if ignitor_update
        format.json { render json: @result }
      else
        format.json { render json: nil }
      end
    end

  end


  def get_pearson_livepage_update
    @name = params[:id]
     response.header["Accept-Ranges"] = "bytes"
    send_file "#{Rails.root.to_s}/pearson_livepage/#{@name}" ,:disposition=>'inline',:x_sendfile=>true
  end

   # Pearson user book_collection upload
  def pearson_user_collection_form

  end

  # process pearson bulk user book collection csv upload
  def user_book_collection_upload
    if request.post? && params[:csv_file].present?
      infile = params[:csv_file].read
      n, errs = 0, []
      CSV.parse(infile) do |row|
        n += 1
        if n == 1 or row.join.blank?
          @header = row
          next
        end
        @user = User.find_by_rollno(row[0])
        if @user
          @book_db = BookKey.find_by_attachment_file_name(row[1])

          if @book_db
            @book = Book.find_by_id(@book_db.book_id)
            if @book
              @collection = Collection.find_by_name(@book.book_asset.attachment_file_name.gsub(".epub",""))
              if @collection.nil?
                @collection = Collection.create(:name=>@book.book_asset.attachment_file_name.gsub(".epub",""))
              end
              if !@collection.book_ids.include?(@book.id)
                BookCollection.create(:collection_id=>@collection.id,:book_id=>@book.id)
              end
              @is_ubc = UserBookCollection.where(:collection_id=>@collection.id,:user_id=>@user.id)
              if @is_ubc.empty?
                UserBookCollection.create(:collection_id=>@collection.id,:user_id=>@user.id)
              end
            else
              errs << ["Book not found",row]
            end
          else
            errs << ["DB not found",row]
          end
        else
          errs << ["User not found",row]
        end
      end
      if errs.any?
        errFile ="errors_#{Date.today.strftime('%d%b%y')}.csv"
        errs.insert(0, @header)
        errCSV = CSV.generate do |csv|
          errs.each {|row| csv << row}
        end
        send_data errCSV,
                  :type => 'text/csv; charset=iso-8859-1; header=present',
                  :disposition => "attachment; filename=#{errFile}.csv"
      else
        flash[:notice] = 'User collection added Successfully'
        redirect_to collections_path
      end
    else
      flash[:error] = 'Please upload file'
      redirect_to pearson_user_collection_form_path
    end

  end


  # upload Pearson user book collection
  def upload_pearson_user_collection_form

  end

  def upload_user_book_collection
    if request.post? && params[:csv_file].present?
      infile = params[:csv_file].read
      n, errs , usr = 0, [], []
      CSV.parse(infile) do |row|
        n += 1
        if n == 1 or row.join.blank?
          @header = row
          next
        end
        @user = User.find_by_rollno(row[0])
        if @user
	  if !usr.include? @user.id
            UserBookCollection.where(:user_id=>@user.id).destroy_all
	    usr << @user.id
	  end
          @book_db = BookKey.find_by_attachment_file_name(row[1])

          if @book_db
            @book = Book.find_by_id(@book_db.book_id)
            if @book
              @collection = Collection.find_by_name(@book.book_asset.attachment_file_name.gsub(".epub",""))
              if @collection.nil?
                @collection = Collection.create(:name=>@book.book_asset.attachment_file_name.gsub(".epub",""))
              end
              if !@collection.book_ids.include?(@book.id)
                BookCollection.create(:collection_id=>@collection.id,:book_id=>@book.id)
              end
	      @is_ubc = UserBookCollection.where(:collection_id=>@collection.id,:user_id=>@user.id)
              if @is_ubc.empty?
                UserBookCollection.create(:collection_id=>@collection.id,:user_id=>@user.id)
              end
            else
              errs << ["Book not found",row]
            end
          else
            errs << ["DB not found",row]
          end
        else
          errs << ["User not found",row]
        end
      end
      if errs.any?
        errFile ="errors_#{Date.today.strftime('%d%b%y')}.csv"
        errs.insert(0, @header)
        errCSV = CSV.generate do |csv|
          errs.each {|row| csv << row}
        end
        send_data errCSV,
                  :type => 'text/csv; charset=iso-8859-1; header=present',
                  :disposition => "attachment; filename=#{errFile}.csv"
      else
        flash[:notice] = 'User collection added Successfully'
        redirect_to collections_path
      end
    else
      flash[:error] = 'Please upload file'
      redirect_to upload_pearson_user_collection_form_path
    end

  end


end
