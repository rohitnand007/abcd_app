#= require d3.min
#= require c3.min
# reusable functions
@createDonut = (donutId, color1, color2, correct, total, correctLabel, wrongLabel) ->
  donut = c3.generate(
    size:
      width: 300
    data:
      columns: [
        [
          correctLabel
          correct
        ]
        [
          wrongLabel
          total - correct
        ]
      ]
      type: "donut"

    bindto: "#" + donutId
    axis:
      x:
        label: "Sepal.Width"

      y:
        label: "Petal.Width"

    donut:
      label:
        format: (d, ratio) ->
          ""

      title: "License Status"

    color:
      pattern: [
        color1
        color2
      ]
  )
  return

@buttonizeToggleButtons = ->
  $detailToggleButton = $(".detailToggleButton")
  $detailToggleButton.button()
  $detailToggleButton.removeClass("ui-corner-all").addClass("ui-corner-top")
  $detailToggleButton.css 'margin-bottom', "-1px"
  return


@buttonizeNormalButtons= ->
  $('.normalButton').button()
  return

#Page specific beautification Functions
@prettifyAggregates = ->
  $mainStatistics = $(".mainStatistics")
  $contentTables = $mainStatistics.find("table")
  $contentTables.find("tr:last-child").addClass "darkgrayize headerize"
  $contentTables.find("tr:first-child").addClass "greenize biggest"
  $contentTables.css "text-align", "center"
  $mainStatistics.addClass "occupyWidth"
  return
@prettifyLicencingInfo = ->
  $licensesConsumed = $("#licensesConsumed")
  $licensesConsumed.css "text-align", "center"
  $licensesConsumed.css "font-size", "15px"
  $licensesConsumed.addClass "darkgrayize "
  return
@removeWebAppButtons = ->
  $('.normalButton,.button').removeClass('button')
  return
@prettifyTaskMenu = ->
  $taskMenu = $("#taskMenu")
  $taskMenu.addClass "occupyWidth darkgrayize headerize"
  $taskMenu.css "text-align", "center"
  $taskMenu.find("svg").css "vertical-align", "middle"
  $taskMenu.find("a").css "text-decoration", "none"
  $taskMenu.find("span").css("cursor", "pointer").hover (->
    $(this).css "color", "#4d917a"
    $(this).find("svg>g").attr "stroke", "#4d917a"
    return
  ), ->
    $(this).css "color", "#636363"
    $(this).find("svg>g").attr "stroke", "#636363"
    return

  return
@showLoadingIconOnSubmit = ($formObject)->
  $formObject.submit ->
    $(this).find(".loading").css("visibility", "visible")
