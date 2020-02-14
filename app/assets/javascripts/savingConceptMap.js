$(document).ready(function(){
	
	//alert("Document Ready");
	shiftPressed=false;
	$("#exit").click(function(){
			var response = confirm("Do you want to exit?");
			if(response){
				saveConceptMap();
				window.location.href = "/concepts";
			}
			
	});
	//SaveMap when exiting from page
	$(window).on('beforeunload', function(){
		saveConceptMap();
	});
	//When Canvas lost focus
	$("#canvas_1").on('mouseout', function(){
		//alert("Lost Focus");
		mouseClicked = false;
	});
	// $('#selectedNodeName').on("input paste",function(e) {
	// 	if(!shiftPressed){
	// 		alert("Use ctrl+shift+v");
	// 		e.preventDefault();
	// 		e.stopPropagation();
	// 		return false;
	// 	}
	// 	  //alert('Binding');
 //          //e.preventDefault();
 //      });
	// $("#selectedNodeName").on('keydown', function(event){
	// 	if(event.shiftKey)
	// 		shiftPressed=true;

	// });
	// $("#selectedNodeName").on("keyup", function(event){
	// 	if(event.shiftKey)
	// 		shiftPressed=false;
	// });
});

function Element(x,y,r,id, description){
	this.x = x;
	this.y = y;
	this.r = r;
	this.name = description;
	this.id = id;
	this.text = "";
	this.concept_id = concept_id;
}

function restructure(root){
	console.log("restructuring");
	if(root){
		var element = new Element(root.x, root.y, root.radius, root.id, root.description, root.text);
		if(root.parent)
			element.parent = root.parent.id;
		else
			element.parent = -1;
		element.text = root.text;
		console.log(element);
		elements.push(element);
		for(var index in root.children){
			restructure(root.children[index]);
		}
	}
}

function saveConceptMap(){
	elements = new Array();
	restructure(root);
	
	for(var index in elements){
		console.log("Element is");
		console.log(elements[index]);
		$.post("/concepts/save_element", elements[index], function(data, status, xhr){
			// if(index == elements.length-1 && status=='success'){
			// 	window.location.href = "/concepts";
			// }
		}, "json");
	}
}