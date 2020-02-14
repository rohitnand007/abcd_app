class CdnContentInfo < ActiveRecord::Base
  # attr_accessible :title, :body
  validates_uniqueness_of :guid, scope: :user_id
  def self.calculate_md5_hash(content_url)
    md5_hash = Digest::MD5.file content_url
    md5_digest = md5_hash.hexdigest
    return md5_digest
  end
end
