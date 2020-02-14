class Slot < ActiveRecord::Base
  set_primary_key :jobid
  set_table_name "slot"
  establish_connection Rails.configuration.database_configuration["chip"]

  def self.find_record_by_cid(cid)
    #   This method is used to check and match only first 30 characters of cid
    Slot.where("lower(substr(cid,1,30))=?", "#{cid[0..29]}".downcase)
  end
end
