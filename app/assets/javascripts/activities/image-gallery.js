var galleryImages = [];
var instruction;
var prefix = 'download/';
var imagecount = 0;
var images_num = 10;
var minWidthImg = 800;
var minHeightImg = 500;
$("#content-create-template").show();
$("#content-create-gallery").hide();

$(".image-gallery-back").click(function(event) {
    $("#tab-create-template").addClass("image-gallery-tab-active");
    $("#tab-create-gallery").removeClass("image-gallery-tab-active");
    $("#content-create-template").show();
    $("#content-create-gallery").hide();
});

$("#save-and-continue-template").click(function(event) {
    $("#tab-create-template").removeClass("image-gallery-tab-active");
    $("#tab-create-gallery").addClass("image-gallery-tab-active");
    $("#content-create-template").hide();
    $("#content-create-gallery").show();
});

//creating a preview
$("#preview-gallery").mousedown(function(event) {
    var finalJSON = createJSON();
    var keycode = event.which;

    if(finalJSON['finalJSON'][0] != undefined  && finalJSON['instructions']!=''){
        if(keycode == 1){
            $(".preview-btn").css({"color":"white"});
            $(".previewBody").playImage_gallery(finalJSON, prefix );
        }else if (keycode == 3) {
            var url = document.location.origin + '/ignitor-web/play_image_gallery.html?value=' + JSON.stringify(finalJSON) + '';
            window.open(url);
        }
    }else{
        err('Add both Instructions and Images to watch preview');
    }
});

// creating JSON
function createJSON(){
    var images = $('.image-gallery-item');
    var counter = 0;
    var finalJSON = {};
    var jsonArray = [];
    var imagesource=[];
    images.each(function () {
        var response = {};

        var imageSource = $(this).attr('src');
        imageSource = imageSource.substring(imageSource.indexOf("image_"));
        var itemClass = "item";
        if (!counter) {
            itemClass = itemClass + " active";
        }
        response["imageSource"] = imageSource;
        response["itemClass"] = itemClass;
        imagesource.push(imageSource);
        jsonArray[counter] = response;
        counter++;
    });
    imagesource.push('ignitor_logo.png');
    finalJSON["finalJSON"] = jsonArray;
    finalJSON["images"] = imagesource;
    $(this).contextmenu(function() {
        return false;
    });
    finalJSON['instructions']= $('#textarea-description').val();
    finalJSON['name']= $('#contentName').val();
    finalJSON['description'] = $('#description').val();
    finalJSON['class'] =	$('#className').val();
    finalJSON['subject'] = $('#subject').val()
    finalJSON['topics'] = $('#chapter').val();
    finalJSON['learning_activity_type'] = $('#learning_activity_type').val();
    finalJSON['logo'] = 'ignitor_logo.png';
    return finalJSON;
    if(logo != ""){
        finalJSON["logo"] = logo;
    }else{
        finalJSON["logo"] = "ignitor_logo.png";
    }
    return finalJSON;

};

// no json function
function emptyJSON(){
    $.alert({
        title: 'Notification',
        content: 'Add both Instructions and Images to watch preview',
        confirmButtonClass: 'error-confirm',
        confirm: function() {}
    });
};

function err(text){
    $.alert({
        title: 'Notification',
        content: text,
        confirmButtonClass: 'error-confirm',
        confirm: function() {}
    });
};

function uploadfailure(){
    $.alert({
        title: 'Notification',
        content: 'Unable to upload image to server',
        confirmButtonClass: 'error-confirm',
        confirm: function() {}
    });
};

// image upload success
var onImageGallerySuccess = function(uploaded_url) {
    var galleryImage = {};
    galleryImage.name = uploaded_url;
    galleryImages.push(galleryImage);
    renderImageGallery(galleryImage);
};

