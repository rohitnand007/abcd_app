var BarChart_GrowAmount = 5;            // Amount to grow in bar animation.
var BarChart_ShrinkAmount = 0;         // Amount to shrink in bar animation.
var BarChart_ShrinkDecrement = 1;       // Amount to shrink by in bar animation.
var BarChart_BarChart_PlotBarsFunc = [];         // Array of  timer functions for registered charts.
var BarChart_CanvasId = [];             // Canvas IDs of registered charts.
var BarChart_HighlightedBar = null;     // The bar currently highlighted from a click.
var BarChart_HitList = [];

function BarChart(chart) {

    var now = new Date();

    BarChart_CanvasId.push(chart.CanvasId);

    canvas = document.getElementById(chart.CanvasId);
    chart.Canvas = canvas;

    canvas.addEventListener("click", BarChart_getPosition, false);
    canvas.addEventListener("mousemove", BarChart_getPosition1, false);
    ctx = canvas.getContext('2d');
    chart.ctx = ctx;

    if (chart.clickColor == undefined) chart.clickColor = "LimeGreen";

    // Default undefined chart properties.

    if (chart.margin == undefined) chart.margin = 16;
    if (chart.Background == undefined) chart.Background = "Black";
    if (chart.titleColor == undefined) chart.titleColor = "White";
    if (chart.minX == undefined) chart.minX = 0;
    if (chart.maxX == undefined) chart.maxX = 500;
    if (chart.tickX == undefined) chart.tickX = 10;
    if (chart.minY == undefined) chart.minY = 0;
    if (chart.maxY == undefined) chart.maxY = 100;
    if (chart.tickY == undefined) chart.tickY = 10;
    if (chart.axisLineColor == undefined) chart.axisLineColor = "White";
    if (chart.tickLineColor == undefined) chart.tickLineColor = "White";
    if (chart.barSize === undefined || chart.barSize < 0.01 || chart.barSize > 1.0) chart.barSize = 0.60 / chart.bars.length;

    ctx.save();

    var minY = chart.minY;
    var maxY = chart.maxY;

    var minX = chart.minX;
    var maxX = chart.maxX;

    var labelWidth = 20;
    var LabelHeight = 8;
    var labelStaryY = minY;
    var tickLineWidth = 10;
    var tickLineHeight = 10;
    var tickLineBottomMargin = 4;
    var x;
    var y;
    var xx;
    var yy;
    var TextLineHeight = 8;
    var YAxisHeight = TextLineHeight + tickLineHeight;
    var XAxisWidth = labelWidth + tickLineWidth;

    chart.barWidth = (chart.barSize/2) * chart.tickX;

    chart.YRange = (canvas.height - (chart.margin * 3) - TextLineHeight - YAxisHeight);
    chart.XRange = (canvas.width - (chart.margin * 3) - TextLineHeight - XAxisWidth);

    chart.PixelsToY = chart.YRange / (maxY - minY);
    chart.PixelsToX = chart.XRange / (maxX - minX);

    chart.xEdge = chart.margin + labelWidth + tickLineWidth;
    chart.yEdge = chart.margin * 2;


    // Graph bounding rectangle

    x = 0;
    y = 0;

    var padding = 2;
    var spacer = 8;

    ctx.beginPath();
    ctx.rect(x, y, canvas.width - 1, canvas.height - 1);
    ctx.fillStyle = chart.Background;
    ctx.fill();
    ctx.lineWidth = 1;
    ctx.strokeStyle = "gray";
    ctx.stroke();


    // Plot bars.

    var bar;
    var series;
    var leftAdjust = (chart.bars.length - 1) * chart.barWidth;    // TODO: find out why X-tick not preceisely centered in 2+ bar plot.

    for (var bb = 0; bb < chart.bars.length; bb++)
    {
        series = chart.bars[bb];
        for (var b = 0; b < series.length; b++)
        {
            bar = series[b];
            bar.X = chart.xEdge + BarChart_XPos(chart, bar.x - chart.barWidth + (bb * chart.barWidth * 2)) - leftAdjust;
            bar.Y = chart.yEdge + BarChart_YPos(chart, bar.y);
            bar.XX = chart.xEdge + BarChart_XPos(chart, bar.x + (bb * chart.barWidth * 2) + chart.barWidth) - leftAdjust;
            bar.YY = chart.yEdge + BarChart_YPos(chart, 0);
            bar.IsGrowing = true;
            bar.IsShrinking = false;
            bar.Growing = (bar.YY - bar.Y) / 2;
            bar.Shrinking = BarChart_ShrinkAmount;
            bar.Delay = b * 5;

            // If color for bar is unspecified, default color to either bar[0].color in the series (if specified), else a blue gradient.

            if (bar.Color === undefined) {
                if (series[0].Color != undefined) {
                    bar.Color = series[0].Color;
                }
                else {
                    bar.Color = "#00B8FD:#004AA8";
                }
            }

            if (bar.title === undefined) {
                if (series[0].title != undefined) {
                    bar.title = series[0].title;
                }
                else {
                    bar.title = "" ;
                }
            }

            if (chart.click || chart.mouseover)
            {
                BarChart_HitList.push({ x: bar.X, y: bar.Y, xx: bar.XX, yy: bar.YY, Bar: bar, Chart: chart });
            }
        }
    }


    BarChart_PlotBars(chart);


    // Set interval timer to animate bars.

    chart.order = BarChart_BarChart_PlotBarsFunc.length;
    BarChart_BarChart_PlotBarsFunc.push(function () { BarChart_PlotBars(chart); });
    setInterval(BarChart_BarChart_PlotBarsFunc[BarChart_BarChart_PlotBarsFunc.length-1], 10);


    // Title

    x = chart.xEdge + BarChart_XPos(chart, (chart.maxX - chart.minX)/2);
    y = chart.yEdge - TextLineHeight;
    ctx.fillStyle = chart.titleColor;

    if (chart.titleFont != undefined) {
        ctx.font = chart.titleFont;
    }
    else {
        ctx.font = "bold 12px sans-serif";
    }

    ctx.textAlign = "center";
    ctx.fillText(chart.title, x, y);


    // Y-Axis - Vertical tick marks

    ctx.strokeStyle = chart.tickLineColor;
    ctx.fillStyle = chart.tickLineColor;
    ctx.lineWidth = 1;

    if (chart.axisFont != undefined) {
        ctx.font = chart.axisFont;
    }
    else {
        ctx.font = "bold 12px sans-serif";
    }

    ctx.textAlign = "center";

    for (var valueY = minY; valueY <= maxY; valueY += chart.tickY) {

        y = chart.yEdge + BarChart_YPos(chart, valueY);
        yy = y + TextLineHeight/2;

        // tick label.

        xx = chart.margin + labelWidth - 8;

        ctx.fillText(Math.round(valueY), xx, yy);

        // tick line

        x = chart.margin + labelWidth;
        xx = x + tickLineWidth;

        ctx.beginPath();
        ctx.lineWidth = 1;
        ctx.moveTo(x, y);
        ctx.lineTo(xx, y);
        ctx.stroke();
    }


    // X-Axis - Horizontal tick marks

    ctx.strokeStyle = chart.tickLineColor;
    ctx.fillStyle = chart.tickLineColor;
    ctx.lineWidth = 2;

    if (chart.axisFont != undefined) {
        ctx.font = chart.axisFont;
    }
    else {
        ctx.font = "bold 12px sans-serif";
    }

    ctx.textAlign = "center";

    x = chart.xEdge;
    y = chart.yEdge + BarChart_YPos(chart, 0) + YAxisHeight;

    var text;
    var c = 0;

    for (var valueX = minX; valueX <= maxX; valueX += chart.tickX) {

        xx = x + BarChart_XPos(chart, valueX);

        // tick label.

        if (chart.hasColumnNames)
        {
            text = chart.columnNames[c++];
        }
        else
        {
            text = Math.round(valueX).toString();
        }

        if (text != undefined) {
            ctx.fillText(text, xx, y + 6);
        }

        // tick line

        yy = y - LabelHeight;

        ctx.beginPath();
        ctx.lineWidth =
        ctx.moveTo(xx, yy);
        ctx.lineTo(xx, yy - tickLineHeight);
        ctx.stroke();
    }


    // Graph Y-Axis line

    x = chart.xEdge + BarChart_XPos(chart, 0);
    y = chart.yEdge + BarChart_YPos(chart, 0);

    xx = chart.margin + labelWidth + tickLineWidth + BarChart_XPos(chart, maxX - 1);
    yy = chart.yEdge + BarChart_YPos(chart, maxY - 1) - TextLineHeight / 2;

    ctx.strokeStyle = chart.axisLineColor;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(x, yy);
    ctx.stroke();


    // Graph X-Axis line

    x = chart.xEdge + BarChart_XPos(chart, 0);
    y = chart.yEdge + BarChart_YPos(chart, 0) + 1;

    xx = chart.xEdge + BarChart_XPos(chart, maxX);
    yy = chart.yEdge + BarChart_YPos(chart, maxY - 1);

    ctx.strokeStyle = chart.axisLineColor;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(xx, y);
    ctx.stroke();

    ctx.restore();
}


