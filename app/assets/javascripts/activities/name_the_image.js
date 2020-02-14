//Js file for naming the image template
var naming = {
    maximgwidth_ans: 200,
    maximgheight_ans: 200,
    minwidth_tag: 176,
    maxwidth_tag: 300,
    z: 0,
    minheight_tag: 40,
    bgimg_width: ($('#questions').width() * $('.col-xs-10').width() / 100) - 30,
    nametag_maxlen: 60,
    description_maxlen: 350,
    stageHeight: 558,
    nametagImg_w: 100,
    nametagImg_h: 110,
    prefix:'download/',
    options_limit :0,
    max_limit:6,
    logo : '',
    minbgwidth:800,
    minbgheight:500
};
// stages and layers
// stage for nametag

$('#canvas_region').width(naming.bgimg_width);
var stage = new Konva.Stage({
    container: 'canvas_region',
    width: naming.bgimg_width,
    height: naming.stageHeight
});
var layer = new Konva.Layer();
stage.add(layer);
stage.draw();
//stage for nametag options
var nametagstage = new Konva.Stage({
    container: 'nametag',
    width: 60,
    height: 70
});
var nametaglayer = new Konva.Layer();

//stage for area tag options
var areatagstage = new Konva.Stage({
    container: 'areatag',
    width: 100,
    height: 70
});

var areataglayer = new Konva.Layer();

//nametag creation
var nametag = new Konva.Line({
    points: [11, 10, 41, 10, 41, 40, 11, 40, 1, 25, 11, 10],
    stroke: 'black',
    strokeWidth: 2,
    closed: true,
    transformsEnabled: 'position',
    shadowColor: 'black',
    shadowBlur: 1,
    shadowOffset: {
        x: 2,
        y: 2
    },
    shadowOpacity: 0.5
});

var nametagcircle = new Konva.Circle({
    x: 6,
    y: 25,
    stroke: '#000000',
    strokeWidth: 1,
    radius: 2,
    shadowColor: 'black',
    shadowBlur: 1,
    shadowOffset: {
        x: 2,
        y: 2
    },
    shadowOpacity: 0.5
});

nametaglayer.add(nametag).add(nametagcircle);
nametagstage.add(nametaglayer);

nametag.on('click tap', function() {
    if(naming.z < 6){
        createNameTag();
    }else{
        err('Maximum number of tags have been added');
        //tagLimit();
    }
});

nametag.on('mouseover', function(e) {
    var nameTag = e.target;
    var nameTagCircle = nametaglayer.find('Circle');
    nameTagCircle.stroke('#76c4ac');
    nameTag.stroke('#76c4ac');
    document.body.style.cursor = 'pointer';
    nametaglayer.draw();
});

nametag.on('mouseout', function(e) {
    var nameTag = e.target;
    var nameTagCircle = nametaglayer.find('Circle');
    nameTagCircle.stroke('black');
    nameTag.stroke('black');
    document.body.style.cursor = 'default';
    nametaglayer.draw();
});

//for area tag options
var areaRect = new Konva.Rect({
    x: 1,
    y: 10,
    width: 30,
    height: 30,
    stroke: '#000000',
    strokeWidth: 2,
    shadowColor: 'black',
    shadowBlur: 1,
    shadowOffset: {
        x: 2,
        y: 2
    },
    shadowOpacity: 0.5,
    name: 'arearect',
    draggable: false,
    transformsEnabled: 'position',
    cornerRadius: 2
});

var areaCirc = new Konva.Circle({
    x: 61,
    y: 23,
    radius: 15,
    stroke: '#000000',
    name: 'droppable',
    strokeWidth: 2,
    shadowColor: 'black',
    shadowBlur: 1,
    shadowOffset: {
        x: 2,
        y: 2
    },
    shadowOpacity: 0.5
});
areataglayer.add(areaCirc).add(areaRect);
areatagstage.add(areataglayer);

areaRect.on('click tap', function() {
    if(naming.z < 6){
        createRectangle();
    }else{
        err('Maximum number of tags have been added');
        //tagLimit();
    }
});

areaRect.on('mouseover', function(e) {
    var areaTag = e.target;
    areaTag.stroke('#76c4ac');
    document.body.style.cursor = 'pointer';
    areataglayer.draw();
});

areaRect.on('mouseout', function(e) {
    var areaTag = e.target;
    areaTag.stroke('#000000');
    document.body.style.cursor = 'default';
    areataglayer.draw();
});


areaCirc.on('click tap', function() {
    if(naming.z < 6){
        createCircle();
    }else{
        err('Maximum number of tags have been added');
        //tagLimit();
    }
});

areaCirc.on('mouseover', function(e) {
    var areaTag = e.target;
    areaTag.stroke('#76c4ac');
    document.body.style.cursor = 'pointer';
    areataglayer.draw();
});

areaCirc.on('mouseout', function(e) {
    var areaTag = e.target;
    areaTag.stroke('#000000');
    document.body.style.cursor = 'default';
    areataglayer.draw();
});

// functions
//function for loading the stage and layers
function loadStage(img) {
    //stage.find('.bgimage').remove();
    var x=0,y=0;
    if(stage.find('.bgimage')[0]){
        x= stage.find('.bgimage')[0]['attrs']['x'];
        y= stage.find('.bgimage')[0]['attrs']['y'];
        stage.find('.bgimage').remove();
    }

    var imageBg = new Image();
    imageBg.onload = function() {
        var india = new Konva.Image({
            x: x,
            y: y,
            image: imageBg,
            draggable: false,
            src: img,
            dragBoundFunc: function(pos) {
                var stage = this.getStage();
                var finalX = this.width() + pos.x;
                var finalY = this.height() + pos.y;
                if (pos.x < 0) {
                    var newX = 0;
                } else if (finalX > stage.width()) {
                    var newX = stage.width() - this.width();
                } else {
                    var newX = pos.x;
                }
                if (pos.y < 0) {
                    var newY = 0;
                } else if (finalY > stage.height()) {
                    var newY = stage.height() - this.height();
                } else {
                    var newY = pos.y;
                }
                return {
                    x: newX,
                    y: newY
                };
            },
            name: 'bgimage'
        });
        stage.find('Layer')[0].add(india);
        india.setZIndex(0);
        stage.draw();
        check();
    };
    imageBg.src = imagePrefix(img);
    $('.lock').hide();
    $('.unlock').show();

};

//creating rectangular area tag
function createRectangle() {
    var color = '#' + Math.floor(Math.random() * 16777215).toString(16);
    var rectGroup = new Konva.Group({
        x: 180,
        y: 50,
        id: naming.z
    });
    stage.find('Layer')[0].add(rectGroup);
    rectGroup.add(new Konva.Rect({
        x: 0,
        y: 0,
        width: 100,
        height: 100,
        stroke: color,
        strokeWidth: 4,
        name: 'droppable',
        id: naming.z,
        transformsEnabled: 'position',
        cornerRadius: 2,
        shadowColor: '#b3b3b3',
        shadowBlur: 1,
        shadowOffset: {
            x: 2,
            y: 2
        },
        shadowOpacity: 0.5
    }));
    var black = "#000000";
    addAnchor(rectGroup, 0, 0, 'topLeft', black);
    addAnchor(rectGroup, 100, 0, 'topRight', black);
    addAnchor(rectGroup, 100, 100, 'bottomRight', black);
    addAnchor(rectGroup, 0, 100, 'bottomLeft', black);
    addEditButton(rectGroup, 50, 0, color);
    addDeleteIcon(rectGroup, 100, 50, color);
    naming.z++;
    rectGroup.setZIndex(1);
    rectGroup.setDraggable(true);
    rectGroup['attrs']['dragBoundFunc'] = function(pos) {
        var stage = rectGroup.getStage();
        var finalX = rectGroup.find('.delete')[0].x() + pos.x;
        var finalY = rectGroup.find('.bottomRight')[0].y() + pos.y;
        var topLeft = rectGroup.find('.topLeft')[0];
        if ((topLeft.x() + pos.x) < 5) {
            var newX = 5 - topLeft.x();
        } else if (finalX > (stage.width() - 20)) {
            var newX = stage.width() - 20 - rectGroup.find('.delete')[0].x();
        } else {
            var newX = pos.x;
        }
        if ((topLeft.y() + pos.y) < 20) {
            var newY = 20 - topLeft.y();
        } else if (finalY > (stage.height() - 10)) {
            var newY = stage.height() - 10 - rectGroup.find('.bottomRight')[0].y();
        } else {
            var newY = pos.y;
        }
        return {
            x: newX,
            y: newY
        };
    }
    stage.find('Layer')[0].draw();
};

//creating circular area tag
function createCircle() {
    var color = '#' + Math.floor(Math.random() * 16777215).toString(16);
    var circGroup = new Konva.Group({
        x: 180,
        y: 50,
        id: naming.z
    });
    stage.find('Layer')[0].add(circGroup);
    circGroup.add(new Konva.Circle({
        x: 50,
        y: 50,
        radius: 50,
        stroke: color,
        name: 'droppable',
        strokeWidth: 4,
        shadowColor: '#b3b3b3',
        shadowBlur: 1,
        shadowOffset: {
            x: 2,
            y: 2
        },
        shadowOpacity: 0.5
    }));
    var black = "#000000";
    addAnchor(circGroup, 50, 100, 'bottom', black);
    addEditButton(circGroup, 50, 0, color);
    addDeleteIcon(circGroup, 100, 55, color);
    circGroup.setZIndex(1);
    circGroup.setDraggable(true);
    circGroup['attrs']['dragBoundFunc'] = function(pos) {
        var stage = circGroup.getStage();
        var circle = circGroup.find('.droppable')[0];
        var left = pos.x + circle.x() - circle.radius();
        var right = pos.x + circle.x() + circle.radius();
        var top = pos.y + circle.y() - circle.radius();
        var bottom = pos.y + circle.y() + circle.radius();
        if (left < 5) {
            var newX = 5 + circle.radius() - circle.x();
        } else if (right > (stage.width() - 20)) {
            var newX = stage.width() - 20 - circle.x() - circle.radius();
        } else {
            var newX = pos.x;
        }
        if (top < 20) {
            var newY = 20 + circle.radius() - circle.y();
        } else if (bottom > (stage.height() - 10)) {
            var newY = stage.height() - 10 - circle.radius() - circle.y();
        } else {
            var newY = pos.y;
        }
        return {
            x: newX,
            y: newY
        };
    }
    stage.find('Layer')[0].draw();
    naming.z++;
};

