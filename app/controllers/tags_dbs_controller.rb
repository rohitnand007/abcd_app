class TagsDbsController < ApplicationController
	authorize_resource
	def index
		@dbs = TagsDb.all
	end

	def new

	end

	def create

	end

	def edit

	end

	def update

	end

	def update_users
		db = TagsDb.find(params[:id])
		if params[:tags_db].present? && params[:tags_db][:user_ids].present?
			user_ids = params[:tags_db][:user_ids]
			updated_users = User.where(id: user_ids)
			# db.users = updated_users
			user_ids.each do |user_id|
				u = User.find(user_id)
				u.set_tags_db(db.id)
			end
		else
			db.users = []
		end
		message = "Users updated."
		redirect_to tags_dbs_path, notice: message
	end

	def update_tags
		updated = false
		begin
			db_id = params[:id]
			tags_info = params[:tags_info]
			tags_info.each do |i,t|
				concept_id = t[:id]
				updated_academic_classes = t[:academic_class]
				updated_subjects = t[:subject]
				updated_academic_class_ids = Tag.where(name: 'academic_class', tags_db_id: db_id, value: updated_academic_classes).map(&:id)
				updated_subject_ids = Tag.where(name: 'subject', tags_db_id: db_id, value: updated_subjects).map(&:id)
				#find old tag_ids
				m = MetaTag.where(tags_db_id: db_id, concept_id: concept_id)
				old_academic_class_ids = m.map(&:class_id).uniq
				old_subject_ids = m.map(&:subject_id).uniq
				#find academic_classes to be removed
				del_ac = old_academic_class_ids - updated_academic_class_ids
				del_tags = m.where(class_id: del_ac)
				del_tags.destroy_all
				#find subjects to be removed
				del_su = old_subject_ids - updated_subject_ids
				del_tags = m.where(subject_id: del_su)
				del_tags.destroy_all
				#new academic_classes to be added
				new_ac = updated_academic_class_ids - old_academic_class_ids
				#new subjects to be added
				new_su = updated_subject_ids - old_subject_ids

				if updated_academic_class_ids.nil? && updated_subject_ids.nil?
				elsif updated_academic_class_ids.nil?
					updated_subject_ids.each {|su| MetaTag.find_or_create_by_class_id_and_subject_id_and_concept_id_and_tags_db_id(nil,su,concept_id,db_id)}
				elsif updated_subject_ids.nil?
					updated_academic_class_ids.each {|ac| MetaTag.find_or_create_by_class_id_and_subject_id_and_concept_id_and_tags_db_id(ac,nil,concept_id,db_id)}
				else
					updated_academic_class_ids.each do |ac|
						updated_subject_ids.each do |su|
							MetaTag.find_or_create_by_class_id_and_subject_id_and_concept_id_and_tags_db_id(ac,su,concept_id,db_id)
						end
					end
					updated_academic_class_ids.each do |ac|
						MetaTag.find_or_create_by_class_id_and_subject_id_and_concept_id_and_tags_db_id(ac,nil,concept_id,db_id)
					end
					updated_subject_ids.each do |su|
						MetaTag.find_or_create_by_class_id_and_subject_id_and_concept_id_and_tags_db_id(nil,su,concept_id,db_id)
					end
				end
			end
			updated = true
		rescue Exception => e 
			logger.info "#{e}"
		end
		respond_to do |format|
      format.json { render json: {updated: updated} }
    end
	end

	def edit_tags
		db = Tag.find(params[:id])
		@db_id = db.id
		@concept_tags = Tag.where(standard: true, name: 'concept_name', tags_db_id: db.id)
		@academic_class_tags = Tag.where(standard: true, name: 'academic_class', tags_db_id: db.id)
		@subject_tags = Tag.where(standard: true, name: 'subject', tags_db_id: db.id)
		@meta_tags = Array.new
		@concept_tags = Kaminari.paginate_array(@concept_tags).page(params[:page]).per(50)

		@concept_tags.each do |c|
			co = Hash.new
			co['academic_class'] = Array.new
			co['subject'] = Array.new
			m = MetaTag.where(concept_id: c.id, tags_db_id: db.id)
			co['academic_class'] = m.where("class_id is not null").map(&:class_tag).uniq.map(&:value)
			co['subject'] = m.where("subject_id is not null").map(&:subject_tag).uniq.map(&:value)
			co['id'] = c.id
			co['value'] = c.value
			@meta_tags << co
		end
	end

	def edit_users
		db = TagsDb.find(params[:id])
		@tags_db = db
		@db_id = db.id
		@institutions = Institution.all 
		@publishers = Publisher.all
	end
end