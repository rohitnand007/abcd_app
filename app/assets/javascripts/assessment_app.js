var application = function(){
    var params_string = document.getElementById("a_quiz_data").innerHTML.trim();
    var params = JSON.parse(params_string);

    var xhr = new XMLHttpRequest();
    xhr.open("POST","/get_data",false);
    xhr.setRequestHeader("Content-Type","application/json");
    xhr.send(JSON.stringify(params));
    if ((xhr.status >= 200 && xhr.status < 300) || xhr.status == 304){
        var data_s = xhr.responseText;
        data = JSON.parse(xhr.responseText);
    }
    else{
        alert("request not successfull");
    }


    var app = new Object();
    app.meta = data;
    app.meta = new Array();
    app.state = new Array();
    app.getQuizInst = function(){
        return data.quiz.intro;
    }
    app.getSecIns = function(num){
        qs = "qs_" + num;
        return data.quiz.quiz_sections[num].intro;
    }
    app.getSecCount = function(){
        return data.quiz.qs_count;
    }
    app.getTotQue = function(){
        return data.quiz.q_count;
    }
    app.getTotAtmpQue = function(){
        var atmpt = 0;
        for(var i = 0; i < this.getSecCount(); i ++){
            atmpt = atmpt + this.getSecTotAtmpQue(i);
        }
        data.state.atmpt = atmpt;
        return data.state.atmpt;
    }
    app.getSecTotQue = function(num){
        return data.quiz.quiz_sections[num].q_count;
    }
    app.getSecTotAtmpQue = function(num){
        var atmpt = 0;
        for(var i = 0; i < this.getSecTotQue(num);i++){
            if(data.state.quiz.quiz_sections[num].questions[i].atmpt == 1){
                atmpt = atmpt + 1;
            }
        }
        data.state.quiz.quiz_sections[num].atmpt = atmpt;
        return data.state.quiz.quiz_sections[num].atmpt;
    }
    app.getScrData = function(num){
        return data.state.quiz.quiz_sections[num].scr;
    }
    app.getSecFlaggedScrData = function(section_number){
        var section_scroller = data.state.quiz.quiz_sections[section_number].scr;
        var section_flagged_scroller = new Array();
        for(var i=0; i<section_scroller.length; i++){
            if(section_scroller[i].fl[2]==1)
                section_flagged_scroller.push(section_scroller[i]);
        }
        return section_flagged_scroller;
    }
    app.getSecFirstFlaggedQuestionIndex = function(section_number){
        var section_scroller = data.state.quiz.quiz_sections[section_number].scr;
        var section_first_flagged_question = -1;
        for(var i=0; i<section_scroller.length; i++){
            if(section_scroller[i].fl[2]==1){
                section_first_flagged_question = i;break;
            }
        }
        return section_first_flagged_question;
    }
    app.getSections = function(){
        var count = 0;
        var options = document.createDocumentFragment();
        for(var i=0; i < data.quiz.qs_count; i++){
            var option = document.createElement("option");
            option.setAttribute("value",count);
            option.setAttribute("data-secID",data.quiz.quiz_sections[i].id);
            option.innerHTML = data.quiz.quiz_sections[i].name;
            options.appendChild(option);
            count++;
        }
        return options;
    }
    app.getSecName = function(num){
        return data.quiz.quiz_sections[num].name;
    }
    app.getTotalNumberOfFlaggedQuestionsInSec = function(section_number){
        //data.state.quiz.quiz_sections[num1].scr[num2].fl
        var section_scroller = data.state.quiz.quiz_sections[section_number].scr;
        var count = 0;
        for(var i=0; i<section_scroller.length; i++){
            if(section_scroller[i].fl[2]==1)
                count++;
        }
        return count;
    }
    app.getTimeLimit = function(){
        return data.quiz.timelimit / 60;
    }
    app.getQuestion = function(num1,num2,num3){
        var que = data.quiz.quiz_sections[num1].questions[num2];
        var stat = data.state.quiz.quiz_sections[num1].questions[num2];
        if(num3 != undefined){
            que = data.quiz.quiz_sections[num1].questions[num2].questions[num3];
            stat = data.state.quiz.quiz_sections[num1].questions[num2].questions[num3];
        }
        var pques;
        if (que.questions != 0) {
            pques = que.questions;
        }
        var opt_obj
        if (stat.options) {
            opt_obj = stat.options;
        }
        else {
            opt_obj = new Array(que.qtext.match(/#DASH#/g).length);
        }

        return {q_no: que.qNo,
            num1: num1,
            num2: num2,
            num3: num3,
            qtext: que.qtext,
            qtype: que.qtype,
            qmulti: que.qmulti,
            marks: que.qQIns.grade,
            n_marks: que.qQIns.penalty,
            options: que.options,
            ans: 1, //stat.answer,
            stat_options: stat.options,
            questions: [num1,num2,num3],
            question: pques
        };
//            scll: app.getFlagData()};
    }
    app.checkMulitAnswerQuestion = function(section_number, question_number){
        //returns true if the question is multi answer multiple choice question
        return data.quiz.quiz_sections[section_number].questions[question_number].qmulti;
    }
    app.getQueFlagData = function(num1, num2){
        return data.state.quiz.quiz_sections[num1].scr[num2].fl;
    }
    app.setQueFlagData = function(section_number, question_number, flag_data){
        data.state.quiz.quiz_sections[section_number].questions[question_number].scr.fl = flag_data;
    }
    app.getQuestionFlagData = function(num1, num2){
        return data.state.quiz.quiz_sections[num1].scr[num2].fl;
    }
    app.setQuestionFlagDataPartially = function(section_number, question_number,flag_index, flag_value){
        data.state.quiz.quiz_sections[section_number].scr[question_number].fl[flag_index]=flag_value;
    }
    app.getQuestionAnsweredStatus = function(section_number, question_number){
        return data.state.quiz.quiz_sections[section_number].questions[question_number].answer;
    }
    app.getFlagData = function(){
        /*
            fl:[a,b,c]
            fl[0] : 0 - not seen the question
            fl[1] : 0 - not answered the question
            fl[2] : 0 - not flagged the question 
        */
        return  [{bl:"/1.png", fl:[0, 0, 0], vl: "5A"},
            {bl:"/A.png", fl:[0, 0, 0], vl: "A"},
            {bl:"/D.png", fl:[0, 1, 0], vl: "D"},
            {bl:"/34.png", fl:[1, 1, 1], vl: "34"},
            {bl:"/5.png", fl:[1, 0, 0], vl: "5"},
            {bl:"/6G", fl:[0, 0, 0], vl: "5G"},
            {bl:"/asdf", fl:[0, 1, 0], vl: "98"},
            {bl:"/asdfag1", fl:[0, 1, 0], vl: "GH"},
            {bl:"/1asdfadf", fl:[1, 1, 1], vl: "KL"}];
    }
    app.getPassageQuestionIDs = function(section_number){
        var questions = data.quiz.quiz_sections[section_number].questions;
        var total_questions = data.quiz.quiz_sections[section_number].q_count;
        var passage_question_ids = [];
        for(var i=0;i<total_questions;i++){
            if(questions[i].questions){
                if(passage_question_ids.indexOf(questions[i].questions.id) == -1)
                    passage_question_ids.push(questions[i].questions.id);
            }
        }
        return passage_question_ids;
    }
    app.getState = function(){
        return {quiz: data.state};
    }
    app.setState = function (x) {
        data.state = x;
    }
    app.postToWrap = function(section_number, question_number, option_index){
        var options= data.state.quiz.quiz_sections[section_number].questions[question_number].options;
        options[option_index].opt = (options[option_index].opt==true) ? '' : true;
        var number_of_options = options.length;
        //if question is single answer multi choice or true or false update all other options as unselected
        var question_type = data.state.quiz.quiz_sections[section_number].questions[question_number].qtype;
        if(question_type=='truefalse' || !(this.checkMulitAnswerQuestion(section_number, question_number))){
            for(var index in options){
                if(index!=option_index)
                    options[index].opt='';
            }
        }
        var answered_status = false;
        for(var index in options){
            var option_status = (options[index].opt==true) ? true : false;
            answered_status = answered_status || option_status;
        }
        data.state.quiz.quiz_sections[section_number].questions[question_number].atmpt = (answered_status) ? 1 : 0;
        data.state.quiz.quiz_sections[section_number].questions[question_number].answer = (answered_status) ? 1 : 0;
    }
    app.postFibToWrap = function (section_number, question_number, a) {
        data.state.quiz.quiz_sections[section_number].questions[question_number].options = a;
        var answered_status = false;
        for(var index in a){
            if(a[index].length>0){
                answered_status = true;break;
            }
        }
        data.state.quiz.quiz_sections[section_number].questions[question_number].atmpt = answered_status ? 1 : 0;
        data.state.quiz.quiz_sections[section_number].questions[question_number].answer = answered_status ? 1 : 0;
    }
    app.setQuesTimeSpent = function (num1, num2, time) {
        data.state.quiz.quiz_sections[num1].questions[num2].time += time;
    }
    app.timestart = function () {
        data.state.timestart = Date.now() / 1000;
    }
    app.timefinish = function () {
        data.state.timefinish = Date.now() / 1000;
    }
    app.getSecTotalMarks = function (section_number) {
        if(section_number != -1){
            var questions = data.quiz.quiz_sections[section_number].questions;
            var total_marks = 0;
            for(var i=0;i<questions.length;i++){
                var marks = questions[i].qQIns.grade * 1;
                total_marks += marks;
            }
        }else{
            var sections = data.quiz.quiz_sections;
            var total_marks = 0;
            for(var i=0;i<sections.length;i++){
                var questions = data.quiz.quiz_sections[i].questions;
                for(var j=0;j<questions.length;j++){
                    var marks = questions[j].qQIns.grade * 1;
                    total_marks += marks;
                }
            }
        }
        return total_marks;
    }
    app.getSecType = function (section_number){
        return data.quiz.quiz_sections[section_number].section_type;
    }
    app.getSecInstructions = function (section_number){
        var instructions = new Object();
        var section = data.quiz.quiz_sections[section_number];
        instructions.section_type = section.section_type;
        if(section.section_type == 'sub_section'){           
            instructions.sub_section_name = section.sub_section_name;
            instructions.sub_section_instructions = section.sub_section_instructions;
        }
        if(section.section_type == 'section' || section.section_type =='sub_section'){
            instructions.section_name = section.section_name;
            instructions.section_instructions = section.section_instructions;
        }
        return instructions;
    }
    app.getQuizPublishId = function(){
        return data.state.publish.id;
    }
    return app;
}();