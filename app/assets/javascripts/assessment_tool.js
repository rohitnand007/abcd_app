

function common_ready_function(){
$(".utility_button").button({
    icons:{primary:"ui-icon-download-btn", secondary: null},
    text: false
  });
// download,duplicate-test,edit,publish,re-publish,view-analytics
$(".utility_button.edit-btn").button("option",{icons:{primary: "ui-icon-edit-btn"}})
$(".utility_button.download-btn").button("option",{icons:{primary: "ui-icon-download-btn"}})
$(".utility_button.duplicate-test-btn").button("option",{icons:{primary: "ui-icon-duplicate-test-btn"}})
$(".utility_button.publish-btn").button("option",{icons:{primary: "ui-icon-publish-btn"}})
$(".utility_button.re-publish-btn").button("option",{icons:{primary: "ui-icon-re-publish-btn"}})
$(".utility_button.view-analytics-btn").button("option",{icons:{primary: "ui-icon-view-analytics-btn"}})

//button for analytics links
    $(".analytics_links").button();
    $(".download_assessment_link").button();
    /* Fixing CSS issues */
    $("#tabsul").removeClass('ui-widget-header');
    $("#tabs").removeClass('ui-widget-content');
    $(".assessment-header").css("padding-left", "12px");
    $(".section-title").css("color", "#60c8cd");

$(".ui-button.ui-widget").css({"height":"45px","width": "75px"});
$(".analytics_links.ui-button.ui-widget, .download_assessment_link").css({"height":"45px","width": "175px","line-height":"45px"});
$(".analytics_links.ui-button.ui-widget .ui-button-text, .download_assessment_link").css({"line-height":"38px"});


$(".pagination_info").html($(".pagination_info").html().replace("quizzes", "Assessments"));
$(".pagination_info").html($(".pagination_info").html().replace("quiz", "Assessment"));



}


function prepare_dialogs_for_analytics(){
    $(".analytics_dropdown").hide();
    $(".downloads_dropdown").hide();
    $('.view-analytics-btn').each(function() {
        $.data(this, 'dialog',
            $(this).next('.analytics_dropdown').dialog({
                autoOpen: false,
                modal: true,
                width: 280
            })
        );
    }).click(function() {
            $.data(this, 'dialog').dialog('open');
            return false;
        });
    $('.download-btn').each(function() {
        $.data(this, 'dialog',
            $(this).next('.downloads_dropdown').dialog({
                autoOpen: false,
                modal: true,
                width: 280
            })
        );
    }).click(function() {
            $.data(this, 'dialog').dialog('open');
            return false;
        });
}


function loadTinyMCEEditorById(id) {
    tinyMCE.init({
        mode:'exact',
        elements : id,
        theme:"advanced",
        verify_html: false,
        plugins: "uploadimage,fmath_formula,googleimagesearch,table",
        /*
         theme_advanced_buttons1:"Blank,bold,italic,underline,separator,bullist,numlist,separator,\
         undo,redo,|,forecolor,backcolor, |, justifyleft, justifycenter, justifyright, justifyfull,\
         formatselect,fontselect,fontsizeselect",
         theme_advanced_buttons2:"hr,removeformat,visualaid,|,sub,sup,|,\
         preview,uploadimage,code",*/
        theme_advanced_buttons1:"Blank,bold,italic,underline,separator,bullist,numlist,separator,\
                  undo,redo,|,forecolor,|, justifyleft, justifyfull, justifyright,\
                  fontselect,fontsizeselect,hr,removeformat,|,sub,sup,|,fmath_formula,googleimagesearch,|,preview,uploadimage,code",
        theme_advanced_buttons2 : "tablecontrols",
        theme_advanced_toolbar_location:"top",
        theme_advanced_toolbar_align:"left", theme_advanced_statusbar_location:"none",
        relative_urls:true,
        document_base_url : "http://"+window.location.host + '/question_images/',
        width: 760,
        height: 300,
        setup : function(ed) {
            var textAreaSelector = "textarea[name='"+ed.getElement().name+"']";
            var $questionContainer= $(textAreaSelector).closest(".question_container");
            ed.onClick.add(function(ed) {

                if ($questionContainer.is(':nth-last-child(2)')) {$("#questionAdder")[0].click() };
            });
            ed.addButton('Blank', {
                title : 'Add blank',
                image : '/assets/dash.gif',
                onclick : function() {
                    // Add you own code to execute something on click
                    ed.focus();
                    ed.selection.setContent('#DASH#');

                    $questionContainer.find(".fib_blank_set").click();

                }
            });
        }
    });
}







