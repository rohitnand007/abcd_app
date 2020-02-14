module MessagesHelper
  def bread_crumb_message_page
    current_page_name = if params[:action].eql?'users'
                          'Inbox'
                        elsif params[:action].eql?'sent'
                          'Sent'
                        elsif params[:action].eql?'new'
                          'New'
                        elsif params[:action].eql?'show'
                          'Message'
                        end

    content_tag(:ul, content_tag(:li,"#{link_to  current_page_name, '#',{:class=>'current', :style=>"cursor:inherit;"}}".html_safe) )
    # content_tag(:ul,
    #             content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
    #                 content_tag(:li,"#{link_to  'Check Messages', messages_path+user_path(current_user)}".html_safe) +
    #                 content_tag(:li,"#{link_to  current_page_name, '#',{:class=>'current'}}".html_safe) )
  end
end
