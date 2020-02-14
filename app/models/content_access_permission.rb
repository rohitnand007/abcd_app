class ContentAccessPermission < ActiveRecord::Base
  belongs_to :user
  belongs_to :accessed_content, :polymorphic => true
  has_one :content_access_license, dependent: :destroy
  after_create :update_user_last_purchased
  before_destroy :update_user_last_purchased

  def update_user_last_purchased
  	user = User.find(self.user_id)
  	user.update_attribute("last_content_purchased", Time.now)
  end

  def assignedVia
    if self.access_type=="package_assign"
      "publisher"
    else
      "store"
    end
  end

  def on_store?
    # user = User.find(self.user_id)
    # url = user.get_store_url
    # guid = self.accessed_content_guid
    true
  end

  def self.get_latest_records(user_id)
    where_hash= {user_id:user_id}
    select_extreme_records(where_hash,:accessed_content_guid,:ends,:max)
  end

  def self.select_extreme_records(where_hash,group_by_field,extrema_field,extrema_function=:max)
    # Where hash contains filters
    # group by field is the uniquess field
    inner_where_clause = where_hash.map do |key,value|
      if value.is_a? Array
        "#{key} IN (#{value.join(",")})"
      else
        "#{key}=#{value}"
      end
    end .join(" AND ")
    where_clause = where_hash.map do |key,value|
      if value.is_a? Array
        "t0.#{key} IN (#{value.join(",")})"
      else
        "t0.#{key}=#{value}"
      end
    end .join(" AND ")
    inner_query = "select #{group_by_field} as gbf, #{extrema_function}(#{extrema_field}) as ef from #{table_name} where #{inner_where_clause} group by #{group_by_field}"
    find_by_sql("select t0.* from #{table_name} t0  inner join (#{inner_query}) t1 on t0.#{group_by_field} = t1.gbf and t0.#{extrema_field}=t1.ef where #{where_clause} ")
  end
end