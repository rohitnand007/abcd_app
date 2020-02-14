var response={};
var max_img_width_ans = 200;
var max_img_height_ans = 200;
var logo = " ";
var description;

$(document).ready(function(){
    $('#textarea-description').val(description);
    $('#DescriptionModal').click(function() {
        var buttonOffset = $(this).offset();
        $('.description-modal-dialog').css('width', '50%').css('margin-left', buttonOffset['left']).css('margin-top', buttonOffset['top'] + 1.5 * $(this).height() - $(window).scrollTop() + 10);
        $('.modal-description').css('height', '235px');
        $('.tagbox-answer').addClass('hidden');
        $('.modal-description').removeClass('hidden');
        $('#myModal').modal('show');
    });
    $('#AddDescription').click(function() {
        description = $('#textarea-description').val();
        if (description) {
            $('.description').empty().append('<h3 class="description-heading" >Instructions for the Activity:</h3><p class="description_text">' + description + '</p>');
            $('.description').height('auto');
            $('.answer_options').height($('.canvas_content').outerHeight(false) - $('.tag_options').outerHeight(true));
        } else {
            $('.description').empty().height(40);
        }
    });

    $(".next ").click(function(){
        $(".nav-pills > li").removeClass("active");
        $(".mynaming-tab").addClass("active");
    })
    $(".back-btn").click(function(){
        $(".nav-pills > li").addClass("active");
        $(".mynaming-tab").removeClass("active");
    })

    /*Regarding the Template Page */
    $(".dropdown-menu li").click(function(){
        var text =$(this).text();
        var $div = $(this).parent().parent();
        $div.children(".form-control").html('<span>'+text+'</span>\
		<span class="glyphicon glyphicon-chevron-down " style="float: right;color:#76c4ac"></span>');
    });

    /* Regarding the Activity Page */
    populateTable();
    afterClick();
    $('.input-image').click(function(event){
        this.value = '';
    });
    $('.input-image').change(function(event){
        addImagetoTable(event);
    });

    $(".for-image").on({
        'mouseenter':function(){
            $(this).find('img').attr('src','/assets/activities/image-2.png');
        },'mouseleave':function(){
            $(this).find('img').attr('src','/assets/activities/image.png');
        }
    });
    $(".for-text").on({
        'mouseenter':function(){
            $(this).find('img').attr('src','/assets/activities/Ktext-2.png');
        },'mouseleave':function(){
            $(this).find('img').attr('src','/assets/activities/Ktext.png');
        }
    });
    $(".input-group-view > input").focus(function(){
        $(this).parent().find(".glyphicon").css({"color":"green"});
    });
    $(".input-group-view > input").blur(function(){
        $(this).parent().find(".glyphicon").css({"color":"grey"});
    });
    $(".activity-glyphicon").click(function(){
        $(this).parent().find("input").focus();
    })
    $(".save-template").mousedown(function(event){
        $(this).contextmenu(function() {
            return false;
        });
        var keycode = event.which;
        if(keycode == 1){
            $(".save-template").css({"color":"white"});
            //TO DO: Make a ajax call with this json
            //var url = document.location.origin + '/ignitor-web/match_the_item.html?value=' + JSON.stringify(createFinalJSON()) + '';
            //window.open(url);
            $.ajax({
                url: "/learning_activities",
                dataType: 'json',
                type: 'POST',
                data: JSON.stringify(createFinalJSON()),
                contentType: "application/json",
                cache: false,
                success: function(data, textStatus, jqXHR)
                {
                    window.history.pushState({},"new url","/learning_activities");
                    window.location.reload();

                },
                error: function(jqXHR, textStatus, errorThrown)
                {
                    alert("error in saving");
                }
            });
        }
    });

    $('.preview-btn').mousedown(function(event) {
        $(this).contextmenu(function() {
            return false;
        });
        response = createFinalJSON();
        var responsesize = 0;
        var eachkeysize = 0;
        var botherr = 0; /*For the Upload err to appear only once */
        var firstrowisless = 0;
        $.each(response,function(key,value){
            if(isNumericKey(key) ){
                $.each(value,function(){
                    responsesize++;
                    eachkeysize++;
                });
                if(botherr < 1){
                    if(eachkeysize !=0 && eachkeysize !=2 && responsesize == 1){
                        firstrowisless ++;
                    }
                    else if(eachkeysize !=0 && eachkeysize !=2 && responsesize > 2){
                        UploadErr("Must Enter both Question and Answer in a row");
                        botherr++;
                    }
                }
                eachkeysize = 0;
            }
        });
        if(firstrowisless ==1 && responsesize > 2){
            UploadErr("Must Enter both Question and Answer in a row");
        }
        if(responsesize < 2){
            UploadErr("Enter atleast one Question & Answer");
        }else{
            var keycode = event.which;
            if(keycode == 1){
                $(".preview-btn").css({"color":"white"});
                $(".preview-modal-body").playMatchtheItem(response,"download/");
                $("#scroll-top").css({"visibility":"hidden"});
                $("#scroll-bottom").css({"visibility":"hidden"});
            }else if (keycode == 3 && botherr == 0) {
                var testUrl = document.location.origin + '/ignitor-web/play_match_the_item.html?value=' + JSON.stringify(response) + '';
                window.open(testUrl);
            }
        }
    });

    $(".logo-btn").click(function(){
        $(".logo-upload").trigger("click");
    });
    $('.logo-upload').click(function(event){
        this.value = '';
    });
    $('.logo-upload').change(function(event){
        newLogoImage(event);
    });

    //TODO: change this to check if this edit view.
    if(document.URL.split('?')[1]){
        //Showing loader while activity is being restored
        $.loader({
            className:"blue-with-image-2",
            content:''
        });
        //TODO: get activity id instead of actual json from url
        var json=document.URL.split('value=')[1];
        if(json){
            var finaljson = JSON.parse(decodeURIComponent(json));
            //TODO: get the json with ajax request with the above id and call the below function with the result json.
            forSaveTemplate(finaljson);
            //Closing loader once everything is restored.
            $.loader('close');
        }
    }
});

