var files

//In case of file upload, this function saves the file to be uploaded once the it is selected.
//Call this function on change of input field for file upload
function prepareUpload(event){
	files = event.target.files;
   
}

//upload_url is the url of upload service for AJAX POST request
//uploadFileSuccess executes on failure of POST request and takes 4 arguments, data, textStatus,
//jqXHR and url of uploaded image
//uploadFileFailure executes on failure of POST request and takes 3 arguments, data, textStatus and errorThrown
function uploadFile(files, upload_url, uploadFileSuccess, uploadFileFailure){
	upload_url = 'uploadfile';
	var data;
	$.each(files, function(key, value)
	{
	data = new FormData();
	data.append("file", value);
    $.ajax({
        url: upload_url,
        type: 'POST',
        data: data,
        cache: false,
        processData: false, // Don't process the files
        contentType: false, // Set content type to false as jQuery will tell the server it's a query string request
        success: function(data, textStatus, jqXHR)
        {
        	var uploaded_url= "download/" + data.substring(data.indexOf("image_"));
//          uploaded_url = " ";
            console.log(uploaded_url);
        	uploadFileSuccess(data, textStatus, jqXHR, uploaded_url);
//        	$("#file-upload-success").css("display", "block");
//        	$("#file-upload-success").text(data);
        },
        error: function(jqXHR, textStatus, errorThrown)
        {
        	uploadFileFailure(data, textStatus, errorThrown);
//        	$("#file-upload-error").css("display", "block");
//        	$("#file-upload-error").text(data);
        }
    });
	
	});
}


//file_url is the url of the image
//upload_url is the url of upload service for AJAX POST request
//uploadUrlSuccess executes on failure of POST request and takes 3 arguments, data, textStatus,
//jqXHR and url of uploaded image
//uploadUrlFailure executes on failure of POST request and takes 3 arguments, data, textStatus and errorThrown
function uploadUrl(event, file_url, upload_url, uploadUrlSuccess, uploadUrlFailure){
	event.stopPropagation(); // Stop stuff happening
    event.preventDefault(); // Totally stop stuff happening

	var data = {
			url : file_url
	} ;
	
    $.ajax({
        url: upload_url,
        type: 'POST',
        data: data,
        success: function(data, textStatus, jqXHR)
        {
        	var uploaded_url= "download/" + data.substring(data.indexOf("image_"));
        	uploadUrlSuccess(data, textStatus, jqXHR, uploaded_url);        	
        },
        error: function(jqXHR, textStatus, errorThrown)
        {
        	uploadUrlFailure(data, textStatus, errorThrown);
        }
    });
}

//downloadImage when file path is given
function downloadImage(event, file_path){
	event.stopPropagation(); // Stop stuff happening
    event.preventDefault(); // Totally stop stuff happening

	download(file_path);
}

//function downloadFile(filePath) {
//	var name = filePath.substring(filePath.indexOf("image_"))
//	
//	$("#download-success").empty();
//	$("#download-success").html("<img src='download/" + name + "' />");
//	$("#download-success").css("display", "block");
//}

function download(filePath){
    console.log(filePath);
	var fileName = filePath.substring(filePath.indexOf("image_"));
    console.log(fileName);
	var currLocation = window.location.href + 'download/' + fileName;
	window.open(currLocation,'_blank');
}

function imagePrefix(imageName){
	var url = "download/"+imageName;
	return url;
}
$(function(){

	// Add events
	$('input[type=file]').on('change', prepareUpload);
	$('#file_upload').on('click', uploadFile);
	$('#url_upload').on('submit', uploadUrl);
	$('#image_download').on('submit', downloadImage);
});