//creating a nameTag
function createNameTag() {
    var rectaGroup = new Konva.Group({
        x: 180,
        y: 50,
        id: naming.z,
        name: 'droppable'
    });
    stage.find('Layer')[0].add(rectaGroup);
    var color = '#' + Math.floor(Math.random() * 16777215).toString(16);
    rectaGroup.add(new Konva.Line({
        points: [200, 200, 200 + naming.minwidth_tag, 200, 200 + naming.minwidth_tag, 200 + naming.minheight_tag, 200, 200 + naming.minheight_tag, 175, 220, 200, 200],
        stroke: color,
        strokeWidth: 3,
        closed: true,
        transformsEnabled: 'position',
        name: 'pentagon',
        lineJoin: 'round',
        lineCap: 'round',
        shadowColor: '#b3b3b3',
        shadowBlur: 1,
        shadowOffset: {
            x: 2,
            y: 2
        },
        shadowOpacity: 0.5
    }));
    addEditButton(rectaGroup, 200 + naming.minwidth_tag / 2, 200, color);
    addDeleteIcon(rectaGroup, 200 + naming.minwidth_tag, 200 + naming.minheight_tag / 2, color);
    stage.find('Layer')[0].add(new Konva.Circle({
        x: 280,
        y: 150,
        stroke: 'red',
        fill: '#ffffff',
        strokeWidth: 2,
        radius: 8,
        name: 'point',
        draggable: true,
        dragOnTop: false,
        id: naming.z
    }));

    rectaGroup.add(new Konva.Circle({
        x: 188,
        y: 220,
        stroke: color,
        strokeWidth: 2,
        radius: 3,
        name: 'deco',
        draggable: false,
        dragOnTop: false
    }));
    rectaGroup.add(new Konva.Line({
        points: [175, 220, 100, 100],
        stroke: '#3282ba',
        strokeWidth: 3,
        lineCap: 'round',
        lineJoin: 'round',
        name: 'connecting',
        draggable: false
    }));


    var points = stage.find('Layer')[0].find('.point');
    rectaGroup.setZIndex(1);
    rectaGroup.setDraggable(true);

    var points = stage.find('Layer')[0].find('.point');

    var topLeftX = rectaGroup['children'][0]['attrs']['points'][0];
    var topRightX = rectaGroup['children'][0]['attrs']['points'][2];
    var topLeftY = rectaGroup['children'][0]['attrs']['points'][1];
    var bottomLeftY = rectaGroup['children'][0]['attrs']['points'][7];

    points[0]['attrs']['dragBoundFunc'] = function(pos) {
        var stage = rectaGroup.getStage();
        if (pos.x < 0) {
            var newX = 0;
        } else if (pos.x > (stage.width() - 4)) {
            var newX = stage.width() - 4;
        } else {
            var newX = pos.x;
        }
        if (pos.y < 0) {
            var newY = 0;
        } else if (pos.y > (stage.height() - 4)) {
            var newY = stage.height() - 4;
        } else {
            var newY = pos.y;
        }
        return {
            x: newX,
            y: newY
        };
    }
    rectaGroup.on('dragmove', function(e) {
        updateLine(e);
        stage.find('Layer')[0].draw();
    });

    points.on('dragmove', function(e) {
        pointsdragmove(e);
    });

    points.on('mouseover', function(e) {
        document.body.style.cursor = 'pointer';
    });
    points.on('mouseout', function() {
        document.body.style.cursor = 'default';
    });
    //nametag bound function reduced
    rectaGroup['attrs']['dragBoundFunc'] = function(pos) {
        var stage = rectaGroup.getStage();
        if (rectaGroup['children'][0]['attrs']['points'][2] > rectaGroup['children'][0]['attrs']['points'][0]) {
            var wid = rectaGroup['children'][0]['attrs']['points'][2]-rectaGroup['children'][0]['attrs']['points'][0]-naming.minwidth_tag;
            if (pos.x+rectaGroup['children'][0]['attrs']['points'][2]-wid < 421+wid) {
                newX = 421-rectaGroup['children'][0]['attrs']['points'][2]+2*wid;
            } else if (pos.x + rectaGroup['children'][0]['attrs']['points'][2] + 20 > stage.width()) {
                newX = stage.width() - rectaGroup['children'][0]['attrs']['points'][2] - 20;
            } else {
                newX = pos.x;
            }
        } else if (rectaGroup['children'][0]['attrs']['points'][2] < rectaGroup['children'][0]['attrs']['points'][0]) {
            var wid = rectaGroup['children'][0]['attrs']['points'][0]-rectaGroup['children'][0]['attrs']['points'][2]-naming.minwidth_tag;
            if (pos.x + rectaGroup['children'][0]['attrs']['points'][2] < 20) {
                newX = 20 - rectaGroup['children'][0]['attrs']['points'][2];
            } else if (pos.x+rectaGroup['children'][0]['attrs']['points'][2]+wid > 401-wid) {
                newX = 401-rectaGroup['children'][0]['attrs']['points'][2]-2*wid;
            } else {
                newX = pos.x;
            }
        }
        var finalY = rectaGroup['children'][0]['attrs']['points'][5] + pos.y;
        if (pos.y < -180) {
            var newY = -180;
        } else if (finalY > (stage.height() - 10)) {
            var newY = stage.height() - 10 - rectaGroup['children'][0]['attrs']['points'][5];
        } else {
            var newY = pos.y;
        }
        return {
            x: newX,
            y: newY
        };
    }
    stage.find('Layer')[0].draw();
    naming.z++;
};

//anchors for resizing 
function addAnchor(group, x, y, name, coloring) {
    var stage = group.getStage();
    var layer = group.getLayer();

    var anchor = new Konva.Circle({
        x: x,
        y: y,
        stroke: coloring,
        fill: coloring,
        strokeWidth: 2,
        radius: 4,
        name: name,
        draggable: true,
        dragOnTop: false
    });
    if (group['children'][0]['className'] != 'Circle') {
        anchor.on('dragmove', function(e) {
            this['attrs']['dragBoundFunc'] = function(pos) {
                var group = this.getParent();
                var stage = group.getStage();
                var positionx = positionX(group);
                var positiony = positionY(group);
                if (this.getName() == 'bottomRight') {
                    var newX = (pos.x - positionx) < 50 ? (50 + positionx) : pos.x;
                    var newY = (pos.y - positiony) < 50 ? (50 + positiony) : pos.y;
                    var new1X = newX > (stage.width() - 20) ? (stage.width() - 20) : newX;
                    var new1Y = newY > (stage.height()) ? (stage.height()) : newY;
                    return {
                        x: new1X,
                        y: new1Y
                    };
                } else if (this.getName() == 'bottomLeft') {
                    var bottomRight = group.find('.bottomRight')[0];
                    var topLeft = group.find('.topLeft')[0];
                    var newX = (bottomRight.x() - (pos.x - group.x())) < 50 ? (bottomRight.x() - 50 + group.x()) : pos.x;
                    var newY = ((pos.y - group.y()) - topLeft.y()) < 50 ? (50 + group.y() + topLeft.y()) : pos.y;
                    var new1X = newX < 5 ? 5 : newX;
                    var new1Y = newY > (stage.height()) ? (stage.height()) : newY;
                    return {
                        x: new1X,
                        y: new1Y
                    };
                } else if (this.getName() == 'topLeft') {
                    var bottomRight = group.find('.bottomRight')[0];
                    var newX = (bottomRight.x() - (pos.x - group.x())) < 50 ? (bottomRight.x() - 50 + group.x()) : pos.x;
                    var newY = (bottomRight.y() - (pos.y - group.y())) < 50 ? (bottomRight.y() - 50 + group.y()) : pos.y;
                    var new1X = newX < 5 ? 5 : newX;
                    var new1Y = newY < 20 ? 20 : newY;
                    return {
                        x: new1X,
                        y: new1Y
                    };
                } else if (this.getName() == 'topRight') {
                    var bottomRight = group.find('.bottomRight')[0];
                    var topLeft = group.find('.topLeft')[0];
                    var newX = ((pos.x - group.x()) - topLeft.x()) < 50 ? (50 + group.x() + topLeft.x()) : pos.x;
                    var newY = (bottomRight.y() - (pos.y - group.y())) < 50 ? (bottomRight.y() - 50 + group.y()) : pos.y;
                    var new1X = newX > (stage.width() - 20) ? (stage.width() - 20) : newX;
                    var new1Y = newY < 20 ? 20 : newY;
                    return {
                        x: new1X,
                        y: new1Y
                    };
                }
            };
            if (group['children'][0]['className'] == 'Rect') {
                update(this, 'rect');
                if (group.find('.answer').length > 0) {
                    if (group.find('.answer')[0]['className'] == "Image") {
                        updateImageAreaTag(group);
                    } else if (group.find('.answer')[0]['className'] == 'Text') {
                        group.find('.tooltip').remove();
                        updateTextAreaTag(group);
                    }
                }
            } else if (group['children'][0]['className'] == 'Line') {
                update(this, 'line')
            }
            layer.draw();
        });
    } else if (group['children'][0]['className'] == 'Circle') {
        anchor.on('dragmove', function(e) {
            this['attrs']['dragBoundFunc'] = function(pos) {
                var group = e.target.getParent();
                var circle = group.find('.droppable')[0];
                var centerX = group.x() + circle.x();
                var centerY = group.y() + circle.y();
                var radius = pos.y - centerY;
                var newY = radius < 40 ? (40 + centerY) : pos.y;
                if ((centerY - radius) < 20) {
                    newY = 2 * centerY - 20;
                } else if ((centerX - radius) < 5) {
                    newY = centerY + centerX - 5;
                }
                return {
                    x: this.getAbsolutePosition().x,
                    y: newY
                }
            };
            updateCircle(this);
            if (group.find('.answer').length > 0) {
                if (group.find('.answer')[0]['className'] == "Image") {
                    updateImageAreaTag(group);
                } else if (group.find('.answer')[0]['className'] == 'Text') {
                    group.find('.tooltip').remove();
                    updateTextAreaTag(group);
                }
            }
            layer.draw();
        });
    }
    anchor.on('mousedown touchstart', function() {
        group.setDraggable(false);
        this.moveToTop();
    });
    anchor.on('dragend', function() {
        group.setDraggable(true);
        layer.draw();
    });
    // add hover styling
    anchor.on('mouseover', function() {
        var layer = this.getLayer();
        document.body.style.cursor = 'pointer';
        this.setStrokeWidth(4);
        layer.draw();
    });
    anchor.on('mouseout', function() {
        var layer = this.getLayer();
        document.body.style.cursor = 'default';
        this.setStrokeWidth(2);
        layer.draw();
    });
    group.add(anchor);
};

//updating anchor position of circle
function updateCircle(activeAnchor) {
    var group = activeAnchor.getParent();
    var circle = group['children'][0];
    var pointX = group.find('.bottom')[0].x();
    var pointY = group.find('.bottom')[0].y();
    var radius = Math.pow((Math.pow((circle.x() - pointX), 2) + Math.pow((circle.y() - pointY), 2)), 0.5);
    circle.radius(radius);
    var txt = group.find('.edit');
    txt.x(circle.x() - 16);
    txt.y(circle.y() - radius - 18);
    var rectangle = group.find('.editButton');
    rectangle[0].x(circle.x() - 20);
    rectangle[0].y(circle.y() - radius - 20);
    var deleteIcon = group.find('.delete');
    deleteIcon[0].x(circle.x() + radius);
    deleteIcon[0].y(circle.y() - 5);
};

