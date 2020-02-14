#= require publisher
prettifyBooksHeader= ->
  $booksHeader = $("#booksHeader")
  $booksHeader.addClass "darkgrayize headerize occupyWidth"
  $booksHeader.find("td:last-child").css(
    "text-align":"right"
  )

# Some Locally Used Functions for prettifying
prettifyFullDetailArea= ->
  buttonizeToggleButtons()
  $fullDetailArea = $(".fullDetailArea")
  $fullDetailArea.find(".firstDetailTable").addClass "occupyWidth"
  $fullDetailArea.find("abridgedBookInfo").parent().addClass("abridgedBookInfoParent")
  $(".extendedDetail").hide()

prettifyBooksList = ->
  $("#booksList").dragScroll()

generateDialogBox = ->
  $("#new_ibook").dialog
    autoOpen: false
    title: "Upload a new book"
    width: "auto"
    resizable: false
    draggable: false
    modal: true


@beautify_toc = ->
  $('.topics,.subtopics,.subsubtopics,.subsubsubtopics').hide()
  $('.contents li').click ->
    $(this).children().toggle()
    false
  $('ul>li').each ->
    if $(this).children().length == 0
      $(this).css 'cursor', 'default'
      $(this).css 'list-style-image', 'url("/assets/DotIcon.png")'
    else
    return
  return


@activateIndexPage = ->
  generateDialogBox()
  # Event Handlers

  $("#createNewBooks").click ->
    $("#new_ibook").dialog("open")
  # Set Toggle Handler
  $(".detailToggleButton").button().toggle(
    ()->
      $(this).button('option', 'label', ' ▲ Hide')
      $(this).parent().siblings(".extendedDetail").slideToggle();
      $('#loading_overlay').show();
      book_id = $(this).closest(".fullDetailArea").data('id')
      $.get "/ibooks/" + book_id + "/get_book_extended_details"
  ,
    ()->
      $(this).button('option', 'label', ' ▼ Details')
      $(this).parent().siblings(".extendedDetail").slideToggle();
  )
  $(".hideDetail").click(
    ()->
      $(this).closest(".fullDetailArea").find('.extendedDetail').slideUp();
      $(this).closest(".fullDetailArea").find('.detailToggleButton').button('option', 'label', ' ▼ Details')
  )

  #vcreate a dialog form
  dialog = $("#dialogForm").dialog
    autoOpen: false
    resizable: false
    modal: true
    close: ->
      form[0].reset()

  # After submitting the form for assigning collections in the dialog
  $("#dialogForm form").submit ->
    $(this).find(".loading").css("visibility", "visible")

  # Upon clicking on assign to collections button
  $("#assignToCollection").click(->
    if ($("input[name=ibooks]:checked").length == 0)
      alert "Please select at least one book"
      return false
    else
      values = []
      $("input[name='ibooks']").each ->
        $this = $(this)
        if ($this.prop("checked") == true)
          values.push($this.val())
      $("input[name='ibook_ids']").val(values)
      dialog.dialog 'open'
      $("span.ui-dialog-title").text(values.length + ' book(s) selected')
      return
  )

  # Prettifies books header
  prettifyBooksHeader()
  prettifyFullDetailArea()
  prettifyBooksList()

  #remove button class automatically provided by simple form for
  removeWebAppButtons()

  # Buttonize
  $("#createNewBooks, #myBooks").button()
  $("#assignToCollection").button()
  $(".detailToggleButton").button()
  buttonizeNormalButtons()
  $(".detailToggleButton").removeClass("ui-corner-all")
  $("#create_new").attr("checked", false)
  $("#newIpack").val("")

  # Attach consistency to checkboxes while creating a new collection
  $("#newIpack").blur ->
    if ($(this).val() == "")
      $("#create_new").attr("checked", false)
  $("#newIpack").focus ->
    $("#create_new").attr("checked", true)
  $("#create_new").change ->
    if ($(this).attr("checked") == "checked")
      $("#newIpack").focus()


@activateNewBooksPage = ->
  #remove button class automatically provided by simple form for
  removeWebAppButtons()
  buttonizeNormalButtons()
  generateDialogBox()
  $("#uploadNewBookStarter").click ->
    $("#new_ibook").dialog("open")
  $("#uploadNewBookStarter").click()