function loadTinyMCEEditor() {
    tinyMCE.init({
        mode:'specific_textareas',
        editor_selector : "full_text",
        theme:"advanced",
        verify_html: false,
        init_instance_callback: "set_up"       ,
        plugins: "uploadimage,googleimagesearch,table",
        /*
         theme_advanced_buttons1:"Blank,bold,italic,underline,separator,bullist,numlist,separator,\
         undo,redo,|,forecolor,backcolor, |, justifyleft, justifycenter, justifyright, justifyfull,\
         formatselect,fontselect,fontsizeselect",
         theme_advanced_buttons2:"hr,removeformat,visualaid,|,sub,sup,|,\
         preview,uploadimage,code",*/
        theme_advanced_buttons1:"Blank,bold,italic,underline,separator,bullist,numlist,separator,\
                  undo,redo,|,forecolor,|, justifyleft, justifyfull, justifyright,\
                  fontselect,fontsizeselect,hr,removeformat,|,sub,sup,|,preview,uploadimage,googleimagesearch,code",
        theme_advanced_buttons3_add : "tablecontrols",
        theme_advanced_toolbar_location:"top",
        theme_advanced_toolbar_align:"left", theme_advanced_statusbar_location:"none",
        relative_urls:true,
        document_base_url : "http://"+window.location.host + '/question_images/',
        width: 760,
        setup : function(ed) {
            var textAreaSelector = "textarea[name='"+ed.getElement().name+"']";
            var $questionContainer= $(textAreaSelector).closest(".question_container");
            $textAreaSelector = $(textAreaSelector);
            ed.onClick.add(function(ed) {

                if ($questionContainer.is(':last-child')) {$("#questionAdder")[0].click() };
            });
            ed.addButton('Blank', {
                title : 'Add blank',
                image : '/assets/dash.gif',
                onclick : function() {
                    // Add you own code to execute something on click
                    ed.focus();
                    ed.selection.setContent('#DASH#');
                    $questionContainer.find(".fib_blank_set").click();
                }
            });

        }

    });
}


function set_up(inst){
  alert('hi');
}

function fibloadTinyMCEEditor() {

    tinyMCE.init({
        mode:'specific_textareas',
        editor_selector : "full_text",
        theme:"advanced",
        plugins: "uploadimage,googleimagesearch,table",
        /*
         theme_advanced_buttons1:"Blank,bold,italic,underline,separator,bullist,numlist,separator,\
         undo,redo,|,forecolor,backcolor, |, justifyleft, justifycenter, justifyright, justifyfull,\
         formatselect,fontselect,fontsizeselect",
         theme_advanced_buttons2:"hr,removeformat,visualaid,|,sub,sup,|,\
         preview,uploadimage,code",*/
        theme_advanced_buttons1:"Blank,bold,italic,underline,separator,bullist,numlist,separator,\
                  undo,redo,|,forecolor,|, justifyleft, justifyfull, justifyright,\
                  fontselect,fontsizeselect,hr,removeformat,|,sub,sup,|,preview,uploadimage,googleimagesearch,code",
        theme_advanced_buttons2 : "tablecontrols",
        theme_advanced_toolbar_location:"top",
        theme_advanced_toolbar_align:"left", theme_advanced_statusbar_location:"none",
        relative_urls:true,
        document_base_url : "http://"+window.location.host + '/question_images/',
        width: 760,
        setup : function(ed) {
            // Add a custom button
            ed.addButton('Blank', {
                title : 'Add blank',
                image : '/assets/dash.gif',
                onclick : function() {
                    // Add you own code to execute something on click
                    ed.focus();
                    ed.selection.setContent('#DASH#');
                }
            });
        }
    });
}