//upload file to server
function uploadFileInput(event) {
    $.loader({
        className:"blue-with-image-2",
        content:''
    });
    var files = $("#uploadFileInput").get(0).files;
    uploadFile(files, "uploadfile", function(data, textStatus, jqXHR,
                                             uploaded_url) {
        $("#uploadFileInput").val("");
        var img = $('<img src="' +uploaded_url + '"/>').load(function() {
                       var w = this.width;
                        var h = this.height;
                        if (w < minWidthImg || h < minHeightImg) {
                               $.loader('close');
                               err('Minimum resolution is 800x500 px');
                            } else {
                               uploaded_url = uploaded_url.substring(uploaded_url.indexOf("image_"));
                               if(imagecount < images_num){
                                                   onImageGallerySuccess(uploaded_url);
                                                   imagecount++;
                                           }else{
                                                   err('Limit exceeded on the allowed number of images');
                                           }
                               $.loader('close');
                            }
                    });


    }, function(jqXHR, textStatus, errorThrown) {
        err('Unable to upload image to server');
        $.loader('close');
    });
};

//create image gallery
function renderImageGallery(galleryImage) {
    var name = galleryImage.name.split(".")[0]
    $("#no-image-in-gallery").hide();
    $("#image-gallery").show();

    console.log(galleryImage.name.split('.')[0]);
    $(".image-gallery-grid").append("<div id='" + galleryImage.name.split('.')[0] + "'></div>");
    $("#" + galleryImage.name.split('.')[0]).append("<div class='image-gallery-wrapper'></div>");
    $("#" + galleryImage.name.split('.')[0] + " .image-gallery-wrapper").append("<div class=\"image-gallery-item-wrapper\"><img class=\"image-gallery-item align-center\" src='" + imagePrefix(galleryImage.name) + "' /></div>");
    $("#" + galleryImage.name.split('.')[0] + " div.image-gallery-wrapper").append("<div><img class='delete-gallery-image' src='/assets/activities/delete_icon.png' /></div>");

    shapeshift();
};

// deleting images from gallery
$('#image-gallery-grid').on('click', '.delete-gallery-image', function() {
    var image_id_to_delete = $(this).parent().parent().parent().attr("id");
    var image_index_to_delete;
    //for (var index in galleryImages) {
    //    if (galleryImages[index].name == image_id_to_delete) {
    //        image_index_to_delete = index;
    //        break;
    //    }
    //}
    //imagecount--;
    //galleryImages.splice(image_index_to_delete, 1);
    //
    //$(this).parent().parent().parent().remove();
    //
    //shapeshift();
    //
    //if (galleryImages.length == 0) {
    //    $("#image-gallery").hide();
    //    $("#no-image-in-gallery").show();
    //}
    var image_div = $(this).parent().parent().parent();
    $.confirm({
        title: 'Confirm!',
        content: 'Are you sure?',
        confirmButtonClass: 'error-confirm',
        confirm: function(){
            for (var index in galleryImages) {
                if (galleryImages[index].name == image_id_to_delete) {
                    image_index_to_delete = index;
                    break;
                }
            }
            imagecount--;
            galleryImages.splice(image_index_to_delete, 1);
            image_div.remove();
            shapeshift();
            if (galleryImages.length == 0) {
                $("#image-gallery").hide();
                $("#no-image-in-gallery").show();
            }
        },
        cancel: function(){
        }
    });

});

function shapeshift() {
    $("#image-gallery-grid").shapeshift({
        align: "left",
        gutterY: 30
    });
}

$('#image-gallery-grid').on('click', '.image-gallery-item', function() {
    var imageSource = $(this).attr("src");
    $('#image-viewer-content').attr('src', imageSource);
    $('#imageViewer').modal('show');
});


//drag and drop images  
var dropZone = document.getElementById('dropUpload');
dropZone.addEventListener('dragover', handleDrag, false);
dropZone.addEventListener('drop', handleDrop, false);

function handleDrag(e) {
    e.stopPropagation();
    e.preventDefault();
};

