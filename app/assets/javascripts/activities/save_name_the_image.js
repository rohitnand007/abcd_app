$.fn.EditNameTheParts = function(json, y){
	$(this).empty();
	$(this).append('<div id="canvas_region"></div>');
	stage = Konva.Node.create(json, 'canvas_region');
		
	var imagesforedit = stage.find('.bgimage')[0];
	document.getElementById('output').src = imagePrefix(imagesforedit['attrs']['src']);

	var images=[];
	var images_in_stage = stage.find('Image');
	for(i=0;i<images_in_stage.length; i++){
		if(images_in_stage[i]['attrs']['name'] == 'answer'){
			images.push(images_in_stage[i]);
		}
	}
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
			img.src = imagePrefix(images[i]['attrs']['src']);
		}
	}
	function start() {
		for (var i = 0; i < imgs.length; i++) {
			images[i].image(imgs[i]);
			stage.draw();
		}
	}
	
	var rect = stage.find('.editButton');
	var edit = stage.find('.edit');
	var remove = stage.find('.delete'); 

	//circle bottom anchor
	var bottom = stage.find('.bottom');

	bottom.on('dragmove', function(e) {
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
		var group = this.getParent().getParent();
		updateCircle(this);
		if (group.find('.answer').length > 0) {
			if (group.find('.answer')[0]['className'] == "Image") {
				updateImageAreaTag(group);
			} else if (group.find('.answer')[0]['className'] == 'Text') {
				updateTextAreaTag(group);
			}
		}
		stage.find('Layer')[0].draw();
	});
	bottom.on('mousedown touchstart', function() {
		this.getParent().setDraggable(false);
		this.moveToTop();
	});
	bottom.on('dragend', function() {
		this.getParent().setDraggable(true);
		stage.find('Layer')[0].draw();
	});
	bottom.on('mouseover', function() {
		var layer = this.getLayer();
		document.body.style.cursor = 'pointer';
		this.setStrokeWidth(4);
		stage.find('Layer')[0].draw();
	});
	bottom.on('mouseout', function() {
		var layer = this.getLayer();
		document.body.style.cursor = 'default';
		this.setStrokeWidth(2);
		stage.find('Layer')[0].draw();
	});

	var lefttopanchor = stage.find('.topLeft');
	lefttopanchor.on('dragmove', function(e) {
		this['attrs']['dragBoundFunc'] = function(pos) {
			var group = this.getParent();
			var stage = group.getStage();
			var positionx = positionX(group);
			var positiony = positionY(group);
			var bottomRight = group.find('.bottomRight')[0];
			var newX = (bottomRight.x() - (pos.x - group.x())) < 50 ? (bottomRight.x() - 50 + group.x()) : pos.x;
			var newY = (bottomRight.y() - (pos.y - group.y())) < 50 ? (bottomRight.y() - 50 + group.y()) : pos.y;
			var new1X = newX < 5 ? 5 : newX;
			var new1Y = newY < 20 ? 20 : newY;
			return {
				x: new1X,
				y: new1Y
			};
		};
		update(this, 'rect');
		if (this.getParent().find('.answer').length > 0) {
			if (this.getParent().find('.answer')[0]['className'] == "Image") {
				updateImageAreaTag(this.getParent());
			} else if (this.getParent().find('.answer')[0]['className'] == 'Text') {
				updateTextAreaTag(this.getParent());
			}
		}
	});

	var righttopanchor = stage.find('.topRight');
	righttopanchor.on('dragmove', function(e) {
		this['attrs']['dragBoundFunc'] = function(pos) {
			var group = this.getParent();
			var stage = group.getStage();
			var positionx = positionX(group);
			var positiony = positionY(group);
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
		};
		update(this, 'rect');
		if (this.getParent().find('.answer').length > 0) {
			if (this.getParent().find('.answer')[0]['className'] == "Image") {
				updateImageAreaTag(this.getParent());
			} else if (this.getParent().find('.answer')[0]['className'] == 'Text') {
				updateTextAreaTag(this.getParent());
			}
		}
	});

	var leftbottomanchor = stage.find('.bottomLeft');
	leftbottomanchor.on('dragmove', function(e) {
		this['attrs']['dragBoundFunc'] = function(pos) {
			var group = this.getParent();
			var stage = group.getStage();
			var positionx = positionX(group);
			var positiony = positionY(group);
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
		};
		update(this, 'rect');
		if (this.getParent().find('.answer').length > 0) {
			if (this.getParent().find('.answer')[0]['className'] == "Image") {
				updateImageAreaTag(this.getParent());
			} else if (this.getParent().find('.answer')[0]['className'] == 'Text') {
				updateTextAreaTag(this.getParent());
			}
		}
	});

	var rightbottomanchor = stage.find('.bottomRight');
	rightbottomanchor.on('dragmove', function(e) {
		this['attrs']['dragBoundFunc'] = function(pos) {
			var group = this.getParent();
			var stage = group.getStage();
			var positionx = positionX(group);
			var positiony = positionY(group);
			var newX = (pos.x - positionx) < 50 ? (50 + positionx) : pos.x;
			var newY = (pos.y - positiony) < 50 ? (50 + positiony) : pos.y;
			var new1X = newX > (stage.width() - 20) ? (stage.width() - 20) : newX;
			var new1Y = newY > (stage.height()) ? (stage.height()) : newY;
			return {
				x: new1X,
				y: new1Y
			};
		};
		update(this, 'rect');
		if (this.getParent().find('.answer').length > 0) {
			if (this.getParent().find('.answer')[0]['className'] == "Image") {
				updateImageAreaTag(this.getParent());
			} else if (this.getParent().find('.answer')[0]['className'] == 'Text') {
				updateTextAreaTag(this.getParent());
			}
		}
	}); 

	var struct = stage.find('Group');
	for(var n=0; n<struct.length; n++){
		if(struct[n]['children'][0]['className']=='Line'){
			struct[n]['attrs']['dragBoundFunc'] = function(pos) {
				var stage = this.getStage();
				if (this['children'][0]['attrs']['points'][2] > this['children'][0]['attrs']['points'][0]) {
					var wid = this['children'][0]['attrs']['points'][2]-this['children'][0]['attrs']['points'][0]-naming.minwidth_tag;
					if (pos.x+this['children'][0]['attrs']['points'][2]-wid < 421+wid) {
						newX = 421-this['children'][0]['attrs']['points'][2]+2*wid;
					} else if (pos.x + this['children'][0]['attrs']['points'][2] + 20 > stage.width()) {
						newX = stage.width() - this['children'][0]['attrs']['points'][2] - 20;
					} else {
						newX = pos.x;
					}
				} else if (this['children'][0]['attrs']['points'][2] < this['children'][0]['attrs']['points'][0]) {
					var wid = this['children'][0]['attrs']['points'][0]-this['children'][0]['attrs']['points'][2]-naming.minwidth_tag;
					if (pos.x + this['children'][0]['attrs']['points'][2] < 20) {
						newX = 20 - this['children'][0]['attrs']['points'][2];
					} else if (pos.x+this['children'][0]['attrs']['points'][2]+wid > 401-wid) {
						newX = 401-this['children'][0]['attrs']['points'][2]-2*wid;
					} else {
						newX = pos.x;
					}
				}
				var finalY = this['children'][0]['attrs']['points'][5] + pos.y;
				if (pos.y < -180) {
					var newY = -180;
				} else if (finalY > (stage.height() - 10)) {
					var newY = stage.height() - 10 - this['children'][0]['attrs']['points'][5];
				} else {
					var newY = pos.y;
				}
				return {
					x: newX,
					y: newY
				};
			}

			struct[n].on('dragmove', function(e) {
				updateLine(e);
				stage.find('Layer')[0].draw();
			});

		}else if(struct[n]['children'][0]['className']=='Rect'){
			struct[n]['attrs']['dragBoundFunc'] = function(pos) {
				var stage = this.getStage();
				var finalX = this.find('.delete')[0].x() + pos.x;
				var finalY = this.find('.bottomRight')[0].y() + pos.y;
				var topLeft = this.find('.topLeft')[0];
				if ((topLeft.x() + pos.x) < 5) {
					var newX = 5 - topLeft.x();
				} else if (finalX > (stage.width() - 20)) {
					var newX = stage.width() - 20 - this.find('.delete')[0].x();
				} else {
					var newX = pos.x;
				}
				if ((topLeft.y() + pos.y) < 20) {
					var newY = 20 - topLeft.y();
				} else if (finalY > (stage.height() - 10)) {
					var newY = stage.height() - 10 - this.find('.bottomRight')[0].y();
				} else {
					var newY = pos.y;
				}
				return {
					x: newX,
					y: newY
				};
			}
		}else if(struct[n]['children'][0]['className']=='Circle'){
			struct[n]['attrs']['dragBoundFunc'] = function(pos) {
				var stage = this.getStage();
				var circle = this.find('.droppable')[0];
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
		}
	}
	var nametag = stage.find('.pentagon');
	var points = stage.find('.point');

	nametag.on('dragmove', function(e) {
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

	remove.on('mouseover', function(e) {
		document.body.style.cursor = 'pointer';
	});
	remove.on('mouseout', function() {
		document.body.style.cursor = 'default';
	});
	remove.on('click tap', function(e) {
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
		group.remove();
		stage.find('Layer')[0].draw();
	});
	naming.z = y;
	stage.draw();
}