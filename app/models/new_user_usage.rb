class NewUserUsage < ActiveRecord::Base

 def self.update_table
     id = NewUserUsage.last.id
    sql1 = "INSERT new_user_usages SELECT * FROM user_usages where user_usages.id > #{id}"
    sql2 = "SET sql_mode = 'NO_UNSIGNED_SUBTRACTION';"
     sql3 = "UPDATE new_user_usages A INNER JOIN new_user_usages B USING (id) SET A.start_time = B.created_at-(B.end_time-B.start_time),A.end_time = B.created_at where B.end_time < 1362076200 and user_usages.id > #{id};"
     sql4 = "update new_user_usages A INNER JOIN new_user_usages B USING (id) SET A.start_time = B.end_time-60 where B.start_time =0 and B.end_time !=0 and user_usages.id > #{id};"
     sql5 = "update new_user_usages A INNER JOIN new_user_usages B USING (id) SET A.start_time = B.end_time, A.end_time = B.start_time where B.start_time > B.end_time and user_usages.id > #{id}"
     #sql6 = "update new_user_usages A INNER JOIN new_user_usages B USING (id) SET A.end_time = B.start_time+3600 where (B.end_time-B.start_time) > 3600 and user_usages.id > #{id}"
    ActiveRecord::Base.connection.execute(sql1)
    ActiveRecord::Base.connection.execute(sql2)
    ActiveRecord::Base.connection.execute(sql3)
    ActiveRecord::Base.connection.execute(sql4)
    ActiveRecord::Base.connection.execute(sql5)
   #ActiveRecord::Base.connection.execute(sql6)
 end

end
