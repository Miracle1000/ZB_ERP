﻿
		function show_cllist(obj_id){
		  if(document.getElementById(obj_id).style.display=="none"){
		  document.getElementById(obj_id).style.display="";}else{
		  document.getElementById(obj_id).style.display="none";
		  }
		  if (obj_id.indexOf("2")>0)
		  {
			op_cl(document.getElementById("v2"),document.getElementById("t2"))
		  }
		  else if (obj_id.indexOf("1")>0)
		  {
			op_cl(document.getElementById("v1"),document.getElementById("t1"))
		  }
		  else
		  {
			op_cl(document.getElementById("v3"),document.getElementById("t3"))
		  }
		}
		function totalday(){
			var lenths=document.getElementById("replysobj").rows.length;
			var days=0;
			for (var ii=0;ii<lenths ; ii++){
				if (document.getElementById("reply"+ii))
				{
					var v=document.getElementById("reply"+ii).value;
					if (!isNaN(v)){days=days+parseInt(v);}
				}
			}
			//保存时判断下 if days>replypause.value
		}
		function showGjcl(){
			var isProtect=0;
			if(document.getElementById("isProtect1").checked==true){
				isProtect=1;
			}
			show_cllist('cllist1');
			if (isProtect==0){
				document.getElementById("cllist5").style.display="none";
				document.getElementById("replysobj").style.display="none";
				document.getElementById("cllist4").style.display="none";
			}else{
				document.getElementById("cllist5").style.display="";
				var hasReply = (document.getElementById("replysobj").innerHTML.replace(/\s/g,"").length>0);
				document.getElementById("replysobj").style.display=(hasReply?"":"none");
				document.getElementById("cllist4").style.display="";
			}
		}
		function op_cl(obj1,obj2)
		{
			if (obj1.value==1)
			{	
				obj2.innerText="(点击即可收回)";
				obj1.value=2;
			}
			else
			{
				obj2.innerText="(点击即可展开)";
				obj1.value=1;
			}
		}
		function showGjday(){
			var isProtect=0;
			if(document.getElementById("isProtect1").checked==true){
				isProtect=1;
			}
			if (isProtect==0){
				document.getElementById("cllist5").style.display="none";
				document.getElementById("replysobj").style.display="none";
				document.getElementById("cllist4").style.display="none";
			}else{
				document.getElementById("cllist5").style.display="";
				var hasReply = (document.getElementById("replysobj").innerHTML.replace(/\s/g,"").length>0);
				document.getElementById("replysobj").style.display=(hasReply?"":"none");
				document.getElementById("cllist4").style.display="";
			}
		}
	