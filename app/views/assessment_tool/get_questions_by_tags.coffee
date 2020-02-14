$("#selected_questions_control_buttons").show();
$(".loading").hide();
$(document).ready ->
  $('.nsbox').bind 'change', ->
    if $(this).is(':checked')
      $('#nstype').show()
      $('#qtype').prop 'disabled', 'disabled'
    else
      $('#nstype').hide()
      $('#qtype').prop 'disabled', false
      $('#tag_list_qsubtype').val 'Select'
    return
  $('.nsbox').trigger 'change'
  return
set_check_box();
$("#select_questions").html("<%= escape_javascript(render :partial => 'select_questions', locals: {questions: @questions})%>")

