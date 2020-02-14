var cardNumber = 1;
var inputLimit = 30;
var instructionsInputLimit = 350;
var clueAnswerInputLimit = 350;
var maxImageWidth = 500;
var maxImageHeight = 500;
var minImageWidth = 250;
var minImageHeight = 150;
var className;
var subject;
var topics;
var logo = 'ignitor_logo.png';
var description;
var instructions
var name;
var clueAnswer = '<img src="/assets/activities/T-1.png" class="text-active">\
	<img src="/assets/activities/I-2.png" class="pic-deactive">\
	<img src="/assets/activities/T-2.png" class="text-deactive">\
	<img src="/assets/activities/I-1.png" class="pic-active">\
	<div class="col-xs-12 text-center text-details" style="padding-top: 30px;padding-bottom: 30px;">\
	<p style="color:#a6a6a6">Add the text for this card</p>\
	<textarea class="clue-answer-text" maxlength = '+clueAnswerInputLimit+' rows="3" placeholder="Add Text"></textarea>\
	<p class="clue-answer-image-restrictions">Maximum character limit is 350</p>\
	</div>\
	<div class="col-xs-12 text-center image-details">\
	<div><img src="" class="clue-answer-image"></div>\
	<div class = "reset-image">\
	<input name="Change File" type="file" accept=".jpg, .jpeg, .png" class="edit-image" title=" ">\
	<span>Reset</span>\
	<span class="glyphicon glyphicon-edit edit-image-glyph" style="display:none"></span>\
	<span class="glyphicon glyphicon-trash delete-image" style="display:none"></span>\
	</div>\
	</div>\
	<div class="col-xs-12 text-center image-change-details">\
	<img src="/assets/activities/picture.png" class="picture-hover picture-add">\
	<p style="font-size:12px">Upload an image for this card</p>\
	<div class="choose-file" >\
	<input name="Change File" type="file" accept=".jpg, .jpeg, .png" class="change-image">\
	<span >Upload a picture</span>\
	<span style="padding-left:5px;"><img src="/assets/activities/upload.png" style="padding-bottom:3%" alt="Upload"></span>\
	</div>\
	<p class="clue-answer-image-restrictions">Maximum size is 500px X 500px and Minimum size is 250px x 150px</p>\
	</div>';
var emptyClueAnswer = '<div class="col-xs-12 no-padding">\
	<div class="col-xs-5 text-center" style="padding-top: 40px;\
	padding-left: 100px;">\
	<img src="/assets/activities/picture.png" class="picture-hover picture-add-empty">\
	<p style="font-size:12px">Upload an image for this card</p>\
	<div class="choose-file" >\
	<input name="Change File" type="file" accept=".jpg, .jpeg, .png" class="add-image">\
	<span >Upload a picture</span>\
	<span style="padding-left:5px;"><img src="/assets/activities/upload.png" style="padding-bottom:3%" alt="Upload"></span>\
	</div>\
	<p class="clue-answer-image-restrictions">Maximum size is 500px X 500px and Minimum size is 250px x 150px</p>\
	</div>\
	<div class="col-xs-1" style="padding-top: 100px;padding-left: 50px;">OR</div>\
	<div class="col-xs-5 text-center" style="padding-top: 40px;\
	padding-left: 90px;">\
	<img src="/assets/activities/text.png" class="text-hover">\
	<p style="font-size:12px">Add text for this card</p>\
	<button type="button" class="btn add-text" >Add text</button>\
	</div>\
	</div>';