function populateTable(){
    var append_data=' ';
    for(var i=0;i<6;i++){
        append_data += '\
      <tr>\
    	<td style="width:44%;">\
        	<div id="question-'+i+'" class="initial-row">\
        		<div class="wrap">\
        			<div class="for-image" id="image-left-'+i+'"><img src="/assets/activities/image.png" /></div>\
        			<div class="for-center"><p>Or</p></div>\
        			<div class="for-text" id="text-left-'+i+'"><img src="/assets/activities/Ktext.png"/></div>\
        		</div>\
        		<div>\
        			<p class="in-row">Click any of the above icons to add media or text</p>\
        		</div>\
        	</div>\
        	\
        	<div class="click-result" id="click-result-text-question-'+i+'">\
        		<p class="reset text-reset" style="float:right;margin-top:20px">Reset</p>\
        		<div class="input-group-view">\
        		<input type="text" placeholder="Add Text" maxlength="60" style="width:250px"/>\
        		<span class="glyphicon glyphicon-pencil activity-glyphicon"></span>\
        		</div>\
        		<p class="text-warning input-group-view-warning">Maximum number of characters is 60</p>\
        	</div>\
        	\
        	<div class="click-result" id="click-result-image-question-'+i+'">\
        		<p class="reset image-reset" style="float:right;margin-top:19px;">Reset</p>\
        		<div class="choose-file">\
	        		<span>Upload from computer</span>\
	        		<input class="input-image add-image" name="Select File" type="file" accept=".jpg, .jpeg, .png"/>\
	        		 <span style="float:right;padding-right:10px;"><img src="/assets/activities/upload.png" style="padding-bottom:3%" alt="Upload"></span>\
        	</div>\
     		<p class="text-warning choose-file-warning">Image size should be less than 200 * 200</p>\
        	</div>\
        	\
        	<div class="upload-result" id="upload-result-image-question-'+i+'">\
        		<p class="reset " style="padding-left:16%;padding-top:15px;">Reset</p>\
        		<div><img  class="added-image" id="image-question-'+i+'"src=""/></div>\
        	</div>\
        	\
      </td>\
        \
         \
      <td style="width:12%;">\
        	<img src="/assets/activities/paring.png" class="pair-image" />\
      </td>\
        \
         \
      <td style="width:44%;">\
	      <div id="answer-'+i+'" class="initial-row">\
	      	  <div class="wrap">\
	            <div class="for-image" id="image-right-'+i+'"><img src="/assets/activities/image.png" /></div>\
	            <div class="for-center"><p>Or</p></div>\
	            <div class="for-text" id="text-right-'+i+'"><img src="/assets/activities/Ktext.png"/></div>\
	          </div>\
	          <div>\
	            <p class="in-row">Click any of the above icons to add media or text </p>\
	          </div>\
	     </div>\
	      \
	     <div class="click-result" id="click-result-text-answer-'+i+'">\
	          <p class="reset text-reset" style="float:right;margin-top:20px">Reset</p>\
	          <div class="input-group-view">\
      		<input type="text" placeholder="Add Text" maxlength="60" class="clue-answer-text" style="width:250px"/>\
      		<span class="glyphicon glyphicon-pencil activity-glyphicon"></span>\
      		</div>\
      		<p class="text-warning input-group-view-warning">Maximum number of characters is 60</p>\
	     </div>\
	     \
	     <div class="click-result" id="click-result-image-answer-'+i+'">\
	     	<p class="reset image-reset" style="float:right;margin-top:19px;">Reset</p>\
	     	<div class="choose-file">\
		        <span>Upload from computer</span>\
		        <input class="input-image add-image" name="Select File" type="file" accept=".jpg, .jpeg, .png"/>\
		        <span style="float:right;padding-right:10px;"><img src="/assets/activities/upload.png" style="padding-bottom:3%" alt="Upload"></span>\
	     </div>\
	     <p class="text-warning choose-file-warning">Image size should be less than 200 * 200</p>\
	     </div>\
	     \
	    <div class="upload-result" id="upload-result-image-answer-'+i+'">\
	    	<p class="reset" style="padding-left:16%;padding-top:15px;">Reset</p>\
	    	<div><img  class="added-image" id="image-answer-'+i+'"src=""/></div>\
	    </div>\
	    \
      </td>\
	   \
	    \
  </tr>' ;
    }
    $("#activity-table").append(append_data);
    $(".reset").hover(function(){
        $(this).toggleClass("reset-hover")
    });
}

