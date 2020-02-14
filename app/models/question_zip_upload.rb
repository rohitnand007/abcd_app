class QuestionZipUpload < ActiveRecord::Base
	belongs_to :question_upload 
	belongs_to :zip_upload
end