function addToList(){
    $('#empty-list').hide();
    $('#empty-clues-answers').hide();
    $('#card-tabs').append('<li class="col-xs-12 no-padding cardsParent no-border-radius" role="presentation" id="card-'+cardNumber+'"><a href="#card-body-'+cardNumber+'" class="cards no-border-radius" aria-controls="card-body-'+cardNumber+'" role="tab" data-toggle="tab">Card Name</a><span class="glyphicon glyphicon-trash delete-card"></span></li>');
    $('#clues-answers>.tab-content').append('<div role="tabpanel" class="tab-pane card-body" id="card-body-'+cardNumber+'">\
			<div class="clue-details"><span class="col-xs-12 text-left" style="color:#ffffff;font-size:16px;background-color: #2fb38e;padding-top:5px;padding-bottom:5px">Clue</span>'+emptyClueAnswer+'</div>\
			<div class="answer-details"><span class="col-xs-12 text-left" style="color:#ffffff;font-size:16px;background-color: #2fb38e;padding-top:5px;padding-bottom:5px">Answer</span>'+emptyClueAnswer+'</div>\
	</div>');
    $('.cards').parent().removeClass('active');
    $('.card-body').removeClass('active');
    $('#card-'+cardNumber).addClass('active');
    $('#card-body-'+cardNumber).addClass('active');
    $( '#card-tabs' ).sortable();
    $('#card-body-'+cardNumber+' .add-text').click(function(){
        var that = $(this);
        addText(that);
    });
    $('#card-body-'+cardNumber+' .text-hover').click(function(){
        var that = $(this);
        addText(that);
    });
    $('#card-body-'+cardNumber+' .add-image').change(function(){
        var that = $(this);
        addImage(that);
    });

    $('#card-body-'+cardNumber+' .picture-add-empty').click(function(){
        var that = $(this);
        var cardBodyId = that.parent().parent().parent().parent().attr('id');
        var textClass = that.parent().parent().parent().attr('class');
        $('#'+cardBodyId+'>.'+textClass+' .add-image').trigger('click');
    });

    $('#card-'+cardNumber+' .cards').click( function() {
        var that = $(this);
        addInput(that);
    });
    $('#card-'+cardNumber+' .delete-card').click(function(){
        confirmDelete($(this));
    });
    $('.picture-hover').mouseenter(function(){
        $(this).attr('src','/assets/activities/picture-2.png');
    });
    $('.picture-hover').mouseleave(function(){
        $(this).attr('src','/assets/activities/picture.png');
    });
    $('.text-hover').mouseenter(function(){
        $(this).attr('src','/assets/activities/text-2.png');
    });
    $('.text-hover').mouseleave(function(){
        $(this).attr('src','/assets/activities/text.png');
    });
    cardNumber++;
}
function addText(that){
    var cardBodyId = that.parent().parent().parent().parent().attr('id');
    var textClass = that.parent().parent().parent().attr('class');
    that.parent().parent().remove();
    $('#'+cardBodyId+'>.'+textClass).append(clueAnswer);
//	changeEditTextCss();
    editText();
    $('#'+cardBodyId+'>.'+textClass+' .image-details').hide();
    $('#'+cardBodyId+'>.'+textClass+' .pic-active').hide();
    $('#'+cardBodyId+'>.'+textClass+' .text-deactive').hide();
    $('#'+cardBodyId+'>.'+textClass+' .image-change-details').hide();
    $('#'+cardBodyId+'>.'+textClass+' .pic-deactive').click(function(){
        if($('#'+cardBodyId+'>.'+textClass+' .text-details  .clue-answer-text').val()){
            confirmChange('pic',$(this));
        }
        else{
            picActive(cardBodyId,textClass);
        }

    });
    $('#'+cardBodyId+'>.'+textClass+' .change-image').change(function(){
        changeFileInput(function(uploaded_url){
            $.loader({
                className:"blue-with-image-2",
                content:''
            });
            var img = $('<img src="' +uploaded_url+ '"/>').load(function() {
                var w = this.width;
                var h = this.height;
                if (w <= maxImageWidth && h <= maxImageHeight && w >= minImageWidth && h >= minImageHeight) {
                    $('#'+cardBodyId+'>.'+textClass+' .image-details .clue-answer-image').attr('src',uploaded_url);
                    $.loader('close');
                    $('#'+cardBodyId+'>.'+textClass+' .image-change-details').hide();
                    $('#'+cardBodyId+'>.'+textClass+' .image-details').show();
                } else {
                    $.loader('close');
                    UploadErr('Maximum size is 500px x 500px and Minimum size is 250px x 150px');
                }
            });

        },function(){},cardBodyId,textClass);

    });
    $('#'+cardBodyId+'>.'+textClass+' .picture-add').click(function(){
        $('#'+cardBodyId+'>.'+textClass+' .change-image').trigger("click");
    });

    $('#'+cardBodyId+'>.'+textClass+' .edit-image').change(function(){
        editFileInput(function(uploaded_url){
            $.loader({
                className:"blue-with-image-2",
                content:''
            });
            var img = $('<img src="' +uploaded_url+ '"/>').load(function() {
                var w = this.width;
                var h = this.height;
                if (w <= maxImageWidth && h <= maxImageHeight && w >= minImageWidth && h >= minImageHeight) {
                    $('#'+cardBodyId+'>.'+textClass+' .image-details .clue-answer-image').attr('src',uploaded_url);
                    $.loader('close');
                    $('#'+cardBodyId+'>.'+textClass+' .image-change-details').hide();
                    $('#'+cardBodyId+'>.'+textClass+' .image-details').show();
                } else {
                    $.loader('close');
                    UploadErr('Maximum size is 500px x 500px and Minimum size is 250px x 150px');
                }
            });

        },function(){},cardBodyId,textClass);

    });
    $('#'+cardBodyId+'>.'+textClass+' .text-deactive').click(function(){
        if($('#'+cardBodyId+'>.'+textClass+' .image-details .clue-answer-image').attr('src')){
            confirmChange('text',$(this));
        }
        else{
            textActive(cardBodyId,textClass);
        }

    });
    $('#'+cardBodyId+'>.'+textClass+' .add-clue-answer-text').click(function(){
        appendText($(this));
    });
}
function addImage(that){

    var cardBodyId = that.parent().parent().parent().parent().parent().attr('id');
    var imageClass = that.parent().parent().parent().parent().attr('class');


    uploadFileInput(function(uploaded_url){
        $.loader({
            className:"blue-with-image-2",
            content:''
        });
        var img = $('<img src="' +uploaded_url+ '"/>').load(function() {
            var w = this.width;
            var h = this.height;
            if (w <= maxImageWidth && h <= maxImageHeight && w >= minImageWidth && h >= minImageHeight) {
                $('#'+cardBodyId+'>.'+imageClass).append(clueAnswer);
//				changeEditTextCss();
                editText();
                $('#'+cardBodyId+'>.'+imageClass+' .image-details .clue-answer-image').attr('src',uploaded_url);
                $.loader('close');
                that.parent().parent().parent().remove();
                $('#'+cardBodyId+'>.'+imageClass+' .text-details').hide();
                $('#'+cardBodyId+'>.'+imageClass+' .text-active').hide();
                $('#'+cardBodyId+'>.'+imageClass+' .pic-deactive').hide();
                $('#'+cardBodyId+'>.'+imageClass+' .image-change-details').hide();
                $('#'+cardBodyId+'>.'+imageClass+' .text-deactive').click(function(){
                    if($('#'+cardBodyId+'>.'+imageClass+' .image-details .clue-answer-image').attr('src')){
                        confirmChange('text',$(this));
                    }
                    else{
                        textActive(cardBodyId,imageClass);
                    }
                });
                $('#'+cardBodyId+'>.'+imageClass+' .pic-deactive').click(function(){
                    if($('#'+cardBodyId+'>.'+imageClass+' .text-details  .clue-answer-text').val()){
                        confirmChange('pic',$(this));
                    }
                    else{
                        picActive(cardBodyId,imageClass);
                    }
                });
                $('#'+cardBodyId+'>.'+imageClass+' .change-image').change(function(){
                    changeFileInput(function(uploaded_url){
                        $.loader({
                            className:"blue-with-image-2",
                            content:''
                        });
                        var img = $('<img src="' +uploaded_url+ '"/>').load(function() {
                            var w = this.width;
                            var h = this.height;
                            if (w <= maxImageWidth && h <= maxImageHeight && w >= minImageWidth && h >= minImageHeight) {
                                $('#'+cardBodyId+'>.'+imageClass+' .image-details .clue-answer-image').attr('src',uploaded_url);
                                $.loader('close');
                                $('#'+cardBodyId+'>.'+imageClass+' .image-change-details').hide();
                                $('#'+cardBodyId+'>.'+imageClass+' .image-details').show();
                            } else {
                                $.loader('close');
                                UploadErr('Maximum size is 500px x 500px and Minimum size is 250px x 150px');
                            }
                        });


                    },function(){},cardBodyId,imageClass);

                });
                $('#'+cardBodyId+'>.'+imageClass+' .edit-image').change(function(){
                    editFileInput(function(uploaded_url){
                        $.loader({
                            className:"blue-with-image-2",
                            content:''
                        });
                        var img = $('<img src="' +uploaded_url+ '"/>').load(function() {
                            var w = this.width;
                            var h = this.height;
                            if (w <= maxImageWidth && h <= maxImageHeight && w >= minImageWidth && h >= minImageHeight) {
                                $('#'+cardBodyId+'>.'+imageClass+' .image-details .clue-answer-image').attr('src',uploaded_url);
                                $.loader('close');
                                $('#'+cardBodyId+'>.'+imageClass+' .image-change-details').hide();
                                $('#'+cardBodyId+'>.'+imageClass+' .image-details').show();
                            } else {
                                $.loader('close');
                                UploadErr('Maximum size is 500px x 500px and Minimum size is 250px x 150px');
                            }
                        });


                    },function(){},cardBodyId,imageClass);

                });
                $('#'+cardBodyId+'>.'+imageClass+' .picture-add').click(function(){
                    $('#'+cardBodyId+'>.'+imageClass+' .change-image').trigger("click");
                });

                $('#'+cardBodyId+'>.'+imageClass+' .add-clue-answer-text').click(function(){
                    appendText($(this));
                });
            }
            else {
                $.loader('close');
                UploadErr('Maximum size is 500px x 500px and Minimum size is 250px x 150px');
            }
        });

    },function(){},cardBodyId,imageClass);

}
function appendText(that){
    var cardBodyId = that.parent().parent().parent().parent().parent().attr('id');
    var textClass = that.parent().parent().parent().parent().attr('class');
    var text = $('#'+cardBodyId+'>.'+textClass+' .text-details textarea').val();
    $('#'+cardBodyId+'>.'+textClass+' .text-details .upload-text').html(text);
}
function picActive(cardBodyId,picClass){
    $('#'+cardBodyId+'>.'+picClass+' .pic-active').show();
    $('#'+cardBodyId+'>.'+picClass+' .text-deactive').show();
    $('#'+cardBodyId+'>.'+picClass+' .text-active').hide();
    $('#'+cardBodyId+'>.'+picClass+' .pic-deactive').hide();
    $('#'+cardBodyId+'>.'+picClass+' .text-details .clue-answer-text').val('');
    $('#'+cardBodyId+'>.'+picClass+' .text-details .upload-text').html('');
    $('#'+cardBodyId+'>.'+picClass+' .text-details').hide();
    $('#'+cardBodyId+'>.'+picClass+' .image-details').hide();
    $('#'+cardBodyId+'>.'+picClass+' .image-change-details').show();
    $('.picture-hover').mouseenter(function(){
        $(this).attr('src','/assets/activities/picture-2.png');
    });
    $('.picture-hover').mouseleave(function(){
        $(this).attr('src','/assets/activities/picture.png');
    });


}
function textActive(cardBodyId,picClass){
    $('#'+cardBodyId+'>.'+picClass+' .pic-active').hide();
    $('#'+cardBodyId+'>.'+picClass+' .text-deactive').hide();
    $('#'+cardBodyId+'>.'+picClass+' .text-active').show();
    $('#'+cardBodyId+'>.'+picClass+' .pic-deactive').show();
    $('#'+cardBodyId+'>.'+picClass+' .image-details').hide();
    $('#'+cardBodyId+'>.'+picClass+' .image-details .clue-answer-image').attr('src','');
    $('#'+cardBodyId+'>.'+picClass+' .text-details').show();
    $('#'+cardBodyId+'>.'+picClass+' .image-change-details').hide();
}
function confirmChange(format,that){
    var cardBodyId = that.parent().parent().attr('id');
    var picClass = that.parent().attr('class');
    $.confirm({
        title: 'Confirm!',
        content: 'Changes will be lost.Are you sure?',
        confirmButton: 'Continue',
        cancelButton: 'Cancel',
        title: false,
        confirmButtonClass: 'btn-confirm',
        cancelButtonClass: 'btn-cancel',
        columnClass: 'col-xs-4 col-xs-offset-5',
        backgroundDismiss: false,
        confirm: function(){
            if(format == 'text'){
                textActive(cardBodyId,picClass);
            }
            else{
                picActive(cardBodyId,picClass);
            }
        },
        cancel: function(){
        }

    });
    changeConfirmCss();
}

