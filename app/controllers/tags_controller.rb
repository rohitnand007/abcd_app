class TagsController < ApplicationController
  require 'redis_interact'
  authorize_resource
  # GET /tags
  # GET /tags.json
  def index
    require "DataTable"
    #@tags = Tag.order("name ASC")
    if request.xhr?
      data = DataTable.new()
      searchParams = params[:sSearch].present? ? params[:sSearch]:nil
      data.setParams(params[:sEcho], searchParams, params[:iDisplayStart], params[:iDisplayLength], Tag.count)
      tags = Tag.unscoped.where(standard: true).where('name like :search or value like :search', search: "%#{searchParams}%").order("created_at desc")
      total_tags= tags.count
      tags = tags.page(data.page).per(data.per_page)
      data.set_total_records(total_tags)
      #Sorting Records
      columns = ["name", "value"]
      if(params[:iSortCol_0].present?)
        column = columns[params[:iSortCol_0].to_i]
        direction = (params[:sSortDir_0] == "desc") ? "desc" : "asc"
        tags = tags.order("lower(#{column})" +" "+  direction)
      end
      tags.map!.with_index do |tag, index|
        row_class = index%2==1 ? "tr-odd" : "tr-even"
        {
          "DT_RowId" => "tag_#{tag.id}",
          "DT_ClassId" => row_class,
          "0" => tag.proper_name,
          "1" => tag.value,
          # "2" => tag.questions.count,
          "2" => tag.tags_db.db_name #view_context.link_to('Manage', edit_tag_path(tag))
        }
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      if request.xhr?
        format.json { render json: data.as_json(tags)}
      else
        format.json { render json: @tags }
      end
      format.json { render json: @tags }
    end
  end

  def old_tags
    require "DataTable"
    #@tags = Tag.order("name ASC")
    if request.xhr?
      data = DataTable.new()
      searchParams = params[:sSearch].present? ? params[:sSearch]:nil
      data.setParams(params[:sEcho], searchParams, params[:iDisplayStart], params[:iDisplayLength], Tag.count)
      tags = Tag.unscoped.where(standard: false).where('name like :search or value like :search', search: "%#{searchParams}%").order("created_at desc")
      total_tags= tags.count
      tags = tags.page(data.page).per(data.per_page)
      data.set_total_records(total_tags)
      #Sorting Records
      columns = ["name", "value"]
      if(params[:iSortCol_0].present?)
        column = columns[params[:iSortCol_0].to_i]
        direction = (params[:sSortDir_0] == "desc") ? "desc" : "asc"
        tags = tags.order("lower(#{column})" +" "+  direction)
      end
      tags.map!.with_index do |tag, index|
        row_class = index%2==1 ? "tr-odd" : "tr-even"
        {
          "DT_RowId" => "tag_#{tag.id}",
          "DT_ClassId" => row_class,
          "0" => tag.proper_name,
          "1" => tag.value,
          "2" => tag.questions.count,
          "3" => view_context.link_to('Manage', edit_tag_path(tag))
        }
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      if request.xhr?
        format.json { render json: data.as_json(tags)}
      else
        format.json { render json: @tags }
      end
      format.json { render json: @tags }
    end
  end

  def publisher_tags
    @publisher_question_bank_id = 1
    @publisher_tags = TagReference.where(:publisher_question_bank_id => 1).collect(&:tag_id)
    @question_tags = Hash.new{|h,k| h[k] = Array.new }
    @tags = Tag.find(@publisher_tags)#.order("name ASC")
    @tags.each do |tag|
      if ["course","subject","difficulty_level","chapter","academic_class"].include? tag.name
        @question_tags[tag.name] = [[tag.id,tag.value]]
      elsif ["blooms_taxonomy","concept_names","specialCategory"].include? tag.name
        @question_tags[tag.name].push([tag.id,tag.value])
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tags }
    end
  end
  # GET /tags/1
  # GET /tags/1.json
  def show
    @tag = Tag.find(params[:id])
    @tagrefs = @tag.tag_references
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tag }
    end
  end

  # GET /tags/new
  # GET /tags/new.json
  def new
    @tag = Tag.new
    @tags_dbs = TagsDb.all
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tag }
    end
  end

  # GET /tags/1/edit
  def edit
    @tag = Tag.find(params[:id])
    if @tag.standard
      redirect_to tags_path
      return
    end
    @publisher_question_banks = []
    if current_user.rc=="EA"
      @publisher_question_banks = PublisherQuestionBank.all
    elsif current_user.rc=="IA"
      @publisher_question_banks = current_user.institution.publisher_question_banks
    elsif current_user.rc=="ECP"
      @publisher_question_banks = current_user.publisher_question_banks
    end
  end

  # POST /tags
  # POST /tags.json
  def create
    @tag = Tag.new(params[:tag])
    @tag.standard = true
    @old_tag = Tag.where(name: params[:tag][:name], value: params[:tag][:value], tags_db_id: params[:tag][:tags_db_id])
    respond_to do |format|
      if @old_tag.count > 0
        format.html { redirect_to @old_tag.first, notice: 'Tag already exists.' }
        format.json { render json: @old_tag.first, status: :exits, location: @old_tag.first }
      elsif @tag.save
        format.html { redirect_to @tag, notice: 'Tag was successfully created.' }
        format.json { render json: @tag, status: :created, location: @tag }
      else
        format.html { render action: "new" }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tags/1
  # PUT /tags/1.json
  def update
    @tag = Tag.find(params[:id])
    @qb_id = params[:user][:question_bank_id]
    @target_tag = Tag.find_or_create_by_name_and_value(params[:tag]["name"], params[:tag]["value"])
    if (@qb_id.present? && @tag.id!=@target_tag.id)
      replace_given_tag_with_target_tag_for_qb(@qb_id, @tag.id, @target_tag.id)
      respond_to do |format|
        format.html { redirect_to @target_tag, notice: 'Tag was successfully updated.' }
        format.json { head :ok }
      end
    elsif (@qb_id.present? && @tag.id==@target_tag.id)
      @target_tag.update_attribute(:value, params[:tag]["value"])
      t = RedisInteract::Plumbing.new
      t.update_tag_details(@target_tag.id, @target_tag.value)
      respond_to do |format|
        format.html { redirect_to @target_tag, notice: 'Found a same tag and it was successfully updated.' }
        format.json { head :ok }
        end
      else
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Either no question bank was specified or the given and target tags are same.' }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  def replace_given_tag_with_target_tag_for_qb(qb_id, given_tag_id, target_tag_id)

    relevant_question_ids = PublisherQuestionBank.find(qb_id).question_ids

    relevant_taggings = Tagging.where(tag_id: given_tag_id, question_id: relevant_question_ids)
    relevant_taggings.update_all(tag_id: target_tag_id) if relevant_taggings.present?

    try_merging_given_tag_with_target_tag_on_redis_db_for_qb(qb_id, given_tag_id, target_tag_id)

    relevant_parent_tag_references = TagReference.where(tag_id: given_tag_id, publisher_question_bank_id: qb_id)
    relevant_parent_tag_references.update_all(tag_id: target_tag_id) if relevant_parent_tag_references.present?

    relevant_child_tag_references = TagReference.where(tag_refer_id: given_tag_id, publisher_question_bank_id: qb_id)
    relevant_child_tag_references.update_all(tag_refer_id: target_tag_id) if relevant_child_tag_references.present?

  end


  # DELETE /tags/1
  # DELETE /tags/1.json
  def destroy
    @tag = Tag.find(params[:id])
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to tags_url }
      format.json { head :ok }
    end
  end

  def csv_upload_interface
  end

  def create_csv_upload
    #csv columns::0:Academic_class, 1:subject, 2:term, 3:chap no, 4:chapter, 5:concept_name ## we use only 0,1,5 columns here
    transaction_successful = false
    begin
      notice_message = ""
      ActiveRecord::Base.transaction do
        CSV.parse(params[:file].read, :headers => true, :col_sep => ',') do |row|
          #find tags db
          db = TagsDb.last
          # tag_category = row[1].lstrip.rstrip
          #tag_category names as t_c_name
            t_c_class = "academic_class"
            t_c_subject = "subject"
            t_c_concept = "concept_name"
          #tag_values entries as t_v_value
          t_v_class = row[0].lstrip.rstrip
          t_v_subject = row[1].lstrip.rstrip
          # t_v_concept = row[5].lstrip.rstrip

          Tag.find_or_create_by_name_and_value_and_tags_db_id_and_standard(t_c_class, t_v_class, db.id, true)
          Tag.find_or_create_by_name_and_value_and_tags_db_id_and_standard(t_c_subject, t_v_subject, db.id, true)
          # Tag.find_or_create_by_name_and_value_and_tags_db_id_and_standard(t_c_concept, t_v_concept, db.id, true)
        end
        transaction_successful = true
      end
    rescue Exception => e
      logger.info "....................#{e}....................."
    end

    notice_message = transaction_successful ? "Tags added successfully." : "Please check the csv file."
    redirect_to "/tags/csv_upload_interface", notice: notice_message

  end
  def create_csv_upload_old
    #csv columns:: 0:tags_db_name, 1:tags_category, 2:tags_value
    transaction_successful = false
    begin
      notice_message = ""
      ActiveRecord::Base.transaction do
        CSV.parse(params[:file].read, :headers => true, :col_sep => ',') do |row|
          #find tags db
          db = TagsDb.find_by_db_name(row[0].lstrip.rstrip)
          tag_category = row[1].lstrip.rstrip
          if tag_category == "Academic Class"
            t_c = "academic_class"
          elsif tag_category == "Subject"
            t_c = "subject"
          elsif tag_category == "Concept"
            t_c = "concept_name"
          else
            notice_message = "Tag Category not found."
            raise ActiveRecord::Rollback
          end
          tag_value = row[2].lstrip.rstrip
          Tag.create(name: t_c, value: tag_value, standard: true, tags_db_id: db.id)
        end
        transaction_successful = true
      end
    rescue Exception => e
      logger.info "....................#{e}....................."
    end

    notice_message = transaction_successful ? "Tags added successfully." : "Please check the csv file."
    redirect_to "/tags/csv_upload_interface", notice: notice_message

  end

  def download_template
    send_file Rails.root.to_s+"/public/templates/tags_csv_template.csv",:type=>"application/octet-stream",:x_sendfile=>true
  end

  def my_class_subject_tags
    user_id = current_user.id
    tags = Tag.user_tags(user_id)
    respond_to do |format|
        format.json { render json: {academic_class_tags: tags['class_tags'].present? ? tags['class_tags'].map(&:value) : [], subject_tags: tags['subject_tags'].present? ? tags['subject_tags'].map(&:value) : []} }
    end
  end

  def try_updating_tag_everywhere_on_redis_db(tg_id)
    p = RedisInteract::Plumbing.new
    begin
      p.update_tag_everywhere(tg_id, name, value)
    rescue Exception => e
      logger.info "....................#{e}....................."
    end
  end

  def try_merging_given_tag_with_target_tag_on_redis_db(given_tag_id, target_tag_id)
    # Given tag is the one which needs to be deleted.
    # Target tag is the one which is going to replace given tag in database.
    p = RedisInteract::Plumbing.new
    begin
      p.merge_given_tag_with_target_tag(given_tag_id, target_tag_id)
    rescue Exception => e
      logger.info "....................#{e}....................."
    end
  end

  def try_merging_given_tag_with_target_tag_on_redis_db_for_qb(qb_id, given_tag_id, target_tag_id)
    p = RedisInteract::Plumbing.new
    begin
      p.merge_given_tag_with_target_tag_for_given_qb(qb_id, given_tag_id, target_tag_id)
    rescue Exception => e
      logger.info "....................#{e}....................."
    end
  end

end
