$.fn.previewConceptMap = function(json,prefix) {
           $(this).css('height',window.innerHeight);
            $('body').on('touchmove', function(e){
                    //prevent native touch activity like scrolling
                        e.preventDefault();
               });
    //     $(window).on("orientationchange",function(){
        //               alert("The orientation has changed!");
            //             });
                       $(this).css('position','relative');
    var height;
    var parentElementColor = '#df3f01',
        childElementColor = '#1ca45c',
        selectedElementColor = 'yellow',
        selected_element,
        logo;
    $(this).empty();
    if(json.logo==undefined || json.logo==""){
        logo='/assets/ignitor_logo.png';
    }
    else{
        logo=addPrefix(json.logo);
    }
    if(!$(this).hasClass('modal-body')){
        $(this).append('<p class="preview-title">Concept Map Editor Preview</p>');
    }
    $(this).addClass('no-padding');
    $(this).append('<div class="row main-body"><div id="previewCanvas" class="col-xs-7"></div><div id="previewDescription" class="col-xs-5"></div></div><img class="logo" src="'+logo+'">');
    var previewStage = Konva.Node.create(json['stagedata'], 'previewCanvas');
    $('#previewDescription').on('touchmove', function (e) {
                e.stopPropagation();
           });
        //$('#previewDescription').css('height', previewStage.height());
        //    $('.main-body').css('height',(window.innerHeight-$('.preview-title').outerHeight()));
    function go() {
        height = window.innerHeight;
        console.log(height);
        if(!$(this).hasClass('modal-body')){
            $(this).css('height',height);
            $('.main-body').css('height',height-32);
            $('#previewDescription').css('height', height-32);
            $('#previewCanvas').css('height', height-32);
        }
        if($(this).hasClass('modal-body')){
            $('#previewDescription').css('height', '562px');
            $('#previewCanvas').css('height', '562px');
        }
    };
    window.setTimeout(go, 300);
            $('.konvajs-content').css('margin','auto');

    var groups = previewStage.find('Group');
    groups.forEach(function(group) {
        $('#content').empty().html(group['attrs']['description']);
        $('#content').find('img').each(function(){
            $(this).attr('src',addPrefix($(this).data('imgname')));
        });
        group['attrs']['description']=$('#content').html();
        group['attrs']['childVisible'] = false;
        group.setDraggable(false);
        group.find('.symbol')[0].text('+');
        resetGroup(group);
        group.hide();
        group.on('click tap touchstart', function() {
            if (selected_element == this) {
                var checked = false;
                if (this['attrs']['childVisible'] == false && checked == false) {
                    checked = true;
                    this.find('.symbol')[0].text('-');
                    showChildren(this);
                } else if (this['attrs']['childVisible'] == true && checked == false) {
                    checked = true;
                    this.find('.symbol')[0].text('+');
                    hideChildren(this);
                }
            }
            selected_element = this;
            $('#previewDescription').empty().html('<p class="previewElementName">' + this['attrs']['elementName'] + '</p>' + this['attrs']['description']);
            if (selected_element['attrs']['name'] == "parent") {
                $('.previewElementName').css('color', parentElementColor);
            } else {
                $('.previewElementName').css('color', childElementColor);
            }
            var allGroups = previewStage.find('Group');
            allGroups.forEach(function(group) {
                resetGroup(group);
            });
            this.find('Circle')[0].stroke(selectedElementColor);
            previewStage.draw();
        });
        group.find('.symbol')[0].on('click tap touchstart', function(e) {
        //    e.cancelBubble = true;
        //    var checked = false;
        //    if (this.getParent()['attrs']['childVisible'] == true && checked == false) {
        //        hideChildren(this.getParent());
        //        this.getParent().find('.symbol')[0].text('+');
        //        checked = true;
        //    } else if (this.getParent()['attrs']['childVisible'] == false && checked == false) {
        //        showChildren(this.getParent());
        //        this.getParent().find('.symbol')[0].text('-');
        //        checked = true;
        //    }
        //    if (selected_element != undefined) {
        //        var id = parseInt(selected_element['attrs']['name']);
        //        if (group['attrs']['id'] == id) {
        //            previewStage.find('Group').forEach(function(entry) {
        //                resetGroup(entry);
        //            });
        //            selected_element = group;
        //            $('#previewDescription').empty().html('<p class="previewElementName">' + selected_element['attrs']['elementName'] + '</p>' + selected_element['attrs']['description']);
        //            if (selected_element['attrs']['name'] == "parent") {
        //                $('.previewElementName').css('color', parentElementColor);
        //            } else {
        //                $('.previewElementName').css('color', childElementColor);
        //            }
        //            selected_element.find('Circle')[0].stroke(selectedElementColor);
        //        }
        //    }
        //    previewStage.draw();
        });
    });
    previewStage.find('.parent').show();
    previewStage.draw();
    previewStage.on('click tap touchstart', function(e) {
        if (e.target['className'] == "Rect") {
            selected_element = undefined;
            var allgroups = previewStage.find('Group');
            allgroups.forEach(function(entry) {
                resetGroup(entry);
            });
            previewStage.draw();
            $('#previewDescription').empty();
        }
    });

    function resetGroup(group) {
        var circle = group.find('Circle')[0];
        if (group['attrs']['name'] == 'parent') {
            circle.stroke(parentElementColor);
        } else {
            circle.stroke(childElementColor);
        }
    }

    function showChildren(group) {
        var name = group['attrs']['id'] + 'child';
        var children = previewStage.find('.' + name + '');
        group['attrs']['childVisible'] = true;
        if (children.length != 0) {
            children.forEach(function(entry) {
                entry.show();
            });
        }
        previewStage.draw();
    }

    function hideChildren(group) {
        var name = group['attrs']['id'] + 'child';
        var children = previewStage.find('.' + name + '');
        group['attrs']['childVisible'] = false;
        if (children.length != 0) {
            children.forEach(function(entry) {
                entry.hide();
                entry.find('.symbol')[0].text('+');
                hideChildren(entry);
            });
        }
        previewStage.draw();
    }

    function addPrefix(imageName) {
        var url = prefix + imageName;
        return url;
    }
}