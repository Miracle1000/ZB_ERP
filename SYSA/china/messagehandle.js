﻿function callServer(){
	if (window.disPrompValue == false)
	{
		var mytime=setTimeout("callServer();",window.num_alt_jg);
		var url = "cu.asp?timestamp=" + new Date().getTime() + "&date1="+ Math.round(Math.random()*100);
		xmlHttp.open("GET", url, false);
		xmlHttp.onreadystatechange = function(){updatePage();};
		xmlHttp.send(null);
		xmlHttp.abort();
	}
}

function updatePage(){
	if (xmlHttp.readyState == 4)
	{
		var response = xmlHttp.responseText;
		delete xmlhttp;
		xmlhttp=null;
		CollectGarbage;
		if ((response == 0) || (response == "")) return;
		var MSG1 = new CLASS_MSN_MESSAGE("aa",200,120,"短消息提示：","您有1封消息",response);
		MSG1.rect(null,null,null,screen.height-50);
		MSG1.speed = 10;
		MSG1.step = 5;
		MSG1.show();
		xmlHttp.abort();
	}
}
CLASS_MSN_MESSAGE.prototype.hide = function()
{
	if(this.onunload())
	{
		var offset = this.height>this.bottom-this.top?this.height:this.bottom-this.top;
		var me = this;
		if(this.timer>0){window.clearInterval(me.timer);}
		var fun = function()
		{
			if(me.pause==false||me.close)
			{
				var x = me.left;
				var y = 0;
				var width = me.width;
				var height = 0;
				if(me.offset>0){height = me.offset;}
				y = me.bottom - height;
				if(y>=me.bottom)
				{
					window.clearInterval(me.timer);
					me.Pop.hide();
				}
				else
				{
					me.offset = me.offset - me.step;
				}
				me.Pop.show(x,y,width,height);
			}
		};
		this.timer = window.setInterval(fun,this.speed);
	}
};

