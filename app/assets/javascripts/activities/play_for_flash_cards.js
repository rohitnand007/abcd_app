$.fn.playForFlashCards = function(json,prefix) {
    var flipCount = 0;
    var previewCardNumber = 0;
    var maxHeight = 350;
    var maxWidth = 270;
    var cards = json;
    var isLastCard = false;
    var isFirstCard = false;
    var fadeOutTime = 3000;
    var that = $(this);
    var logoPrefix;
    if(cards["logo"] == 'ignitor_logo.png'){
        logoPrefix = '/assets';
    }
    else{
        logoPrefix = prefix;
    }
    $(this).empty();
    $(this).append('<div class="content-of-preview"><div class="col-xs-12 no-padding">\
			<span class="col-xs-12 active activeprev">'+cards["name"]+'</span>\
			</div>\
			<div id="container_for_preview">\
			<div class="text-center" id="preview-home">\
			<p>'+ cards["instructions"]+'</p>\
			<div class="row start-preview" >\
            <img  id="preview-play" src="/assets/activities/play-sign.png">\
			</div>\
			<div class="row">\
				<span class="preview-play preview-play-label">Start</span>\
			</div>\
			</div>\
			<div class = "col-xs-12" id="flash-cards-preview">\
			<span id="card-number" style="font-size:22px;">1/10</span>\
			<div class ="col-xs-4 timer text-center">\
			<div class="item">\
			<h2></h2>\
			<svg width="160" height="160" xmlns="http://www.w3.org/2000/svg">\
			<g>\
			<title>Layer 1</title>\
			<circle id="circle" class="circle_animation" r="69.85699" cy="81" cx="81" stroke-width="3" stroke="#509F80" fill="none"/>\
			</g>\
			</svg>\
			</div>\
			<div class = "col-xs-12 flip-tip text-center" style="display:none" id="clue-side-tip">\
			<span class="col-xs-1"><img alt="bulb" src="/assets/activities/bulb.png"></span>\
			<p class="col-xs-11">To see the answer, please click anywhere on the card</p>\
			</div>\
			<div class = "col-xs-12 flip-tip text-center" style="display:none" id="answer-side-tip">\
			<span class="col-xs-1"><img alt="bulb" src="/assets/activities/bulb.png"></span>\
			<p class="col-xs-11">To go back to question, please click on the card again</p>\
			</div>\
			<div class="text-left col-xs-12 no-padding">\
			<button class="btn" id="next-card" style="display:none">Next Card</button>\
			</div>\
			<div class="text-left col-xs-12 no-padding">\
			<button class="btn" id="previous-card" style="display:none">Previous Card</button>\
			</div>\
			</div>\
			<div id="card-flip" class="col-xs-8 text-center">\
			<div class ="card-preview  front" >\
			<div id = "clue-side" class="preview-clue-answer">\
			<p></p>\
			<img src="/assets/activities/picture.png">\
			</div>\
			</div>\
			<div class ="card-preview back" >\
			<div id = "answer-side" class="preview-clue-answer">\
			<p style="display:none"></p>\
			<img src="/assets/activities/picture.png">\
			</div>\
			</div>\
			</div> \
			</div>\
			</div>\
			<img src="'+logoPrefix+cards["logo"]+'" class="ignitor-logo"/>\
			</div>');
    previewModal();

    changeHeightOfPreview();
           $(window).resize(function(){
                       changeHeightOfPreview();
               });
           $('html, body').on('touchmove', function(e){
                    //prevent native touch activity like scrolling
                        e.preventDefault();
               });
           function changeHeightOfPreview(){
                       var parentId = $('.content-of-preview').parent().attr('id');
                       var windowHeight = window.innerHeight;
                       if(parentId != 'preview-body'){
                                   $('.content-of-preview').css('height',windowHeight);
                                   $('#container_for_preview').css('height',windowHeight-35);
                           }
                       else{
                                   $('.content-of-preview').css('height','620px');
                                   $('#container_for_preview').css('height','590px');
                           }
               }


    function changeTextAlignClue(){
        var clueSideTextHeight = $('#clue-side p').height();
        //var answerSideTextHeight = $('#answer-side p').height();
        if(clueSideTextHeight > 23){
            //$('#clue-side p').css('text-align','left');
            $('#clue-side p').removeClass("text-align-center");
            $('#clue-side p').addClass("text-align-left");
        }
        else{
            //$('#clue-side p').css('text-align','center');
            $('#clue-side p').removeClass("text-align-left");
            $('#clue-side p').addClass("text-align-center");
        }
        if(answerSideTextHeight > 23){
            $('#answer-side p').css('text-align','left');
        }
        else{
            $('#answer-side p').css('text-align','center');
        }
    }

    function changeTextAlignAnswer(){
        var answerSideTextHeight = $('#answer-side p').height();
        if(answerSideTextHeight > 23){
            $('#answer-side p').removeClass("text-align-center");
            $('#answer-side p').addClass("text-align-left");
        }
        else{
            $('#answer-side p').removeClass("text-align-left");
            $('#answer-side p').addClass("text-align-center");
        }
    }


    $('#preview-home > .start-preview').click(function(){
        startPreview(cards);
    });
    $('#next-card').click(function(){
        flipCount = -1;
        $('#card-flip').trigger('click');
        previewCardNumber++;
        previewCardsClue(cards,previewCardNumber);
        $('#card-flip').trigger('click');

        if(previewCardNumber+1 == cards["finalJSON"].length){
            isLastCard = true;
        }
        if(previewCardNumber != 0){
            isFirstCard = false;
        }
        $('.circle_animation').css('stroke-dashoffset','0');
    });
    $('#previous-card').click(function(){
        flipCount = -1;
        $('#card-flip').trigger('click');
        previewCardNumber--;
        previewCardsClue(cards,previewCardNumber);
        $('#card-flip').trigger('click');

        if(previewCardNumber == 0){
            isFirstCard = true;
        }
        if(previewCardNumber+1 != cards["finalJSON"].length){
            isLastCard = false;
        }
        $('.circle_animation').css('stroke-dashoffset','0');
    });
    $('#card-flip').flip();
    $("#card-flip").on('flip:done',function(){

        if(flipCount == -1){
            startTimer();
            previewCardsAnswer(cards,previewCardNumber);
        }
        else if (flipCount%2 == 0 && !isLastCard && !isFirstCard){
            $('#clue-side-tip').hide();
            $('#next-card').show();
            $('#previous-card').show();
            $('#answer-side-tip').fadeIn();
        }
        else if (flipCount%2 == 0 && !isLastCard && isFirstCard){
            $('#clue-side-tip').hide();
            $('#next-card').show();
            $('#previous-card').hide();
            $('#answer-side-tip').fadeIn();
        }
        else if (flipCount%2 == 0 && isLastCard && !isFirstCard){
            $('#clue-side-tip').hide();
            $('#next-card').hide();
            $('#previous-card').show();
            $('#answer-side-tip').fadeIn();

        }
        else if (flipCount%2 == 0 && isLastCard && isFirstCard){
            $('#clue-side-tip').hide();
            $('#next-card').hide();
            $('#previous-card').hide();
            $('#answer-side-tip').fadeIn();

        }
        else{
            $('#clue-side-tip').fadeIn();
            $('#next-card').hide();
            $('#previous-card').hide();
            $('#answer-side-tip').hide();
        }
        flipCount++;
    });
    function previewModal(){
        $('#preview-home').show();
        $('#flash-cards-preview').hide();
        $('.circle_animation').css('stroke-dashoffset','0');
        $('.content-of-preview').css('background','url(/assets/activities/prev_for_imagegallery.png)');
    }
    function startPreview(cards){
        $('#preview-home').hide();
        $('#flash-cards-preview').show();
        $('.content-of-preview').css('background','url(/assets/activities/preview_background.png)');

        if (flipCount%2 != 0){
            $('#card-flip').trigger('click');
        }
        startTimer();
        previewCardNumber = 0;
        isLastCard = false;
        isFirstCard = true;
        if(cards["finalJSON"].length == 1){
            isLastCard = true;
            isFirstCard = true;
        }
        previewCardsClue(cards,previewCardNumber);
        previewCardsAnswer(cards,previewCardNumber);

    }
    function startTimer(){
        $('.item').show();
        $('#clue-side-tip').hide();
        $('#next-card').hide();
        $('#previous-card').hide();
        $('#answer-side-tip').hide();
        $('#card-flip').css("pointer-events", "none");
        $('.modal-header-preview > span').css("pointer-events", "none");
        var time = 0;
        var maxTime = 2;
        var initialOffset = '440';

        $('.item > h2').text(maxTime);
        var i = maxTime;
        var interval = setInterval(function() {

            i--;

            if (i == time-1) {
                clearInterval(interval);
                $('.item').hide();
                $('#clue-side-tip').fadeIn();
                $('#card-flip').css("pointer-events", "auto");
                $('.modal-header-preview > span').css("pointer-events", "auto");
            }
            $('.circle_animation').css('stroke-dashoffset', initialOffset-(i*(initialOffset/maxTime)));
            $('.item > h2').text(i);


        }, 1000);
    }
    function previewCardsClue(cards,i){
        if(cards["finalJSON"][i]["clue"]["type"] == 'text'){
            $('#clue-side p').show();
            $('#clue-side img').hide();
            $('#clue-side p').html(cards["finalJSON"][i]["clue"]["value"]);
        }
        else if(cards["finalJSON"][i]["clue"]["type"] == 'image'){
            $('#clue-side p').hide();
            $('#clue-side img').show();
            var imageValue = imagePrefix(cards["finalJSON"][i]["clue"]["value"]);
            changeAspectRatio(imageValue,'clue-side');
            $('#clue-side img').attr('src',imageValue);
        }
        $('#card-number').text((previewCardNumber+1)+'/'+cards["finalJSON"].length);
        changeTextAlignClue();
    }

    function previewCardsAnswer(cards,i){
        if(cards["finalJSON"][i]["answer"]["type"] == 'text'){
            $('#answer-side p').show();
            $('#answer-side img').hide();
            $('#answer-side p').text(cards["finalJSON"][i]["answer"]["value"]);
        }
        else if(cards["finalJSON"][i]["answer"]["type"] == 'image'){
            $('#answer-side p').hide();
            $('#answer-side img').show();
            var imageValue = imagePrefix(cards["finalJSON"][i]["answer"]["value"]);
            changeAspectRatio(imageValue,'answer-side');
            $('#answer-side img').attr('src',imageValue);
        }
        changeTextAlignAnswer();
    }

        function changeAspectRatio(image,side){
        var img = $('<img src="' +image+ '"/>').load(function() {
            var w = this.width;
            var h = this.height;
            if(w >= h){
                if (w > maxWidth) {
                    $('#'+side+' img').css('width','100%');
                    $('#'+side+' img').css('height','auto');
                }
                else{
                    $('#'+side+' img').css('width','auto');
                    $('#'+side+' img').css('height','auto');
                }
            }
            else{
                if (h > maxHeight) {
                    $('#'+side+' img').css('width','auto');
                    $('#'+side+' img').css('height','100%');
                }
                else{
                    $('#'+side+' img').css('width','auto');
                    $('#'+side+' img').css('height','auto');
                }
            }
        });
    }
    function imagePrefix(imageName){
        var url = prefix+imageName;
        return url;
    }
}