//updating anchor position of rectangle
function update(activeAnchor, type) {
    var group = activeAnchor.getParent();
    var topLeft = group.get('.topLeft')[0];
    var topRight = group.get('.topRight')[0];
    var bottomRight = group.get('.bottomRight')[0];
    var bottomLeft = group.get('.bottomLeft')[0];
    var anchorX = activeAnchor.getX();
    var anchorY = activeAnchor.getY();


    // update anchor positions
    switch (activeAnchor.getName()) {
        case 'topLeft':
            topRight.setY(anchorY);
            bottomLeft.setX(anchorX);
            break;
        case 'topRight':
            topLeft.setY(anchorY);
            bottomRight.setX(anchorX);
            break;
        case 'bottomRight':
            bottomLeft.setY(anchorY);
            topRight.setX(anchorX);
            break;
        case 'bottomLeft':
            bottomRight.setY(anchorY);
            topLeft.setX(anchorX);
            break;
    }
    var rectangle = group.get('Rect')[0];
    rectangle.position(topLeft.position());
    var width = topRight.getX() - topLeft.getX();
    var height = bottomLeft.getY() - topLeft.getY();
    if (width && height) {
        rectangle.width(width);
        rectangle.height(height);
    }
    var txt = group.find('.edit');
    txt.x((topRight.getX() + topLeft.getX()) / 2 - 8);
    txt.y(topRight.getY() - 18);
    var rectangle = group.find('.editButton');
    rectangle[0].x((topRight.getX() + topLeft.getX()) / 2 - 12);
    rectangle[0].y(topRight.getY() - 20);

//    group.find('.tooltip').remove();
    var deleteIcon = group.find('.delete');
    var X = topRight.getX();
    var Y = (topRight.getY() + bottomRight.getY()) / 2 - 10;
    deleteIcon[0].x(X);
    deleteIcon[0].y(Y);
};

// Update line of name tag
function updateLine(e) {
    if (e.target['nodeType'] == 'Group') {
        var group = e.target;

    } else {
        var group = e.target.getParent();
    }
    var stage = group.getStage();
    var topLeftX = group['children'][0]['attrs']['points'][0];
    var topRightX = group['children'][0]['attrs']['points'][2];
    var topLeftY = group['children'][0]['attrs']['points'][1];
    var bottomLeftY = group['children'][0]['attrs']['points'][7];
    var id = group['attrs']['id'];
    var allPoints = stage.find('.point');
    for (i = 0; i < allPoints.length; i++) {
        if (allPoints[i]['attrs']['id'] == id) {
            var point = [];
            point.push(allPoints[i]);
        }
    }
    var txt = group.find('.answer');
    if (topRightX > topLeftX) {
        w_of_tag = topRightX - topLeftX;
    } else {
        w_of_tag = topLeftX - topRightX;
    }
    if (topLeftX + group.x() > point[0].x() && topRightX + group.x() > point[0].x()) {
        var line = group.find('.connecting');
        line[0]['attrs']['points'] = [topLeftX - 25, (topLeftY + bottomLeftY) / 2, point[0].x() - group.x(), point[0].y() - group.y()];
        if (txt[0]) {
            group.find('.edit')[0].text('Edit');
        }
    } else if (topLeftX + group.x() < point[0].x() && topRightX + group.x() > point[0].x()) {
        group['children'][0]['attrs']['points'] = [topLeftX - 50, topLeftY, topLeftX - 50 - w_of_tag, topLeftY, topLeftX - 50 - w_of_tag, bottomLeftY, topLeftX - 50, bottomLeftY, group['children'][0]['attrs']['points'][8], group['children'][0]['attrs']['points'][9], topLeftX - 50, topLeftY];
        var line = group.find('.connecting');
        line[0]['attrs']['points'] = [group['children'][0]['attrs']['points'][0] + 25, (group['children'][0]['attrs']['points'][1] + group['children'][0]['attrs']['points'][7]) / 2, point[0].x() - group.x(), point[0].y() - group.y()];
        group.find('.delete').remove();
        var edit = group.find('.editButton');
        var color = edit[0]['attrs']['fill'];
        addDeleteIcon(group, group['children'][0]['attrs']['points'][2] - 20, (group['children'][0]['attrs']['points'][3] + group['children'][0]['attrs']['points'][5]) / 2, color);
        group.find('.edit').remove();
        group.find('.editButton').remove();
        group.find('.deco').setX(group['children'][0]['attrs']['points'][8] - 10 - 3);
        addEditButton(group, group['children'][0]['attrs']['points'][2] + (group['children'][0]['attrs']['points'][0] - group['children'][0]['attrs']['points'][2]) / 2, group['children']['0']['attrs']['points'][1], color);
        if (txt[0]) {
            txt.setX(group['children'][0]['attrs']['points'][2] + 10);
            group.find('.edit')[0].text('Edit');
        }
    } else if (topLeftX + group.x() < point[0].x() && topRightX + group.x() < point[0].x()) {
        var line = group.find('.connecting');
        line[0]['attrs']['points'] = [group['children'][0]['attrs']['points'][0] + 25, (group['children'][0]['attrs']['points'][1] + group['children'][0]['attrs']['points'][7]) / 2, point[0].x() - group.x(), point[0].y() - group.y()];
    } else if (topLeftX + group.x() > point[0].x() && topRightX + group.x() < point[0].x()) {
        group['children'][0]['attrs']['points'] = [topLeftX + 50, topLeftY, topLeftX + 50 + w_of_tag, topLeftY, topLeftX + 50 + w_of_tag, bottomLeftY, topLeftX + 50, bottomLeftY, group['children'][0]['attrs']['points'][8], group['children'][0]['attrs']['points'][9], topLeftX + 50, topLeftY];
        var line = group.find('.connecting');
        group.find('.delete').remove();
        var edit = group.find('.editButton');
        var color = edit[0]['attrs']['fill'];
        addDeleteIcon(group, group['children'][0]['attrs']['points'][2], (group['children'][0]['attrs']['points'][3] + group['children'][0]['attrs']['points'][5]) / 2, color);
        group.find('.edit').remove();
        group.find('.editButton').remove();
        group.find('.deco').setX(group['children'][0]['attrs']['points'][8] + 10 + 3);
        addEditButton(group, group['children'][0]['attrs']['points'][2] + (group['children'][0]['attrs']['points'][0] - group['children'][0]['attrs']['points'][2]) / 2, group['children'][0]['attrs']['points'][1], color);
        line[0]['attrs']['points'] = [group['children'][0]['attrs']['points'][0] - 25, (group['children'][0]['attrs']['points'][1] + group['children'][0]['attrs']['points'][7]) / 2, point[0].x() - group.x(), point[0].y() - group.y()];
        if (txt[0]) {
            txt.setX(group['children'][0]['attrs']['points'][0]);
            group.find('.edit')[0].text('Edit');
        }
    }

};

//add edit icon
function addEditButton(group, x, y, color) {
    var stage = group.getStage();
    var layer = group.getLayer();
    var type = group['children'][0]['className'];
    var edit = new Konva.Text({
        x: x - 14,
        y: y - 18,
        text: 'Add',
        draggable: false,
        align: 'center',
        name: 'edit',
        fill: 'white',
        padding: 1,
        width: 24
        // fontStyle:'bold',
    });
    var rect = new Konva.Rect({
        x: x - 18,
        y: y - 20,
        stroke: color,
        strokeWidth: 1,
        fill: color,
        width: edit.getWidth() + 12,
        height: edit.getHeight() + 7,
        draggable: false,
        name: 'editButton',
        cornerRadius: 2,
        shadowColor: '#b3b3b3',
        shadowBlur: 1,
        shadowOffset: {
            x: 2,
            y: 2
        },
        shadowOpacity: 0.5
    });
    rect.on('click tap', function(e) {
        setModal(this);
    });
    edit.on('click tap', function(e) {
        setModal(this);
    });

    edit.on('mouseover', function(e) {
        document.body.style.cursor = 'pointer';
    });
    edit.on('mouseout', function() {
        document.body.style.cursor = 'default';
    });
    rect.on('mouseover', function(e) {
        document.body.style.cursor = 'pointer';
    });
    rect.on('mouseout', function() {
        document.body.style.cursor = 'default';
    });
    group.add(rect);
    group.add(edit);
};

//add delete icon
function addDeleteIcon(group, x, y, z) {
    var deleteIcon = new Konva.Path({
        x: x,
        y: y - 10,
        data: 'M355.914,61.065c-81.42-81.42-213.428-81.42-294.849,0s-81.421,213.427,0,294.849c81.42,81.42,213.428,81.42,294.849,0   C437.334,274.492,437.334,142.485,355.914,61.065z M312.525,258.763c4.454,4.454,4.454,11.675,0,16.129l-37.632,37.632   c-4.454,4.454-11.675,4.453-16.13,0l-50.273-50.275l-50.275,50.275c-4.453,4.455-11.674,4.453-16.128,0l-37.632-37.632   c-4.454-4.454-4.453-11.674,0-16.127l50.275-50.276l-50.275-50.275c-4.453-4.454-4.453-11.675,0-16.128l37.633-37.632   c4.454-4.454,11.675-4.454,16.127,0l50.275,50.275l50.274-50.275c4.454-4.454,11.675-4.454,16.129,0l37.632,37.632   c4.453,4.454,4.454,11.675,0,16.128l-50.275,50.275L312.525,258.763z',
        fill: z,
        scale: {
            x: 0.05,
            y: 0.05
        },
        name: 'delete',
        close: true,
        shadowColor: '#b3b3b3',
        shadowBlur: 1,
        shadowOffset: {
            x: 2,
            y: 2
        },
        shadowOpacity: 0.5
    });
    group.add(deleteIcon);
    deleteIcon.on('mouseover', function(e) {
        document.body.style.cursor = 'pointer';
    });
    deleteIcon.on('mouseout', function() {
        document.body.style.cursor = 'default';
    });
    deleteIcon.on('click tap', function(e) {
        var group = e.target.getParent();
        var id = group['attrs']['id'];
        var allPoints = stage.find('Layer')[0].find('.point');
        if (allPoints.length != 0) {
            for (i = 0; i < allPoints.length; i++) {
                if (allPoints[i]['attrs']['id'] == id) {
                    allPoints[i].remove();

                }
            }
        }
        naming.z--;
        group.remove();
        stage.find('Layer')[0].draw();
    });
    stage.find('Layer')[0].draw();
};

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

//Modal for adding answers to tags
function setModal(e) {
    var group = e.getParent();
    var rect = group.find('.editButton')[0];
    var divOffset = $('.mainbox').offset();
    var X = group.x() + rect.x() + 10;
    var Y = group.y() + rect.y() + divOffset['top'] + 60 - $(window).scrollTop();
    $('#save').data('id', group['attrs']['id']);
    $('.modal-dialog').css('width', '25%').css('margin-left', X).css('margin-top', Y);
    $('.modal-content').css('height', '225px');
    $('.tagbox-answer').removeClass('hidden');
    $('.modal-description').addClass('hidden');
    $('.modal-title-tagbox').html('Edit the Tag Box');
    $('#save').removeClass('hidden');
    $('#AddWrongAnswer').addClass('hidden');
    $('#myModal').modal('show');
    if (group['attrs']['correctAnswer'] != undefined && group['attrs']['correctAnswer'] != '' ) {
        if (group.find('.answer')[0]['attrs']['answertype'] == "text") {
            $('.content-show').show();
            $('.img-preview-modal').hide();
            $('#input-answer').val(group['attrs']['correctAnswer']);
        } else if (group.find('.answer')[0]['attrs']['answertype'] == 'image') {

            $('.content-show').hide();
            $('.img-preview-modal').show();
            $('.image-details').html('<img src='+imagePrefix(group["attrs"]["correctAnswer"]) +' class="answer-image">\
					<span class="glyphicon glyphicon-edit edit-image" ></span>');
            $('.edit-image').click(function(){
                $('.img-preview-modal').hide();
                $('.content-show').show();
                $('#input-answer').val('');
                $('#input-image').val('');
            });

        }
    }
    else {
        $('.content-show').show();
        $('.img-preview-modal').hide();
        $('#input-answer').val('');
        $('#input-image').val('');
    }
};

