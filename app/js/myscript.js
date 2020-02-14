"use strict";
var nodeCount = 0, big_radiusC = 50, small_radiusC = 16;
var selectedNode = 0;
var linesArray = new Array();
var iL = 0, jL = 0;

function get(id, att) {
    return document.getElementById("node" + id).getAttribute(att);
}

function set(id, att, value) {
    document.getElementById("node" + id).setAttribute(att, value);
}

function getDistance(pX, pY, jX, jY) {
    return Math.round(Math.sqrt(Math.pow(jX - pX, 2) + Math.pow(jY - pY, 2)));
}

function toRadians(angle) {
    return angle * (Math.PI / 180);
}

function saveDetails() {
    /*console.log(tinyMCE.activeEditor.getContent());
     var contentDetails = document.getElementById("contentDetails");*/
    set(selectedNode, "details", tinyMCE.activeEditor.getContent());
}

function updateQuizDetails(quizId, quizName) {
    set(selectedNode, "quizId", quizId);
    set(selectedNode, "quizName", quizName);
}

function getNode() {
    nodeCount++
    var element = document.createElement("canvas");
    element.setAttribute("height", 100);
    element.setAttribute("width", 100);
    element.setAttribute("id", "node" + nodeCount);
    element.setAttribute("nodeNumber", nodeCount);
    element.setAttribute("childCount", 0);
    element.setAttribute("diagonalC", 150);
    element.setAttribute("name", 0);
    return element;
}

function addNode() {
    var element = getNode();
    element.setAttribute("name", selectedNode);
    $("#graph").append(element);
    var cnt = Number(get(selectedNode, "childcount"));
    set(selectedNode, "childcount", cnt + 1);

    redrawNodes(selectedNode);
    iL = 0;
    clearGraphLines();
    drawAllLines(1);
    drawNodeBetLines();
    $("#graphLine").css({"z-index":10});
    animateToSmallCircle(selectedNode);
    drawSelectedNode(nodeCount);
    var top = get(nodeCount, "y");
    var left = get(nodeCount, "x");
    window.scroll((left - (window.innerWidth / 3) + (big_radiusC * 2)), (top - (window.innerHeight / 3)));
    addTextBox(nodeCount);
    var contentDetails = document.getElementById("tinymce");
    //contentDetails.innerHtml = "";
    tinyMCE.editors[0].setContent('')
    var concept_name = document.getElementById("concept_name");
    concept_name.value = "";
    document.getElementById("quizName").innerText = "";
    document.getElementById("quizId").setAttribute("value", "");
    document.getElementById("addQuiz").hidden = false;
    document.getElementById("deleteQuiz").hidden = true;

}
function editConceptName(e) {
    if (e.keyCode == 13) {
        var value = document.getElementById("concept_name").value;
        set(selectedNode, "text", value);
        document.getElementById("nodeLabel" + selectedNode).innerHTML = truncate(value);
    }

}