function loadTinyMCEEditorSmall(id_string) {
    tinyMCE.init({
        mode:'exact',
        elements : id_string,
        theme:"advanced",
        verify_html: false,
        plugins: "uploadimage,fmath_formula,googleimagesearch,table",
        /*
         theme_advanced_buttons1:"Blank,bold,italic,underline,separator,bullist,numlist,separator,\
         undo,redo,|,forecolor,backcolor, |, justifyleft, justifycenter, justifyright, justifyfull,\
         formatselect,fontselect,fontsizeselect",
         theme_advanced_buttons2:"hr,removeformat,visualaid,|,sub,sup,|,\
         preview,uploadimage,code",*/
        theme_advanced_buttons1:"Blank,bold,italic,underline,separator,bullist,numlist,separator,\
                  undo,redo,|,forecolor,|, justifyleft, justifyfull, justifyright,\
                  fontselect,fontsizeselect,hr,removeformat,|,sub,sup,|,fmath_formula,googleimagesearch,preview,uploadimage,code",
        theme_advanced_buttons2 : "tablecontrols",
        theme_advanced_toolbar_location:"top",
        theme_advanced_toolbar_align:"left", theme_advanced_statusbar_location:"none",
        relative_urls:true,
        //document_base_url : "http://"+window.location.host + '/question_images/',
        document_base_url : "http://"+window.location.host + '/question_images/',
        width: 760,
        height:150,
        setup : function(ed) {
            ed.onInit.add(function(ed, event) {
                ed.contentAreaContainer.style.height = "auto";
                $('#' + ed.id + '_tbl ').css({"height":"auto","border":"none"});
                $('#' + ed.id + '_tbl '+'.mceIframeContainer').css({"border":"none"});
                $('#' + ed.id + '_tbl '+'.mceToolbar').css({"border":"none"});
                $(ed.getBody()).blur(function() {
                    $('#' + ed.id + '_tbl '+'.mceToolbar').hide();
                    $('#' + ed.id + '_ifr ').css("height","35px");
                });

                $(ed.getBody()).focus(function() {
                    $('#' + ed.id + '_tbl '+'.mceToolbar').show();
                    $('#' + ed.id + '_ifr ').css("height","60px");
                });
                $(ed.getBody()).blur();
            });


        }

    });
}

function apply_Tiny_mce(object) {
//Instantiate full functionality for questions and feedback
    var full_text_ids = [];
    object.find(".full_text").each(function () {
        full_text_ids.push(this.id);
    });
    loadTinyMCEEditorById(full_text_ids.toString());
    // Instantiates hidden tool bar functionality for answer texts
    var small_text_ids = [];
    object.find(".small_text").each(function () {
        small_text_ids.push(this.id);
    });
    loadTinyMCEEditorSmall(small_text_ids.toString());
}


function load_Tiny_mce(event,inserted_item){
    // Instantiate tinyMCE for newquestion as well as its options if it is a question
    if (inserted_item.hasClass("question_container")){
        apply_Tiny_mce(inserted_item);
    }

    // Only instantiate TinyMCE for that MCQ Option.
    if (inserted_item.hasClass("mcq_option_set")){
        loadTinyMCEEditorSmall(inserted_item.find(".small_text").attr('id'));
    }
}

function preload_Tiny_mce(){
    $(".basic_container").each(function(){
        apply_Tiny_mce($(this));
    })

}

function alphabetize(n) {
    var s = "";
    while(n >= 0) {
        s = String.fromCharCode(n % 26 + 97) + s;
        n = Math.floor(n / 26) - 1;
    }
    return s;
}

