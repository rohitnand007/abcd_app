// JavaScript Document

function jSonCreation(id, jsonData) {
    jsonData.child = [];
    var nodes = new Array();
    nodes = document.getElementsByName(id);
    for (var i = 0; i < nodes.length; i++) {
        var childCount = Number(nodes[i].getAttribute("childCount"));
        jsonData.child[i] = { id:"" + getNodeId(nodes[i].getAttribute("id")), parentId:"" + id, name:nodes[i].getAttribute("text"), details:nodes[i].getAttribute("details"),quizId:nodes[i].getAttribute("quizId") };
        if (childCount > 0) {
            jSonCreation(getNodeId(nodes[i].getAttribute("id")), jsonData.child[i]);
        }
    }
}

function createJSon() {
    var jsonData1 = {
        "id":"1",
        "name":get(1,"text"),
        "details":get(1,"details"),
        "parentId":"1" ,
        "quizId":get(1,"quizId")
    };
    jSonCreation(1, jsonData1);
    var sResults = JSON.stringify(jsonData1, null, 2);
    var jsonObj=JSON.parse(sResults);
    loadJson(jsonObj);
    console.log(jsonObj);
    document.getElementById("concept_concept").setAttribute("value",sResults);
}
