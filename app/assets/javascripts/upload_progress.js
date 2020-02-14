var upload_file = function()
{
    $(".form_group").on('submit',function(e)
    {
        e.preventDefault();
       $(this).ajaxSubmit(

           {
              dataType: 'json',
              beforeSend:function()
               {
                $("#prog").show();
                $("#prog").attr('value','0');
               },
               uploadProgress:function(event,position,total,percentCompelete)
               {
                  $("#prog").attr('value',percentCompelete);
                  $("#percent").html(percentCompelete+'%');
                  $('body').append('<div id="over" style="position: absolute;top:0;left:0;width: 100%;height:100%;z-index:999;opacity:0.4;filter: alpha(opacity = 50)"></div>');

                   window.onbeforeunload = confirmExit;
                    function confirmExit() {
                      return "You have attempted to leave this page. Are you sure?";
                    }
               },
               success:function(data)
               {
                   if (data["launch_file"] == false){
                   //will get new url in data
                   //$('#prog').hide('slow');
                   $('#_file').val(null);
                   $('#user_asset_asset_name').val(' ');
                   $('#tag_class_id').val('');
                   $('#tag_subject_id').val('');
                   $('#tag_concept_id').val('');
                   $("#_submit").attr("disabled", false);
                   $('#percent').append(' <p>Uploaded!!!</p>');
                   $("#over").remove();
                   window.onbeforeunload="";
                   window.history.pushState({},"new url",data["url"] + "/?notice=" + data["message"]);
                   window.location.reload();
                   }
                   else{
                       //window.location.href = "/user_assets/launch_file_setter/" + data["asset_id"]

                       var ajax_url = "/user_assets/launch_file_setter/" +  data["asset_id"]
                       $.ajax({
                           url: ajax_url,
                           type: "post",
                           dataType: "html"
                       }).done(function(data) {
                           var $response=$(data);
                           //query the jq object for the values
                           var dataNeeded = $response.find('#launcher').html()
                           $("#launch_file_set").html(dataNeeded)

                       });
                       $("#launch_file_set").dialog({title: "set launch file for this asset",
                           dialogClass: 'setLaunchFile',
                           width: "auto",
                           height: "auto",
                           resizable: false,
                           draggable: false,
                           modal: true});
                       $("#update_launch_file").click(function(){
                           var $this = $(this);
                           $this.dialog('close');
                           //$('#_file').val(null);
                           //$('#user_asset_asset_name').val(' ');
                           //$('#tag_class_id').val('');
                           //$('#tag_subject_id').val('');
                           //$('#tag_concept_id').val('');
                           //$("#_submit").attr("disabled", false);
                           //$('#percent').append(' <p>Uploaded!!!</p>');
                           //$("#over").remove();
                           //window.onbeforeunload="";
                           //window.history.pushState({},"new url",data["url"] + "/?notice=" + data["message"]);
                           //window.location.reload();
                       })
                   }
               }
           });
   });
};
$(document).ready(upload_file);