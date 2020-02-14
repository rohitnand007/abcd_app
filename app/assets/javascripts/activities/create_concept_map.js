var selected_element,
    dataId = 0,
    stage_width = $('#canvas-region').outerWidth(true),
    stage_height = $('.canvas-btn').outerHeight(true) - $('.btn-row-create-concept').outerHeight(true),
    parentElementColor = '#df3f01',
    childElementColor = '#1ca45c',
    parentElementRadius = 50,
    childElementRadius = 40,
    maxElementRadius = 85,
    selectedElementColor = 'yellow',
    prefix = "download/",
    logoName = "";

tinymce.init({
    selector: '#node-description',
    plugins: 'textcolor image paste',
    content_css: ['/assets/activities/bootstrap_3.3.6.min.css', '/assets/activities/create_concept_map.css'],
    content_style: "img {max-width:377px}",
    //changes
    mode : "textareas",
    force_br_newlines : false,
    force_p_newlines : false,
    forced_root_block : '',
    //
    // paste_strip_class_attributes:'all',
    // paste_as_text: true,
    // paste_text_sticky: true,
    // paste_text_sticky_default: true,
    // paste_enable_default_filters: false,
    // paste_webkit_styles:"color",
    // paste_remove_styles_if_webkit: false,
    // paste_data_images: true,
    // paste_auto_cleanup_on_paste : true,
    paste_preprocess: function(plugin, args) {
        args.content = args.content.replace(/\<(?!img|br).*?\>/g, "");
    },
    automatic_uploads: true,
    browser_spellcheck: true,
    resize: false,
    min_height: 541,
    max_height: 541,
    menubar: false,
    statusbar: false,
    toolbar1: "dummy | formatselect | bold italic underline  bullist numlist  link  alignleft aligncenter alignright alignjustify  forecolor  insert",
    textcolor_map: [
        "202020", "",
        "0977aa", "",
        "898989", "",
        "0f7760", "",
        "d7450c", ""
    ],
    setup: function(ed) {
        ed.on('focusout', function() {
            if (selected_element != undefined) {
                selected_element['attrs']['description'] = tinyMCE.activeEditor.getContent();
            }
        });
        ed.on('keyup', function(e) {
            var string = tinyMCE.activeEditor.getContent();
            $('#content').empty().append(string);
            var changed = false;
            if ($('#content').find('img')[0] != undefined) {
                var array = $('#content').find('img');
                array.each(function() {
                    if ($(this).attr('data-source') == undefined) {
                        $(this).attr('data-source', 'changed');
                        $(this).attr('data-tempid', dataId);
                        dataId++;
                        changed = true;
                        image(e, $(this), function(uploaded_url, x) {
                            var newstring = tinyMCE.activeEditor.getContent();
                            $('#content1').empty().append(newstring);
                            var allImages = $('#content1').find('img');
                            allImages.each(function() {
                                if ($(this).attr('data-tempid') == x.attr('data-tempid')) {
                                    $(this).attr('src', imagePrefix(uploaded_url));
                                    $(this).attr('data-imgname', uploaded_url);
                                }
                            });
                            tinyMCE.activeEditor.setContent($('#content1').html());
                        });
                    }
                });
                if (changed == true) {
                    tinyMCE.activeEditor.setContent($('#content').html());
                }
            }
            if (selected_element != undefined) {
                selected_element['attrs']['description'] = tinyMCE.activeEditor.getContent();
            }
        });
        ed.addButton('dummy', {
            title: 'Add Image',
            icon: 'image',
            onclick: function() {
                ed.windowManager.open({
                    title: 'Add image',
                    body: [{
                        type: 'textbox',
                        subtype: 'file',
                        name: 'source',
                        label: 'Source'
                    }],
                    onsubmit: function(e) {
                        if (selected_element != undefined) {
                            var array = $('.mce-textbox');
                            array.each(function() {
                                if ($(this).attr('type') == 'file') {
                                    uploadFileInput($(this), function(uploaded_url) {
                                        var string = tinyMCE.activeEditor.getContent();
                                        string = string + '<img src="' + imagePrefix(uploaded_url) + '" data-source="changed" data-imgname="' + uploaded_url + '">';
                                        tinyMCE.activeEditor.setContent(string);
                                        if (selected_element != undefined) {
                                            selected_element['attrs']['description'] = string;
                                        }
                                    });
                                }
                            });
                        }
                    }
                });
            }
        });
    }
});

$(".next-page ").click(function(){
           $(".nav-pills > li").removeClass("active");
           $(".mynaming-tab").addClass("active");
    });
$(".concept-map-template").click(function(){
           $(".nav-pills > li").addClass("active");
           $(".mynaming-tab").removeClass("active");
    });

var z = 0;
var stage = new Konva.Stage({
    container: 'canvas-region',
    width: stage_width,
    height: stage_height
});
var layer = new Konva.Layer();
stage.add(layer);
var bg = new Konva.Rect({
    width: stage.getWidth(),
    height: stage.getHeight(),
    x: 0,
    y: 0,
    name: 'background'
});
layer.add(bg);
stage.draw();

