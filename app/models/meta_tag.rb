class MetaTag < ActiveRecord::Base
	#columns: class_id, subject_id, concept_id, tags_db_id
	validates_presence_of :concept_id, :tags_db_id
	validate :value_of_class_id
	validate :value_of_subject_id
	validate :value_of_concept_id
	validate :value_of_tags_db_id
	validates_uniqueness_of :tags_db_id, :scope => [:class_id, :subject_id, :concept_id]

	belongs_to :class_tag, :class_name => 'Tag', :foreign_key => 'class_id'
	belongs_to :subject_tag, :class_name => 'Tag', :foreign_key => 'subject_id'
	belongs_to :concept_tag, :class_name => 'Tag', :foreign_key => 'concept_id'
	belongs_to :tags_db

	def value_of_class_id
		#check if tag_id is of class tag
		if self.class_id.present?
			tag_name = Tag.find(self.class_id).name
			errors.add(:class_id,"not a valid class tag") if tag_name != "academic_class"
		end
	end

	def value_of_subject_id
		if self.subject_id.present?
			tag_name = Tag.find(self.subject_id).name
			errors.add(:class_id,"not a valid subject tag") if tag_name != "subject"
		end
	end

	def value_of_concept_id
		tag_name = Tag.find(self.concept_id).name
		errors.add(:class_id,"not a valid concept tag") if tag_name != "concept_name"
	end

	def value_of_tags_db_id
		if !TagsDb.where(id: self.tags_db_id).present?
			errors.add(:tags_db_id, "tags_db id is not present")
		end
	end

	def self.create_tag_links(file_path, db_id)
		begin
			CSV.foreach(file_path, :headers => true, :col_sep => ',') do |row|
				#0: concept_name, 1: subjects, 2: classes, 3: user_id
				concept_tags = []
				subject_tags = []
				class_tags = []
				concepts = row[3].split(";")
				subjects = row[1].split(";")
				classes = row[0].split(";")

				concepts.each do |concept|
					concept_tags << Tag.find_or_create_by_name_and_value_and_tags_db_id_and_standard("concept_name", concept.rstrip.lstrip, db_id, true)
				end
				subjects.each do |subject|
					subject_tags << Tag.find_or_create_by_name_and_value_and_tags_db_id_and_standard("subject", subject.rstrip.lstrip, db_id, true)
				end
				classes.each do |a_class|
					class_tags << Tag.find_or_create_by_name_and_value_and_tags_db_id_and_standard("academic_class", a_class.rstrip.lstrip, db_id, true)
				end
				concept_tags.each do |co_tag|
					subject_tags.each do |su_tag|
						class_tags.each do |cl_tag|
							MetaTag.find_or_create_by_class_id_and_subject_id_and_concept_id_and_tags_db_id(cl_tag.id, su_tag.id, co_tag.id,db_id)
							MetaTag.find_or_create_by_class_id_and_subject_id_and_concept_id_and_tags_db_id(cl_tag.id, nil, co_tag.id,db_id)
						end
						MetaTag.find_or_create_by_class_id_and_subject_id_and_concept_id_and_tags_db_id(nil, su_tag.id, co_tag.id,db_id)
					end
				end
			end
		rescue Exception => e
			logger.info e 
		end
	end
end