function confirmDelete(that){
           $.confirm({
                   title: 'Confirm!',
                       content: 'Do you want to delete this card ?',
                       confirmButton: 'Delete',
                       cancelButton: 'Cancel',
                       title: false,
                       confirmButtonClass: 'btn-confirm',
                       cancelButtonClass: 'btn-cancel',
                       columnClass: 'col-xs-4 col-xs-offset-5',
                       backgroundDismiss: false,
                       confirm: function(){
                               deleteCard(that);
                       },
                   cancel: function(){
                       }

               });
}

function UploadErr(text){
    $.alert({
        title: 'Error!',
        content: text,
        confirmButton: 'Okay',
        confirmButtonClass: 'error-confirm',
        confirm: function(){
        }
    });
}
function changeConfirmCss(){
    $('.btn-confirm').parent().addClass('confirm-buttons');
    $('.btn-confirm').parent().parent().addClass('confirm-box');
}

function addInput(that){
    var cardId = that.parent().attr('id');
    console.log(that.width());
    if (that.find('input').length > 0) {
        return;
    }
    var currentText = that.text();
    if (currentText == 'Card Name'){
        currentText = '';
    }

    var $input = $('<input>').val(currentText)
        .css({
            'position': 'absolute',
            top: '-1px',
            left: '-1px',
            width: that.width()+30,
            height: that.parent().height()+1,
            opacity: 0.9,
            padding: '0px 0px 0px 15px',
            border : 'none'
        });
    $input.attr('maxlength',inputLimit);
    that.append($input);
    $input.focus();
    var tmpStr = $input.val();
    $input.val('');
    $input.val(tmpStr);
//	Handle outside click
    $(document).click(function(event) {

        if(!$(event.target).closest('#'+cardId).length) {
            if ($input.val()) {
                that.text($input.val());
            }
            that.find('input').remove();
        }
    });
}