function LoadValue(x) {
    $('#image-input').value = imagePrefix(x)
}

// answer inside tags
function setAnswer(group, type, option) {
    //setting answers for area tags
    if (type != 'Line') {
        if (group.find('.answer').length == 1) {
            if (option == "text") {
                if(group.find('.answer')[0]['className']=='Image'){
                    group.find('.answer')[0].remove();
                    group.add(new Konva.Text({
                        x: 0,
                        y: 0,
                        text: group['attrs']['correctAnswer'],
                        draggable: false,
                        fontSize: 14,
                        align: 'center',
                        name: 'answer',
                        answertype: 'text',
                        fontStyle: 'bold'
                    }));
                }
                var text = group.find('.answer')[0];
                text.text(group['attrs']['correctAnswer']);
                group['children'][0].fill('white');
                group['children'][0].opacity(0.5);
                group.find('.tooltip').remove();
                var shape = group.find('.droppable')[0];
                if (group['children'][0]['className'] == "Rect") {
                    if (text.width() > shape.width()) {
                        addtooltip(group);
                    }
                }else{
                    if(text.width()>shape.radius()*2){
                        addtooltip(group);
                    }
                }
                updateTextAreaTag(group);
                text.on('mouseover tap ', function(e){
                    document.body.style.cursor = 'pointer';
                    var tooltip = group.find('.tooltip');
                    tooltip.show();
                    tooltip.setX(text.x()+text.width()/2);
                    tooltip.setY(text.y());
                    stage.draw();
                });
                text.on('mouseout tap', function(){
                    document.body.style.cursor = 'default';
                    group.find('.tooltip').hide();
                    stage.draw();
                });
            } else if (option == "image") {
                group.find('.answer')[0].remove();
                var imageObj = new Image();
                imageObj.onload = function() {
                    var imageAnswer = new Konva.Image({
                        x: 0,
                        y: 0,
                        draggable: false,
                        image: imageObj,
                        width: 50,
                        height: 50,
                        answertype: 'image',
                        name: 'answer',
                        src:group['attrs']['correctAnswer']
                    });
                    group.add(imageAnswer);
                    group['children'][0].fill('white');
                    group['children'][0].opacity(0.5);
                    updateImageAreaTag(group);
                    stage.find('Layer')[0].draw();
                }
                imageObj.src = imagePrefix(group['attrs']['correctAnswer']);
            }
        } else {
            if (option == "text") {
                group.add(new Konva.Text({
                    x: 0,
                    y: 0,
                    text: group['attrs']['correctAnswer'],
                    draggable: false,
                    fontSize: 14,
                    align: 'center',
                    name: 'answer',
                    answertype: 'text',
                    fontStyle: 'bold'
                }));
                group['children'][0].fill('white');
                group['children'][0].opacity(0.5);

                var text = group.find('.answer')[0];
                updateTextAreaTag(group);
                text.on('mouseover tap', function(e){
                    document.body.style.cursor = 'pointer';
                    var tooltip = group.find('.tooltip');
                    tooltip.show();
                    tooltip.setX(text.x()+text.width()/2);
                    tooltip.setY(text.y());
                    stage.draw();
                });
                text.on('mouseout tap', function(){
                    document.body.style.cursor = 'default';
                    group.find('.tooltip').hide();
                    stage.draw();
                });
            } else if (option == "image") {
                var imageObj = new Image();
                imageObj.onload = function() {
                    var imageAnswer = new Konva.Image({
                        x: 0,
                        y: 0,
                        draggable: false,
                        image: imageObj,
                        width: 50,
                        height: 50,
                        answertype: 'image',
                        name: 'answer',
                        src:group['attrs']['correctAnswer']
                    });
                    group.add(imageAnswer);
                    group['children'][0].fill('white');
                    group['children'][0].opacity(0.5);
                    updateImageAreaTag(group);
                    stage.find('Layer')[0].draw();
                }
                imageObj.src =imagePrefix(group['attrs']['correctAnswer']);
            }
        }
    }
    //setting answers for name tag
    else {

        if (group['children'][0]['attrs']['points'][2] > group['children'][0]['attrs']['points'][0]) {
            if (group.find('.answer').length == 1) {
                if (option == 'text') {
                    if(group.find('.answer')[0]['className']=='Image'){
                        group.find('.answer')[0].remove();
                        group.add(new Konva.Text({
                            x: 200,
                            y: 213,
                            text: group['attrs']['correctAnswer'],
                            fontSize: 16,
                            draggable: false,
                            align: 'center',
                            name: 'answer',
                            answertype: 'text'
                        }));
                        var text = group.find('.answer')[0];
                    }else{
                        var text = group.find('.answer')[0];
                        text.text(group['attrs']['correctAnswer']);
                        group.find('.tooltip').remove();
                    }
                    checkwidth(group, text);
                    text.on('mouseover tap', function(e){
                        document.body.style.cursor = 'pointer';
                        var tooltip = group.find('.tooltip');
                        tooltip.show();
                        tooltip.setX((group['children'][0]['attrs']['points'][0]+group['children'][0]['attrs']['points'][2])/2);
                        tooltip.setY(group['children'][0]['attrs']['points'][1]-20);
                        stage.draw();
                    });
                    text.on('mouseout tap', function(){
                        document.body.style.cursor = 'default';
                        group.find('.tooltip').hide();
                        stage.draw();
                    });
                } else if (option == 'image') {
                    group.find('.answer')[0].remove();
                    var imageObj = new Image();
                    imageObj.onload = function() {
                        var imageAnswer = new Konva.Image({
                            x: 200,
                            y: 210,
                            draggable: false,
                            image: imageObj,
                            width: naming.nametagImg_w - 10,
                            height: naming.nametagImg_h - 20,
                            answertype: 'image',
                            name: 'answer',
                            src:group['attrs']['correctAnswer']
                        });
                        group.add(imageAnswer);
                        stage.find('Layer')[0].draw();
                    }
                    imageObj.src = imagePrefix(group['attrs']['correctAnswer']);
                    var line = group['children'][0];

                    if (group['children'][0]['attrs']['points'][1] + group.y() + naming.nametagImg_h - 10 > stage.height()) {
                        line['attrs']['points'] = [line['attrs']['points'][6], line['attrs']['points'][7] - naming.nametagImg_h, line['attrs']['points'][6] + naming.nametagImg_w, line['attrs']['points'][7] - naming.nametagImg_h, line['attrs']['points'][6] + naming.nametagImg_w, line['attrs']['points'][7], line['attrs']['points'][6], line['attrs']['points'][7], line['attrs']['points'][8], line['attrs']['points'][7] - naming.nametagImg_h / 2 - 5, line['attrs']['points'][6], line['attrs']['points'][7] - naming.nametagImg_h];
                    } else {
                        line['attrs']['points'] = [line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] + naming.nametagImg_w, line['attrs']['points'][1], line['attrs']['points'][0] + naming.nametagImg_w, line['attrs']['points'][1] + naming.nametagImg_h, line['attrs']['points'][0], line['attrs']['points'][1] + naming.nametagImg_h, line['attrs']['points'][8], line['attrs']['points'][1] + naming.nametagImg_h / 2 - 5, line['attrs']['points'][0], line['attrs']['points'][1]];
                    }
                    group.find('.delete').remove();
                    group.find('.edit').remove();
                    var edit = group.find('.editButton');
                    var color = edit[0]['attrs']['fill'];
                    edit.remove();
                    addEditButton(group, (line['attrs']['points'][0] + line['attrs']['points'][2]) / 2, line['attrs']['points'][1], color);
                    addDeleteIcon(group, line['attrs']['points'][2], (line['attrs']['points'][3] + line['attrs']['points'][5]) / 2, color);
                    group.find('.deco').setX(line['attrs']['points'][8] + 10 + 3);
                    group.find('.deco').setY(line['attrs']['points'][9]);
                    var connector = group.find('.connecting');
                    var inix = connector[0]['attrs']['points'][2];
                    var iniy = connector[0]['attrs']['points'][3];
                    connector[0]['attrs']['points'] = [line['attrs']['points'][8], line['attrs']['points'][9], inix, iniy];
                }
            } else {
                if (option == 'text') {
                    group.add(new Konva.Text({
                        x: 200,
                        y: 213,
                        text: group['attrs']['correctAnswer'],
                        fontSize: 16,
                        draggable: false,
                        align: 'center',
                        name: 'answer',
                        answertype: 'text'
                    }));
                    var txt = group.find('.answer')[0];
                    checkwidth(group, txt);
                    txt.on('mouseover tap', function(e){
                        document.body.style.cursor = 'pointer';
                        var tooltip = group.find('.tooltip');
                        tooltip.show();
                        tooltip.setX((group['children'][0]['attrs']['points'][0]+group['children'][0]['attrs']['points'][2])/2);
                        tooltip.setY(group['children'][0]['attrs']['points'][1]-20);
                        stage.draw();
                    });
                    txt.on('mouseout tap', function(){
                        document.body.style.cursor = 'default';
                        group.find('.tooltip').hide();
                        stage.draw();
                    });
                } else if (option == 'image') {
                    var imageObj = new Image();
                    imageObj.onload = function() {
                        var imageAnswer = new Konva.Image({
                            x: 200,
                            y: line['attrs']['points'][1] + 13,
                            draggable: false,
                            image: imageObj,
                            width: naming.nametagImg_w - 10,
                            height: naming.nametagImg_h - 20,
                            answertype: 'image',
                            name: 'answer',
                            src:group['attrs']['correctAnswer']
                        });
                        group.add(imageAnswer);
                        stage.find('Layer')[0].draw();
                    }
                    imageObj.src = imagePrefix(group['attrs']['correctAnswer']);
                    var line = group['children'][0];

                    if (group['children'][0]['attrs']['points'][1] + group.y() + naming.nametagImg_h - 10 > stage.height()) {
                        line['attrs']['points'] = [line['attrs']['points'][6], line['attrs']['points'][7] - naming.nametagImg_h, line['attrs']['points'][6] + naming.nametagImg_w, line['attrs']['points'][7] - naming.nametagImg_h, line['attrs']['points'][6] + naming.nametagImg_w, line['attrs']['points'][7], line['attrs']['points'][6], line['attrs']['points'][7], line['attrs']['points'][8], line['attrs']['points'][7] - naming.nametagImg_h / 2 - 5, line['attrs']['points'][6], line['attrs']['points'][7] - naming.nametagImg_h];
                    } else {
                        line['attrs']['points'] = [line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] + naming.nametagImg_w, line['attrs']['points'][1], line['attrs']['points'][0] + naming.nametagImg_w, line['attrs']['points'][1] + naming.nametagImg_h, line['attrs']['points'][0], line['attrs']['points'][1] + naming.nametagImg_h, line['attrs']['points'][8], line['attrs']['points'][1] + naming.nametagImg_h / 2 - 5, line['attrs']['points'][0], line['attrs']['points'][1]];
                    }
                    group.find('.delete').remove();
                    group.find('.edit').remove();
                    var edit = group.find('.editButton');
                    var color = edit[0]['attrs']['fill'];
                    edit.remove();
                    addEditButton(group, (line['attrs']['points'][0] + line['attrs']['points'][2]) / 2, line['attrs']['points'][1], color);
                    addDeleteIcon(group, line['attrs']['points'][2], (line['attrs']['points'][3] + line['attrs']['points'][5]) / 2, color);
                    group.find('.deco').setX(line['attrs']['points'][8] + 10 + 3);
                    group.find('.deco').setY(line['attrs']['points'][9]);
                    var connector = group.find('.connecting');
                    var inix = connector[0]['attrs']['points'][2];
                    var iniy = connector[0]['attrs']['points'][3];
                    connector[0]['attrs']['points'] = [line['attrs']['points'][8], line['attrs']['points'][9], inix, iniy];
                }
            }
        } else {
            if (group.find('.answer').length == 1) {
                if (option == 'text') {
                    if(group.find('.answer')[0]['className']=='Image'){
                        group.find('.answer')[0].remove();
                        group.add(new Konva.Text({
                            x: group['children'][0]['attrs']['points'][2] + 10,
                            y: 213,
                            text: group['attrs']['correctAnswer'],
                            fontSize: 16,
                            draggable: false,
                            align: 'center',
                            name: 'answer',
                            answertype: 'text'
                        }));
                        var text = group.find('.answer')[0];
                    }else{
                        var text = group.find('.answer')[0];
                        text.text(group['attrs']['correctAnswer']);
                        group.find('.tooltip').remove();
                    }
                    checkwidthreverse(group, text);
                    text.on('mouseover tap', function(e){
                        document.body.style.cursor = 'pointer';
                        var tooltip = group.find('.tooltip');
                        tooltip.show();
                        tooltip.setX((group['children'][0]['attrs']['points'][0]+group['children'][0]['attrs']['points'][2])/2);
                        tooltip.setY(group['children'][0]['attrs']['points'][1]-20);
                        stage.draw();
                    });
                    text.on('mouseout tap', function(){
                        document.body.style.cursor = 'default';
                        group.find('.tooltip').hide();
                        stage.draw();
                    });
                } else if (option == 'image') {
                    group.find('.answer')[0].remove();
                    var imageObj = new Image();
                    imageObj.onload = function() {
                        var imageAnswer = new Konva.Image({
                            x: group['children'][0]['attrs']['points'][2],
                            y: group['children'][0]['attrs']['points'][1] + 17,
                            draggable: false,
                            image: imageObj,
                            width: naming.nametagImg_w - 10,
                            height: naming.nametagImg_h - 20,
                            answertype: 'image',
                            name: 'answer',
                            src:group['attrs']['correctAnswer']
                        });
                        group.add(imageAnswer);
                        stage.find('Layer')[0].draw();
                    }
                    imageObj.src = imagePrefix(group['attrs']['correctAnswer']);
                    var line = group['children'][0];
                    if (group['children'][0]['attrs']['points'][1] + group.y() + naming.nametagImg_h - 10 > stage.height()) {
                        line['attrs']['points'] = [line['attrs']['points'][6], line['attrs']['points'][7] - naming.nametagImg_h, line['attrs']['points'][6] - naming.nametagImg_w, line['attrs']['points'][7] - naming.nametagImg_h, line['attrs']['points'][6] - naming.nametagImg_w, line['attrs']['points'][7], line['attrs']['points'][6], line['attrs']['points'][7], line['attrs']['points'][8], line['attrs']['points'][7] - naming.nametagImg_h / 2 - 5, line['attrs']['points'][6], line['attrs']['points'][7] - naming.nametagImg_h];
                    } else {
                        line['attrs']['points'] = [line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] - naming.nametagImg_w, line['attrs']['points'][1], line['attrs']['points'][0] - naming.nametagImg_w, line['attrs']['points'][1] + naming.nametagImg_h, line['attrs']['points'][0], line['attrs']['points'][1] + naming.nametagImg_h, line['attrs']['points'][8], line['attrs']['points'][1] + naming.nametagImg_h / 2 - 5, line['attrs']['points'][0], line['attrs']['points'][1]];
                    }
                    group.find('.delete').remove();
                    group.find('.edit').remove();
                    var edit = group.find('.editButton');
                    var color = edit[0]['attrs']['fill'];
                    edit.remove();
                    addEditButton(group, (line['attrs']['points'][0] + line['attrs']['points'][2]) / 2, line['attrs']['points'][1], color);
                    addDeleteIcon(group, line['attrs']['points'][2] - 20, (line['attrs']['points'][3] + line['attrs']['points'][5]) / 2, color);
                    group.find('.deco').setX(line['attrs']['points'][8] -10-3);
                    group.find('.deco').setY(line['attrs']['points'][9]);
                    var connector = group.find('.connecting');
                    var inix = connector[0]['attrs']['points'][2];
                    var iniy = connector[0]['attrs']['points'][3];
                    connector[0]['attrs']['points'] = [line['attrs']['points'][8], line['attrs']['points'][9], inix, iniy];
                }
            } else {
                if (option == 'text') {
                    group.add(new Konva.Text({
                        x: group['children'][0]['attrs']['points'][2] + 10,
                        y: 213,
                        text: group['attrs']['correctAnswer'],
                        fontSize: 16,
                        draggable: false,
                        align: 'center',
                        name: 'answer',
                        answertype: 'text'
                    }));
                    var txt = group.find('.answer')[0];
                    checkwidthreverse(group, txt);
                    txt.on('mouseover tap', function(e){
                        document.body.style.cursor = 'pointer';
                        var tooltip = group.find('.tooltip');
                        tooltip.show();
                        tooltip.setX((group['children'][0]['attrs']['points'][0]+group['children'][0]['attrs']['points'][2])/2);
                        tooltip.setY(group['children'][0]['attrs']['points'][1]-20);
                        stage.draw();
                    });
                    txt.on('mouseout tap', function(){
                        document.body.style.cursor = 'default';
                        group.find('.tooltip').hide();
                        stage.draw();
                    });
                } else if (option == 'image') {
                    var imageObj = new Image();
                    imageObj.onload = function() {
                        var imageAnswer = new Konva.Image({
                            x: group['children'][0]['attrs']['points'][2],
                            y: group['children'][0]['attrs']['points'][1] + 17,
                            draggable: false,
                            image: imageObj,
                            width: naming.nametagImg_w - 10,
                            height: naming.nametagImg_h - 20,
                            answertype: 'image',
                            name: 'answer',
                            src:group['attrs']['correctAnswer']
                        });
                        group.add(imageAnswer);
                        stage.find('Layer')[0].draw();
                    }
                    imageObj.src = imagePrefix(group['attrs']['correctAnswer']);
                    var line = group['children'][0];
                    if (group['children'][0]['attrs']['points'][1] + group.y() + naming.nametagImg_h - 10 > stage.height()) {
                        line['attrs']['points'] = [line['attrs']['points'][6], line['attrs']['points'][7] - naming.nametagImg_h, line['attrs']['points'][6] - naming.nametagImg_w, line['attrs']['points'][7] - naming.nametagImg_h, line['attrs']['points'][6] - naming.nametagImg_w, line['attrs']['points'][7], line['attrs']['points'][6], line['attrs']['points'][7], line['attrs']['points'][8], line['attrs']['points'][7] - naming.nametagImg_h / 2 - 5, line['attrs']['points'][6], line['attrs']['points'][7] - naming.nametagImg_h];
                    } else {
                        line['attrs']['points'] = [line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] - naming.nametagImg_w, line['attrs']['points'][1], line['attrs']['points'][0] - naming.nametagImg_w, line['attrs']['points'][1] + naming.nametagImg_h, line['attrs']['points'][0], line['attrs']['points'][1] + naming.nametagImg_h, line['attrs']['points'][8], line['attrs']['points'][1] + naming.nametagImg_h / 2 - 5, line['attrs']['points'][0], line['attrs']['points'][1]];
                    }
                    group.find('.delete').remove();
                    group.find('.edit').remove();
                    var edit = group.find('.editButton');
                    var color = edit[0]['attrs']['fill'];
                    edit.remove();
                    addEditButton(group, (line['attrs']['points'][0] + line['attrs']['points'][2]) / 2, line['attrs']['points'][1], color);
                    addDeleteIcon(group, line['attrs']['points'][2] - 20, (line['attrs']['points'][3] + line['attrs']['points'][5]) / 2, color);
                    group.find('.deco').setX(line['attrs']['points'][8] - 10 - 3);
                    group.find('.deco').setY(line['attrs']['points'][9]);
                    var connector = group.find('.connecting');
                    var inix = connector[0]['attrs']['points'][2];
                    var iniy = connector[0]['attrs']['points'][3];
                    connector[0]['attrs']['points'] = [line['attrs']['points'][8], line['attrs']['points'][9], inix, iniy];
                }
            }
        }
    }
    group.find('.edit')[0].text('Edit');
    stage.find('Layer')[0].draw();
};

