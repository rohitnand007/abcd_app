class Api::Panacea::ApiBaseController <  ActionController::Base
   before_filter :parse_request_data, :authenticate_user_from_token!

    private
       def authenticate_user_from_token!
         if !@json['api_token']
           render nothing: true, status: :unauthorized
         else
           @api_user = nil
           User.find_each do |u|
             if Devise.secure_compare(u.authentication_token, @json['api_token'])
               @api_user = u
             end
           end
           if @api_user.nil?
             render nothing: true, status: :unauthorized
           end
         end
       end

       def parse_request_data
         @json = JSON.parse(request.body.read)
         logger.info "===#{@json}"
       end
end