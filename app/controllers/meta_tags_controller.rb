class MetaTagsController < ApplicationController
	authorize_resource
	def index
		require "DataTable"
	    #@tags = Tag.order("name ASC")
	    if request.xhr?
	      data = DataTable.new()
	      searchParams = params[:sSearch].present? ? params[:sSearch]:nil
	      data.setParams(params[:sEcho], searchParams, params[:iDisplayStart], params[:iDisplayLength], MetaTag.count)
	      meta_tags = MetaTag.includes(:class_tag, :subject_tag, :concept_tag)
	      meta_tags = meta_tags.where("tags.value like :search or subject_tags_meta_tags.value like :search or concept_tags_meta_tags.value like :search", search: "%#{searchParams}%")
	      # meta_tags = meta_tags.where("subject_tags_meta_tags.value like :search", search: "%#{searchParams}%")
	      # meta_tags = meta_tags.where("concept_tags_meta_tags.value like :search", search: "%#{searchParams}%")
	      total_tags= meta_tags.count
	      meta_tags = meta_tags.page(data.page).per(data.per_page)
	      data.set_total_records(total_tags)
	      #Sorting Records
	      columns = ["class_id", "subject_id", "concept_id", "tags_db_id"]
	      if(params[:iSortCol_0].present?)
	        column = columns[params[:iSortCol_0].to_i]
	        direction = (params[:sSortDir_0] == "desc") ? "desc" : "asc"
	        meta_tags = meta_tags.order("lower(#{column})" +" "+  direction)
	      end
	      meta_tags.map!.with_index do |meta_tag, index|
	        row_class = index%2==1 ? "tr-odd" : "tr-even"
	        {
	          "DT_RowId" => "tag_#{meta_tag.id}",
	          "DT_ClassId" => row_class,
	          "0" => meta_tag.class_tag.value,
	          "1" => meta_tag.subject_tag.value,
	          "2" => meta_tag.concept_tag.value,
	          "3" => meta_tag.user.present? ? meta_tag.user.name : "",
	          "4" => view_context.link_to('Manage', edit_meta_tag_path(meta_tag))
	        }
	      end
	    end
	    respond_to do |format|
	      format.html # index.html.erb
	      if request.xhr?
	        format.json { render json: data.as_json(meta_tags)}
	      else
	        format.json { render json: @tags }
	      end
	      format.json { render json: @tags }
	    end
	end

	def new
		@class_tags = Tag.where(name: 'academic_class')
		@subject_tags = Tag.where(name: 'subject')
		@concept_tags = Tag.where(name: 'concept_name')
		@meta_tag = MetaTag.new
	end

	def edit
		@meta_tag = MetaTag.find(params[:id])
		@class_tags = Tag.where(name: 'academic_class')
		@subject_tags = Tag.where(name: 'subject')
		@concept_tags = Tag.where(name: 'concept_name')
	end

	def show
		@meta_tag = MetaTag.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @meta_tag }
    end
	end

	def create
		class_tags = params[:meta_tags][:s_class]
		subject_tags = params[:meta_tags][:subject]
		concepts = params[:concept_tags]
		user_id = params[:user_id]
		tags_saved = true
		logger.info "concept_tags"
		if User.where(id: user_id).present?
			begin
				class_tags.each do |class_tag|
					cl_tag = Tag.find(class_tag)
					subject_tags.each do |subject_tag|
					su_tag = Tag.find(subject_tag)
						concepts.split(";").each do |concept_tag|
							co_tag = Tag.find_or_create_by_name_and_value("concept_name", concept_tag)
							MetaTag.create(class_id: cl_tag.id, subject_id: su_tag.id, concept_id: co_tag.id, user_id: user_id)
						end
					end
				end
			rescue Exception => e 
				tags_saved = false
			end
		else
			tags_saved = false
			notice_message = "Check the enetered values."
		end
	    respond_to do |format|
	      if tags_saved
	        # format.html { redirect_to @meta_tag, notice: 'Meta Tag was successfully created.' }
	        format.json { render json: {tags_added: true}, status: :created }
	      else
	        # format.html { render action: "new" }
	        format.json { render json: {tags_added: false, message: notice_message}}
	      end
	    end
	end

	def destroy

	end

	def my_tags
		tags_db = UsersTagsDb.find_by_user_id(current_user.id).tags_db
		relevant_tags = Array.new
		meta_tags = MetaTag.where(tags_db_id: tags_db.id)
		meta_tags = meta_tags.where(class_id: params[:s_class]) if params[:s_class].present?
		meta_tags = meta_tags.where(subject_id: params[:subject]) if params[:subject].present?
		meta_tags = meta_tags.includes(:concept_tag)
		meta_tags.each {|m| relevant_tags.push(m.concept_tag.value) if relevant_tags.index(m.concept_tag.value).nil? }
		respond_to do |format|
			format.json { render json: relevant_tags}
		end
	end

	def update
		@meta_tag_id = params[:id]
		@meta_tag = MetaTag.find(params[:id])
		@meta_tag.class_id = params[:meta_tag][:class_id]
		@meta_tag.subject_id = params[:meta_tag][:subject_id]
		@meta_tag.concept_id = params[:meta_tag][:concept_id]
		@meta_tag.user_id = params[:meta_tag][:user_id]

		@class_tags = Tag.where(name: 'academic_class')
		@subject_tags = Tag.where(name: 'subject')
		@concept_tags = Tag.where(name: 'concept_name')
		respond_to do |format|
	      if @meta_tag.save
	        format.html { redirect_to @meta_tag, notice: 'Meta Tag was successfully updated' }
	        format.json { render json: @meta_tag, status: :created, location: @meta_tag }
	      else
	        format.html { render action: "new" }
	        format.json { render json: @meta_tag.errors, status: :unprocessable_entity }
	      end
    	end
	end

	def get_tags_lpc
		tags_db = UsersTagsDb.find_by_user_id(current_user.id).tags_db
		@meta_tags = MetaTag.where(tags_db_id: tags_db.id).includes(:class_tag, :subject_tag, :concept_tag)
		@class_tags = @meta_tags.where("class_id is not null").select('class_id').uniq
		@subject_tags = @meta_tags.where("subject_id is not null").select('subject_id').uniq
		@concept_tags = []
	end

	def tags_csv_upload_interface
	end

	def create_tags_csv
		transaction_successful = false
			ActiveRecord::Base.transaction do 
				CSV.parse(params[:file].read, :headers => true, :col_sep => ',') do |row|
						#0: concept_name, 1: subjects, 2: classes, 3: user_id
						concept_tags = []
						subject_tags = []
						class_tags = []
						concepts = row[0].split(";")
						subjects = row[1].split(";")
						classes = row[2].split(";")
						user_id = row[3]
						concepts.each do |concept|
							concept_tags << Tag.find_or_create_by_name_and_value("concept_name", concept.rstrip.lstrip)
						end
						subjects.each do |subject|
							subject_tags << Tag.find_or_create_by_name_and_value("subject", subject.rstrip.lstrip)
						end
						classes.each do |a_class|
							class_tags << Tag.find_or_create_by_name_and_value("academic_class", a_class.rstrip.lstrip)
						end
						concept_tags.each do |co_tag|
							subject_tags.each do |su_tag|
								class_tags.each do |cl_tag|
									MetaTag.create(class_id: cl_tag.id, subject_id: su_tag.id, concept_id: co_tag.id, user_id: user_id)
								end
							end
						end
			  end
			  transaction_successful = true
			end

		notice_message = transaction_successful ? "Tags assigned successfully." : "Please check the csv file."
		redirect_to "/meta_tags/tags_csv_upload_interface", notice: notice_message
	end
end