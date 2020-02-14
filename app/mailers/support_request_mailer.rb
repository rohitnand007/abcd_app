class SupportRequestMailer < ActionMailer::Base
  default from: "sriharsha@myedutor.com"


  def forgot_password_mail(data)
    @request_info = data
    mail(:to=>"support@myedutor.com",:from=>"dilip.bv@myedutor.com",:subject=>"#{@request_info[:name]} forgot password on #{Time.now.strftime("%Y-%m-%d")}")
  end
end
