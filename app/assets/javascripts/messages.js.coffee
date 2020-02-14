# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

#$(document).ready ->
#  $('#message_receiver_name').autocomplete({source: "/ajax/users"})
 $(document).ready ->
         $('#message_receiver_name').autocomplete
                 source: "/profile_users"
                 select: (event,ui) -> $("#message_recipient_id").val(ui.item.id) 