//*******************
//*                 *
//*  BarChart_YPos  *
//*                 *
//*******************
// Convert Y value to Y position. Relative, does not take margin into account.

function BarChart_YPos(chart, y)
{
    return chart.YRange - (y * chart.PixelsToY);
}


//*******************
//*                 *
//*  BarChart_XPos  *
//*                 *
//*******************
// Convert X value to X position. Relative, does not take margin into account.

function BarChart_XPos(chart, x) {
    return (x * chart.PixelsToX);
}


//***********************
//*                     *
//*  BarChart_PlotLine  *
//*                     *
//***********************
// Draw a line connecting two points.

function BarChart_PlotLine(ctx, x, y, xx, yy) {
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(xx, yy);
    ctx.stroke();
}


//**********************
//*                    *
//*  BarChart_PlotBar  *
//*                    *
//**********************
// Draw a bar connecting two corners.

function BarChart_PlotBar(chart, x, y, xx, yy, color) {

    var ctx = chart.ctx;

    lingrad = ctx.createLinearGradient(x, y, xx, yy);

    ctx.beginPath();
    ctx.rect(x, y, xx - x, yy - y);

    SetFillStyle(chart.ctx, color, x, y, xx, yy);

    ctx.fill();
    ctx.lineWidth = 0;
    ctx.strokeStyle = "Transparent";
    ctx.stroke();
}


