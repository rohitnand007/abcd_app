function tinymceEditor(){
	tinyMCE.init({
			                    mode:'textareas',
			                    width: '200px',
			                    height: 0.75*window.innerHeight,
			                    //height: '100%',
			                    plugins:"uploadimage,table,advhr,advimage,advlink,insertdatetime,media,preview",
			                    theme:'advanced',
			                    theme_advanced_buttons1:"bold,italic,underline,separator,bullist,numlist,separator,undo,redo,|,forecolor,backcolor, |, justifyleft, justifycenter, justifyright, justifyfull",
			                    theme_advanced_buttons2:"formatselect,fontselect,fontsizeselect",
			                    theme_advanced_buttons3:"tablecontrols,|,charmap,iespell,media,advhr",
			                    theme_advanced_buttons4:"hr,removeformat,visualaid,|,sub,sup,|,insertdate,inserttime,preview,uploadimage,|,link,unlink,code",
			                    theme_advanced_toolbar_location:"top",
			                    theme_advanced_toolbar_align:"left", theme_advanced_statusbar_location:"none",
			                    relative_urls:false,
			                    skin : "o2k7",
			                    skin_variant : "silver",
			                    document_base_url: "http://"+ window.location.host+"/question_images/",
			                    init_instance_callback: "defaultContent"
		        })
		        ;
		        tinyMCE.addI18n('en.uploadimage', {
		            desc:'Insert an image from your computer'
		        });
		        //updateEditor();
}
function defaultContent(inst){
	updateEditor();
}
function start() {
  //alert("Inside Start");
  console.log("Inside Start");
  canvas = document.getElementById("canvas_1");
  canvas.addEventListener('mousemove', mouseMove, false);
  canvas.addEventListener('mousedown', mouseDown, true);
  canvas.addEventListener('mouseup', mouseUp, true);
  //canvas.addEventListener('mouseout', focusout, true);
  context = canvas.getContext("2d");
  window.addEventListener('resize', resizeCanvas);
  context.fillStyle = "RGB(255, 0, 0)";
  editable = true;
  nodeRadius = 0.03;
  //nodeNumber = 0;
  allNodes= new Array();
  //drawNode(canvas.width/2, canvas.height/2, 10);
  root = new Node(0.5, 0.5, nodeRadius, null);
  getId(root);
  
  //alert("New Node added:" + root.x +" y: "+root.y +" r: "+root.radius+ " p: "+root.parent);
  allNodes.push(root);
  selectingNode = true;
  selectedNode = root;
  mouseClicked = false;
  drawNode(root);
  resizeCanvas();
  updateEditor();
  $("#selectedNodeName").attr("value", selectedNode.description);
}

function focusout(){
	alert("Lost Focus");

}

function getId(node){
	$.post("/concepts/add_new_element", {x:node.x, y:node.y}, function(data, status, xhr){
		if(status=="success"){
			node.id = data.id;
			saveConceptMap();
			//alert('Id assigned'+ node.id);
		}
	}, "json");
}

function resizeCanvas(){
	//alert('Resizing Canvas');
	var width = window.innerWidth;
	var height = window.innerHeight;
	canvas.width = 0.7*window.innerWidth;
	canvas.height = 0.75*window.innerHeight;
	console.log('width: ' + width);
	//canvas.width = 0.6*width;
	//canvas.height = 0.8*height;
	clearCanvas();
	var temp = $("#tinymceEditor").css('width');
	console.log("width "+ temp);
	temp = $('#tinymceEditor').css('height');
	console.log('Height '+ temp);
	//$("#tinymceEditor").css({'width': width*0.05, 'height': height*0.1});
	temp = $("#tinymceEditor").css('width');
	console.log(" new width "+ temp);
	temp = $('#tinymceEditor').css('height');
	console.log('Height '+ temp);
	resizeEditor();
}

function resizeEditor(){
	//var editor = $("#tinymceEditor");
	$("content").css("width", 0.2*window.innerWidth);
}

function mouseMove(evt) {
      //alert("Mouse Clicked");
      mouseMoving=true;
      var mousePosition = getMousePosition(canvas, evt);
      //moveNode(x,y,mousePosition.x,mousePosition.y);
      if(selectingNode && selectedNode && mouseClicked && editable){
      	//console.log('Mouse Moving');
      	//console.log(mousePosition);
      	//eraseNode(selectedNode);
		selectedNode.x = mousePosition.x;
		selectedNode.y = mousePosition.y;

		//drawNode(selectedNode.x, selectedNode.y, selectedNode.radius);
		//drawNode(selectedNode);
		clearCanvas();
      }
      //updateEditor();
      $("#selectedNodeName").attr("value", selectedNode.description);
}