function do_numbering(object){

    // If object is a question
    if (object.hasClass("question_container")){
       //number the question
        if (object.parents(".passage_question").length>0){
            var parent_number = object.parents(".passage_question").find(".parent_question_number").text().trim()
            var index = object.parent().children(".question_container").index(object)
            var serial_number = parent_number + "." + alphabetize(index);
            object.find(".question_number").text(serial_number);
        }
        else
        {
            object.find(".question_number").text(object.parent().children(".question_container").index(object)+1);
        }
       // number the mcq options for the questions
        object.find(".mcq_option_set").each(function(index,element){
            do_numbering($(this));
        })

    }

    // If object is MCQ Option
    if (object.hasClass("mcq_option_set")){
        //number the option
        var $serial_number = object.find(".answer_number");
        var index = object.parent().children(".mcq_option_set").index(object);
        if (object.parents("#addQuestionTabs-4").length>0){
            index = object.parent().children(".mcq_option_set:visible").index(object);
        }
        var serial_number = alphabetize(index);
        $serial_number.text(serial_number);
    }
}

//resets passage question by removing all the questions ahssociated with the paragraphs
function reset_passage_question(link){
    var $passage_question = link.closest(".passage_question")
    $passage_question.find(".question_container").each(function(){
        $(this).find(".remove_questions")[0].click();
    })
    reset_question($passage_question);
    $("#questionAdder")[0].click();
    do_numbering($passage_question.find(".question_container"));
}

// resets the full question and triggers the change handler
function reset_question(question_object){
    question_object.find('input:text, input:password, input:file, select, textarea').val('');
    try{
        question_object.find(".full_text").each(function(){
            tinymce.get($(this).attr("id")).setContent('');
        })
    }
    catch(err){
        console.log("Tinymce apparently failed but works upon using try catch")
    }
    question_object.find('input:radio, input:checkbox').removeAttr('checked').removeAttr('selected');
    reset_option_values(question_object);
    show_selected_option_set("multichoice",question_object);
}

// only resets the question options but not the question
function reset_option_values(question_object){
    // this part resets the number of lines the answer can take for descriptive questions
    question_object.find(".answer_lines input[type='number']").val("0");
    var $options_fields = question_object.find(".question_table>tbody>tr").not(".ui-widget-content,.question_type_select")
    $options_fields.find('input:text, input:password, input:file, select, textarea').val('');
    $options_fields.find('input:radio, input:checkbox').removeAttr('checked').removeAttr('selected');
    // resets tinymce editor instance for mcq options
    question_object.find(".mcq_option_set .small_text").each(function(){
        tinymce.get($(this).attr("id")).setContent('');
    })

}

// Shows only the relevant fields depending upon the selected question type
function show_selected_option_set(qtype,question_container_object){
    $mcq_set = question_container_object.find(".mcq_option_set");
    $tf_set = question_container_object.find(".tf_option_set");
    $fib_set = question_container_object.find(".fib_option_set");
    $answer_lines = question_container_object.find(".answer_lines");
    $actual_answer = question_container_object.find(".actual_answer");
    $penalty_marks = question_container_object.find(".penalty_marks");
    var fib_icon =  question_container_object.find(".mce_Blank");   //question_container_object.closest("a[href$='_questiontext_Blank']");
    var fib_info =  question_container_object.find(".fib_help_info");
    fib_icon.css("display","inline-block");
    $mcq_set.hide();
    $tf_set.hide();
    $fib_set.hide();
    $actual_answer.hide();
    $answer_lines.hide();
    $penalty_marks.prop("disabled",false);
    switch(qtype) {
        case "fib":
            //tinyMCE.execCommand('mceRemoveControl', false, 'quiz1_question_questiontext');
            //fibloadTinyMCEEditor();
            fib_icon.show();
            fib_info.show();
            $fib_set.show();
            break;
        case "multichoice":
            fib_icon.hide();
            fib_info.hide();
            $mcq_set.show();
            break;
        case "truefalse":
            fib_icon.hide();
            fib_info.hide();
            question_container_object.find(".true_field").val("True");
            question_container_object.find(".false_field").val("False");
            $tf_set.show();
            break;
        case "vsaq":
        case "saq":
        case "laq":
            fib_icon.hide();
            fib_info.hide();
            $answer_lines.show();
            $actual_answer.show()

        default:
            $answer_lines.show();
            $penalty_marks.prop("disabled",true);
            fib_icon.hide();
            fib_info.hide();
            break;
    }
};

