#class Archive < ActiveRecord::Base
#  belongs_to :creator ,:foreign_key => :created_by ,:class_name => "User"
#  has_many :test_results
#
#  Paperclip.interpolates 'created_user' do |attachment, style|
#    attachment.instance.creator.id
#  end
#  Paperclip.interpolates 'archiveId' do |attachment, style|
#    attachment.instance.archiveId
#  end
#
#  has_attached_file :attachment,
#                    :url => "/archives/:created_user/:archiveId/:basename" + ".:extension",
#                    :path => ":rails_root/public/archives/:created_user/:archiveId/:basename" + ".:extension"
#
#  validates_attachment_presence :attachment
#
#  before_save {|record| self.archiveId = Time.now.strftime("%Y%m%d%H%M%S")}
#
#end