$('#element-name').val('').prop('disabled', true);

$('.maincontent').hide();

$('.next-page').click(function() {
    $('.form-content').hide();
    $('.maincontent').show();
    if (selected_element == undefined) {
        tinymce.activeEditor.getBody().setAttribute('contenteditable', false);
    }
});

$('.concept-map-template').click(function() {
    $('.maincontent').hide();
    $('.form-content').show();
});

$('#add-child').click(function() {
    addChild();
});

$('#delete-element').click(function() {
    deleteElement(null);
});

$('#show-complete').click(function() {
    showComplete();
});

$('#save-name').click(function() {
    if (selected_element != undefined) {
        selected_element['attrs']['elementName'] = $('#element-name').val();
        selected_element['attrs']['tempElementName'] = $('#element-name').val();
        selected_element.find('.elementName')[0].text($('#element-name').val());
        setText(selected_element);
        stage.draw();
    }
});

$('#preview').mousedown(function(event) {
    if (selected_element != undefined) {
        selected_element['attrs']['description'] = tinyMCE.activeEditor.getContent();
    }
    $(this).contextmenu(function() {
        return false;
    });
    var keycode = event.which;
    var json = createJson();
    if (keycode == 1 && stage.find('Group').length != 0) {
        $('.modal-dialog').css('height', stage_height + 30);
        $('#ModalForPreview').modal('show');
        $('.previewBody').previewConceptMap(json, prefix);
    } else if (keycode == 1 && stage.find('Group').length == 0) {
        $.alert({
            title: 'Notification',
            content: 'Add Elements before clicking preview',
            confirmButtonClass: 'error-confirm',
            confirm: function() {}
        });
    } else if (keycode == 3) {
        var url = document.location.origin + '/ignitor-web/play_concept_map.html?value=' + JSON.stringify(json) + '';
        window.open(url, '_blank');
    }
});

$('#save-template').click(function() {
    if (selected_element != undefined) {
        selected_element['attrs']['description'] = tinyMCE.activeEditor.getContent();
    }
    var json = createJson();
    //TO DO:send ajax request with the json created below
    //var url = document.location.origin + '/ignitor-web/concept_map.html?value=' + JSON.stringify(json) + '';
    //window.open(url, '_blank');
    $.ajax({
        url: "/learning_activities",
        dataType: 'json',
        type: 'POST',
        data:  JSON.stringify(json),
        contentType: "application/json; charset=utf-8",
        cache: false,
        success: function(data, textStatus, jqXHR)
        {
            window.history.pushState({},"new url","/learning_activities");
            window.location.reload();

        },
        error: function(jqXHR, textStatus, errorThrown)
        {
            alert("Error in saving");
        }
    });
});

stage.on('click', function(e) {
    if (e.target['attrs']['name'] == "background") {
        var allGroups = stage.find('Group');
        for (i = 0; i < allGroups.length; i++) {
            if (allGroups[i]['attrs']['selected'] == true) {
                allGroups[i]['attrs']['selected'] = false;
                resetGroup(allGroups[i]);
            }
        }
        selected_element = undefined;
        $('#element-name').val('');
        $('#element-name').prop('disabled', true);
        $('#save-name').css('background-color','#c2c2c2');
        $('#save-name').css('border','1px solid #c2c2c2');
        tinymce.activeEditor.getBody().setAttribute('contenteditable', false);
        tinyMCE.activeEditor.setContent('');
    }
    if (selected_element != undefined) {
        var allGroups = stage.find('Group');
        allGroups.forEach(function(group) {
            resetGroup(group);
        });
        $('#element-name').prop('disabled', false);
        tinymce.activeEditor.getBody().setAttribute('contenteditable', true);
        selected_element.find('Circle')[0].stroke(selectedElementColor);
        stage.draw();
    } else {
        var allGroups = stage.find('Group');
        allGroups.forEach(function(group) {
            resetGroup(group);
        });
        stage.draw();
    }
});

function createJson() {
    var formData = $('.form-horizontal').serializeArray();
    if (stage.find('.parent').length != 0) {
        stage.find('.parent')[0]['attrs']['indexofid'] = z;
    }
    var imagesArray = [];
    stage.find('Group').forEach(function(entry) {
        $('#content3').empty().html(entry['attrs']['description']);
        $('#content3').find('img').each(function() {
            imagesArray.push($(this).data('imgname'));
        });
    });
    var stageJson = stage.toJSON();

    //Generate Data
    var otherData = {};
    for(x in formData){
        console.log(x);
        otherData[formData[x]['name']] = formData[x]['value'];
    }
    otherData["name"] = otherData["contentName"];
    console.log("OtherData");
    console.log(otherData);
    var json = {
        'formdata': formData,
        'stagedata': stageJson,
        'images': imagesArray,
        'logo': logoName,
        'learning_activity_type': 'concept_map',
        'name': otherData['contentName'],
        'class': otherData['class'],
        'subject': otherData['subject'],
        'topics': otherData['topics'],
        'description': otherData['description']
    };
    console.log("jsonData");
    console.log(json);
    return json;
}

