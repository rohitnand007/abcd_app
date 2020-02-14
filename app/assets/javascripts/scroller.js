scData = application.getScrData(0);
colorCode = {
    not_checked : '#f0f0f0',
    checked : '#f0f0f0',
    answered_and_unflagged : '#ccc',
    answered_and_flagged : "#ff9da2",
    unanswered_and_flagged : "#ff9da2"
    //unanswered and flagged is same as just checked
};
(function(){
    var obj = [];
    var count = 0;
    Scroller = function(sc){
        this.id = count;
        this._present_index = 0;
        var sr = new Object();
        sr.df = document.createDocumentFragment();
        var dfd = document.createElement("div");
        sr.lad = laDiv();
        dfd.appendChild(sr.lad);
        sr.md = document.createElement("div");
        sr.len = sc.length > 5 ? sc.length : 5 ;

        for (var i = 0; i < sr.len; i++){
            var doc = document.createElement("div");
            var txt = i < sc.length ? sc[i].vl : ".";
            var id = i< sc.length ? sc[i].bl : "0";
            var fl = i < sc.length ? sc[i].fl : "";
            var question_index = i < sc.length ? sc[i].question_index : "-1";
            var a = document.createTextNode(txt);
            doc.setAttribute("data-link_id", id);
            doc.setAttribute("value", i);
            doc.setAttribute("question_index", question_index);
            doc = styleNode(doc, i, fl);
            if(i == 0){
                doc.style.outline = "#ccc solid 2px";
            }
            doc.appendChild(a);
            sr.md.appendChild(doc);
        }
        sr.md.style.display = "inline-block";
        dfd.appendChild(sr.md);
        sr.rad = raDiv();
        dfd.appendChild(sr.rad);
        sr.df.appendChild(dfd);
        sr.tost = getToast();
        sr.df.appendChild(sr.tost);
        count = count + 1;
        obj.push(sr);

        this.getDisplayNode = function(){
            return obj[this.id].df;
        };

        this.getLad = function(){
            return obj[this.id].lad;
        };

        this.getMd = function(){
            return obj[this.id].md;
        };

        this.getRad = function(){
            return obj[this.id].rad;
        };

        this.scRight = function(){
            if (obj[this.id].len >= 5){
                var arl = obj[this.id].md.childNodes;
                var arr = [];
                for(var i = 0; i < arl.length;i++){
                    arr.push(arl[i]);
                }
                arr = arr.filter(function(item, index, array){
                    return (item.style.display == "inline-block")
                });
                if(arr[4] !== arr[0].parentNode.lastChild){
                    arr[0].style.display = "none";
                    arr[4].nextSibling.style.display = "inline-block";
                }
                else{
                    if(obj[this.id].len >= 5){
                        // var x =  obj[this.id].tost;
                        // x.innerHTML = "Hey! you have reached last question of this section."
                        // x.style.display = "block";
                        // setTimeout(function(){x.style.display = "none";},2000);
                        showToastMessage(this.getRad(),"Hey! you have reached last question of this section.");
                    }
                }
            }
        };

        this.scLeft = function(){
            if (obj[this.id].len >= 5){
                var arl = obj[this.id].md.childNodes;
                var arr = [];
                for(var i = 0; i < arl.length;i++){
                    arr.push(arl[i]);
                }
                arr = arr.filter(function(item, index, array){
                    return (item.style.display == "inline-block")
                });
                if(arr[0] !== arr[0].parentNode.firstChild){
                    arr[0].previousSibling.style.display = "inline-block";
                    arr[4].style.display = "none";
                }
                else{
                    if(obj[this.id].len >= 5){
                        // var x =  obj[this.id].tost;
                        // x.innerHTML = "Hey! you have reached first question of this section."
                        // x.style.display = "block";
                        // setTimeout(function(){x.style.display = "none";},2000);
                        showToastMessage(this.getLad(),"Hey! you have reached first question of this section.");
                    }
                }
            }
        };

        this.getDiv = function(){
            //returns all middle nodes which are visible and not visible
            return obj[this.id].md.childNodes;
        };

        this.currentBtn = function(){
            for(var i = 0; i< obj[this.id].md.childNodes.length; i++){
                obj[this.id].md.childNodes[i].style.outline = "none";
            }
        };

        this.updateAMiddleNode = function(index){
            //set the status of the node as visible or not on the scroller
            var middle_div = this.getMd();
            var scroller_blocks = middle_div.querySelectorAll('div');
            var l;
            if(scroller_blocks[index].style.display=='inline-block')
                l=0;
            else
                l=10;
            if(index>=0 && index<scData.length){
                var flag_data = scData[index].fl;
                styleNode(obj[this.id].md.childNodes[index], l, flag_data);
            }
        }

        this.resetScroller = function(question_number){
            //question number is the question that is currently displayed
            var middle_div = this.getMd();
            var scroller_blocks = middle_div.querySelectorAll('div');
            var first_block = 0;
            if(scroller_blocks.length <= 5)
                return;
            else if(scroller_blocks.length - question_number <= 5){
                //question number is in last five
                first_block = scroller_blocks.length - 5;
            }else if(question_number==0){
                first_block = 0;
            }else{
                first_block = question_number - 1;
            }
            for(var i=0; i<scroller_blocks.length;i++){
                if((i-first_block)<=4 && (i-first_block)>=0)
                    scroller_blocks[i].style.display='inline-block';
                else
                    scroller_blocks[i].style.display='none';
            }
        }

        this.getQuestionIndexes = function(){
            var middle_divisions = this.getMd().childNodes;
            var question_numbers = new Array();
            for(var i=0; i<middle_divisions.length;i++){
                if(middle_divisions[i].getAttribute('data-link_id')!='0')
                    question_numbers.push((middle_divisions[i].getAttribute('question_index'))*1);
            }
            return question_numbers;
        }

        this.setPresentIndex = function(index){
            this._present_index = index;
        }

        this.getPresentIndex = function(){
            return this._present_index;
        }
    };

    function laDiv(){
        var lad = document.createElement("div");
        var la = document.createElement("img");
        la.src = "/assets/grey_arrow_left.png";
        la.style.verticalAlign = "middle";
        lad.appendChild(la);
        lad = styleNode(lad, -1 , [0, 0, 0] );
        return lad;
    }
    function raDiv(){
        var rad = document.createElement("div");
        var ra = document.createElement("img");
        ra.src = "/assets/grey_arrow_right.png";
        ra.style.verticalAlign = "middle" ;
        rad.appendChild(ra);
        rad = styleNode(rad, -1 , [0, 0, 0]);
        return rad;
    }
    function getToast(){
        var toast = document.createElement("div");
        toast.style.width = "185px";
        toast.style.height = "35px";
        toast.style.backgroundColor = "lightgray";
        toast.style.display = "none";
        toast.style.border = "1px solid grey";
        toast.style.borderRadius = "6px";
        toast.style.top = "35px";
        toast.style.left = "20px";
        toast.style.position = "absolute";
        toast.style.zIndex = "2";
        toast.style.padding = "10px";
        toast.style.textAlign = "center";
        toast.style.lineHeight = "normal";
        return toast;
    }
    function styleNode(dn, l, fl){
        //l = -1 right arrow or left arrow
        //0 <= l < 5division that should be seen on the scroller
        //l > 5 division that should not be seen on the scroller
        //fl[2] = 1: flagged, fl[1] = 1: Question Answered, fl[0] = 1: Question Seen
        if(l < 5 ){
            dn.style.display = "inline-block";
        }
        else{
            dn.style.display = "none";
        }
        dn.style.width = "30px";
        //dn.style.width = "15%";
        //dn.style.position = "absolute";
        dn.style.height = "24px";
        dn.style.backgroundColor = "#f0f0f0";
        dn.style.margin = "0px 2px";
        dn.style.lineHeight = "24px";
        dn.style.textAlign = "center";
        dn.style.color = "grey";
        dn.style.cursor = "pointer";
        //l=-1 for left arrow and right arrow
        if(l == -1){
            // dn.style.width = "20px";
            dn.style.width = "20px";
            dn.style.backgroundColor = "#fff";
            return dn;
        }
        // if(fl[0] == 1){
        //     dn.style.background = "#4D917A";
        //     dn.title = "Answered"}
        // else if(fl[1] == 1){
        //     dn.style.background = "#64B4E4";
        //     dn.title = "Flagged"
        // }
        // else if(fl[2] == 1){
        //     dn.style.background = "#F37934";
        //     dn.title = "Answered & Flagged"
        // }
        else if(fl[0]){
            if(fl[1]){
                if(fl[2]){
                    //question answered and flagged
                    dn.style.background = colorCode['answered_and_flagged'];
                }else{
                    //question answered and not flagged
                    dn.style.background = colorCode['answered_and_unflagged'];
                }
                dn.style.color = "white";
            }else{
                if(fl[2]){
                    //question not answered and flagged
                    dn.style.background = colorCode['unanswered_and_flagged'];
                    dn.style.color = "white";
                }else{
                    //question not answered and not flagged but seen
                    dn.style.background = colorCode['checked'];
                }
            }
        }else{
            dn.style.background = colorCode['not_checked'];
        }

        return dn;
    }

})();