//************************
//*                      *
//*  UnBarChart_PlotBar  *
//*                      *
//************************
// Remove a bar.
function UnBarChart_PlotBar(chart, x, y, xx, yy) {

    var ctx = chart.ctx;
    if (chart.Background == "Transparent") {
        ctx.clearRect(x, y, xx - x, yy - y);
    }
    else {
        ctx.fillStyle = chart.Background;
        ctx.fillRect(x, y, xx - x, yy - y);

    }
}


//***********************
//*                     *
//*  BarChart_PlotBars  *
//*                     *
//***********************
// Draw all bars, all series.

function BarChart_PlotBars(chart) {
    var active = 0;
    var series;
    var bar;
    var ctx = chart.ctx;
    var TextLineHeight = 8;

    if (chart.valueFont != undefined) {
        ctx.font = chart.valueFont;
    }
    else {
        ctx.font = "bold 16px sans-serif";
    }

    ctx.textAlign = "center";

    for (var bb = 0; bb < chart.bars.length; bb++) {
        series = chart.bars[bb];

        for (var b = 0; b < series.length; b++) {
            bar = series[b];

            if (bar.Delay > 0) {    // Delaying
                bar.Delay--;
                active++;
            }
            else {  // Not delaying

                if (bar.IsGrowing) {   // Still growing
                    active++;
                    rem = bar.Growing;
                    y = bar.Y + rem;
                    if (y > bar.YY) { y = bar.YY; }
                    BarChart_PlotBar(chart, bar.X, y, bar.XX, bar.YY, bar.Color);
                    bar.Growing -= BarChart_GrowAmount;
                    rem -= BarChart_GrowAmount;
                    if (rem <= -BarChart_ShrinkAmount) {
                        bar.IsGrowing = false;
                        bar.IsShrinking = true;
                    }
                }
                else if (bar.IsShrinking) {
                    rem = bar.Shrinking;
                    active++;
                    y = bar.Y + rem;
                    if (y > bar.YY) { y = bar.YY; }
                    UnBarChart_PlotBar(chart, bar.X, bar.Y - BarChart_ShrinkAmount, bar.XX, y);
                    BarChart_PlotBar(chart, bar.X, y, bar.XX, bar.YY, bar.Color);
                    bar.Shrinking -= BarChart_ShrinkDecrement;
                    rem -= BarChart_ShrinkDecrement;
                    if (rem <= 0) {
                        bar.IsShrinking = false;
                        if (bar.Value != undefined) {
                            ctx.fillText(bar.Value.split('_')[0], bar.X + ((bar.XX - bar.X) / 2), bar.Y - 4);
                            ctx.font = "16px sans-serif";
                            ctx.fillText(bar.title, chart.xEdge+200,chart.yEdge+(bb*20));
                            if (bar.Value2 != undefined) {
                                ctx.fillText(bar.Value2, bar.X + ((bar.XX - bar.X) / 2), bar.Y - 4 - TextLineHeight);
                            }
                        }
                    }
                }
            }
        }
    }
    if (active == 0)
    {
        clearInterval(BarChart_BarChart_PlotBarsFunc[chart.order]);
    }
}