//adding elements
function addChild() {
    if (stage.find('Circle').length == 0) {
        var parentGroup = new Konva.Group({
            x: 100,
            y: 100,
            id: z,
            name: 'parent',
            selected: true,
            draggable: true,
            description: '',
            childVisible: true,
            dragBoundFunc: function(pos) {
                var radius = parentGroup.find('Circle')[0].radius();
                var newX = pos.x;
                var newY = pos.y;
                if ((pos.x - radius) < 3) {
                    newX = radius + 3;
                } else if ((pos.x + radius) > stage.getWidth() - 5) {
                    newX = stage.getWidth() - radius - 5;
                }
                if ((pos.y - radius) < 5) {
                    newY = radius + 5;
                } else if ((pos.y + radius) > stage.getHeight() - 5) {
                    newY = stage.getHeight() - radius - 5;
                }
                return {
                    x: newX,
                    y: newY
                };
            }
        });
        $('#save-name').css('background-color','#76C4AC');
        $('#save-name').css('border','1px solid #76C4AC');
        stage.find('Layer')[0].add(parentGroup);
        parentGroup.add(new Konva.Circle({
            x: 0,
            y: 0,
            radius: parentElementRadius,
            fill: parentElementColor,
            stroke: selectedElementColor,
            strokeWidth: 2,
            draggable: false,
            shadowColor: 'black',
            shadowBlur: 10,
            shadowOffset: {
                x: 1,
                y: 1
            },
            shadowOpacity: 0.5
        }));
        parentGroup.add(new Konva.Text({
            x: 0,
            y: 0,
            text: 'Element',
            fontSize: 14,
            fontFamily: 'Arial',
            fontStyle: 'bold',
            draggable: false,
            fill: 'white',
            name: 'elementName'
        }));
        parentGroup.add(new Konva.Text({
            x: -2,
            y: 5,
            text: '-',
            fontSize: 14,
            fontFamily: 'Arial',
            fontStyle: 'bold',
            draggable: false,
            fill: 'white',
            name: 'symbol'
        }));
        parentGroup.find('.symbol')[0].hide();
        setText(parentGroup);
        parentGroup.setZIndex(5);
        parentGroup.on('dragmove', function(e) {
            updateLine(e.target);
        });
        parentGroup['attrs']['tempElementName'] = "Element";
        parentGroup['attrs']['elementName'] = "Element";
        parentGroup.on('click', function(e) {
            if (selected_element == e.target.getParent()) {
                var checked = false;
                if (e.target.getParent()['attrs']['childVisible'] == true && checked == false) {
                    hideChildren(e.target.getParent());
                    parentGroup.find('.symbol')[0].text('+');
                    checked = true;
                } else if (e.target.getParent()['attrs']['childVisible'] == false && checked == false) {
                    showChildren(e.target.getParent());
                    parentGroup.find('.symbol')[0].text('-');
                    checked = true;
                }
            }
            selected_element = e.target.getParent();
            tinyMCE.activeEditor.setContent(selected_element['attrs']['description']);
            $('#save-name').css('background-color','#76C4AC');
            $('#save-name').css('border','1px solid #76C4AC');
            $('#element-name').val(selected_element['attrs']['elementName']);
            e.target.getParent()['attrs']['selected'] = true;
        });
        parentGroup.on('mouseover', function() {
            document.body.style.cursor = 'pointer';
        });
        parentGroup.on('mouseout', function() {
            document.body.style.cursor = 'default';
        });
        parentGroup.find('.symbol')[0].on('click', function(e) {
            e.cancelBubble = true;
            var checked = false;
            if (this.getParent()['attrs']['childVisible'] == true && checked == false) {
                hideChildren(this.getParent());
                this.getParent().find('.symbol')[0].text('+');
                checked = true;
            } else if (this.getParent()['attrs']['childVisible'] == false && checked == false) {
                showChildren(this.getParent());
                this.getParent().find('.symbol')[0].text('-');
                checked = true;
            }
            if (selected_element != undefined) {
                var id = parseInt(selected_element['attrs']['name']);
                if (parentGroup['attrs']['id'] == id) {
                    stage.find('Group').forEach(function(entry) {
                        resetGroup(entry);
                    });
                    selected_element = parentGroup;
                    tinyMCE.activeEditor.setContent(selected_element['attrs']['description']);
                    $('#element-name').val(selected_element['attrs']['elementName']);
                    selected_element.find('Circle')[0].stroke(selectedElementColor);
                }
            }
            stage.draw();
        });
        selected_element = parentGroup;
        $('#element-name').val('Element').prop('disabled', false);
        tinymce.activeEditor.getBody().setAttribute('contenteditable', true);
    } else {
        if (selected_element != undefined) {
            if (selected_element['attrs']['childVisible'] == false) {
                showChildren(selected_element);
                selected_element.find('.symbol')[0].text('-');
            }
            selected_element.find('.symbol')[0].show();
            var startX = selected_element.find('Circle')[0].x() + selected_element.x();
            var startY = selected_element.find('Circle')[0].y() + selected_element.y();
            var name = selected_element['attrs']['id'] + 'child';
            if (stage.find('.parent')[0]['attrs']['id'] == selected_element['attrs']['id']) {
                var color = parentElementColor;
            } else {
                var color = childElementColor;
            }
            var childGroup = new Konva.Group({
                x: 300,
                y: 300,
                id: z,
                name: name,
                draggable: true,
                description: '',
                childVisible: false,
                dragBoundFunc: function(pos) {
                    var radius = childGroup.find('Circle')[0].radius();
                    var newX = pos.x;
                    var newY = pos.y;
                    if ((pos.x - radius) < 3) {
                        newX = radius + 3;
                    } else if ((pos.x + radius) > stage.getWidth() - 5) {
                        newX = stage.getWidth() - radius - 5;
                    }
                    if ((pos.y - radius) < 5) {
                        newY = radius + 5;
                    } else if ((pos.y + radius) > stage.getHeight() - 5) {
                        newY = stage.getHeight() - radius - 5;
                    }
                    return {
                        x: newX,
                        y: newY
                    };
                }
            });
            stage.find('Layer')[0].add(childGroup);
            childGroup.add(new Konva.Circle({
                x: 0,
                y: 0,
                radius: childElementRadius,
                fill: childElementColor,
                stroke: childElementColor,
                strokeWidth: 2,
                draggable: false,
                shadowColor: 'black',
                shadowBlur: 10,
                shadowOffset: {
                    x: 1,
                    y: 1
                },
                shadowOpacity: 0.5
            }));
            randomPosition(childGroup);
            var endX = childGroup.find('Circle')[0].x();
            var endY = childGroup.find('Circle')[0].y();
            childGroup.add(new Konva.Line({
                points: [startX - childGroup.x(), startY - childGroup.y(), endX, endY],
                stroke: color,
                strokeWidth: 5,
                lineCap: 'round',
                lineJoin: 'round',
                name: 'connecting',
                draggable: false,
            }));
            childGroup.add(new Konva.Text({
                x: 0,
                y: 0,
                text: 'Element',
                fontSize: 14,
                fontFamily: 'Arial',
                fontStyle: 'bold',
                fill: 'white',
                name: 'elementName'
            }));
            childGroup.add(new Konva.Text({
                x: -2,
                y: 5,
                text: '+',
                fontSize: 14,
                fontFamily: 'Arial',
                fontStyle: 'bold',
                fill: 'white',
                name: 'symbol'
            }));
            childGroup.find('.symbol')[0].hide();
            setText(childGroup);
            lineStartPoints(childGroup.find('Line')[0], selected_element);
            addArrow(childGroup);
            updateArrow(childGroup);
            childGroup['attrs']['tempElementName'] = "Element";
            childGroup['attrs']['elementName'] = "Element";
            childGroup.find('Line').setZIndex(0);
            childGroup.on('dragmove', function(e) {
                updateLine(e.target);

            });
            childGroup.on('click', function(e) {
                if (selected_element == e.target.getParent()) {
                    var checked = false;
                    if (e.target.getParent()['attrs']['childVisible'] == true && checked == false) {
                        hideChildren(e.target.getParent());
                        childGroup.find('.symbol')[0].text('+');
                        checked = true;
                    } else if (e.target.getParent()['attrs']['childVisible'] == false && checked == false) {
                        showChildren(e.target.getParent());
                        childGroup.find('.symbol')[0].text('-');
                        checked = true;
                    }
                }
                selected_element = e.target.getParent();
                tinyMCE.activeEditor.setContent(selected_element['attrs']['description']);
                $('#element-name').val(selected_element['attrs']['elementName']);
                e.target.getParent()['attrs']['selected'] = true;
            });
            childGroup.on('mouseover', function() {
                document.body.style.cursor = 'pointer';
            });
            childGroup.on('mouseout', function() {
                document.body.style.cursor = 'default';
            });
            childGroup.find('.symbol')[0].on('click', function(e) {
                e.cancelBubble = true;
                var checked = false;
                if (this.getParent()['attrs']['childVisible'] == true && checked == false) {
                    hideChildren(this.getParent());
                    this.getParent().find('.symbol')[0].text('+');
                    checked = true;
                } else if (this.getParent()['attrs']['childVisible'] == false && checked == false) {
                    showChildren(this.getParent());
                    this.getParent().find('.symbol')[0].text('-');
                    checked = true;
                }
                if (selected_element != undefined) {
                    var id = parseInt(selected_element['attrs']['name']);
                    if (childGroup['attrs']['id'] == id) {
                        stage.find('Group').forEach(function(entry) {
                            resetGroup(entry);
                        });
                        selected_element = childGroup;
                        tinyMCE.activeEditor.setContent(selected_element['attrs']['description']);
                        $('#element-name').val(selected_element['attrs']['elementName']);
                        selected_element.find('Circle')[0].stroke(selectedElementColor);
                    }
                }
                stage.draw();
            });
        } else {
            $.alert({
                title: 'Notification',
                content: 'Please select element before adding child',
                confirmButtonClass: 'error-confirm',
                confirm: function() {}
            });
        }
    }
    z++;
    stage.draw();
}

