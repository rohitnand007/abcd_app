class UserGroup < ActiveRecord::Base
  #belongs_to :user, :foreign_key=>'user_id'
  #belongs_to :user, :foreign_key=>'group_id'
  belongs_to :user
  belongs_to :group, :class_name => "User"
  belongs_to :publisher,:foreign_key => 'group_id'
  has_many :messages
  has_many :class_rooms,:primary_key => 'group_id',:foreign_key => 'group_id'
  has_many :test_configurations,:primary_key => 'group_id',:foreign_key => 'group_id'
  has_many :test_results,:primary_key => 'user_id',:foreign_key => 'user_id'
  has_many :students,:class_name => 'User',:primary_key => 'group_id'
  attr_accessible :user_id, :group_id
end