//******************
//*                *
//*  SetFillStyle  *
//*                *
//******************
// Convert a style string (can be undefined, empty, <style-text>, a #<color-code>, <color-name>, or #<color1>::#<color2> (gradient).
// The gradient processing is the special is what this function contributes.

function SetFillStyle(ctx, style, x, y, xx, yy) {
    if (style != undefined && style != null) {
        var pos = style.toString().indexOf(":#");
        if (pos != -1) {

            color1 = style.slice(0, pos);
            color2 = style.slice(pos + 1, style.length);
            var lingrad = ctx.createLinearGradient(x, y, xx, yy);
            lingrad.addColorStop(0, color1);
            lingrad.addColorStop(0.5, color1);
            lingrad.addColorStop(1, color2);
            ctx.fillStyle = lingrad;
        }
        else {
            ctx.fillStyle = style;
        }
    }
}


//**************************
//*                        *
//*  BarChart_getPosition  *
//*                        *
//**************************
// Mouse event handler - highlight bar when clicked over.

function BarChart_getPosition(event) {

    var x;
    var y;
    var region;
    var canvasId;
    var canvas;
    var hit = false;

    if (BarChart_CanvasId != undefined) {
        for (var c = 0; c < BarChart_CanvasId.length; c++) {
            canvasId = BarChart_CanvasId[c];
            canvas = document.getElementById(canvasId);

            //if (event.x != undefined && event.y != undefined)
            //{
            //    x = event.x;
            //    y = event.y;
           // }
           // else // Firefox method to get the position
           // {
                x = event.clientX + document.body.scrollLeft +
                    document.documentElement.scrollLeft;
                y = event.clientY + document.body.scrollTop +
                    document.documentElement.scrollTop;
           // }

            x -= canvas.offsetLeft;
            y -= canvas.offsetTop;



            for (var h = 0; h < BarChart_HitList.length; h++) {
                region = BarChart_HitList[h];
                if (region.Chart.CanvasId == canvasId &&
                    x >= region.x && x <= region.xx && y >= region.y && y <= region.yy) {
                    if (BarChart_HighlightedBar != null) {
                        BarChart_PlotBar(BarChart_HighlightedBar.Chart, BarChart_HighlightedBar.x, BarChart_HighlightedBar.y, BarChart_HighlightedBar.xx, BarChart_HighlightedBar.yy, BarChart_HighlightedBar.Bar.Color);
                        BarChart_HighlightedBar = null;
                    }

                    BarChart_PlotBar(region.Chart, region.x, region.y, region.xx, region.yy, region.Chart.clickColor);
                    BarChart_HighlightedBar = region;
                    hit = true;
                    //alert(h);
                    var url_names = ["institutions","centers","classes","sections","users"];
                    var id = region.Bar.Value.split('_')[1];
                    var mode = region.Bar.Value.split('_')[2];
                    //alert(id);
                    if (mode!=undefined){
                        var append_url= url_names.indexOf(mode);
                        if (mode!="users"){
                            window.location = "http://"+location.host+"/"+mode+"/"+id+"/"+url_names[append_url+1]+"/usage/report";
                        }else{
                            window.location = "http://"+location.host+"/"+mode+"/"+id+"/usage/report";
                        }
                    }
                    break;
                } // end if
            } // end for h
        } // end for c

        if (!hit && BarChart_HighlightedBar != null) {
            BarChart_PlotBar(BarChart_HighlightedBar.Chart, BarChart_HighlightedBar.x, BarChart_HighlightedBar.y, BarChart_HighlightedBar.xx, BarChart_HighlightedBar.yy, BarChart_HighlightedBar.Bar.Color);
            BarChart_HighlightedBar = null;
        }
    } // end if
} // end func


