$("#addQuestionTabs-3").html "<%= escape_javascript(render :partial => 'section_box', locals: {assessment_div: @assessment_div})%>"
#rearranges questions inside paragraph
rearrange_as_nested()

make_the_section_sortable()

