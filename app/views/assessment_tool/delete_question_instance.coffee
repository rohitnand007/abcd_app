q_i_id = <%=@question_instance_id%>
qid = "#qiid_"+q_i_id
$(qid).html ""
$("#test_details").html "<%= escape_javascript(render :partial => 'test_details', locals: {quiz: @quiz})%>"