function BarChart_getPosition1(event) {

    var x;
    var y;
    var region;
    var canvasId;
    var canvas;
    var hit = false;

    if (BarChart_CanvasId != undefined) {
        for (var c = 0; c < BarChart_CanvasId.length; c++) {
            canvasId = BarChart_CanvasId[c];
            canvas = document.getElementById(canvasId);


            //x -= canvas.offsetLeft;
            //y -= canvas.offsetTop;
             x = event.clientX + document.body.scrollLeft +
                    document.documentElement.scrollLeft;
                y = event.clientY + document.body.scrollTop +
                    document.documentElement.scrollTop;
           // }

            x -= canvas.offsetLeft;
            y -= canvas.offsetTop;

            for (var h = 0; h < BarChart_HitList.length; h++) {
                region = BarChart_HitList[h];
                if (region.Chart.CanvasId == canvasId &&
                    x >= region.x && x <= region.xx && y >= region.y && y <= region.yy) {
                    if (BarChart_HighlightedBar != null) {
                        BarChart_PlotBar(BarChart_HighlightedBar.Chart, BarChart_HighlightedBar.x, BarChart_HighlightedBar.y, BarChart_HighlightedBar.xx, BarChart_HighlightedBar.yy, BarChart_HighlightedBar.Bar.Color);
                        BarChart_HighlightedBar = null;
                    }
                    BarChart_PlotBar(region.Chart, region.x, region.y, region.xx, region.yy, region.Chart.clickColor);
                    BarChart_HighlightedBar = region;
                    hit = true;
                    $("#_"+(h+1)).show();
                    break;
                }else{
                 $("#_"+(h+1)).hide();
                } // end if
            } // end for h
        } // end for c

        if (!hit && BarChart_HighlightedBar != null) {
            BarChart_PlotBar(BarChart_HighlightedBar.Chart, BarChart_HighlightedBar.x, BarChart_HighlightedBar.y, BarChart_HighlightedBar.xx, BarChart_HighlightedBar.yy, BarChart_HighlightedBar.Bar.Color);
            BarChart_HighlightedBar = null;
        }
    } // end if
} // end func



function writeMessage(canvas, message){
    var context = canvas.getContext('2d');
    context.clearRect(0, 0, canvas.width, canvas.height);
    context.font = '18pt Calibri';
    context.fillStyle = 'black';
    context.fillText(message, 10, 25);
}