//updating line position on moving the element
function updateLine(group) {
    if (group['attrs']['name'] == "parent") {
        var name = group['attrs']['id'] + 'child';
        var children = stage.find('.' + name + '');
        children.forEach(function(child) {
            var line = child.find('Line')[0];
            var points = line.points();
            var newpoints = [];
            points[0] = group.find('Circle')[0].x() - child.x() + group.x();
            points[1] = group.find('Circle')[0].y() - child.y() + group.y();
            line.points(points);
            lineStartPoints(line, group);
            updateArrow(child);
        });
    } else {
        var id = parseInt(group['attrs']['name']);
        var allGroups = stage.find('Group');
        var parentGroup;
        allGroups.forEach(function(ele) {
            if (ele['attrs']['id'] == id) {
                parentGroup = ele;
            }
        });
        var line = group.find('Line')[0];
        var points = line.points();
        var newpoints = [];
        newpoints[0] = parentGroup.find('Circle')[0].x() + parentGroup.x() - group.x();
        newpoints[1] = parentGroup.find('Circle')[0].y() + parentGroup.y() - group.y();
        newpoints[2] = group.find('Circle')[0].x();
        newpoints[3] = group.find('Circle')[0].y();
        line.points(newpoints);
        lineStartPoints(line, parentGroup);
        updateArrow(group);
        var name = group['attrs']['id'] + 'child';
        var children = stage.find('.' + name + '');
        children.forEach(function(child) {
            var childLine = child.find('Line')[0];
            var childPoints = childLine.points();
            childPoints[0] = group.find('Circle')[0].x() - child.x() + group.x();
            childPoints[1] = group.find('Circle')[0].y() - child.y() + group.y();
            childLine.points(childPoints);
            lineStartPoints(childLine, child);
            updateArrow(child);
        });
    }
    stage.draw();
}

