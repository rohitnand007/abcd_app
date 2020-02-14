$("#selected_questions_control_buttons").show();
$(".loading").hide();
set_check_box();
$("#select_questions").html("<%= escape_javascript(render :partial => 'select_questions', locals: {questions: @questions,publisher_question_bank_id:@publisher_question_bank_id})%>")