function addtooltip(group){
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
        text: group['attrs']['correctAnswer'],
        fontFamily: 'Calibri',
        fontSize: 16,
        padding: 5,
        fill: 'white'
    }));
    tooltip.hide();
    stage.find('Layer')[0].draw();
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

// checks width of text in name tag
function checkwidth(group, text) {
    group.find('.tooltip').remove();
    var line = group['children'][0];
    var nametagtext;
    if (text['textWidth'] < naming.minwidth_tag) {
        line['attrs']['points'] = [line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] + naming.minwidth_tag, line['attrs']['points'][1], line['attrs']['points'][0] + naming.minwidth_tag, line['attrs']['points'][1] + naming.minheight_tag, line['attrs']['points'][0], line['attrs']['points'][1] + naming.minheight_tag, line['attrs']['points'][8], line['attrs']['points'][1] + naming.minheight_tag / 2, line['attrs']['points'][0], line['attrs']['points'][1]];
    }else if(text['textWidth'] > naming.minwidth_tag && text['textWidth'] < naming.maxwidth_tag){
        line['attrs']['points'] = [line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] + 5 + text['textWidth'], line['attrs']['points'][1], line['attrs']['points'][0] + 5 + text['textWidth'], line['attrs']['points'][1]+naming.minheight_tag, line['attrs']['points'][6], line['attrs']['points'][1]+naming.minheight_tag, line['attrs']['points'][8], line['attrs']['points'][1]+naming.minheight_tag/2, line['attrs']['points'][0], line['attrs']['points'][1]];
        var wid = line['attrs']['points'][2]-line['attrs']['points'][0]-naming.minwidth_tag;
        if(line['attrs']['points'][2]+group.x()+20>stage.width()){
            var w= line['attrs']['points'][2]-line['attrs']['points'][0];
            line['attrs']['points'][2] = stage.width()-20-group.x();
            line['attrs']['points'] = [line['attrs']['points'][2]-w,line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]-w,line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]-w-25,line['attrs']['points'][1]+naming.minheight_tag/2,line['attrs']['points'][2]-w,line['attrs']['points'][1]];
        }else if(group.x()+line['attrs']['points'][2]-wid < 421+wid){
            var w= line['attrs']['points'][2]-line['attrs']['points'][0];
            line['attrs']['points'][2]=421+2*wid-group.x();
            line['attrs']['points'] = [line['attrs']['points'][2]-w,line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]-w,line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]-w-25,line['attrs']['points'][1]+naming.minheight_tag/2,line['attrs']['points'][2]-w,line['attrs']['points'][1]];
        }
    }else if(text['textWidth'] > naming.maxwidth_tag){
        addtooltip(group);
        line['attrs']['points'] = [line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] + naming.maxwidth_tag, line['attrs']['points'][1], line['attrs']['points'][0] +naming.maxwidth_tag, line['attrs']['points'][1]+naming.minheight_tag, line['attrs']['points'][6], line['attrs']['points'][1]+naming.minheight_tag, line['attrs']['points'][8], line['attrs']['points'][1]+naming.minheight_tag/2, line['attrs']['points'][0], line['attrs']['points'][1]];
        var wid = line['attrs']['points'][2]-line['attrs']['points'][0]-naming.minwidth_tag;
        if(line['attrs']['points'][2]+group.x()+20>stage.width()){
            line['attrs']['points'][2] = stage.width()-20-group.x();
            line['attrs']['points'] = [line['attrs']['points'][2]-naming.maxwidth_tag,line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]-naming.maxwidth_tag,line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]-naming.maxwidth_tag-25,line['attrs']['points'][1]+naming.minheight_tag/2,line['attrs']['points'][2]-naming.maxwidth_tag,line['attrs']['points'][1]];
        }else if(group.x()+line['attrs']['points'][2]-wid < 421+wid){
            line['attrs']['points'][2]=421+2*wid-group.x();
            line['attrs']['points'] = [line['attrs']['points'][2]-naming.maxwidth_tag,line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]-naming.maxwidth_tag,line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]-naming.maxwidth_tag-25,line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]-naming.maxwidth_tag,line['attrs']['points'][1]];
        }
        var truncat = group.find('.answer')[0];
        if (getTextWidth(truncat.text(), '16px arial') > naming.maxwidth_tag) {
            for (i = 1; i < truncat.text().length; i++) {
                if (getTextWidth(truncat.text().substr(0, i), '16px arial') > naming.maxwidth_tag) {
                    truncat.text(truncat.text().substr(0, i - 4) + '..');
                    break;
                }
            }
        }
    }
    group.find('.delete').remove();
    group.find('.edit').remove();
    group.find('.deco').setX(line['attrs']['points'][8] + 10 + 3);
    group.find('.deco').setY(line['attrs']['points'][9]);
    var connector = group.find('.connecting');
    var inix = connector[0]['attrs']['points'][2];
    var iniy = connector[0]['attrs']['points'][3];
    connector[0]['attrs']['points'] = [line['attrs']['points'][8], line['attrs']['points'][9], inix, iniy];
    var edit = group.find('.editButton');
    var color = edit[0]['attrs']['fill'];
    edit.remove();
    addEditButton(group, (line['attrs']['points'][0] + line['attrs']['points'][2]) / 2, line['attrs']['points'][1], color);
    addDeleteIcon(group, line['attrs']['points'][2], (line['attrs']['points'][3] + line['attrs']['points'][5]) / 2, color);
    group.find('.answer').setX(line['attrs']['points'][0]);
    group['children'][0].fill('white');
    group['children'][0].opacity(0.5);
    //stage.find('Layer')[0].draw();
};

