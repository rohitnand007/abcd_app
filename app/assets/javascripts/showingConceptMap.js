$(document).ready(function(){
	$.post("/concepts/data", {'concept_id': concept_id}, function(data, status, xhr){
		if(status == "success"){
			buildCanvas(data);
		}
	}, "json");
});

function buildCanvas(data){
	console.log("Data is: ");
	console.log(data);
	nodeRadius = 0.03;
	console.log("Inside Start");
	  canvas = document.getElementById("canvas_1");
	  canvas.addEventListener('mousemove', mouseMove, false);
	  canvas.addEventListener('mousedown', mouseDown, true);
	  canvas.addEventListener('mouseup', mouseUp, true);
	  context = canvas.getContext("2d");
	  window.addEventListener('resize', resizeCanvas);
	  context.fillStyle = "RGB(255, 0, 0)";
	  editable = true;
	  //nodeNumber = 0;
	  allNodes= new Array();
	//find the root node
	for(var index in data){
		if(!data[index].parent_id){
			root = new Node(data[index].x, data[index].y, nodeRadius, null);
			root.id = data[index].id;
			root.description = data[index].name;
			root.text = data[index].description;
			allNodes.push(root);
		}
	}
	//find the children of root note
	buildMap(root, data);
	selectingNode = true;
	  selectedNode = root;
	  hideGrandChildren();
	  mouseClicked = false;
	  resizeCanvas();
	  clearCanvas();
	  editable = true;
	$("#selectedNodeName").attr("value", selectedNode.description);
}

function buildMap(root, data){
	for(var index in data){
		if(data[index].parent_id == root.id){
			var node = new Node(data[index].x, data[index].y, nodeRadius, root);
			node.id = data[index].id;
			node.description = data[index].name;
			node.text = data[index].description;
			root.addChild(node);
			allNodes.push(node);
			buildMap(node, data);
		}
	}
}