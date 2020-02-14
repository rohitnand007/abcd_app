class TestResult < ActiveRecord::Base
  belongs_to :user
 # belongs_to :content,:foreign_key=>"uri"
  belongs_to :assessment


  def self.csv_header
  "id,user_id,marks,percentage,submission_time,rank,created_at,updated_at,test_type,attempt,display_name,rank_status,uri,uid,time_taken_per_question".split(",")
  end

  def to_csv
    [id, user_id, marks, percentage, submission_time, rank, created_at, updated_at, test_type, attempt, display_name, rank_status, uri, uid, time_taken_per_question]
  end

=begin def self.uri_resolver(uri)
    # method to convert "/Curriculum/Assessment/aakash/NTSE Plus iTutor - Basic/practice-tests/Physics/Force and Pressure/Practice Test1" to "/Curriculum/Content/aakash/NTSE Plus iTutor - Basic/practice-tests/Physics/Force and Pressure/"
    str = uri.split('/')
    size = uri.split('/').size
    str.delete_at(size-2)
    str.join('/')
  end
=end
end