function afterClick(){
    $(".click-result").hide();
    $(".upload-result").hide();
    $(".for-text").click(function(){
        var text_click_id = $(this).parent().parent().attr('id');
        $(this).parent().parent().hide();
        var click_result = "click-result-text-"+text_click_id;
        $("#"+click_result).show();
        $("#"+click_result).css({"width":"250px"});
        $("#"+click_result).find("input").focus();
        $(".text-reset").css({"top":"-3px"});
    });
    $(".for-image").click(function(){
        var image_click_id = $(this).parent().parent().attr('id');
        $(this).parent().parent().hide();
        var click_result = "click-result-image-"+image_click_id;
        $("#"+click_result).show();
        $("#"+click_result).css({"width":"250px"});
        $(".image-reset").css({"top":"1px"});
    });
    $(".reset").click(function(){
        var reset_click=$(this).parent().attr('id');
        var reset_results = reset_click.split("-");
        $(this).parent().hide();
        $("#click-result-text-"+reset_results[3]+"-"+reset_results[4]).find("input").val("");
        $("#image-"+reset_results[3]+"-"+reset_results[4]).attr("src","");
        $("#"+reset_results[3]+"-"+reset_results[4]).show();
        response[reset_results[4].toString()] ={};
    });
}

function addImagetoTable(event){
    var parentid = $(event.target).parent().parent();
    parentsplit = parentid.get(0).id.split("-");
    var type= parentsplit[3];
    var number=parentsplit[4];
    child_class = $(event.target);
    uploadInputImage(child_class,function(url){
        $("#image-"+type+"-"+number).attr('src',url);
        $('<img src="' + url + '"/>').load(function(){
            var w = this.width;
            var h = this.height;
            if (w < max_img_width_ans && h < max_img_height_ans) {
                $("#upload-result-image-"+type+"-"+number).show();
                $("#click-result-image-"+type+"-"+number).hide();

            }
            else {
                UploadErr('The image size is too big to upload. <br> Size sholud be less than 200 * 200');
                $("#image-"+type+"-"+number).attr("src","");
            }
        });
    },function(){
        UploadErr('The image couldnot be uploaded');
    })
}

function newLogoImage(event){
    var logoclass = $(event.target);
    uploadLogo(logoclass,function(url){
        $(".logo-btn").find("img").attr("src",url);
        logo = url.split("download/")[1];
    },function(url){
        UploadErr('The image couldnot be uploaded');
    })
}
function uploadLogo(logoclass,succesFunc,failureFunc){
    var files = $(logoclass).get(0).files;
    $.loader({
        className:"blue-with-image-2",
        content:''
    });
    uploadFile(files,"uploadfile",function(data, textStatus, jqXHR, uploaded_url){
        succesFunc(uploaded_url);
        $.loader('close');
    },function(data, textStatus,  errorThrown){
        $.loader('close');
    });
}


function uploadInputImage(child_class,succesFunc,failureFunc){
    var files = $(child_class).get(0).files;
    $.loader({
        className:"blue-with-image-2",
        content:''
    });
    uploadFile(files,"uploadfile",function(data, textStatus, jqXHR, uploaded_url){
        succesFunc(uploaded_url);
        $.loader('close');
    },function(data, textStatus,  errorThrown){
        failureFunc();
        $.loader('close');
    });
}

