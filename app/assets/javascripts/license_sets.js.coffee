#= require publisher
@readyForm = ->
  showLoadingIconOnSubmit($("#new_license_set"))
  $('#new_license_set input:submit').removeClass('ui-corner-all').button()
  $('#selectSchool input:radio').click ->
    $('#selectSchool input:radio').not(this).prop 'checked', false
    return
  $('#new_license_set').submit (e) ->
    if ($('#selectSchool input:radio:checked').length == 0)
      alert 'Please select a center or an institute'
      $('#new_license_set').find(".loading").css "visibility", "hidden"
      return false
    if ($('#license_set_licences').val() == '')
      alert 'No. of licenses can\'t be empty'
      $('#new_license_set').find(".loading").css "visibility", "hidden"
      return false
    if (confirm("Are you sure you want to assign the collection to this school?") == false)
      $('#new_license_set').find(".loading").css "visibility", "hidden"
      return false
    return true

# these functions are used for prettifying index page
prettifyLicenseListHeader = ->
  $("#licenseListHeader").addClass "darkgrayize headerize occupyWidth"
  return

prettifyLicenseList = ->
  prettifyLicenseListHeader()
  $licenseList = $("#licenseList")
  $licenseList.addClass "occupyWidth"
  $licenseList.css "text-align", "left"
  $('.showStudents').css
    "width": '80%'
    "padding": "20px"
  return
disableRevokeButton = ($buttonObject) ->
  $buttonObject.attr('disabled', 'disabled').addClass("disable")
enableRevokeButton = (event) ->
  $buttonObject = event.data.$buttonObject
  $buttonObject.removeAttr('disabled').removeClass("disable")
  event.data.$callerObjects.off "change", enableRevokeButton
@readyPublisherLicenseSetsPage = ->
  $(":radio").removeAttr('checked')
  $revokeButton = $("#revokeButton")
  disableRevokeButton($revokeButton)
  $(":radio[name=id]").on "change", {$buttonObject: $revokeButton, $callerObjects: $(":radio[name=id]")}, enableRevokeButton
  $('#revokeForm').on "submit", (e)->
    e.preventDefault()
    messageHtmlString = "<p>If licenses are revoked, the assigned end users will not be able to access books.</p>"
    verifyPassword($(e.target), messageHtmlString)
  return

@prettifyLicensesIndex = ->
  $("#licenseListHeader").find(".prev a").html("<img src='/assets/white_arrow_left.png' alt='Prev'>")
  $("#licenseListHeader").find(".next a").html("<img src='/assets/white_arrow_right.png' alt='Next'>")
  prettifyLicenseList()
  $(".detailToggleButton").toggle(
    ->
      $(this).html('Hide')
      $(this).closest(".leadRow").nextAll(".detailsRow:first").find(".allDetails").slideDown()
  ,
    ->
      $(this).html('Manage Licenses')
      $detailsRow = $(this).closest(".leadRow").nextAll(".detailsRow:first")
      $detailsRow.find(".allDetails").slideUp()
      $detailsRow.find(".cleanList").click()
  )
  $(".selectall").live "click", -> $(this).closest(".studentTable").find(":checkbox").attr('checked',
    'checked')
  $(".deselectall").live "click", -> $(this).closest(".studentTable").find(":checkbox").attr('checked',
    false)
  $(".showAll").live "click", ->
    $(this).closest("form").find(" .studentName, .studentCheckbox").show()
    $(this).closest("form").find("input:radio[name=center]").attr('checked', false)

  $(":radio[value=assign_new]").attr("checked", "checked")
  $toggleBooksLicenses = $(".toggleBooksLicenses")
  $toggleBooksLicenses.change ->
    $this = $(this)
    $radio = $(this).find("input:radio:checked")
    if ($radio.val() == "assign_new")
      $this.nextAll(".assignNew:first").fadeIn()
      $this.nextAll(".showStudents:first").fadeOut()
      $this.closest(".detailsRow").css("background-color", "#eeffee")
    else
      $this.nextAll(".assignNew:first").fadeOut()
      $this.nextAll(".showStudents:first").fadeIn()
      if ($this.closest(".detailsRow").find("input[value=Update]").length == 1)
        $this.closest(".detailsRow").css("background-color", "#ffeeee")
    return
  return

@dynamicallyPopulateFilters = ->
  $('.center_id').live 'change', ->
    $parentFormWrapper = $(this).closest(".searchStudentsFormWrapper")
    institution_identifier = "#" + $parentFormWrapper.attr("id") + " .institution_id"
    center_identifier = "#" + $parentFormWrapper.attr("id") + " .center_id"
    academic_class_identifier = "#" + $parentFormWrapper.attr("id") + " .academic_class_id"
    section_identifier = "#" + $parentFormWrapper.attr("id") + " .section_id"
    set_default $(academic_class_identifier)
    set_default $(section_identifier)
    institution = $(institution_identifier + ' :selected').val()
    center = $(center_identifier + ' :selected').val()
    if institution == ''
      institution = 0
    if center == ''
      center = 0
      $(section_identifier).attr 'disabled', 'disabled'
    url = '/institution/get_academic_classes/' + institution + '/' + center
    div_update = academic_class_identifier
    get_url_Data_for_multiparams url, div_update
    $(academic_class_identifier).removeAttr 'disabled'
    $(groups).tokenInput 'clear'
    $('.token-input-dropdown').remove()
    $('.token-input-list').remove()
    $('#token-input-user_group_ids').remove()
    $(groups).tokenInput getSearchURL('user'),
      preventDuplicates: true
      theme: ''
      crossDomain: false
    $(groups).tokenInput 'clear'
    return
  $('#user_academic_class_id').live 'change', ->
    $parentFormWrapper = $(this).closest(".searchStudentsFormWrapper")
    institution_identifier = "#" + $parentFormWrapper.attr("id") + " .institution_id"
    center_identifier = "#" + $parentFormWrapper.attr("id") + " .center_id"
    academic_class_identifier = "#" + $parentFormWrapper.attr("id") + " .academic_class_id"
    section_identifier = "#" + $parentFormWrapper.attr("id") + " .section_id"
    set_default $(section_identifier)
    institution = $(institution_identifier + ' :selected').val()
    center = $(center_identifier + ' :selected').val()
    academic_class = $(academic_class_identifier + ' :selected').val()
    if institution == ''
      institution = 0
    if center == ''
      center = 0
    if academic_class == ''
      academic_class = 0
    url = '/institution/get_sections/' + institution + '/' + center + '/' + academic_class
    div_update = section_identifier
    get_url_Data_for_multiparams url, div_update
    $(section_identifier).removeAttr 'disabled'
    return
  return

@toggleStudentsOfCenters = ->
  $("input:radio[name=center]").live "change", ->
    $thisCenter = $(this)
    center = $thisCenter.val()
    $parentForm = $(this).closest "form"
    $parentForm.find(".studentCenter, .studentName, .studentCheckbox").hide()
    $relevantCenters = $parentForm.find(".studentCenter:contains('" + center + "')")
    $relevantCenters.prev().show().prev().show()
    $parentForm.find(".licenses").text($relevantCenters.size())
    return
  return