function mouseUp(e){
	mouseClicked = false;
	//selectedNode = null;
	selectingNode = false;
	var mousePosition = getMousePosition(canvas, e);
	var node = nodePresentAt(mousePosition.x, mousePosition.y);
	if(node && !mouseMoving){
		if(node.showChildren == true){
			node.showChildren = false;
			for(var index in node.children){
				node.children[index].show=false;
				node.children[index].showChildren = false;
			}
			hideGrandChildren();
		}
		else{
			node.showChildren = true;
			for(var index in node.children)
				node.children[index].show=true;
			hideGrandChildren();
		}
	}
	clearCanvas();
	
	selectedNode.show = true;
}

function mouseDown(e){
	mouseMoving = false;
	mouseClicked = true;
	//selectingNode = true;
	var mousePosition = getMousePosition(canvas, e);
	if(1){
	//if(selectingNode){
		//alert('Selecting Node');
		var node = nodePresentAt(mousePosition.x, mousePosition.y);
      	if(node && node.show ){
      		selectedNode = nodePresentAt(mousePosition.x, mousePosition.y);
      		//selectedNode.show = true;
      		//console.log("Node Selected" + selectedNode);
      		selectingNode = true;
      		document.getElementById('selectedNodeName').value = selectedNode.description;
      		$("#data").empty();
      		$("#data").append(selectedNode.text);
      		hideGrandChildren();
      		
			updateEditor();
      	}
      }
      clearCanvas();

}

function selectNode(){
	selectingNode = true;
	selectedNode = null;
	//alert("Selecting Requested");
}

function getMousePosition(canvas, evt) {
    var rect = canvas.getBoundingClientRect();
    return {
          x: (evt.clientX-rect.left)/(rect.right-rect.left),
          y: (evt.clientY-rect.top)/(rect.bottom-rect.top)
    };
}

function clearCanvas() {
	//canvas.width = canvas.width;
	//alert(1);
    context.clearRect(0,0, canvas.width,canvas.height);
    //alert(2);
    drawTree(root);
}

function add() {
	if(editable){
		var r1 = 0.8*Math.random();
		var r2 = 0.8*Math.random();
		var r3 = Math.random();
		var r4 = Math.random();
		if(r3<0.5)
			r1 *= -1;
		if(r4<0.5)
			r2 *= -1;
		 x=(selectedNode.x + 10*r1*nodeRadius)>1 || (selectedNode.x + 10*r1*nodeRadius)<0 ? (selectedNode.x - 10*r1*nodeRadius) : (selectedNode.x + 10*r1*nodeRadius);
		 y=(selectedNode.y + 10*r2*nodeRadius)>1 || (selectedNode.y + 10*r2*nodeRadius)<0 ? (selectedNode.y - 10*r2*nodeRadius) : (selectedNode.y + 10*r2*nodeRadius);
		//x=r1;
		//y=r2;
		//nodeNumber++;
        var node = new Node(x,y,nodeRadius, selectedNode);
        getId(node);
        console.log('Node Added');
        console.log(node);
        //node.nodeNumber = nodeNumber;
        selectedNode.addChild(node);
        selectedNode.showChildren = true;
        for(var index in selectedNode.children){
        	selectedNode.children[index].show=true;
        }
        clearCanvas();
        allNodes.push(node);
	}
}

function deleteNode(){
	if(editable){
		//alert(1);
		var response = confirm("Deleting an element will also delete all the child elments. Do you want to proceed ?");
		//alert(response);
		if(response){
			if(selectedNode == root){
				alert("You can not delete the main Element");
			}
			else
			{				
				//Get all the ids of child elements
				deletingIds = new Array();
				var temp = selectedNode;
				getAllChildIds(temp);

				$.post("/concepts/delete_elements", {ids: deletingIds}, function(data, status, xhr){
					if(status=="success"){
						var parent = selectedNode.parent;
						var index = parent.children.indexOf(selectedNode);
						parent.children.splice(index,1);
						index = allNodes.indexOf(selectedNode);
						allNodes.splice(index,1);
						clearCanvas();
					}else{
						alert('Some Thing went wrong! Try deleting the element again');
					}
				}, "json");
			}
		}
	}
}