function change_displayed_section(event) {
    var $selected_option = $(event.target).find(":selected");
    var new_href = "";
    var waiting_image = '<center><svg version="1.1" id="Layer_5" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"\
                      	 width="100px" height="100px" viewBox="0 0 100 100" enable-background="new 0 0 100 100" xml:space="preserve">\
                      <path fill="#aee3e5" d="M63.021,26.333H12.109c-0.915,0-1.656,0.741-1.656,1.655v15.047c0,0.914,0.741,1.655,1.656,1.655h50.912\
                      	c0.914,0,1.655-0.741,1.655-1.655V27.988C64.677,27.074,63.936,26.333,63.021,26.333z M37.565,39.433H15.834V30.74h21.731V39.433z\
                      	 M63.021,48.529H12.109c-0.915,0-1.656,0.741-1.656,1.655v15.047c0,0.915,0.741,1.656,1.656,1.656h50.912\
                      	c0.914,0,1.655-0.741,1.655-1.656V50.185C64.677,49.271,63.936,48.529,63.021,48.529z M37.565,61.405H15.834v-8.692h21.731V61.405z\
                      	 M63.021,70.513H12.109c-0.915,0-1.656,0.741-1.656,1.655v15.047c0,0.914,0.741,1.655,1.656,1.655h50.912\
                      	c0.914,0,1.655-0.741,1.655-1.655V72.168C64.677,71.254,63.936,70.513,63.021,70.513z M37.565,84.038H15.834v-8.692h21.731V84.038z\
                      	 M89.547,12.785v15.047c0,0.914-0.741,1.655-1.656,1.655H69v-1.106c0-3.394-2.762-6.155-6.156-6.155h-0.409v-6.688h-21.73v6.688\
                      	h-5.381v-9.44c0-0.914,0.741-1.655,1.655-1.655h50.912C88.806,11.13,89.547,11.871,89.547,12.785z M89.547,34.981v15.047\
                      	c0,0.915-0.741,1.656-1.656,1.656H69v-1.107c0-1.333-0.431-2.565-1.154-3.575C68.569,45.993,69,44.761,69,43.428V33.326h18.891\
                      	C88.806,33.326,89.547,34.067,89.547,34.981z M89.547,56.965v15.047c0,0.914-0.741,1.655-1.656,1.655H69v-1.106\
                      	c0-1.285-0.397-2.479-1.074-3.468C68.603,68.104,69,66.91,69,65.624V55.31h18.891C88.806,55.31,89.547,56.051,89.547,56.965z"/>\
                      </svg> <div style="color:#636363">Fetching latest data ...</div> </center>'
    $("#addQuestionTabs-3").html(waiting_image)
    // only updates the edit sectiontab with latest data, doesn't change the data
    var assessment_div_id = $("#section_selector").val().toString();
    if ($(document).find("#addQuestions").length == 1)
    {new_href= "/assessment_tool/update_assessment_division?assessment_division_id="+assessment_div_id;}
    else
    {new_href = "/assessment_tool/update_assessment_division?assessment_division_type=simple_test&assessment_division_id="+assessment_div_id ;}
    $.getScript(new_href,function(data, textStatus, jqxhr){
        // followup function after script is loaded
        $("#addQuestionTabs").tabs("select",0);
        //adds an assessment div id. If the assessment division is a quiz, sets assessment div id to quiz id
        // Controller should first see if quiz has any subsections before hand otherwise there is a chance of entering quiz id in place of quiz section id
        replaceAssessmentDivisionIdInForms(assessment_div_id);

    });

}

