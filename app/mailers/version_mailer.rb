class VersionMailer < ActionMailer::Base
  def version_mail
    attachments["Version_vs_LearnerNumber.csv"] = File.read("public/user_version_csv/#{Time.now.strftime("%Y-%m-%d")}.csv")
    mail(:from => "admin@myedutor.com",
         :to => "prasanna.boni@myedutor.com, ashok@myedutor.com, dilip.bv@myedutor.com, steve.vosloo@pearson.com,support@myedutor.com",
         :subject => "Pearson app version csv on #{Time.now.strftime("%Y-%m-%d")}")
  end
end