function getNodeId(str) {
    var n = str.split("node");
    return n[1];
}
function redrawNodes(id) {

    var cnt = Number(get(id, "childcount"));
    var diagonalC = Number(get(id, "diagonalC"));
    var startAngle = 0;
    var pY = Number(get(id, "y"));
    var pX = Number(get(id, "x"));
    var totalNodes = Number(cnt) + 1;
    var parentId = get(id, "name");
    var parentAngle;
    if (parentId != 0) {
        parentAngle = get(parentId, "sourceAngle");
        var currentAngle = Number(get(id, "angle"));
        if (currentAngle == 0) {
            currentAngle = 360;
        }
        startAngle = Math.abs(currentAngle - Math.round(parentAngle / 2));
    }
    else {
        parentAngle = 360;
        startAngle = 0;
    }
    var angle = parentAngle / totalNodes;
    set(id, "sourceAngle", angle);
    var nodes = new Array();
    nodes = document.getElementsByName(id);
    var incremented = false;
    for (var i = 0; i < cnt; i++) {
        var nodeId = nodes[i].getAttribute("id");
        var iRadian = toRadians(angle * i + startAngle);
        var iX = Math.abs(Math.round(diagonalC * Math.sin(iRadian) + pX));
        var iY = Math.abs(Math.round(diagonalC * Math.cos(iRadian) + pY));
        for (var j = 0; j < i; j++) {
            var jId = getNodeId(nodes[j].getAttribute("id"));
            var jY = Number(get(jId, "y"));
            var jX = Number(get(jId, "x"));
            if (!incremented) {
                var distance = getDistance(iX, iY, jX, jY);
                var constDistance = big_radiusC * 2 + small_radiusC;
                while (constDistance > distance) {
                    incremented = true;
                    diagonalC = diagonalC + big_radiusC;
                    iX = Math.abs(Math.round(diagonalC * Math.sin(iRadian) + pX));
                    iY = Math.abs(Math.round(diagonalC * Math.cos(iRadian) + pY));
                    set(id, "diagonalC", diagonalC);
                    distance = getDistance(iX, iY, jX, jY);
                }
            }
        }
        $("#" + nodeId).css({position:"absolute", top:iY, left:iX, "z-index":nodeCount + 10 });
        $("#nodeLabel" + getNodeId(nodeId)).css({position:"absolute", top:iY + big_radiusC - 20, left:iX + big_radiusC - 20, "z-index":nodeCount + 10 });

        nodes[i].setAttribute("x", iX);
        nodes[i].setAttribute("y", iY);
        nodes[i].setAttribute("angle", angle * i);
        if (nodes[i].getAttribute("childcount") > 0) {
            redrawNodes(getNodeId(nodes[i].getAttribute("id")));
        }
    }

    if (incremented) {
        var i = 0;
        var nodeId = nodes[i].getAttribute("id");
        var iRadian = toRadians(angle * i + startAngle);
        var iX = Math.round(diagonalC * Math.sin(iRadian) + pX);
        var iY = Math.round(diagonalC * Math.cos(iRadian) + pY);
        $("#" + nodeId).css({position:"absolute", top:iY, left:iX, "z-index":nodeCount + 10 });
        $("#nodeLabel" + getNodeId(nodeId)).css({position:"absolute", top:iY + big_radiusC - 20, left:iX + big_radiusC - 20, "z-index":nodeCount + 10 });
        nodes[i].setAttribute("x", iX);
        nodes[i].setAttribute("y", iY);
        nodes[i].setAttribute("angle", angle * 0);
    }

    var top = get(selectedNode, "y");
    var left = get(selectedNode, "x");
    window.scroll((left - (window.innerWidth / 3) + (big_radiusC * 2)), (top - (window.innerHeight / 3)));

}

function animateToBigCircle(id) {
    $("#node" + id).animateLayer("nodeLayer" + id, {
        x:big_radiusC, y:big_radiusC,
        strokeStyle:"#47e",
        fillStyle:"#47c",
        strokeWidth:7,
        radius:big_radiusC - 5
    }, 1);
    var top = get(id, "y");
    var left = get(id, "x");

    window.scroll((left - (window.innerWidth / 3) + (big_radiusC * 2)), (top - (window.innerHeight / 3)));
    var iY = Number(get(id, "y"));
    var iX = Number(get(id, "x"));
    $("#nodeLabel" + id).css({position:"absolute", top:iY + big_radiusC - 20, left:iX + big_radiusC - 20, "z-index":nodeCount + 10 });
}

function animateToSmallCircle(id) {
    $("#node" + id).animateLayer("nodeLayer" + id, {
        strokeStyle:"#B4B4B4",
        fillStyle:"#B4B4B4",
        strokeWidth:1,
        position:'absolute',
        x:big_radiusC, y:big_radiusC,
        radius:small_radiusC
    }, 1);
    var iY = Number(get(id, "y"));
    var iX = Number(get(id, "x"));
    $("#nodeLabel" + id).css({position:"absolute", top:iY + big_radiusC + small_radiusC + 5, left:iX + big_radiusC + small_radiusC + 5, "z-index":nodeCount + 10 });
}