/**//*
*    消息卸载事件，可以重写
*/
CLASS_MSN_MESSAGE.prototype.onunload = function(){return true;};
/**//*
*    消息命令事件，要实现自己的连接，请重写它
*
*/
CLASS_MSN_MESSAGE.prototype.oncommand = function(){this.hide(); window.open("topalt.asp");};
/**//* 
*    消息显示方法 
*/
CLASS_MSN_MESSAGE.prototype.show = function()
{
	var oPopup = window.createPopup(); //IE5.5+ 
	this.Pop = oPopup; 
	var w = this.width; 
	var h = this.height; 
	var str = "<DIV  onfocus='testfunc(event);' style='BORDER-RIGHT: #455690 1px solid; BORDER-TOP: #a6b4cf 1px solid; Z-INDEX: 99999; LEFT: 0px; BORDER-LEFT: #a6b4cf 1px solid; WIDTH: " + w + "px; BORDER-BOTTOM: #455690 1px solid; POSITION: absolute; TOP: 0px; HEIGHT: " + h + "px; background-image: ../images/m_table_top.jpg'>" 
	str += "<TABLE style='BORDER-TOP: #ffffff 1px solid; BORDER-LEFT: #ffffff 1px solid' cellSpacing=0 cellPadding=0 width='100%' bgColor=#ecf5ff border=0>" 
	str += "<TR>" 
	str += "<TD style='FONT-SIZE: 12px;COLOR: #0f2c8c' width=30 height=24></TD>" 
	str += "<TD style='PADDING-LEFT: 4px; FONT-WEIGHT: normal; FONT-SIZE: 12px; COLOR: #1f336b; PADDING-TOP: 4px' vAlign=center width='100%'>" + this.caption + "</TD>" 
	str += "<TD style='PADDING-RIGHT: 2px; PADDING-TOP: 2px' vAlign=center align=right width=19>" 
	str += "<SPAN title=关闭 style='FONT-WEIGHT: bold; FONT-SIZE: 12px; CURSOR: hand; COLOR: red; MARGIN-RIGHT: 4px' id='btSysClose' >×</SPAN></TD>" 
	str += "</TR>" 
	str += "<TR>" 
	str += "<TD style='PADDING-RIGHT: 1px;PADDING-BOTTOM: 1px' colSpan=3 height=" + (h-28) + ">" 
	str += "<DIV style='BORDER-RIGHT: #b9c9ef 1px solid; PADDING-RIGHT: 8px; BORDER-TOP: #728eb8 1px solid; PADDING-LEFT: 8px; FONT-SIZE: 12px; PADDING-BOTTOM: 8px; BORDER-LEFT: #728eb8 1px solid; WIDTH: 100%; COLOR: #1f336b; PADDING-TOP: 8px; BORDER-BOTTOM: #b9c9ef 1px solid; HEIGHT: 100%'><BR>" 
	str += "<DIV style='WORD-BREAK: break-all' align=left><font hidefocus=false id='btCommand'>您有"+this.message+"条消息</font> -  <A href='#' target='_blank' hidefocus=false id='alt_href'><FONT color=#ff0000>查看详情>></FONT></A></DIV><BR>" 
	str += "<DIV style='WORD-BREAK: break-all' align=left><input type='checkbox' name='checkbox'  id='alt_close' value='checkbox' />今日不再提示</DIV>"
	str += "</DIV>" 
	str += "</TD>" 
	str += "</TR>" 
	str += "</TABLE>" 
	str += "</DIV>" 
	oPopup.document.body.innerHTML = str; 
  this.offset = 0; 
  var me = this; 
  oPopup.document.body.onmouseover = function(){me.pause=true;};
  oPopup.document.body.onmouseout = function(){me.pause=false;};

	var fun = function()
	{
		var x = me.left;
		var y = 0;
		var width = me.width; 
		var height = me.height;
		if(me.offset>me.height)
		{
			height = me.height; 
		}
		else
		{
			height = me.offset;
		}
		y = me.bottom - me.offset;
		if(y<=me.top)
		{
			me.timeout--;
			if(me.timeout==0)
			{
				window.clearInterval(me.timer);
				if(me.autoHide){me.hide();}
			} 
		}
		else
		{ 
			me.offset = me.offset + me.step;
		}
		me.Pop.show(x,y,width,height);
  };
	this.timer = window.setInterval(fun,this.speed);
	var btalt_close = oPopup.document.getElementById("alt_close");

  btalt_close.onclick = function()
	{
		alt_close();
		window.disPrompValue = true;
		alt_SetDisPromp();
		me.close = true;
		me.hide();
	};

	var btalt_href = oPopup.document.getElementById("alt_href"); 
	btalt_href.onclick = function()
	{ 
		alt_href();
		alt_close();
		me.close = true;
		me.hide();
	};

	var btClose = oPopup.document.getElementById("btSysClose"); 
	btClose.onclick = function()
	{
		me.close = true;
		me.hide();
	};
	var btCommand = oPopup.document.getElementById("btCommand");
	btCommand.onclick = function(){me.oncommand();};
};
/**//*
*    消息构造
*/
function CLASS_MSN_MESSAGE(id,width,height,caption,title,message,target,action){ 
	this.id = id; 
	this.title = title; 
	this.caption= caption; 
	this.message= message; 
	this.target = target; 
	this.action = action; 
	this.width = width?width:200; 
	this.height = height?height:120; 
	this.timeout= 600; 
	this.speed = 20000; 
	this.step = 1; 
	this.right = screen.width -1; 
	this.bottom = screen.height; 
	this.left = this.right - this.width; 
	this.top = this.bottom - this.height; 
	this.timer = 0; 
	this.pause = false;
	this.close = false;
	this.autoHide = true;
}

/**//*
*    隐藏消息方法
*/

/**//*
** 设置速度方法
**/
CLASS_MSN_MESSAGE.prototype.speed = function(s){
	var t = 20; 
	try{t = praseInt(s);}catch(e){}
	this.speed = t; 
};
/**//*
** 设置步长方法
**/
CLASS_MSN_MESSAGE.prototype.step = function(s){ 
	var t = 1; 
	try{t = praseInt(s);}catch(e){}
	this.step = t;
};

CLASS_MSN_MESSAGE.prototype.rect = function(left,right,top,bottom){ 
	try
	{
		this.left = left !=null?left:this.right-this.width;
		this.right = right !=null?right:this.left +this.width;
		this.bottom = bottom!=null?(bottom>screen.height?screen.height:bottom):screen.height;
		this.top = top !=null?top:this.bottom - this.height;
	}
	catch(e){}
};

window.onload = function(){
	window.disPrompValue = (alt_GettDisPromp() == "True") ? true : false;
	var myalt=setTimeout("callServer();",10000); 
}