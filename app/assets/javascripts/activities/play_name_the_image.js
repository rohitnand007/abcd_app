// plugin for preview of naming the template
$.fn.Play_name_the_image = function(json,prefix) {
    var naming = {
        minwidth_tag: 176,
        maxwidth_tag:300,
        minheight_tag: 40,
        nametagImg_w: 100,
        nametagImg_h: 110,
        margin_left: parseInt($(this).css('margin-left')),
        name_of_content: ''
    };

    if(json['name']){
        naming.name_of_content = json['name'];
    }
    var logo;
    if(json['logo'] =="ignitor_logo.png"){
        logo = "/assets/activities/"+ json['logo'];
    }else{
        logo = addPrefix(json['logo']);
    }

    var global_droppableTarget;
    var imageObjects = [];
    $(this).empty();
    $(this).append('<div class="container content-of-preview" style="width:100%">\
                        <div class="row">\
                            <div><span class="col-sm-6 active activeprev content-name">'+ naming.name_of_content +'</span></div>\
                            <div class="check_answers"><span class="col-sm-2 prev"><img src="/assets/activities/check-mark.png" class="preview-glyph">Check My Answer</span>\
                            </div>\
                            <div class="need_help"><span class="col-sm-2 prev"><img src="/assets/activities/information-button.png" class="preview-glyph">Need Help</span>\
                            </div>\
                            <div class="reset_the_question"><span class="col-sm-2 prev" style="border-right:0px"><img src="/assets/activities/reload.png" class="preview-glyph">Reset the Questions</span>\
                        </div>\
                        <div class="row" id="container_for_preview">\
                        <div  class="description_canvas col-xs-9"  style="display:block"><div id="previewDescription"></div><div id="previewCanvas"></div></div><div id="previewOptions"  style="display:block;float:right"><p class="optional-answers">Your Optional Answers</p><ul id="optionList"></ul></div>\
                        </div>\
                    </div>\
                            <audio id="excellent" src="/assets/audio/Excellent.wav"></audio><audio id="tryagain" src="/assets/audio/Please_try_again.wav"></audio>');
    if (json['instructions'] != undefined) {
        $('#previewDescription').empty().append('<h3 class="description-heading" style="margin-top:0px">Instructions for the Activity:</h3><p class="description_text">' + json['instructions'] + '</p>');
    } else {
        $('#previewDescription').empty();
    }
    var options = shuffle(json['alloptions']);
    for (i = 0; i < options.length; i++) {
        if (options[i]['image']) {
            $('#optionList').append('<li class="all_option_image drag_options"><img src="' + addPrefix(options[i]['image']) + '" class="image-option"></li>');
        } else {
            $('#optionList').append('<li class="all_option_text drag_options"><span style="text-align:center;">' + options[i]['text'] + '</span></li>');
        }
    }
    var previewStage = Konva.Node.create(json['stage'], 'previewCanvas');
    var lay = new Konva.Layer();
    previewStage.add(lay);
    previewStage.draw();
    previewStage.find('.answer').remove();
    previewStage.find('Group').setDraggable(false);
    previewStage.find('.delete').remove();
    previewStage.find('.edit').remove();
    previewStage.find('.editButton').remove();
    previewStage.find('Image').setDraggable(false);
    previewStage.find('.point').setDraggable(false);
    previewStage.find('.topLeft').hide();
    previewStage.find('.topRight').hide();
    previewStage.find('.bottomLeft').hide();
    previewStage.find('.bottomRight').hide();
    previewStage.find('.bottom').hide();
    previewStage.find('.tooltip').remove();
    var images = previewStage.find('Image');
    var imagesOK = 0;
    var imgs = [];

    loadAllImages(start);

    function loadAllImages(callback) {
        for (var i = 0; i < images.length; i++) {
            var img = new Image();
            imgs.push(img);
            img.onload = function() {
                imagesOK++;
                if (imagesOK >= images.length) {
                    callback();
                }
            };
            img.src = addPrefix(images[i]['attrs']['src']);
        }
    }

    function start() {
        for (var i = 0; i < imgs.length; i++) {
            images[i].image(imgs[i]);
            previewStage.draw();
        }
    }

    function resetAreaTags(allDroppableTargets) {
        for (i = 0; i < allDroppableTargets.length; i++) {
            if (allDroppableTargets[i]['children'][0]['className'] !== 'Line') {
                allDroppableTargets[i]['children'][0].strokeEnabled(false);
                allDroppableTargets[i]['children'][0].fill('#FFFBE8');
                allDroppableTargets[i].hide();
            }
        }
        previewStage.draw();
    }

    resetAreaTags(previewStage.find('Group'));

    function resetNameTags(dropGroups) {
        for (i = 0; i < dropGroups.length; i++) {
            if (dropGroups[i]['children'][0]['className'] == "Line") {
                var newstartpoints;
                var deco = dropGroups[i].find('.deco')[0];
                var points = dropGroups[i]['children'][0].points();
                dropGroups[i]['children'][0].fill('');
                var startpoints = dropGroups[i].find('.connecting')[0].points();
                dropGroups[i].find('.right').remove();
                dropGroups[i].find('.wrong').remove();
                global_droppableTarget = dropGroups[i];
                var x = global_droppableTarget.x();
                if (points[2] > points[0]) {
                    if (points[0] + global_droppableTarget.x() + naming.minwidth_tag > previewStage.width()) {
                        newpoints = [previewStage.width() - naming.minwidth_tag - x, points[1], previewStage.width() - x, points[1], previewStage.width() - x, points[1] + naming.minheight_tag, previewStage.width() - naming.minwidth_tag - x, points[1] + naming.minheight_tag, previewStage.width() - naming.minwidth_tag - 25 - x, points[1] + naming.minheight_tag / 2, previewStage.width() - x - naming.minwidth_tag, points[1]];
                    } else {
                        var newpoints = [points[0], points[1], (points[0] + naming.minwidth_tag), points[1], (points[0] + naming.minwidth_tag), (points[1] + naming.minheight_tag), points[0], (points[1] + naming.minheight_tag), points[0] - 25, points[1] + naming.minheight_tag / 2, points[0], points[1]];
                    }
                    deco.x(newpoints[0] - 12);
                    deco.y(newpoints[1] + 20);
                    newstartpoints = [newpoints[0] - 25, newpoints[1] + naming.minheight_tag / 2, startpoints[2], startpoints[3]];
                } else {
                    if (-points[2] + global_droppableTarget.x() < 0) {
                        newpoints = [points[2] + naming.minwidth_tag, points[1], points[2], points[1], points[2], points[1] + naming.minheight_tag, points[2] + naming.minwidth_tag, points[1] + naming.minheight_tag, points[2] + naming.minwidth_tag + 25, points[1] + naming.minheight_tag / 2, points[2] + naming.minwidth_tag, points[1]];
                    } else {
                        var newpoints = [points[0], points[1], (points[0] - naming.minwidth_tag), points[1], (points[0] - naming.minwidth_tag), (points[1] + naming.minheight_tag), points[0], (points[1] + naming.minheight_tag), points[0] + 25, points[1] + naming.minheight_tag / 2, points[0], points[1]];
                    }
                    deco.x(newpoints[0] + 13);
                    deco.y(newpoints[1] + 20);
                    newstartpoints = [newpoints[0] + 25, newpoints[1] + 20, startpoints[2], startpoints[3]];
                }
                dropGroups[i].find('.connecting')[0].points(newstartpoints);
                dropGroups[i]['children'][0].points(newpoints);
                previewStage.draw();
            }
        }
    }

    resetNameTags(previewStage.find('Group'));

    $('.drag_options').draggable({
        helper: "clone",
        cursor: 'pointer',
        containment: '#container_for_preview',
        //revert: 'invalid',
        drag: function(e, ui) {
            var divX = parseInt($('.ui-draggable-dragging').css('left'));
            var divY = parseInt($('.ui-draggable-dragging').css('top'));
            $('.ui-draggable-dragging').attr('word-break','break-all');
            if (divX > 0 && divX < ($('#previewCanvas').outerWidth(true) - $('.ui-draggable-dragging').outerWidth(true) + naming.margin_left) && divY <= ($('.prev').outerHeight(true)) + 15) {
                var scroll = $('.description_canvas').scrollTop() - 10;
                if (scroll > 0) {
                    $('.description_canvas').scrollTop(scroll);
                } else {
                    $('.description_canvas').scrollTop(0);
                }
            } else if (divX > 0 && divX < ($('#previewCanvas').outerWidth(true) - $('.ui-draggable-dragging').outerWidth(true)) && divY >= 510) {
                var scroll = $('.description_canvas').scrollTop() + 10;
                $('.description_canvas').scrollTop(scroll);
            }
            optionOnDrag(e, ui, this);
        },
        stop: function(e) {
            optionOnDrop(e, this);
        }
    });

    function dropCheck(e, draggable, droppableGroup) {
        var scrollValue = $('.description_canvas').scrollTop() - ($('#previewCanvas').offset().top + $('.description_canvas').scrollTop() - $('#container_for_preview').offset().top);
        var mouse = {
            x: e.pageX - $('#container_for_preview').offset().left,
            y: e.pageY - $('#container_for_preview').offset().top
        };
        if (droppableGroup.find('.answer').length == 0) {
            var dragX = parseInt(draggable.css('left')) + 5 - naming.margin_left;
            var dragY = parseInt(draggable.css('top')) - 35;
            var dragW = draggable.width();
            var dragH = draggable.height() + 5;
            if (droppableGroup['children'][0]['className'] == "Rect") {
                var dropX = positionX(droppableGroup);
                var dropY = positionY(droppableGroup) - scrollValue;
                var dropW = droppableGroup['children'][0].width();
                var dropH = droppableGroup['children'][0].height();
                if ((dropX < dragX && dropY < dragY && (dropX + dropW) > (dragX) && (dropY + dropH) > (dragY)) || (dropX < (dragX + dragW) && dropY < dragY && (dropX + dropW) > (dragX + dragW) && (dropY + dropH) > (dragY)) || (dropX < (dragX + dragW) && dropY < (dragY + dragH) && (dropX + dropW) > (dragX + dragW) && (dropY + dropH) > (dragY + dragH)) || (dropX < (dragX) && dropY < (dragY + dragH) && (dropX + dropW) > (dragX) && (dropY + dropH) > (dragY + dragH)) || (dragX < dropX && dragY < dropY && (dragX + dragW) > (dropX) && (dragY + dragH) > (dropY)) || (dragX < (dropX + dropW) && dragY < dropY && (dragX + dragW) > (dropX + dropW) && (dragY + dragH) > (dropY)) || (dragX < (dropX + dropW) && dragY < (dropY + dropH) && (dragX + dragW) > (dropX + dropW) && (dragY + dragH) > (dropY + dropH)) || (dragX < (dropX) && dragY < (dropY + dropH) && (dragX + dragW) > (dropX) && (dragY + dragH) > (dropY + dropH)) || (dropX < mouse.x && dropY < mouse.y && (dropX + dropW) > (mouse.x) && (dropY + dropH) > (mouse.y))) {
                    return true;
                }
            } else if (droppableGroup['children'][0]['className'] == "Circle") {
                var centerX = droppableGroup['children'][0].x() + droppableGroup.x();
                var centerY = droppableGroup['children'][0].y() + droppableGroup.y() - scrollValue;
                var distance1 = distanceBetweenPoints(centerX, centerY, dragX, dragY);
                var distance2 = distanceBetweenPoints(centerX, centerY, dragX + dragW, dragY);
                var distance3 = distanceBetweenPoints(centerX, centerY, dragX + dragW, dragY + dragH);
                var distance4 = distanceBetweenPoints(centerX, centerY, dragX, dragY + dragH);
                var distance5 = distanceBetweenPoints(centerX, centerY, (dragX + 0.5 * dragW), (dragY + 0.5 * dragH));
                var distance6 = distanceBetweenPoints(centerX, centerY, mouse.x, mouse.y);
                var radius = droppableGroup['children'][0].radius();
                if (distance1 < radius || distance2 < radius || distance3 < radius || distance4 < radius || distance6 < radius) {
                    return true;
                }
            } else if (droppableGroup['children'][0]['className'] == "Line") {
                var points = droppableGroup['children'][0].points();
                if (points[2] > points[0]) {
                    var dropX = points[0] + droppableGroup.x();
                    var dropY = points[1] + droppableGroup.y() - scrollValue;
                    var dropW = points[2] - points[0];
                    var dropH = points[5] - points[1];
                    if ((dropX < mouse.x && dropY < mouse.y && (dropX + dropW) > (mouse.x) && (dropY + dropH) > (mouse.y)) || (dropX < dragX && dropY < dragY && (dropX + dropW) > (dragX) && (dropY + dropH) > (dragY)) || (dropX < (dragX + dragW) && dropY < dragY && (dropX + dropW) > (dragX + dragW) && (dropY + dropH) > (dragY)) || (dropX < (dragX + dragW) && dropY < (dragY + dragH) && (dropX + dropW) > (dragX + dragW) && (dropY + dropH) > (dragY + dragH)) || (dropX < (dragX) && dropY < (dragY + dragH) && (dropX + dropW) > (dragX) && (dropY + dropH) > (dragY + dragH)) || (dragX < dropX && dragY < dropY && (dragX + dragW) > (dropX) && (dragY + dragH) > (dropY)) || (dragX < (dropX + dropW) && dragY < dropY && (dragX + dragW) > (dropX + dropW) && (dragY + dragH) > (dropY)) || (dragX < (dropX + dropW) && dragY < (dropY + dropH) && (dragX + dragW) > (dropX + dropW) && (dragY + dragH) > (dropY + dropH)) || (dragX < (dropX) && dragY < (dropY + dropH) && (dragX + dragW) > (dropX) && (dragY + dragH) > (dropY + dropH))) {
                        return true;
                    }
                } else {
                    var dropX = points[2] + droppableGroup.x();
                    var dropY = points[1] + droppableGroup.y() - scrollValue;
                    var dropW = points[0] - points[2];
                    var dropH = points[5] - points[1];
                    if ((dropX < mouse.x && dropY < mouse.y && (dropX + dropW) > (mouse.x) && (dropY + dropH) > (mouse.y)) || (dropX < dragX && dropY < dragY && (dropX + dropW) > (dragX) && (dropY + dropH) > (dragY)) || (dropX < (dragX + dragW) && dropY < dragY && (dropX + dropW) > (dragX + dragW) && (dropY + dropH) > (dragY)) || (dropX < (dragX + dragW) && dropY < (dragY + dragH) && (dropX + dropW) > (dragX + dragW) && (dropY + dropH) > (dragY + dragH)) || (dropX < (dragX) && dropY < (dragY + dragH) && (dropX + dropW) > (dragX) && (dropY + dropH) > (dragY + dragH)) || (dragX < dropX && dragY < dropY && (dragX + dragW) > (dropX) && (dragY + dragH) > (dropY)) || (dragX < (dropX + dropW) && dragY < dropY && (dragX + dragW) > (dropX + dropW) && (dragY + dragH) > (dropY)) || (dragX < (dropX + dropW) && dragY < (dropY + dropH) && (dragX + dragW) > (dropX + dropW) && (dragY + dragH) > (dropY + dropH)) || (dragX < (dropX) && dragY < (dropY + dropH) && (dragX + dragW) > (dropX) && (dragY + dragH) > (dropY + dropH))) {
                        return true;
                    }
                }
            }
        }
    }

    function distanceBetweenPoints(x1, y1, x2, y2) {
        var distance = Math.pow((Math.pow((x1 - x2), 2) + Math.pow((y1 - y2), 2)), 0.5);
        return distance;
    }

    function optionOnDrag(e, ui, element) {
        $(element).hide();
        var draggable = $('.ui-draggable-dragging');
        var droppableTargets = previewStage.find('Group');
        for (i = 0; i < droppableTargets.length; i++) {
            if (droppableTargets[i]['children'][0]['className'] != "Line" && droppableTargets[i].find('.answer').length == 0) {
                var result = dropCheck(e, draggable, droppableTargets[i]);
                if (result === true) {
                    if (droppableTargets[i].visible() == false) {
                        droppableTargets[i].visible(true);
                        droppableTargets[i]['children'][0].fill('#FFFBE8');
                        for (j = 0; j < droppableTargets.length; j++) {
                            if (droppableTargets[j]['children'][0]['className'] != "Line" && droppableTargets[j].find('.answer').length == 0 && i != j) {
                                droppableTargets[j].hide();
                            }
                        }
                        previewStage.draw();
                    }
                    break;
                } else {
                    if (droppableTargets[i].visible() == true) {
                        droppableTargets[i].hide();
                        previewStage.draw();
                    }
                }
            }
        }
    }


    function checkwidthprev(group, text) {
        var line = group['children'][0];
        var text_width = getTextWidth(text, '16px arial');
        if (text_width < naming.minwidth_tag) {
            line.points([line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] + naming.minwidth_tag, line['attrs']['points'][1], line['attrs']['points'][0] + naming.minwidth_tag, line['attrs']['points'][1] + naming.minheight_tag, line['attrs']['points'][0], line['attrs']['points'][1] + naming.minheight_tag, line['attrs']['points'][8], line['attrs']['points'][1] + naming.minheight_tag / 2, line['attrs']['points'][0], line['attrs']['points'][1]]);
        }else if(text_width > naming.minwidth_tag && text_width< naming.maxwidth_tag){
            line.points([line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] + 5 + text_width, line['attrs']['points'][3], line['attrs']['points'][0] + 5 + text_width, line['attrs']['points'][5], line['attrs']['points'][6], line['attrs']['points'][7], line['attrs']['points'][8], line['attrs']['points'][9], line['attrs']['points'][10], line['attrs']['points'][11]]);
            var wid = line['attrs']['points'][2]-line['attrs']['points'][0]-naming.minwidth_tag;
            if(line['attrs']['points'][2]+group.x()+20>previewStage.width()){
                var w= line['attrs']['points'][2]-line['attrs']['points'][0];
                line['attrs']['points'][2] = previewStage.width()-20-group.x();
                line['attrs']['points'] = [line['attrs']['points'][2]-w,line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][5],line['attrs']['points'][2]-w,line['attrs']['points'][7],line['attrs']['points'][2]-w-25,line['attrs']['points'][9],line['attrs']['points'][2]-w,line['attrs']['points'][11]];
            }
        }else if(text_width >naming.maxwidth_tag){
            addtooltip(group, text);
            line.points([line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] +naming.maxwidth_tag, line['attrs']['points'][3], line['attrs']['points'][0] +naming.maxwidth_tag, line['attrs']['points'][5], line['attrs']['points'][6], line['attrs']['points'][7], line['attrs']['points'][8], line['attrs']['points'][9], line['attrs']['points'][10], line['attrs']['points'][11]]);
            var wid = line['attrs']['points'][2]-line['attrs']['points'][0]-naming.minwidth_tag;
            if(line['attrs']['points'][2]+group.x()+20>previewStage.width()){
                line['attrs']['points'][2] = previewStage.width()-20-group.x();
                line['attrs']['points'] = [line['attrs']['points'][2]-naming.maxwidth_tag,line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][5],line['attrs']['points'][2]-naming.maxwidth_tag,line['attrs']['points'][7],line['attrs']['points'][2]-naming.maxwidth_tag-25,line['attrs']['points'][9],line['attrs']['points'][2]-naming.maxwidth_tag,line['attrs']['points'][11]];
            }
        }
        group.find('.deco').setX(line['attrs']['points'][8] + 10 + 3);
        group.find('.deco').setY(line['attrs']['points'][9]);
        var connector = group.find('.connecting');
        var inix = connector[0]['attrs']['points'][2];
        var iniy = connector[0]['attrs']['points'][3];
        connector[0]['attrs']['points'] = [line['attrs']['points'][8], line['attrs']['points'][9], inix, iniy];
        group['children'][0].fill('white');
        group['children'][0].opacity(0.5);
    };


    function checkwidthreverseprev(group, text) {
        var line = group['children'][0];
        var text_width = getTextWidth(text, '16px arial');
        if(text_width<naming.minwidth_tag){
            line['attrs']['points'] = [line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] - naming.minwidth_tag, line['attrs']['points'][1], line['attrs']['points'][0] - naming.minwidth_tag, line['attrs']['points'][1] + naming.minheight_tag, line['attrs']['points'][0], line['attrs']['points'][1] + naming.minheight_tag, line['attrs']['points'][8], line['attrs']['points'][1] + naming.minheight_tag / 2, line['attrs']['points'][0], line['attrs']['points'][1]];
        } else if (text_width > naming.minwidth_tag && text_width < naming.maxwidth_tag) {
            line['attrs']['points'] = [line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] - 5 - text_width, line['attrs']['points'][3], line['attrs']['points'][0] - 5 - text_width, line['attrs']['points'][5], line['attrs']['points'][6], line['attrs']['points'][7], line['attrs']['points'][8], line['attrs']['points'][9], line['attrs']['points'][10], line['attrs']['points'][11]];
            var wid = line['attrs']['points'][0]-line['attrs']['points'][2]-naming.minwidth_tag;
            var w= line['attrs']['points'][0]-line['attrs']['points'][2];
            if(line['attrs']['points'][2]+group.x()+20<20){
                line['attrs']['points'][2] = 20-group.x();
                line['attrs']['points'] = [line['attrs']['points'][2]+w,line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][5],line['attrs']['points'][2]+w,line['attrs']['points'][7],line['attrs']['points'][2]+w+25,line['attrs']['points'][9],line['attrs']['points'][2]+w,line['attrs']['points'][11]];
            }
        }else if(text_width >naming.maxwidth_tag){
            addtooltip(group, text);
            line.points([line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] -naming.maxwidth_tag, line['attrs']['points'][3], line['attrs']['points'][0] -naming.maxwidth_tag, line['attrs']['points'][5], line['attrs']['points'][6], line['attrs']['points'][7], line['attrs']['points'][8], line['attrs']['points'][9], line['attrs']['points'][10], line['attrs']['points'][11]]);
            var wid = line['attrs']['points'][0]-line['attrs']['points'][2]-naming.minwidth_tag;
            if(line['attrs']['points'][2]+group.x()+20<20){
                line['attrs']['points'][2] = 20-group.x();
                line['attrs']['points'] = [line['attrs']['points'][2]+naming.maxwidth_tag,line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][5],line['attrs']['points'][2]+naming.maxwidth_tag,line['attrs']['points'][7],line['attrs']['points'][2]+naming.maxwidth_tag+25,line['attrs']['points'][9],line['attrs']['points'][2]+naming.maxwidth_tag,line['attrs']['points'][11]];
            }
        }
        group.find('.deco').setX(line['attrs']['points'][8] - 10 - 3);
        group.find('.deco').setY(line['attrs']['points'][9]);
        group.find('.answer').setX(line['attrs']['points'][2] + 10);
        var connector = group.find('.connecting');
        var inix = connector[0]['attrs']['points'][2];
        var iniy = connector[0]['attrs']['points'][3];
        connector[0]['attrs']['points'] = [line['attrs']['points'][8], line['attrs']['points'][9], inix, iniy];
        group['children'][0].fill('white');
        group['children'][0].opacity(0.5);
    };

    function addtooltip(group, text){
        var tooltip = new Konva.Label({
            x: 0,
            y: 0,
            opacity: 1,
            name : 'tooltip'
        });
        group.add(tooltip);
        tooltip.add(new Konva.Tag({
            fill: '#7ac9aa',
            pointerDirection: 'down',
            pointerWidth: 10,
            pointerHeight: 10,
            lineJoin: 'round',
            cornerRadius: 5
        }));
        tooltip.add(new Konva.Text({
            text:text,
            fontFamily: 'Calibri',
            fontSize: 16,
            padding: 5,
            fill: 'white'
        }));
        tooltip.hide();
        previewStage.draw();
    };

    function nametagText(group){
        var truncat = group.find('.answer')[0];
        truncat.on('tap', function(){
            var tooltip = group.find('.tooltip')[0];
            if(tooltip['attrs']['visible']== true){
                tooltip.hide();
                previewStage.draw();
            }else if(tooltip['attrs']['visible']== false){
                tooltip.show();
                tooltip.setX((group['children'][0]['attrs']['points'][0]+group['children'][0]['attrs']['points'][2])/2);
                tooltip.setY(group['children'][0]['attrs']['points'][1]+20);
                previewStage.draw();
            }
        });
        truncat.on('mouseover', function(e){
            document.body.style.cursor = 'pointer';
            var tooltip = group.find('.tooltip');
            tooltip.show();
            tooltip.setX((group['children'][0]['attrs']['points'][0]+group['children'][0]['attrs']['points'][2])/2);
            tooltip.setY(group['children'][0]['attrs']['points'][1]+20);
            previewStage.draw();
        });
        truncat.on('mouseout', function(){
            document.body.style.cursor = 'default';
            group.find('.tooltip').hide();
            previewStage.draw();
        });
        var match = false;
        if (getTextWidth(truncat.text(), '16px arial') > naming.maxwidth_tag) {
            for (k = 1; k < truncat.text().length; k++) {
                if (getTextWidth(truncat.text().substr(0, k), '16px arial') > naming.maxwidth_tag && match==false) {
                    truncat.text(truncat.text().substr(0, k - 2) + '..');
                    break ;
                }
            }
        }

    }

    function getTextWidth(text, fonter) {
        var canvas = getTextWidth.canvas || (getTextWidth.canvas = document.createElement("canvas"));
        var context = canvas.getContext("2d");
        context.font = fonter;
        var metrics = context.measureText(text);
        return metrics.width;
    };

    function optionOnDrop(e, element) {
        $(element).show();
        var draggable = $('.ui-draggable-dragging');
        var droppableTargets = previewStage.find('Group');
        var match = false;
        for (i = 0; i < droppableTargets.length; i++) {
            var result = dropCheck(e, draggable, droppableTargets[i]);
            if (result === true && (droppableTargets[i].visible() === true || droppableTargets[i].visible() == 'inherit')) {
                //dropping options in area tag
                if (droppableTargets[i]['children'][0]['className'] != "Line") {
                    if ($(element).hasClass('all_option_text')) {
                        global_droppableTarget = droppableTargets[i];
                        droppableTargets[i]['attrs']['tempAnswer'] = $(element).find('span').html();
                        droppableTargets[i].add(new Konva.Text({
                            x: 0,
                            y: 0,
                            text: $(element).find('span').html(),
                            fontSize: 14,
                            align: 'center',
                            name: 'answer',
                            useranswer: $(element).find('span').html(),
                            answertype: 'text',
                            draggable: false
                        }));
                        droppableTargets[i].visible(true);
                        droppableTargets[i]['children'][0].fill('white');
                        droppableTargets[i]['children'][0].opacity(0.5);
                        droppableTargets[i]['children'][0].strokeEnabled(true);
                        updateTextAreaTag(droppableTargets[i]);
                        var text = global_droppableTarget.find('.answer')[0];
                        text.fontStyle('bold');
                        previewStage.draw();
                    } else if ($(element).hasClass('all_option_image')) {
                        global_droppableTarget = droppableTargets[i];
                        var imageObj = new Image();
                        imageObj.onload = function() {
                            var imageAnswer = new Konva.Image({
                                x: 0,
                                y: 0,
                                draggable: false,
                                image: imageObj,
                                width: 50,
                                height: 50,
                                useranswer: $(element).find('img').attr('src'),
                                answertype: 'image',
                                name: 'answer'
                            });
                            global_droppableTarget.add(imageAnswer);
                            global_droppableTarget.visible(true);
                            global_droppableTarget['children'][0].fill('white');
                            global_droppableTarget['children'][0].opacity(0.5);
                            global_droppableTarget['children'][0].strokeEnabled(true);
                            updateImageAreaTag(global_droppableTarget);
                            var image = global_droppableTarget.find('.answer')[0];
                            image.setZIndex(100);
                            previewStage.draw();
                        }
                        imageObj.src = $(element).find('img').attr('src');
                    }
                    previewStage.draw();
                }
                //dropping options in name tag 
                else {
                    if ($(element).hasClass('all_option_text')) {
                        if (droppableTargets[i]['children'][0]['attrs']['points'][2] > droppableTargets[i]['children'][0]['attrs']['points'][0]) {
                            checkwidthprev(droppableTargets[i] , $(element).find('span').html());
                            answer_position = droppableTargets[i]['children'][0]['attrs']['points'][0];

                        } else {
                            checkwidthreverseprev(droppableTargets[i] , $(element).find('span').html());
                            answer_position = droppableTargets[i]['children'][0]['attrs']['points'][2] + 10;
                        }
                        droppableTargets[i].add(new Konva.Text({
                            x: answer_position,
                            y: droppableTargets[i]['children'][0]['attrs']['points'][1] + 13,
                            text: $(element).find('span').html(),
                            fontSize: 16,
                            draggable: false,
                            align: 'center',
                            name: 'answer',
                            useranswer: $(element).find('span').html(),
                            answertype: 'text'
                        }));
                        nametagText(droppableTargets[i]);
                        previewStage.draw();
                    } else if ($(element).hasClass('all_option_image')) {
                        global_droppableTarget = droppableTargets[i];
                        var points = global_droppableTarget['children'][0]['attrs']['points'];
                        if (points[2] > points[0]) {
                            var imageObj = new Image();
                            imageObj.onload = function() {
                                var newpoints;
                                if (points[1] + global_droppableTarget.y() + naming.nametagImg_h > previewStage.height()) {
                                    newpoints = [points[6], points[7] - naming.nametagImg_h, points[6] + naming.nametagImg_w, points[7] - naming.nametagImg_h, points[6] + naming.nametagImg_w, points[7], points[6], points[7], points[8], points[7] - naming.nametagImg_h / 2 + 5, points[6], points[7] - naming.nametagImg_h];
                                } else {
                                    newpoints = [points[0], points[1], points[0] + naming.nametagImg_w, points[1], points[0] + naming.nametagImg_w, points[1] + naming.nametagImg_h, points[0], points[1] + naming.nametagImg_h, points[8], points[1] + naming.nametagImg_h / 2 - 5, points[0], points[1]];
                                }
                                var imageAnswer = new Konva.Image({
                                    x: newpoints[0],
                                    y: newpoints[1] + 15,
                                    draggable: false,
                                    image: imageObj,
                                    width: naming.nametagImg_w - 10,
                                    height: naming.nametagImg_h - 20,
                                    answertype: 'image',
                                    name: 'answer',
                                    useranswer: $(element).find('img').attr('src')
                                });
                                global_droppableTarget.add(imageAnswer);
                                global_droppableTarget['children'][0].points(newpoints);
                                global_droppableTarget.find('.right').remove();
                                global_droppableTarget.find('.wrong').remove();
                                global_droppableTarget.find('.deco').setX(newpoints[8] + 10 + 3);
                                global_droppableTarget.find('.deco').setY(newpoints[9]);
                                var connector = global_droppableTarget.find('.connecting');
                                var inix = connector[0]['attrs']['points'][2];
                                var iniy = connector[0]['attrs']['points'][3];
                                connector[0]['attrs']['points'] = [newpoints[8], newpoints[9], inix, iniy];
                                previewStage.draw();
                            }

                        } else {
                            var imageObj = new Image();
                            imageObj.onload = function() {
                                var newpoints;
                                if (points[1] + global_droppableTarget.y() + naming.nametagImg_h > previewStage.height()) {
                                    newpoints = [points[6], points[7] - naming.nametagImg_h, points[6] - naming.nametagImg_w, points[7] - naming.nametagImg_h, points[6] - naming.nametagImg_w, points[7], points[6], points[7], points[8], points[7] - naming.nametagImg_h/2 +5, points[6], points[7] - naming.nametagImg_h];
                                } else {
                                    newpoints = [points[0], points[1], points[0] - naming.nametagImg_w, points[1], points[0] - naming.nametagImg_w, points[1] + naming.nametagImg_h, points[0], points[1] + naming.nametagImg_h, points[8], points[1] + naming.nametagImg_h / 2 - 5, points[0], points[1]];
                                }
                                var imageAnswer = new Konva.Image({
                                    x: newpoints[2] + 10,
                                    y: newpoints[1] + 15,
                                    draggable: false,
                                    image: imageObj,
                                    width: naming.nametagImg_w - 10,
                                    height: naming.nametagImg_h - 20,
                                    answertype: 'image',
                                    name: 'answer',
                                    useranswer: $(element).find('img').attr('src')
                                });
                                global_droppableTarget.add(imageAnswer);
                                global_droppableTarget['children'][0].points(newpoints);
                                global_droppableTarget.find('.right').remove();
                                global_droppableTarget.find('.wrong').remove();
                                global_droppableTarget.find('.deco').setX(newpoints[8] - 10 - 3);
                                global_droppableTarget.find('.deco').setY(newpoints[9]);
                                var connector = global_droppableTarget.find('.connecting');
                                var inix = connector[0]['attrs']['points'][2];
                                var iniy = connector[0]['attrs']['points'][3];
                                connector[0]['attrs']['points'] = [newpoints[8], newpoints[9], inix, iniy];
                                previewStage.draw();
                            }

                        }
                        imageObj.src = $(element).find('img').attr('src');
                    }
                }
                $(element).hide();
                break;
            }
        }
    }

    function shuffle(array) {
        var counter = array.length,
            temp, index;

        while (counter > 0) {
            index = Math.floor(Math.random() * counter);
            counter--;
            temp = array[counter];
            array[counter] = array[index];
            array[index] = temp;
        }

        return array;
    }

    function resetQuestion() {
        //previewStage.find('.tooltip').remove();
        //$('#optionList').find('li').each(function() {
        //    $(this).show();
        //});
        //previewStage.find('.answer').remove();
        //previewStage.find('.answerBorder').remove();
        //previewStage.find('.icon').remove();
        //var nametag = previewStage.find('.pentagon');
        //for (i = 0; i < nametag.length; i++) {
        //    nametag[i]['attrs']['fill'] = '#ffffff';
        //}
        //resetNameTags(previewStage.find('Group'));
        //resetAreaTags(previewStage.find('Group'));
        previewStage.draw();
        location.reload();
    }

    function needHelp() {
        //resetQuestion();
        var answerImagesOK = 0;
        var allImageAnswers = 0;
        var answerImgs = [];
        var group = previewStage.find('Group');
        for (i = 0; i < group.length; i++) {
            if (group[i]['attrs']['correctAnswerType'] == "image") {
                allImageAnswers++;
            }
        }

        for (i = 0; i < group.length; i++) {
            if (group[i]['children'][0]['className'] != 'Line') {
                if (group[i]['attrs']['correctAnswerType'] == "text") {
                    global_droppableTarget = group[i];
                    group[i]['attrs']['tempAnswer'] = group[i]['attrs']['correctAnswer'];
                    group[i].add(new Konva.Text({
                        x: 0,
                        y: 0,
                        text: group[i]['attrs']['correctAnswer'],
                        draggable: false,
                        fontSize: 14,
                        align: 'center',
                        name: 'answer',
                        answertype: 'text',
                        useranswer:group[i]['attrs']['correctAnswer']
                    }));
                    group[i].visible(true);
                    group[i]['children'][0].fill('white');
                    group[i]['children'][0].opacity(0.5);
                    group[i]['children'][0].strokeEnabled(true);
                    updateTextAreaTag(group[i]);
                    var text = global_droppableTarget.find('.answer')[0];
                    text.fontStyle('bold');
                } else if (group[i]['attrs']['correctAnswerType'] == "image") {
                    var imageObj = new Image();
                    var object = {
                        'areaTag': imageObj,
                        'group': group[i]
                    };
                    answerImgs.push(object);
                    imageObj.onload = function() {
                        answerImagesOK++;
                        if (answerImagesOK >= allImageAnswers) {
                            loadAnswerImages(answerImgs);
                        }
                    }
                    group[i].visible(true);
                    group[i]['children'][0].fill(null);
                    imageObj.src = addPrefix(group[i]['attrs']['correctAnswer']);
                }
            }
            //setting answers for name tag
            else {
                if (group[i]['children'][0]['attrs']['points'][2] > group[i]['children'][0]['attrs']['points'][0]) {
                    checkwidthprev(group[i] , group[i]['attrs']['correctAnswer']);
                    if (group[i]['attrs']['correctAnswerType'] == 'text') {
                        group[i].add(new Konva.Text({
                            x: group[i]['children'][0]['attrs']['points'][0],
                            y: 215,
                            text: group[i]['attrs']['correctAnswer'],
                            fontSize: 16,
                            draggable: false,
                            align: 'center',
                            name: 'answer',
                            answertype: 'text',
                            useranswer:group[i]['attrs']['correctAnswer']
                        }));
                        nametagText(group[i] );
                    } else if (group[i]['attrs']['correctAnswerType'] == 'image') {
                        global_droppableTarget = group[i];
                        var points = global_droppableTarget['children'][0]['attrs']['points'];
                        var imageObj = new Image();
                        var object = {
                            'nameTag': imageObj,
                            'startpoint': 200,
                            'group': group[i]
                        };
                        answerImgs.push(object);
                        imageObj.onload = function() {
                            answerImagesOK++;
                            if (answerImagesOK >= allImageAnswers) {
                                loadAnswerImages(answerImgs);
                            }
                        }
                        imageObj.src = addPrefix(group[i]['attrs']['correctAnswer']);
                    }
                }else {
                    if (group[i]['attrs']['correctAnswerType'] == 'text') {
                        checkwidthreverseprev(group[i] , group[i]['attrs']['correctAnswer']);
                        group[i].add(new Konva.Text({
                            x: group[i]['children']['0']['attrs']['points'][2]+10,
                            y: 215,
                            text: group[i]['attrs']['correctAnswer'],
                            fontSize: 16,
                            draggable: false,
                            align: 'center',
                            name: 'answer',
                            answertype: 'text',
                            useranswer:group[i]['attrs']['correctAnswer']
                        }));
                        nametagText(group[i],group[i]['attrs']['correctAnswer']);
                    } else if (group[i]['attrs']['correctAnswerType'] == 'image') {
                        global_droppableTarget = group[i];
                        var X = group[i].x();
                        var imageObj = new Image();
                        var object = {
                            'nameTag': imageObj,
                            'group': group[i]
                        };
                        answerImgs.push(object);
                        imageObj.onload = function() {
                            answerImagesOK++;
                            if (answerImagesOK >= allImageAnswers) {
                                loadAnswerImages(answerImgs);
                            }
                        }
                        imageObj.src = addPrefix(group[i]['attrs']['correctAnswer']);
                    }
                }
            }
        }
        previewStage.draw();
    }

    function loadAnswerImages(answerImgs) {
        for (var i = 0; i < answerImgs.length; i++) {
            if (answerImgs[i]['areaTag']) {
                var imageAnswer = new Konva.Image({
                    x: 0,
                    y: 0,
                    draggable: false,
                    image: answerImgs[i]['areaTag'],
                    width: 50,
                    height: 50,
                    answertype: 'image',
                    name: 'answer'
                });
                answerImgs[i]['group'].add(imageAnswer);
                answerImgs[i]['group']['children'][0].fill('white');
                answerImgs[i]['group']['children'][0].opacity(0.5);
                answerImgs[i]['group']['children'][0].strokeEnabled(true);
                updateImageAreaTag(answerImgs[i]['group']);
                var image = answerImgs[i]['group'].find('.answer')[0];
                image.setZIndex(100);
                previewStage.draw();
            } else if (answerImgs[i]['nameTag']) {
                if (answerImgs[i]['group']['children']['0']['attrs']['points'][2] > answerImgs[i]['group']['children']['0']['attrs']['points'][0]) {
                    var imageAnswer = new Konva.Image({
                        x: answerImgs[i]['group']['children']['0']['attrs']['points'][0],
                        y: answerImgs[i]['group']['children']['0']['attrs']['points'][1] + 17,
                        draggable: false,
                        image: answerImgs[i]['nameTag'],
                        width: naming.nametagImg_w - 10,
                        height: naming.nametagImg_h - 20,
                        answertype: 'image',
                        name: 'answer'
                    });
                    answerImgs[i]['group'].add(imageAnswer);
                    var points = answerImgs[i]['group']['children'][0]['attrs']['points'];
                    var newpoints = [points[0], points[1], points[0] + naming.nametagImg_w, points[1], points[0] + naming.nametagImg_w, points[1] + naming.nametagImg_h, points[0], points[1] + naming.nametagImg_h, points[8], points[1] + naming.nametagImg_h / 2 - 5, points[0], points[1]];
                    answerImgs[i]['group']['children'][0].points(newpoints);
                    answerImgs[i]['group'].find('.right').remove();
                    answerImgs[i]['group'].find('.wrong').remove();
                    answerImgs[i]['group'].find('.deco').setX(newpoints[8] + 10 + 3);
                    answerImgs[i]['group'].find('.deco').setY(newpoints[9]);
                    var connector = answerImgs[i]['group'].find('.connecting');
                    var inix = connector[0]['attrs']['points'][2];
                    var iniy = connector[0]['attrs']['points'][3];
                    connector[0]['attrs']['points'] = [newpoints[8], newpoints[9], inix, iniy];
                    previewStage.draw();
                } else {
                    var imageAnswer = new Konva.Image({
                        x: answerImgs[i]['group']['children']['0']['attrs']['points'][0] - naming.nametagImg_w,
                        y: answerImgs[i]['group']['children']['0']['attrs']['points'][1] + 17,
                        draggable: false,
                        image: answerImgs[i]['nameTag'],
                        width: naming.nametagImg_w - 10,
                        height: naming.nametagImg_h - 20,
                        answertype: 'image',
                        name: 'answer'
                    });
                    answerImgs[i]['group'].add(imageAnswer);
                    var points = answerImgs[i]['group']['children'][0]['attrs']['points'];
                    var newpoints = [points[0], points[1], points[0] - naming.nametagImg_w, points[1], points[0] - naming.nametagImg_w, points[1] + naming.nametagImg_h, points[0], points[1] + naming.nametagImg_h, points[8], points[1] + naming.nametagImg_h / 2 - 5, points[0], points[1]];
                    answerImgs[i]['group']['children'][0].points(newpoints);
                    answerImgs[i]['group'].find('.right').remove();
                    answerImgs[i]['group'].find('.wrong').remove();
                    answerImgs[i]['group'].find('.deco').setX(newpoints[8] - 10 - 3);
                    answerImgs[i]['group'].find('.deco').setY(newpoints[9]);
                    var connector = answerImgs[i]['group'].find('.connecting');
                    var inix = connector[0]['attrs']['points'][2];
                    var iniy = connector[0]['attrs']['points'][3];
                    connector[0]['attrs']['points'] = [newpoints[8], newpoints[9], inix, iniy];
                    previewStage.draw();
                }
            }
        }
    }

    function checkAnswers() {
        var group = previewStage.find('Group');
        previewStage.find('.right').remove();
        previewStage.find('.wrong').remove();
        var count=0;
        for (i = 0; i < group.length; i++) {
            if (group[i]['attrs']['correctAnswer']) {
                if (group[i].find('.answer').length > 0) {
                    var answer = group[i].find('.answer')[0];
                    var result = false;
                    if (answer['attrs']['answertype'] == "text" && group[i]['attrs']['correctAnswer'] == answer['attrs']['useranswer']) {
                        result = true;
                    } else if (answer['attrs']['answertype'] == "image") {
                        var userAnswer = answer['attrs']['image']['src'].split(prefix)[1];
                        var correctAnswer = group[i]['attrs']['correctAnswer'];
                        if (userAnswer == correctAnswer) {
                            if (group[i]['children'][0]['className'] != 'Line') {
                                result = true;
                            } else {
                                result = true;
                                var color = group[i]['children'][0]['attrs']['stroke'];
                                group[i]['children'][0]['attrs']['fill'] = color;
                            }
                        }
                    }
                }else{
                    var result = false;
                }
                if (group[i].find('.icon')[0]) {
                    group[i].find('.icon')[0].remove();
                }
                addIcon(group[i], result);
                group[i].show();
            }
            if(!result){
                count++;
            }

        }
        message(count);
        previewStage.draw();
    }

    function addIcon(group, result) {
        var imageObj = new Image();
        imageObj.onload = function() {
            var imageAnswer = new Konva.Image({
                x: 0,
                y: 0,
                draggable: false,
                image: imageObj,
                width: 30,
                height: 30,
                name: 'icon'
            });
            group.add(imageAnswer);
            var icon = group.find('.icon')[0];
            if (group['children'][0]['className'] == "Rect") {
                var posX = positionX(group) + group['children'][0].width() - group.x() - 15;
                var posY = positionY(group) - group.y() - 15;
            } else if (group['children'][0]['className'] == "Circle") {
                var posX = group['children'][0].x() + (group['children'][0].radius() / Math.pow(2, 0.5)) - 15;
                var posY = group['children'][0].y() - (group['children'][0].radius() / Math.pow(2, 0.5)) - 15;
            } else if (group['children'][0]['className'] == "Line") {
                var points = group['children'][0].points();
                var posX = points[2] - 15;
                var posY = points[3] - 15;
                var color = group['children'][0]['attrs']['stroke'];
                group['children'][0]['attrs']['fill'] = color;
                if(group.find('.answer')[0]){
                                           group.find('.answer')[0]['attrs']['fill'] = '#ffffff';
                                    }

            }
            icon.x(posX);
            icon.y(posY);
            previewStage.draw();
        }
        if (result == true) {
            imageObj.src = "/assets/activities/correct.png";
        } else if (result == false) {
            imageObj.src = "/assets/activities/cancel.png";
        }
    }

    //get position x 
    function positionX(group) {
        var circles = group.find('Circle');
        for (j = 0; j < 4; j++) {
            if (j == 0) {
                x = group.x() + circles[j].x();
            } else {
                if (x > (group.x() + circles[j].x())) {
                    x = group.x() + circles[j].x();
                }
            }
        }
        return x;
    };

    //get position y
    function positionY(group) {
        var circles = group.find('Circle');
        for (j = 0; j < 4; j++) {
            if (j == 0) {
                y = group.y() + circles[j].y();
            } else {
                if (y > (group.y() + circles[j].y())) {
                    y = group.y() + circles[j].y();
                }
            }
        }
        return y;
    };

    function updateTextAreaTag(group) {
        var text = group.find('.answer')[0];
        text.text(group['attrs']['tempAnswer']);
        text.fontSize(14);
        if (group['children'][0]['className'] == "Rect") {
            var rect = group.find('.droppable')[0];
            if (text.width() > rect.width()) {
                addtooltip(group, text['attrs']['useranswer']);
                textSize(rect, text);
            }
            var finalX = positionX(group) + (0.5 * rect.width()) - (0.5 * text.width()) - group.x();
            var finalY = positionY(group) + (0.5 * rect.height()) - (0.5 * text.height()) - group.y();
            text.x(finalX);
            text.y(finalY);
        } else if (group['children'][0]['className'] == "Circle") {
            var circle = group.find('.droppable')[0];
            if (text.width() > (circle.radius() * 2)) {
                addtooltip(group, text['attrs']['useranswer']);
                textSize(circle, text);
            }
            var finalX = circle.x() - text.width() * 0.5;
            var finalY = circle.y() - text.height() * 0.5;
            text.x(finalX);
            text.y(finalY);
        }
    };

    function textSize(shape, text) {
        var group = shape.getParent();
        text.on('tap', function(){
            var tooltip = group.find('.tooltip')[0];
            if(tooltip['attrs']['visible']== true){
                tooltip.hide();
                previewStage.draw();
            }else if(tooltip['attrs']['visible']== false){
                tooltip.show();
                tooltip.setX(text.x()+text.width()/2);
                tooltip.setY(text.y());
                previewStage.draw();
            }
        });
        text.on('mouseover', function(e){
            document.body.style.cursor = 'pointer';
            var tooltip = group.find('.tooltip');
            tooltip.show();
            tooltip.setX(text.x()+text.width()/2);
            tooltip.setY(text.y());
            previewStage.draw();
        });
        text.on('mouseout', function(){
            document.body.style.cursor = 'default';
            group.find('.tooltip').hide();
            previewStage.draw();
        });

        if (shape['className'] == "Rect") {
            var w = shape.width();
            var h = shape.height();
        } else if (shape['className'] == "Circle") {
            var w = shape.radius() * 2;
        }
        if (text.fontSize() > 12) {
            if (text['textWidth'] > w - 10) {
                text.fontSize(12);
                textSize(shape, text);
            }
        } else {
            var truncat = text.text();
            if (getTextWidth(truncat, '12px arial') > w - 10) {
                for (k = 1; k < truncat.length; k++) {
                    if (getTextWidth(truncat.substr(0, k), '12px arial') > w - 10) {
                        text.text(truncat.substr(0, k - 4) + '..');
                        break;
                    }
                }
            }
        }
    };

    function updateImageAreaTag(group) {
        var image = group.find('.answer')[0];
        var imgWidth = 100;
        var imgHeight = 100;
        //image adjustments for rectangular area tag
        if (group['children'][0]['className'] == "Rect") {
            var targetW = Math.abs(group['children'][0].width());
            var targetH = Math.abs(group['children'][0].height());
            var targetX = positionX(group);
            var targetY = positionY(group);
            var arr = imageDimensions(imgWidth, imgHeight, targetH, targetW, targetX, targetY);
            image.width(arr[0]);
            image.height(arr[1]);
            image.x(arr[2] - group.x());
            image.y(arr[3] - group.y());
        }
        //image adjustments for circular area tag
        else if (group['children'][0]['className'] == 'Circle') {
            var circle = group['children'][0];
            var centerX = circle.x();
            var centerY = circle.y();
            var distance = Math.pow((Math.pow(imgWidth * 0.5, 2) + Math.pow(imgHeight * 0.5, 2)), 0.5);
            if (distance <= circle.radius()) {
                image.x(centerX - imgWidth * 0.5);
                image.y(centerY - imgHeight * 0.5);
            } else {
                var newWidth = Math.pow(2, 0.5) * circle.radius();
                image.x(centerX - newWidth * 0.5);
                image.y(centerY - newWidth * 0.5);
                image.width(newWidth);
                image.height(newWidth);
            }
        }
    };

    function imageDimensions(imgWidth, imgHeight, targetH, targetW, targetX, targetY) {
        if (imgWidth < targetW && imgHeight < targetH) {
            var finalWidth = imgWidth;
            var finalHeight = imgHeight;
            var finalX = targetX + 0.5 * targetW - 0.5 * imgWidth;
            var finalY = targetY + 0.5 * targetH - 0.5 * imgHeight;
            var arr = [finalWidth, finalHeight, finalX, finalY];
            return arr;
        } else {
            var finalWidth = targetW;
            var finalHeight = targetH;
            if (finalWidth > imgWidth) {
                finalWidth = imgWidth;
            }
            if (finalHeight > imgHeight) {
                finalHeight = imgHeight;
            }
            var finalX = targetX + 0.5 * targetW - 0.5 * finalWidth;
            var finalY = targetY + 0.5 * targetH - 0.5 * finalHeight;
            var arr = [finalWidth, finalHeight, finalX, finalY];
            return arr;
        }
    };

    $('.check_answers').click(function() {
        checkAnswers();
    });
    $('.need_help').click(function() {
        needHelp();
    });
    $('.reset_the_question').click(function() {
        resetQuestion();
    });

    function message(n){
        if(n == 0){
            var audio = document.getElementById('excellent');
            audio.play();
        }else{
            var audio = document.getElementById('tryagain');
            audio.play();
        }
    }

    function addPrefix(imageName){
        var url = prefix+imageName;
        return url;
    }

    changeHeightOfPreview();
           $(window).resize(function(){
                       changeHeightOfPreview();
               });
           function changeHeightOfPreview(){

                           if(!$('.content-of-preview').parent().hasClass('previewBody')){
                                   var windowHeight = window.innerHeight;
                                   $('.content-of-preview').css('height',windowHeight);
                                   $('.description_canvas').css('height',windowHeight-50);
                                   $('.description_canvas').css('border-right', '1px solid #adadad');
                           }
                       else{
                                   $('.content-of-preview').css('height','550px');
                           }
               }


};