function deleteElement(id) {
    if (selected_element != undefined && id == null) {
        var siblings = stage.find('.' + selected_element['attrs']['name'] + '');
        if (siblings.length == 1) {
            var tempId = parseInt(selected_element['attrs']['name']);
            var allgroups = stage.find('Group');
            allgroups.forEach(function(entry) {
                if (entry['attrs']['id'] == tempId) {
                    entry.find('.symbol')[0].hide();
                }
            });
        }
        var name = selected_element['attrs']['id'] + 'child';
        var allChildren = stage.find('.' + name + '');
        selected_element.remove();
        if (allChildren.length != 0) {
            allChildren.forEach(function(entry) {
                deleteElement(entry['attrs']['id']);
            });
        }
        tinyMCE.activeEditor.setContent('');
    }
    if (id != null) {
        var allGroups = stage.find('Group');
        allGroups.forEach(function(entry) {
            if (entry['attrs']['id'] == id) {
                entry.remove();
            }
        });
        var name = id + 'child';
        var children = stage.find('.' + name + '');
        if (children.length != 0) {
            children.forEach(function(entry) {
                deleteElement(entry['attrs']['id']);
            });
        }
    }
    selected_element = undefined;
    $('#element-name').val('');
    $('#element-name').prop('disabled', true);
    tinymce.activeEditor.getBody().setAttribute('contenteditable', false);
    stage.draw();
}

//show all child elements
function showComplete() {
    stage.find('Layer')[0]['children'].show();
    var groups = stage.find('Group');
    groups.forEach(function(group) {
        group['attrs']['childVisible'] = true;
        group.find('.symbol')[0].text('-');
    });
    stage.draw();
}

function resetGroup(group) {
    var circle = group.find('Circle')[0];
    if (group['attrs']['name'] == 'parent') {
        circle.stroke(parentElementColor);
    } else {
        circle.stroke(childElementColor);
    }
}

//show all the child elements of the selected element
function showChildren(group) {
    var name = group['attrs']['id'] + 'child';
    var children = stage.find('.' + name + '');
    group['attrs']['childVisible'] = true;
    if (children.length != 0) {
        children.forEach(function(entry) {
            entry.show();
            entry.find('.symbol')[0].text('-');
            showChildren(entry);
        });
    }
    stage.draw();
}

//hide all the child elements of the selected element
function hideChildren(group) {
    var name = group['attrs']['id'] + 'child';
    var children = stage.find('.' + name + '');
    group['attrs']['childVisible'] = false;
    if (children.length != 0) {
        children.forEach(function(entry) {
            entry.hide();
            entry.find('.symbol')[0].text('+');
            hideChildren(entry);
        });
    }
    stage.draw();
}

//random position of the child element
function randomPosition(group) {
    var circle = group.find('Circle')[0];
    if (selected_element != undefined) {
        var centerX = selected_element.x() + selected_element.find('Circle')[0].x();
        var centerY = selected_element.y() + selected_element.find('Circle')[0].y();
        var x = stage.getWidth() * Math.random();
        var y = stage.getHeight() * Math.random();
        var distance = Math.pow((Math.pow((centerX - x), 2) + Math.pow((centerY - y), 2)), 0.5);
        if ((x - circle.radius()) > 0 && (y - circle.radius()) > 0 && (x + circle.radius()) < stage.getWidth() && (y + circle.radius()) < stage.getHeight() && distance > (circle.radius() + selected_element.find('Circle')[0].radius())) {
            group.x(x);
            group.y(y);
        } else {
            randomPosition(group);
        }
    }
}

