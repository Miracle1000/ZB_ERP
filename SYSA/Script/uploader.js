﻿window.onload = function(){  
   /*init webuploader*/  
   var $list=$("#thelist");   //这几个初始化全局的百度文档上没说明，好蛋疼。  
   var $btn =$("#ctlBtn");   //开始上传  
   var thumbnailWidth = 100;   //缩略图高度和宽度 （单位是像素），当宽高度是0~1的时候，是按照百分比计算，具体可以看api文档  
   var thumbnailHeight = 100;  
  
   var uploader = WebUploader.create({  
       // 选完文件后，是否自动上传。  
       auto: false,    
       // swf文件路径  
       swf: '../script/Uploader.swf',  
       // 文件接收服务端。  
       server: '../../SYSN/view/comm/uploader.ashx?__msgid=uploader&dir=reply',  
       // 选择文件的按钮。可选。  
       // 内部根据当前运行是创建，可能是input元素，也可能是flash.  
       pick: '#filePicker',  
       // 只允许选择图片文件。  
       accept: {  
           title: '所有允许上传文件',
           //extensions: 'gif,jpg,jpeg,bmp,png',  
           //mimeTypes: 'image/*'  
           extensions: 'png,jpg,jpeg,gif,psd,dwg,txt,doc,docx,xls,xlsx,ppt,pptx,ppts,pdf,rar,Zip,exe,avi,mp4,MP3'
       },  
	    formData: { "billord": window.billord ,"sorttype":window.sorttype },
		method:'POST',
		// 不压缩image, 默认如果是jpeg，文件上传前会压缩一把再上传！
		resize: false
   });  
   // 当有文件添加进来的时候  
   uploader.on( 'fileQueued', function( file ) {  // webuploader事件.当选择文件后，文件被加载到文件队列中，触发该事件。等效于 uploader.onFileueued = function(file){...} ，类似js的事件定义。  
      /* var $li = $(  
               '<div id="' + file.id + '" class="file-item thumbnail">' +  
                   '<img>' +  
                   '<div class="info">' + file.name + '</div>' +  
               '</div>'  
               ),  
           $img = $li.find('img');  
  
  
       // $list为容器jQuery实例  
       $list.append( $li );  
		*/
	   $list.append( '<div id="' + file.id + '" class="item">' +
        '<h4 class="info">' + file.name + '</h4>' +
        '<p class="state">等待上传...</p>' +
    '</div>' );
  
       // 创建缩略图  
       // 如果为非图片文件，可以不用调用此方法。  
       // thumbnailWidth x thumbnailHeight 为 100 x 100  
	   /*
       uploader.makeThumb( file, function( error, src ) {   //webuploader方法  
           if ( error ) {  
               $img.replaceWith('<span>不能预览</span>');  
               return;  
           }  
  
           $img.attr( 'src', src );  
       }, thumbnailWidth, thumbnailHeight );  
	   */
   });  
   // 文件上传过程中创建进度条实时显示。  
   uploader.on( 'uploadProgress', function( file, percentage ) {  
		$(".state").hide();
		var $li = $( '#'+file.id ),  
           $percent = $li.find('.progress span');  
  
       // 避免重复创建  
       if ( !$percent.length ) {  
           $percent = $('<p class="progress" style="position:static;height:20px;padding:0px"><span style="background-color:#00b7ee;display:block;width:0;height:20px"></span></p>').appendTo($li).find('span');  
       }  
       $percent.css( 'width', percentage * 100 + '%' );  
   });  
  
	// 文件上传成功，给item添加成功class, 用样式标记上传成功。  
	uploader.on( 'uploadSuccess', function( file ,response) {  
		 var obj = eval("(" + response["_raw"] + ")");
		$( '#'+file.id ).addClass('upload-state-done'); 
		$( '#'+file.id ).remove();
		if(obj.Message){
			alert(obj.Message);
			return;
		}
		var foldername = obj.foldername;
		var filename = obj.filename;
		var oldFileName =file.name;
		var strDesc = "无"; //文件备注
		var fileSize = obj.filesize; //文件大小
		var FileLink="<a href='../reply/upload/" + foldername + "/" + filename + "' target='_blank'>" + oldFileName + "</a>"
		
		var strDel="<a href='###' onclick='delRow(this,"+ obj.serverid +");'>删除</a>"
		addAtt(FileLink,fileSize, strDesc + "&nbsp;",strDel)
	});  
  
   // 文件上传失败，显示上传出错。  
   uploader.on( 'uploadError', function( file ) {  
       var $li = $( '#'+file.id ),  
           $error = $li.find('div.error');  
       // 避免重复创建  
       if ( !$error.length ) {  
           $error = $('<div class="error"></div>').appendTo( $li );  
       }
       $error.text('上传失败');  
   });  
  
   // 完成上传完了，成功或者失败，先删除进度条。  
   uploader.on( 'uploadComplete', function( file ) {  
       $( '#'+file.id ).find('.progress').remove();  //fadeOut() 渐隐渐没
   }); 
   
   $btn.on('click', function() {  
        uploader.upload();  
      });  
}; 