class ConceptElement < ActiveRecord::Base
  attr_accessible :description, :name, :parent_id, :concept_id, :x, :y
  belongs_to :concept
  has_many :childConceptElement, :class_name => "ConceptElement",
           :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "ConceptElement"
  acts_as_tree
end
