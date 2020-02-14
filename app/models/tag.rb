class Tag < ActiveRecord::Base

  default_scope :order => 'tags.value ASC'
  validates_presence_of :name, :value
  validates_uniqueness_of :name, :scope=>[:value],:message=>'Tag value already created'
  #validates_length_of :name, maximum: 255
  before_save :ignore_spaces

  has_many :taggings, :dependent => :destroy
  has_many :questions, :through => :taggings
  has_many :tag_references,:dependent => :destroy
  has_many :ref_tags,:class_name => "TagReference" ,:foreign_key => :tag_refer_id, :dependent => :destroy
  has_many :tag_mappings, :dependent => :destroy

  has_and_belongs_to_many  :publisher_question_banks
  belongs_to :tags_db

  # Meta Tags
  has_many :class_tags, :class_name => 'MetaTag', :foreign_key => 'class_id', :dependent => :destroy
  has_many :subject_tags, :class_name => 'MetaTag', :foreign_key => 'subject_id', :dependent => :destroy
  has_many :concept_tags, :class_name => 'MetaTag', :foreign_key => 'concept_id', :dependent => :destroy

  scope :class_tags, where(name: 'academic_class', standard: true)
  scope :subject_tags, where(name: 'subject', standard: true)
  scope :concept_tags, where(name: 'concept_name', standard: true)

  # Tag categories: academic_class, subject, chapter, concept_names, difficulty_level, blooms_taxonomy, specialCategory, descriptive, 

  def self.add_ref_tags(tag,tag_ref,institution_id,center_id,publisher_question_bank_id)
    TagReference.find_or_create_by_tag_id_and_tag_refer_id_and_institution_id_and_center_id_and_publisher_question_bank_id(tag,tag_ref,institution_id,center_id,publisher_question_bank_id)
  end

  def name_value
    self.name+" ------ "+self.value
  end


  def value_text
    require 'redis_interact'
    value = self.value
    prettified_name = RedisInteract::PrettyNames[value].present? ? RedisInteract::PrettyNames[value] : value
    # if value=="mmcq"
    #   "Multiple Answer MCQ"
    # elsif value=="smcq"
    #   "Single Answer MCQ"
    # elsif value=="ifib"
    #   "Integer"
    # elsif value=="oomtf"
    #   "One-One Matching"
    # elsif value=="ommtf"
    #   "One-Many Matching"
    # else
    #   value.capitalize
    # end
  end

  def ignore_spaces
    self.value = self.value.lstrip.rstrip
  end

  def proper_name
    if self.name.index("s_") == 0
      # "Standard " + self.name.gsub("s_", "").humanize.titleize
      self.name.gsub("s_", "").humanize.titleize
    else
      self.name.humanize.titleize
    end
  end

  def is_standard?
    if self.name.index("s_") == 0
      return true
    else
      return false
    end
  end

  def self.user_tags(user_id)
    tags = Hash.new
    if UsersTagsDb.find_by_user_id(user_id).present?
      db = UsersTagsDb.find_by_user_id(user_id).tags_db
      tags['class_tags'] = Tag.where(name: 'academic_class', tags_db_id: db.id, standard: true)
      tags['subject_tags'] = Tag.where(name: 'subject', tags_db_id: db.id, standard:true)
      tags['concept_tags'] = Tag.where(name: 'concept_name', tags_db_id: db.id, standard: true)
    end
    return tags
  end
end
