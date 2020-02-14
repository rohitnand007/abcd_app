
"use strict";
// add onload event listener
// if (window.addEventListener) {
//     window.addEventListener('load', conceptmap_init, false);
// }
// else if (window.attachEvent) {
//     window.attachEvent('onload', conceptmap_init);
// }
/*Variable declarations and initializations*/
var main_storage = new Array(), allchilds = new Array(), divColors = new Array(), cnvs = new Array(), ctx = new Array();
var nodeStore = new Array();
var childStore = new Array();
var anim_layer = new Array();
var anim_ctx = new Array();
var el_ce_an_store = new Array();
var Element_positions = new Array();
var el_position = new Array();
var new_el_pos = new Array();
var default_pos = new Array();
var dcindex=0,nodeState=0, xmlhttp, x, i, main_element, childs, node, id, parent_id, element_name, detail;
var arrow_layer, arrow_ctx, anim_layer, anim_ctx, anim_load = 0, line_length=90, select_anim_load=0;
var infoDisplay, showSelection, initial=0, styles, zoom=1, angle_state=0, zoomclick=0, depth=0;
var zoom_anim, zoom_load, click=0, click_anim=0, big_radius=45, small_radius=14,myscroll, done=0, detector=0;
/*temp vars*/ var anlgle_init_pos = new Array();
var angle_end_pos = new Array();
var scolor = "rgb(180,180,180)",bcolor = "rgb(40,176,242)",linecolor = "rgb(13,148,213)";
var diagonal = Math.round(Math.sqrt(2)*big_radius*2)+1;
var static_diag=diagonal;
var conceptmapLocation = "";

var selected_node;
// header initialization
function conceptmap_init()
{

    /*getObj("previewconceptmap_button").setAttribute("class","preview");

    getObj("createconceptmap_button").style.display="none";//setAttribute("class","newConcept");
    getObj("create_arrow").style.display="none";//setAttribute("class","polygon-right");

    getObj("submit_button").setAttribute("class","submitCM");

    getObj("editconceptmap_button").setAttribute("class","conceptMap selected");
    getObj("edit_arrow").setAttribute("class","polygon-right-selected");

    getObj("preview_arrow").setAttribute("class","polygon-right");
    getObj("submit_arrow").setAttribute("class","polygon-right");
    getObj("boxBody").style.display ="none";

    getObj("conceptmap").style.visibility ="visible";
    //getObj("conceptmap").style.display ="";
      */
    window.setTimeout(function(){
        try{
            if(!document.getElementById("aside")){
                return;
            }
        }catch(er){
            return;
        }
        try{

            url = window.location.href+".xml";
            invocation.open('GET', url, true);
            invocation.onreadystatechange = handler;
            invocation.send();


        }catch(er){
            alert('load er'+er)
        }


    },1);
}
var invocation = new XMLHttpRequest();
var url ,len;
var concept_name,board_id,content_year_id,subject_id,topic_id,chapter_id,sub_topic_id,conceptmap_id;
function handler(evtXHR){
    if (invocation.readyState == 4)
    {
        if (invocation.status == 200)
        {

            try{
                len =0;
                var _obj = invocation.responseText;
                try{
                    var xml_node = _obj.replace(/xml version=&quot;1.0&quot; encoding=&quot;UTF-8&quot;/g,"");

                    var temp = xml_node.split("&lt;??&gt;");
                    var elements = temp[1].replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&quot;/g,'"');
                    var nodes = temp[2].replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&quot;/g,'"');;

                    var xml_data1 = new DOMParser().parseFromString(elements,"text/xml");
                    try{
                        concept_name = xml_data1.getElementsByTagName("name")[0].firstChild.nodeValue;
                        conceptmap_id = xml_data1.getElementsByTagName("id")[0].firstChild.nodeValue;
                        board_id = xml_data1.getElementsByTagName("board-id")[0].firstChild.nodeValue;
                        content_year_id = xml_data1.getElementsByTagName("content-year-id")[0].firstChild.nodeValue;
                        subject_id = xml_data1.getElementsByTagName("subject-id")[0].firstChild.nodeValue;
                        chapter_id = xml_data1.getElementsByTagName("chapter-id")[0].firstChild.nodeValue;
                        //topic_id = xml_data1.getElementsByTagName("topic-id")[0].firstChild.nodeValue;
                        //sub_topic_id= xml_data1.getElementsByTagName("sub-topic-id")[0].firstChild.nodeValue;
                    }catch(er){
                        alert('xmldata1 er'+er)
                    }
                    var xml_data2 = new DOMParser().parseFromString(nodes,"text/xml");
                    var child_nodes = xml_data2.getElementsByTagName("concept-element");
                    var _minus = child_nodes[0].getElementsByTagName("id")[0].firstChild.nodeValue*1-1;
                    for(var i=0;i<child_nodes.length;i++){
                        var _parentid = null;
                        try{
                            _parentid = child_nodes[i].getElementsByTagName("parent-id")[0].firstChild.nodeValue;
                        }catch(er){
                        }
                        if(_parentid==null || _parentid=="")
                            _parentid = 0;
                        else
                            _parentid = _parentid*1-_minus;
                        var _description = null;

                        try{
                            _description = child_nodes[i].getElementsByTagName("description")[0].firstChild.nodeValue;
                        }catch(er){
                        }
                        if(_description==null)
                            _description="details:";
                        main_storage[i] = [child_nodes[i].getElementsByTagName("name")[0].firstChild.nodeValue,(child_nodes[i].getElementsByTagName("id")[0].firstChild.nodeValue*1-_minus),_parentid,_description];
                        len++;
                    }
                }catch(er){
                    alert('xml_node er'+er);
                }
                window.setTimeout(create_Init_Element,50);
            }catch(er){
                alert('concept_ider'+er);
            }
        }
        else {
          /*  getObj("previewconceptmap_button").setAttribute("class","preview");
            getObj("createconceptmap_button").style.display="";//setAttribute("class","newConcept");
            getObj("create_arrow").style.display="";//setAttribute("class","polygon-right");
            getObj("create_arrow").setAttribute("class","polygon-right-selected");
            getObj("createconceptmap_button").setAttribute("class","newConcept selected");

            getObj("submit_button").setAttribute("class","submitCM");

            getObj("editconceptmap_button").setAttribute("class","conceptMap");
            getObj("edit_arrow").setAttribute("class","polygon-right");

            getObj("preview_arrow").setAttribute("class","polygon-right");
            getObj("submit_arrow").setAttribute("class","polygon-right");
            getObj("boxBody").style.display ="";
            getObj("conceptmap").style.visibility ="hidden";
            */
            main_storage[0] = ["parent","1",'0','detail'];
            window.setTimeout(create_Init_Element,50);
        }
    }
}
function getObj(id)
{
    return document.getElementById(id);
}
function zplus()
{
    if(zoom<=5 && zoomclick==0)
    {
        var brk = 0.1/10;
        var store = zoom;
        zoomclick =1;
        zoom_load = window.setInterval(zoom_anim,35,[zoom,brk,store,0]);
        zoom=zoom+0.1;
        return false;
    }
}
function zoom_anim(data)
{
    getObj('map').style.MozTransform = "scale("+data[0]+")";
    getObj('map').style.WebkitTransform = "scale("+data[0]+")";
    getObj('map').style.Transform = "scale("+data[0]+")";
    if(el_position){
        getObj('map').style.MozTransformOrigin = ""+el_position[0]+" "+el_position[1]+"";
        getObj('map').style.TransformOrigin =  ""+el_position[0]+" "+el_position[1]+"";}
    if(data[3]==0)
    {
        data[0]=data[0]+data[1];
        if(data[2]+0.1<=data[0])
        {
            clearInterval(zoom_load);
            zoomclick=0;
        }
    }
    else
    {
        data[0]=data[0]-data[1];
        if(data[2]-0.1>=data[0])
        {
            clearInterval(zoom_load);
            zoomclick=0;
        }
    }
}
function zminus()
{
    if(zoom>=0.1 && zoomclick==0)
    {
        var brk = 0.1/10;
        var store = zoom;
        zoomclick =1;
        zoom_load = window.setInterval(zoom_anim,35,[zoom,brk,store,1]);
        zoom=zoom-0.1;
        return false;
    }
}
function reset_view()
{
    getObj('map').style.MozTransform = "scale(1)";
    getObj('map').style.WebkitTransform = "scale(1)";
    getObj('map').style.Transform = "scale(1)";
    getObj('map').style.MozTransformOrigin = ""+el_position[0]+" "+el_position[1]+"";
    getObj('map').style.TransformOrigin = ""+el_position[0]+" "+el_position[1]+"";
    window.scroll(default_pos[0],default_pos[1]);
    zoom=1;
    return false;
}