function replaceAssessmentDivisionIdInForms(assessment_div_id){
    $(".edit_quiz, .quiz1_edit,.edit_quiz1,.quiz_edit").each(function(){
        var action = $(this).attr("action");
        $(this).attr("action",action
            .replace(/assessment\_div\_id\=\d*/, 'assessment_div_id='+assessment_div_id));
    });
}

function addQuestionsToActiveSection(){
    if (question_array.length == 0)
    {
        return false
    }
    $(".selected_section_cue").html('<img alt="Small_loading" class="loading" src="/assets/small_loading.gif" style="vertical-align: middle;">');
    var new_href = "/assessment_tool/update_assessment_division?assessment_division_id="+$("#section_selector").val().toString() +"&selected_questions=" + question_array.join("-");
    $(this).attr("href",new_href);
    return true;
}


function addQuestionsDirectlyToAssessment(){
    if (question_array.length == 0)
    {
        return false
    }
    $(".selected_section_cue").html('<img alt="Small_loading" class="loading" src="/assets/small_loading.gif" style="vertical-align: middle;">');
    var new_href = "/assessment_tool/update_assessment_division?assessment_division_type=simple_test&assessment_division_id="+$("#section_selector").val().toString() +"&selected_questions=" + question_array.join("-");
    $(this).attr("href",new_href);
    return true;
}

function stylizeButtons(){
    //input type submit becomes a button
    $('input[type=submit]:not(".search_iconview")').button();

    $( "#questionBankSearch" ).button();
    $( "#addQuestions" ).button();
    $( "#addQuestionsSimpleTest").button();
    //$("#search_for_questions").button();
    $("#goToAssessmentPreview").button();
}

// after image insert click
/*
 $(".upload_image").live("click",function(){
 $(this).closest(".basic_container").find(".mceButton.mce_uploadimage")[0].click();
 }) */

function reset_options(){
    var qtype = $(this).val()
    $question_container = $(this).closest(".question_container");
    reset_option_values($question_container);
    show_selected_option_set(qtype,$question_container);
}


// assign reset handler for reset button in the question options
$(".reset_question").live('click',function(){
    var $question_object = $(this).closest(".question_container");
    reset_question($question_object);
});

function act_like_radio_buttons(){
    var $this = $(this);
    var $group = $this.closest(".question_container").find(".tf_option_set input:checkbox");
    $group.attr("checked",false);
    $this.attr("checked",true);
}

function rearrange_as_nested() {
    if ($("#addQuestionTabs-3 .passage_question").length != 0) {
        $("#addQuestionTabs-3 .passage_question").each(function () {
            // moves the children questions into the parent question
            var $this = $(this)
            var child_ids = $this.find(".child_questions").val().split(" ");
            var $sub_questions_container = $this.find(".sub_questions");
            var nested_question_positions = [];
            $.each(child_ids, function (index, child_id) {
                var $child_question = $("#ques_id_" + child_id).closest(".question_container");
                $child_question.detach().appendTo($sub_questions_container);
                nested_question_positions.push($child_question.find(".question_position").val())
            });
            //sort the position array by value of the content
            nested_question_positions.sort();
            var $rearranged_nested_set = $("<div></div>");
            //rearranges child questions inside a passage question
            $.each(nested_question_positions,function(index,position){
                var $target_question = $sub_questions_container.find(".question_position[value="+position+"]").closest(".question_container");
                $rearranged_nested_set.append($target_question) ;
            });
            $sub_questions_container.html($rearranged_nested_set.html());

            //  renumbers the children questions
            $this.find(".question_container").each(function () {
                do_numbering($(this));
            });
            // renumbers the subsequent siblings of the parent passage question
            $this.nextAll(".question_container").each(function () {
                do_numbering($(this));
            });

        });

    }
}