function getAllChildIds(node){
	deletingIds.push(node.id);
	for(var index in node.children){
		getAllChildIds(node.children[index]);
	}
}


function drawNode(node){
	context.fillStyle = node.color;
	if(node==selectedNode){
		context.fillStyle = "#0530c2";
		context.beginPath();
		context.arc(node.x* canvas.width, node.y* canvas.height, (node.radius+0.008) * canvas.width, 0, 2*Math.PI, true);
		context.fill();
		context.fillStyle= "black";
		context.font = 'italic ' + canvas.width*0.008+ 'pt Calibri';
		context.textAlign = "center";
	    context.fillText(node.description, node.x*canvas.width, node.y*canvas.height);
	}
	else if(node.parent == selectedNode){
		context.fillStyle = "#054de0";
		context.beginPath();
		context.arc(node.x* canvas.width, node.y* canvas.height, node.radius * canvas.width, 0, 2*Math.PI, true);
		context.fill();
		context.fillStyle= "black";
		context.font = 'italic ' + canvas.width*0.008+ 'pt Calibri';
		context.textAlign = "center";
	    context.fillText(node.description, node.x*canvas.width, node.y*canvas.height);
	}
	else{
		context.fillStyle = "#05a1fb";
		context.beginPath();
		context.arc(node.x* canvas.width, node.y* canvas.height, node.radius * canvas.width, 0, 2*Math.PI, true);
		context.fill();
		context.fillStyle= "black";
		context.font = 'italic ' + canvas.width*0.008+ 'pt Calibri';
		context.textAlign = "center";
	    context.fillText(node.description, node.x*canvas.width, node.y*canvas.height);
	}
	if(node.showChildren && node.children.length>0){
		context.fillText("-", node.x*canvas.width, (node.y+node.radius/1.25)*canvas.height);
	}
	else if(node.children.length>0){
		context.fillText("+", node.x*canvas.width, (node.y+node.radius/1.2)*canvas.height);
	}
	//wrapText(context, node.text, node.x, node.y, 2*node.radius, 2*node.radius);
}

function eraseNode(node){
	//console.log('r= ' + node.radius + ' x= '+ node.x + ' y= ' + node.y);
	context.fillStyle = "RGB(255, 255, 255)";
	context.beginPath();
	context.arc(node.x, node.y, node.radius+0.1, 0, 2*Math.PI, true);
	context.fill();
}

function connectNodes(node1, node2){
	
	context.strokeStyle = "#05d6fb";
	if(node1==selectedNode)
		context.lineWidth = 10;
	else
		context.lineWidth = 5;
	var capWidth = context.lineWidth/2;
	context.beginPath();
	context.moveTo(node1.x*canvas.width, node1.y*canvas.height);
	context.lineTo(node2.x*canvas.width, node2.y*canvas.height);
	context.stroke();

	//Drawing an arrow
	var a = Math.atan2((node2.y-node1.y), (node2.x-node1.x));
	var b1 = Math.PI+a - Math.PI/4;
	var b2 = Math.PI+ a + Math.PI/4;
	var l = 0.02;
	var midPoint = { x : (node1.x+node2.x)/2, y: (node1.y+node2.y)/2};
	var B1 = {x: l*Math.cos(b1)+midPoint.x, y: l*Math.sin(b1)+midPoint.y };
	var B2 = {x: l*Math.cos(b2)+midPoint.x, y: l*Math.sin(b2)+midPoint.y };

	context.beginPath();
	context.moveTo(midPoint.x*canvas.width, midPoint.y*canvas.height);
	context.lineTo(B1.x*canvas.width, B1.y*canvas.height);
	context.stroke();

	context.beginPath();
	context.moveTo(midPoint.x*canvas.width, midPoint.y*canvas.height);
	context.lineTo(B2.x*canvas.width, B2.y*canvas.height);
	context.stroke();

	console.log("*****ARROWS******");
	console.log(midPoint);
	console.log(B1);
	console.log(B2);
}

function nodePresentAt(x, y){
	console.log("Checking Node Presence");
	console.log(allNodes);
	console.log("Mouse Position "+x + "  " +y);
	for(node in allNodes){
		console.log("node is ");
		console.log(node);
		var xdistance = Math.pow(x - allNodes[node].x, 2);
		var ydistance = Math.pow(y - allNodes[node].y, 2);
		var distance = Math.sqrt(xdistance + ydistance);
		console.log("distance is "+distance);
		if(distance<allNodes[node].radius){
			console.log("Node Presence Found");
			return allNodes[node];
		}
	}
	return false;
}