function lineStartPoints(line, group) {
    var points = line.points();
    var x1 = points[0] + line.getParent().x();
    var y1 = points[1] + line.getParent().y();
    var x2 = points[2] + line.getParent().x();
    var y2 = points[3] + line.getParent().y();
    if ((x2 - x1) != 0) {
        var a = 1 + Math.pow(((y2 - y1) / (x2 - x1)), 2);
        var b = (2 * ((y2 - y1) / (x2 - x1)) * (y1 - ((y2 - y1) / (x2 - x1)) * x1)) - (2 * ((y2 - y1) / (x2 - x1)) * y1) - (2 * x1);
        var c = Math.pow((y1 - ((y2 - y1) / (x2 - x1)) * x1), 2) + Math.pow(x1, 2) + Math.pow(y1, 2) - Math.pow(group.find('Circle')[0].radius(), 2) - (2 * y1 * (y1 - ((y2 - y1) / (x2 - x1)) * x1));
        var startX1 = (-b + Math.pow((Math.pow(b, 2) - (4 * a * c)), 0.5)) / (2 * a);
        var startX2 = (-b - Math.pow((Math.pow(b, 2) - (4 * a * c)), 0.5)) / (2 * a);
        var startY1 = ((y2 - y1) / (x2 - x1)) * startX1 + (y1 - ((y2 - y1) / (x2 - x1)) * x1);
        var startY2 = ((y2 - y1) / (x2 - x1)) * startX2 + (y1 - ((y2 - y1) / (x2 - x1)) * x1);
    } else {
        var startX1 = x1;
        var startY1 = y1 + group.find('Circle')[0].radius();
        var startX2 = x1;
        var startY2 = y1 - group.find('Circle')[0].radius();
    }
    var distance1 = Math.pow((Math.pow((startX1 - x2), 2) + Math.pow((startY1 - y2), 2)), 0.5);
    var distance2 = Math.pow((Math.pow((startX2 - x2), 2) + Math.pow((startY2 - y2), 2)), 0.5);
    if (distance1 < distance2) {
        var finalX = startX1 - line.getParent().x();
        var finalY = startY1 - line.getParent().y();
    } else {
        var finalX = startX2 - line.getParent().x();
        var finalY = startY2 - line.getParent().y();
    }
    line.points([finalX, finalY, points[2], points[3]]);
}

function addArrow(group) {
    var points = group.find('Line')[0].points();
    var id = parseInt(group['attrs']['name']);
    if (stage.find('.parent')[0]['attrs']['id'] == id) {
        var color = parentElementColor;
    } else {
        var color = childElementColor;
    }
    group.add(new Konva.Arrow({
        x: 0,
        y: 0,
        points: points,
        pointerLength: 20,
        pointerWidth: 20,
        fill: color,
        stroke: 'black',
        strokeWidth: 4,
        strokeEnabled: false
    }));
}

function updateArrow(group) {
    var points = group.find('Line')[0].points();
    var distance = Math.pow((Math.pow(points[0] - points[2], 2) + Math.pow(points[1] - points[3], 2)), 0.5) - group.find('Circle')[0].radius();
    var arrows = group.find('Arrow');
    if (distance > 0) {
        arrows.show();
        var requiredArrows = Math.floor(distance / 100);
        if (requiredArrows >= 1) {
            if (arrows.length < requiredArrows) {
                var diff = requiredArrows - arrows.length;
                for (i = 0; i < diff; i++) {
                    addArrow(group, 'black');
                    stage.draw();
                }
            } else if (arrows.length > requiredArrows) {
                var diff = arrows.length - requiredArrows;
                for (i = 0; i < diff; i++) {
                    arrows[i].remove();
                    arrows = group.find('Arrow');
                }
            }
        }
        var finalArrows = group.find('Arrow');
        var k = (distance / (finalArrows.length + 1)) + 15;
        for (i = 0; i < finalArrows.length; i++) {
            arrowPositions(points, finalArrows[i], (i + 1) * k);
        }
    } else if (distance < 0) {
        arrows.hide();
    }
}