// checks width of text in name tag when reversed
function checkwidthreverse(group, text) {
    group.find('.tooltip').remove();
    var line = group['children'][0];
    var nametagtext;
    if(text['textWidth']<naming.minwidth_tag){
        line['attrs']['points'] = [line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] - naming.minwidth_tag, line['attrs']['points'][1], line['attrs']['points'][0] - naming.minwidth_tag, line['attrs']['points'][1] + naming.minheight_tag, line['attrs']['points'][0], line['attrs']['points'][1] + naming.minheight_tag, line['attrs']['points'][8], line['attrs']['points'][1] + naming.minheight_tag / 2, line['attrs']['points'][0], line['attrs']['points'][1]];
    } else if (text['textWidth'] > naming.minwidth_tag && text['textWidth'] < naming.maxwidth_tag) {
        line['attrs']['points'] = [line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] - 5 - text['textWidth'], line['attrs']['points'][1], line['attrs']['points'][0] - 5 - text['textWidth'], line['attrs']['points'][1]+naming.minheight_tag, line['attrs']['points'][6], line['attrs']['points'][1]+naming.minheight_tag, line['attrs']['points'][8], line['attrs']['points'][1]+naming.minheight_tag/2, line['attrs']['points'][0], line['attrs']['points'][1]];
        var wid = line['attrs']['points'][0]-line['attrs']['points'][2]-naming.minwidth_tag;
        var w= line['attrs']['points'][0]-line['attrs']['points'][2];
        if(line['attrs']['points'][2]+group.x()+20<20){
            line['attrs']['points'][2] = 20-group.x();
            line['attrs']['points'] = [line['attrs']['points'][2]+w,line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]+w,line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]+w+25,line['attrs']['points'][1]+naming.minheight_tag/2,line['attrs']['points'][2]+w,line['attrs']['points'][1]];
        }else if(group.x()+line['attrs']['points'][2]+wid > 401-wid){
            line['attrs']['points'][2]=401-2*wid-group.x();
            line['attrs']['points'] = [line['attrs']['points'][2]+w,line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]+w,line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]+w+25,line['attrs']['points'][1]+naming.minheight_tag/2,line['attrs']['points'][2]+w,line['attrs']['points'][1]];
        }
    }else if(text['textWidth'] > naming.maxwidth_tag){
        addtooltip(group);
        line['attrs']['points'] = [line['attrs']['points'][0], line['attrs']['points'][1], line['attrs']['points'][0] - naming.maxwidth_tag, line['attrs']['points'][1], line['attrs']['points'][0] -naming.maxwidth_tag, line['attrs']['points'][1]+naming.minheight_tag, line['attrs']['points'][6], line['attrs']['points'][1]+naming.minheight_tag, line['attrs']['points'][8], line['attrs']['points'][1]+naming.minheight_tag/2, line['attrs']['points'][0], line['attrs']['points'][1]];
        var wid = line['attrs']['points'][0]-line['attrs']['points'][2]-naming.minwidth_tag;
        if(line['attrs']['points'][2]+group.x()+20<20){
            line['attrs']['points'][2] = 20-group.x();
            line['attrs']['points'] = [line['attrs']['points'][2]+naming.maxwidth_tag,line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]+naming.maxwidth_tag,line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]+naming.maxwidth_tag+25,line['attrs']['points'][1]+naming.minheight_tag/2,line['attrs']['points'][2]+naming.maxwidth_tag,line['attrs']['points'][1]];
        }else if(group.x()+line['attrs']['points'][2]+wid < 401-wid){
            line['attrs']['points'][2]=401-2*wid-group.x();
            line['attrs']['points'] = [line['attrs']['points'][2]+naming.maxwidth_tag,line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1],line['attrs']['points'][2],line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]+naming.maxwidth_tag,line['attrs']['points'][1]+naming.minheight_tag,line['attrs']['points'][2]+naming.maxwidth_tag+25,line['attrs']['points'][1]+naming.minheight_tag/2,line['attrs']['points'][2]+naming.maxwidth_tag,line['attrs']['points'][1]];
        }
        var truncat = group.find('.answer')[0];
        if (getTextWidth(truncat.text(), '16px arial') > naming.maxwidth_tag){
            for (i = 1; i < truncat.text().length; i++) {
                if (getTextWidth(truncat.text().substr(0, i), '16px arial') > naming.maxwidth_tag) {
                    truncat.text(truncat.text().substr(0, i - 2) + '..');
                    break;
                }
            }
        }
    }
    group.find('.delete').remove();
    group.find('.edit').remove();
    group.find('.deco').setX(line['attrs']['points'][8] - 10 - 3);
    group.find('.deco').setY(line['attrs']['points'][9]);
    group.find('.answer').setX(line['attrs']['points'][2] + 10);
    var connector = group.find('.connecting');
    var inix = connector[0]['attrs']['points'][2];
    var iniy = connector[0]['attrs']['points'][3];
    connector[0]['attrs']['points'] = [line['attrs']['points'][8], line['attrs']['points'][9], inix, iniy];
    var edit = group.find('.editButton');
    var color = edit[0]['attrs']['fill'];
    edit.remove();
    addEditButton(group, (line['attrs']['points'][0] + line['attrs']['points'][2]) / 2, line['attrs']['points'][1], color);
    addDeleteIcon(group, line['attrs']['points'][2] - 20, (line['attrs']['points'][3] + line['attrs']['points'][5]) / 2, color);
    group['children'][0].fill('white');
    group['children'][0].opacity(0.5);
    //stage.find('Layer')[0].draw();
};

function updateTextAreaTag(group) {
    var text = group.find('.answer')[0];
    var textwidth = getTextWidth(group['attrs']['tempAnswer'],'14px arial');
    var shape = group.find('.droppable')[0];
    if (group['children'][0]['className'] == "Rect") {
        if (textwidth > shape.width()) {
            addtooltip(group);
        }
    }else{
        if(textwidth > shape.radius()*2){
            addtooltip(group);
        }
    }
    text.text(group['attrs']['tempAnswer']);
    text.fontSize(14);
    if (group['children'][0]['className'] == "Rect") {
        var rect = group.find('.droppable')[0];
        if (text.width() > rect.width()) {
            textSize(rect, text);
        }
        var finalX = positionX(group) + (0.5 * rect.width()) - (0.5 * text.width()) - group.x();
        var finalY = positionY(group) + (0.5 * rect.height()) - (0.5 * text.height()) - group.y();
        text.x(finalX);
        text.y(finalY);
    } else if (group['children'][0]['className'] == "Circle") {
        var circle = group.find('.droppable')[0];
        if (text.width() > (circle.radius() * 2)) {
            textSize(circle, text);
        }
        var finalX = circle.x() - text.width() * 0.5;
        var finalY = circle.y() - text.height() * 0.5;
        text.x(finalX);
        text.y(finalY);
    }
};