function handleDrop(e) {
    e.stopPropagation();
    e.preventDefault();
    var files = e.dataTransfer.files;
    $.loader({
        className:"blue-with-image-2",
        content:''
    });
    uploadFile(files, "uploadfile", function(data, textStatus, jqXHR, uploaded_url) {
        var img = $('<img src="' +uploaded_url + '"/>').load(function() {
                        var w = this.width;
                        var h = this.height;
                        if (w < minWidthImg || h < minHeightImg) {
                               $.loader('close');
                               err('Minimum resolution is 800x500 px');
                            } else {
                               uploaded_url = uploaded_url.substring(uploaded_url.indexOf("image_"));
                               if(imagecount < images_num){
                                                   onImageGallerySuccess(uploaded_url);
                                                   imagecount++;
                                           }else{
                                                   err('Limit exceeded on the allowed number of images');
                                           }
                               $.loader('close');
                            }
                    });

    }, function(jqXHR, textStatus, errorThrown) {
        $.loader('close');
        err('Unable to upload image to server');
    });
};

// opening description modal
$('#DescriptionModal').click(function() {
    var buttonOffset = $(this).offset();
    $('#instruction_modal .modal-dialog').css('margin-left', buttonOffset['left']).css('margin-top', buttonOffset['top'] + 1.5 * $(this).height() - $(window).scrollTop() + 10);
    $('#instruction_modal .modal-content').css('height', '225px').css('width', '650px');
    $('#instruction_modal').modal('show');
    $('#textarea-description').val(instruction);
    $('#textarea-description').attr('maxlength','350');

});

//saving instructions
$('#AddDescription').click(function(){
    instruction = $('#textarea-description').val();
});

// save and edit 

$('.save').click(function(){
    var json = createJSON();
    if(json['finalJSON'] != [] && json['instructions']!=''){
        //TO DO: send ajax request with json created below
        //var url = document.location.origin + '/ignitor-web/image_gallery.html' + '?' + JSON.stringify(json);
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
                err("Error in saving the activity");
            }
        });
    }else{
        err('Add both Instructions and Images to watch preview');
    }
});

$(document).ready(function(){

    //TODO: change this to check if this edit view.
    if(document.URL.split('?')[1]){
        //Showing loader while activity is being restored
        $.loader({
            className:"blue-with-image-2",
            content:''
        });
        //TODO: get activity id instead of actual json from url
        var json=document.URL.split('?')[1];
        if(json){
            var finaljson = JSON.parse(decodeURIComponent(json));
            //TODO: get the json with ajax request with the above id and call the below function with the result json.
            restoreImageGallery(finaljson);
            //Closing loader once everything is restored.
            $.loader('close');
        }
    }
});

function restoreImageGallery(finaljson){
    $('#contentName').val(finaljson['name']);
    $('#description').val(finaljson['description']);
    $('#className').val(finaljson['class']);
    $('#subject').val(finaljson['subject']);
    $('#chapter').val(finaljson['topics']);

    instruction = finaljson['instructions'];
    $('#textarea-description').val(instruction);

    logo = finaljson["logo"];
    if(logo == 'ignitor_logo.png'){
        $(".logo-btn").find("img").attr("src","images/"+logo );
    }else{
        $(".logo-btn").find("img").attr("src",imagePrefix(logo));
    }
    $("#content-create-template").hide();
    $("#content-create-gallery").show();
    for(var k=0; k<finaljson['finalJSON'].length; k++){
        var uploaded_url = finaljson['finalJSON'][k]['imageSource'];
        onImageGallerySuccess(uploaded_url);
    }
    $("#content-create-template").show();
    $("#content-create-gallery").hide();

}

$(".logo-btn").click(function(){
    $(".logo-upload").trigger("click");
});
$('.logo-upload').click(function(event){
    this.value = '';
});
$('.logo-upload').change(function(event){
    newLogoImage(event);
});

function newLogoImage(event){
    var logoclass = $(event.target);
    uploadLogo(logoclass,function(url){
        $(".logo-btn").find("img").attr("src",url);
        logo = url.split(prefix)[1];
    },function(url){
        err('Unable to upload image to server');
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
        err('Unable to upload image to server');
        $.loader('close');
    });
}
