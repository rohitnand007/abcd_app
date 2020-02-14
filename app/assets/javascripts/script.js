"use strict";
// add onload event listener
/*if (window.addEventListener) {
 window.addEventListener('load', header_init, false);
 }
 else if (window.attachEvent) {
 window.attachEvent('onload', header_init);
 }*/
/*Variable declarations and initializations*/
var main_storage = new Array(), childArray = new Array(), allchilds = new Array(), divColors = new Array(), cnvs = new Array(), ctx = new Array();
var nodeStore = new Array();
var childStore = new Array();
var anim_layer = new Array();
var anim_ctx = new Array();
var el_ce_an_store = new Array();
var Element_positions = new Array();
var el_position = new Array();
var new_el_pos = new Array();
var default_pos = new Array();
var dcindex = 0, nodeState = 0, xmlhttp, x, i, main_element, childs, node, id, parent_id, element_name, detail;
var arrow_layer, arrow_ctx, anim_layer, anim_ctx, anim_load = 0, line_length = 90, select_anim_load = 0;
var infoDisplay, showSelection, initial = 0, styles, zoom = 1, angle_state = 0, zoomclick = 0, depth = 0;
var zoom_anim, zoom_load, click = 0, click_anim = 0, big_radius = 45, small_radius = 14, myscroll, done = 0, detector = 0;
/*temp vars*/
var anlgle_init_pos = new Array();
var angle_end_pos = new Array();
var scolor = "rgb(180,180,180)", bcolor = "rgb(40,176,242)", linecolor = "rgb(13,148,213)";
var diagonal = Math.round(Math.sqrt(2) * big_radius * 2) + 1;
var static_diag = diagonal;
var conceptmapLocation = "";
var iCnt = 0;
// header initialization
function header_init() {
    /*    try {
     if (myScroll)
     myScroll.destroy();
     } catch (er) {

     }*/
//    window.setTimeout(function () {
//        var arg = "#default";
//
//        try {
//            arg = window.webviewhandler.getArgument();
//        } catch (e) {
//            arg = "#default";
//        }
//        if (arg && arg != "#default") {
//            var temp = arg.split('\/');
//            conceptmapLocation = arg.substr(0, (arg.length - temp[temp.length - 1].length));
//            loadXML(arg);
//        }
//        else {
//            conceptmapLocation = "src/xml/"
//            loadXML("src/xml/conceptmap.xml");
//        }
//        window.setTimeout(create_Init_Element, 50);
//        $$("aside").className = "fixedclass";
//
//        //myScroll = new iScroll('aside');
//    }, 50);
}
function $$(id) {
    return document.getElementById(id);
}
function zplus() {
    if (zoom <= 5 && zoomclick == 0) {
        var brk = 0.1 / 10;
        var store = zoom;
        zoomclick = 1;
        zoom_load = window.setInterval(zoom_anim, 35, [zoom, brk, store, 0]);
        zoom = zoom + 0.1;
        return false;
    }
}
function zoom_anim(data) {
    $$('map').style.MozTransform = "scale(" + data[0] + ")";
    $$('map').style.WebkitTransform = "scale(" + data[0] + ")";
    $$('map').style.Transform = "scale(" + data[0] + ")";
    if (el_position) {
        $$('map').style.MozTransformOrigin = "" + el_position[0] + " " + el_position[1] + "";
        $$('map').style.TransformOrigin = "" + el_position[0] + " " + el_position[1] + "";
    }
    if (data[3] == 0) {
        data[0] = data[0] + data[1];
        if (data[2] + 0.1 <= data[0]) {
            clearInterval(zoom_load);
            zoomclick = 0;
        }
    }
    else {
        data[0] = data[0] - data[1];
        if (data[2] - 0.1 >= data[0]) {
            clearInterval(zoom_load);
            zoomclick = 0;
        }
    }
}
function zminus() {
    if (zoom >= 0.1 && zoomclick == 0) {
        var brk = 0.1 / 10;
        var store = zoom;
        zoomclick = 1;
        zoom_load = window.setInterval(zoom_anim, 35, [zoom, brk, store, 1]);
        zoom = zoom - 0.1;
        return false;
    }
}
function reset_view() {
    $$('map').style.MozTransform = "scale(1)";
    $$('map').style.WebkitTransform = "scale(1)";
    $$('map').style.Transform = "scale(1)";
    $$('map').style.MozTransformOrigin = "" + el_position[0] + " " + el_position[1] + "";
    $$('map').style.TransformOrigin = "" + el_position[0] + " " + el_position[1] + "";
    window.scroll(default_pos[0], default_pos[1]);
    zoom = 1;
    return false;
}