function clearGraphLines() {
    if (document.getElementById("graphLines")) {
        var childNode = document.getElementById("graphLines");
        childNode.parentNode.removeChild(childNode);
        var element = document.createElement("canvas");
        element.setAttribute("height", $("#graph").height());
        element.setAttribute("width", $("#graph").width());
        element.setAttribute("id", "graphLines");
        $("#graph").append(element);
    }
}

function drawAllLines(id) {
    var pId = Number(get(id, "name"));
    if (pId != 0) {
        linesArray[iL] = new Array();
        linesArray[iL][0] = id;
        linesArray[iL][1] = pId;
        iL++;

        //drawNodeBetLine(id, pId);
    }
    var childCnt = Number(get(id, "childCount"));
    if (childCnt == 0) {
        if (pId != 0) {
            linesArray[iL] = new Array();
            linesArray[iL][0] = id;
            linesArray[iL][1] = pId;
            iL++;
            //drawNodeBetLine(id, pId);
        }
    }
    else {
        var nodes = new Array();
        nodes = document.getElementsByName(id);
        for (var i = 0; i < nodes.length; i++) {
            drawAllLines(getNodeId(nodes[i].getAttribute("id")));
        }
    }
}


function clickEvent(id) {
    if (selectedNode != id) {
        animateToSmallCircle(selectedNode)
        selectedNode = id;
        animateToBigCircle(id);
        /*var contentDetails = document.getElementById("contentDetails");
         contentDetails.value = get(selectedNode, "details");*/
        var concept_name = document.getElementById("concept_name");
        concept_name.value = get(id, "text");
        if (get(selectedNode, "details") != null) {
            tinyMCE.editors[0].setContent(get(selectedNode, "details"));
        }
        else {
            tinyMCE.editors[0].setContent("");
        }
        if (get(selectedNode, "quizId") != null) {
            document.getElementById("quizName").innerText = "Quiz :" + get(selectedNode, "quizName");
            document.getElementById("quizId").setAttribute("value", get(selectedNode, "quizId"));
            document.getElementById("addQuiz").hidden = true;
            document.getElementById("deleteQuiz").hidden = false
        }
        else {
            document.getElementById("quizName").innerText = "";
            document.getElementById("quizId").setAttribute("value", "");
            document.getElementById("addQuiz").hidden = false;
            document.getElementById("deleteQuiz").hidden = true;
        }
    }
}

function addTextBox(id) {

    var pos = $("#node" + id).position();
    if (document.getElementById("nodeTextBox" + id) == null) {
        var textBox = document.createElement("input");
        textBox.setAttribute("type", "text");
        textBox.setAttribute("id", "nodeTextBox" + id);
        textBox.setAttribute("name", "nodeTextBox" + id);
        $("#graph").append(textBox);
        textBox.focus();
    }
    $("#nodeTextBox" + id).css({position:"absolute", top:pos.top + big_radiusC, left:pos.left, "z-index":nodeCount + 10 });
    $("#nodeTextBox" + id).bind("enterKey", function (e) {
        var text = get(id, "text");
        set(id, "text", e.target.value);
        animateToBigCircle(id);
        selectedNode = id;
        var nodeLabel;
        if (document.getElementById("nodeLabel" + id) == null) {
            nodeLabel = document.createElement("label");
            $("#graph").append(nodeLabel);
        }
        else {
            nodeLabel = document.getElementById("nodeLabel" + id);
        }
        nodeLabel.setAttribute("id", "nodeLabel" + id);
        nodeLabel.setAttribute("name", "nodeLabel" + id);
        nodeLabel.setAttribute("ondblclick", "showTextBox(" + id + ")");

        var concept_name = document.getElementById("concept_name");

        nodeLabel.innerHTML = truncate(e.target.value);
        concept_name.value = e.target.value;

        $("#nodeLabel" + id).css({position:"absolute", top:pos.top + big_radiusC - 20, left:pos.left + big_radiusC - 20, "z-index":nodeCount + 10 });
    });
    $("#nodeTextBox" + id).keyup(function (e) {
        if (e.keyCode == 13) {
            $(this).trigger("enterKey");
            $(this).hide();
        }
    });

    $("#nodeTextBox" + id).blur(function (e) {
        $(this).trigger("enterKey");
        $(this).hide();
    });
    var top = pos.top + big_radiusC;
    var left = pos.left;
    window.scroll((left - (window.innerWidth / 3) + (big_radiusC * 2)), (top - (window.innerHeight / 3)));
    $("#nodeTextBox" + id).show();
}

