class SupportRequestsController < ApplicationController

  skip_before_filter :authenticate_user!, :only => [:new_forgot_password_request,:create_forgot_password_request]
  #skip_before_filter :verify_authenticity_token, :only => [:new_forgot_password_request,:create_forgot_password_request]

 layout "sign"

  def new_forgot_password_request

  end

  def create_forgot_password_request
    if verify_recaptcha
      email=params[:support_request][:email]
      name=params[:support_request][:name]
      center=params[:support_request][:center]
      institute=params[:support_request][:institute]
      role=params[:support_request][:role]
      phone=params[:support_request][:phone]
      received_parameters={email: email, name: name, center: center,institute: institute,role: role, phone: phone}
      serialized_body=@received_parameters.to_json
      @support = SupportRequest.create(rtype:'Forgot password',body:serialized_body,status:1)
      SupportRequestMailer.forgot_password_mail(received_parameters).deliver
      redirect_to sign_in_path , notice:"An email has been sent to our customer care executive. Please wait till we contact you."
    else
      redirect_to :back
    end
  end
end