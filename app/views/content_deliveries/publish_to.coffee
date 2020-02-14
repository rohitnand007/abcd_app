$("#selected_books_control_button").show();
$("#publish_content").html("<%= escape_javascript(render :partial => 'publish_to', locals: {ibooks: @ibooks})%>")
set_check_box();
$(".loading").hide();