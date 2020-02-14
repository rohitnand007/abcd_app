# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

#$(document).ready ->
#  $('#device_user_name').autocomplete({source: "/ajax/users"})
 $(document).ready ->
         $('#device_user_name').autocomplete
                 source: "/students"
                 select: (event,ui) -> $("#device_user_id").val(ui.item.id)