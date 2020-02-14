module ProfilesHelper
  def bread_crumb_for_profile_pages
 current_page_name = if params[:action].eql?'show'
                          'Profile'
                        elsif params[:action].eql?'edit'
                          'Update Profile'
                        elsif params[:action].eql?'new'
                          'New'
                        end
    # content_tag(:ul,
    #             content_tag(:li,"#{link_to  current_page_name, '#',{:class=>'current'}}".html_safe) )
  end
end
#content_tag(:ul,
# content_tag(:li,"#{link_to  'Home', root_path}".html_safe) +
# content_tag(:li,"#{link_to  current_page_name, '#',{:class=>'current'}}".html_safe) )