function arrowPositions(points, arrow, distance) {
    var x1 = points[0];
    var y1 = points[1];
    var x2 = points[2];
    var y2 = points[3];
    if ((x2 - x1) != 0) {
        var slope = (y2 - y1) / (x2 - x1);
        var positionX1 = Math.pow((Math.pow(distance, 2) / (1 + Math.pow(slope, 2))), 0.5) + x1;
        var positionX2 = -Math.pow((Math.pow(distance, 2) / (1 + Math.pow(slope, 2))), 0.5) + x1;
        var positionY1 = y1 + slope * (positionX1 - x1);
        var positionY2 = y1 + slope * (positionX2 - x1);
    } else {
        var positionX1 = x1;
        var positionY1 = y1 - distance;
        var positionX2 = x1;
        var positionY2 = y1 + distance;
    }
    var distance1 = Math.pow((Math.pow(positionX1 - x2, 2) + Math.pow(positionY1 - y2, 2)), 0.5);
    var distance2 = Math.pow((Math.pow(positionX2 - x2, 2) + Math.pow(positionY2 - y2, 2)), 0.5);
    if (distance1 < distance2) {
        var finalX = positionX1;
        var finalY = positionY1;
    } else {
        var finalX = positionX2;
        var finalY = positionY2;
    }
    arrow.points(points);
    arrow.x(finalX);
    arrow.y(finalY);
}

function setText(group) {
    var text = group.find('.elementName')[0];
    var circle = group.find('Circle')[0];
    var symbol = group.find('.symbol')[0];
    text.fontSize(14);
    if (group['attrs']['tempElementName']) {
        text.text(group['attrs']['tempElementName']);
        if (text.width() > (circle.radius() * 2)) {
            textSize(circle, text);
        }
    }
    if (group['attrs']['name'] == 'parent') {
        var minRadius = parentElementRadius * 2;
    } else {
        var minRadius = childElementRadius * 2;
    }
    if (text.width() < minRadius) {
        circle.radius(minRadius * 0.5);
    } else if (text.width() > minRadius) {
        circle.radius((text.width() + 5) * 0.5);
    } else if (text.width() > minRadius && text.width() > (maxElementRadius) * 2) {
        circle.radius(maxElementRadius);
    }
    var finalX = circle.x() - text.width() * 0.5;
    var finalY = circle.y() - text.height() * 0.5;
    text.x(finalX);
    text.y(finalY);
    symbol.y(0.5 * text.height() + 5);
};

function textSize(shape, text) {
    var group = shape.getParent();
    var symbol = group.find('.symbol')[0];
    var w = shape.radius() * 2;
    if (text.fontSize() > 12) {
        if (text['textWidth'] > w) {
            text.fontSize(12);
            textSize(shape, text);
        }
    } else {
        var characters = text.text().length;
        var numberOfLines = Math.ceil(characters / 20);
        var string = "";
        for (i = 0; i < numberOfLines; i++) {
            if (characters < ((i + 1) * 20)) {
                string = string + text.text().substring((i * 20), characters);
            } else {
                if (text.text().substring((((i + 1) * 20) - 1), ((i + 1) * 20)) == " " || text.text().substring((((i + 1) * 20)), (((i + 1) * 20) + 1)) == " ") {
                    string = string + text.text().substring((i * 20), (((i + 1) * 20))) + '\n';
                } else {
                    if (characters != ((i + 1) * 20)) {
                        string = string + text.text().substring((i * 20), ((i + 1) * 20)) + '-\n';
                    } else {
                        string = string + text.text().substring((i * 20), ((i + 1) * 20)) + '\n';
                    }
                }
            }
        }
        text.text(string);
    }
};

function getTextWidth(text, fonter) {
    var canvas = getTextWidth.canvas || (getTextWidth.canvas = document.createElement("canvas"));
    var context = canvas.getContext("2d");
    context.font = fonter;
    var metrics = context.measureText(text);
    return metrics.width;
};

//upload images through url
function image(e, x, successFunc) {
    uploadUrl(e, x.attr('src'), 'uploadurl', function(data, textStatus, jqXHR, uploaded_url) {
        uploaded_url = uploaded_url.substring(uploaded_url.indexOf("image_"));
        successFunc(uploaded_url, x);
    }, function(jqXHR, textStatus, errorThrown) {
        failFunc(uploaded_url);
    });
};

//upload images through file selection
function uploadFileInput(x, successFunc, failFunc) {
    x.get(0).files;
    uploadFile(x.get(0).files, 'uploadfile', function(data, textStatus, jqXHR, uploaded_url) {
        uploaded_url = uploaded_url.substring(uploaded_url.indexOf("image_"));
        successFunc(uploaded_url);
    }, function(jqXHR, textStatus, errorThrown) {
        failFunc(uploaded_url);
    });
};

