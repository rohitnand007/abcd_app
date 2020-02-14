class TagReference < ActiveRecord::Base
  belongs_to :tag

  def child_tag
    Tag.find(self.tag_refer_id)
  end
  def parent_tag
    Tag.find(self.tag_id)
  end
end
