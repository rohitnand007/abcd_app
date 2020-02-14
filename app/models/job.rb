class Job < ActiveRecord::Base
  set_table_name "job"
  establish_connection Rails.configuration.database_configuration["chip"]
end