function createFinalJSON(){
    response["images"] = [];
    for(var i=0;i<6;i++){
        var question_image = $("#image-question-"+i).attr("src");
        var answer_image = $("#image-answer-"+i).attr("src");
        var question_text=$("#click-result-text-question-"+i).children(".input-group-view").children("input[type='text']").val();
        var answer_text=$("#click-result-text-answer-"+i).children(".input-group-view").children("input[type='text']").val();
        if(question_image != ""){
            addImagetoJSON("question",i,question_image);
        }else if(question_text != ""){
            addTexttoJSON("question",i,question_text);
        }
        if(answer_image != ""){
            addImagetoJSON("answer",i,answer_image);
        }else if(answer_text != ""){
            addTexttoJSON("answer",i,answer_text);
        }
    }
    response["name"] = $("#contentName").val();
    response["description"] = $("#description").val();
    response["class"] = $("#class-name").val();
    response["subject"] =$("#subject-name").val();
    response["topics"] = $("#chapter").val();
    response['learning_activity_type'] = $('#learning_activity_type').val();
    if(logo != " "){
        response["logo"] = logo;
    }else{
        response["logo"] = "ignitor_logo.png";
    }
    response["images"].push(response["logo"]);
    return response;
}

function addTexttoJSON(type,number,value){
    var textValue={};
    var text={};
    var types={};$('#textarea-description').val(description);
    textValue["value"]=value;
    text["text"] = textValue;
    types["type"] = text;
    response[number.toString()][type] = types;
}

function addImagetoJSON(type,number,url){
    var image={};
    var value={};
    var types={};
    url = url.split("download/")[1];
    value["value"]=url;
    image["image"] = value;
    types["type"] = image;
    response[number.toString()][type] = types;
    response["images"].push(url);
}

function forSaveTemplate(finaljson){
    var urlJson=finaljson;
    $("#contentName").val(urlJson["name"]);
    $("#description").val(urlJson["description"]);
    $("#class-name").val(urlJson["class"]);
    $("#subject-name").val(urlJson["subject"]);
    $("#chapter").val(urlJson["topics"]);
    if (urlJson['instructions'] != undefined) {
        $("#textarea-description").val(urlJson["instructions"]);
    }

    $.each(urlJson,function(key,value){
        if(isNumericKey(key)){
            var keylength = Object.keys(value);
            $.each(urlJson[key],function(newkey,newvalue){
                if(newkey == "answer"){
                    $.each(newvalue["type"],function(type,typevalue){
                        if(type == "text"){
                            $("#answer-"+key).hide();
                            $("#click-result-text-answer-"+key).show();
                            $("#click-result-text-answer-"+key).find("input").val(typevalue["value"]);
                            $("#click-result-text-answer-"+key).css({"width":"250px"});
                            $("#click-result-text-answer-"+key).css({"top":"-3px"});
                        }else if(type == "image"){
                            $("#answer-"+key).hide();
                            $("#upload-result-image-answer-"+key).show();
                            $("#image-answer-"+key).attr('src',imagePrefix(typevalue["value"]));
                            $("#click-result-image-answer-"+key).css({"width":"250px"});
                            $(".image-reset").css({"top":"1px"});
                        }
                    })
                }else if(newkey == "question"){
                    $.each(newvalue["type"],function(type,typevalue){
                        if(type == "text"){
                            $("#question-"+key).hide();
                            $("#click-result-text-question-"+key).show();
                            $("#click-result-text-question-"+key).find("input").val(typevalue["value"]);
                            $("#click-result-text-question-"+key).css({"width":"250px"});
                            $("#click-result-text-question-"+key).css({"top":"-3px"});
                        }else if(type == "image"){
                            $("#question-"+key).hide();

                            $("#upload-result-image-question-"+key).show();
                            $("#image-question-"+key).attr('src',imagePrefix(typevalue["value"]));
                            $("#click-result-image-question-"+key).css({"width":"250px"});
                            $(".image-reset").css({"top":"1px"});
                        }
                    })
                }
            })
        }
    });

    var logo_prefix = "images/"
    if(urlJson["logo"] != "ignitor_logo.png"){
        logo_prefix = "download/";
    }
    $(".logo-btn").find("img").attr("src",logo_prefix+urlJson["logo"]);
    logo = urlJson["logo"];
}

function UploadErr(alert_text){
    $.alert({
        title: 'Error!',
        content: alert_text,
        confirmButtom : "Okay",
        confirmButtonClass: 'error-confirm',
        confirm: function(){
        }
    });
}

function isNumericKey(value){
    var numericKeys = false;
    if(!(isNaN(parseInt(value,10)))){
        numericKeys = true;
    }
    return numericKeys;
}

$(function(){
    for(var i=0;i<6;i++){
        response[i.toString()] = {};
    }
});