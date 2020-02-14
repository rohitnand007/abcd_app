class AacademicYear < Content
 belongs_to :course
 has_many :subjects, :conditions=>{:type=>"Subject"}
end