class IbooksController < ApplicationController
  authorize_resource :only => [:edit, :index, :new, :show]
  skip_before_filter :authenticate_user!, :only=>[:get_ibook_cover_image_url]

  # GET /ibooks
  # GET /ibooks.json

  def index
    @ibook = Ibook.new
    #current user is publisher
    if (current_user && current_user.is?("ECP"))
      @ibooks = current_user.ibooks.desc
      @ipacks = current_user.ipacks
    else
      # This will be the books info hash provided as a response to api call for the user's books
      edutorid = params["edutorid"]
      @ibooks = User.where(:edutorid => edutorid).first.license_sets.map { |ls| ls.ipack.ibooks }.flatten.compact
    end
    respond_to do |format|
      format.html
      # This will be response to API call for the user's books
      format.json { render json: @ibooks.map { |ibook| ibook.book_info_for_user } }
    end
  end

  # GET /ibooks/1
  # GET /ibooks/1.json
  def show
    @ibook = Ibook.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ibook }
    end
  end

  # GET /ibooks/new
  # GET /ibooks/new.json
  def new
    @ibook = Ibook.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ibook }
    end
  end

  # GET /ibooks/1/edit
  def edit
    @ibook = Ibook.find(params[:id])
  end

  def edit_info
    @ibook = Ibook.find(params[:id])
  end

  # POST /ibooks
  # POST /ibooks.json
  def create
    @ibook = Ibook.new(params[:ibook])

    respond_to do |format|
      if @ibook.save
        format.html { redirect_to ibooks_url, notice: 'Book was successfully created.' }
        format.json { render json: @ibook, status: :created, location: @ibook }
      else
        format.html { redirect_to :back, notice: "Unable to create a book.#{@ibook.errors.full_messages}" }
        format.json { render json: @ibook.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /ibooks/1
  # PUT /ibooks/1.json
  def update
    @ibook = Ibook.find(params[:id])
    # This method is only used to upload encrypted content later.
    respond_to do |format|
      if @ibook.update_attributes({:encrypted_content => params[:ibook][:encrypted_content]})
        format.html { redirect_to ibooks_url, notice: 'Ibook was successfully updated.' }
        format.json { head :ok }
      else
        format.html { redirect_to :back, notice: "Unable to update book.#{@ibook.errors.full_messages}" }
        format.json { render json: @ibook.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ibooks/1
  # DELETE /ibooks/1.json
  def destroy
    @ibook = Ibook.find(params[:id])
    @ibook.destroy

    respond_to do |format|
      format.html { redirect_to ibooks_url }
      format.json { head :ok }
    end
  end

  def update_info
    @ibook = Ibook.find(params[:id])
    begin
      # Update info file with new info file
      if @ibook.update_attribute(:info_file,params[:ibook][:info_file])
        @ibook.update_info
        user_ids = ContentAccessPermission.where(:accessed_content_guid=>@ibook.ibook_id).pluck(:user_id)
        User.where(id:user_ids).update_all(:last_content_purchased=>Time.now.to_i)
        redirect_to ibooks_url, notice: 'Successfully updated.' 
      else
        redirect_to :back, notice: "Unable to update book.#{@ibook.errors.full_messages}" 
      end
    rescue Exception=>e 
      redirect_to :back, notice: "Unable to update book.#{e.backtrace.join('\n')}" 
    end
  end

  def user_ibooks
    if params[:format] == 'json'
      user_id = params[:user_id]
      #@ibooks = User.find(user_id).license_sets.map { |ls| ls.ipack.ibooks }.uniq.flatten.compact
      #TODO for supporting store purchased books in 5.0 combining the license set books and store purchased books
      @books = User.find(user_id).license_sets.map { |ls| ls.ipack.ibooks }.uniq.flatten.compact.map{|i| i.ibook_id}
      @accessed_content = ContentAccessPermission.get_latest_records(user_id)
      @accessed_content_course =  @accessed_content.select{|ai| ai.accessed_content_type=='course' }.map{|i|i.accessed_content_guid}
      @accessed_content_course_books = Course.where(guid:@accessed_content_course).map{|i|i.ibooks.pluck(:ibook_id)}.uniq.flatten.compact
      @accessed_content_books = @accessed_content.select{|ai| ai.accessed_content_type=='book' }.map{|i|i.accessed_content_guid}
      @ibooks = Ibook.where(:ibook_id=>[@books+@accessed_content_books+@accessed_content_course_books].uniq)
    end
    respond_to do |format|
      format.json { render json: @ibooks.map { |ibook| ibook.book_info_for_user } }
    end
  end

  def ibook_info
    if params[:format] == 'json'
      book_id = params[:book_id]
      user_id = params[:user_id]
      user = User.find(user_id)
      @ibook = Ibook.where(ibook_id: book_id).last
      @license_sets = user.license_sets.select { |ls| ls.ipack.ibook_ids.include?(@ibook.id) }
      if @license_sets.present?
        starts = @license_sets.last.starts
        ends = @license_sets.last.ends
      end
      #TODO dynamically give license start and end dates and update JSON below. For that we also require user id in the request
      book_info_full = @ibook.book_info_full
      @cdn = user.center.cdn_configs
      # if @cdn.present?
      #   book_info_full[:book_url] = "#{@cdn.first.cdn_ip}/#{@ibook.get_ibook_url}?edutor_id=#{user.edutorid}"
      # end
      if @license_sets.present?
        book_info_full[:book_start_date] = starts
        book_info_full[:book_end_date] = ends
      end
      #TODO for supporting store purchased books in 5.0 starts and ends dates getting from content access permission
      @content_access = ContentAccessPermission.where(:user_id=>user_id,:accessed_content_guid=>book_id)
      if !@content_access.empty?
        book_info_full[:book_start_date] = @content_access.order("starts ASC").first.starts
        book_info_full[:book_end_date] = @content_access.order("ends DESC").first.ends
      end

    end
    respond_to do |format|

      format.json { render json: book_info_full }
    end
  end

  def get_ibook
    @ibook =  Ibook.where("id = ? or ibook_id = ?",params[:id],params[:id])
    if @ibook.empty?
      render nothing:true, status:404,layout:false
      return
    else
      @ibook = @ibook.first
    end
    if @ibook.encrypted_content.present?
    response.header["Accept-Ranges"] = "bytes"
    send_file @ibook.encrypted_content.path, :disposition => 'inline', :type => "application/octet-stream", :x_sendfile => true
    else
    render nothing:true, status:404,layout:false
  return
    end
  end

  def get_ibook_info_file
    @ibook =  Ibook.where("id = ? or ibook_id = ?",params[:id],params[:id])
    if @ibook.empty?
      render nothing:true, status:404,layout:false
      return
    else
     @ibook = @ibook.first
    end
    if @ibook.info_file.present?
      response.header["Accept-Ranges"] = "bytes"
      send_file @ibook.info_file.path, :disposition => 'inline', :type => "application/octet-stream", :x_sendfile => true
    else
      render nothing:true, status:404,layout:false
      return
    end
  end

  def get_ibook_toc
    @ibook = Ibook.find(params["book_id"])
    @toc_tree = @ibook.get_toc_tree
    @new_book = @ibook.toc_items.present?
    @latest_toc_tree = @new_book ? @ibook.toc_items.where("content_type not like?","live-page") : []
    @chapter_arr = []
    @topic_arr ={}
    @sub_arr ={}
    @controller = self.class.to_s
    @class_type =[["Animation","animation"],["Textbook","text-book"],["Assessment","assessment-quiz"],["Concept Map", "concept-map"], ["Audio", "audio"], ["Video", "video-lecture"]]
    # "topic,chapter,animation,assessmentpracticetests,assessmentiittests,textbook,tsp,assessmentquiz,weblink,conceptmap,homework,activity,audio,glossary,question,videolecture,imagegallery,powerpoint,summary,knowdiscovery,learnobjectives,additionalresource,worksheet"
    @toc_tree["chapters"].each do |chapter|
      topic_hash = {}
      if @new_book
        chapter_info = @latest_toc_tree.where(uri:chapter["uri"]).first
        @chapter_arr << [chapter["name"], chapter["uri"], chapter_info.guid, chapter_info.parent_guid]
      else
        @chapter_arr << [chapter["name"], chapter["uri"]]
      end
      if chapter["topics"].present?
        chapter["topics"].each do |topic|
          sub_hash = {}
          if @new_book
            topic_info = @latest_toc_tree.where(uri:"#{topic["uri"]}").first
            topic_hash["#{topic["name"]}"] = "#{topic["uri"]}" "$" "#{topic_info.guid}" "$" "#{topic_info.parent_guid}"
          else
            topic_hash["#{topic["name"]}"] = "#{topic["uri"]}"
          end

          if topic["sub-topics"].present?
            topic["sub-topics"].each do |sub|
              if @new_book
                sub_topic_info = @latest_toc_tree.where(uri:"#{sub["uri"]}").first
                # binding.pry if sub_topic_info.nil?

                sub_hash["#{sub["name"]}"] = "#{sub["uri"]}" "$" "#{sub_topic_info.guid}" "$" "#{sub_topic_info.parent_guid}"
                # sub_hash["#{sub["name"]}"] = "#{sub["uri"]}"
              else
                sub_hash["#{sub["name"]}"] = "#{sub["uri"]}"
              end

            end

          end
          @sub_arr["#{topic["name"]}"] = sub_hash
        end
        @topic_arr["#{chapter["name"]}"] = topic_hash
      end
    end
    respond_to do |format|
      format.js
      format.json
    end
  end

  def latest_toc
    @ibook = Ibook.last
    latest_toc_tree = @ibook.build_toc
    render json: latest_toc_tree , status: :ok
  end

  def get_csv_book_list
    csv_data = Ibook.csv_book_list(current_user)
    send_data csv_data, type: "text/csv; charset=UTF-8;", :disposition => "attachment;filename=PublisherBooks#{Time.now.to_i}.csv"
  end

  def get_ibook_cover_image_url
    ibook = Ibook.find_by_ibook_id(params[:id])
    if ibook.present?
      redirect_to "/ibook_public/#{ibook.id}/"+"cover.png"
    else
      render nothing:true, status:404,layout:false
    end
  end

  def get_book_extended_details
    @ibook = Ibook.find(params[:id])
  end

end