function showTextBox(id) {
    $("#nodeTextBox" + id).bind("enterKeyOnEdit", function (e) {
        writeText(id, e.target.value);
    });
    $("#nodeTextBox" + id).keyup(function (e) {
        if (e.keyCode == 13) {
            $(this).trigger("enterKeyOnEdit");
            $(this).hide();
        }
    });
    $("#nodeTextBox" + id).show();
}
function truncate(str) {
    var trunc = str;
    var len = 5
    if (trunc.length > len) {
        trunc = trunc.substring(0, len);
        trunc += '...';
    }
    return trunc
}
function writeText(id, text) {
    var text = get(id, "text");
    set(id, "text", text);
    var nodeLabel = document.getElementById("nodeLabel" + id);

    nodeLabel.innerHTML = truncate(text);
}

function drawSelectedNode(id) {
    //selectedNode=id;
    $("#node" + id).drawArc({
        layer:true,
        name:"nodeLayer" + id,
        strokeStyle:"#47e",
        fillStyle:"#47c",
        strokeWidth:7,
        position:'absolute',
        x:big_radiusC, y:big_radiusC,
        radius:big_radiusC - 5,
        dblclick:function (layer) {
            showTextBox(id);
        },
        click:function (layer) {
            clickEvent(id);
        }
    });

}

function drawNodeBetLine(id, pId) {
    var constant = big_radiusC;/// 2 + small_radiusC;
    var cY = Number(get(id, "y"))+ constant;
    var cX = Number(get(id, "x"))+ constant;
    var pY = Number(get(pId, "y"))+ constant;
    var pX = Number(get(pId, "x"))+ constant;
    var graphsLineCtx = document.getElementById("graphLines").getContext("2d");
    var halfX=Math.round((cX+pX)/2);
    var halfY=Math.round((cY+pY)/2);
    graphsLineCtx.save();
    graphsLineCtx.beginPath();

    canvas_arrow(graphsLineCtx,pX, pY, halfX, halfY);
    graphsLineCtx.moveTo(halfX, halfY);
    graphsLineCtx.lineTo(cX, cY);
    graphsLineCtx.strokeStyle = linecolor;
    graphsLineCtx.stroke();
    graphsLineCtx.closePath();
    graphsLineCtx.restore();
    /*
     var constant = big_radiusC;/// 2 + small_radiusC;
     var cY = Number(get(id, "y"))+ constant;
     var cX = Number(get(id, "x"))+ constant;
     var pY = Number(get(pId, "y"))+ constant;
     var pX = Number(get(pId, "x"))+ constant;
     var graphsLineCtx = document.getElementById("graphLines").getContext("2d");
     canvas_arrow(graphsLineCtx, pX, pY, cX, cY);
     $("#graphLines").drawLine({
     strokeStyle:"#47c",
     strokeWidth:1,
     visible:true,
     x1:pX , y1:pY,
     x2:cX, y2:cY
     });*/


}

function drawNodeBetLines() {

    var constant = big_radiusC;
    for (var i = 0; i < linesArray.length; i++) {
        var id = linesArray[i][0];
        var pId = linesArray[i][1];
        drawNodeBetLine(id, pId);

    }
}