function textSize(shape, text) {
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

function getTextWidth(text, fonter) {
    var canvas = getTextWidth.canvas || (getTextWidth.canvas = document.createElement("canvas"));
    var context = canvas.getContext("2d");
    context.font = fonter;
    var metrics = context.measureText(text);
    return metrics.width;
};

function pointsdragmove(e) {
    var points = stage.find('Layer')[0].find('.point');
    var points = e.target;
    var id = points['attrs']['id'];
    var groups = stage.find('Layer')[0].find('Group');
    for (i = 0; i < groups.length; i++) {
        if (groups[i]['attrs']['id'] == id) {
            var group = groups[i];
        }
    }
    var w_of_tag;
    var line = group.find('.connecting');
    var poly = group.find('.pentagon');
    var txt = group.find('.answer');
    var penta_coordinates = poly[0]['attrs']['points'];
    var topLeftX = penta_coordinates[0];
    var topLeftY = penta_coordinates[1];
    var topRightX = penta_coordinates[2];
    if (topRightX > topLeftX) {
        w_of_tag = topRightX - topLeftX;
    } else {
        w_of_tag = topLeftX - topRightX;
    }
    if (penta_coordinates[8] + group.x() > points.x() && penta_coordinates[2] + group.x() > points.x()) {
        var bottomLeftY = penta_coordinates[7];
        line[0]['attrs']['points'] = [topLeftX - 25, (topLeftY + bottomLeftY) / 2, points.x() - group.x(), points.y() - group.y()];
        if (txt[0]) {
            txt.setX(penta_coordinates[0]);
            group.find('.edit')[0].text('Edit');
        }
    } else
    if (penta_coordinates[8] + group.x() < points.x() && penta_coordinates[0] + group.x() > points.x()) {
        penta_coordinates[0] = penta_coordinates[0] - 50;
        penta_coordinates[2] = penta_coordinates[2] - 50 - 2 * w_of_tag;
        penta_coordinates[4] = penta_coordinates[4] - 50 - 2 * w_of_tag;
        penta_coordinates[6] = penta_coordinates[6] - 50;
        penta_coordinates[8] = penta_coordinates[8];
        penta_coordinates[10] = penta_coordinates[0];
        group.find('.delete').remove();
        var edit = group.find('.editButton');
        var color = edit[0]['attrs']['fill'];
        group.find('.edit').remove();
        group.find('.editButton').remove();
        group.find('.deco').setX(group['children'][0]['attrs']['points'][8] - 10 - 3);
        addEditButton(group, penta_coordinates[2] + (penta_coordinates[0] - penta_coordinates[2]) / 2, penta_coordinates[1], color);
        addDeleteIcon(group, penta_coordinates[2] - 20, (penta_coordinates[3] + penta_coordinates[5]) / 2, color);
        if (txt[0]) {
            txt.setX(penta_coordinates[2] + 10);
            group.find('.edit')[0].text('Edit');
        }
        var topLeftX = group['children'][0]['attrs']['points'][0];
        var topLeftY = group['children'][0]['attrs']['points'][1];
        var bottomLeftY = group['children'][0]['attrs']['points'][7];
        line[0]['attrs']['points'] = [topLeftX + 25, (topLeftY + bottomLeftY) / 2, points.x() - group.x(), points.y() - group.y()];
    } else if (penta_coordinates[2] + group.x() < points.x() && penta_coordinates[0] + group.x() < points.x()) {
        var topLeftX = penta_coordinates[0];
        var topLeftY = penta_coordinates[1];
        var bottomLeftY = penta_coordinates[7];
        line[0]['attrs']['points'] = [topLeftX + 25, (topLeftY + bottomLeftY) / 2, points.x() - group.x(), points.y() - group.y()];
        if (txt[0]) {
            txt.setX(penta_coordinates[2] + 10);
            group.find('.edit')[0].text('Edit');
        }
    } else if (penta_coordinates[8] + group.x() > points.x() && penta_coordinates[2] + group.x() < points.x()) {
        penta_coordinates[0] = penta_coordinates[0] + 50;
        penta_coordinates[2] = penta_coordinates[2] + 50 + 2 * w_of_tag;
        penta_coordinates[4] = penta_coordinates[4] + 50 + 2 * w_of_tag;
        penta_coordinates[6] = penta_coordinates[6] + 50;
        penta_coordinates[8] = penta_coordinates[8];
        penta_coordinates[10] = penta_coordinates[0];
        group.find('.delete').remove();
        group.find('.edit').remove();
        var edit = group.find('.editButton');
        var color = edit[0]['attrs']['fill'];
        group.find('.editButton').remove();
        group.find('.deco').setX(group['children'][0]['attrs']['points'][8] + 10 + 3);
        addEditButton(group, penta_coordinates[0] + (penta_coordinates[2] - penta_coordinates[0]) / 2, penta_coordinates[1], color);
        addDeleteIcon(group, penta_coordinates[2], (penta_coordinates[3] + penta_coordinates[5]) / 2, color);
        var topLeftX = group['children'][0]['attrs']['points'][0];
        var topLeftY = group['children'][0]['attrs']['points'][1];
        line[0]['attrs']['points'] = [topLeftX - 25, (topLeftY + bottomLeftY) / 2, points.x() - group.x(), points.y() - group.y()];
        if (txt[0]) {
            txt.setX(penta_coordinates[0]);
            group.find('.edit')[0].text('Edit');
        }
    }
    stage.find('Layer')[0].draw();
};

function check() {
    var imgs = stage.find('.bgimage');
    if(naming.minbgwidth/(imgs[0].width()) < naming.minbgheight/(imgs[0].height())){
        var ratio = (naming.minbgwidth) / imgs[0].width();
        imgs[0].width(naming.minbgwidth);
        imgs[0].height(imgs[0].height() * ratio);
    }else{
        var ratio = (naming.minbgheight) / imgs[0].height();
        imgs[0].height(naming.minbgheight);
        imgs[0].width(imgs[0].width() * ratio);
    }

    stage.find('Layer')[0].draw();
    stage.draw();
};

//uploading file to server
function uploadFileInput(successFunc, failFunc) {
    $('#input-image').get(0).files;
    uploadFile($('#input-image').get(0).files, 'uploadfile', function(data, textStatus, jqXHR, uploaded_url) {
        uploaded_url = uploaded_url.substring(uploaded_url.indexOf("image_"));
        successFunc(uploaded_url);
    }, function(jqXHR, textStatus, errorThrown) {
        failFunc(uploaded_url);
    });
};

//google custom search function
function mySearch() {
    $.loader({
        className:"blue-with-image-2",
        content:''
    });
    var x = document.getElementById("myText").value;
    var url1 = "https://www.googleapis.com/customsearch/v1element?key=AIzaSyCVAXiUzRYsML1Pv6RwSG1gunmMikTzQqY&filter=1&num=9&rights=cc_noncommercial&hl=en&searchtype=image&cx=013932277737828851970:swtqb7-jepk&alt=json&disableWebSearch=false&gl=in&q=";
    var url = url1 + x;

    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (xhttp.readyState == 4 && xhttp.status == 200) {
            var obj = JSON.parse(xhttp.responseText);
            var myImages = '';
            if (obj.results.length) {
                for (var i = 0; i < obj.results.length; i++) {
                    if (obj.results[i]['url'].search('%') == -1) {
                        myImages += '<img class="google-images" src="' + obj.results[i]['url'] + '" width="90px" height="90px" onclick="image(event,this)" style="margin:10px"  id = "img' + i + '"/>'
                    }
                }
                $.loader('close');
            } else {
                $.loader('close');
                myImages = '<h5 style="padding:10px">Error..! No Images to display here</h5>';
            }
            document.getElementById('myImgHolder').innerHTML = myImages;
            $('#myImgHolder').prepend('<p style="color:red">Tap/Click on the Image to upload</p>')
            $('#myImgHolder').css('background-color', '#f1f1f1');
            $('#myImgHolder').simplePagination({
                items_per_page : 9
            });
        }
    };
    xhttp.open("GET", url, true);
    xhttp.send();
};


function image(e, x) {
    $.loader({
        className:"blue-with-image-2",
        content:''
    });
    uploadUrl(e, x.src, 'uploadurl', function(data, textStatus, jqXHR, uploaded_url) {
        var img = $('<img src="' +uploaded_url + '"/>').load(function() {
            var w = this.width;
            var h = this.height;
            if (w < naming.minbgwidth || h < naming.minbgheight) {
                $.loader('close');
                err('Minimum resolution is 800x500 px');
            } else {
                var output = document.getElementById('output');
                output.src = uploaded_url;
                $.loader('close');
            }
        });

    }, function(jqXHR, textStatus, errorThrown) {
        $.loader('close');
        err('Unable to upload image to server');
    });
};

function previewImage(input) {
    var preview = document.getElementById('preview');
    if (input.files && input.files[0]) {
        var reader = new FileReader();
        reader.onload = function(e) {
            preview.setAttribute('src', e.target.result);
        }
        reader.readAsDataURL(input.files[0]);
    } else {
        preview.setAttribute('src', 'placeholder.png');
    }
};

function loadImageToServer(event) {
    $.loader({
        className:"blue-with-image-2",
        content:''
    });
    var files = $("#imageUpload").get(0).files;
    uploadFile(files, "uploadfile", function(data, textStatus, jqXHR, uploaded_url) {
        var img = $('<img src="' +uploaded_url + '"/>').load(function() {
            var w = this.width;
            var h = this.height;
            if (w < naming.minbgwidth || h < naming.minbgheight) {
                $.loader('close');
                err('Minimum resolution is 800x500 px');
            } else {
                var output = document.getElementById('output');
                output.src = uploaded_url;
                $.loader('close');
            }
        });

    }, function(jqXHR, textStatus, errorThrown) {
        err('Unable to upload image to server');
        $.loader('close');
    });
};

function err(text){
    $.alert({
        title: 'Notification',
        content: text,
        confirmButtonClass: 'error-confirm',
        confirm: function() {}
    });
}

var dropZone = document.getElementById('dropUpload');
dropZone.addEventListener('dragover', handleDrag, false);
dropZone.addEventListener('drop', handleDrop, false);
//drag and drop image
function handleDrag(e) {
    e.stopPropagation();
    e.preventDefault();
};

function handleDrop(e) {
    e.stopPropagation();
    e.preventDefault();
    var files = e.dataTransfer.files;
    $.loader({
        className:"blue-with-image-2",
        content:''
    });
    uploadFile(files, "uploadfile", function(data, textStatus, jqXHR, uploaded_url) {
        var img = $('<img src="' +uploaded_url + '"/>').load(function() {
            var w = this.width;
            var h = this.height;
            if (w < naming.minbgwidth || h < naming.minbgheight) {
                $.loader('close');
                err('Minimum resolution is 800x500 px');
            } else {
                var output = document.getElementById('output');
                output.src = uploaded_url;
                $.loader('close');
            }
        });

    }, function(jqXHR, textStatus, errorThrown) {
        $.loader('close');
        err('Unable to upload image to server');
    });
};

function createjson(){
    var json = {};
    var stageJson = stage.toJSON();
    var allOptions = [];
    var images = [];
    var options = [];
    $('.options li').each(function(i) {
        if ($(this).attr('class') == "option_text") {
            var object = {
                'text': $(this).find('span').eq(1).html()
            }
            allOptions.push(object);
            options.push(object);
        } else {
            var object = {
                'image': $(this).find('img').attr('src').substring($(this).find('img').attr('src').indexOf("image_"))
            }
            allOptions.push(object);
            options.push(object);
            images.push($(this).find('img').attr('src').substring($(this).find('img').attr('src').indexOf("image_")));
        }
    });
    var correctOptions = stage.find('.answer');
    for (i = 0; i < correctOptions.length; i++) {
        if (correctOptions[i]['attrs']['answertype'] == "text") {
            var object = {
                'text': correctOptions[i].getParent()['attrs']['correctAnswer']
            };
            allOptions.push(object);

        } else {
            var object = {
                'image': correctOptions[i].getParent()['attrs']['correctAnswer']
            };
            allOptions.push(object);
            images.push(correctOptions[i].getParent()['attrs']['correctAnswer']);
        }
    }
    var bgimage = stage.find('.bgimage')[0]['attrs']['src'];
    images.push(bgimage);stage.draw();
    images.push('ignitor_logo.png');
    json['stage']=stageJson;
    json['alloptions'] = allOptions;
    json['instructions'] = $('.description_text').html();
    json['name'] = $('#contentName').val();
    json['description'] = $('#description').val();
    json['class'] =	$('#className').val();
    json['subject'] = $('#subject').val()
    json['topics'] = $('#chapter').val();
    json['learning_activity_type'] = $('#learning_activity_type').val();
    if(naming.logo != ""){
        json["logo"] = naming.logo;
    }
    else{
        json["logo"] = "ignitor_logo.png";
    }
    json['images'] = images;
    json['value_of_Z'] = naming.z;
    json['options'] = options;
    return json;
};