function loadJson(jsonStr) {
    loadObject(jsonStr);
    x = new Object();
    x.length = iCnt;
}
function loadObject(obj) {
    id = obj.id;
    parent_id = obj.parentId;
    var m = obj.name;
    element_name = obj.name;
    m = obj.details;
    detail = m;// m[0].firstChild.nodeValue;
    if (detail != null) {
        detail = detail.replace(/height=/g, "name=");
        detail = detail.replace(/<img /g, '<img onclick="javascript:showBigImage(this);"');
        detail = detail.replace(/src="/g, 'src="' + conceptmapLocation);
    }
    else {
        detail = "No description";
    }
    main_storage[iCnt++] = [element_name, id, parent_id, detail];
    if (obj.child != null && obj.child.length > 0) {
        for (var j = 0; j < obj.child.length; j++) {
            loadObject(obj.child[j]);
        }
    }

//}
//function loadXML(url) {
//    if (window.XMLHttpRequest) {// code for IE7+, Firefox, Chrome, Opera, Safari
//        xmlhttp = new XMLHttpRequest();
//    }
//    else {// code for IE6, IE5
//        xmlhttp = new ActiveXnodeect("Microsoft.XMLHTTP");
//    }
//    xmlhttp.onreadystatechange = function () {
//        if (xmlhttp.readyState == 4) {
//            x = xmlhttp.responseXML.getElementsByTagName("cmap");
//            for (i = 0; i < x.length; i++) {
//                id = x[i].getAttribute("id");
//                parent_id = x[i].getAttribute("parent_id");
//                var m = x[i].getElementsByTagName("name");
//                element_name = m[0].firstChild.nodeValue;
//                m = x[i].getElementsByTagName("detail");
//                detail = m[0].firstChild.nodeValue;
//                detail = detail.replace(/height=/g, "name=");
//                detail = detail.replace(/<img /g, '<img onclick="javascript:showBigImage(this);"');
//                detail = detail.replace(/src="/g, 'src="' + conceptmapLocation);
//                main_storage[i] = [element_name, id, parent_id, detail];
//            }
//        }
//    }
    //  xmlhttp.open("GET", url, false);
    //  xmlhttp.send();
}

function showBigImage(imgObj) {
    var zoomImage = document.getElementById('zoomimage');
    zoomImage.style.position = 'absolute';
    zoomImage.src = imgObj.src;
    zoomImage.onerror = function () {
        alert('error loading ' + imgObj.src);
    };
    zoomImage.style.position = 'fixed';
    zoomImage.style.left = (parseInt(window.innerWidth) - parseInt(zoomImage.offsetWidth)) / 2 + 'px';
    if (zoomImage.offsetHeight >= window.innerHeight)
        zoomImage.style.top = 0 + 'px';
    else
        zoomImage.style.top = (parseInt(window.innerHeight) / 2 - parseInt(zoomImage.offsetHeight) / 2) + 'px';
    zoomImage.style.zIndex = 35;
    zoomImage.style.visibility = 'visible';
    document.getElementById('zoomimage').style.visibility = 'visible';
}

function create_Init_Element() {
    var top = Math.floor((window.innerHeight + window.outerHeight * 2) / 2);
    var left = Math.floor((window.innerWidth + window.outerWidth * 2) / 2);
    main_element = document.createElement("canvas");
    settingsApply(main_element, dcindex, 0, 0);
    ctx = $$(main_storage[0][1]).getContext("2d");
    settingContext(ctx, small_radius, (main_element.width / 2), (main_element.height - main_element.height / 8), getText(main_storage[0][0]), scolor)
    attach_createchild_Event($$(main_storage[0][1]));
    $$(main_storage[0][1]).style.position = "absolute";
    $$(main_storage[0][1]).style.left = left + "px";
    $$(main_storage[0][1]).style.top = top + "px";
    window.scroll((left - (window.innerWidth / 3) + (big_radius * 2)), (top - (window.innerHeight / 3)));
    default_pos = [(left - (window.innerWidth / 3) + (big_radius * 2)), (top - (window.innerHeight / 3))];
    $$('zoomerplus').addEventListener('click', zplus, true);
    $$('zoomerminus').addEventListener('click', zminus, true);
    $$('normal_view').addEventListener('click', reset_view, true);
    $$("content").innerHTML = "Please click on " + getText(main_storage[0][0]) + " to know more about it.";
    $$("title").innerHTML = "HELP";

    //below lines for line drawing layer
    arrow_layer = document.createElement("canvas");
    arrow_layer.setAttribute("height", ($$("map").offsetHeight));
    arrow_layer.setAttribute("width", ($$("map").offsetWidth));
    arrow_layer.setAttribute("id", "arrow");
    $$("map").appendChild(arrow_layer);
    arrow_layer.setAttribute("class", "map_2nd_layer");
    $$("arrow").style.border = "none";
    arrow_ctx = arrow_layer.getContext("2d");
    arrow_layer.style.position = "absolute";
    arrow_layer.style.left = 0+"px";
    arrow_layer.style.top = 0+"px";

    //animation layer setup and animation context setup layer: anim_layer, ctx: anim_ctx
    anim_layer = document.createElement("canvas");
    anim_layer.setAttribute("height", ($$("map").offsetHeight));
    anim_layer.setAttribute("width", ($$("map").offsetWidth));
    anim_layer.setAttribute("id", "animation");
    $$("map").appendChild(anim_layer);
    anim_layer.setAttribute("class", "map_3rd_layer");
    anim_ctx = anim_layer.getContext("2d");
    anim_layer.style.position = "absolute";
    anim_layer.style.left = 0+"px";
    anim_layer.style.top = 0+"px";
}
function create_Childs(e) {

    $$("preview").childNodes[1].appendChild($$("map"));

    if (click == 0 && click_anim == 0) {
        click = 1;
        click_anim = 1;
        document.getElementById('zoomimage').src = '';
        document.getElementById('zoomimage').style.visibility = 'hidden';
        node = e.target;
        window.scroll((node.offsetLeft - (window.innerWidth / 3) + (big_radius * 2)), (node.offsetTop - (window.innerHeight / 3)));
        el_position = [(node.offsetLeft - (window.innerWidth / 3) + (big_radius * 2)), (node.offsetTop - (window.innerHeight / 3))];
        var pos = infoDisplay(node);
        if (!node.nodeState) {
            allchilds = getAllChilds(node);
            showAllChilds(allchilds, node);
            showSelection(node, pos, 1);
        }
        else {
            showSelection(node, pos, 0);
            click_anim = 0;
        }
        e.preventDefault();
        e.stopPropagation();
    }
}
function showSelection(node, pos, state) {
    var new_ctx = node.getContext("2d");
    var temp_Radius = small_radius;
    select_anim_load = 0;
    select_anim_load = window.setInterval(selected_Animation, 1, [node, new_ctx, pos, temp_Radius]);
    var allchilds = getAllChilds(node);
    childStore = allchilds.slice();//copying array into another array
    if (initial == 0 || nodeStore[0].id == node.id)//if the same node clicked again then will not draw again.
    {
        nodeStore = [node, pos, childStore];
        initial = 1;
    }
    else {
        for (i = 0; i < nodeStore[2].length; i++) {
            var childs = nodeStore[2];
            var p = childs[i];
            var id = main_storage[p][1];
            if ((main_storage[p][1]) != node.id) {
                var ctx = $$(main_storage[p][1]).getContext("2d");
                ctx.clearRect(0, 0, $$(main_storage[p][1]).width, $$(main_storage[p][1]).height);
                settingContext(ctx, small_radius, ($$(main_storage[p][1]).width / 2), ($$(main_storage[p][1]).height - $$(main_storage[p][1]).height / 8), getText(main_storage[p][0]), scolor);
            }
        }
        var old_ctx = nodeStore[0].getContext("2d");
        old_ctx.clearRect(0, 0, nodeStore[0].width, nodeStore[0].height);
        settingContext(old_ctx, small_radius, (nodeStore[0].width / 2), (nodeStore[0].height - nodeStore[0].height / 8), getText(main_storage[nodeStore[1]][0]), scolor);
        nodeStore = [node, pos, childStore];
        if (node.nodeState) {
            for (i = 0; i < nodeStore[2].length; i++) {
                var childs = nodeStore[2];
                var p = childs[i];
                var id = main_storage[p][1];
                if ((main_storage[p][1]) != node.id) {
                    var ctx = $$(main_storage[p][1]).getContext("2d");
                    ctx.clearRect(0, 0, $$(main_storage[p][1]).width, $$(main_storage[p][1]).height);
                    settingContext(ctx, small_radius, ($$(main_storage[p][1]).width / 2), ($$(main_storage[p][1]).height - $$(main_storage[p][1]).height / 8), getText(main_storage[p][0]), bcolor);
                }
            }
        }
    }
    node.nodeState = 1;
}
function selected_Animation(data) {
    var node = data[0];
    var new_ctx = data[1];
    var pos = data[2];
    new_ctx.clearRect(0, 0, node.width, node.height);
    settingContext(new_ctx, data[3], (node.width / 2), (node.height / 2), getText(main_storage[pos][0]), bcolor);
    if (data[3] >= big_radius) {
        data[3] = big_radius;
        window.clearInterval(select_anim_load);
        click = 0;
    }
    if (data[3] + 2 < big_radius)
        data[3] = data[3] + 2;
    else
        data[3]++;
}
function infoDisplay(node) {
    for (i = 0; i < x.length; i++) {
        if (node.id == main_storage[i][1]) {
            $$("content").innerHTML = main_storage[i][3] + "<br><br><br><br><br><br>";
            setTimeout(resizeImage, 10);
            $$("title").innerHTML = main_storage[i][0];

            return i;
        }
    }
}
function getParent(node) {
    for (var i = 0; i < x.length; i++) {
        if (node.id == main_storage[i][1]) {
            var parent = $$(main_storage[i][2]);
            return parent;
        }
    }
}
function placingNodes(ncleft, nctop, node, required_len, degrees, angle, r) {
    if (node.id == 1) {
        node.depth = node.id;
    }
    else {
        var parent = getParent(node);
        node.depth = parseInt(parent.depth) + 1;
    }
    Element_positions.length = 0;
    new_el_pos.length = 0;
    var j = 0;
    var len = document.querySelectorAll('.canvas_map').length;
    if (node.id == 1) {
        var step = (degrees * Math.PI) / required_len;
        var origin_angle = angle;
    }
    else {
        var angle_toreduce = node.angle_state / required_len;
        if (angle_toreduce < 0.15 && node.depth > 2) {
            angle_toreduce = 0.2;
        }
        var stable = angle_toreduce;
        step = angle_toreduce;
        r = (big_radius + (big_radius - big_radius / 3)) / (Math.tan(stable));
        if (r < diagonal) {
            r = diagonal;
        }
        else if (r > 350) {
            r = 300;
        }
        var fromX = (parent.offsetLeft + ((parent.offsetWidth) / 2));
        var fromY = (parent.offsetTop + ((parent.offsetHeight) / 2));
        var origin_angle = Math.atan2(nctop - fromY, ncleft - fromX);
    }
    for (var k = 0; k < required_len; k++) {
        var cnleft = Math.round(ncleft + r * Math.cos(origin_angle));
        var cntop = Math.round(nctop + r * Math.sin(origin_angle));
        Element_positions[j++] = [cnleft, cntop, r, step];
        if (node.id != 1) {
            if (done == 0) {
                origin_angle += angle_toreduce;
                done = 1;
            }
            else {
                origin_angle = origin_angle - angle_toreduce;
                done = 0;
            }
            angle_toreduce = angle_toreduce + stable;
        }
        else {
            origin_angle += step;
        }
    }
    return Element_positions;
}
function resizeImage() {
    var ln = $$("content").querySelectorAll("img").length;
    for (i = 0; i < ln; i++) {
        if ($$("content").querySelectorAll("img")[i].width > $$("asidedata").offsetWidth) {
            $$("content").querySelectorAll("img")[i].style.width = "100%";
        }
        $$("content").querySelectorAll("img")[i].style.position = "relative";
        $$("content").querySelectorAll("img")[i].style.left = 2 + "px";
    }
    if ($$("content").querySelector("embed")) {
        //alert($$("content").querySelector("embed"));
    }
}
function getAllChilds(node) {
    var count = 0;
    var left = node.offsetLeft;
    var top = node.offsetTop;
    childArray.length = 0;
    for (i = 0; i < x.length; i++) {
        if (node.id == main_storage[i][2] && node.id == main_storage[i][1])//if it is a starting node
        {
            for (var j = 0; j < x.length; j++) {
                if (node.id == main_storage[j][2] && node.id != main_storage[j][1]) {
                    childArray[count] = j;
                    ++count;
                }
            }
            return childArray;
        }
        else if (node.id == main_storage[i][2]) {
            childArray[count] = i;
            ++count;
        }
    }
    return childArray;
}

function showAllChilds(allchilds, node) {
    var ncleft = (node.offsetLeft + ((node.offsetWidth) / 2));
    var nctop = (node.offsetTop + ((node.offsetHeight) / 2));
    var len = allchilds.length;
    var nooverlap = placingNodes(ncleft, nctop, node, len, 2, 0, diagonal);
    var r = 10;
    if (len > 0) {
        window.clearInterval(anim_load);
        anim_load = 0;
        anim_load = window.setInterval(animateCircles, 1, [ncleft, nctop, len, allchilds, r, nooverlap]);
    }
    else {
        click_anim = 0;
    }
}
function drawing_circles(data) {
    var nooverlap = data[4];
    var ncleft = data[0];
    var nctop = data[1];
    var len = data[2];
    var allchilds = data[3];
    var radius = nooverlap[0][2];
    for (i = 0; i < len; i++) {
        var pos = allchilds[i];
        cnvs[i] = document.createElement("canvas");
        settingsApply(cnvs[i], dcindex, i, pos);//applying settings for canvas element
        $$(main_storage[pos][1]).angle_state = nooverlap[0][3];
        ctx[i] = $$(main_storage[pos][1]).getContext("2d");
        settingContext(ctx[i], small_radius, (cnvs[i].width / 2), (cnvs[i].height - cnvs[i].height / 8), getText(main_storage[pos][0]), bcolor);
        $$(main_storage[pos][1]).style.position = "absolute";
        attach_createchild_Event($$(main_storage[pos][1]));
        $$(main_storage[pos][1]).style.left = (nooverlap[i][0] - (big_radius + small_radius / 2)) + "px";
        $$(main_storage[pos][1]).style.top = (nooverlap[i][1] - (big_radius + small_radius / 2)) + "px";
    }
    createLines(ncleft, nctop, len, nooverlap);
}
function settingsApply(obj, dcindex, index, pos) {
    obj.setAttribute("height", ((big_radius * 2) + small_radius));
    obj.setAttribute("width", ((big_radius * 2) + small_radius));
    obj.setAttribute("id", main_storage[pos][1]);
    $$("map").appendChild(obj);
    obj.setAttribute("class", "canvas_map");
}
function settingsApplyforAnim(obj, dcindex, pos) {
    obj.setAttribute("height", ((big_radius * 2) + small_radius));
    obj.setAttribute("width", ((big_radius * 2) + small_radius));
    obj.setAttribute("id", main_storage[pos][1]);
    $$("map").appendChild(obj);
    obj.setAttribute("class", "canvas_map");
}
function attach_createchild_Event(obje) {
    obje.addEventListener("click", create_Childs, true);
}
function getText(obj_for_text) {
    $$("dummy").innerHTML = obj_for_text;
    return $$("dummy").textContent;//.firstChild.firstChild.firstChild.nodeValue;
}
function settingContext(ctx, r, left, top, text, color) {
    ctx.beginPath();
    ctx.arc($$("1").width / 2, $$("1").height / 2, r, 0, Math.PI * 2, true);
    ctx.fillStyle = color;
    ctx.fill();
    if (r == big_radius)//this is for border drawing on outer side of big circle
    {
        ctx.strokeStyle = bcolor;
        ctx.arc($$("1").width / 2, $$("1").height / 2, r + 4, 0, Math.PI * 2, true);
        ctx.stroke();
    }
    ctx.closePath();
    ctx.beginPath();
    ctx.font = "10pt Tahoma";
    if (r == big_radius) {
        if (text.length > 15) {
            wrapText(ctx, text, left, top - 10, ($$("1").width - $$("1").width / 3), 10);
        }
        else {
            wrapText(ctx, text, left, top + 5, ($$("1").width - $$("1").width / 3), 10);
        }
    }
    else {
        wrapText(ctx, text, left, top - 10, $$("1").width, 10);//ctx.fillText(text, 5, 10); this has been replaced if text is bigger
    }
    ctx.closePath();
}
function createLines(x, y, no_of_lines, nooverlap) {
    var radius = nooverlap[0][2];
    var firsthalf = radius / 3;
    for (var i = 0; i < no_of_lines; i++) {
        var angle = Math.atan2(nooverlap[i][1] - y, nooverlap[i][0] - x);
        var lineleft = Math.round(x + (firsthalf * 2 - 2) * Math.cos(angle));
        var linetop = Math.round(y + (firsthalf * 2 - 2) * Math.sin(angle));
        arrow_ctx.save();
        arrow_ctx.beginPath();
        canvas_arrow(arrow_ctx, x, y, lineleft, linetop);

        var nleft = Math.round(lineleft + (firsthalf + 2) * Math.cos(angle));
        var ntop = Math.round(linetop + (firsthalf + 2) * Math.sin(angle));
        arrow_ctx.moveTo(lineleft, linetop);
        arrow_ctx.lineTo(nleft, ntop);
        arrow_ctx.strokeStyle = linecolor;
        arrow_ctx.stroke();
        arrow_ctx.closePath();
        arrow_ctx.restore();
    }
}
function animateCircles(data) {
    var ncleft = data[0];
    var nctop = data[1];
    var len = data[2];
    var allchilds = data[3];
    var nooverlap = data[5];
    for (var i = 0; i < len; i++) {
        var pos = allchilds[i];
        anim_layer[i] = document.createElement("canvas");
        settingsApplyforAnim(anim_layer[i], dcindex, pos);//applying settings for canvas element
        anim_ctx[i] = $$(main_storage[pos][1]).getContext("2d");
        settingContext(anim_ctx[i], small_radius, (anim_layer[i].width / 2), (anim_layer[i].height - anim_layer[i].height / 8), getText(main_storage[pos][0]), bcolor);
        $$(main_storage[pos][1]).style.position = "absolute";
        var angle = Math.atan2(nooverlap[i][1] - nctop, nooverlap[i][0] - ncleft);
        var cnleft = Math.round(ncleft + data[4] * Math.cos(angle));
        var cntop = Math.round(nctop + data[4] * Math.sin(angle));
        $$(main_storage[pos][1]).style.left = (cnleft - (big_radius + small_radius / 2)) + "px";
        $$(main_storage[pos][1]).style.top = (cntop - (big_radius + small_radius / 2)) + "px";
    }
    data[4] += 8;
    for (var i = 0; i < len; i++) {
        anim_layer[i].width = anim_layer[i].width;
    }
    if (data[4] > nooverlap[0][2]) {
        clearInterval(anim_load);

        window.setTimeout(drawing_circles, 10, [ncleft, nctop, len, allchilds, nooverlap]);
        for (var i = 0; i < len; i++) {
            anim_ctx[i].clearRect(0, 0, anim_layer[i].width, anim_layer[i].height);
        }
        click_anim = 0;
    }
}
function wrapText(context, text, x, y, maxWidth, lineHeight) {
    text = text.replace(/-/g, '- ');
    var words = text.split(' ');
    var line = "";
    context.fillStyle = "black";
    context.textAlign = "center";


    for (var n = 0; words.length > 1 && n < words.length; n++) {
        var testLine = line + words[n] + " ";
        var metrics = context.measureText(testLine);
        var testWidth = metrics.width;
        if (testWidth > maxWidth) {
            context.fillText(line, x, y);
            line = words[n] + " ";
            y += lineHeight;
        }
        else {
            line = testLine;
        }
    }
    if (words.length == 1) {
        if (text.length > 15) {
            try {
                line = text.substr(0, 15);
                context.fillText(line, x, y);
                y += lineHeight;
                line = text.substr(15, text.length);
                context.fillText("-" + line, x, y);
                /*for(i=0;i<text.length-15;){
                 line = text.substr(i,i+15);
                 context.fillText(line, x, y);
                 y += lineHeight;
                 i = i+15;
                 }*/
            } catch (er) {

            }
        }
        else
            context.fillText(text, x, y);

    }
    else
        context.fillText(line, x, y);
    context.fill();
}
function canvas_arrow(context, fromx, fromy, tox, toy) {
    var headlen = 15;   // length of head in pixels
    var angle = Math.atan2(toy - fromy, tox - fromx);
    context.moveTo(fromx, fromy);
    context.lineTo(tox, toy);
    context.moveTo(tox, toy);
    context.lineTo(tox - headlen * Math.cos(angle - Math.PI / 6), toy - headlen * Math.sin(angle - Math.PI / 6));
    context.moveTo(tox, toy);
    context.lineTo(tox - headlen * Math.cos(angle + Math.PI / 6), toy - headlen * Math.sin(angle + Math.PI / 6));
}