function showBigImage(imgObj) {
    var zoomImage = document.getElementById('zoomimage');
    zoomImage.style.position = 'absolute';
    zoomImage.src = imgObj.src;
    zoomImage.onerror = function () {
        alert('error loading ' + imgObj.src);
    };
    zoomImage.style.position ='fixed';
    zoomImage.style.left = (parseInt(window.innerWidth)-parseInt(zoomImage.offsetWidth))/2+'px';
    if(zoomImage.offsetHeight >= window.innerHeight)
        zoomImage.style.top  = 0+'px';
    else
        zoomImage.style.top  = (parseInt(window.innerHeight)/2-parseInt(zoomImage.offsetHeight)/2)+'px';
    zoomImage.style.zIndex = 35;
    zoomImage.style.visibility = 'visible';
    document.getElementById('zoomimage').style.visibility = 'visible';
}
function updateContent(){
    for(var i=0;i<main_storage.length;i++)
    {
        if(selected_node.id == main_storage[i][1])
        {
            try{
                main_storage[i][0] = getObj("title").value ;
                if(getObj("editbuttons").style.display==""){
                    main_storage[i][3] = tinyMCE.get('content').getContent().replace("\n","<br/>");
                }
                else
                    main_storage[i][3] = getObj('content_label').innerHTML;//tinyMCE.get('content').getContent();
                var contx = getObj(main_storage[i][1]).getContext("2d");
                contx.clearRect(0,0,getObj(main_storage[i][1]).width,getObj(main_storage[i][1]).height);
                //settingContext(contx,small_radius,(getObj(main_storage[i][1]).width/2),(getObj(main_storage[i][1]).height-getObj(main_storage[i][1]).height/8),getText(main_storage[i][0]),scolor);
                settingContext(contx,big_radius,(getObj(main_storage[i][1]).width/2),(getObj(main_storage[i][1]).height-getObj(main_storage[i][1]).height/2),getText(main_storage[i][0]),bcolor);

                //contx.fillText(getObj("title").value, small_radius, ((big_radius*2)+small_radius));
                //contx.fill();
            }catch(er){
                alert("here i'm"+er)
            }
            break;
        }
    }
    //var pos = infoDisplay(selected_node);
}
function editConceptMap(){
//<<<<<<< HEAD
    //New CHANGES
    var data = {};
    data.name = $('#concept_name').val();
    data.board_id = $('#quiry_board option:selected').val();
    data.content_year_id = $('#quiry_class option:selected').val();
    data.subject_id = $('#quiry_subject option:selected').val();
    data.chapter_id = $('#quiry_chapters option:selected').val();
    if(data.board_id==null || data.chapter_id==null || data.chapter_id=="" || data.subject_id==null || data.content_year_id==null ||data.name==null || data.name=="")
        alert("Enter the Mandatary Details");
    else{
        $.post('/concepts/new_concept', data, function(Res, status, xhr){
            if(status=='success'){
                console.log('Data is');
                console.log(Res);
                if(Res['created']==true)
                    window.location = "/concepts/new_concept_map/" + Res['concept_id'];
                else
                    alert('Please Check the enetered details');
            }
        }, 'json');
    }
    
// =======
//     var _temp = getObj("previewconceptmap_button").getAttribute("class");
//     if(_temp!='preview'){
//         getObj("content").style.display ="";
//         tinyMCE.execCommand('mceAddControl', false, 'content' );
//     }
//     var scripts = document.getElementsByTagName('script');
//     var i = scripts.length;
//     while (i--) {
//         if(scripts[i].src.match(/json.js/g))
//             scripts[i].parentNode.removeChild(scripts[i]);
//     }
//     getObj("previewconceptmap_button").setAttribute("class","preview");
//     getObj("createconceptmap_button").setAttribute("class","newConcept");
//     getObj("submit_button").setAttribute("class","submitCM");
//     getObj("editconceptmap_button").setAttribute("class","conceptMap selected");
//     getObj("edit_arrow").setAttribute("class","polygon-right-selected");
//     getObj("create_arrow").setAttribute("class","polygon-right");
//     getObj("preview_arrow").setAttribute("class","polygon-right");
//     getObj("submit_arrow").setAttribute("class","polygon-right");
//     getObj("boxBody").style.display ="none";

//     getObj("conceptmap").style.visibility ="visible";
//     //getObj("conceptmap").style.display ="";
//     try{
//         getObj("title").style.display ="";

//         getObj("label_fields").style.display ="none";
//         //getObj("content_label").style.display ="none";
//     }catch(er){
//         alert('er01'+er)
//     }
//     getObj("editbuttons").style.display ="";

//     window.setTimeout(
// 	function(){
// 	create_Childs(getObj(main_storage[0][1]));
// 	},50);
// >>>>>>> origin
}
function previewConceptMap(){
    var scripts = document.getElementsByTagName('script');
    var i = scripts.length;
    while (i--) {
        if(scripts[i].src.match(/json.js/g))
            scripts[i].parentNode.removeChild(scripts[i]);
    }
    getObj("previewconceptmap_button").setAttribute("class","preview  selected");
    getObj("createconceptmap_button").setAttribute("class","newConcept");
    getObj("editconceptmap_button").setAttribute("class","conceptMap");
    getObj("submit_button").setAttribute("class","submitCM");
    getObj("edit_arrow").setAttribute("class","polygon-right");
    getObj("create_arrow").setAttribute("class","polygon-right");
    getObj("preview_arrow").setAttribute("class","polygon-right-selected");
    getObj("submit_arrow").setAttribute("class","polygon-right");
    getObj("boxBody").style.display ="none";
    updateContent();
    getObj("conceptmap").style.visibility ="visible";
    //getObj("conceptmap").style.display ="";
    getObj("editbuttons").style.display ="none";

    try{

        tinyMCE.execCommand( 'mceRemoveControl', false, 'content' );
        getObj("title").style.display ="none";
        getObj("content").style.display ="none";
        getObj("label_fields").style.display ="";
        //getObj("content_label").style.display ="";
    }catch(er){
        alert('er02'+er)
    }

    window.setTimeout(
	function(){
	create_Childs(getObj(main_storage[0][1]));
	},50);
    //window.setTimeout(create_Init_Element,50);
}
function createConceptMap(){
    getObj("previewconceptmap_button").setAttribute("class","preview");
    getObj("createconceptmap_button").setAttribute("class","newConcept  selected");
    getObj("editconceptmap_button").setAttribute("class","conceptMap");
    getObj("submit_button").setAttribute("class","submitCM");
    getObj("edit_arrow").setAttribute("class","polygon-right");
    getObj("create_arrow").setAttribute("class","polygon-right-selected");
    getObj("preview_arrow").setAttribute("class","polygon-right");
    getObj("submit_arrow").setAttribute("class","polygon-right");
    getObj("boxBody").style.display ="";
    getObj("conceptmap").style.visibility ="hidden";
    //getObj("conceptmap").style.display ="none";
    var scripts = document.getElementsByTagName('script');
    var i = scripts.length;
    while (i--) {
        if(scripts[i].src.match(/json.js/g))
            scripts[i].parentNode.removeChild(scripts[i]);
    }
}

