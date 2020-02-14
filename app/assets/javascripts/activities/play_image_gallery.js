$.fn.playImage_gallery = function(json, prefix){
    var data = '';
    var imagenumber = '';
    for(var i=0;i<json['finalJSON'].length;i++){
        data += "<div class='" + json['finalJSON'][i]['itemClass'] + " images-div'><img class='align-center' src='" + addPrefix(json['finalJSON'][i]['imageSource']) + "' ><div class='align-bottom' style='font-size:20px;'>"+(i+1)+'/'+json['finalJSON'].length+"</div></div>";
    }

    $('.images-div').css('width','700');
    var activityName = 'Template Name  ';
    if(json['name']){
        activityName = json['name'];
    }
    var logo;
    if(json['logo'] == "ignitor_logo.png"){
        logo = "/assets/activities/"+ json['logo'];
    }else{
        logo = addPrefix(json['logo']);
    }

    var that = $(this);
    $(this).empty();
    $(this).append('<div class="content-of-preview">\
			<div class="preview-header preview-header-inner">'
    + activityName +
    '</div>\
    <div id="preview-home" class="aligning-prev" style="padding-botom:0px">\
        <div class="row">\
            <p class="preview-text" style="word-wrap:break-word">'+json['instructions']+'</p>\
			</div>\
			<div class="row start-preview" >\
			<img  id="preview-play" src="assets/activities/play-sign.png">\
			</div>\
		<div class="row">\
			<span class="preview-play preview-play-label">Start</span>\
		</div>\
		</div>\
		<div id="imagepreview" class="aligning-prev" style="margin-top:0px;padding-bottom:0px">\
			<div class="previewbody">\
				<div id="previewCarousel" class="carousel slide" style="margin-top:-50px">\
					<!-- Wrapper for slides-->\
					\
					<div class="carousel-inner" role="listbox">'
    + data +
    '</div>\
    <!-- Left and right controls -->\
    <a class="left carousel-control" href="#previewCarousel" role="button"\
                                               data-slide="prev"> <img src="/assets/activities/left-arrow.png" class="align-vertical"><img> <span class="sr-only">Previous</span>\
                                       </a> <a class="right carousel-control" href="#previewCarousel"\
                                               role="button" data-slide="next"> <img src="/assets/activities/right-arrow.png" class="align-vertical"><img> <span\
                                                class="sr-only">Next</span>\
                                        </a>\
</div>\
<img class="ignitor-logo" src="'+logo+'">\
		</div>\
			\
		</div></div>');
    showModal();
    window.setTimeout(changeHeightOfPreview, 300);
    // $(window).resize(function(){
    //     changeHeightOfPreview();
    // });
    function changeHeightOfPreview(){
        var parentId = $('.content-of-preview').parent().attr('id');
        var windowHeight = window.innerHeight;

        if(parentId != 'preview-body'){
            $('.content-of-preview').css('height',windowHeight);
        }
        else{
            $('.content-of-preview').css('height','570px');
        }
    }

    function showModal(){
        $('#preview-home').show();
        $('#imagepreview').hide();
        $('.content-of-preview').css('background-image','url("/assets/activities/prev_for_imagegallery.png")');
    }

    $('.carousel-inner >img').css('max-width','750').css('max-height','400');
    $('.start-preview').click(function(){
        $('#preview-home').hide();
        $('#imagepreview').show();
        $('.content-of-preview').css('background-image','url("/assets/activities/preview_background.png")');
        $('#previewCarousel').carousel({
            pause: true,
            interval: false
        });
    });

    $('html, body').on('touchmove', function(e){
        //prevent native touch activity like scrolling
        e.preventDefault();
    });


    function addPrefix(imageName){
        var url = prefix+imageName;
        return url;
    };
};