function deleteCard(that){
    var id = that.parent().children('a').attr('href');

    var hasActiveClass = that.parent().hasClass('active');
    $(''+id).remove();
    that.parent().remove();
    var numberOfCards = $('#card-tabs li').length;
    if(numberOfCards == 0){
        cardNumber = 1;
        $('#empty-list').show();
        $('#empty-clues-answers').show();
    }
    else{
        if(hasActiveClass){
            $('#card-tabs li').first().addClass('active');
            var bodyId = $('#card-tabs li').first().children('a').attr('href');
            $(''+bodyId).addClass('active');
        }
    }

}
function changeFileInput(successFunc, failFunc,cardBodyId,picClass) {
    $('#'+cardBodyId+'>.'+picClass+' .change-image').get(0).files;
    uploadFile($('#'+cardBodyId+'>.'+picClass+' .change-image').get(0).files, 'uploadfile', function(data, textStatus, jqXHR, uploaded_url) {
        successFunc(uploaded_url);
    }, function(jqXHR, textStatus, errorThrown) {
        failFunc();
    });
}
function editFileInput(successFunc, failFunc,cardBodyId,picClass) {
    $('#'+cardBodyId+'>.'+picClass+' .edit-image').get(0).files;
    uploadFile($('#'+cardBodyId+'>.'+picClass+' .edit-image').get(0).files, 'uploadfile', function(data, textStatus, jqXHR, uploaded_url) {
        successFunc(uploaded_url);
    }, function(jqXHR, textStatus, errorThrown) {
        failFunc();
    });
}
function uploadFileInput(successFunc, failFunc,cardBodyId,picClass) {
//	$('#'+cardBodyId+'>.'+picClass+' .add-image').get(0).files;
    uploadFile($('#'+cardBodyId+'>.'+picClass+' .add-image').get(0).files, 'uploadfile', function(data, textStatus, jqXHR, uploaded_url) {
        successFunc(uploaded_url);
    }, function(jqXHR, textStatus, errorThrown) {
        failFunc();
    });
}
function continueFromTemplate(){
    $('.naming_tabs').removeClass('active');
    $('.naming_tabs1').addClass('active');
    $('#create-template-tab').removeClass('active');
    $('#create-activity-tab').addClass('active');
}
function backFromActivity(){
    $('.naming_tabs').addClass('active');
    $('.naming_tabs1').removeClass('active');
    $('#create-template-tab').addClass('active');
    $('#create-activity-tab').removeClass('active');
}
function editText(){
    $('.edit-text').click(function(){
        $(this).prev().focus();
    });
}
function changeEditTextCss(){
    $('.clue-answer-text').focusin(function(){
        $(this).next().css("color", "#76c4ac");
    });
    $('.clue-answer-text').focusout(function(){
        $(this).next().css("color", "#a6a6a6");
    });
}
function checkEntering(){
    var cardNameEntry;
    var isDataEntered;
    var isEntered = true;
    if ($('#card-tabs li').length == 0 || !instructions){
        isEntered = false;
    }
    else{
        $('#card-tabs li').each(function(index){
            var id = $(this).find('a').attr('href');
            cardNameEntry = $(this).find('a').html();
            isDataEntered = ($(id+'> .clue-details > div').hasClass('text-details') && $(id+'> .answer-details > div').hasClass('text-details'));
            var clueText = $(id+'> .clue-details > .text-details textarea').val();
            var clueImage = $(id+'> .clue-details > .image-details .clue-answer-image').attr('src');
            var answerText = $(id+'> .answer-details > .text-details textarea').val();
            var answerImage = $(id+'> .answer-details > .image-details .clue-answer-image').attr('src');
            if(!isDataEntered){
                isEntered = false;
                return;
            }
            else if(clueText == '' && clueImage == '' || answerText == '' && answerImage == ''){
                isEntered = false;
                return;
            }
        });
    }
    return isEntered;
}
function previewError(text){
    $.alert({
        title: 'Error!',
        content: text,
        confirmButton: 'Okay',
        confirmButtonClass: 'error-confirm',
        confirm: function(){
        }
    });
}
function createJSON(){
    var json = {};
    var finalJSON = [];
    var imagesArray = [];
    var indexOfImagesArray = 0;
    var clueType;
    var clueValue;
    var answerType;
    var answerValue;
    var numberOfCards = $('#card-tabs li').length;
    $('#card-tabs li').each(function(index){
        var response = {};
        response["clue"]={};
        response["answer"] = {};
        var id = $(this).find('a').attr('href');
        var cardName = $(this).find('input').val();
        if (!cardName){
            cardName = $(this).find('a').html();
        }
        var clueText = $(id+'> .clue-details > .text-details textarea').val();
        var clueImage = $(id+'> .clue-details > .image-details .clue-answer-image').attr('src');
        var answerText = $(id+'> .answer-details > .text-details textarea').val();
        var answerImage = $(id+'> .answer-details > .image-details .clue-answer-image').attr('src');
        if(clueText != ""){
            clueType = 'text';
            clueValue = clueText;
        }
        else if(clueImage != ""){
            clueType = 'image';
            clueValue = clueImage.split('/')[1];
            imagesArray[indexOfImagesArray] = clueValue;
            indexOfImagesArray++;
        }
        if(answerText != ""){
            answerType = 'text';
            answerValue = answerText;
        }
        else if(answerImage != ""){
            answerType = 'image';
            answerValue = answerImage.split('/')[1];
            imagesArray[indexOfImagesArray] = answerValue;
            indexOfImagesArray++;
        }
        response["clue"]["type"] = clueType;
        response["clue"]["value"] = clueValue;
        response["clue"]["cardName"] = cardName;
        response["answer"]["type"] = answerType;
        response["answer"]["value"] = answerValue;
        response["answer"]["cardName"] = cardName;
        finalJSON[index] = response;
    });
    imagesArray[indexOfImagesArray] = logo;
    name = $('#contentName').val();
    description = $('#description').val();
    className = $('#class').val();
    subject = $('#subject').val();
    topics = $('#topics').val();
    json["finalJSON"] = finalJSON;
    json["instructions"] = instructions;
    json["description"] = description;
    json["class"] = className;
    json["subject"] = subject;
    json["topics"] = topics;
    json['learning_activity_type'] = $('#learning_activity_type').val();
    json["name"] = name;
    json["logo"] = logo;
    json["images"] = imagesArray;
    console.log(json);
    return json;
}