function restoreConceptMap(json) {
    json['formdata'].forEach(function(array) {
        $('.form-horizontal [name="' + array['name'] + '"]').val(array['value']);
    });
    $('#canvas-region').remove();
    $('.canvas-btn').append('<div id="canvas-region"></div>');
    stage = Konva.Node.create(json['stagedata'], 'canvas-region');
    if (stage.find('.parent').length != 0) {
        z = stage.find('.parent')[0]['attrs']['indexofid'];
    }
    stage.find('Group').forEach(function(group) {
        $('#content2').empty().html(group['attrs']['description']);
        $('#content2').find('img').each(function() {
            $(this).attr('src', imagePrefix($(this).data('imgname')));
        });
        group['attrs']['description'] = $('#content2').html();
        group['attrs']['dragBoundFunc'] = function(pos) {
            var radius = group.find('Circle')[0].radius();
            var newX = pos.x;
            var newY = pos.y;
            if ((pos.x - radius) < 3) {
                newX = radius + 3;
            } else if ((pos.x + radius) > stage.getWidth() - 5) {
                newX = stage.getWidth() - radius - 5;
            }
            if ((pos.y - radius) < 5) {
                newY = radius + 5;
            } else if ((pos.y + radius) > stage.getHeight() - 5) {
                newY = stage.getHeight() - radius - 5;
            }
            return {
                x: newX,
                y: newY
            };
        };
        group.on('click', function() {
            if (selected_element == this) {
                var checked = false;
                if (this['attrs']['childVisible'] == true && checked == false) {
                    hideChildren(this);
                    this.find('.symbol')[0].text('+');
                    checked = true;
                } else if (this['attrs']['childVisible'] == false && checked == false) {
                    showChildren(this);
                    this.find('.symbol')[0].text('-');
                    checked = true;
                }
            }
            selected_element = this;
            tinyMCE.activeEditor.setContent(selected_element['attrs']['description']);
            $('#element-name').val(this['attrs']['elementName']);
            this['attrs']['selected'] = true;
            stage.draw();
        });
        group.on('dragmove', function(e) {
            updateLine(e.target);
        });
        group.on('mouseover', function() {
            document.body.style.cursor = 'pointer';
        });
        group.on('mouseout', function() {
            document.body.style.cursor = 'default';
        });
        group.find('.symbol')[0].on('click', function(e) {
            e.cancelBubble = true;
            var checked = false;
            if (this.getParent()['attrs']['childVisible'] == true && checked == false) {
                hideChildren(this.getParent());
                this.getParent().find('.symbol')[0].text('+');
                checked = true;
            } else if (this.getParent()['attrs']['childVisible'] == false && checked == false) {
                showChildren(this.getParent());
                this.getParent().find('.symbol')[0].text('-');
                checked = true;
            }
            if (selected_element != undefined) {
                var id = parseInt(selected_element['attrs']['name']);
                if (group['attrs']['id'] == id) {
                    stage.find('Group').forEach(function(entry) {
                        resetGroup(entry);
                    });
                    selected_element = group;
                    tinyMCE.activeEditor.setContent(selected_element['attrs']['description']);
                    $('#element-name').val(selected_element['attrs']['elementName']);
                    selected_element.find('Circle')[0].stroke(selectedElementColor);
                }
            }
            stage.draw();
        });
        resetGroup(group);
        stage.draw();
    });
    stage.on('click', function(e) {
        if (e.target['attrs']['name'] == "background") {
            var allGroups = stage.find('Group');
            for (i = 0; i < allGroups.length; i++) {
                if (allGroups[i]['attrs']['selected'] == true) {
                    allGroups[i]['attrs']['selected'] = false;
                    resetGroup(allGroups[i]);
                }
            }
            selected_element = undefined;
            $('#element-name').val('');
            $('#element-name').prop('disabled', true);
            tinymce.activeEditor.getBody().setAttribute('contenteditable', false);
            tinyMCE.activeEditor.setContent('');
        }
        if (selected_element != undefined) {
            var allGroups = stage.find('Group');
            allGroups.forEach(function(group) {
                resetGroup(group);
            });
            $('#element-name').prop('disabled', false);
            tinymce.activeEditor.getBody().setAttribute('contenteditable', true);
            selected_element.find('Circle')[0].stroke(selectedElementColor);
            stage.draw();
        } else {
            var allGroups = stage.find('Group');
            allGroups.forEach(function(group) {
                resetGroup(group);
            });
            stage.draw();
        }
    });
}

$(document).ready(function() {

    //TODO: change this to check if this edit view.
    if (document.URL.split('?')[1]) {
        //TODO: get activity id instead of actual json from url
        var json = document.URL.split('?value=')[1];
        if (json) {
            var finaljson = JSON.parse(decodeURIComponent(json));
            //TODO: get the json with ajax request with the above id and call the below function with the result json.
            restoreConceptMap(finaljson);
        }
    }
});

$(".logo-btn").click(function() {
    $(".logo-upload").trigger("click");
});
$('.logo-upload').click(function(event) {
    this.value = '';
});
$('.logo-upload').change(function(event) {
    newLogoImage(event);
});

function newLogoImage(event) {
    var logoclass = $(event.target);
    uploadLogo(logoclass, function(url) {
        $(".logo-btn").find("img").attr("src", url);
        logoName = url.split(prefix)[1];
    }, function(url) {
        $.alert({
            title: 'Notification',
            content: 'Unable to upload image to server',
            confirmButtonClass: 'error-confirm',
            confirm: function() {}
        });
    })
}

function uploadLogo(logoclass, succesFunc, failureFunc) {
    var files = $(logoclass).get(0).files;
    uploadFile(files, "uploadfile", function(data, textStatus, jqXHR, uploaded_url) {
        succesFunc(uploaded_url);
    }, function(data, textStatus, errorThrown) {
        $.alert({
            title: 'Notification',
            content: 'Unable to upload image',
            confirmButtonClass: 'error-confirm',
            confirm: function() {}
        });
    });
}