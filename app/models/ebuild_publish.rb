class EbuildPublish < ActiveRecord::Base
  belongs_to :ebuild_tag
  belongs_to :user

  after_create :set_user_type

  def set_user_type
    self.update_attribute(:user_type,User.find(self.user_id).type  )
    if !self.ebuild_tag_id.nil?
      EbuildTag.find(self.ebuild_tag_id).ebuild_apps.each do |e_apps|
        if !EbuildTag.find(self.publish_ebuild_tag_id).ebuild_apps.map(&:package).include? e_apps.package
          new_app = e_apps.dup
          new_app.ebuild_tag_id = self.publish_ebuild_tag_id
          new_app.publish_flag = false
	  new_app.attachment = File.open(e_apps.attachment.path)
          new_app.save
        end
      end
    end
  end

end