function savingTemplate(){
    if(checkEntering()){
        var json = createJSON();
        var length = json["finalJSON"].length;
        //TODO : make an ajax request with the json created below
        //var url = document.location.origin + '/ignitor-web/flash_cards.html?value=' + JSON.stringify(json) + '';
        //window.open(url);
        $.ajax({
            url: "/learning_activities",
            dataType: 'json',
            type: 'POST',
            data: JSON.stringify(json),
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
    else{
        if(!instructions){
            previewError('You have not entered instructions');
        }
        else{
            previewError('You have not entered card data or not added card');
        }
    }
}
function uploadImageAfterSavingTemplate(cardBodyId,picClass,imageUrl){
    $('#'+cardBodyId+'>.'+picClass+' .pic-active').show();
    $('#'+cardBodyId+'>.'+picClass+' .text-deactive').show();
    $('#'+cardBodyId+'>.'+picClass+' .text-active').hide();
    $('#'+cardBodyId+'>.'+picClass+' .pic-deactive').hide();
    $('#'+cardBodyId+'>.'+picClass+' .text-details .clue-answer-text').val('');
    $('#'+cardBodyId+'>.'+picClass+' .text-details .upload-text').html('');
    $('#'+cardBodyId+'>.'+picClass+' .text-details').hide();
    $('#'+cardBodyId+'>.'+picClass+' .image-details').show();
    $('#'+cardBodyId+'>.'+picClass+' .image-details .clue-answer-image').attr('src',imageUrl);
    $('#'+cardBodyId+'>.'+picClass+' .image-change-details').hide();
}
function afterSavingTemplate(finaljson){
    var length = finaljson["finalJSON"].length;
    instructions = finaljson["instructions"];
    $('#contentName').val(finaljson["name"]);
    $('#description').val(finaljson["description"]);
    $('#class').val(finaljson["class"]);
    $('#subject').val(finaljson["subject"]);
    $('#topics').val(finaljson["topics"]);
    logo = finaljson["logo"];
    if(finaljson["logo"] == 'ignitor_logo.png'){
        $(".logo-btn").find("img").attr("src","images/"+finaljson["logo"]);
    }
    else{
        $(".logo-btn").find("img").attr("src","download/"+finaljson["logo"]);
    }
    for (i=0;i<length;i++){
        var presentCardNumber = cardNumber;
        addToList();
        $('#card-'+presentCardNumber).find('a').html(finaljson["finalJSON"][i]["clue"]["cardName"]);
        if(finaljson["finalJSON"][i]["clue"]["type"] == 'text'){
            $('#card-body-'+presentCardNumber+' >.clue-details .add-text').trigger("click");
            $('#card-body-'+presentCardNumber+' >.clue-details .clue-answer-text').val(finaljson["finalJSON"][i]["clue"]["value"]);
        }
        else if(finaljson["finalJSON"][i]["clue"]["type"] == 'image'){
            addText($('#card-body-'+presentCardNumber+'>.clue-details .add-text'));
            uploadImageAfterSavingTemplate('card-body-'+presentCardNumber,'clue-details',imagePrefix(finaljson["finalJSON"][i]["clue"]["value"]));
        }
        if(finaljson["finalJSON"][i]["answer"]["type"] == 'text'){
            $('#card-body-'+presentCardNumber+' >.answer-details .add-text').trigger("click");
            $('#card-body-'+presentCardNumber+' >.answer-details .clue-answer-text').val(finaljson["finalJSON"][i]["answer"]["value"]);
        }
        else if(finaljson["finalJSON"][i]["answer"]["type"] == 'image'){
            addText($('#card-body-'+presentCardNumber+'>.answer-details .add-text'));
            uploadImageAfterSavingTemplate('card-body-'+presentCardNumber,'answer-details',imagePrefix(finaljson["finalJSON"][i]["answer"]["value"]));
        }
    }
}

function newLogoImage(event){
    var logoclass = $(event.target);
    uploadLogo(logoclass,function(url){
        console.log(url);
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


$(document).ready(function(){
    //TODO: change this to check if this edit view.
    if(document.URL.split('?')[1]){
        //Showing loader while activity is being restored
        $.loader({
            className:"blue-with-image-2",
            content:''
        });
        //TODO: get activity id instead of actual json from url
        var json = document.URL.split('value=')[1];
        if(json){
            var finaljson = JSON.parse(decodeURIComponent(json));
            //TODO: get the json with ajax request with the above id and call the below function with the result json.
            afterSavingTemplate(finaljson);
            //Closing loader once everything is restored.
            $.loader('close');
        }
    }
    $('#continue_from_create').click(function(){
        continueFromTemplate();
    });
    $('.back-to-template').click(function(){
        backFromActivity();
    });
    $('#add-to-list').click(function(){
        var numberOfCards = $('#card-tabs li').length;
        if(numberOfCards <= 14){
            addToList();
        }
    });
    $('#PreviewModal').mousedown(function(event){
        $(this).contextmenu(function() {
            return false;
        });
        var keycode = event.which;
        var data = createJSON();
        if (keycode == 1) {
            if(checkEntering()){
                $('#PreviewModal').attr("data-toggle","modal");
                $('#preview-body').playForFlashCards(data,'download/');
            }
            else{
                $('#PreviewModal').removeAttr("data-toggle");
                if(!instructions){
                    previewError('You have not entered instructions');
                }
                else{
                    previewError('You have not entered card data or not added card');
                }
            }
        }
        else if (keycode == 3) {
            if(checkEntering()){
                var url = document.location.origin + '/ignitor-web/play_flash_cards.html?value=' + JSON.stringify(data) + '';
                window.open(url);
            }
            else{
                if(!instructions){
                    previewError('You have not entered instructions');
                }
                else{
                    previewError('You have not entered card data or not added card');
                }

            }
        }


    });
    $('#DescriptionModal').click(function() {
        var buttonOffset = $(this).offset();
        $('#ModalForDescription .modal-dialog').css('width', '50%').css('margin-left', buttonOffset['left']).css('margin-top', buttonOffset['top'] + 1.5 * $(this).height() - $(window).scrollTop() + 10);
        $('#ModalForDescription .modal-content').css('height', '225px');
        $('#textarea-description').val(instructions);
        $('#textarea-description').attr('maxlength', instructionsInputLimit);
        $('#ModalForDescription').modal('show');
    });
    $('#AddDescription').click(function(){
        instructions = $('#textarea-description').val();
    });

    $('#save-template').click(function(){
        savingTemplate();
    });

    $(".logo-btn").click(function(){
        $(".logo-upload").trigger("click");
        console.log($(".logo-upload").val());
    });
    $('.logo-upload').click(function(event){
        this.value = '';
    });
    $('.logo-upload').change(function(event){
        newLogoImage(event);
    });

});
