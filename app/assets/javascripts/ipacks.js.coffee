#= require publisher
prettifyPacksHeader= ->
  $ipacksHeader = $("#ipacksHeader")
  $ipacksHeader.addClass "darkgrayize headerize occupyWidth"
  $ipacksHeader.find("td:last-child").css(
    "text-align":"right"
  )
prettifyPacksTable= ->
  $ipacksList = $("#ipacksList")
  $ipacksList.addClass "occupyWidth"
  $(".extendedDetail").hide()
  $(".assignedBooks").addClass "occupyWidth"
  $ipacksList.css "text-align", "left"
  $(".ipackHeader").parent().css "padding-top", "10px"
  return
prettifyPacksList = ->
  $ipackList = $("#ipackList")
  $ipackList.dragScroll()
@readyIndexPage = ->
  # prettify
  prettifyPacksHeader()
  prettifyPacksTable()
  prettifyPacksList()
  #remove button class automatically provided by simple form for
  removeWebAppButtons()

  # Functions to handle events
  # Set Toggle Handler
  $(".detailToggleButton").button().toggle(
    ()->
      $(this).button('option', 'label', ' ▲ Hide')
      $(this).closest(".togglerRow").prev().find(".extendedDetail").slideToggle();
  ,
    ()->
      $(this).button('option', 'label', ' ▼ Details')
      $(this).closest(".togglerRow").prev().find(".extendedDetail").slideToggle();
  )


  # Buttonize
  $("#createNewIpack").button()
  $("#assignToSchool").button().click ->
    $(this).closest("td").find(".loading").css("visibility", "visible")
  $(".detailToggleButton").button()
  buttonizeNormalButtons()
  buttonizeToggleButtons()
  $(".ipackHeader a").tipTip();
