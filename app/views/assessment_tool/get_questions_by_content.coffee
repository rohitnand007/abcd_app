$("#selected_questions_control_buttons").show();
$("#select_questions").html("<%= escape_javascript(render :partial => 'select_questions', locals: {questions: @questions})%>")
set_check_box();
$(".loading").hide();