function make_the_section_sortable() {
//makes the questions sortable within section
    $("#addQuestionTabs-3 .sortable_questions").sortable({ stop: function (event, ui) {
        $(".question_position").each(function (index, element) {
            $(this).val(index + 1);
        });
        $("#saveAssessment2").click();
    }});
}
function set_check_box() {
$("#select_questions input[type=checkbox]").each(function(){
    if ($.inArray(this.value, question_array) !== -1) {
        $(this).prop('checked',true)
    }
});
}

function empty_question_array() {
    question_array = []
    try{
        $( "#addQuestions" ).button( "disable" );
    }
    catch(err) {
        //nothing here
    }
    try{
        $( "#addQuestionsSimpleTest" ).button( "disable" );
    }
    catch(err) {
        //nothing here
    }
}


function uncheck_question_checkbox() {
    $("#select_questions input[type=checkbox]").each(function(){
            $(this).prop('checked',false)
    });
}


function hide_fib_dash(){
    var fib_icon = $("#quiz1_question_questiontext_Blank")
}

function add_accordion_to_searches(){
    $("#searchOptions .ui-state-hover.ui-widget-content").css({
        //code below not working
        "border-color":"#60c8cd !important"
    })

    $("#searchOptions .searchFilterContainer,.searchIdBoxContainer").css({
        "padding":"1em 1.2em"
    })

    $("#tag_list_search_by_id").css({width:220, height:40})

    $("#searchOptions h3").css({
        "background-color":"#FFFFFF",
        height:25,
        "line-height":"25px",
        "padding-left":3
    })
    $("#searchOptions").accordion({
        icons:false,
        animated:"slide"
    });
    automatically_clear_search_by_id();
}

function automatically_clear_search_by_id(){
    $( "#searchOptions" ).on( "accordionchange", function( event, ui ) {
        // Resets the value of the question search by id field upon changing to search by filters mode
        if (ui.newHeader.text()=="Search by Filters")
        {   $("#tag_list_search_by_id").val("");
    }
} )
}
function associateAjaxCallForChangeDatabaseSelectBox(){
    $("#search_db").change(function(){
        var db = $("#search_db").val();
        var qbt = $("#search_db").find('option:selected').data("question_bank_type");
        $.ajax({//Make the Ajax Request
            type: "GET",
            url: '/assessment_tool/update_search_filter',
            data: {question_bank_id: db,quiz:'',question_bank_type: qbt},
            beforeSend:  function() {
                $('.spinner-gif').show();
                //$('#progress-indicator').show();
                //$("#users_list").css('opacity',0.6);
                //$(".filters :input").attr("disabled", true);
            },
            success: function(html){//html = the server response html code
                $('.spinner-gif').hide();
                $('.loading').hide();
                alert("Success ! Database changed to "+ $("#search_db :selected").text() +".");
                //$('#progress-indicator').hide();
                //$("#users_list").css('opacity','');
                //$(".filters :input").attr("disabled", false);
            },
            fail:function(){
                $('.spinner-gif').hide();
                $('.loading').hide();
                alert("Oops ! Something went wrong. Try changing the query terms");
            }
        });
    })
}
function attachLiveEventsForDynamicEntities(){
    // shows explanation field for the question upon clicking
    $(".show_explanation_field").live('click',function(){
        var $this = $(this);
        var $explanation_field = $this.closest(".question_container").find(".extra_explanation");
        $explanation_field.show();
        $this.hide();
        return false;
    })

}
function setupEventsForStaticEntities(){
    // hides remove link from individual question
    $("#individualQuestion .remove_questions").hide();

}

function random_questions_selector(){
    var all_ids = $(".all_ids").html().split(',');
    question_array.push(all_ids)
    $( "#addQuestions" ).hide();
}
