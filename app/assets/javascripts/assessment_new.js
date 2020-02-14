var alpha = ["A","B","C","D","E","F","G","H","I"];
var node = document.getElementById("a_question_body");
window.onload = initialize;
var num = 0;
var current_time = 0;
var data;
var scrl;
var quiz_started = false;
var reviewing_test = false;
var flagged_mode = false;
var quiz_submitted = false;
var appTime;
window.onbeforeunload = function() {
    if(appTime.getTime()>0)
        submitQuiz();
}
function createQues(data){
    hell = data;
    var div1 = document.createElement("div");
    div1.setAttribute("num1", data.num1);//section number
    div1.setAttribute("num2", data.num2);//question number
    if (data.num3) {
        div1.setAttribute("num3", data.num3);
    }
    var div2 = document.createElement("div");
    div2.className = "a_question_body1";
    div1.appendChild(div2);
    var node = document.createDocumentFragment();
    node.appendChild(quesBox());
    node.firstElementChild.appendChild(quesMetaNode());
    questionMeta(node.firstElementChild,data);
    node.childNodes[1].appendChild(quesTextNode(data));
    switch(data.qtype){
        case "multichoice":
            for (var i = 0; i < data.options.length; i++){
                node.lastElementChild.lastChild.setAttribute("data-answer", data.ans);
                node.lastElementChild.lastChild.appendChild(quesOptionsNode(data, i));
            }
            break;
        case "truefalse":
            for (var i = 0; i < 2; i++){
                node.lastElementChild.lastChild.appendChild(quesOptionsTFNode(data, i));
            }
            break;
        case "fib":
            var blanks = data.qtext.match(/#DASH#/g);
            var total_number_of_blanks;
            if(blanks)
                total_number_of_blanks = blanks.length;
            else
                total_number_of_blanks = 1;
            for (var i = 0; i < total_number_of_blanks; i++) {
                node.lastElementChild.lastChild.appendChild(quesFIBOpNode(data, i));
            }
            break;
        case "vsaq":
        case "saq":
        case "laq":
        case "project":
        default:
            node.lastElementChild.lastChild.appendChild(textOptionNode(data));
            break;
        case "passage":
            div1.appendChild(passageQuesNode(data));
            var sel1 = document.querySelector(".a_meta_sec_select select");
            var q_num1 = sel1.value * 1;
            var srl1 = new Scroller(application.getQueFlagData(q_num1, num));
            var div_s = srl1.getDisplayNode();
            div_s.firstChild.className = "passage_scroll";
            div1.appendChild(div_s);
            var rd = srl1.getRad();
            rd.onclick = function(){srl1.scRight()};
            var ld = srl1.getLad();
            ld.onclick = function(){srl1.scLeft()};
            var div_c1 = srl1.getDiv();
//            var num1 = 0
            for(var i = 0; i < div_c1.length; i++){
                div_c1[i].onclick = function(event){
                    srl1.currentBtn();
                    var qId = event.target.getAttribute("data-link_id");
                    var val = event.target.getAttribute("value");
                    var node1 = event.target.parentNode.parentNode.previousSibling;
                    if(event.target.innerHTML.trim() != "."){
                        node1.replaceChild(createQues(application.getQuestion(q_num1, num, val)), node1.firstElementChild);
//                        num1 = val;
                        event.target.style.outline = "#ccc solid 2px";
                    }
                }
            }
            break;
    }
    if(!reviewing_test){
        if (data.question) {
            if (document.getElementById("pques")) {
                document.getElementById("pques").parentNode.removeChild(document.getElementById("pques"));
            }
            var ele = document.getElementById("a_question_body");
            var pques = document.createElement("div");
            pques.id = "pques";
            pques.appendChild(quesTextNode(data.question));
            div1.insertBefore(pques, div2);
        }
        else if (document.getElementById("pques")) {
            document.getElementById("pques").parentNode.removeChild(document.getElementById("pques"));
        }
        node.appendChild(quesFlag());
        div2.appendChild(node);
    }else{
        //If Section has passage questions
        div2.appendChild(node);
        if(application.getPassageQuestionIDs(data.num1).length>0){
            if(data.question){
                //If present question is a passage question
                if(document.querySelector("#pques"+data.question.id)){
                    //If Present Passage is already Added
                }else{
                    //If Present Passage is not added
                    var new_passage_div = document.createElement("div");
                    new_passage_div.id = "pques" + data.question.id;
                    new_passage_div.className = "pques_review";
                    new_passage_div.appendChild(quesTextNode(data.question));
                    //var child_question = document.getElementById("a_question_body").lastElementChild.lastElementChild;
                    //child_question.parentNode.insertBefore(new_passage_div, child_question);
                    div1.insertBefore(new_passage_div, div2);
                }
            }else{
                //Do nothing
            }
        }else{
            //If Section does not have passage questions
            //while(document.querySelector())
        }
        //div2.appendChild(node);
    }
    return div1;
}

function quesBox(){
    var div = document.createDocumentFragment();
    var mQues = document.createElement("div");
    mQues.className = "a_meta_question";
    var qBox = document.createElement("div");
    qBox.className = "a_question_box";
    div.appendChild(mQues);
    div.appendChild(qBox);
    return div;
}

function quesMetaNode(){
    //Creates structure for questions meta data
    var div = document.createDocumentFragment();
    var queNo = document.createElement("div");
    queNo.className = "a_meta_ques_no";
    var queNoS = document.createElement("span");
    queNo.appendChild(queNoS);
    var queType = document.createElement("div");
    queType.className = "a_meta_ques_type";
    var queTypeS = document.createElement("span");
    queType.appendChild(queTypeS);
    var queM = document.createElement("div");
    queM.className = "a_dyn_ques_marks";
    var queMS = document.createElement("span");
    queM.appendChild(queMS);
    var queN = document.createElement("div");
    queN.className = "a_meta_ques_neg";
    var queNS = document.createElement("span");
    queN.appendChild(queNS);
    div.appendChild(queNo);
    div.appendChild(queType);
    div.appendChild(queM);
    div.appendChild(queN);
    return div;
}

function questionMeta(node, data){
    //sets the questions meta data
    //node is the questions meta division
    node.childNodes[0].firstChild.innerHTML = "Question no: " + data.q_no;
    var qtype = node.childNodes[1].firstChild;
    switch (data.qtype){
        case "multichoice" :
            qtype.innerHTML = "Question Type:" + "Multiple Choice Question";
            break;
        case "fib" :
            qtype.innerHTML = "Question Type:" + "Fill in the Blanks";
            break;
        case "truefalse" :
            qtype.innerHTML = "Question Type:" + "True or False Question";
            break;
        case "saq":
            qtype.innerHTML = "Question Type:" + "Short Answer Question";
            break;
        case "vsaq":
            qtype.innerHTML = "Question Type:" + "Very Short Answer Question";
            break;
        case "laq" :
            qtype.innerHTML = "Question Type:" + "Long Answer Question";
            break;
        case "passage" :
            qtype.innerHTML = "Question Type:" + "Passage/Group Questions";
            break;
        case "project" :
            qtype.innerHTML = "Question Type:" + "Project Question";
            break;
        default:
            qtype.innerHTML = "Question Type:" + "Multiple Choice Question";
    }
    node.childNodes[2].firstChild.innerHTML = "Marks: " + data.marks;
    node.childNodes[3].firstChild.innerHTML = "Negative Marks: " + data.n_marks;
}

function quesTextNode(data){
    var div = document.createDocumentFragment();
    var qData = document.createElement("div");
    qData.className = "a_data_question";
    var qDP = document.createElement("p");
    qData.appendChild(qDP);
    var qDPT = document.createElement("div");
    var qText = data.qtext.replace(/#DASH#/g, "____________________");
    // qText = qText.replace(/src="/g,'src="\/question_images\/');
    qDPT.innerHTML = decodeHtml(qText);
    qDP.appendChild(qDPT);
    var qDOps = document.createElement("div");
    qDOps.className =  "a_data_options";
    div.appendChild(qData);
    div.appendChild(qDOps);
    return div;
}

function quesOptionsNode(data, i){
    var opData = document.createElement("div");
    opData.className = "a_data_option";
    var opDS = document.createElement("span");
    opDS.appendChild(document.createTextNode(alpha[i]));
    opData.appendChild(opDS);
    var opDV = document.createElement("div");
    opDV.className = "a_data_option_value";
    var option_text = data.options[i].answer;
    // option_text = option_text.replace(/src="/g,'src="\/question_images\/');
    var opDVT = document.createElement("div")
    opDVT.innerHTML = decodeHtml(option_text);
    opDV.appendChild(opDVT);
    opData.appendChild(opDV) ;
    var opR = document.createElement("input");
    opData.setAttribute("data-opt_value", data.stat_options[i].opt);
    opData.setAttribute("data-opt_index", i);
    opR.type = "checkbox";
    //If question is single answer multiple choice question give same name attrribute to all radio buttons
    if (!data.qmulti) {
        opR.type = "radio";
        opR.name = "Question No: "+data.num2+" Single Answer Question";
    }
    opR.checked = data.stat_options[i].opt;
    opR.setAttribute("data-checked_status", opR.checked==true ? true : false);
    opData.onclick = function (event) {
        ansAction(event)
    };
    opData.appendChild(opR);
    return opData;
}
function quesOptionsTFNode(data, i){
    var opData = document.createElement("div");
    opData.className = "a_data_option";
    var opDS = document.createElement("span");
    opDS.appendChild(document.createTextNode(alpha[i]));
    opData.appendChild(opDS);
    var opDV = document.createElement("div");
    opDV.className = "a_data_option_value";
    var opDVT = document.createElement("div");
    if(i == 0){
        opDVT.innerHTML = "True";
    }else{
        opDVT.innerHTML = "False";
    }
    opDV.appendChild(opDVT);
    opData.appendChild(opDV) ;
    var opR = document.createElement("input");
    opData.setAttribute("data-opt_value", data.stat_options[i].opt);
    opData.setAttribute("data-opt_index", i);
    opR.type = "radio";
    opR.name = "Question No: "+data.num2+" Single Answer Question";
    opR.checked = data.stat_options[i].opt;
    opR.setAttribute("data-checked_status", opR.checked==true ? true : false);
    opData.onclick = function (event) {
        ansAction(event)
    };
    opData.appendChild(opR);
    return opData;
}
function quesFIBOpNode(data, i){
    var opData = document.createElement("div");
    opData.className = "a_data_option";
    var opDS = document.createElement("span");
    opDS.appendChild(document.createTextNode(alpha[i]));
    opData.appendChild(opDS);
    var opDV = document.createElement("div");
    opDV.className = "a_data_option_blank_value";
    var opDVT = document.createElement("input");
    opDVT.type = "text";
    opDVT.setAttribute("placeholder", "Type Your Answer...");
    if (data.stat_options[i]) {
        opDVT.setAttribute("data-opt_value", data.stat_options[i]);
        opDVT.value = data.stat_options[i];
    }
    opDV.appendChild(opDVT);
    opDVT.onblur = function (event) {
        fibAnsAction(event)
    };
    opData.appendChild(opDV);
    return opData;
}
function textOptionNode(data){
    var opData = document.createElement("div");
    opData.className = "a_data_option";
    var opDV = document.createElement("div");
    opDV.className = "a_data_option_value";
    var opDVT = document.createElement("textarea");
    opDVT.rows = "5";
    opDVT.cols = "100";
    // opDVT.placeholder = "Type Your Answer...";
    opDVT.setAttribute("placeholder", "Type Your Answer...");
    if (data.stat_options) {
        opDVT.setAttribute("data-opt_value", data.stat_options[0]);
        opDVT.value = typeof(data.stat_options[0]) == 'undefined' ? '' : data.stat_options[0];
    }
    opDV.appendChild(opDVT);
    opDVT.onblur = function (event) {
        descAnsAction(event)
    };
    opData.appendChild(opDV);
    return opData;
}
function quesFlag(){
    var fBtn = document.createElement("button");
    fBtn.innerHTML = "flag";
    fBtn.setAttribute("data-state", 'Unflagged');
    fBtn.setAttribute("class", "flagButton");
    // fBtn.addEventListener('click', flagClicked);
    fBtn.onclick = flagClicked;
    return fBtn;
}

function passageQuesNode(data){
    return arguments.callee.caller(application.getQuestion(data.questions[0], data.questions[1],0));
}

function ansAction(event){
    var radio = event.currentTarget.querySelector("input[type='radio'], input[type='checkbox']");
    if (radio.getAttribute("data-checked_status")=='true') {
        radio.checked = false;
        radio.setAttribute("data-checked_status", 'false');
    } else {
        radio.checked = true;
        radio.setAttribute("data-checked_status", 'true');
    }
    //If the question is a single answer question update all other options data-checked_status attribute
    if(radio.getAttribute('name')=='Single Answer Question'){
        var options_div = radio.parentNode.parentNode;
        var radio_buttons = options_div.querySelectorAll("input[type='radio']");
        for(var index=0; index < radio_buttons.length; index++){
            if(radio_buttons[index]!= radio){
                radio_buttons[index].setAttribute("data-checked_status", 'false');
            }
        }
    }
    var sel = document.querySelector(".a_meta_sec_select select");
    var q_num = sel.value * 1;
    var ans_opt = event.currentTarget.getAttribute("data-opt_index");
    application.postToWrap(q_num, num , ans_opt);
    updateMetaData();
}

function fibAnsAction(event) {
    event.target.setAttribute("data-opt_value", (event.target.value));
    var a = new Array();
    for (var i = 0, len = document.querySelectorAll(".a_data_options input[type='text']").length; i < len; i++) {
        a.push(document.querySelectorAll(".a_data_options input[type='text']")[i].value);
    }
    var ele = document.getElementById("a_question_body").firstElementChild;
    var num1 = ele.getAttribute("num1") * 1;
    var num2 = ele.getAttribute("num2") * 1;
    application.postFibToWrap(num1, num2, a);
    updateMetaData();
}

function descAnsAction(event) {
    event.target.setAttribute("data-opt_value", (event.target.value));
    var a = new Array();
    for (var i = 0, len = document.querySelectorAll(".a_data_options textarea").length; i < len; i++) {
        a.push(document.querySelectorAll(".a_data_options textarea")[i].value);
    }
    var ele = document.getElementById("a_question_body").firstElementChild;
    var num1 = ele.getAttribute("num1") * 1;
    var num2 = ele.getAttribute("num2") * 1;
    application.postFibToWrap(num1, num2, a);
    updateMetaData();
}

function saveQuestionTime() {
    var ele = document.getElementById("a_question_body").firstElementChild;
    var num1 = ele.getAttribute("num1") * 1;
    var num2 = ele.getAttribute("num2") * 1;
    var time = appTime.getTime() - current_time;
    application.setQuesTimeSpent(num1, num2, time);
}

function updateMetaData() {
    var sec = document.querySelector(".a_meta_sec_select select");
    var section_number = sec.value * 1;
    //Update Scroller
    updateQuestionFlagDataWhenAnswered();
    var totSecAtmpQue = document.querySelector(".a_dyn_sec_attempt span:first-of-type");
    totSecAtmpQue.innerHTML = application.getSecTotAtmpQue(section_number);
    var totAtmpQue = document.querySelector(".a_dyn_test_attempt span:first-of-type");
    totAtmpQue.innerHTML = application.getTotAtmpQue();
}

function initPrevNext(){
    var get_ques_btn = document.querySelector("#a_question_commit input:last-of-type");
    var get_ques_btn_previous = document.querySelector("#a_question_commit input:first-of-type");
    get_ques_btn.parentNode.insertBefore(getQueToast(), get_ques_btn.nextSibling);
    get_ques_btn_previous.parentNode.insertBefore(getQueToast(), get_ques_btn_previous.nextSibling);
    get_ques_btn.onclick = function(event){
        get_question(event, scrl);
        //updateScrollerWhenNextBtnClicked(scrl);
        scrl.resetScroller(num);
        updateFlagButton();
        updateQuestionFlagDataWhenDisplayed();
    };
    get_ques_btn_previous.onclick = function(event){
        get_prev_question(event,scrl);
        //updateScrollerWhenPrevBtnClicked(scrl);
        scrl.resetScroller(num);
        updateFlagButton();
        updateQuestionFlagDataWhenDisplayed();
    };
    var review = document.querySelector(".a_quiz_commit input:first-of-type");
    review.onclick = reviewBtn;
}

function initialize(){
    window.history.pushState({},"Online Assessment",'/');
    toggle_visibility('popup-box1');
    initQuizMeta();
//    document.querySelector(".a_meta_question").onclick = postState;
    init_timer();
    init_scroller();
    initFlagQue();
    initPrevNext();
    initReview();
    initInstructions();
    hideHeaderAndFooter();
}
function init_timer(){
    var time = application.getTimeLimit();
    appTime = Timer(time);
    setInterval(function(){
        document.getElementsByClassName("a_time_up")[0].firstChild.nodeValue = appTime.displayUpTime();
        if(time != 0){
            document.getElementsByClassName("a_time_down")[0].firstChild.nodeValue = appTime.displayDownTime();
            if (appTime.getSetTime() - appTime.getTime() <= 1000) {
                changeTestVisibility("hide");
                submitQuiz();
            }
        }
    },1000);
    if(time==0){
        document.getElementsByClassName("a_time_down")[0].style.display = "none";
        document.getElementsByClassName("a_time_up")[0].style.width = "95%";
    }
}

function init_scroller(){
    var srl = new Scroller(scData);
    scrl = srl;
    document.getElementById("browse").appendChild(srl.getDisplayNode());
    var rd = srl.getRad();
    rd.onclick = function(){scrl.scRight()};
    var ld = srl.getLad();
    ld.onclick = function(){scrl.scLeft()};
    var div_c = srl.getDiv();
    for(var i = 0; i < div_c.length; i++){
        div_c[i].onclick = function(event){
            scrollClick(event,srl);
        }
    }
}

function scrollClick(event,srl){
    srl.currentBtn();
    var qId = event.target.getAttribute("data-link_id");
    var question_number = event.target.getAttribute("question_index");
    var section = document.querySelector(".a_meta_sec_select select");
    var section_number = section.value * 1;
    if(event.target.innerHTML.trim() != "."){
        saveQuestionTime();
        num = question_number * 1;
        current_time = appTime.getTime();
        node.replaceChild(createQues(application.getQuestion(section_number, question_number)), node.firstElementChild);
        event.target.style.outline = "#ccc solid 2px";
        //Update the flag data of the question as seen
        updateFlagButton();
        updateQuestionFlagDataWhenDisplayed();
        //Update scroller present index
        var question_indexes = srl.getQuestionIndexes();
        var question_index = question_indexes.indexOf(num);
        srl.setPresentIndex(question_index);
    }
}

function get_question(event, srl){
    //only called when next button is clicked
    var section = document.querySelector(".a_meta_sec_select select");
    var section_number = section.value * 1;
    // if(num < application.getSecTotQue(q_num) - 1){
    //     //If this is not the last question
    //     srl.currentBtn();//Remove border for all te scroller divisions
    //     saveQuestionTime();
    //     current_time = appTime.getTime();
    //     node.replaceChild(createQues(application.getQuestion(section_number, (++num) )),node.firstElementChild);
    //     (srl.getMd().childNodes)[num].style.outline = "#ccc solid 2px";
    // }
    // else if(num == application.getSecTotQue(q_num) - 1){
    //     var tost_next = document.querySelector("#a_question_commit input:last-of-type").nextSibling;
    //     tost_next.innerHTML = "<h4>Hey! you have reached Last Question of this section.</h4>";
    //     tost_next.style.display = "block";
    //     setTimeout(function(){tost_next.style.display = "none";},2000);
    // }
    var question_indexes = srl.getQuestionIndexes();
    var question_index = question_indexes.indexOf(num);//question_index : Index of question on the scroller
    if(question_index < question_indexes.length - 1){
        //There are more questions in the scroller
        srl.currentBtn();
        saveQuestionTime();
        current_time = appTime.getTime();
        num = question_indexes[question_index+1];
        node.replaceChild(createQues(application.getQuestion(section_number, num)),node.firstElementChild);
        (srl.getMd().childNodes)[question_index+1].style.outline = "#ccc solid 2px";
        srl.setPresentIndex(question_index+1);
    }else if(question_index == question_indexes.length - 1){
        // var tost_next = document.querySelector("#a_question_commit input:last-of-type").nextSibling;
        // tost_next.innerHTML = "<h4>Hey! you have reached Last Question of this section.</h4>";
        // tost_next.style.display = "block";
        // setTimeout(function(){tost_next.style.display = "none";},2000);
        showToastMessage(event.currentTarget, "Hey! you have reached Last Question of this section.");    
    }
}

function get_prev_question(event,srl){
    //only called when prev button is called
    var section = document.querySelector(".a_meta_sec_select select");
    var section_number = section.value * 1;
    // if(num > 0){
    //     //If this is not the first question
    //     srl.currentBtn();
    //     saveQuestionTime();
    //     current_time = appTime.getTime();
    //     node.replaceChild(createQues(application.getQuestion(section_number, (--num) )),node.firstElementChild);
    //     (srl.getMd().childNodes)[num].style.outline = "#ccc solid 2px";
    // }
    // else if(num == 0){
    //     var tost_pre = document.querySelector("#a_question_commit input:last-of-type").nextSibling;
    //     tost_pre.innerHTML = "<h4>Hey! you have reached First Question of this section.</h4>";
    //     tost_pre.style.display = "block";
    //     setTimeout(function(){tost_pre.style.display = "none";},2000);
    // }
    var question_indexes = srl.getQuestionIndexes();
    var question_index = question_indexes.indexOf(num);//question_index : Index of question on the scroller
    if(question_index > 0){
        //There are more questions in the scroller
        srl.currentBtn();
        saveQuestionTime();
        current_time = appTime.getTime();
        num = question_indexes[question_index-1];
        node.replaceChild(createQues(application.getQuestion(section_number, num)),node.firstElementChild);
        (srl.getMd().childNodes)[question_index-1].style.outline = "#ccc solid 2px";
        srl.setPresentIndex(question_index-1);
    }else if(question_index == 0){
        // var tost_next = document.querySelector("#a_question_commit input:last-of-type").nextSibling;
        // tost_next.innerHTML = "<h4>Hey! you have reached First Question of this section.</h4>";
        // tost_next.style.display = "block";
        // // 
        // setTimeout(function(){tost_next.style.display = "none";},2000);
        showToastMessage(event.currentTarget, "Hey! you have reached First Question of this section.");      
    }
}

function postState(){
    xhr = new XMLHttpRequest();
    xhr.open("POST","/data_js",false);
    xhr.setRequestHeader("Content-Type","application/json");
    xhr.send(JSON.stringify(application.getState()));
   if ((xhr.status >= 200 && xhr.status < 300) || xhr.status == 304){
       // num++;
       // application.setState(JSON.parse(xhr.responseText));
        window.history.pushState({},"Attempted Assessments",'/quizzes/show_student_attempts/' + application.getQuizPublishId())
        location.reload();
   }
   else{
       alert("request not successfull");
   }
}

function toggle_visibility(id) {
    var e = document.getElementById(id);
    if(e.style.display == 'block')
        e.style.display = 'none';
    else
        e.style.display = 'block';
}

function initQuizMeta(){
    var sel = document.querySelector(".a_meta_sec_select select");
    sel.appendChild(application.getSections());
    var num1 = sel.value;
    node.appendChild(createQues(application.getQuestion(0, 0)));
    var qIns = document.querySelector(".a_meta_test_instruction div");
    qIns.innerHTML = decodeHtml(application.getQuizInst());
    var secIns = document.querySelector(".a_meta_sec_instruction div");
    secIns.innerHTML = decodeHtml(application.getSecIns(0));
    var totSec = document.querySelector(".a_meta_sec_count span");
    totSec.innerHTML = 'Total no. of sections: 0' + application.getSecCount();
    var totQue = document.querySelector(".a_dyn_test_attempt span:last-of-type");
    totQue.innerHTML = application.getTotQue();
    var totSecQue = document.querySelector(".a_dyn_sec_attempt span:last-of-type");
    totSecQue.innerHTML = application.getSecTotQue(0);
    var totSecAtmpQue = document.querySelector(".a_dyn_sec_attempt span:first-of-type");
    totSecAtmpQue.innerHTML = application.getSecTotAtmpQue(0);
    var totAtmpQue = document.querySelector(".a_dyn_test_attempt span:first-of-type");
    totAtmpQue.innerHTML = application.getTotAtmpQue();
    initFlagMeta(0);
    var flagLeftBtn = document.querySelector(".a_flag_browse_left div:first-of-type");
    flagLeftBtn.style.cursor = "pointer";
    flagLeftBtn.onclick = initFlagMetaPrepLeft;
    var flagRightBtn = document.querySelector(".a_flag_browse_right div:last-of-type");
    flagRightBtn.style.cursor = "pointer";
    flagRightBtn.onclick = initFlagMetaPrepRight;
    sel.onchange = interQuizMeta;
}

//Called when section is changed
function interQuizMeta(){
    var sel = document.querySelector(".a_meta_sec_select select");
    var num1 = sel.value;
    num = 0;
    if(!reviewing_test){
        saveQuestionTime();
        current_time = appTime.getTime();
    } 
    //Remove all Child elements of node
    // while(node.firstElementChild){
    //     node.removeChild(node.firtElementChild);
    // }
    for(var i=node.children.length - 1;i>=0;i--){
        node.removeChild(node.children[i]);
    }
    node.appendChild(createQues(application.getQuestion(num1, 0)));
    //node.replaceChild(createQues(application.getQuestion(num1, 0)),node.firstElementChild);
    var secIns = document.querySelector(".a_meta_sec_instruction div");
    secIns.innerHTML = decodeHtml(application.getSecIns(num1));
    var totSecQue = document.querySelector(".a_dyn_sec_attempt span:last-of-type");
    totSecQue.innerHTML = application.getSecTotQue(num1);
    var totSecAtmpQue = document.querySelector(".a_dyn_sec_attempt span:first-of-type");
    totSecAtmpQue.innerHTML = application.getSecTotAtmpQue(num1);
    var totAtmpQue = document.querySelector(".a_dyn_test_attempt span:first-of-type");
    totAtmpQue.innerHTML = application.getTotAtmpQue();
    document.getElementById("browse").innerHTML = "";
    //Updating Scroller
    scData = application.getScrData(num1);
    init_scroller(scData);
    updateFlagButton();
    updateQuestionFlagDataWhenDisplayed();
    initFlagMeta(parseInt(num1));
    //Hide see all questions link
    document.querySelector(".a_flag_meta span").innerHTML = "";
    document.querySelector(".a_flag_meta span").appendChild(document.createTextNode("No. of Flagged Questions"));
    document.querySelector(".a_flag_meta a").innerHTML = "";
    document.querySelector(".a_flag_meta a").appendChild(document.createTextNode("See Flagged Questions"));
    document.querySelector("#a_flag_keeper").style.backgroundColor = "#f0f0f0";
}

function initFlagMetaPrepLeft(){
    var leftSec = document.querySelector(".a_flag_browse_left span:first-of-type");
    var sInd = leftSec.getAttribute("data_num")*1;
    if (sInd > 0 ){
        initFlagMeta(sInd -1)
    }else{
        showToastMessage(document.querySelector("#a_flag_keeper"),"Hey! There are no more sections.");
    }
}
function initFlagMetaPrepRight(){
    var leftSec = document.querySelector(".a_flag_browse_left span:first-of-type");
    var sInd = leftSec.getAttribute("data_num")*1;
    if (sInd < (application.getSecCount() - 2) ){
        initFlagMeta(sInd + 1)
    }else{
        showToastMessage(document.querySelector("#a_flag_keeper"),"Hey! There are no more sections.");
    }
}
function initFlagMeta(ind){
    if(ind < application.getSecCount()-1 ||ind == 0){
        //Updating Left Flag
        var leftSec = document.querySelector(".a_flag_browse_left span:first-of-type");
        var section_name = application.getSecName(ind);
        leftSec.innerHTML = section_name.indexOf(":") >= 0 ? section_name.split(":")[1] : section_name;
        leftSec.setAttribute("data_num",ind);
        leftSec.parentNode.onclick = updateScrollerWithFlaggedQuestions;
        //Update total no. of flagged Questions on left side
        var flaggedQuestionCount = application.getTotalNumberOfFlaggedQuestionsInSec(ind);
        flaggedQuestionCount = (flaggedQuestionCount >= 10) ? flaggedQuestionCount.toString() : '0'+flaggedQuestionCount.toString();
        document.querySelector(".a_flag_browse_left span:last-of-type").innerHTML = flaggedQuestionCount;
        //Updating Right Flag
        if(application.getSecCount() > 1){
            flaggedQuestionCount = application.getTotalNumberOfFlaggedQuestionsInSec(ind + 1);
            flaggedQuestionCount = (flaggedQuestionCount >= 10) ? flaggedQuestionCount.toString() : '0'+flaggedQuestionCount.toString();
            document.querySelector(".a_flag_browse_right span:last-of-type").innerHTML = flaggedQuestionCount;
            var rightSec = document.querySelector(".a_flag_browse_right span:first-of-type");
            var section_name = application.getSecName(ind+1);
            rightSec.innerHTML = section_name.indexOf(":") >= 0 ? section_name.split(":")[1] : section_name;
            rightSec.setAttribute("data_num", ind+1);
            rightSec.parentNode.onclick = updateScrollerWithFlaggedQuestions;
        }else{
            document.querySelector(".a_flag_browse_right div").style.display="none";
            document.querySelector(".a_flag_browse_left").style.borderRight="none";
            document.querySelector(".a_flag_browse_left").style.width = "320px";
            document.querySelector(".a_flag_browse_right").style.width = "120px";
        }
        //update total no. of flagged Questions on right side
    }
    else if(ind == application.getSecCount()-1)
        initFlagMeta(ind-1);
}
function initFlagQue(){
    document.querySelector("#a_flag_sec > span").innerHTML = "Flagged Questions \| " + application.getSecName(0)
    document.getElementById("browse1").innerHTML = "";
    var scData = application.getFlagData();
    var srr = new Scroller(scData);
    document.getElementById("browse1").appendChild(srr.getDisplayNode());
    var rd = srr.getRad();
    rd.onclick = function(){srr.scRight()};
    var ld = srr.getLad();
    ld.onclick = function(){srr.scLeft()};
    var div_c = srr.getDiv();
    for(var i = 0; i < div_c.length; i++){
        div_c[i].onclick = function(event){
            srr.currentBtn();
            scrollClick(event);
            updateFlagButton();
        }
    }
    updateQuestionFlagDataWhenDisplayed();
}
function decodeHtml(html) {
    var txt = document.createElement("textarea");
    txt.innerHTML = html;
    return txt.value;
}

function getQueToast(){
    var toast = document.createElement("div");
    toast.id = "que_toast";
    return toast;
}

function initGoBack(){
    //Called when resuming the test after reviewing
    document.querySelector(".a_meta_sec_select select").value=0;
    interQuizMeta();
    removeOverlay();
}

function tabClick(event){
    var sec_num = event.target.getAttribute("value");
    var all_tabs = event.target.parentNode.childNodes;
    for(var i=0;i<all_tabs.length;i++){
        all_tabs[i].style.borderBottom = "none";
    }
    event.target.style.borderBottom = "3px solid grey";
    displayReview(sec_num);
}

function displayReview(num){
    var que = document.getElementById("a_question_body");
    while(que.firstElementChild){
        que.removeChild(que.firstElementChild);
    }
    que = que.appendChild(document.createElement("div"));
    overlay();
    for(var i = 0; i< application.getSecTotQue(num); i++){
        que.appendChild(createQues(application.getQuestion(num, i)));
    }
    //overlay();//makes any question unselectable and unanswerable
    var all_tabs = document.querySelector("#a_tab_sec").childNodes;
    for(var i=0;i<all_tabs.length;i++){
        all_tabs[i].style.borderBottom = "none";
    }
    document.querySelector("#a_tab_sec").childNodes[num].style.borderBottom = "3px solid grey";
}

function initReview(){
    for(var i = 0; i < application.getSecCount(); i++){
        var div = document.createElement("a");
        div.setAttribute("value",i)
        div.setAttribute("href","#");
        var section_name = application.getSecName(i);
        div.innerHTML = section_name.indexOf(":") >= 0 ? section_name.split(":")[1] : section_name;
        div.onclick = tabClick;
        document.getElementById("a_tab_sec").appendChild(div) ;
    }
}

function reviewBtn(){
    if(!reviewing_test){
        document.querySelector("#a_rev_ques").style.display = "block";
        document.querySelector("#a_flag_keeper").style.display = "none";
        document.querySelector("#a_meta_section").style.display = "none";
        document.querySelector("#a_question_commit").style.display = "none";
        saveQuestionTime();
        reviewing_test=true;
        displayReview(0);
        document.querySelector(".a_quiz_commit input:first-of-type").value = "Resume Test";
    }else{
        document.querySelector("#a_rev_ques").style.display = "none";
        document.querySelector("#a_flag_keeper").style.display = "block";
        document.querySelector("#a_meta_section").style.display = "block";
        document.querySelector("#a_question_commit").style.display = "block";
        reviewing_test=false;
        document.querySelector(".a_quiz_commit input:first-of-type").value = "Review Test";
        initGoBack();
        updateFlagButton();
        flagged_mode=false;
    }
    rearrangeTimerAndQuizCommit();
}

function startQuiz(){
    quiz_started = true;
    appTime.startTime();
    application.timestart();
}

function submitQuiz(){
    if(!quiz_submitted){
        document.querySelector("#popup-box2 #div_btn div:last-of-type").onclick = null;
        saveQuestionTime();
        application.timefinish();
        quiz_submitted = true;
        postState();
    }
}

function flagClicked(event){
    //get the section number
    var section = document.querySelector(".a_meta_sec_select select");
    var section_number = section.value * 1;
    //get the question number 
    var question_number = num;
    //update the flag status of this question
    var flag_data = application.getQuestionFlagData(section_number, question_number);
    var previous_status = flag_data[2];
    var present_status = (previous_status==0) ? 1 : 0;
    application.setQuestionFlagDataPartially(section_number, question_number, 2, present_status);
    //update the scroller data
    //get the question index on the scroller
    var question_index = scrl.getPresentIndex();
    scrl.updateAMiddleNode(question_index);
    //update Flag Button
    updateFlagButton();
    //update Flag Meta Data
    initFlagMeta(section_number);
}

function updateFlagButton(){
    //get the section number
    var section = document.querySelector(".a_meta_sec_select select");
    var section_number = section.value * 1;
    //get the question number 
    var question_number = num;
    //get question flag data
    var flag_data=application.getQuestionFlagData(section_number, question_number);
    var flag_button = document.querySelector('.flagButton');
    if(flag_data[2]==1){
        flag_button.innerHTML='unflag';
        flag_button.style.backgroundColor = "rgba(255, 157, 162, 0.5)";
    }else{
        flag_button.innerHTML='flag';
        flag_button.style.backgroundColor = "rgba(255, 157, 162, 1.0)";
    }
}

function updateQuestionFlagDataWhenDisplayed(){
    //Sets the flag data as seen
    //get the section number
    var section = document.querySelector(".a_meta_sec_select select");
    var section_number = section.value * 1;
    //get the question number 
    var question_number = num;
    //update question flag data as seen
    application.setQuestionFlagDataPartially(section_number, question_number, 0, 1);
    //update the scroller data
    //get the position of the question on the scroller
    var question_index = scrl.getPresentIndex();
    scrl.updateAMiddleNode(question_index);
}

function updateQuestionFlagDataWhenAnswered(){
    //get the section number
    var section = document.querySelector(".a_meta_sec_select select");
    var section_number = section.value * 1;
    //get the question number 
    var question_number = num;
    //get the questions answered status
    var value = application.getQuestionAnsweredStatus(section_number, question_number);
    //update question flag answer data
    application.setQuestionFlagDataPartially(section_number, question_number, 1, value);
    //update the scroller data
    var question_index = scrl.getPresentIndex();
    scrl.updateAMiddleNode(question_index);
}

function overlay(){
    var question_body = document.querySelector("#a_question_body");
    var overlay = document.createElement("div");
    overlay.setAttribute("id", "overlay");
    overlay.setAttribute("style", "z-index:99; position:absolute; background-color:rgba(255,255,255,0);width:900px;height:1000px;");
    question_body.insertBefore(overlay, question_body.childNodes[0]);
    overlay_interval = setInterval(function(){
        var question_body_width = $("#a_question_body").css('width');
        var question_body_height = $("#a_question_body").css('height');
        $('#overlay').css('width',question_body_width);
        $('#overlay').css('height',question_body_height);
    }, 1000);
    $('.flagButton').hide();
}

function removeOverlay(){
    clearInterval(overlay_interval);
    var overlay = document.querySelector("#overlay");
    if(overlay != null){
        overlay.parentNode.removeChild(overlay);
    }
    $('.flagButton').show();
}

function updateScrollerWithFlaggedQuestions(event){
    var section = document.querySelector(".a_meta_sec_select select");
    var section_number;
    var previous_section_number = section.value * 1;
    var previous_quiz_state_flagged;
    previous_quiz_state_flagged = flagged_mode;
    if(event!=undefined)
        section_number=event.currentTarget.querySelector("span").getAttribute("data_num");
    else{
        section_number=section.value * 1;
    }
    section.value = section_number;
    section_number *= 1;
    var new_scroller = application.getSecFlaggedScrData(section_number);
    if(new_scroller.length >= 1){
        scData = new_scroller;
        document.getElementById("browse").innerHTML = "";
        saveQuestionTime();
        current_time = appTime.getTime();
        num=application.getSecFirstFlaggedQuestionIndex(section_number);
        //Updating Scroller
        init_scroller(scData);
        node.replaceChild(createQues(application.getQuestion(section_number, num)),node.firstElementChild);
        updateFlagButton();
        updateQuestionFlagDataWhenDisplayed();
        if(event!=undefined){
            document.querySelector(".a_flag_meta a").setAttribute("state", "flagged_questions");
            document.querySelector(".a_flag_meta span").innerHTML = "";
            document.querySelector(".a_flag_meta span").appendChild(document.createTextNode("Seeing Flagged Questions"));
            document.querySelector(".a_flag_meta a").innerHTML = "";
            document.querySelector(".a_flag_meta a").appendChild(document.createTextNode("See All Questions"));
            document.querySelector("#a_flag_keeper").style.backgroundColor = "#ff9da2";
        }
        flagged_mode = true;
        updateQuestionCountInHeader();
        return true;
    }else{
        showToastMessage(document.querySelector("#a_flag_keeper"),"There are no flagged questions in this section.");
        if(event != undefined){
            // if(previous_quiz_state_flagged){
            //     document.querySelector(".a_flag_meta a").setAttribute("state", "flagged_questions");
            //     document.querySelector(".a_flag_meta span").innerText = "Seeing Flagged Questions";
            //     document.querySelector(".a_flag_meta a").innerText = "See All Questions";
            // }else{
            //     document.querySelector(".a_flag_meta a").setAttribute("state", "all_questions");
            //     document.querySelector(".a_flag_meta span").innerText = "No. of Flagged Questions";
            //     document.querySelector(".a_flag_meta a").innerText = "See Flagged Questions";
            // }
        }else{
            
        }
        section.value = previous_section_number;
    }
    return false;
}

function updateScrollerWithAllQuestions(){
    interQuizMeta();
    document.querySelector(".a_flag_meta span").innerHTML = "";
    document.querySelector(".a_flag_meta span").appendChild(document.createTextNode("No. of Flagged Questions"));
    document.querySelector(".a_flag_meta a").innerHTML = "";
    document.querySelector(".a_flag_meta a").appendChild(document.createTextNode("See Flagged Questions"));
    flagged_mode = false;
}

function updateQuestionCountInHeader(){
    var section = document.querySelector(".a_meta_sec_select select");
    var section_number = section.value;
    var totSecQue = document.querySelector(".a_dyn_sec_attempt span:last-of-type");
    totSecQue.innerHTML = application.getSecTotQue(section_number);
    var totSecAtmpQue = document.querySelector(".a_dyn_sec_attempt span:first-of-type");
    totSecAtmpQue.innerHTML = application.getSecTotAtmpQue(section_number);
    var totAtmpQue = document.querySelector(".a_dyn_test_attempt span:first-of-type");
    totAtmpQue.innerHTML = application.getTotAtmpQue();
}

function toggleQuizMode(){
    var present_state = document.querySelector(".a_flag_meta a").getAttribute("state");
    if(present_state == "flagged_questions"){
        updateScrollerWithAllQuestions();
        document.querySelector(".a_flag_meta a").setAttribute("state", "all_questions");
        document.querySelector(".a_flag_meta span").innerHTML = "";
        document.querySelector(".a_flag_meta span").appendChild(document.createTextNode("No. of Flagged Questions"));
        document.querySelector(".a_flag_meta a").innerHTML = "";
        document.querySelector(".a_flag_meta a").appendChild(document.createTextNode("See Flagged Questions"));
        document.querySelector("#a_flag_keeper").style.backgroundColor = "#f0f0f0";
    }else{
        var state_changed=updateScrollerWithFlaggedQuestions();
        if(state_changed){
            document.querySelector(".a_flag_meta a").setAttribute("state", "flagged_questions");
            document.querySelector(".a_flag_meta span").innerHTML = "";
            document.querySelector(".a_flag_meta span").appendChild(document.createTextNode("Seeing Flagged Questions"));
            document.querySelector(".a_flag_meta a").innerHTML = "";
            document.querySelector(".a_flag_meta a").appendChild(document.createTextNode("See All Questions"));
            document.querySelector("#a_flag_keeper").style.backgroundColor = "#ff9da2";
        }
    }
    updateFlagButton();
}

function showInstructions(section_number){
    if(typeof section_number == 'undefined'){
        section_number = -1;
    }
    var a_meta_instruction_division = document.getElementById("a_instructions_meta");
    a_meta_instruction_division.innerHTML = "";
    var ul_div = document.createElement("ul");
    var sec_instructions, instructions_heading;
    var instructions_div = document.getElementById("a_instructions");
    instructions_div.innerHTML = "";
    //show section count
    //show total questions
    //show total marks
    //show test duration
    var section_count, total_questions, total_marks, test_duration;
    if(section_number == -1){
        section_count = document.createElement('li');
        section_count.appendChild(document.createTextNode("Total Number of Sections: "+application.getSecCount()));
        total_questions = document.createElement('li');
        total_questions.appendChild(document.createTextNode("Total Number of Questions: "+application.getTotQue()));
        total_marks = document.createElement('li');
        total_marks.appendChild(document.createTextNode("Total Marks: "+application.getSecTotalMarks(-1)));
        test_duration = document.createElement('li');
        var time_limit = application.getTimeLimit(section_number)*60;
        if(time_limit == 0)
            test_duration.appendChild(document.createTextNode("Time Limit: "+ "No Time Limit"));
        else
            test_duration.appendChild(document.createTextNode("Time Limit: "+application.getTimeLimit(section_number)*60 + " min"));
        ul_div.appendChild(section_count).appendChild(total_questions).appendChild(test_duration).appendChild(total_marks);
        instructions_heading = document.createElement('h3');
        instructions_heading.appendChild(document.createTextNode("Main Instructions"));
        section_instructions = document.createElement('div');
        section_instructions.innerHTML = application.getQuizInst();
        document.getElementById("a_instructions_heading").innerHTML = "";
        document.getElementById("a_instructions_heading").appendChild(instructions_heading);
        instructions_div.appendChild(section_instructions);
        if(application.getQuizInst()==null || application.getQuizInst()=="")
            instructions_heading.style.display='none';
        document.getElementById("a_sec_instructions_tab").style.display="none";
    }else{
        total_questions = document.createElement('li');
        total_questions.appendChild(document.createTextNode("Total Number of Questions: "+application.getSecTotQue(section_number)));
        total_marks = document.createElement('li');
        total_marks.appendChild(document.createTextNode("Total Marks: "+application.getSecTotalMarks(section_number)));
        ul_div.appendChild(total_questions).appendChild(total_marks);
        var section_type = application.getSecType(section_number);
        var instructions = application.getSecInstructions(section_number);
        if(section_type == 'section' || section_type == 'sub_section'){
            instructions_heading = document.createElement('h3');
            instructions_heading.appendChild(document.createTextNode(instructions.section_name+" Instructions"));
            section_instructions = document.createElement('div');
            section_instructions.innerHTML = instructions.section_instructions;
            document.getElementById("a_instructions_heading").innerHTML = "";
            document.getElementById("a_instructions_heading").appendChild(instructions_heading);
            instructions_div.appendChild(section_instructions);
            if(instructions.section_instructions==null || instructions.section_instructions=="")
                instructions_heading.style.display='none';
        }
        if(section_type == 'sub_section'){
            instructions_heading = document.createElement('h3');
            instructions_heading.appendChild(document.createTextNode(instructions.sub_section_name+" Instructions"));
            section_instructions = document.createElement('div');
            section_instructions.innerHTML = instructions.sub_section_instructions;
            instructions_div.appendChild(instructions_heading);
            instructions_div.appendChild(section_instructions);
            if(instructions.sub_section_instructions==null || instructions.sub_section_instructions=="")
                instructions_heading.style.display='none';
        }
        // sec_instructions = application.getSecIns(section_number);
        document.getElementById("a_sec_instructions_tab").style.display="block";
    }
    a_meta_instruction_division.appendChild(ul_div);
    document.getElementById("a_instructions_dialog_box").style.display = 'block';
    //Display border for present Section
    var all_tabs = document.getElementById("a_sec_instructions_tab").childNodes;
    for(var i=0;i<all_tabs.length;i++){
        all_tabs[i].style.border = "none";
        if((all_tabs[i].getAttribute("value") * 1 == section_number)){
            all_tabs[i].style.borderBottom = "2px solid grey";
            all_tabs[i].style.color = "#60c8cd";
        }else{           
            all_tabs[i].style.borderBottom = "1px solid lightgray";
            all_tabs[i].style.color = "grey";
        }
    }
}

function hideInstructions(){
    document.getElementById("a_instructions_dialog_box").style.display = 'none';
}

function hideHeaderAndFooter(){
    document.getElementById("header_bg").style.display = 'none';
    document.getElementById("footer").style.display = 'none';
}

function initInstructions(){
    var test_instructions_tab = document.getElementById("a_test_instructions_tab");
    var sections_tab = document.getElementById("a_sec_instructions_tab");
    //If there are no sections in the test hide sections tab
    var total_number_of_sections = application.getSecCount();
    if(total_number_of_sections == 1 && application.getSecType(0)=='none'){
        document.getElementById("a_sec_instructions_wrapper_tab").style.display = "none";
    }else{
        for(var i = 0; i < total_number_of_sections; i++){
            if(application.getSecType(i)!="none"){
                var div = document.createElement("div");
                div.setAttribute("value",i)
                var section_name = application.getSecName(i);
                div.appendChild(document.createTextNode(section_name.indexOf(":") >= 0 ? section_name.split(":")[1] : section_name));
                div.onclick = tabClickSecInstructions;
                sections_tab.appendChild(div) ;
            }
        }
    }
}

function tabClickSecInstructions(event){
    var section_number = event.currentTarget.getAttribute('value');
    section_number *= 1;
    var all_tabs = event.currentTarget.parentNode.childNodes;
    for(var i=0;i<all_tabs.length;i++){
        all_tabs[i].style.border = "none";
        all_tabs[i].style.borderBottom = "1px solid lightgray";
    }
    event.currentTarget.style.borderBottom = "1px solid grey";
    showInstructions(section_number);
}

function showSecInstructions(){
    var total_number_of_sections = application.getSecCount();
    if(total_number_of_sections == 1 && application.getSecType(0)=='none'){
        showToastMessage(document.querySelector('.a_meta_sec_instruction'), "There are no Section Instructions.");
    }else{
        var section = document.querySelector(".a_meta_sec_select select");
        var section_number = section.value * 1;
        tabClickInstructions(1, section_number);
    }
}

function showInstructionBeforeStartingTest(){    
    toggle_visibility('popup-box1');
    changeTestVisibility("hide");
    document.getElementById("a_assessment").style.display = "block";
    tabClickInstructions(0, -1);
}

function resumeTest(){
    if(!quiz_started){
        startQuiz();
        changeTestVisibility("show");
        document.querySelector('#a_instructions_commit input[type="button"]').setAttribute('value', 'ResumeTest');
    }else{
        togglePauseTest("ResumeTest");
    }
    hideInstructions();
}

function changeTestVisibility(state){
    var display_style;
    if(state == "hide")
        display_style = "none";
    else
        display_style = "block";
    document.getElementById("a_header").style.display = display_style;
    document.getElementById("a_question_body").style.display = display_style;
    document.getElementById("a_question_commit").style.display = display_style;
    document.getElementById("a_quiz_tool").style.display = display_style;
}

function doNotStartTest(){
    //Called when clicked cancel button at the start of the test
    window.history.pushState({},"Attempted Assessments",'/quizzes/show_student_attempts/' + application.getQuizPublishId());
    location.reload();
}

function rearrangeTimerAndQuizCommit(){
    var timer = document.querySelector(".a_time_keeper");
    var quiz_commit = document.querySelector(".a_quiz_commit");
    var fixed_div = document.getElementById("a_fixed_quiz_tool");
    var quiz_tool = document.getElementById("a_quiz_tool");
    var flag_keeper = document.getElementById("a_flag_keeper");
    if(reviewing_test){
        fixed_div.appendChild(timer);
        fixed_div.appendChild(quiz_commit);
    }else{
        flag_keeper.parentNode.insertBefore(timer, flag_keeper);
        flag_keeper.parentNode.appendChild(quiz_commit);
    }
}

function tabClickInstructions(index, section_number){
    //index - 0 Test Instructions
    //index - 1 Section Instructions
    var test_instructions_tab = document.getElementById("a_test_instructions_tab");
    var sec_instructions_tab = document.getElementById("a_sec_instructions_wrapper_tab");
    if(index==0){
        test_instructions_tab.style.borderBottom = "3px solid grey";
        test_instructions_tab.querySelector('h3').style.color = "#1fa5b1";
        sec_instructions_tab.style.borderBottom = "none";
        sec_instructions_tab.querySelector('h3').style.color = "grey";
        showInstructions(-1);
    }else{
        sec_instructions_tab.style.borderBottom = "3px solid grey";
        sec_instructions_tab.querySelector('h3').style.color = "#1fa5b1";
        test_instructions_tab.style.borderBottom = "none";
        test_instructions_tab.querySelector('h3').style.color = "grey";
        showInstructions(section_number);
    }
}

function showToastMessage(element, message){
    var toast_div = document.createElement('div');
    toast_div.className = "toast_message";
    var m = document.createElement('h4');
    m.innerHTML = "";
    m.appendChild(document.createTextNode(message));
    toast_div.appendChild(m);
    //element.parentNode.insertBefore(toast_div, element.nextSibling);
    element.parentNode.appendChild(toast_div);
    setTimeout(function(){
        element.parentNode.removeChild(toast_div);
    }, 2000);
}

function togglePauseTest(new_state){
    var pause_button = document.querySelector(".pause_button");
    if(pause_button != null){
        var present_state = pause_button.getAttribute("state");
        if(typeof(new_state) == 'undefined' && present_state == "Running"){
            appTime.pauseTime();
            // pause_button.innerHTML = "";
            // pause_button.appendChild(document.createTextNode("Paused"));
            pause_button.setAttribute("state", "Paused");
            pause_button.value = "Paused";
            tabClickInstructions(0, -1);
        }else if(present_state == "Paused"){
            appTime.startTime();
            // pause_button.innerHTML = "";
            // pause_button.appendChild(document.createTextNode("Pause Test"));
            pause_button.setAttribute("state", "Running");
            pause_button.value = "Pause Test";
        }
    }
}

