// JavaScript Document
function startCreating() {
    if (document.getElementById("graph") != null) {
        $("#map").css({"z-index":0});
        $("#map .canvas_map ").css({"text-align":"center", position:"relative", "z-index":0});


        var ele = document.getElementById("graphLines");
        document.getElementById("contentDetails").addEventListener("blur", saveDetails, true);
        document.getElementById("concept_name").addEventListener("keyup", editConceptName, true);
        document.getElementById("Czoomerplus").addEventListener("click", zplusC, true);
        document.getElementById("Czoomerminus").addEventListener("click", zminusC, true);
        document.getElementById("Cnormal_view").addEventListener("click", reset_viewC, true);
        var graphArea = $("#graph");

        var top = Math.floor(graphArea.height() / 2) - big_radiusC;
        var left = Math.floor(graphArea.width() / 2);

        if (document.getElementById(selectedNode) == null) {
            var ele = getNode();
            $("#graph").append(ele);
            $("#node" + nodeCount).css({position:"absolute", top:top, left:left, "z-index":nodeCount });
            document.getElementById("node" + nodeCount).setAttribute("x", left);
            document.getElementById("node" + nodeCount).setAttribute("y", top);
            drawSelectedNode(nodeCount);
            window.scroll((left - (window.innerWidth / 3) + (big_radiusC * 2)), (top - (window.innerHeight / 3)));
            selectedNode = nodeCount;
            addTextBox(nodeCount);
        }
    }
}

function submit1() {
    iCnt = 0;
    if (document.getElementById("map") != null) {
        var childNode = document.getElementById("map");
        childNode.parentNode.removeChild(childNode);
        var element = document.createElement("div");
        element.setAttribute("id", "map");
        element.setAttribute("height", $("#graph").height());
        element.setAttribute("width", $("#graph").width());
        $("#preview").children()[0].appendChild(element);

    }
    createJSon();
    create_Init_Element();
    $("#map").css({"z-index":nodeCount});
    $("#map .canvas_map ").css({"text-align":"center", position:"relative", "z-index":nodeCount + 10});
    var lineLayer = document.getElementsByClassName("map_2nd_layer")[0];
    $("#arrow").css({position:"absolute", top:"0", left:"0"});
    lineLayer.setAttribute("height", $$("map").getAttribute("height"));
    lineLayer.setAttribute("width", $$("map").getAttribute("width"));
}

function submitForm() {
    document.getElementById("new_concept").submit();
}