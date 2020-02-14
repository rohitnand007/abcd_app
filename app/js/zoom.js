// JavaScript Document

var styles, zoom = 1,  zoomclickC = 0;
var zoom_animC, zoom_loadC, click = 0;
var el_positionC = new Array();
function zplusC() {
    if (zoom <= 5 && zoomclickC == 0) {
        var brk = 0.1 / 10;
        var store = zoom;
        zoomclickC = 1;
        zoom_loadC = window.setInterval(zoom_animC, 35, [zoom, brk, store, 0]);
        zoom = zoom + 0.1;
        return false;
    }
}
function zoom_animCC(data) {
    document.getElementById("graph").style.MozTransform = "scale(" + data[0] + ")";
    document.getElementById("graph").style.WebkitTransform = "scale(" + data[0] + ")";
    document.getElementById("graph").style.Transform = "scale(" + data[0] + ")";
    if (el_positionC) {
        document.getElementById("graph").style.MozTransformOrigin = "" + el_positionC[0] + " " + el_positionC[1] + "";
        document.getElementById("graph").style.TransformOrigin = "" + el_positionC[0] + " " + el_positionC[1] + "";
    }
    if (data[3] == 0) {
        data[0] = data[0] + data[1];
        if (data[2] + 0.1 <= data[0]) {
            clearInterval(zoom_loadC);
            zoomclickC = 0;
        }
    }
    else {
        data[0] = data[0] - data[1];
        if (data[2] - 0.1 >= data[0]) {
            clearInterval(zoom_loadC);
            zoomclickC = 0;
        }
    }
}
function zminusC() {
    if (zoom >= 0.1 && zoomclickC == 0) {
        var brk = 0.1 / 10;
        var store = zoom;
        zoomclickC = 1;
        zoom_loadC = window.setInterval(zoom_animC, 35, [zoom, brk, store, 1]);
        zoom = zoom - 0.1;
        return false;
    }
}
function reset_viewC() {
    document.getElementById("#graph").style.MozTransform = "scale(1)";
    document.getElementById("#graph").style.WebkitTransform = "scale(1)";
    document.getElementById("#graph").style.Transform = "scale(1)";
    document.getElementById("graph").style.MozTransformOrigin = "" + el_positionC[0] + " " + el_positionC[1] + "";
    document.getElementById("graph").style.TransformOrigin = "" + el_positionC[0] + " " + el_positionC[1] + "";
    window.scroll(default_pos[0], default_pos[1]);
    zoom = 1;
    return false;
}