function submitConceptMap(){
    try{
        if(concept_name == null){
            if(getObj('concept_name').value=="" || getObj('concept_name').value==null)
            {
                alert("please enter concept map title...");
                return;
            }
            else if(getObj('quiry_board').value=="" || getObj('quiry_board').value==null){
                alert("please select board...");
                return;
            }
            else if(getObj('quiry_class').value=="" || getObj('quiry_class').value==null){
                alert("please select class...");
                return;
            }
            else if(getObj('quiry_subject').value=="" || getObj('quiry_subject').value==null){
                alert("please select subject...");
                return;
            }
            else if(getObj('quiry_chapters').value=="" || getObj('quiry_board').value==null){
                alert("please select chapter...");
                return;
            }

            concept_name = getObj('concept_name').value;
            board_id = getObj('quiry_board').value;
            content_year_id = getObj('quiry_class').value;
            subject_id = getObj('quiry_subject').value;
            chapter_id = getObj('quiry_chapters').value;
            conceptmap_id = null;
        }
        getObj("previewconceptmap_button").setAttribute("class","preview");
        getObj("createconceptmap_button").setAttribute("class","newConcept");
        getObj("editconceptmap_button").setAttribute("class","conceptMap");
        getObj("submit_button").setAttribute("class","submitCM selected");
        getObj("edit_arrow").setAttribute("class","polygon-right");
        getObj("create_arrow").setAttribute("class","polygon-right");
        getObj("submit_arrow").setAttribute("class","polygon-right-selected");
        getObj("preview_arrow").setAttribute("class","polygon-right");
        getObj("boxBody").style.display ="none";

        getObj("conceptmap").style.visibility ="hidden";
        //getObj("conceptmap").style.display ="none";
	var node_data = getChilds("0");
    }catch(er){

        alert('1 er'+er)
    }
    try{


        window.setTimeout(function(){

            var myJSONtext = '{"conceptmap_name": "'+concept_name+'","conceptmap_id": "'+conceptmap_id+'","board_id": "'+board_id+'","class_id": "'+content_year_id+'","subject_id": "'+subject_id+'","chpater_id": "'+chapter_id+'","cmap": '+node_data+'}';

            //       var myObject = eval('(' + myJSONtext + ')');
            // construct an HTTP request
            var xhr = new XMLHttpRequest();
            xhr.open("post", "/concept_create.json", true);
            xhr.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
            // send the collected data as JSON
            xhr.send(myJSONtext);

            xhr.onloadend = function () {
                if (xhr.responseText == "200"){
                    window.location="/concepts";
                }
                else{
                    //alert(404);
                }
            };
        },5)
    }catch(er){
        alert("here err"+er)
    }
}
function getChilds(_obj){
    var _temp="{";
    for(var i=0;i<main_storage.length;i++)
    {
        if(main_storage[i][2]==_obj){
		var _details = main_storage[i][3].replace(/"/g,'\'').replace(/\n/g,'');
	//alert(_details);
            _temp+= '"id":"'+main_storage[i][1]+'", "parent_id":"'+main_storage[i][2]+'", "name":"'+main_storage[i][0]+'","detail":"'+_details+'","childs":';
            //if(checkChilds(main_storage[i][1])=="true")
            var _data = getChilds(main_storage[i][1])
            //if(_data!="")
            _temp += '['+_data+']},{';

        }
    }
    _temp += '}';
    //alert(_temp.substr(_temp.length-2,_temp.length))
    if(_temp.substr(_temp.length-2,_temp.length)=="{}")
        return _temp.substr(0,_temp.length-3)
    else
        return _temp

}
function loadTinyMCE() {
    getObj('textarea').tinymce({
        script_url : '../js/tinymce/tiny_mce.js'
    });
}

function destoryTinyMCE() {
    getObj('textarea').tinymce().destroy();
}
function create_Init_Element()
{
    try{
        var top = Math.floor((window.innerHeight+window.outerHeight*2)/2);
        var left = Math.floor((window.innerWidth+window.outerWidth*2)/2);
        main_element = document.createElement("canvas");
        settingsApply(main_element,0,0,0);
        ctx = getObj(main_storage[0][1]).getContext("2d");
        settingContext(ctx,small_radius,(main_element.width/2),(main_element.height-main_element.height/8),getText(main_storage[0][0]),scolor)
        attach_createchild_Event(getObj(main_storage[0][1]));
        getObj(main_storage[0][1]).style.position = "absolute";
        getObj(main_storage[0][1]).style.left = left+"px";
        getObj(main_storage[0][1]).style.top = top+"px";
        window.scroll((left-(window.innerWidth/3)+(big_radius*2)),(top-(window.innerHeight/3)));
        default_pos = [(left-(window.innerWidth/3)+(big_radius*2)),(top-(window.innerHeight/3))];
        getObj('zoomerplus').addEventListener('click', zplus, true);
        getObj('zoomerminus').addEventListener('click', zminus, true);
        getObj('normal_view').addEventListener('click', reset_view, true);
        var temp_nod = getText(main_storage[0][0]);
	var details_data = main_storage[0][3].toString().trim();
	details_data = details_data.replace(/&amp;lt;/g,"<").replace(/&amp;gt;/g,">")
	details_data = details_data.replace(/&lt;/g,"<").replace(/&gt;/g,">")
	details_data = details_data.replace(/&amp;nbsp;/g,"").replace(/&amp;amp;nbsp;/g,"");
	//_obj.innerHTML = main_storage[0][3];
        getObj("title_label").innerHTML = temp_nod;//main_storage[0][3];
        	getObj("title").value = temp_nod;//main_storage[0][0];
        if(getObj("editbuttons").style.display==""){
                 
            tinyMCE.execCommand('mceReplaceContent',false,details_data);//'Please click on '+temp_nod+' to modify/add Data.'
        }else{
		getObj("content_label").innerHTML = details_data;//"";
		//getObj("content_label").appendChild(_obj);//"Please click on "+temp_nod+" to know more about it.";
        }
        //below lines for line drawing layer
        arrow_layer = document.createElement("canvas");
        //arrow_layer.setAttribute("height",(getObj("map").offsetHeight));
        //arrow_layer.setAttribute("width",(getObj("map").offsetWidth));
        arrow_layer.setAttribute("id","arrow");
        getObj("map").appendChild(arrow_layer);
        arrow_layer.setAttribute("class","map_2nd_layer");
        getObj("arrow").style.border = "none";
        arrow_ctx = arrow_layer.getContext("2d");
        //arrow_layer.style.position = "absolute";
        //arrow_layer.style.left = 0+"px";
        //arrow_layer.style.top = 0+"px";
        getObj("s").setAttribute("height", (getObj("map").offsetHeight));
        getObj("s").setAttribute("width", (getObj("map").offsetWidth));
        //animation layer setup and animation context setup layer: anim_layer, ctx: anim_ctx
        anim_layer = document.createElement("canvas");
        anim_layer.setAttribute("height",(getObj("map").offsetHeight));
        anim_layer.setAttribute("width",(getObj("map").offsetWidth));
        anim_layer.setAttribute("id","animation");
        getObj("map").appendChild(anim_layer);
        anim_layer.setAttribute("class","map_3rd_layer");
        anim_ctx = anim_layer.getContext("2d");
        //anim_layer.style.position = "absolute";
        //anim_layer.style.left = 0+"px";
        //anim_layer.style.top = 0+"px";
        //myScroll = new iScroll('aside');
    }catch(er){
        alert('****er'+er);
    }
}

function create_Childs(e)
{
    try{
        getObj("Body").appendChild(getObj("map"));
	
	if(e.target && e.target.id){
            node = e.target;
	}        
	else
            node = e;

        if(selected_node && selected_node.id && selected_node.id == node.id)
            return;
        if(selected_node && getObj("editbuttons").style.display=="")
            updateContent();
        selected_node = node;
        if(click==0 && click_anim==0)
        {
            click=1;
            click_anim=1;
            document.getElementById('zoomimage').src ='';
            document.getElementById('zoomimage').style.visibility='hidden';
            window.scroll((node.offsetLeft-(window.innerWidth/3)+(big_radius*2)),(node.offsetTop-(window.innerHeight/3)));
            el_position = [(node.offsetLeft-(window.innerWidth/3)+(big_radius*2)),(node.offsetTop-(window.innerHeight/3))];

            var pos = infoDisplay(node)
            if(!node.nodeState)
            {
                //allchilds = getAllChilds(node);
                //showAllChilds(allchilds, node);
                showSelection(node,pos,1);
                click_anim =0;
            }
            else
            {
                showSelection(node,pos,1);
                click_anim=0;
            }

            addNode(node)
		if(e.target && e.target.id){
		    e.preventDefault();
		    e.stopPropagation();
		}
        }
    }catch(er){
        alert('errr1'+er)
    }
}
function showSelection(_node,pos,state)
{
    try{
        var new_ctx = selected_node.getContext("2d");

        var temp_Radius = small_radius;
        select_anim_load = 0;
        select_anim_load = window.setInterval(selected_Animation,1,[selected_node,new_ctx,pos,temp_Radius]);
        var allchilds = getAllChilds(selected_node);
        childStore = allchilds.slice();//copying array into another array
        if(initial==0 || nodeStore[0].id==selected_node.id)//if the same node clicked again then will not draw again.
        {
            nodeStore = [selected_node,pos,childStore];
            initial =1;
        }
        else
        {
            //var _pos = infoDisplay(nodeStore[0]);
            //infoDisplay(nodeStore[0]);
            nodeStore[2] = getAllChilds(nodeStore[0]).slice();
            for(i=0;i<nodeStore[2].length;i++)
            {
                var childs = nodeStore[2];
                var p = childs[i];
                var id = main_storage[p][1];
                if((main_storage[p][1])!=selected_node.id && getObj(main_storage[p][1])){
                    var ctx = getObj(main_storage[p][1]).getContext("2d");
                    ctx.clearRect(0,0,getObj(main_storage[p][1]).width,getObj(main_storage[p][1]).height);
                    settingContext(ctx,small_radius,(getObj(main_storage[p][1]).width/2),(getObj(main_storage[p][1]).height-getObj(main_storage[p][1]).height/8),getText(main_storage[p][0]),scolor);
                }
            }
            try{
                var old_ctx = nodeStore[0].getContext("2d");
                old_ctx.clearRect(0,0,nodeStore[0].width,nodeStore[0].height);
                settingContext(old_ctx,small_radius,(nodeStore[0].width/2),(nodeStore[0].height-nodeStore[0].height/8),getText(main_storage[nodeStore[1]][0]),scolor);
                nodeStore = [selected_node,pos,childStore];

                if(selected_node.nodeState)
                {
                    for(i=0;i<nodeStore[2].length;i++)
                    {
                        var childs = nodeStore[2];
                        var p = childs[i];
                        var id = main_storage[p][1];
                        if((main_storage[p][1])!=selected_node.id && getObj(main_storage[p][1])){

                            //alert(selected_node.id+"**p"+p+"**"+main_storage[p][1]);
                            var ctx = getObj(main_storage[p][1]).getContext("2d");
                            ctx.clearRect(0,0,getObj(main_storage[p][1]).width,getObj(main_storage[p][1]).height);
                            settingContext(ctx,small_radius,(getObj(main_storage[p][1]).width/2),(getObj(main_storage[p][1]).height-getObj(main_storage[p][1]).height/8),getText(main_storage[p][0]),bcolor);
                        }
                    }
                }
            }catch(er){
                alert('er7'+er);
            }
        }
        selected_node.nodeState = 1;
    }catch(er){
        alert('er3'+er)
    }
}
function selected_Animation(data)
{try{
    var _node = data[0];
    var new_ctx = data[1];
    var pos = data[2];
    new_ctx.clearRect(0,0,_node.width,_node.height);
    settingContext(new_ctx,data[3],(_node.width/2),(_node.height/2),getText(main_storage[pos][0]),bcolor);
    if(data[3]>=big_radius)
    {
        data[3] = big_radius;
        window.clearInterval(select_anim_load);
        click=0;
    }
    if(data[3]+2<big_radius)
        data[3] =data[3]+2;
    else
        data[3]++;
}catch(er){
	alert('selected animation err'+er);
	}
}
function create(htmlstr){
try{
	var frag = document.createDocumentFragment();
	var temp = document.createElement('div');
	temp.innerHTML = htmlstr;
	while(temp.hasChildNodes && temp.childNodes[0] && temp.childNodes[0].textContent){
	var temp_obj = document.createElement('div');
		alert(temp.childNodes[0].textContent);
		temp_obj.innerHTML = temp.childNodes[0].textContent;
		frag.appendChild(temp_obj);
		temp.removeChild(temp.childNodes[0]);
	}
	return frag;
	}catch(er){
	alert('create er'+er);
	}
}
function infoDisplay(_node)
{
try{
    for(i=0;i<main_storage.length;i++)
    {
        if(_node.id == main_storage[i][1])
        {
            try{
	var details_data = main_storage[i][3].toString().trim();
	details_data = details_data.replace(/&amp;lt;/g,"<").replace(/&amp;gt;/g,">")
	details_data = details_data.replace(/&lt;/g,"<").replace(/&gt;/g,">")
	details_data = details_data.replace(/&amp;nbsp;/g,"").replace(/&amp;amp;nbsp;/g,"");
//	alert(details_data);
//var _obj = create(details_data);
	//document.body.insertBefore(_obj,getObj("content_label"))
getObj("title_label").innerHTML = main_storage[i][0];

   	getObj("title").value = main_storage[i][0];
                if(getObj("editbuttons").style.display==""){
                    tinyMCE.activeEditor.setContent('');
                    tinyMCE.execCommand('mceReplaceContent',false,details_data);
                }
		else{
			getObj("content_label").innerHTML = details_data;
			//getObj("content_label").appendChild(_obj);
            	}                
                setTimeout(resizeImage,10);
        }catch(er){
        	alert('info display er:'+er)
    	}
            return i;
        }
    }
}catch(er){
	alert('info display err'+er);
	}
}
function deleteNode(_node){
    if(_node=="null" && selected_node.id!="1"){
        _node = selected_node;
        for(var i=0; i<main_storage.length;){
            if(main_storage[i][1]==selected_node.id){
                main_storage.splice(i, 1);
                //len--;
            }
            else if(main_storage[i][2]==selected_node.id){
                var temp1_nodeid = main_storage[i][1];
                main_storage.splice(i, 1);
                for(var j=0; j<main_storage.length;){
                    if(main_storage[j][2]==temp1_nodeid){
                        var temp2_nodeid = main_storage[j][1];
                        main_storage.splice(j, 1);
                        for(var k=0; k<main_storage.length;){
                            if(main_storage[k][2]==temp2_nodeid)
                                main_storage.splice(k, 1);
                            else
                                k++;
                        }
                    }
                    else
                        j++;
                }
                //len--;
            }
            else
                i++
        }
        getObj(selected_node.title+"_childs").removeChild(getObj(selected_node.id));
        if(getObj(selected_node.id+"_arrows"))
            getObj(selected_node.title+"_arrows").removeChild(getObj(selected_node.id+"_arrows"));
        if(getObj(selected_node.id+"_lines"))
            getObj(selected_node.title+"_lines").removeChild(getObj(selected_node.id+"_lines"));
        if(getObj(selected_node.id+"_childs"))
            getObj(selected_node.title+"_childs").removeChild(getObj(selected_node.id+"_childs"));
        selected_node = getObj(selected_node.title)
        if(selected_node.id=="1"){
            getObj("s").removeChild(getObj(selected_node.id+"_arrows"))
            getObj("s").removeChild(getObj(selected_node.id+"_lines"))
        }
        else{

            if(getObj(selected_node.id+"_arrows"))
                getObj(selected_node.title+"_arrows").removeChild(getObj(selected_node.id+"_arrows"));
            if(getObj(selected_node.id+"_lines"))
                getObj(selected_node.title+"_lines").removeChild(getObj(selected_node.id+"_lines"));
        }
        var pos = infoDisplay(selected_node)
        showSelection(selected_node,pos,1);
        allchilds = getAllChilds(selected_node);
        showAllChilds(allchilds, selected_node);

        //line_"+selected_node.id+


    }
}
function playAnimation(filepath){
    try{
        getObj("mask").style.display="";
        getObj("mask-data").style.display = "";
        var _poster = filepath.substr(0,filepath.length-4);
        getObj("mask-data").innerHTML='<video id="content_videoid" poster="'+_poster+'.jpg" style="height:100%;width:100%;position:fixed;z-index:1000" controls="controls" preload="auto">'+
            '<source src="'+filepath+'" type="video/mp4" /></video><image src="src/images/close.png" style="z-index:1011;right:5em;width:5%; height:auto;position:fixed;" onclick="javascript:getObj(\'mask-data\').style.display=\'none\';javascript:getObj(\'mask\').style.display=\'none\';"/>';
        window.setTimeout(function(){
            getObj("content_videoid").play();
        },100);
    }catch(er){
        alert("vide***"+er);
    }
}

function closeVideo(){
    getObj('mask-data').style.display='none';
    getObj('mask').style.display='none';

}
var len = 1;
function addNode(_node){

    if(_node=="null"){
        _node = selected_node;
	if(getObj("editbuttons").style.display=="")        	
        	updateContent();
        var pos = infoDisplay(selected_node);
        var _details = '';
        main_storage[main_storage.length] = ["child"+(len+1),(len+1)+"",_node.id,'details'];
        len++;
    }

    allchilds = getAllChilds(_node);
    if(allchilds.length>1 && getObj(selected_node.id+"_arrows") && getObj(selected_node.id+"_lines")){
        try{
            if(selected_node.id=="1"){
                getObj("s").removeChild(getObj(selected_node.id+"_arrows"))
                getObj("s").removeChild(getObj(selected_node.id+"_lines"))
            }
            else{
                getObj(selected_node.title+"_arrows").removeChild(getObj(selected_node.id+"_arrows"));
                getObj(selected_node.title+"_lines").removeChild(getObj(selected_node.id+"_lines"));
            }
        }catch(er){
            alert('remove line&arrows er:'+er)
        }
    }
    showAllChilds(allchilds, _node);

}

function getParent(node)
{
try{
    for(var i=0;i<main_storage.length;i++)
    {
        if(node.id == main_storage[i][1])
        {
            var parent = getObj(main_storage[i][2]);
            return parent;
        }
    }
}catch(er){
	alert('getparent err'+er);
	}
}
function getParentId(node)
{
try{
    for(var i=0;i<main_storage.length;i++)
    {
        if(node.id == main_storage[i][1])
        {
            return main_storage[i][2];
        }
    }
}catch(er){
	alert('getparentid err'+er);
	}
}
function placingNodes(ncleft,nctop,node,required_len,degrees,angle,r)
{
try{
    if(node.id==1)
    {
        node.depth = node.id;
    }
    else
    {
        var parent = getParent(node);
        node.depth = parseInt(parent.depth)+1;
    }
    Element_positions.length = 0;
    new_el_pos.length =0;
    var j=0;
    var len = document.querySelectorAll('.canvas_map').length;
    if(node.id==1)
    {
        var step = (degrees*Math.PI)/required_len;
        var origin_angle = angle;
    }
    else
    {
        var angle_toreduce = node.angle_state/required_len;
        if(angle_toreduce<0.15 && node.depth>2)
        {
            angle_toreduce=0.2;
        }
        var stable = angle_toreduce;
        step = angle_toreduce;
        r=(big_radius+(big_radius-big_radius/3))/(Math.tan(stable));
        if(r<diagonal)
        {
            r=diagonal;
        }
        else if(r>350)
        {
            r=300;
        }
        var fromX = (parent.offsetLeft+((parent.offsetWidth)/2));
        var fromY = (parent.offsetTop+((parent.offsetHeight)/2));
        var origin_angle = Math.atan2(nctop-fromY, ncleft-fromX);
    }
    for(var k=0;k<required_len;k++)
    {
        var cnleft=Math.round(ncleft+r*Math.cos(origin_angle));
        var cntop=Math.round(nctop+r*Math.sin(origin_angle));
        Element_positions[j++] = [cnleft,cntop,r,step];
        if(node.id!=1)
        {
            if(done==0)
            {
                origin_angle+=angle_toreduce;
                done=1;
            }
            else
            {
                origin_angle=origin_angle-angle_toreduce;
                done=0;
            }
            angle_toreduce=angle_toreduce+stable;
        }
        else
        {
            origin_angle+=step;
        }
    }
    return Element_positions;
}catch(er){
	alert('placing nodes err'+er);
	}
}
function resizeImage()
{
    var ln = getObj("content_label").querySelectorAll("img").length;
    for(i=0;i<ln;i++)
    {
        if(getObj("content_label").querySelectorAll("img")[i].width>getObj("aside").offsetWidth)
        {
            getObj("content_label").querySelectorAll("img")[i].style.width = "100%";
        }
        getObj("content_label").querySelectorAll("img")[i].style.position = "relative";
        getObj("content_label").querySelectorAll("img")[i].style.left = 2+"px";
    }
    if(getObj("content_label").querySelector("embed")){
        //alert(getObj("content").querySelector("embed"));
    }
}
function getAllChilds(_parent)
{
try{
    var count=0;
    var left = _parent.offsetLeft;
    var top = _parent.offsetTop;
    var childArray = new Array();
    childArray.length = 0;
    for(var o=0;o<main_storage.length;o++)
    {
        if(_parent.id == main_storage[o][2] && _parent.id == main_storage[o][1])//if it is a starting _node
        {
            for(var p=0;p<main_storage.length;p++)
            {
                if(_parent.id == main_storage[p][2] && _parent.id!=main_storage[p][1])
                {
                    childArray[count] = p;
                    ++count;
                }
            }
            return childArray;
        }
        else if(_parent.id == main_storage[o][2])
        {
            childArray[count] = o;
            ++count;
        }
    }
    return childArray;
}catch(er){
	alert('getallchilds err'+er);
	}
}

function showAllChilds(allchilds, _node)
{
    try{
        var ncleft = (_node.offsetLeft+((_node.offsetWidth)/2));
        var nctop = (_node.offsetTop+((_node.offsetHeight)/2));
        var len = allchilds.length;
        var nooverlap = placingNodes(ncleft,nctop,_node,len,2,0,diagonal);
        var r=10;
        if(len>0)
        {
            window.clearInterval(anim_load);
            anim_load = 0;
            anim_load = window.setInterval(animateCircles,1,[ncleft,nctop,len,allchilds,r,nooverlap,_node.title]);
        }
        else
        {
            click_anim=0;
        }
    }catch(er){
        alert('er5'+er);
    }
}
function drawing_circles(data)
{
try{
    var nooverlap = data[4];
    var ncleft = data[0];
    var nctop = data[1];
    var len = data[2];
    var allchilds = data[3];
    var radius = nooverlap[0][2];
    for(i=0;i<len;i++)
    {
        var pos = allchilds[i];
        cnvs[i] = document.createElement("canvas");
        settingsApply(cnvs[i],dcindex,i,pos);//applying settings for canvas element
        getObj(main_storage[pos][1]).angle_state = nooverlap[0][3];
        ctx[i] = getObj(main_storage[pos][1]).getContext("2d");
        settingContext(ctx[i],small_radius,(cnvs[i].width/2),(cnvs[i].height-cnvs[i].height/8),getText(main_storage[pos][0]),bcolor);
        getObj(main_storage[pos][1]).style.position = "absolute";
        attach_createchild_Event(getObj(main_storage[pos][1]));
        getObj(main_storage[pos][1]).style.left = (nooverlap[i][0]-(big_radius+small_radius/2))+"px";
        getObj(main_storage[pos][1]).style.top = (nooverlap[i][1]-(big_radius+small_radius/2))+"px";
    }
    createLines(ncleft,nctop,len,nooverlap);

}catch(er){
	alert('drawing circles err'+er);
	}
}
function settingsApply(obj,dcindex,index,pos)
{
    try{
        obj.setAttribute("height",((big_radius*2)+small_radius));
        obj.setAttribute("width",((big_radius*2)+small_radius));
        obj.setAttribute("id",main_storage[pos][1]);
        obj.setAttribute("title",main_storage[pos][2]);
        obj.setAttribute("class","canvas_map");
        if(getObj(main_storage[pos][1]+"_childs")){
            getObj(main_storage[pos][2]+"_childs").removeChild(getObj(main_storage[pos][1]+"_childs"));
        }
        var _obj = document.createElement("div");
        _obj.setAttribute("id",main_storage[pos][1]+"_childs");
        if(main_storage[pos][1]=="1"){
            getObj("map").appendChild(_obj);
            getObj("map").appendChild(obj);
        }
        else{
            getObj(main_storage[pos][2]+"_childs").appendChild(_obj);
            getObj(main_storage[pos][2]+"_childs").appendChild(obj);
        }
    }catch(er){
        alert("er2"+er);
    }
}
function settingsApplyforAnim(obj,dcindex,pos)
{
    try{

        obj.setAttribute("height",((big_radius*2)+small_radius));
        obj.setAttribute("width",((big_radius*2)+small_radius));
        obj.setAttribute("id",main_storage[pos][1]);
        obj.setAttribute("title",main_storage[pos][2]);
        obj.setAttribute("class","canvas_map");
        if(getObj(main_storage[pos][1]+"_childs")){
            getObj(main_storage[pos][2]+"_childs").removeChild(getObj(main_storage[pos][1]+"_childs"));
        }

        var _obj = document.createElement("div");
        _obj.setAttribute("id",main_storage[pos][1]+"_childs");

        if(main_storage[pos][1]=="1"){
            getObj("map").appendChild(_obj);
            getObj("map").appendChild(obj);
        }
        else{
            //var _parentid = getParentId(getObj(main_storage[pos][2]));
            getObj(main_storage[pos][2]+"_childs").appendChild(_obj);
            getObj(main_storage[pos][2]+"_childs").appendChild(obj);
        }
    }catch(er){
        alert("err3"+er);
    }
}
function attach_createchild_Event(obje)
{
    obje.addEventListener("click", create_Childs, true);
}
function getText(obj_for_text)
{
	try{
	    getObj("dummy").innerHTML = obj_for_text;
	    return getObj("dummy").textContent;//firstChild.firstChild.firstChild.nodeValue;
	}catch(er){
		alert('get text errr'+er);
		return obj_for_text;
	}
}
function settingContext(ctx,r,left,top,text,color)
{
try{
    ctx.beginPath();
    ctx.arc(getObj(main_storage[0][1]).width/2,getObj(main_storage[0][1]).height/2,r,0,Math.PI*2,true);
    ctx.fillStyle=color;
    ctx.fill();
    if(r==big_radius)//this is for border drawing on outer side of big circle
    {
        ctx.strokeStyle = bcolor;
        ctx.arc(getObj(main_storage[0][1]).width/2,getObj(main_storage[0][1]).height/2,r+4,0,Math.PI*2,true);
        ctx.stroke();
    }
    ctx.closePath();
    ctx.beginPath();
    ctx.font = "10pt Tahoma";
    if(r==big_radius)
    {
        if(text.length>15)
        {
            wrapText(ctx, text, left, top-10, (getObj(main_storage[0][1]).width-getObj(main_storage[0][1]).width/3), 10);
        }
        else
        {
            wrapText(ctx, text, left, top+5, (getObj(main_storage[0][1]).width-getObj(main_storage[0][1]).width/3), 10);
        }
    }
    else
    {
        wrapText(ctx, text, left, top-10, getObj(main_storage[0][1]).width, 10);//ctx.fillText(text, 5, 10); this has been replaced if text is bigger
    }
    ctx.closePath();
	}catch(er){
	alert('settingcontext err'+er);
	}
}
function createLines(x,y,no_of_lines,nooverlap)
{

    var radius = nooverlap[0][2];
    var firsthalf = radius/3;
    for(var i = 0; i<no_of_lines; i++)
    {
        var angle = Math.atan2(nooverlap[i][1]-y, nooverlap[i][0]-x);
        var lineleft=Math.round(x+(radius-2)*Math.cos(angle));
        var linetop=Math.round(y+(radius-2)*Math.sin(angle));
        /*arrow_ctx.save();
         arrow_ctx.beginPath();
         canvas_arrow(arrow_ctx, x, y, lineleft, linetop);

         var nleft=Math.round(lineleft+(firsthalf+2)*Math.cos(angle));
         var ntop=Math.round(linetop+(firsthalf+2)*Math.sin(angle));
         arrow_ctx.moveTo(lineleft,linetop);
         arrow_ctx.lineTo(nleft,ntop);
         arrow_ctx.strokeStyle=linecolor;
         arrow_ctx.stroke();
         arrow_ctx.closePath();
         arrow_ctx.restore();		*/
        try{

            drawPixel(getObj("s"), x, y, lineleft, linetop,i);
            var headlen = 15;   // length of head in pixels
            var angle = Math.atan2(linetop-y,lineleft-x);
            var tpixel = document.createElementNS("http://www.w3.org/2000/svg", "polygon");
            var xx=Math.round(x+(radius/2)*Math.cos(angle));
            var yy=Math.round(y+(radius/2)*Math.sin(angle));
            //points="200,10 250,190 160,210"
            tpixel.setAttribute('id',"arrow_"+selected_node.id+"_"+i);
            tpixel.setAttribute('points',xx+","+yy+" "+(xx-headlen*Math.cos(angle-Math.PI/6))+","+(yy-headlen*Math.sin(angle-Math.PI/6))+" "+(xx-headlen*Math.cos(angle+Math.PI/6))+","+(yy-headlen*Math.sin(angle+Math.PI/6)));
            tpixel.setAttribute('style', 'fill:rgb(10,140,200);stroke:rgb(10,140,200);stroke-width:1');
            if(!getObj(selected_node.id+"_arrows")){
                var _obj = document.createElementNS("http://www.w3.org/2000/svg", "svg")
                _obj.setAttribute("id",selected_node.id+"_arrows");


                if(selected_node.id == "1")
                    getObj("s").appendChild(_obj);
                else{
                    try{
                        getObj(selected_node.title+"_arrows").appendChild(_obj);
                    }catch(er){
                        alert('arrowerr1'+er);
                    }
                }
            }
            getObj(selected_node.id+"_arrows").appendChild(tpixel);
        }catch(er){
            alert("triangle"+er);
        }
    }
}
function animateCircles(data)
{
try{
    var ncleft = data[0];
    var nctop = data[1];
    var len = data[2];
    var allchilds = data[3];
    var nooverlap = data[5];
    for(var i=0;i<len;i++)
    {
        var pos = allchilds[i];
        anim_layer[i] = document.createElement("canvas");
        settingsApplyforAnim(anim_layer[i],data[6],pos);//applying settings for canvas element
        anim_ctx[i] = getObj(main_storage[pos][1]).getContext("2d");
        settingContext(anim_ctx[i],small_radius,(anim_layer[i].width/2),(anim_layer[i].height-anim_layer[i].height/8),getText(main_storage[pos][0]),bcolor);
        getObj(main_storage[pos][1]).style.position = "absolute";
        var angle = Math.atan2(nooverlap[i][1]-nctop, nooverlap[i][0]-ncleft);
        var cnleft=Math.round(ncleft+data[4]*Math.cos(angle));
        var cntop=Math.round(nctop+data[4]*Math.sin(angle));
        getObj(main_storage[pos][1]).style.left = (cnleft-(big_radius+small_radius/2))+"px";
        getObj(main_storage[pos][1]).style.top = (cntop-(big_radius+small_radius/2))+"px";
    }
    data[4] += 8;
    for(var i=0;i<len;i++){
        anim_layer[i].width = anim_layer[i].width;}
    if(data[4]>nooverlap[0][2])
    {
        clearInterval(anim_load);
        window.setTimeout(drawing_circles,10,[ncleft,nctop,len,allchilds,nooverlap]);
        for(var i=0;i<len;i++){
            anim_ctx[i].clearRect(0,0,anim_layer[i].width,anim_layer[i].height);}
        click_anim=0;
    }
}catch(er){
	alert('animcircles err'+er);
	}
}
function wrapText(context, text, x, y, maxWidth, lineHeight)
{
try{
    text =text.replace(/-/g,'- ');
    var words = text.split(' ');
    var line = "";
    context.fillStyle = "black";
    context.textAlign = "center";



    for (var n = 0; words.length>1 && n < words.length; n++) {
        var testLine = line + words[n] + " ";
        var metrics = context.measureText(testLine);
        var testWidth = metrics.width;
        if (testWidth > maxWidth) {
            context.fillText(line, x, y);
            line = words[n] + " ";
            y += lineHeight;
        }
        else {
            line = testLine;
        }
    }
    if(words.length==1){
        if(text.length>15){
            try{
                line = text.substr(0,15);
                context.fillText(line, x, y);
                y += lineHeight;
                line = text.substr(15,text.length);
                context.fillText("-"+line, x, y);
                /*for(i=0;i<text.length-15;){
                 line = text.substr(i,i+15);
                 context.fillText(line, x, y);
                 y += lineHeight;
                 i = i+15;
                 }*/
            }catch(er){

            }
        }
        else
            context.fillText(text, x, y);

    }
    else
        context.fillText(line, x, y);
    context.fill();
}catch(er){
	alert('wrap text err'+er);
	}
}
function canvas_arrow(context, fromx, fromy, tox, toy){
try{
    var headlen = 15;   // length of head in pixels
    var angle = Math.atan2(toy-fromy,tox-fromx);
    context.moveTo(fromx, fromy);
    context.lineTo(tox, toy);
    context.moveTo(tox, toy);
    context.lineTo(tox-headlen*Math.cos(angle-Math.PI/6),toy-headlen*Math.sin(angle-Math.PI/6));
    context.moveTo(tox, toy);
    context.lineTo(tox-headlen*Math.cos(angle+Math.PI/6),toy-headlen*Math.sin(angle+Math.PI/6));
}catch(er){
	alert('canvas arrow err'+er);
	}
}
function drawPixel(SVGRoot, x, y, tox, toy,linenum) {
    try{
        var pixel = document.createElementNS("http://www.w3.org/2000/svg", "line");

        pixel.setAttribute('x1', x);
        pixel.setAttribute('y1', y);
        pixel.setAttribute('x2', tox);
        pixel.setAttribute('y2', toy);
        pixel.setAttribute('style', 'stroke:rgb(10,140,200);stroke-width:2');
        pixel.setAttribute('id',"line_"+selected_node.id+"_"+linenum);

        if(!getObj(selected_node.id+"_lines")){
            var _obj = document.createElementNS("http://www.w3.org/2000/svg", "svg");//document.createElement("div");//document.createElementNS("http://www.w3.org/2000/svg", "line");
            _obj.setAttribute("id",selected_node.id+"_lines");



            if(selected_node.id == "1")
                getObj("s").appendChild(_obj);
            else{
                try{
                    getObj(selected_node.title+"_lines").appendChild(_obj);
                }catch(er){
                    alert('getObj(dcindex+"_childs"err1'+er);
                }
            }
            //alert("***"+dcindex);
        }
        getObj(selected_node.id+"_lines").appendChild(pixel);
        //getObj("s").appendChild(pixel);
    }catch(e){
        alert("drawpixel er "+e);
    }
}