//Node Class
function Node(x,y,r,parent){
	this.x=x;
	this.y=y;
	this.radius=r;
	this.parent=parent;
	this.show = true;
	this.showChildren = false;
	this.color = "red";
	this.description = "Element";
	this.children = new Array();
	this.text = "";
	//this.nodeNumber = nodeNumber;
	this.addChild = function(node){
		this.children.push(node);
	}
}

function drawTree(root){
	if(root && root.show){
		//alert(node_no++);
		//drawNode(root);
		if(root.showChildren){
			for(node in root.children){
				if(root.children[node].show){
					connectNodes(root, root.children[node]);
					drawTree(root.children[node]);
				}
			}
		}
		drawNode(root);
	}
}

function hideTree(root){
	if(root){
		root.show = false;
		for(node in root.children){
			hideTree(root.children[node]);
		}
	}
}

function showCompleteTree(root){
	if(root){
		root.show = true;
		root.showChildren=true;
		for(var index in root.children){
			showCompleteTree(root.children[index]);
		}
	}
}

function drawCompleteTree(){
	showCompleteTree(root);
	drawTree(root);
}

function hideGrandChildren(){

     for(var node1 in selectedNode.children){
		selectedNode.children[node1].show = true;
		//console.log("Selected Node is "+selectedNode);
		//console.log(selectedNode);
		var temp = selectedNode.children[node1];
		//console.log('temp is' );
		//console.log(temp);
		for(var node2 in temp.children){
			console.log("Hiding Nodes");
			console.log(temp.children[node2]);

			hideTree(temp.children[node2]);
		}
		clearCanvas();
	}

	//Hiding SelectedNode siblings Children
	var parent = selectedNode.parent;
	if(parent){
		for(var node1 in parent.children){
			if(parent.children[node1] != selectedNode){
				var temp = parent.children[node1];
				for(var node2 in temp.children){
					hideTree(temp.children[node2]);
				}
				clearCanvas();
			}
		}
	}
}

function updateNodeData(){
	
	if(editable){
		updateNodeName();
		var data = tinyMCE.get('content').getContent();
		data1 = data;
		selectedNode.text = data;
	}
}

function updateEditor(){
	console.log(selectedNode.text);
	
	//tinyMCE.activeEditor.setContent('');
	if(editable)
		tinyMCE.get('content').setContent(selectedNode.text);
    //tinyMCE.execCommand('mceReplaceContent',false,selectedNode.text);
	//document.getElementById('tinymceEditor').innerHTML = selectedNode.text;
}

function showContent(){
	updateEditor();
	console.log("JSON DATA");
	console.log(root);
}

function updateNodeName(){
	var newName = document.getElementById("selectedNodeName").value;
	//alert(newName);
	console.log('Name in textBox is '+newName);
	selectedNode.description = newName;
	clearCanvas();
}

function preview() {
	if(editable){
		editable = false;
		changeEditorMode();
		selectedNode = root;
		$("#editor").hide();
		$("#selectedNodeName").prop("disabled", true);
		$("#showingData").attr("hidden", false);
		$("#data").empty();
		$("#data").append(selectedNode.text);
		$("#preview").text("Edit");

		//Disbling Buttons
		$("#delete").hide();
		$('#delete').prop('disabled', true);
		$("#AddChild").hide();
		$('#AddChild').prop('disabled', true);
		$("#reload").hide();
		$('#reload').prop('disabled', true);


		hideGrandChildren();
	}
	else{
		editable = true;
		
		$("#showingData").attr("hidden", true);
		$('#data').empty();
		$("#editor").show();
		changeEditorMode();
		$("#preview").text("Preview");
		$("#selectedNodeName").prop("disabled", false);

		$("#delete").show();
		$('#delete').prop('disabled', false);
		$("#AddChild").show();
		$('#AddChild').prop('disabled', false);
		$("#reload").show();
		$('#reload').prop('disabled', false);
	}
	console.log("In previewMode");
}

function changeEditorMode() { 
        // if(!editable) { 
        //     tinyMCE.removeMCEControl(tinyMCE.getEditorId('content')); 
        // } else { 
        //     tinyMCE.addMCEControl(document.getElementById('content'), 'content'); 
        // } 
        if(!editable)
        	tinyMCE.execCommand( 'mceRemoveControl', false, 'content' );
        else{
        	console.log("Adding tinymce Editor");
        	tinyMCE.execCommand( 'mceAddControl', false, 'content');
        }
}