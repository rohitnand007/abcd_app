
$.fn.playMatchtheItem = function(json,prefix){
//	screen.orientation.lock('landscape');
    var strokecolor={
        "0":"#1C86EE",
        "1":"#7171C6",
        "2":"#FF3E96",
        "3":"#8FBC8F",
        "4":"#1C86EE",
        "5":"#7171C6"
    }
    var stageWidth = 1000;
    var stageHeight = 550;
    var questionX = 150;
    var answerXoffset = 530;
    var questionYoffset = 130;  /*Same as Answer Y offset */
    var firstQuesPositionY = 35;
    var firstBoxPositionY =25;
    var boxX = 360;
    var answerFinalPosition = {};
    var forgettingBox={};
    var sources={};
    var answersources={};
    var imageBorder = "#008B45";
    var imageWidth = 90;
    var imageHeight = 90;
    var answerInBoxOffsetX=70;
    var answerInBoxOffsetY = 12;
    var forScramble = new Array();
    var scrambledArray = new Array();
    var shadowOffsetX = 1;
    var shadowOffsetY =1;
    var shadowcolor = '#c5c5c5';
    var shadowblur = 8;
    var shadowopacity = 0.8;
    var wrongAnswerNum = 0;
    var needHelpClicked = 0;
    var backrectY = 0;
    /****variable for disable click if no element is inside the box *****/
    var answerPositionforChecking = {};
    //question image positions
    var questions_position = {
        "0": {
            "x": questionX ,
            "y": firstQuesPositionY
        },
        "1": {
            "x": questionX ,
            "y": firstQuesPositionY+questionYoffset
        },
        "2": {
            "x": questionX ,
            "y": firstQuesPositionY+2*questionYoffset
        },
        "3": {
            "x": questionX ,
            "y": firstQuesPositionY+3*questionYoffset
        },
        "4":{
            "x": questionX ,
            "y": firstQuesPositionY+4*questionYoffset
        },
        "5":{
            "x": questionX ,
            "y": firstQuesPositionY+5*questionYoffset
        }
    };
    var answerbox_position={
        "0": {
            "x": boxX,
            "y": firstBoxPositionY
        },
        "1": {
            "x": boxX,
            "y": firstBoxPositionY+questionYoffset
        },
        "2": {
            "x": boxX,
            "y": firstBoxPositionY+2*questionYoffset
        },
        "3": {
            "x": boxX,
            "y": firstBoxPositionY+3*questionYoffset
        },
        "4":{
            "x": boxX ,
            "y": firstBoxPositionY+4*questionYoffset
        },
        "5":{
            "x": boxX ,
            "y": firstBoxPositionY+5*questionYoffset
        }
    };
    var logo_prefix = "/assets/activities/"
    if(json["logo"] != "ignitor_logo.png"){
        logo_prefix = prefix;
    }
    $('html, body').on('touchmove', function(e){
        //prevent native touch activity like scrolling
        e.preventDefault();
    });
    $(this).html('\<div class="preview-content">\
			<div class="row preview-row">\
			\
			<div><span class="col-sm-6 active activeprev">'+json["name"]+'</span></div>\
			<div><span class="col-sm-2 prev" id="check-answer" ><img src="/assets/activities/check-mark.png" class="preview-glyph">Check My Answer</span></div>\
                       <div><span class="col-sm-2 prev" id="need-help"><img src="/assets/activities/information-button.png" class="preview-glyph">Need Help</span></div>\
                       <div><span class="col-sm-2 prev" id="reset-the-questions"><img src="/assets/activities/reload.png" class="preview-glyph">Reset the Questions</span></div>\
			</div>\
			<div id="previewDescription"></div>\
			<div id="preview-container"></div>\
            <div class="btn" id="scroll-top"><div class="up-arrow">Up</div></div>\
            <div class="btn" id="scroll-bottom"><div class="down-arrow">Down</div></div>\
			<img src="'+logo_prefix+json["logo"]+'" class="ignitor-logo"/>\
			<audio id="excellent" src="/assets/audio/Excellent.wav"></audio><audio id="tryagain" src="/assets/audio/Please_try_again.wav"></audio></div>\
	');
    if (json['instructions'] != undefined) {
        $('#previewDescription').empty().append('<h3 class="description-heading" style="margin-top:0px">Instructions for the Activity:</h3><p class="description_text">' + json['instructions'] + '</p>');
    } else {
        $('#previewDescription').empty();
    }

    $("#check-answer").hover(function(){
        if(atleastOneElemntIsInBox()){
            $(this).css({"cursor":"pointer"});
        }else{
            $(this).css({"cursor":"not-allowed"});
        }
    })

    sources = {};
    answersouces = {};
    forgettingBox={};
    imageSources();
    answerfinalPosition();
    scrambledanswerFinalPosition();
    loadImages(sources,loadPreview);
    window.onresize = resizeFunc;
    $("#reset-the-questions").click(function(){
        //answerfinalPosition();
        //loadImages(sources,loadPreview);
        location.reload();
    });

    function resizeFunc(){
        answerfinalPosition();
        loadImages(sources,loadPreview);
    };

    function imageSources(){
        $.each(json,function(key,value){
            if(isNumericKey(key)){
                var i=0;
                var itisImage = false;
                $.each(value,function(newkey,newvalue){
                    i++;
                    if(i == 2){
                        $.each(value["question"]["type"],function(keys,values){
                            if(keys == "image"){
                                itisImage = true;
                            }
                        })
                    }
                });
                if(i == 2 && itisImage){
                    sources[key]=imageUrl(value["question"]["type"]["image"]["value"]);
                    forgettingBox[key]=imageUrl(value["question"]["type"]["image"]["value"]);
                }
                else if(i == 2 && !(itisImage)){
                    forgettingBox[key]=value["question"]["type"]["text"]["value"];
                }
            }
        });
        $.each(json,function(key,value){
            if(isNumericKey(key)){
                var i=0;
                var itisImage = false;
                $.each(value,function(newkey,newvalue){
                    i++;
                    if(i == 2){
                        $.each(value["answer"]["type"],function(keys,values){
                            if(keys == "image"){
                                itisImage = true;
                            }
                        })
                    }
                });
                if(i == 2 && itisImage){
                    answersources[key]=imageUrl(value["answer"]["type"]["image"]["value"]);
                }
            }
        });
    }

    /*For positioning Answers at random position use the following array */
    function answerfinalPosition(){
        var i=0;
        $.each(forgettingBox,function(key,value){
            answerFinalPosition[key] = {};
            answerFinalPosition[key]["x"] = answerbox_position[key].x;
            answerFinalPosition[key]["y"] = answerbox_position[key].y;
            forScramble[i]=key;
            i++;
        });
    };

    function scrambledanswerFinalPosition(){
        var k=0;
        $.each(forgettingBox,function(key,value){
            var rand = forScramble[Math.floor(Math.random() * forScramble.length)];
            scrambledArray[k] = rand;
            remove(forScramble,rand);
            k++;
        });
    };

    function remove(array,value){
        var index = array.indexOf(value);
        if(index != -1) {
            array.splice(index, 1);
        }
    }

    function loadImages(sources, callback) {
        var images = {};
        var answerimages={};
        var loadedImages = 0;
        var answerloadedImages = 0;
        var numImages = 0;
        var answerNumImages = 0;
        for(var src in sources) {
            numImages++;
        }
        for(var src in answersources){
            answerNumImages++;
        }

        for(var src in sources) {
            images[src] = new Image();
            images[src].onload = function() {
                if(++loadedImages >= numImages) {
                    $(".modal-content").scrollTop(700);
                    if(answerNumImages == 0){
                        callback(images,answerimages);
                    }
                }
            };
            images[src].src = sources[src];
        }
        for(var src in answersources) {
            answerimages[src] = new Image();
            answerimages[src].onload = function() {
                if(++answerloadedImages >= answerNumImages) {
                    callback(images,answerimages);
                }
            };
            answerimages[src].src = answersources[src];
        }
        if(numImages == 0 && answerNumImages == 0){
            callback(images,answerimages);
        }
    }

    function loadPreview(images,answerimages){
        var morethanthree=0;
        for(var key in forgettingBox) {
            morethanthree++;
            answerPositionforChecking[key] = {};
            answerPositionforChecking[key]["isNearOutline"] = false;
        }
        if(!parentisModal()){
            $("#preview-container").css({"height":$(window).height() - 95});
            $(".for-preview").find(".preview-row").css({"margin":"0px","width":"100%"});
            $(".for-preview").find(".preview-container").css({"width":"100%"});
            $(".for-preview").find("#preview-container").css({"width": "100%"});
            $(".for-preview").find(".preview-content").css({"width": "100%"});
            $(".for-preview").find(".konvajs-content").css({"margin-left":"auto","margin-right":"auto","width":"1024px"});
        }else{
            stageWidth = 970;
            questionX = 120;
            boxX = 330;
            $(".for-preview").css({"height":"700px"});
            $(".konvajs-content").css({"width":"970px","height":"665px"});
            //$(".preview-content").css({"border": "1px solid rgb(57, 177, 141)"});
            $("#preview-container").css({"width": "1020px"});
            $(".preview-row").css({"margin":"0px","width":"1024px"});
        }
        /*Below function is for scroll to apper only when more than 3 rows are filled */
        scrollAppear();

        var stage = new Konva.Stage({
            container: 'preview-container',
            width: stageWidth,
            height : stageHeight
        });
        var answerLayer = new Konva.Layer();
//         if(morethanthree > 3 && !parentisModal() ){
//             var rect_back = new Konva.Rect({
//                 x : -10,
//                 y: -115,
//                 width:stageWidth,
//                 height:10000,
//                 draggable: true,
//                 fill : "white",
//                 name : "rect_back",
//                 dragBoundFunc: function(pos) {
//                     var newY;
//                     var newX;
//                     if(pos.y > -10 ){
//                         newY = - 115;
//                     }else if(pos.y < -9000){
//                         newY = -230;
//                     }else{
//                         newY = pos.y;
//                     }
//                     if(pos.x > -10 ){
//                         newX = -10;
//                     }else if(pos.x < -10){
//                         newX = -10;
//                     }else{
//                         newX = pos.x;
//                     }
//                     return {
//                         x: newX,
//                         y: newY
//                     };
//                 }
//             });
//             rect_back.on('touchstart', function() {
//                 backrectY = rect_back.getY();
//                 console.log("touched screen");
//             });
//             rect_back.on('dragmove', function() {
// //				console.log("dragmove : "+rect_back.getY());
//                 backScrollFunction(rect_back);
//                 answerLayer.draw();
//             });
//             answerLayer.add(rect_back);
//         }
        var answerShapes = [];
        $.each(forgettingBox,function(key,value){
            var forDropTextChangeKey = key; /*This is used in dropend function */
            var questionIsImage = false;
            var answerIsImage = false;
            // anonymous function to induce scope
            (function() {
                var privKey = key;
                var ques = questions_position[key];
                $.each(json[key],function(newkey,newvalue){
                    $.each(json[key]["question"]["type"],function(typekeys,typevalues){
                        if(typekeys == "image"){
                            questionIsImage = true;
                        }else if(typekeys == "text"){
                            questionIsImage = false;
                        }
                    });
                    $.each(json[key]["answer"]["type"],function(typekeys,typevalues){
                        if(typekeys == "image"){
                            answerIsImage = true;
                        }else if(typekeys == "text"){
                            answerIsImage = false;
                        }
                    })
                })
                var out = answerbox_position[key];
                var lines = new Konva.Line({
                    points: [out.x, out.y+57, out.x-150, out.y+57],
                    stroke: strokecolor[key]
                });
                answerLayer.add(lines);
                var quesnumber = new Konva.Text({
                    x : ques.x - 60,
                    y : ques.y+35,
                    text : parseInt(key)+1+".",
                    fontSize : 14,
                    fill : "red",
                    padding : 2
                });
                answerLayer.add(quesnumber);
                /*For creating the question part in the konvas */
                if(questionIsImage){
                    question = new Konva.Image({
                        image : images[key],
                        x : ques.x,
                        y: ques.y,
                        width:imageWidth,
                        height:imageHeight,
                        name:"question-"+key,
                        stroke:imageBorder,
                        strokeWidth:2
                    });
                    var questionImage_back = new Konva.Rect({
                        x : ques.x,
                        y: ques.y,
                        width:imageWidth,
                        height:imageHeight,
                        fill : "white"
                    })
                    answerLayer.add(questionImage_back);
                    answerLayer.add(question);
                }else{       /*If question is Text */
                    var textQuestion = new Konva.Text({
                        x: 3,
                        y: 25,
                        text: json[key]["question"]["type"]["text"]["value"],
                        fontSize: 14,
                        fontFamily: 'Arial',
                        fill:"white",
                        width:145,
                        padding : 10
                    });
                    var text_question_box = new Konva.Rect({
                        x: 3,
                        y: 25,
                        width: 145,
                        height: textQuestion.getHeight(),
                        cornerRadius: 5,
                        fill: strokecolor[key]
                    });
                    var fortextposition =(textQuestion.getHeight() - 34)/2;
                    var text_question = new Konva.Group({
                        x: ques.x-40,
                        y: ques.y + 3 - fortextposition,
                        name:"question-"+key
                    });
                    text_question.add(text_question_box);
                    text_question.add(textQuestion);
                    answerLayer.add(text_question);
                }
                var answY = questions_position[scrambledArray[parseInt(key,10)]]["y"];
                if(answerIsImage){
                    var answer = new Konva.Group({
                        x: ques.x+answerXoffset,
                        y: answY,
                        draggable: true,
                        width:imageWidth,
                        height:imageHeight,
                        name:"answer-"+key,
                        dragBoundFunc: function(pos) {
                            var newY;
                            var newX;
                            if(pos.y > stageHeight - 110 ){
                                newY = stageHeight - 110;
                            }else if(pos.y < 10){
                                newY = 10;
                            }else{
                                newY = pos.y;
                            }
                            if(pos.x > stageWidth - 100 ){
                                newX = stageWidth - 100;
                            }else if(pos.x < 10){
                                newX = 10;
                            }else{
                                newX = pos.x;
                            }
                            return {
                                x: newX,
                                y: newY
                            };
                        }
                    })
                    var answerImage = new Konva.Image({
                        image: answerimages[key],
                        x: 0,
                        y: 0,
                        width:imageWidth,
                        height:imageHeight,
                        stroke:imageBorder
                    });
                    var answerImage_back = new Konva.Rect({
                        x: 0,
                        y: 0,
                        width:imageWidth,
                        height:imageHeight,
                        fill : "white"
                    })

                    answer.on('dragstart', function() {
                        this.moveToTop();
                        answerLayer.draw();
                        var values = [];
                        values = isNearOutline(answer);
                        if(values[0]){
                            var boxText= answerLayer.get("#text-"+values[3]);
                            boxText.setText("Drop the Answer Here");
                            answerLayer.draw();
                        }
                        forDropTextChangeKey = getBoxKey(answer);/*To get The Key of the dropbox postion where the answer image is present*/
                        needHelpClicked = 0;
                    });
                    /*
                     * check if answer is in the right spot and
                     * snap into place if it is
                     */
                    answer.on('dragend', function() {
                        var answer_names = answer['attrs'].name;
                        var answer_name = answer_names.split("-")[1];
                        var values = isNearOutline(answer); /*output array is[true/false, X-position, Y-position, box-key]*/
                        if(values[0]) {
                            answerPositionforChecking[answer_name]["isNearOutline"] = true;
                            answer.position({
                                x : values[1]+answerInBoxOffsetX,
                                y : values[2]+answerInBoxOffsetY
                            });
                            var myText= answerLayer.get("#text-"+values[3]);  /*To get The dropbox postion where the answer image is left */
                            myText.setText(" ");  			/* for changing drop text here */
                            answerLayer.draw();
                        }else{
                            answerPositionforChecking[answer_name]["isNearOutline"] = false;
                            /*When the answer Image is not in the box,then for movin back to the original position */
                            answer.position({
                                x : questions_position[answer_name].x + answerXoffset,
                                y : answY
                            });
                            var correct_icon = answerLayer.find(".correct-"+forDropTextChangeKey);
                            var wrong_icon = answerLayer.find(".wrong-"+forDropTextChangeKey);
                            correct_icon.hide();
                            wrong_icon.hide();
                            answerLayer.draw();
                        }
                        answerFinalPosition[answer_name] = {};
                        answerFinalPosition[answer_name]["x"] = this.getPosition().x;
                        answerFinalPosition[answer_name]["y"] = this.getPosition().y;
                        verifyAnswerAlreadyPresent(answerLayer,answer_name,answerInBoxTextOffsetY); /*To verify whether another answer is prent in answer box */
                    });

                    answer.on('mouseover', function() {
                        document.body.style.cursor = 'pointer';
                    });
                    answer.on('mouseout', function() {
                        answerLayer.draw();
                        document.body.style.cursor = 'default';
                    });
                    answer.on('dragmove', function() {
                        scrollFunction(answer);
                        answerLayer.draw();
                    });
                    answer.add(answerImage_back);
                    answer.add(answerImage);
                    answerLayer.add(answer);
                    answerShapes.push(answer);
                }else{ 			/*If answer is Text */
                    var answerText  = json[key]["answer"]["type"]["text"]["value"];
                    var answerInBoxTextOffsetY  = 2;
//					/* See Below(at the shape definition and dragend function) to know about the variables defined above*/
                    var textAnswer = new Konva.Text({
                        x: 3,
                        y: 27,
                        text: answerText,
                        fontSize: 14,
                        fontFamily: 'Arial',
                        fill:"white",
                        width:145,
                        padding : 10
                    });
                    var text_answer_box = new Konva.Rect({
                        x: 3,
                        y: 27,
                        width: 145,
                        height: textAnswer.getHeight(),
                        cornerRadius: 5,
                        fill: strokecolor[scrambledArray[parseInt(key,10)]],
                        name : "answer-text-box-"+key
                    });
                    var fortextanswerposition =(textAnswer.getHeight() - 34)/2;
                    var text_answer = new Konva.Group({
                        x: ques.x+answerXoffset-30,
                        y: answY + 3 - fortextanswerposition,
                        name:"answer-"+key,
                        draggable:true,
                        dragBoundFunc: function(pos) {
                            var newY;
                            var newX;
                            if(pos.y > stageHeight - 60 ){
                                newY = stageHeight - 60;
                            }else if(pos.y < 0){
                                newY = 0;
                            }else{
                                newY = pos.y;
                            }
                            if(pos.x > stageWidth - 160 ){
                                newX = stageWidth - 160;
                            }else if(pos.x < 20){
                                newX = 20;
                            }else{
                                newX = pos.x;
                            }
                            return {
                                x: newX,
                                y: newY
                            };
                        }
                    });

                    text_answer.on('dragstart', function() {
                        this.moveToTop();
                        answerLayer.draw();
                        var values = [];
                        values = isNearOutline(text_answer);
                        if(values[0]){
                            var boxText= answerLayer.get("#text-"+values[3]);
                            boxText.setText("Drop the Answer Here");
                            answerLayer.draw();
                        }
                        forDropTextChangeKey = getBoxKey(text_answer);   /*To get The Key of the dropbox postion where the answer text is present*/
                        needHelpClicked = 0;
                    });
                    /*
                     * check if answer is in the right spot and
                     * snap into place if it is
                     */
                    text_answer.on('dragend', function() {
                        var textboxposition = (text_answer.children["0"].getHeight() -34)/2;
                        var answer_names =  text_answer['attrs'].name;
                        var answer_name = answer_names.split("-")[1];
                        var values = isNearOutline(text_answer); /*output array is[true/false, X-position, Y-position, box-key]*/
                        if(values[0]) {
                            answerPositionforChecking[answer_name]["isNearOutline"] = true;
                            text_answer.position({
                                x : values[1] + answerInBoxOffsetX - 15, /*change answerFinalPosition[answer_name]["x"] below according to this value */
                                y : values[2]+answerInBoxOffsetY + answerInBoxTextOffsetY - textboxposition   /*change answerFinalPosition[answer_name]["y"] below according to this value */
                            });

                            var myText= answerLayer.get("#text-"+values[3]);  /*To get The dropbox postion where the answer image is left */
                            myText.setText(" ");  			/* for changing drop text here */
                            answerLayer.draw();
                        }else{
                            answerPositionforChecking[answer_name]["isNearOutline"] = false;
                            /*When the answer Image is not in the box,then for moving back to the original position */
                            text_answer.position({
                                x : questions_position[answer_name].x + answerXoffset - 30,
                                y : answY + 3 - textboxposition
                            });
                            var correct_icon = answerLayer.find(".correct-"+forDropTextChangeKey);
                            var wrong_icon = answerLayer.find(".wrong-"+forDropTextChangeKey);
                            correct_icon.hide();
                            wrong_icon.hide();
                            answerLayer.draw();
                        }
                        answerFinalPosition[answer_name] = {};
                        answerFinalPosition[answer_name]["x"] = this.getPosition().x + 15 ; /* +10, - 4 will get from above text_answer.postion values at line 501,502 */
                        answerFinalPosition[answer_name]["y"] = this.getPosition().y - answerInBoxTextOffsetY + textboxposition;
                        verifyAnswerAlreadyPresent(answerLayer,answer_name,answerInBoxTextOffsetY); /*To verify whether another answer is prent in answer box */
                    });
                    text_answer.on('mouseover', function() {
                        document.body.style.cursor = 'pointer';
                    });
                    text_answer.on("touchstart",function(){
                        console.log("touched");
                    })
                    text_answer.on('mouseout', function() {
                        document.body.style.cursor = 'default';
                    });

                    text_answer.on('dragmove', function() {
                        document.body.style.cursor = 'pointer';
                        scrollFunction(text_answer);
                    });
                    text_answer.add(text_answer_box);
                    text_answer.add(textAnswer);
                    answerLayer.add(text_answer);
                    answerShapes.push(text_answer);
                }
            })();
        });
        // create boxoutline outlines
        $.each(forgettingBox,function(key,value){
            var out = answerbox_position[key];
            var boxoutline = boxOutLine(out.x,out.y,answerLayer,key); /*for drawing the answer Boxes*/
            var boxtext =  boxText(out.x,out.y,answerLayer,key);
            var correctIcon = CorrectIcon(answerLayer,key);
            var wrongIcon  =  WrongIcon(answerLayer,key);
            answerLayer.add(boxoutline);
            answerLayer.add(boxtext);
            answerLayer.add(correctIcon);
            answerLayer.add(wrongIcon);
        });
        document.getElementById("need-help").addEventListener('click',function(){
            needHelpClicked = 1;
            needHelp(answerLayer);
        },false);
        document.getElementById("check-answer").addEventListener('click', function() {
            wrongAnswerNum = 0;
            if(needHelpClicked  == 0 && atleastOneElemntIsInBox()){
                verifyAnswers(answerLayer);
                forAudio();
            }
        }, false);
        document.getElementById("scroll-top").addEventListener('click', function() {
            scrollTopButtonFunction(morethanthree);
        }, false);
        document.getElementById("scroll-bottom").addEventListener('click', function() {
            scrollDownButtonFunction(morethanthree);
        }, false);
        stage.add(answerLayer);
    };

    function verifyAnswers(layer){
        $.each(forgettingBox,function(key,value){
            var correct_icon = layer.find(".correct-"+key);
            var wrong_icon = layer.find(".wrong-"+key);
            correct_icon.hide();
            wrong_icon.hide();
            if(isInCorrectPosition(key)){
                correct_icon.show();
                wrong_icon.hide();
                layer.draw();
            }else{
                wrongAnswerNum++;
                wrong_icon.show();
                correct_icon.hide();
                layer.draw();
            }
        });
    }

    function forAudio(){
        if(wrongAnswerNum == 0){
            var audioElement = document.createElement('audio');
            var audio = document.getElementById('excellent');
            audio.play();
        }else{
            var audio = document.getElementById('tryagain');
            audio.play();
        }
    }

    /*To verify whether another answer is alredy present in box after drag end */
    function verifyAnswerAlreadyPresent(layer,presentDragKey,answerInBoxTextOffsetY){
        $.each(answerFinalPosition,function(key,value){
            $.each(json[key]["answer"]['type'],function(type,typeHead){
                if(presentDragKey != key && value["x"] == answerFinalPosition[presentDragKey]["x"] && value["y"] == answerFinalPosition[presentDragKey]["y"]){
                    var alreadyPresentAnswer = layer.find(".answer-"+key);
                    if(type == "text"){
                        var textboxposition = (alreadyPresentAnswer["0"].children["0"].getHeight() -34)/2;
                        alreadyPresentAnswer.position({
                            x : questions_position[key].x + answerXoffset - 30,
                            y : questions_position[scrambledArray[parseInt(key,10)]]["y"] + 3 - textboxposition
                        })
                        layer.draw();
                        answerFinalPosition[key]["x"] = alreadyPresentAnswer.getPosition().x +15 ;
                        answerFinalPosition[key]["y"] = alreadyPresentAnswer.getPosition().y - answerInBoxTextOffsetY + textboxposition;
                    }else if(type == "image"){
                        alreadyPresentAnswer.position({
                            x : questions_position[key].x + answerXoffset ,
                            y : questions_position[scrambledArray[parseInt(key,10)]]["y"]
                        })
                        layer.draw();
                        answerFinalPosition[key]["x"] = alreadyPresentAnswer.getPosition().x  ;
                        answerFinalPosition[key]["y"] = alreadyPresentAnswer.getPosition().y  ;
                    }
                }
            })
        })
    };

    function needHelp(layer){
        $.each(forgettingBox,function(key,value){
            $.each(json[key]["answer"]['type'],function(type,typeHead){
                if(type == "text"){
                    var answerInBoxTextOffsetY  = 2;
                    var textAnswerGroup = layer.find(".answer-"+key);
                    var textboxposition = (textAnswerGroup["0"].children["0"].getHeight() -34)/2;
                    textAnswerGroup.position({
                        x : answerbox_position[key].x + answerInBoxOffsetX - 15,
                        y : answerbox_position[key].y+answerInBoxOffsetY + answerInBoxTextOffsetY - textboxposition
                    });
                    textAnswerGroup.setZIndex(99);
                    var myText= layer.get("#text-"+key);
                    myText.setText(" ");
                    layer.draw();
                }else if(type  == "image"){
                    var imageAnswerGroup = layer.find(".answer-"+key);
                    imageAnswerGroup.position({
                        x : answerbox_position[key].x +answerInBoxOffsetX,
                        y : answerbox_position[key].y +answerInBoxOffsetY
                    });
                    imageAnswerGroup.setZIndex(99);
                    var myText= layer.get("#text-"+key);
                    myText.setText(" ");
                    layer.draw();
                }
            })
            var correct_icon = layer.find(".correct-"+key);
            var wrong_icon = layer.find(".wrong-"+key);
            wrong_icon.hide();
            correct_icon.hide();
            layer.draw();
        });
        /*Below is to git correct icon when check answers is clicked after need help is clicked */
        document.getElementById("check-answer").addEventListener('click', function() {
            if(needHelpClicked == 1){
                $.each(forgettingBox,function(key,value){
                    var correct_icon = layer.find(".correct-"+key);
                    var wrong_icon = layer.find(".wrong-"+key);
                    correct_icon.hide();
                    wrong_icon.hide();
                    layer.draw();
                });
            }
        }, false);
    };

    function CorrectIcon(layer,key){
        var imageObj = new Image();
        var correctIcon =  new Konva.Image({
            x: answerbox_position[key].x - 5,
            y: answerbox_position[key].y -5,
            draggable: false,
            image: imageObj,
            width: 30,
            height: 30,
            name:"correct-"+key,
            visible: false
        });
        imageObj.src = "/assets/activities/correct.png";
        return correctIcon;
    }

    function WrongIcon(layer,key){
        var imageObj = new Image();
        var wrongIcon = new Konva.Image({
            x: answerbox_position[key].x - 5,
            y: answerbox_position[key].y - 5,
            draggable: false,
            image: imageObj,
            width: 30,
            height: 30,
            name:'wrong-'+key,
            visible: false

        });
        imageObj.src = "/assets/activities/cancel.png";
        return wrongIcon;
    }

    function scrollAppear(){
        var i=0;
        for(var key in forgettingBox) {
            i++;
        }
        var scrollHeight = 550;
        if(i <= 3){
            $("#preview-container").removeClass("preview-container-scroll");
            $("#scroll-top").css({"visibility":"hidden"});
            $("#scroll-bottom").css({"visibility":"hidden"});
        }else if(((i == 4 && $(window).height() < 620) || (i== 5 && $(window).height() < 755) || ( i == 6 && $(window).height() < 900)) && !(parentisModal())){
            $(".for-preview").find(".preview-content").css({"position":" relative"});
            if(i ==4){
                $("#preview-container").addClass("preview-container-scroll");
                stageHeight = scrollHeight + 50;
            }else if(i ==5){
                $("#preview-container").addClass("preview-container-scroll");
                stageHeight = scrollHeight + 140;
            }else if(i == 6){
                $("#preview-container").addClass("preview-container-scroll");
                stageHeight = scrollHeight + 265;
            }
        }else if(i == 4 && $(window).height() > 620 && !(parentisModal())){
            stageHeight = 620;
            $(".for-preview").css({"position":" relative"});
            $("#scroll-top").css({"visibility":"hidden"});
            $("#scroll-bottom").css({"visibility":"hidden"});
        }else if(i== 5 && $(window).height() > 755 && !(parentisModal())){
            stageHeight = 730;
            $(".for-preview").css({"position":" relative"});
            $("#scroll-top").css({"visibility":"hidden"});
            $("#scroll-bottom").css({"visibility":"hidden"});
        }else if(i == 6 && $(window).height() > 900 && !(parentisModal())){
            stageHeight = 810;
            $(".for-preview").css({"position":" relative"});
            $("#scroll-top").css({"visibility":"hidden"});
            $("#scroll-bottom").css({"visibility":"hidden"});
        }else if(i == 4 && parentisModal()){
            $("#preview-container").addClass("preview-container-scroll");
            stageHeight = scrollHeight + 50;
        }else if(i == 5 && parentisModal()){
            $("#preview-container").addClass("preview-container-scroll");
            stageHeight = scrollHeight + 170;
        }else if(i == 6 && parentisModal()){
            $("#preview-container").addClass("preview-container-scroll");
            stageHeight = scrollHeight + 265;
        }
    }
    function scrollDownButtonFunction(i){
        var scrollbottom = 0;
        if($(window).height() <= 620){
            if(i == 4){
                scrollbottom = 190;
            }else if(i == 5){
                scrollbottom = 390;
            }else if(i == 6){
                scrollbottom = 410;
            }
        }else if($(window).height() <= 755){
            if(i == 5){
                scrollbottom = 155;
            }else if(i == 6){
                scrollbottom = 300;
            }
        }else if($(window).height() <= 900){
            if(i == 6){
                scrollbottom = 300;
            }
        }
        $("#preview-container").scrollTop(scrollbottom);
    }
    function scrollTopButtonFunction(i){
        var scrollTop = 0;
        if($(window).height() <= 620){
            if(i == 4){
                scrollTop = -65;
            }else if(i == 5){
                scrollTop = -155;
            }else if(i == 6){
                scrollTop= -285;
            }
        }else if($(window).height() <= 715){
            if(i == 5){
                scrollTop = -155;
            }else if(i == 6){
                scrollTop = -265;
            }
        }else if($(window).height() <= 900){
            if(i == 6){
                scrollTop = -265;
            }
        }
        $("#preview-container").scrollTop(scrollTop);
    }
    function scrollFunction(answer){
        if(answer.getY() >= $("#preview-container").outerHeight(true) - 100 ){
            var scrollbottom = $("#preview-container").scrollTop() + 20 ;
            $("#preview-container").scrollTop(scrollbottom);
        }else if(answer.getY()-$("#preview-container").scrollTop() <= 20){
            var scrolltop = $("#preview-container").scrollTop() -20;
            $("#preview-container").scrollTop(scrolltop);
        }
    }

    // function backScrollFunction(rect_back){
    //     if(backrectY - rect_back.getY() > 0 && !(rect_back.getY() == -115)){
    //         var scrollBottom = $("#preview-container").scrollTop() + (backrectY - rect_back.getY());
    //         $("#preview-container").scrollTop(scrollBottom);
    //     }else if(backrectY - rect_back.getY() < 0 && !(rect_back.getY() == -230)){
    //         var scrollTop =  $("#preview-container").scrollTop() + (backrectY - rect_back.getY());
    //         $("#preview-container").scrollTop(scrollTop);
    //     }
    // }

    function isInCorrectPosition(key){
        var ax = answerFinalPosition[key]["x"];
        var ay = answerFinalPosition[key]["y"];
        var answerBoxX = answerbox_position[key]["x"];
        var answerBoxY = answerbox_position[key]["y"];
        var result = false;
        if(((ax - answerBoxX) == answerInBoxOffsetX && (ay - answerBoxY) == answerInBoxOffsetY)){
            result = true;
        }
        return result;
    }

    function getBoxKey(answer){
        var values = isNearOutline(answer);
        var key = " ";
        if(values[0]){
            key = values[3];
        }
        return key;
    }

    function boxOutLine(outx,outy,layer,key){
        var boxoutLine = new Konva.Rect({
            x: outx,
            y: outy,
            width : 250,
            height : 115,
            fill: 'white',
            cornerRadius: 20,
            name : key,
            stroke: strokecolor[key],
            strokeWidth: 2,
            strokeWidth:2,
            shadowColor:shadowcolor ,
            shadowBlur: shadowblur,
            shadowOffset: {x : shadowOffsetX, y : shadowOffsetY},
            shadowOpacity: shadowopacity
        });
        return boxoutLine;
    }

    function boxText(outx,outy,layer,key){
        var droptext = new Konva.Text({
            x: outx+45,
            y: outy+50,
            id : "text-"+key,
            text: 'Drop the Answer Here',
            fontSize: 16,
            fontFamily: 'Arial',
            fill:'#9CA3A1',
            width:200
        });
        return droptext;
    }

    function atleastOneElemntIsInBox(){
        var moved = false;
        $.each(answerPositionforChecking,function(key,value){
            if(value["isNearOutline"] == true){
                moved = true;
                return false;
            }
        });
        return moved;
    }


    function isNearOutline(answer) {
        var a = answer;
        var ax = a.getX();
        var ay = a.getY();
        var answer_name =  answer['attrs'].name;
        var results=[];
        results[0] = false;
        $.each(forgettingBox,function(key,value){
            if(ax > answerbox_position[key].x - 90 && ax < answerbox_position[key].x + 250 && ay > answerbox_position[key].y - 42 && ay < answerbox_position[key].y + 82 ) {
                result = true;
                results[0] = true;
                results[1] = answerbox_position[key].x;
                results[2] = answerbox_position[key].y;
                results[3] = key;
                return false;
            }
            else {
                results[0] = false;
                results[1] = "Drop the Answer Here";
            }
        });

        return results;
    }

    function isNumericKey(value){
        var numericKeys = false;

        if(!(isNaN(parseInt(value,10)))){
            numericKeys = true;
        }
        return numericKeys;
    }
    function imageUrl(imageName){
        var url = prefix + imageName;
        return url;
    }
    function parentisModal(){
        var isModal = false;
        var parentId = $(".preview-content").parent().attr('id');
        if(parentId == "modal-body-preview"){
            isModal = true;
        }
        return isModal;
    }
    $(function() {
        FastClick.attach(document.body);
    });
};