// jquery events
$('#AnswerModal').click(function() {
    $('.content-show').show();
    $('.img-preview-modal').hide();
    var buttonOffset = $(this).offset();
    $('.modal-dialog').css('width', '25%').css('margin-left', buttonOffset['left']).css('margin-top', buttonOffset['top'] + 1.5 * $(this).height() - $(window).scrollTop() + 10);
    $('.modal-content').css('height', '230px');
    $('.tagbox-answer').removeClass('hidden');
    $('.modal-description').addClass('hidden');
    $('#save').addClass('hidden');
    $('#AddWrongAnswer').removeClass('hidden');
    $('.modal-title-tagbox').html('Add other optional Answers');
    $('#input-image').val('');
    $('#input-answer').val('');
    $('#myModal').modal('show');
});

$('#DescriptionModal').click(function() {
    var buttonOffset = $(this).offset();
    $('.modal-dialog').css('width', '50%').css('margin-left', buttonOffset['left']).css('margin-top', buttonOffset['top'] + 1.5 * $(this).height() - $(window).scrollTop() + 10);
    $('.modal-content').css('height', '235px');
    $('.tagbox-answer').addClass('hidden');
    $('.modal-description').removeClass('hidden');
    $('#textarea-description').val($('.description').find('p').text());
    $('#myModal').modal('show');
});

$('#save').click(function(e) {
    var groupId = $(this).data('id');
    var Allgroups = stage.find('Layer')[0].find('Group');
    for (i = 0; i < Allgroups.length; i++) {
        if (Allgroups[i]['attrs']['id'] == groupId) {
            var group = Allgroups[i];
        }
    }
    var type = group['children'][0]['className'];
    if($('#input-answer').val() || $('#input-image').val()){
        if ($('#input-answer').val()) {
            group['attrs']['correctAnswer'] = $('#input-answer').val();
            group['attrs']['correctAnswerType'] = "text";
            group['attrs']['tempAnswer'] = $('#input-answer').val();
            setAnswer(group, type, 'text');
        } else if ($('#input-image').val()) {
            uploadFileInput(function(uploaded_url) {
                var img = $('<img src="' +imagePrefix(uploaded_url) + '"/>').load(function() {
                    var w = this.width;
                    var h = this.height;
                    if (w < naming.maximgwidth_ans && h < naming.maximgheight_ans) {
                        group['attrs']['correctAnswer'] = uploaded_url;
                        group['attrs']['correctAnswerType'] = "image";
                        setAnswer(group, type, 'image');
                    } else {
                        err('The maximum image resolution should be 200x200 px');
                    }
                });
            }, function(uploaded_url) {
                err('Unable to upload image to server');
            });
        }
        $('#myModal').modal('hide');
    }else{
        err('Enter something to save');
    }

});

$('#AddWrongAnswer').click(function() {
    var numberOfOptions = $('.answer_options li').length;
    if(numberOfOptions < naming.max_limit){
        if ($('#input-answer').val()) {
            $('.answer_options').find('ul').append('<li class="option_text"></span><span class="answer_remove_text pull-left" style="margin-left:3px;position:relative;top:0px;left:2px;color:#ffe11c"><b>X&nbsp</b></span><span style="text-align:center">' + $("#input-answer").val() + '</li>');
            $('.answer_remove_text').click(function() {
                $(this).parent().remove();
            });
        } else if ($('#input-image').val()) {
            uploadFileInput(function(uploaded_url) {
                var img = $('<img src="' + imagePrefix(uploaded_url) + '"/>').load(function() {
                    var w = this.width;
                    var h = this.height;
                    if (w < naming.maximgwidth_ans && h < naming.maximgheight_ans) {
                        $('.answer_options').find('ul').append('<li class="option_image"><span class="answer_remove" style="margin-left:5px;margin-right:5px;position:relative;top:-37px;color:#ffe11c"><b>X</b></span><img src="' + imagePrefix(uploaded_url) + '" class="image-option"></li>');
                    } else {
                        err('The maximum image resolution should be 200x200 px');
                    }
                    $('.answer_remove').click(function() {
                        $(this).parent().remove();
                    });
                });
            }, function(uploaded_url) {
                err('Unable to upload image to server');
            });
        }
    }else{
        err('Maximum number of options have been added');
    }
});

$('#AddDescription').click(function() {
    var description = $('#textarea-description').val();
    if (description) {
        $('.description').empty().append('<h3 class="description-heading" >Instructions for the Activity:</h3><p class="description_text">' + description + '</p>');
        $('.description').height('auto');
        $('.answer_options').height($('.canvas_content').outerHeight(false) - $('.tag_options').outerHeight(true));
    } else {
        $('.description').empty().height(40);
        $('.answer_options').height($('.description').height() + $('#canvas_region').outerHeight(true) - $('.tag_options').outerHeight(true));
    }

});

$('.next').click(function() {
    var nxt = $('.nav-pills > .active').next('li').find('a');
    nxt.tab('show');
});


$('.continue_from_upload').click(function() {
    var nxt = $('.nav-pills > .active').next('li').find('a');
    var imageslink = document.getElementById('output');
    if (imageslink.src.split('/').pop() !== 'image-upload.png') {
        nxt.tab('show');
        var img = document.getElementById('output').src;
        img = img.substring(img.indexOf("image_"));
        loadStage(img);
    } else {
        err('Please upload the image to continue');
    }
});



$('#PreviewModal').mousedown(function(event) {
    $(this).contextmenu(function() {
        return false;
    });
//    stage.find('.delete').remove();
    var keycode = event.which;
    var json = createjson();
    if (keycode == 1) {
        $('#ModalForPreview').modal('show');
        $('.modal-dialog').css('width', '1024px');
        $('.modal-content').css('height', '600px');
        $('.modal-dialog').css('margin-left', 150);
        $('.modal-dialog').css('margin-top', 50);
        $('.previewBody').Play_name_the_image(json, naming.prefix);
    } else if (keycode == 3) {
        var url = document.location.origin + '/ignitor-web/play_name_the_image.html?value=' + JSON.stringify(json) + '';
        window.open(url, '_blank');
    }
});

$('.back').click(function() {
    var back = $('.nav-pills > .active').prev('li').find('a');
    back.tab('show');
});

$('#input-answer').attr('maxlength', naming.nametag_maxlen);
$('#textarea-description').attr('maxlength', naming.description_maxlen);


$('.search').on('click tap', function(e) {
    mySearch();
});

$('#myText').on('keydown', function(e) {
    if (event.keyCode == 13) {
        $(".search").click();
    }
});


$('#input-answer').on('keydown', function(e) {
    if ($(this).parent().parent().find('#save').is(':visible')) {
        if (event.keyCode == 13) {
            $("#save").click();
        }
    } else if ($(this).parent().parent().find('#AddWrongAnswer').is(':visible')) {
        if (event.keyCode == 13) {
            $("#AddWrongAnswer").click();
        }
    }
});


//Saving and editing template
// saving and editing the json

$('.save').click(function() {
    var json = createjson();
    //TO DO:send ajax request with the json created below
    $.ajax({
        url: "/learning_activities",
        dataType: 'json',
        type: 'POST',
        data: JSON.stringify(json),
        contentType: "application/json",
        cache: false,
        success: function(data, textStatus, jqXHR)
        {
            window.history.pushState({},"new url","/learning_activities");
            window.location.reload();

        },
        error: function(jqXHR, textStatus, errorThrown)
        {
            alert("error in saving");
        }
    });
    //var url = document.location.origin + '/save_learning_activity' + 'data?' + JSON.stringify(json)+' ';
    //window.open(url);
});


$(document).ready(function(){

    //TODO: change this to check if this edit view.
    if(document.URL.split('?')[1]){
        //Showing loader while activity is being restored
        $.loader({
            className:"blue-with-image-2",
            content:''
        });
        //TODO: get activity id instead of actual json from url
        var json=document.URL.split('?')[1];
        if(json){
            var finaljson = JSON.parse(decodeURIComponent(json));
            //TODO: get the json with ajax request with the above id and call the below function with the result json.
            restoreNameTheParts(finaljson);
            //Closing loader once everything is restored.
            $.loader('close');
        }
    }
});

function restoreNameTheParts(finaljson){
    if (finaljson['instructions']) {
        $('.description').empty().append('<h3 class="description-heading" style="margin-top:0px">Description:</h3><p class="description_text">' + finaljson['instructions'] + '</p>');
    }
    $('#contentName').val(finaljson['name']);
    $('#description').val(finaljson['description']);
    $('#className').val(finaljson['class']);
    $('#subject').val(finaljson['subject']);
    $('#chapter').val(finaljson['topics']);

    naming.logo = finaljson["logo"];
    if(naming.logo == 'ignitor_logo.png'){
        $(".logo-btn").find("img").attr("src","images/"+naming.logo );
    }else{
        $(".logo-btn").find("img").attr("src",imagePrefix(naming.logo));
    }
    if (finaljson['options']) {
        var options = finaljson['options'];
        for (i = 0; i < options.length; i++) {
            if (options[i]['image']) {
                $('.answer_options').find('ul').append('<li class="option_image"><span class="answer_remove" style="margin-left:5px;margin-right:5px;position:relative;top:-37px;color:#ffe11c"><b>X</b></span><img src="' + imagePrefix(options[i]["image"]) + '" class="image-option"></li>');
            } else {
                $('.answer_options').find('ul').append('<li class="option_text"></span><span class="answer_remove pull-left" style="margin-left:3px;position:relative;top:0px;left:2px;color:#ffe11c"><b>X&nbsp</b></span><span style="text-align:center">' + options[i]["text"] + '</li>');
            }
        }
        $('.answer_remove').click(function() {
            $(this).parent().remove();
        });
    }
    $('#canvas_region').EditNameTheParts(finaljson['stage'], finaljson['value_of_Z']);
}


$('.unlock').click(function(){
    stage.find('.bgimage').setDraggable(true);
    $(this).hide();
    $('.lock').show();
});

$('.lock').click(function(){
    stage.find('.bgimage').setDraggable(false);
    $(this).hide();
    $('.unlock').show();
});

+$(".logo-btn").click(function(){
    $(".logo-upload").trigger("click");
});
$('.logo-upload').click(function(event){
    this.value = '';
});
$('.logo-upload').change(function(event){
    newLogoImage(event);
});

function newLogoImage(event){
    var logoclass = $(event.target);
    uploadLogo(logoclass,function(url){
        $(".logo-btn").find("img").attr("src",url);
        naming.logo = url.split(naming.prefix)[1];
    },function(url){
        err('Unable to upload image to server');
    })
}

function uploadLogo(logoclass,succesFunc,failureFunc){
    var files = $(logoclass).get(0).files;
    $.loader({
        className:"blue-with-image-2",
        content:''
    });
    uploadFile(files,"uploadfile",function(data, textStatus, jqXHR, uploaded_url){
        succesFunc(uploaded_url);
        $.loader('close');
    },function(data, textStatus,  errorThrown){
        err('Unable to upload image');
        $.loader('close');
    });
}
