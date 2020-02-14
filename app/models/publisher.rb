class Publisher < User
  attr_accessible :white_center_ids
  attr_accessible :white_institution_ids
  has_many :publisher_question_banks,:dependent => :destroy
  has_many :created_questions ,:class_name => "Question",:foreign_key => 'createdby'
  has_many :qdb_questions, :source=>:questions , :through=>:publisher_question_banks
  has_many :question_bank_users,:dependent => :destroy
  has_many :white_schools
  has_many :white_centers, through: :white_schools, source: :center, foreign_key: :center_id
  has_many :white_institutions,through: :white_schools, source: :institution,  foreign_key: :institution_id
  has_many :ibooks
  has_many :ipacks
  has_many :license_sets
  has_many :publisher_stores
  has_many :stores, :through => :publisher_stores , :uniq => true


  before_create :set_defaults
  after_create :create_publisher_question_bank

=begin
  has_many :assets,:foreign_key=>"publisher_id"
  has_many :chapters,:through=>:assets, :foreign_key => 'publisher_id'
  has_many :topics,:through=>:assets, :foreign_key => 'publisher_id'
  has_many :sub_topics,:through=>:assets, :foreign_key => 'publisher_id'
=end

  def set_defaults
    self.role_id = 16
    self.is_activated = true
  end

  def  create_publisher_question_bank
    self.publisher_question_banks.create(description:"This is #{self.name}'s question bank'",question_bank_name:"#{self.name} Question Bank")
  end

  def licenses_issued
    self.license_sets.inject(0) { |total, ls| ls.licences.present? ? total+ls.licences : total+0 }
  end

  def licenses_utilized
    self.license_sets.inject(0) { |total, ls| total+ls.utilized }
  end

  def percentage_licenses_consumed
    self.licenses_issued==0 ? 0 : (self.licenses_utilized * 100)/(self.licenses_issued)
  end
end
