﻿<%@ language=VBScript %>
<%
	Response.write vbcrlf
	ZBRLibDLLNameSN = "ZBRLib3205"
	Set zblog = server.createobject(ZBRLibDLLNameSN & ".ZBSysLog")
	zblog.init me
'ZBRLibDLLNameSN = "ZBRLib3205"
	Function EnCrypt(m)
		Dim bc : Set bc = server.createobject(ZBRLibDLLNameSN & ".Base64Class")
		EnCrypt = bc.EnCrypt(m & "") : Set bc = nothing
	end function
	Function DeCrypt(m)
		Dim bc : Set bc = server.createobject(ZBRLibDLLNameSN & ".Base64Class")
		DeCrypt = bc.DeCrypt(m & "") : Set bc = nothing
	end function
	Function pwurl(ByVal theNumber)
		If isnumeric(theNumber)=False Then pwurl = "" : Exit Function
		If LCase(typename(Sdk))<>"commclass" Then
			Dim sdktmp :Set sdktmp = server.createobject(ZBRLibDLLNameSN & ".CommClass")
			pwurl = sdktmp.VBL.EncodeNum(CLng(theNumber), server)
			Set sdktmp = Nothing
		else
			pwurl = ZBRuntime.Sdk.VBL.EncodeNum(CLng(theNumber), server)
		end if
	end function
	Function deurl(theNumber)
		If Len(theNumber&"") > 0 Then
			If InStr(theNumber,"%")>0 Then
				Dim b64 : Set b64 = server.createobject(ZBRLibDLLNameSN & ".Base64Class")
				theNumber = b64.UrlDecodeByUtf8(theNumber)
				Set b64 = nothing
			end if
			Dim v : v = ZBRuntime.Sdk.VBL.DecodeNum(theNumber & "") & ""
			if v ="" Or isnumeric(v) = False then
				deurl="-1"
			else
				deurl=v
			end if
		end if
	end function
	call ProxyUserCheck()
	function IsNumeric(byval v)
		dim r :  r = ""
		if len(v & "")=0 then IsNumeric = false : exit function
		on error resume next
		r  = replace((v & ""),",","")*1
		IsNumeric = len(r & "") >0
	end function
	function zbcdbl(byval v)
		if len(v & "") = 0 or IsNumeric(v & "")=False then  zbcdbl = 0 : exit function
		zbcdbl = cdbl(v)
	end function
	If Application("dis_sql_safe_check") = "" Then
		If comSqlSafeCheck = False Then
			if instr(lcase(request.ServerVariables("URL")),"checkin2.asp") > 0 Then
				Response.clear
			end if
			Response.end
		end if
	end if
	Sub ShowErrorMsg(ByVal title, ByVal code, ByVal errmsg)
		Dim c : On Error Resume Next
		Set c = server.createobject(ZBRLibDLLNameSN & ".CommClass")
		Dim vp : vp = ""
		vp = c.getvirpath
		Response.clear
		If InStr(lcase(code),"<script>") > 0 Then
			Response.write Replace(code, "@virpath", vp)
		else
			Response.write "<html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'/><title>系统信息</title><style>.r{color:red}</style><link href='" & vp & "inc/cskt.css' rel='stylesheet' "&_
			"type='text/css'/></head><body><table width='100%'  border='0' align='center' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'><tr><td width='100%' valign='top'>" &_
			"<table width='100%' border='0' cellpadding='0' cellspacing='0' background='" & vp & "images/m_mpbg.gif'>" &_
			"<tr><td class='place'>" & title & "</td><td>&nbsp;</td><td align='right'>&nbsp;</td><td width='3'><img src='" & vp & "images/m_mpr.gif' width='3' height='32' /></td></tr></table></td></tr>" &_
			"<tr><td style='border-top:1px solid #c0ccdd'><div style='padding:20px;line-height:24px'>"
			Response.write Replace(code, "@virpath", vp)
			If Len(errmsg) > 0 Then
				Response.write "<div id='errordiv' style='background-color:#f2f2f2;color:blue;font-family:arial,宋体;margin:10px auto;text-align:center;border:1px dotted #ccc;padding:10px;width:50%;display:none'>异常描述：" & errmsg & "</div>"
			end if
			Response.write "</td></td></tr></table><table width='100%' cellspacing='0' style='border-top:1px solid #c0ccdd'><tr><td class='page'>&nbsp;</td></tr></table><script>function showerror(){var box=document.getElementById(""errordiv"").style;box.display=box.display==""none""?""block"":""none""}</script></body></html>"
		end if
		Response.end
		Set c = nothing
	end sub
	Sub InitSysRuntimeVar
		Set ZBRuntime = server.createobject(ZBRLibDLLNameSN & ".Library")
		If ZBRuntime.SplitVersion <3173 Then Response.write "<br><br><br><br><center style='color:red;font-size:12px'>系统提示：运行库组件版本不正确。</center>" : Response.end
		if ZBRuntime.loadOK=False  Then
			Set sdk = server.createobject(ZBRLibDLLNameSN & ".CommClass")
			Call ZBRuntime.setDefLCID(Session)
			sdk.init me
		else
			If InStr(lcase(request.ServerVariables("URL")),"index2.asp") = 0 Then
				ShowErrorMsg "","<script>top.window.location.href ='@virpathindex2.asp?id2=8'</script>",""
			else
				ShowErrorMsg  "系统加载失败", "<center style='color:red'>系统运行组件未获取到正确的签名信息.</center>",""
			end if
		end if
	end sub
	function comSqlSafeCheck
		dim disCheckUrl , disSqlCheck , i
		disCheckUrl = "contract/moban_dy.asp|contract/moban_dy2.asp|email/creatAttach.asp"
		disCheckUrl = split(disCheckUrl,"|")
		for i = 0 to ubound( disCheckUrl )
			if instr(lcase(request.ServerVariables("URL")),disCheckUrl(i)) > 0 Then
				comSqlSafeCheck = true
				exit function
			end if
		next
		Dim fromurl : fromurl = Replace(Request.ServerVariables("Http_Referer"),"""","\""")
		dim keydatas,keylist,Sql_Post,ii, SqlKeys,hsQ
		keydatas = "'|exec |insert |select |delete |update |truncate |execute |shell |union |drop |create |<script|alert |confirm |eval "
		SqlKeys = Array( vbtab,  vbcr,  vblf,  "(",  "--", "/*")
		keylist = split(keydatas,"|")
		Dim n1,  n2,  n3
		If Request.QueryString<>"" Then
			For Each qname In Request.QueryString
				n1 = Request.QueryString(qname)
				For ii=0 To Ubound(keylist)
					n2 = keylist(ii)
					hsQ = instr(lcase(n1),lcase(n2))>0
					For  n3 = 0 To ubound(SqlKeys)
						If hsQ = True Then  Exit for
						hsQ  =  instr(lcase(n1), lcase(Replace(n2 &""," ", SqlKeys(n3))))>0
					next
					if  hsQ  Then
						Response.clear
						response.charset="UTF-8"
						Response.write "<script>alert('请不要使用非法字符(A)！');if(this.parent && this.parent!=this && this.parent.location.href==""" & fromurl & """){}else{history.back(-1)}</Script>"
						comSqlSafeCheck = false
						exit function
					end if
				next
			next
		end if
		If InStr(lcase(request.servervariables("CONTENT_TYPE") & ""),lcase("multipart/form-data"))=0  then
			If Request.Form<>"" Then
				For Each postname In Request.Form
					n1 = Request.Form(postname)
					For ii=0 To Ubound(keylist)
						n2 = keylist(ii)
						if len(n1&"")>1 then
							hsQ = instr(lcase(n1&""),lcase(n2&""))>0
						else
							hsQ =false
						end if
						For  n3 = 0 To ubound(SqlKeys)
							If hsQ = True Then  Exit for
							hsQ  =  instr(lcase(n1), lcase(Replace(n2 &""," ", SqlKeys(n3))))>0
						next
						if  hsQ  Then
							Response.clear
							response.charset="UTF-8"
							Response.write "<script>alert('请不要使用非法字符(B)');if(this.parent && this.parent!=this && this.parent.location.href==""" & fromurl & """){}else{history.back(-1)}</Script>"
							comSqlSafeCheck = false
							exit function
						end if
					next
				next
			end if
		end if
		comSqlSafeCheck = true
	end function
	public ZBRuntime, Sdk
	Call InitSysRuntimeVar
	Class ExcelCollocation
		Public Function Create()
			on error resume next
			Set m_xlsobj_app  = Server.CreateObject("Excel.Application")
			If Err.number <> 0 Then
				Response.clear
				Response.write sdk.Res.html("msg_excel_err")
				conn.close : cn.close : Response.end
			end if
		end function
		Private Sub Class_Terminate()
			on error resume next
			If LCase(typename(conn)) = "connection" Then conn.close : Set conn = nothing
			if LCase(typename(m_xlsobj_app)) = "application" Then
				Dim fs , fp : fp = server.mappath("../out/outerror_tmp_" & session("personzbintel2007") & ".xls")
				Set fs = server.createobject("Scripting.FileSystemObject")
				If Not fs Is Nothing then
					If fs.FileExists(fp) Then fs.DeleteFile fp  , true
					If Not fs.FileExists(fp) Then m_xlsobj_app.Worksheets(1).SaveAs fp
					m_xlsobj_app.Quit
					Set m_xlsobj_app = Nothing : Set fs = nothing
				end if
			end if
		end sub
	End Class
	Dim ec_obj , m_xlsobj_app
	Set ec_obj = New ExcelCollocation
	Function GetExcelApplication
		Call ec_obj.Create()
		Set GetExcelApplication = m_xlsobj_app
	end function
	Function ClientClosedExit
		If response.isClientconnected = false Then
			Err.raise 4908, "xlscc.asp", "客户端已经断开，触发Clientconnected判断机制，抛出常规性错误。"
		else
			ClientClosedExit = true
		end if
	end function
	Function JmgToUrl(url)
		If InStr(url,"?") > 0 Then
			url = url & "&asize=" & Abs(Len(request.form & request.querystring) > 0) & "&u=" &  server.htmlencode(LCase(request.servervariables("url")))
		end if
		Response.redirect url
	end function
	Function checkSuperDog(ByVal cnobj, ByVal vPath , ByVal ismobile)
		on error resume next
		Dim redirectURL , message
		redirectURL = "" : message = ""
		Dim tb_vcsc, DogApp, rs, dllpathmd5
		tb_vcsc = ""
		dllpathmd5 = ZBRuntime.DLLPath_MD5
		If Len(dllpathmd5) > 0 Then
			dllpathmd5 = " where  vpath='" & dllpathmd5 & "'"
		end if
		Err.clear
		If cnobj.Execute("select count(1) where EXISTS(SELECT id FROM dbo.SysObjects WHERE ID = object_id(N'M_content') AND OBJECTPROPERTY(ID, 'IsTable') = 1)")(0) > 0 Then
			If cnobj.Execute("select 1 from syscolumns where id = OBJECT_ID(N'[dbo].[M_content]') and name='vpath'").EOF Then
				cnobj.Execute "ALTER TABLE dbo.M_content ADD vpath varchar(50) NULL"
			end if
			Set rs = cnobj.Execute("select top 1 vcsc from M_content " & dllpathmd5)
			If Not rs.EOF Then tb_vcsc = rs(0)
			rs.close
		end if
		If tb_vcsc = "" Then
			redirectURL = vPath & "manager/setactive.asp?msg=本地注册凭证失效"
			message = "本地注册凭证失效"
		else
			tb_vcsc = StrReverse(Left(tb_vcsc, 9)) & StrReverse(Right(tb_vcsc, 23))
			tb_vcsc = Mid(tb_vcsc, 6, 16)
			If ZBRuntime.MC(61000) Then
				Set DogApp = server.CreateObject("SuperDog.DogApplication")
				If Err.Number <> 0 Then
					redirectURL = vPath & "check_log.asp?status=1" '"1.创建SuperDog组件失败,请注册: regsvr32 dog_com_windows.dll"
					message = getJmgStatus(1)
				else
					If (Nothing Is DogApp) Then
						redirectURL = vPath & "check_log.asp?status=1" '"1.创建SuperDog组件失败,请注册: regsvr32 dog_com_windows.dll"
						message = getJmgStatus(1)
					else
						If Err.Number <> 0 Then
							redirectURL = vPath & "check_log.asp?status=1" '"1.创建SuperDog组件失败,请注册: regsvr32 dog_com_windows.dll"
							message = getJmgStatus(1)
						else
							Dim FeatuerID, Dog
							Set FeatuerID = DogApp.Feature(1)
							Set Dog = DogApp.Dog(FeatuerID)
							Dim scope
							scope = "<?xml version=""1.0"" encoding=""UTF-8"" ?><dogscope><license_manager hostname =""localhost"" /></dogscope>"
'Dim scope
							Dim VendorCode1, VendorCode2, VendorCode3
							VendorCode1 ="rZIi6W3U5qKtIUZNTjSSgnhned/2ai8+E0R0NBzKbAJXC54ZGmWT6KxwW27xD1AAqNSGgkqq2vLKZw8H58QaVhSY09qxrACJswOaYydxdLtPynyrGcpOvvXgQQBtnQTdsn/aJD+SIcGRu+E0tXpExTbE5bblEy2H97Lo8uwTEM/vYCtheUo6wug5xulAxI71tRUorfpngzn"
'Dim VendorCode1, VendorCode2, VendorCode3
							VendorCode3 = "KzclLlNKmiU9pTIkRRyUqlzFtcEnhEjwamZxKCqp1ppaom0A5X72DEDnSMBg0rdCayaxJh/VrqtRv2Wujjx5acac1r+N7aaCjNiUer5X7ZExbWWIcRNxxwgFLZNALO5FliaHyopyWg4RQTbGGyZKdZ3RfiZJdfJLu0PApMQN+8ersyK2m7LMSY8eZc83D1vTX8BoZWY/HXvOsju2M039UnKUU+v00tdeT5/xhB3fNe6RSjcZXa/ZofLDQzHOj/2xRIAGISJ0JtQivr5jsgOQuhjJk9PthL5eFzYL+pYA0zdMIP5C42Go7MgAZSPLwMiEIOuyIeLep9ZR5iRcBl1fVyVjyaCVrn9Qt+Glcpj0lziam3SsGnl1WdXxM6yEc0nmmVrr0DSA=="
'Dim VendorCode1, VendorCode2, VendorCode3
							VendorCode2 = "Yi4m7PAjeQ4n7FGAPxnO63MrESMHczwVh9uod/MbrU7RYOiM90y6Cu9lNBpibp1LDERxDWctlxBEldMry6QLEG705q6ie6aQncWu9evLTsmkMsw4PDWoowCwyW431Wzc/+8EAk6gLkA2m6Jkf+Qooqu5Q5UQlJvDa8BQZqU7Lx2ZRqI3RGW7APIqWGFk1Bdrvedg16+zHL6/J9V7b5+KBAq9cAreJhcLN8WZ1yID1RZ5gDqSDu25Yajso92uXyN+M65WmMatEPxD4pZbUPRTxGrCRghIYzzWjpWRbg1ZVyyOT4RJpgu/9dF1UqooTD+jrT/VA121EYPt2FyMMYtVINiUH1LumPukUPH2s0D6Lk8UhNEvckutzCZtZ+ipswOzEac"
'Dim VendorCode1, VendorCode2, VendorCode3
							Dim status, DogFile
							status = Dog.LoginScope(VendorCode1 & VendorCode2 & VendorCode3, scope)
							If Not Dog.IsLoggedIn Then
								redirectURL = vPath & "check_log.asp?status=" & status
								message = getJmgStatus(status)
							else
								Set DogFile = Dog.GetFile(65524)
								If IsNull(DogFile) Then
									redirectURL = vPath & "check_log.asp?status=111" '"111.获取superDog空间内容失败"
									message = getJmgStatus(111)
								else
									Dim Size: Set Size = DogFile.FileSize
									If Size.status <> 0 Then
										redirectURL = vPath & "check_log.asp?status=" & Size.status
										message = getJmgStatus(Size.status)
									else
										Dim superDog_text : superDog_text = Trim(Replace(Replace(DogFile.ReadString,vbcr,""),vblf,""))
										If LCase(superDog_text) <> REMD5(LCase(tb_vcsc)) Then
											redirectURL = vPath & "check_log.asp?status=1000" '"1000.SuperDog硬件与该系统不匹配"
											message = getJmgStatus(1000)
										end if
									end if
								end if
								If Len(redirectURL)>0 Then Dog.Logout
							end if
						end if
					end if
				end if
				Set DogApp = Nothing
			end if
		end if
		On Error GoTo 0
		If ismobile = True Then
			If Len(message)>0 Then
				app.mobile.document.body.CreateModel("message","").Text = message
				Call App.mobile.flush
				Response.end
			end if
		else
			If Len(redirectURL)>0 Then
'Call retrieveSys(vPath)
'Call JmgToUrl(redirectURL)
			end if
		end if
	end function
	Function REMD5(str)
		Dim tStr, s, i
		If Trim(str) = "" Or IsNull(str) Then Exit Function
		For i = 1 To Len(str)
			s = Mid(str, i, 1)
			Select Case s:
			Case "0": s = "f"
			Case "1": s = "e"
			Case "2": s = "d"
			Case "3": s = "c"
			Case "4": s = "b"
			Case "5": s = "a"
			Case "6": s = "9"
			Case "7": s = "8"
			Case "8": s = "7"
			Case "9": s = "6"
			Case "a": s = "5"
			Case "b": s = "4"
			Case "c": s = "3"
			Case "d": s = "2"
			Case "e": s = "1"
			Case "f": s = "0"
			End Select
			tStr = tStr & s
		next
		REMD5 = tStr
	end function
	Function retrieveSys(ByVal vPath)
		on error resume next
		application.contents.removeall
		Session.Abandon
	end function
	Function getJmgStatus(ByVal status)
		Dim s : s = ""
		Select Case status
		Case 1:
		s = "错误号0001，创建服务器加密锁组件失败，请尝试通过注册命令“regsvr32 dog_com_windows.dll”解决该问题。"
		Case 7:
		s = "错误号0007，未找到服务器加密锁。"
		Case 30:
		s = "错误号0030，签名验证失败。"
		Case 31:
		s = "错误号0031，特征不可用。"
		Case 50:
		s = "错误号0050，不能找到与范围匹配的特征。"
		Case 111:
		s = "错误号0111，获取服务器加密锁内容失败。"
		Case 400
		s = "错误号0400，未找到API的动态库，请确认DLL是否正确的安装在System32或目录中。"
		Case 1000:
		s = "错误号1000，服务器加密锁与该系统不匹配。"
		Case else
		s = status & ".访问服务器错误。"
		End Select
		getJmgStatus = s
	end function
	sub ProxyUserCheck()
		on error resume next
		dim rs , sessionid, sdk, cnn
'if len(Application("_ZBM_Lib_Cache") & "") = 0 then
'Dim z : Set z = server.createobject(ZBRLibDLLNameSN & ".Library")
'z.GetLibrary "ZBIntel2013CheckBitString"
'end if
		if len(session("personzbintel2007") & "") > 0  and len(session("adminokzbintel") & "")>0 then
			exit sub
		end if
		sessionid = request.Cookies("ASP.NET_SessionId")
		if len(sessionid & "") = 0 then exit sub
		Set sdk = server.createobject(ZBRLibDLLNameSN & ".CommClass")
		sdk.TryReloadUserByRedis
		if len(session("personzbintel2007") & "") > 0  and len(session("adminokzbintel") & "")>0 then
			set sdk = nothing
			exit sub
		end if
		set cnn = server.CreateObject("adodb.connection")
		cnn.Open sdk.database.ConnectionText
		set rs = cnn.execute("select uid from UniqueLogin where  abs(datediff(n, LastActiveTime, getdate()))<15 and status='1' and sessionId='" &  replace(sessionid,"'","") & "'")
		if rs.eof = false then
			session("personzbintel2007") = rs(0).value
			session("adminokzbintel")="true2006chen"
		end if
		rs.close
		set rs = nothing
		cnn.Close
		set cnn = nothing
		err.Clear
	end sub
	Sub TryLoadSysInfo
		if  len(application("sys.info.configindex") & "")=0 then
			Dim z : Set z = server.createobject(ZBRLibDLLNameSN & ".Library")
			call z.LoadDBSysInfo
			set z = nothing
		end if
	end sub
	call TryLoadSysInfo
	Const XUNJIA_SIZE = 100
	Function GetAjaxRequest
		Dim s : GetAjaxRequest = false
		For Each s In Request.ServerVariables
			If s = "HTTP_A_S_T_ISAJAX" Then GetAjaxRequest = True : Exit function
		next
	end function
	sub ConflictProcHandle
		If isAjaxRequest Then Exit Sub
		Err.clear
		on error resume next
		if len(request.form & "") > 0 Then
			If Err.number = 0 Then Exit Sub
		end if
		If Err.number <> 0 Then
			On Error GoTo 0
			sdk.showmsg "提示信息", "<div style='padding:20px;color:red'>由于您提交到服务器的数据量可能过大，导致页面无法打开，请联系系统管理员，调整站点IIS相关配置解决该问题。</div>"
			conn.close
			Response.end
		end if
		Dim exiturl : exiturl = Split("planall,content,telhy,tongji",",")
		Dim i, url : url = geturl()
		For i= 0 To ubound(exiturl)
			If InStr(1, url, exiturl(i), 1)>0 Then Exit sub
		next
		on error resume next
		Dim cftManger: Set cftManger = Nothing
		Set cftManger = server.createobject(ZBRLibDLLNameSN & ".ConflictManger")
		If cftManger Is Nothing Then Err.clear: Exit Sub
		If IsObject(sdk) = False Then
			Set sdk = server.createobject(ZBRLibDLLNameSN & ".CommClass")
			sdk.init me
		end if
		If cftManger.ConflictProc(sdk) = False then
			Set cftManger = nothing
			call db_close : Response.end
		else
			ConflictPageUrllist = cftManger.ConflictPageUrllist
		end if
		Set cftManger = nothing
	end sub
	function GetConnectionText()
		Dim txt : txt = Application("_sys_connection")
		if len(txt) = 0 Then txt = sdk.database.ConnectionText
		server_1 = Application("_sys_sql_svr")
		sql_1 = Application("_sys_sql_db")
		user_1 = Application("_sys_db_user")
		pw_1 = Application("_sys_db_pass")
		getConnectionText = txt
	end function
	function GetHttpType
		dim loginurl
		loginurl = session("clientloginurl")
		if instr(1, loginurl, "https://", 1)>0 then
			GetHttpType = "https"
		else
			GetHttpType = "http"
		end if
	end function
	sub Response_redirect(url)
		on error resume next
		conn.close
		Response.redirect url
		call db_close : Response.end
	end sub
	function GetHl(ByVal bz, ByVal dvalue)
		If isdate(dvalue) = False Then GetHl = 1: Exit function
		GetHl = sdk.setup.Gethl(CStr(bz), CDate(dvalue))
	end function
	sub close_list(args)
		on error resume next
		call add_logs (args)
		conn.close:set conn=Nothing
		dim s : s = right("00" & action1,2)
		dim isbill, isreport
		if s="添加" or s="修改" or s="详情" then
			isbill = true
			isreport = false
		else
			if typename(page_count)<>"Empty" then
				isreport = true
				isbill = false
			end if
		end if
		if isbill then Response.write "<script>window.RegBillUISkin();</script>"
		if isreport then Response.write "<script>window.RegReportUISkin();</script>"
	end sub
	sub db_close()
		on error resume next
		If typename(conn) <> "Empty" And typename(conn) <> "Nothing" then
			conn.close:Set conn = Nothing
		end if
	end sub
	function FormatnumberSub(x1,x2,x3)
		if x1<>"" and x2<>"" then
			FormatnumberSub=Formatnumber(x1,x2,x3)
		else
			FormatnumberSub=""
		end if
	end function
	function colorWork(ByVal s)
		s=replace(s,"潜在客户","<font class='greenFont'>潜在客户</font>")
		s=replace(s,"重点客户","<font class='redFont'>重点客户</font>")
		s=replace(s,"老客户","<font class='orgFont'>老客户</font>")
		s=replace(s,"初次接触","<font class='greenFont1'>初次接触</font>")
		s=replace(s,"多次接触","<font class='greenFont2'>多次接触</font>")
		colorWork=s
	end function
	function Format_Time(s_Time, n_Flag)
		Select Case n_Flag
		Case 1: Format_Time = sdk.VBL.Format(s_Time, "yyyy-MM-dd hh:nn:ss")
'Select Case n_Flag
		Case 2: Format_Time = sdk.VBL.Format(s_Time, "yyyy-MM-dd")
'Select Case n_Flag
		Case 3: Format_Time = sdk.VBL.Format(s_Time, "hh:nn:ss")
		Case 4: Format_Time = sdk.VBL.Format(s_Time, "yyyy年MM月dd日")
		Case 5: Format_Time = sdk.VBL.Format(s_Time, "yyyyMMdd")
		Case 6: Format_Time = sdk.VBL.Format(s_Time, "yyyyMMddhhnnss")
		End Select
	end function
	sub CreateSqlConnection
		Set conn = server.CreateObject("adodb.connection")
		conn.commandtimeout=1200
		conn.open getConnectionText()
		sdk.InitRegDBOK
		If Application("__nosqlcahace")="1" Then conn.execute "DBCC DROPCLEANBUFFERS"
		conn.CursorLocation = 3
		conn.execute "SET ANSI_WARNINGS OFF"
		if err.number<>0 then
			Response.write "<script>top.location=""" & GetVirPath & "index4.asp?msg=" & server.urlencode(Err.description) & """;</script>"
			Call db_close() : Response.end()
		end if
	end sub
	Sub SqlLockSniffer()
		Dim url , uid
		url = request.servervariables("url")
		If Len(url) > 150 Then url = Left(url,150)
		url = Replace(url, "'","''")
		uid = sdk.user & ""
		If Len(uid) = 0 Or isnumeric(uid) =  False Then  uid = 0
		conn.Execute "exec sp_killlock 1 ,0,'" & url & "'," & uid
	end sub
	sub error(message)
		Response.write "<script>alert('" & Replace(message & "","'","\'") & "');history.back();window.close();</script>"
		call db_close : Response.end
	end sub
	function ReturnUrl()
		ReturnUrl=replace( split(geturl() & "?","?")(1) ,"%20","")
	end function
	function iif(byval cv,byval ov1,byval ov2)
		if cv then iif=ov1 : exit function
		iif=ov2
	end function
	function CNull(ByVal value, ByVal rpv1, ByVal rpv2)
		if value & "" = rpv1 & "" Then CNull = rpv2 : Exit function
		CNull = value
	end function
	Function GetStringLen(Str)
		on error resume next
		Dim Wd,I,Size
		Size = conn.execute("select DATALENGTH('"& Str &"') as r")(0)
		if err.number > 0 then Size = len(Str)
		GetStringLen = Size
	end function
	function ShowSignImage(ByVal catename, ByVal cateid, ByVal billdate)
		If catename&""="" Then catename = ""
		If cateid&""="" Then cateid = 0
		If billdate&""="" Then billdate = Date
		cateid = CLng(cateid)
		ShowSignImage = ZBRuntime.SDK.DHL.ShowSignImage(cateid, billdate, catename, Application, request, Server,  conn)
	end function
	Function GetIdentity(ByVal tableName,ByVal fieldName,ByVal addPerson,ByVal connStr)
		Dim r : r = sdk.setup.GetIdentity(tableName,fieldName,addPerson)
		if r = 0 then err.raise 908, "GetIdentity", sdk.LastError
		GetIdentity = r
	end function
	Function strSubtraction(strOri, strComb, strSplit) '从集合中剔除一个元素, 如：strSubtraction("a,b,c","b",",")="a,c"
		Dim f_str : f_str = Replace(strSplit&strOri&strSplit, strSplit&strComb&strSplit, strSplit)
		If Left(f_str, Len(strSplit)) = strSplit Then f_str = Right(f_str, Len(f_str) - Len(strSplit))
'Dim f_str : f_str = Replace(strSplit&strOri&strSplit, strSplit&strComb&strSplit, strSplit)
		If Right(f_str, Len(strSplit)) = strSplit Then f_str = Left(f_str, Len(f_str) - Len(strSplit))
'Dim f_str : f_str = Replace(strSplit&strOri&strSplit, strSplit&strComb&strSplit, strSplit)
		strSubtraction = f_str
	end function
	Sub clearBHTempRec(bhConfigId,dbconn)
		dbconn.execute "delete BHTempTable where configId="&bhConfigId&" and addCate=" & sdk.user
	end sub
	dim  LongRequestObj
	Set LongRequestObj = nothing
	Function LongRequest(byval urlparams)
		Dim longurlid : longurlid = CLng("0" & request.querystring("__sys_LongUrlParamsID"))
		Dim vvvv  :  vvvv = request.querystring(urlparams)
		If Len(vvvv) >0  Then LongRequest = vvvv : Exit Function
		If LongRequestObj Is Nothing Then
			Dim rs   :  Set rs = conn.execute("select ParamsData from erp_sys_UrlBigParamCaches where ID=" & longurlid )
			If rs.eof = False Then
				Dim json  :   json   = rs(0).value & ""
				If Len(json) > 0 Then
					Dim p :  Set p = server.createobject("MSScriptControl.ScriptControl")
					p.Language = "jscript"
					set  LongRequestObj = p.Eval("(" & json & ")")
					Set p = Nothing
				end if
			end if
			rs.close
			set rs = nothing
		end if
		If Not LongRequestObj Is Nothing Then
			Dim o
			For Each o in LongRequestObj
				If LCase(o.n) = LCase(urlparams) Then
					LongRequest = o.v
				end if
			next
		end if
	end function
	function  CreatefilterSqlLongRquest(byval filtersql)
		dim uid , rs, b64, SrcSign
		SrcSign = request.ServerVariables("URL")
		set b64 =  sdk.base64
		uid = session("personzbintel2007")
		conn.execute "delete erp_sys_UrlBigParamCaches where userid=" & uid &" and SrcSign='"& SrcSign &"'"
		set rs = server.CreateObject("adodb.recordset")
		rs.Open "select * from erp_sys_UrlBigParamCaches where ID<0",  conn, 1,  3
		rs.AddNew
		rs.Fields("userid").value = uid
		rs.Fields("indate").value = now
		rs.Fields("SrcSign").value = SrcSign
		rs.Fields("ParamsData").value =  "[{n:""afv_existssql"",v:""urlencode.utf8:" & Server.URLEncode(filtersql) & """}]"
		rs.update
		CreatefilterSqlLongRquest = rs("id").value
		rs.close
		set rs = nothing
	end function
	Function shortKey
		dim urls , p , i, mshortKey : mshortKey = ""
		urls = replace(request.ServerVariables("PATH_TRANSLATED"),server.mappath(sysCurrPath),"")
		urls = split(urls ,"\")
		for i = 1 to ubound(urls) - 1
'urls = split(urls ,"\")
			p = p & left(urls(i),1) & right(urls(i),1) & "_"
		next
		mshortKey = p & replace(replace(urls(ubound(urls)),".asp","",1,-1,1),".","")
'p = p & left(urls(i),1) & right(urls(i),1) & "_"
		shortKey = mshortKey
	end  Function
	Sub addDefaultScript()
		Response.write "<script type=""text/javascript"" src=""" & sysCurrPath & "Script/" & shortKey & ".js""></script>"
	end sub
	sub InitSystemVars
		hl_dot = sdk.info.hlNumber
		num1_dot = sdk.Info.floatNumber
		num_dot_xs = sdk.Info.moneyNumber
		CommPrice_dot_num = sdk.Info.CommPriceDotNum
		SalesPrice_dot_num = sdk.Info.SalesPriceDotNum
		StorePrice_dot_num = sdk.Info.StorePriceDotNum
		FinancePrice_dot_num = sdk.Info.FinancePriceDotNum
		title_xtjm = sdk.Info.title
		num_timeout = sdk.Info.TimeoutNumber
		num_cpmx_yl = sdk.info.MaxLinesNumber
		discount_dot_num = sdk.Info.DiscountNumber
		discount_max_value = sdk.Info.MaxDiscountValue
		percentWithDot=sdk.getSqlValue("select num1 from setjm3 where ord=20171221", 2)
		session.timeout=num_timeout
	end sub
	function getint(v): getint = sdk.TryNumber(v,0) : end function
	function getip: getip = sdk.vbl.getip(request): end function
	function getvirpath: getvirpath = sdk.getvirpath: end function
	function geturl: geturl = sdk.vbl.geturl(request): end function
	function browser: browser = sdk.vbl.getbrowser(request): end function
	function getattr(k): getattr = sdk.setup.attributes(k & ""): end function
	function setattr(k,nv): sdk.setup.attributes(k & "") = nv & "": end function
	function operationsystem: operationsystem = sdk.vbl.getos(request): end function
	function getkulastid(k_id): getkulastid = sdk.setup.getkulastid(k_id): end function
	function htmlarea(strcontent)
		htmlarea=Replace(sdk.setup.htmlarea(strcontent), "<tr>","<tr style='background-color:transparent'>",1,1)
'function htmlarea(strcontent)
	end function
	function acccanmodify(urd): acccanmodify=sdk.setup.acccanmodify(clng(urd)) : end function
	function getcanminus(byval bankid): getcanminus=sdk.setup.getcanminus(clng(bankid)): end function
	function conver(tmpvalue): conver=replace(trim(tmpvalue & ""),"'","''"): end function
	function isallowhandle(ByVal cid,ctime,typ): If cid&""="" Then cid=0 : End If : isallowhandle=sdk.setup.isallowhandle(CLng(cid),ctime,CLng(typ)) : end function
	function checkpurview(alls, items): checkpurview = sdk.setup.checkpurview(alls & "", items & "") : end function
	function forwardparams(exs,xtype):forwardparams=sdk.setup.forwardparams(exs&"",clng(xtype),server,request): end function
	sub add_logs(byval args): call sdk.setup.add_logs(application, session, request, server, args, action1): end sub
	function GetERPVersion: GetERPVersion=clng("0" & Replace(split(sdk.info.version & "","(")(0), ".", "")) : end function
	Function FormatInput(str)
		If Len(str&"") = 0 Then Exit Function
		Dim temp : temp = Replace(str,"""","&quot;") : FormatInput = temp
	end function
	Function GetSetJm3Value(keysign,  nullvalue)
		If isnumeric(nullvalue) And Len(nullvalue & "")>0 then
			GetSetJm3Value = sdk.setup.GetSetjm3(keysign, nullvalue)
		else
			GetSetJm3Value = sdk.setup.GetSetjm3Text(keysign, CLng("0" & nullvalue) )
		end if
	end function
	Function GetPowerValue(ByRef qxopenv, ByRef qxintrov, ByVal sort1,  ByVal sort2)
		Dim rs : set rs= conn.execute("select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=" & sort1 & " and sort2=" & sort2 & "")
		if rs.eof  Then     qxopenv=0  :  qxintrov="-222" :   rs.close :  Exit Function
		qxopenv = rs("qx_open").value : qxintrov=rs("qx_intro").value
		rs.close  : set rs=nothing
	end function
	function CNumberList(byval listvalue)
		dim r, i , n :  r = ""
		listvalue = split(replace(listvalue & ""," ",""), ",")
		for i = 0 to ubound(listvalue)
			n = listvalue(i)
			if len(n)>0 and isnumeric(n) then
				if len(r)>0 then r = r & ","
				r = r & n
			end if
		next
		CNumberList = r
	end function
	function GetUserIdsByOrgsID(byval w1)
		dim sql , ids
		ids = ""
		sql = "select x.id  from orgs_parts x inner join (" & _
		"  select fullids from orgs_parts  where '," + replace(w1, " ","") + ",%'  like '%,' + cast(ID as varchar(12)) + ',%'" & _
		") y on charindex(y.fullids+',',  x.fullids+',')=1"
		set rs = conn.execute(sql)
		while rs.eof = false
			if len(ids)>0 then ids =  ids & ","
			ids = ids & rs(0).value
			rs.movenext
		wend
		rs.close
		if len(ids) = 0 then ids = "-1"
		ids = ids & rs(0).value
		ids = "select ord from gate where orgsid in ("& ids &")"
		GetUserIdsByOrgsID = ids
	end function
	Class regExistsFilesProxy
		Public cn, conn
		public function init
			Set cn = server.CreateObject("adodb.connection")
			cn.open Application("_sys_connection")
			Set conn = cn
			Set init = Server.createobject(ZBRLibDLLNameSN & ".commClass")
			init.init me
		end function
		Public Sub cls
			cn.close
			Set cn = Nothing
			Set conn = Nothing
			Set sdk = nothing
		end sub
	End Class
	Sub writeCommHeaderJScript
		Dim szmx: szmx = sdk.Attributes("uizoom")
		If szmx="" Then szmx = "1"
		Response.write "" & vbcrlf & "<script type=""text/javascript"">" & vbcrlf & "        var getIEVer = function () {" & vbcrlf & "            var browser = navigator.appName;" & vbcrlf & "                if(window.ActiveXObject && top.document.compatMode==""BackCompat"") {return 5;}" & vbcrlf & "             var b_version = navigator.appVersion;" & vbcrlf & "             var version = b_version.split("";"");" & vbcrlf & "               if(document.documentMode && isNaN(document.documentMode)==false) { return document.documentMode; }" & vbcrlf & "              if (window.ActiveXObject) {" & vbcrlf & "                     var v = version[1].replace(/[ ]/g, """");" & vbcrlf & "                   if (v == ""MSIE10.0"") {return 10;}" & vbcrlf & "                        if (v == ""MSIE9.0"") {return 9;}" & vbcrlf & "                   if (v == ""MSIE8.0"") {return 8;}" & vbcrlf & "                   if (v == ""MSIE7.0"") {return 7;}" & vbcrlf & "                   if (v == ""MSIE6.0"") {return 6;}" & vbcrlf & "                   if (v == ""MSIE5.0"") {return 5;" & vbcrlf & "                    } else {return 11}" & vbcrlf & "         }" & vbcrlf & "               else {" & vbcrlf & "                  return 100;" & vbcrlf & "             }" & vbcrlf & "       };" & vbcrlf & "      try{ document.getElementsByTagName(""html"")[0].className = ""IE"" + getIEVer() ; } catch(exa){}" & vbcrlf & "        window.uizoom = "
'If szmx="" Then szmx = "1"
		Response.write szmx
		Response.write ";" & vbcrlf & "    if( (top==window ||  (top.app && top.app.IeVer>=100) ) && uizoom!=1){document.write(""<style>body{position:relative;zoom:"" + window.uizoom + ""}</style>"");}" & vbcrlf & "  window.sysConfig = {BrandIndex:"""
'Response.write szmx
		Response.write application("sys.info.configindex")
		Response.write """, floatnumber:"
		Response.write num1_dot
		Response.write ",moneynumber:"
		Response.write num_dot_xs
		Response.write ",CommPriceDotNum:"
		Response.write CommPrice_dot_num
		Response.write ",SalesPriceDotNum:"
		Response.write SalesPrice_dot_num
		Response.write ",StorePriceDotNum:"
		Response.write StorePrice_dot_num
		Response.write ",FinancePriceDotNum:"
		Response.write FinancePrice_dot_num
		Response.write ",discountMaxLimit:"
		Response.write DISCOUNT_MAX_VALUE
		Response.write ",discountDotNum:"
		Response.write DISCOUNT_DOT_NUM
		Response.write ",hlDotNum:"
		Response.write hl_dot
		Response.write ",percentDotNum:"
		Response.write percentWithDot
		Response.write "};" & vbcrlf & "   window.sysCurrPath = """
		Response.write sysCurrPath
		Response.write """;" & vbcrlf & "        window.currUser = """
		Response.write sdk.user
		Response.write """;" & vbcrlf & "        window.SessionId ="""
		Response.write session("SessionID")
		Response.write """;" & vbcrlf & "        window.nowTime = """
		Response.write now()
		Response.write """;" & vbcrlf & "        window.nowDate = """
		Response.write date()
		Response.write """;" & vbcrlf & "        window.syssoftversion = """
		Response.write Application("__sys_soft_ver")
		Response.write """" & vbcrlf & " window.currForm = """
		if len(request.form) < 1000 then Response.write replace(request.form,"""","\""")
		Response.write """;" & vbcrlf & "        window.currQueryString = """
		Response.write replace(replace(request.querystring,"\","\\"),"""","\""")
		Response.write """;" & vbcrlf & "        window.ConflictPageUrllist = """
		Response.write ConflictPageUrllist
		Response.write """; //冲突的页面" & vbcrlf & "   "
		Dim PATH_INFO : PATH_INFO = Request.ServerVariables("PATH_INFO")
		if instr(1,PATH_INFO,"/tongji/",1)>0 or instr(1,PATH_INFO,"/out/",1)>0 then
			Response.write "" & vbcrlf & "     window.isGatherListPage=1;" & vbcrlf & "      "
		end if
		Response.write "" & vbcrlf & "     document.title="""
		Response.write replace(title_xtjm,"""","\""")
		Response.write """" & vbcrlf & "</script>" & vbcrlf & ""
	end sub
	Function IsNetProduce()
		Dim jm2017112116 : jm2017112116 = GetSetJm3Value(2017112116, 0)
		if ZBRuntime.MC(35000) = False  And ZBRuntime.MC(18100)=false Then
			jm2017112116 = -1
'if ZBRuntime.MC(35000) = False  And ZBRuntime.MC(18100)=false Then
		else
			If ZBRuntime.MC(35000) = False Then
				jm2017112116 = 0
			ElseIf  ZBRuntime.MC(18100)=false and ZBRuntime.MC(18600)=false Then
				jm2017112116 = 1
			end if
		end if
		IsNetProduce = jm2017112116
	end function
	Response.Charset="UTF-8"
'IsNetProduce = jm2017112116
	Response.ExpiresAbsolute = Now() - 1
'IsNetProduce = jm2017112116
	Response.Expires = 0
	Response.CacheControl = "no-cache"
'Response.Expires = 0
	Response.AddHeader "Pragma", "No-Cache"
'Response.Expires = 0
	Dim sysCurrPath : sysCurrPath = SDK.GetVirPath
	Dim conn, server_1, user_1, pw_1, sql_1, ConflictPageUrllist, title_xtjm, hl_dot,percentWithDot, IsAjaxRequest
	Dim num1_dot,num_dot_xs,num_timeout,num_cpmx_yl,discount_max_value,discount_dot_num,CommPrice_dot_num,SalesPrice_dot_num,StorePrice_dot_num,FinancePrice_dot_num
	IsAjaxRequest = GetAjaxRequest()
	Call ConflictProcHandle
	Call CreateSqlConnection
	If sdk.Setup.UserLoginCheck = False Then
		Response.end
	else
		if conn.Execute("select 1 from gate with(nolock) where del=1 and ord=" & CLng("0" & session("personzbintel2007")) ).eof then
			Response.write "<script>alert(""账号已经删除或冻结，请重新登录！"");top.location.href ='" & sdk.GetVirPath & "index2.asp';</script>"
		end if
	end if
	Call checkSuperDog(conn, "../", False)
	Call InitSystemVars
	If Len(Application("systemstate")&"")>0 Then
		If Application("systemstate")="2" And Application("systemlockid")<>sdk.user Then
			Response.write "<script>alert(""系统维护中，请稍后再试！""); </script>"
			call db_close : Response.end
		end if
	end if
	set rs2t=server.CreateObject("adodb.recordset")
	sql2t="select sort1,qx_open,w1,w2,w3 from power2  where cateid="&session("personzbintel2007")&" and sort1 in(1,2,3,4) and qx_open=1"
	rs2t.open sql2t,conn,1,1
	While rs2t.eof = False
		zzjg_open_1_1=rs2t("qx_open") : zzjg_sort1=rs2t("sort1")
		zzjg_w1_list=rs2t("w1")
		zzjg_w2_list=rs2t("w2")
		zzjg_w3_list=rs2t("w3")
		If zzjg_open_1_1&"" = "1" Then
			If Trim(replace(zzjg_w1_list&"",",",""))="" Or Trim(replace(zzjg_w2_list&"",",",""))="" Or Trim(replace(zzjg_w3_list&"",",",""))="" Then
				If Trim(replace(zzjg_w1_list&"",",","")) = "" Then zzjg_w1_list = "-222"
				If Trim(replace(zzjg_w2_list&"",",","")) = "" Then zzjg_w2_list = "-222"
				If Trim(replace(zzjg_w3_list&"",",","")) = "" Then zzjg_w3_list = "-222"
				conn.execute("update power2 set w1='"& zzjg_w1_list &"', w2='"& zzjg_w2_list &"', w3='"& zzjg_w3_list &"'  where cateid="&session("personzbintel2007")&" and sort1="& zzjg_sort1)
			end if
		end if
		rs2t.movenext
	wend
	rs2t.close
	set rs2t=Nothing
	Dim tp: tp=0
	set rs2t=server.CreateObject("adodb.recordset")
	sql2t="select qx_open from power where ord="& sdk.user &" and sort1=74 and sort2=12"
	rs2t.open sql2t,conn,1,1
	if not rs2t.eof Then tp = 1-Abs(rs2t("qx_open")=0)
'rs2t.open sql2t,conn,1,1
	rs2t.close
	set rs2t=nothing
	session("sys_userlastvistime") = now()
	If HasSysTongJiJoinPage & "" = "1" Then Call DoSysTongJiJoinPageProc(0)
	If IsAjaxRequest=False Then
		dim bigsystemtype : bigsystemtype = ""
		if application("sys.info.configindex")  = "3" then
			bigsystemtype = ".mozi"
		end if
		Response.write "<!Doctype html><html>" & vbcrlf & "<head>" & vbcrlf & "<meta http-equiv=""X-UA-Compatible"" content =""IE=edge,chrome=1"">" & vbcrlf & "<meta name=""vs_targetSchema"" content=""http://schemas.microsoft.com/intellisense/ie5""/>" & vbcrlf & "<meta http-equiv=""Content-Type"" content=""text/html; charset=UTF-8"">" & vbcrlf & "<meta name=""format-detection"" content=""telephone=no"">" & vbcrlf & ""
'bigsystemtype = ".mozi"
		call WriteCommHeaderJScript
		Response.write "" & vbcrlf & "<script type=""text/javascript"" src='"
		Response.write sysCurrPath
		Response.write "inc/dateid.js?ver="
		Response.write Application("sys.info.jsver")
		Response.write "'></script>" & vbcrlf & "<script type=""text/javascript"" src='"
		Response.write sysCurrPath
		Response.write "inc/setup.js?ver="
		Response.write Application("sys.info.jsver")
		Response.write "'></script>" & vbcrlf & "<script type=""text/javascript"" src="""
		Response.write sysCurrPath
		Response.write "inc/jQuery-1.7.2.min.js?ver="
		Response.write sysCurrPath
		Response.write Application("sys.info.jsver")
		Response.write """></script>" & vbcrlf & ""
		Response.write "" & vbcrlf & "<script type=""text/javascript"" src="""
		Response.write sysCurrPath
		Response.write "inc/UiSkinV3179"
		Response.write bigsystemtype
		Response.write ".js?ver="
		Response.write Application("sys.info.jsver")
		Response.write """></script>" & vbcrlf & "<script type=""text/javascript"" src="""
		Response.write sysCurrPath
		Response.write "Script/inc_setup.js?ver="
		Response.write Application("sys.info.jsver")
		Response.write """></script>" & vbcrlf & ""
		If request.querystring("__fReclst")="1" Then
			Response.write "<style>input.anybutton, input.anybutton2 {display:none} </style>"
			Response.write "<script defer src='" & sysCurrPath & "back/autohidecontentbtn.js?ver=" & Application("sys.info.jsver") & "'></script>"
		end if
		Response.write "<script type=""text/javascript"" src=""" & sysCurrPath & "inc/jquery-autobh.js?ver=" & Application("sys.info.jsver") & """></script>" & vbcrlf
		Response.write "</head>"
	end if
	dim AppDataVersion : AppDataVersion= Application("sys.info.jsver")
	AppDataVersion = split(AppDataVersion&".",".")(0)
	if AppDataVersion&""="" then AppDataVersion = "3100"
	if len(AppDataVersion)>4 then  AppDataVersion = left(AppDataVersion, 4)
	Response.write "" & vbcrlf & "<noscript></noscript>"
	
	set rs1=server.CreateObject("adodb.recordset")
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=6 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_6_1=0
		intro_6_1=0
	else
		open_6_1=rs1("qx_open")
		intro_6_1=rs1("qx_intro")
	end if
	rs1.close
	set rs1=nothing
	set rs1=server.CreateObject("adodb.recordset")
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=6 and sort2=17"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_6_17=0
		intro_6_17=0
	else
		open_6_17=rs1("qx_open")
		intro_6_17=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=6 and sort2=11"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_6_11=0
		intro_6_11=0
	else
		open_6_11=rs1("qx_open")
		intro_6_11=rs1("qx_intro")
	end if
	rs1.close
	If intro_6_11&"" = "" Then intro_6_11 = 0
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=6 and sort2=20"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_6_20=0
		intro_6_20=0
	else
		open_6_20=rs1("qx_open")
		intro_6_20=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=6 and sort2=21"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_6_21=0
		intro_6_21=0
	else
		open_6_21=rs1("qx_open")
		intro_6_21=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=6 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_6_14=0
		intro_6_14=0
	else
		open_6_14=rs1("qx_open")
		intro_6_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=6 and sort2=3"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_6_3=0
		intro_6_3=0
	else
		open_6_3=rs1("qx_open")
		intro_6_3=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=6 and sort2=7"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_6_7=0
		intro_6_7=0
	else
		open_6_7=rs1("qx_open")
		intro_6_7=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=6 and sort2=8"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_6_8=0
		intro_6_8=0
	else
		open_6_8=rs1("qx_open")
		intro_6_8=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=6 and sort2=10"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_6_10=0
		intro_6_10=0
	else
		open_6_10=rs1("qx_open")
		intro_6_10=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=6 and sort2=13"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_6_13=0
		intro_6_13=0
	else
		open_6_13=rs1("qx_open")
		intro_6_13=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=6 and sort2=16"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_6_16=0
		intro_6_16=0
	else
		open_6_16=rs1("qx_open")
		intro_6_16=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=1 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_1_14=0
		intro_1_14=0
	else
		open_1_14=rs1("qx_open")
		intro_1_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=1 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_1_1=0
		intro_1_1=0
	else
		open_1_1=rs1("qx_open")
		intro_1_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=2 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_2_14=0
		intro_2_14=0
	else
		open_2_14=rs1("qx_open")
		intro_2_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=2 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_2_1=0
		intro_2_1=0
	else
		open_2_1=rs1("qx_open")
		intro_2_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=3 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_3_14=0
		intro_3_14=0
	else
		open_3_14=rs1("qx_open")
		intro_3_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=3 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_3_1=0
		intro_3_1=0
	else
		open_3_1=rs1("qx_open")
		intro_3_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=5 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_5_14=0
		intro_5_14=0
	else
		open_5_14=rs1("qx_open")
		intro_5_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=5 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_5_1=0
		intro_5_1=0
	else
		open_5_1=rs1("qx_open")
		intro_5_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=22 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_22_14=0
		intro_22_14=0
	else
		open_22_14=rs1("qx_open")
		intro_22_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=22 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_22_1=0
		intro_22_1=0
	else
		open_22_1=rs1("qx_open")
		intro_22_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=33 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_33_14=0
		intro_33_14=0
	else
		open_33_14=rs1("qx_open")
		intro_33_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=33 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_33_1=0
		intro_33_1=0
	else
		open_33_1=rs1("qx_open")
		intro_33_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=41 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_41_1=0
		intro_41_1=0
	else
		open_41_1=rs1("qx_open")
		intro_41_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=41 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_41_14=0
		intro_41_14=0
	else
		open_41_14=rs1("qx_open")
		intro_41_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=75 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_75_1=0
		intro_75_1=0
	else
		open_75_1=rs1("qx_open")
		intro_75_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=75 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_75_14=0
		intro_75_14=0
	else
		open_75_14=rs1("qx_open")
		intro_75_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=71 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_71_14=0
		intro_71_14=0
	else
		open_71_14=rs1("qx_open")
		intro_71_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=71 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_71_1=0
		intro_71_1=0
	else
		open_71_1=rs1("qx_open")
		intro_71_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=42 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_42_14=0
		intro_42_14=0
	else
		open_42_14=rs1("qx_open")
		intro_42_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=42 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_42_1=0
		intro_42_1=0
	else
		open_42_1=rs1("qx_open")
		intro_42_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=26 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_26_14=0
		intro_26_14=0
	else
		open_26_14=rs1("qx_open")
		intro_26_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=26 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_26_1=0
		intro_26_1=0
	else
		open_26_1=rs1("qx_open")
		intro_26_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=101 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_101_1=0
		intro_101_1=0
	else
		open_101_1=rs1("qx_open")
		intro_101_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=101 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_101_14=0
		intro_101_14=0
	else
		open_101_14=rs1("qx_open")
		intro_101_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=102 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_102_1=0
		intro_102_1=0
	else
		open_102_1=rs1("qx_open")
		intro_102_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=102 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_102_14=0
		intro_102_14=0
	else
		open_102_14=rs1("qx_open")
		intro_102_14=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=103 and sort2=1"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_103_1=0
		intro_103_1=0
	else
		open_103_1=rs1("qx_open")
		intro_103_1=rs1("qx_intro")
	end if
	rs1.close
	sql1="select qx_open,qx_intro from power  where ord="&session("personzbintel2007")&" and sort1=103 and sort2=14"
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_103_14=0
		intro_103_14=0
	else
		open_103_14=rs1("qx_open")
		intro_103_14=rs1("qx_intro")
	end if
	rs1.close
	set rs1=nothing
	if open_6_1=3 then
		list=""
	elseif open_6_1=1 then
		list="and cateid in ("&intro_6_1&")"
	else
		list="and cateid=-1"
		list="and cateid in ("&intro_6_1&")"
	end if
	Str_Result="where del=1 "&list&""
	Str_Result2="and del=1 "&list&""
	
	Function GetW3Core(ByVal strW1,ByVal strW2, ByVal strW3, ByVal deltype)
		dim rs, orgsid, sql
		If Len(strW3) > 0 And strW3<>"0" then
			If InStr(1,strW3,"select",1) > 0 Then
				GetW3Core = strW3
				Exit function
			end if
			strW3 = Replace(strW3 & "", " ", "")
			strW3 = Replace(strW3, ",,", ",")
			strW3 = Replace(Replace("?" & strW3 & "?", "?,", ""),",?","")
			strW3 = Replace(strW3,"?","")
			If strW3 = "" Then strW3 = "0"
			GetW3Core=strW3
			Exit function
		else
			if len(strW2) > 0 And strW2<>"0" Then
				sql = "select ord from gate where orgsid in ("& strW2 &") or ('"& strW1&"'='999999999' and orgsid=0)"
			else
				if len(strW1) > 0 And strW1<>"0" Then
					strW3 = ""
					orgsid =  Replace(("," & Replace(strW1 & "," & strW2, " ", ",")  & ","), ",0,",",")
					dim ids :ids = ""
					sql = "select x.id  from orgs_parts x inner join (" & _
					"   select fullids from orgs_parts  where '," + replace(orgsid, " ","") + ",%'  like '%,' + cast(ID as varchar(12)) + ',%'" & _
					") y on charindex(y.fullids+',',  x.fullids+'," & _
					"set rs = conn.execute(sql)"
					while rs.eof = false
						if len(ids)>0 then ids =  ids & ","
						ids = ids & rs(0).value
						rs.movenext
					wend
					rs.close
					if len(ids) = 0 then ids = "-1"
					ids = ids & rs(0).value
					if strW1&""="" then strW1 = 0
					if instr(strW1,"-")>0 then ids = replace(strW1,"-","")
'if strW1&""="" then strW1 = 0
					sql = "select ord from gate where orgsid in ("& ids &") or ('"& strW1 &"'='999999999' and orgsid=0)"
				else
					GetW3Core = "0"
					Exit function
				end if
			end if
		end if
		set rs = conn.execute(sql)
		While rs.eof= False
			If Len(strW3)>0 Then  strW3 = strW3 & ","
			strW3 = strW3 & rs(0).value
			rs.movenext
		wend
		rs.close
		if strW1&""="999999999" then
			If Len(strW3)>0 Then strW3 = strW3 & ","
			strW3 = strW3 & "0"
		end if
		GetW3Core=strW3
	end function
	function getW3(ByVal strW1,ByVal strW2, ByVal strW3)
		getW3=GetW3Core(strW1, strW2, strW3, "1")
	end function
	function getLimitedW3(strw3,stype,sort1,sort2,cid)
		dim i,sql
		if (stype<>1 and stype<>2) or not isnumeric(sort1) or not isnumeric(sort2) or not isnumeric(cid) then
			Response.write "参数错误"
			call db_close : Response.end
		end if
		Dim fw1,fw2,fw3,pw3,qx_open,tmpW3,tmp,rs
		fw1=replace(request("w1")," ","")
		fw2=replace(request("w2")," ","")
		fw3=replace(request("w3")," ","")
		if fw3<>"" and fw3<>"0" and (fw1="" or fw1="0") and (fw2="" or fw2="0") and isnumeric(fw3) and instr(fw3,",")<=0 then
			getLimitedW3=strw3
		else
			if strw3="-1" or strw3="0" Or strw3&""="" then
				getLimitedW3=strw3
				getLimitedW3=strW3
			else
				if stype=1 then
					sql="select qx_open,qx_intro from power where sort1="&sort1&" and sort2="&sort2&" and ord="& cid
				elseif stype=2 then
					sql="select qx_open,w3 from power2 where sort1="&sort1&" and cateid="& cid
				end if
				set rs=conn.execute(sql)
				if not rs.eof then
					qx_open=rs(0)
					pw3=replace(rs(1)," ","")
				else
					qx_open=0
					pw3=""
				end if
				rs.close
				if qx_open="1" then
					tmp=split(strw3,",")
					tmpW3=""
					for i=0 to ubound(tmp)
						if instr(1,","&pw3&",",","&tmp(i)&",")>0 then
							if tmpW3="" then
								tmpW3=tmp(i)
							else
								tmpW3=tmpW3&","&tmp(i)
							end if
						end if
					next
					if ((fw1<>"" And fw1<>"0") or (fw2<>"" And fw2<>"0") or (fw3<>"" And fw3<>"0")) and replace(replace(tmpW3," ",""),"0","")="" then tmpW3="-1"
					tmpW3=tmpW3&","&tmp(i)
					getLimitedW3=tmpW3
				elseif qx_open="0" then
					getLimitedW3="-1"
'elseif qx_open="0" then
				elseif qx_open="3" then
					getLimitedW3=strw3
				end if
			end if
		end if
	end function
	function getW1W2(strW3)
		dim rtnW1,rtnW2,frs,fsql, strW3s
		rtnW1=""
		rtnW2=""
		If InStr(strW3,"|") >0 Then strW3s = Split(strW3, "|"):   strW3 = strW3s(ubound(strW3s))
		strW3 = Replace(","&Trim(strW3)&",",",0,",",")
		If Left(strW3,1)="," Then strW3=Right(strW3,Len(strW3)-1)
'strW3 = Replace(","&Trim(strW3)&",",",0,",",")
		If right(strW3,1)="," Then strW3=left(strW3,Len(strW3)-1)
'strW3 = Replace(","&Trim(strW3)&",",",0,",",")
		if strW3<>"" Then
			fsql="select distinct sorce from gate where charindex(','+cast(ord as varchar(10))+',',',"&strW3&",')>0 and sorce>=0"
'if strW3<>"" Then
			set frs=conn.execute(fsql)
			while not frs.eof
				if rtnW1="" then
					rtnW1=frs(0)
				else
					rtnW1=rtnW1&","&frs(0)
				end if
				frs.movenext
			wend
			frs.close
			fsql="select distinct sorce2 from gate where charindex(','+cast(ord as varchar(10))+',',',"&strW3&",')>0 and sorce2>=0"
			frs.close
			set frs=conn.execute(fsql)
			while not frs.eof
				if rtnW2="" then
					rtnW2=frs(0)
				else
					rtnW2=rtnW2&","&frs(0)
				end if
				frs.movenext
			wend
			frs.close
		end if
		if rtnW1="" then rtnW1="0"
		if rtnW2="" then rtnW2="0"
		getW1W2=rtnW1&";"&rtnW2
	end function
	function getW3WithLock(strW1,strW2,strW3)
		getW3WithLock=GetW3Core(strW1, strW2, strW3, "1,2,3")
	end function
	function CheckPurview(AllPurviews,strPurview)
		if isNull(AllPurviews) or AllPurviews="" or strPurview="" then
			CheckPurview=False
			exit function
		end if
		CheckPurview=False
		if instr(AllPurviews,",")>0 then
			dim arrPurviews,i77
			arrPurviews=split(AllPurviews,",")
			for i77=0 to ubound(arrPurviews)
				if trim(arrPurviews(i77))=strPurview then
					CheckPurview=True
					exit for
				end if
			next
		else
			if AllPurviews=strPurview then
				CheckPurview=True
			end if
		end if
	end function
	
	ZBRLibDLLNameSN = "ZBRLib3205"
	Sub noCache
		Response.ExpiresAbsolute = #2000-01-01#
'Sub noCache
		Response.AddHeader "pragma", "no-cache"
'Sub noCache
		Response.AddHeader "cache-control", "private, no-cache, must-revalidate"
'Sub noCache
	end sub
	Sub echo(Byval str)
		Response.write(str)
		response.Flush()
	end sub
	Sub die(Byval str)
		if not isNul(str) then
			echo str
		end if
		call db_close : Response.end()
	end sub
	Function IsNum(Str)
		IsNum=False
		If Str<>"" then
			If RegTest(Str,"^[\d]+$")=True Then
'If Str<>"" then
				IsNum=True
			end if
		end if
	end function
	Function IsMoney(Str)
		IsMoney=False
		If Str<>"" then
			If RegTest(Str,"^[\d]+\.?[\d]+?$")=True Then
'If Str<>"" then
				IsMoney=True
			end if
		end if
	end function
	Function IsNegMoney(Str)
		IsNegMoney=False
		If Str<>"" then
			If RegTest(Str,"^\-[\d]+\.?[\d]+?$")=True Then
'If Str<>"" then
				IsNegMoney=True
			end if
		end if
	end function
	Function isNul(Byval str)
		if isnull(str) then
			isNul = true : exit function
		else
			if isarray(str) then isNul = false : exit function
			if str= "" then
				isNul = true : exit function
			else
				isNul = false : exit function
			end if
		end if
	end function
	Sub closers(byval rsobj)
		if isobject(rsobj) then
			rsobj.close
			set rsobj =nothing
		end if
	end sub
	Function getrsval(Byval sqlstr)
		dim rs
		set rs = conn.execute (sqlstr)
		if rs.eof then
			getrsval = ""
		else
			If isnumeric(rs(0)) Then
				getrsval = zbcdbl(rs(0))
			else
				getrsval = rs(0)
			end if
		end if
		call closers(rs)
	end function
	Function getrs(Byval sqlstr)
		set getrs = server.CreateObject("adodb.recordset")
		getrs.open sqlstr ,conn,1,3
	end function
	Function getrsArray(Byval sqlstr)
		set rsobj = getrs(sqlstr)
		if not rsobj.eof then
			getrsArray = rsobj.getrows
		end if
		call closers(rsobj)
	end function
	Function closeconn
		if isobject(conn) then
			conn.close
			set conn =nothing
		end if
	end function
	Function jsStr(Byval str)
		jsStr = "<script language=""JavaScript"" type=""text/javascript"">"&str&"</script>"
	end function
	Function alert(Byval str)
		alert = jsStr("alert("""&str&""")")
	end function
	Function alertgo(Byval str,Byval url)
		alertgo = alert(str)&jsStr("location.href="""&url&"""")
	end function
	Function confirm(Byval str,Byval url1,Byval url2)
		confirm = jsstr("if(confirm("""&str&""")){location.href="""&url1&"""}else{location.href="""&url2&"""}")
	end function
	Function jsPageGo(Byval page)
		if isnumeric(page) then
			jsPageGo = jsStr("history.go("&page&")")
		else
			jsPageGo = jsStr("location.href="""&page&"""")
		end if
	end function
	Function Historyback(msg)
		Historyback=JavaScriptSet("alert('"& msg &"');history.go(-1)")
'Function Historyback(msg)
	end function
	Function jspageback
		jspageback = jsPageGo(-1)
'Function jspageback
	end function
	Function JavaScriptSet(str)
		JavaScriptSet = "<script language=""JavaScript"" type=""text/javascript"">"&str&"</script>"
	end function
	function CloseSelf(msg)
		CloseSelf=JavaScriptSet("try{alert('"&Replace(msg,"'","")&"'); window.opener=null;window.open('','_self');window.close();}catch(e){}")
	end function
	function ReloadCloseSelf(msg)
		ReloadCloseSelf=JavaScriptSet("alert('"&Replace(msg,"'","")&"'); try{window.opener.location.reload();}catch(e1){} try{window.opener=null;window.open('','_self');window.close();}catch(e){}")
	end function
	function strLength(str)
		on error resume next
		dim WINNT_CHINESE
		WINNT_CHINESE    = (len("中国")=2)
		if WINNT_CHINESE then
			dim l,t,c
			dim i
			l=len(str)
			t=l
			for i=1 to l
				c=asc(mid(str,i,1))
				if c<0 then c=c+65536
'c=asc(mid(str,i,1))
				if c>255 then
					t=t+1
'if c>255 then
				end if
			next
			strLength=t
		else
			strLength=len(str)
		end if
		if err.number<>0 then err.clear
	end function
	function checkphone(str,num_code)
		dim arr_num,tmpnum,tmparr,areacode
		dim i
		if trim(str)="" or isnull(str) then exit function
		str=replace(replace(str,"/","-"),"\","-")
'if trim(str)="" or isnull(str) then exit function
		arr_num=split(str,"-")
'if trim(str)="" or isnull(str) then exit function
		tmpnum=""
		for i=0 to ubound(arr_num)
			tmparr=arr_num(i)
			if i=0 then
				if left(tmparr,1)="0" and (len(tmparr)=3 or len(tmparr)=4) then
					areacode=tmparr
				else
					tmpnum=tmparr
				end if
			else
				if left(tmparr,3)="400" or left(tmparr,3)="800" then
					areacode=""
				elseif left(str,1)="1" and len(str)=11 then
					areacode=""
				end if
				if tmpnum="" then
					tmpnum=tmparr
				else
					tmpnum=tmpnum & "-" & tmparr
				end if
			end if
		next
		if areacode=num_code then areacode=""
		checkphone=areacode & tmpnum
	end function
	function strFreMobil(strMobil)
		strFreMobil=""
		Set rs = server.CreateObject("adodb.recordset")
		for i=4 to 11
			sql="select areacode  from MOBILEAREA where shortno like ''+substring('"&strMobil&"', 1, "&i&")+'%'"
'for i=4 to 11
			rs.open sql,conn,3,1
			if not rs.eof then
				if rs.recordcount=1 then
					strFreMobil=rs("areacode")
					rs.close
					exit for
				else
					strFreMobil=""
				end if
			else
				strFreMobil=""
			end if
			rs.close
		next
		set rs=nothing
	end function
	function fenjiNum(StrNum)
		StrNum=replace(StrNum,"-",",,,,,,,,,,")
'function fenjiNum(StrNum)
		fenjiNum=StrNum
	end function
	function unfenjiNum(StrNum)
		StrNum=replace(StrNum,",,,,,,,,,,","-")
'function unfenjiNum(StrNum)
		unfenjiNum=StrNum
	end function
	Function RegTest(a,p)
		Dim reg
		RegTest=false
		Set reg = New RegExp
		reg.pattern=p
		reg.IgnoreCase = True
		If reg.test(a)Then
			RegTest=true
		else
			RegTest=false
		end if
	end function
	Function RegReplace(s,p,strReplace)
		Dim r
		Set r =New RegExp
		r.Pattern = p
		r.IgnoreCase = True
		r.Global = True
		RegReplace=r.replace(s,strReplace)
	end function
	Function GetRegExpCon(strng,patrn)
		Dim regEx, Match, Matches,RetStr
		RetStr=""
		Set regEx = New RegExp
		regEx.Pattern = patrn          ' 设置模式。'"\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*"
'Set regEx = New RegExp
		regEx.IgnoreCase = True
		regEx.Global = True
		Set Matches = regEx.Execute(strng)
		For Each Match In Matches
			if RetStr="" then
				RetStr=Match.Value
			else
				RetStr=RetStr&"$"&Match.Value
			end if
		next
		GetRegExpCon = RetStr
	end function
	function unPhone(StrNum)
		sqlci = "select callPreNum from gate where ord="&session("personzbintel2007")&""
		Set Rsci = server.CreateObject("adodb.recordset")
		Rsci.open sqlci,conn,1,1
		num_pre1=rsci("callPreNum")
		rsci.close
		set rsci=nothing
		if num_pre1<>"" then
			StrNum=RegReplace(StrNum,"^"&num_pre1&",","")
		end if
		if  RegTest(StrNum,"^0(13[0-9]|14[0-9]|15[^4]|17[0-9]|18[0-9])\d{8}$") then
			StrNum=RegReplace(StrNum,"^"&num_pre1&",","")
			StrNum=RegReplace(StrNum,"^0","")
		end if
		StrNum=unfenjiNum(StrNum)
		unPhone=StrNum
	end function
	sub strCheckBH(bhid,table,strBhID,str)
		if strBhID<>"" then
			Err.Clear
			set rs=server.CreateObject("adodb.recordset")
			sqlStr="select "&bhid&" from "&table&" where del<>7 and "&bhid&"='"&strBhID&"'"
			rs.open sqlStr,conn,1,1
			if not rs.eof then
				Response.write"<script language=javascript>alert('该"&str&"编号已存在！请返回重试');window.history.back(-1);</script>"
'if not rs.eof then
				call db_close : Response.end
			end if
			rs.close
			set rs=nothing
		end if
	end sub
	function getPersonSex(nameX,sexX)
		getPersonSex=""
		if nameX<>"" and sexX<>"" then
			if sexX="男" then
				getPersonSex=left(nameX,1)&"先生"
			elseif sexX="女" then
				getPersonSex=left(nameX,1)&"小姐"
			else
				getPersonSex=nameX
			end if
		else
			getPersonSex=nameX
		end if
	end function
	function getPersonJob(nameX,jobX)
		getPersonJob=""
		if nameX<>"" and jobX<>"" then
			if jobX<>"" then
				getPersonJob=left(nameX,1)&jobX
			else
				getPersonJob=nameX
			end if
		else
			getPersonJob=nameX
		end if
	end function
	function getNameJob(nameX,jobX)
		getNameJob=""
		if nameX<>"" and jobX<>"" then
			if jobX<>"" then
				getNameJob=nameX&jobX
			else
				getNameJob=nameX
			end if
		else
			getNameJob=nameX
		end if
	end function
	function isMobile(num1)
		isMobile=false
		if num1<>"" then
			isMobile=RegTest(num1,"^(13[0-9]|14[0-9]|15[^4]|16[0-9]|17[0-9]|18[0-9]|19[0-9])\d{8}$")
'if num1<>"" then
		else
			isMobile=false
		end if
	end function
	function myReplace(fString)
		myString=""
		if fString<>"" then
			myString=Replace(fString,"&","&amp;")
			myString=Replace(myString,"<","&lt;")
			myString=Replace(myString,">","&gt;")
			myString=Replace(myString,"&nbsp;","")
			myString=Replace(myString,chr(13),"")
			myString=Replace(myString,chr(10),"")
			myString=Replace(myString,chr(32),"&nbsp")
			myString=Replace(myString,chr(9),"")
			myString=Replace(myString,chr(39),"")
			myString=Replace(myString,chr(34),"&quot;")
			myString=Replace(myString,chr(8),"")
			myString=Replace(myString,chr(11),"")
			myString=Replace(myString,chr(12),"")
			myString=Replace(myString,Chr(32),"")
			myString=Replace(myString,Chr(26),"")
			myString=Replace(myString,Chr(27),"")
		end if
		myReplace=myString
	end function
	Function RemoveHTML(strHTML)
		Dim objRegExp, Match, Matches
		Set objRegExp = New Regexp
		objRegExp.IgnoreCase = True
		objRegExp.Global = True
		objRegExp.Pattern = "<.+?>"
'objRegExp.Global = True
		Set Matches = objRegExp.Execute(strHTML)
		For Each Match in Matches
			strHtml=Replace(strHTML,Match.Value,"")
		next
		RemoveHTML=strHTML
		Set objRegExp = Nothing
	end function
	Function getTitle(str,byVal lens)
		if isnull(str) then getTitle="":exit function
		if str="" then
			getTitle="":exit function
		else
			dim str1
			str1=str
			str1=RemoveHTML(str1)
			if len(str1)=0 and len(str)>0 then str1="."
			if str1<>"" then
				str1=myReplace(str1)
				if str1<>"" then str1=replace(replace(replace(replace(replace(replace(str1,"&amp;nbsp;",""),"&amp;quot;",""),"&amp;amp;",""),"&amp;lt;",""),"&amp;gt;",""),"&nbsp","")
				if len(str)>lens then
					str1=left(str1,lens)&"."
				else
					str1=left(str1,lens)
				end if
			end if
			getTitle=str1
		end if
	end function
	Function getFirstName(str)
		getFirstName=""
		if str<>"" then
			strXing="欧阳|太史|端木|上官|司马|东方|独孤|南宫|万俟|闻人|夏侯|诸葛|尉迟|公羊|赫连|澹台|皇甫|宗政|濮阳|公冶|太叔|申屠|公孙|慕容|仲孙|钟离|长孙|宇文|司徒|鲜于|司空|闾丘|子车|亓官|司寇|巫马|公西|颛孙|壤驷|公良|漆雕|乐正|宰父|谷梁|拓跋|夹谷|轩辕|令狐|段干|百里|呼延|东郭|南门|羊舌|微生|公户|公玉|公仪|梁丘|公仲|公上|公门|公山|公坚|左丘|公伯|西门|公祖|第五|公乘|贯丘|公皙|南荣|东里|东宫|仲长|子书|子桑|即墨|达奚|褚师|吴铭"
			if instr(strXing,left(str,2))>0 then
				getFirstName=left(str,2)
			else
				getFirstName=left(str,1)
			end if
		else
			getFirstName=""
		end if
	end function
	Function NongliMonth(m)
		If m>=1 And m<=12 Then
			MonthStr=",正,二,三,四,五,六,七,八,九,十,十一,腊"
			MonthStr=Split(MonthStr,",")
			NongliMonth=MonthStr(m)
		else
			NongliMonth=m
		end if
	end function
	Function NongliDay(d)
		If d>=1 And d<=30 Then
			DayStr=",初一,初二,初三,初四,初五,初六,初七,初八,初九,初十,十一,十二,十三,十四,十五,十六,十七,十八,十九,二十,廿一,廿二,廿三,廿四,廿五,廿六,廿七,廿八,廿九,三十"
			DayStr=Split(DayStr,",")
			NongliDay=DayStr(d)
		else
			NongliDay=d
		end if
	end function
	Function htmlspecialchars(str)
		if len(str&"") = 0 then
			exit function
		end if
		str = Replace(str, "&", "&amp;")
		str = Replace(str, "&amp;#", "&#")
		str = Replace(str, "<", "&lt;")
		str = Replace(str, ">", "&gt;")
		str = Replace(str, """", "&quot;")
		htmlspecialchars = str
	end function
	function isEmail(num1)
		isEmail=false
		if num1<>"" then
			isEmail=RegTest(num1,"^$|^(\w{0,10}\[)?\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*(\])?$")
'if num1<>"" then
			if isEmail=false then
				isEmail=RegTest(num1,"^$|^([a-zA-Z0-9_\u4e00-\u9fa5]+\[)?\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*(\])?\;(([a-zA-Z0-9_\u4e00-\u9fa5]+\[)?\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*(\])?)*$")
			end if
		else
			isEmail=false
		end if
	end function
	function isobjinstalled(strclassstring)
		on error resume next
		isobjinstalled = false
		err = 0
		dim xtestobj
		set xtestobj = server.createobject(strclassstring)
		if 0 = err then isobjinstalled = true
		set xtestobj = nothing
		err = 0
	end function
	function DelAttach(sql_at)
		set rs_At=server.CreateObject("adodb.recordset")
		rs_At.open sql_at, conn,1,1
		if not rs_At.eof then
			FileName_At=server.MapPath(rs_At(0))
			set fso_At=server.CreateObject("scripting.filesystemobject")
			if fso_At.FileExists(FileName_At) then
				fso_At.DeleteFile FileName_At
			end if
			set fso_At=nothing
		end if
		rs_At.close
		set rs_At=nothing
	end function
	function DelAllAttach(sql_at)
		set rs_At=server.CreateObject("adodb.recordset")
		rs_At.open sql_at, conn,1,1
		if not rs_At.eof then
			do while not rs_At.eof
				FileName_At=server.MapPath(rs_At(0))
				set fso_At=server.CreateObject("scripting.filesystemobject")
				if fso_At.FileExists(FileName_At) then
					fso_At.DeleteFile FileName_At
				end if
				set fso_At=nothing
				rs_At.movenext
			loop
		end if
		rs_At.close
		set rs_At=nothing
	end function
	function getGateName(id)
		getGateName=""
		if id<>"" and isnumeric(id) then
			set rs_Gate=server.CreateObject("adodb.recordset")
			sql_Gate="select name from gate where  ord="&id&""
			rs_Gate.open sql_Gate,conn,1,1
			if not rs_Gate.eof then
				getGateName=rs_Gate("name")
			end if
			rs_Gate.close
			set rs_Gate=nothing
		end if
	end function
	function getSorceName(id)
		getSorceName="无"
		if id<>"" and isnumeric(id) then
			set rs_Gate=server.CreateObject("adodb.recordset")
			sql_Gate="select sort1 from gate1 where  ord="&id&""
			rs_Gate.open sql_Gate,conn,1,1
			if not rs_Gate.eof then
				getSorceName=rs_Gate("sort1")
			end if
			rs_Gate.close
			set rs_Gate=nothing
		end if
	end function
	function getSorce2Name(id)
		getSorce2Name="无"
		if id<>"" and isnumeric(id) then
			set rs_Gate=server.CreateObject("adodb.recordset")
			sql_Gate="select sort2 from gate2 where  ord="&id&""
			rs_Gate.open sql_Gate,conn,1,1
			if not rs_Gate.eof then
				getSorce2Name=rs_Gate("sort1")
			end if
			rs_Gate.close
			set rs_Gate=nothing
		end if
	end function
	function getUidSorceName(id)
		getUidSorceName="无"
		if id<>"" and isnumeric(id) then
			set rs_Gate=server.CreateObject("adodb.recordset")
			sql_Gate="select a.sort1 from gate1 a inner join gate b on a.ord=b.sorce where  b.ord="&id&" "
			rs_Gate.open sql_Gate,conn,1,1
			if not rs_Gate.eof then
				getUidSorceName=rs_Gate("sort1")
			end if
			rs_Gate.close
			set rs_Gate=nothing
		end if
	end function
	function getUidSorce2Name(id)
		getUidSorce2Name="无"
		if id<>"" and isnumeric(id) then
			set rs_Gate=server.CreateObject("adodb.recordset")
			sql_Gate="select a.sort2 from gate2 a inner join gate b on a.ord=b.sorce2 where  b.ord="&id&" "
			rs_Gate.open sql_Gate,conn,1,1
			if not rs_Gate.eof then
				getUidSorce2Name=rs_Gate("sort2")
			end if
			rs_Gate.close
			set rs_Gate=nothing
		end if
	end function
	function TbCompanyName(id)
		TbCompanyName=""
		if id<>"" and isnumeric(id) then
			set rs_Gate=server.CreateObject("adodb.recordset")
			sql_Gate="select name from tel where  ord="&id&""
			rs_Gate.open sql_Gate,conn,1,1
			if not rs_Gate.eof then
				TbCompanyName=rs_Gate("name")
			end if
			rs_Gate.close
			set rs_Gate=nothing
		end if
	end function
	function TbPersonName(id)
		TbPersonName=""
		if id<>"" and isnumeric(id) then
			set rs_Gate=server.CreateObject("adodb.recordset")
			sql_Gate="select name from person where  ord="&id&""
			rs_Gate.open sql_Gate,conn,1,1
			if not rs_Gate.eof then
				TbPersonName=rs_Gate("name")
			end if
			rs_Gate.close
			set rs_Gate=nothing
		end if
	end function
	function zbintelEmailEncode(inputstr,inputtype,rdNum)
		tmpstr=""
		if inputtype=1 then
			for i=1 to len(inputstr)
				tmpstr=tmpstr&emailgetChar(mid(inputstr,i,1),inputtype,rdNum)
			next
		else
			inputstr=replace(inputstr,"%","$")
			inputstr=replace(inputstr,"*","$")
			inputstr=replace(inputstr,"#","$")
			inputstr=replace(inputstr,"@","$")
			inputstr=replace(inputstr,"a","$")
			inputstr=replace(inputstr,"b","$")
			inputstr=replace(inputstr,"c","$")
			inputstr=replace(inputstr,"d","$")
			inputstr=replace(inputstr,"e","$")
			inputstr=replace(inputstr,"f","$")
			inputstr=replace(inputstr,"g","$")
			inputstr=replace(inputstr,"h","$")
			inputstr=replace(inputstr,"i","$")
			inputstr=replace(inputstr,"j","$")
			inputstr=replace(inputstr,"k","$")
			inputstr=replace(inputstr,"l","$")
			inputstr=replace(inputstr,"m","$")
			inputstr=replace(inputstr,"n","$")
			if instr(inputstr,"$")>0 then
				arrStr=split(inputstr,"$")
				for i=0 to Ubound(arrStr)-1
					arrStr=split(inputstr,"$")
					Response.write(arrStr(i)&"<br/>")
					tmpstr=tmpstr&Chr(arrStr(i)-rdNum)
					Response.write(arrStr(i)&"<br/>")
				next
			end if
		end if
		zbintelEmailEncode=tmpstr
	end function
	function emailgetChar(inputchar,chartype,rdNum)
		if inputchar<>"" then
			emailgetChar=(asc(inputchar)+rdNum)&randomStr(1)
'if inputchar<>"" then
		else
			emailgetChar=""
		end if
	end function
	Function randomStr(intLength)
		strSeed = "$%*#@abcdefghijklmn"
		seedLength = Len(strSeed)
		Str = ""
		Randomize
		For i = 1 To intLength
			Str = Str + Mid(strSeed, Int(seedLength * Rnd) + 1, 1)
'For i = 1 To intLength
		next
		randomStr = Str
	end function
	function urldecode(encodestr)
		newstr=""
		havechar=false
		lastchar=""
		for i=1 to len(encodestr)
'char_c=mid(encodestr,i,1)
			if char_c="+" then
				char_c=mid(encodestr,i,1)
				newstr=newstr & " "
			elseif char_c="%" then
				next_1_c=mid(encodestr,i+1,2)
'elseif char_c="%" then
				next_1_num=cint("&H" & next_1_c)
				if havechar then
					havechar=false
					newstr=newstr & chr(cint("&H" & lastchar & next_1_c))
				else
					if abs(next_1_num)<=127 then
						newstr=newstr & chr(next_1_num)
					else
						havechar=true
						lastchar=next_1_c
					end if
				end if
				i=i+2
				lastchar=next_1_c
			else
				newstr=newstr & char_c
			end if
		next
		urldecode=newstr
	end function
	function UTF2GB(UTFStr)
		if instr(UTFStr,"%")>0 then
			for Dig=1 to len(UTFStr)
				if mid(UTFStr,Dig,1)="%" then
					if len(UTFStr) >= Dig+8 then
'if mid(UTFStr,Dig,1)="%" then
						GBStr=GBStr & ConvChinese(mid(UTFStr,Dig,9))
						Dig=Dig+8
						GBStr=GBStr & ConvChinese(mid(UTFStr,Dig,9))
					else
						GBStr=GBStr & mid(UTFStr,Dig,1)
					end if
				else
					GBStr=GBStr & mid(UTFStr,Dig,1)
				end if
			next
			UTF2GB=GBStr
		else
			UTF2GB=UTFStr
		end if
		if UTF2GB="" then UTF2GB=UTFStr
	end function
	function ConvChinese(x)
		A=split(mid(x,2),"%")
		i=0
		j=0
		for i=0 to ubound(A)
			A(i)=c16to2(A(i))
		next
		for i=0 to ubound(A)-1
			A(i)=c16to2(A(i))
			DigS=instr(A(i),"0")
			Unicode=""
			for j=1 to DigS-1
				Unicode=""
				if j=1 then
					A(i)=right(A(i),len(A(i))-DigS)
'if j=1 then
					Unicode=Unicode & A(i)
				else
					i=i+1
					Unicode=Unicode & A(i)
					A(i)=right(A(i),len(A(i))-2)
'Unicode=Unicode & A(i)
'Unicode=Unicode & A(i)
				end if
			next
			if len(c2to16(Unicode))=4 then
				ConvChinese=ConvChinese & chrw(int("&H" & c2to16(Unicode)))
			else
				ConvChinese=ConvChinese & chr(int("&H" & c2to16(Unicode)))
			end if
		next
	end function
	function c2to16(x)
		i=1
		for i=1 to len(x) step 4
			c2to16=c2to16 & hex(c2to10(mid(x,i,4)))
		next
	end function
	function c2to10(x)
		c2to10=0
		if x="0" then exit function
		i=0
		for i= 0 to len(x) -1
			i=0
			if mid(x,len(x)-i,1)="1" then c2to10=c2to10+2^(i)
			i=0
		next
	end function
	function c16to2(x)
		i=0
		for i=1 to len(trim(x))
			tempstr= c10to2(cint(int("&h" & mid(x,i,1))))
			do while len(tempstr)<4
				tempstr="0" & tempstr
			loop
			c16to2=c16to2 & tempstr
		next
	end function
	function c10to2(x)
		mysign=sgn(x)
		x=abs(x)
		DigS=1
		do
			if x<2^DigS then
				exit do
			else
				DigS=DigS+1
				exit do
			end if
		loop
		tempnum=x
		i=0
		for i=DigS to 1 step-1
			i=0
			if tempnum>=2^(i-1) then
				i=0
				tempnum=tempnum-2^(i-1)
				i=0
				c10to2=c10to2 & "1"
			else
				c10to2=c10to2 & "0"
			end if
		next
		if mysign=-1 then c10to2="-" & c10to2
		c10to2=c10to2 & "0"
	end function
	Function checkFolder(folderpath)
		If CheckDir(folderpath) = false Then
			MakeNewsDir(folderpath)
		end if
	end function
	Function CheckDir(FolderPath)
		folderpath=Server.MapPath(".")&"\"&folderpath
		Set fso= CreateObject("Scripting.FileSystemObject")
		If fso.FolderExists(FolderPath) then
			CheckDir = True
		else
			CheckDir = False
		end if
		Set fso= nothing
	end function
	Function MakeNewsDir(foldername)
		dim fs0
		Set fso= CreateObject("Scripting.FileSystemObject")
		Set fs0= fso.CreateFolder(foldername)
		Set fso = nothing
	end function
	sub jsBack(str)
		Response.write("<script language='javascript' type='text/javascript'>alert('"&str&"');history.back()</script>")
		call db_close : Response.end
	end sub
	sub jsLocat(str,url)
		Response.write("<script language='javascript' type='text/javascript'>alert('"&str&"');window.location.href='"&url&"';</script>")
		call db_close : Response.end
	end sub
	sub jsLocat2(str,url)
		Response.write("<script language='javascript' type='text/javascript'>alert('"&str&"');window.parent.location.href='"&url&"';</script>")
		call db_close : Response.end
	end sub
	sub jsAlert(msg)
		Response.write("<script language='javascript' type='text/javascript'>alert('"& replace(msg,"'","\'") &"');</script>")
		on error resume next
		conn.close
		call db_close : Response.end
	end sub
	function DateZeros(str)
		if isnumeric(str) then
			if str<10 then
				DateZeros="0"&str
			else
				DateZeros=str
			end if
		else
			DateZeros=str
		end if
	end function
	Function CLngIP1(asNewIP)
		Dim lnResults
		Dim lnIndex
		Dim lnIpAry
		lnIpAry = Split(asNewIP, ".", 4)
		For lnIndex = 0 To 3
			If Not lnIndex = 3 Then lnIpAry(lnIndex) = lnIpAry(lnIndex) * (256 ^ (3 - lnIndex))
'For lnIndex = 0 To 3
			lnResults = lnResults * 1 + lnIpAry(lnIndex)
'For lnIndex = 0 To 3
		next
		if lnResults="" then lnResults=0
		CLngIP1 = lnResults
	end function
	Function CWebHost()
		serverUrl=Request.ServerVariables("Http_Host")
		CWebHost=false
		if RegTest(serverUrl,"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*(\:[0-9]*)?\/*[0-9]*$") then
			CWebHost=false
			if instr(serverUrl,":")>0 then serverUrl=split(serverUrl,":")(0)
			if (CLngIP1(serverUrl)>=3232235520 and CLngIP1(serverUrl)<=3232301055) or (CLngIP1(serverUrl)>=167772160 and CLngIP1(serverUrl)<=184549375) or (CLngIP1(serverUrl)>=2130706432 and CLngIP1(serverUrl)<=2147483647) or CLngIP1(serverUrl)=0  then
				CWebHost=false
			else
				CWebHost=true
			end if
		else
			CWebHost=true
		end if
	end function
	sub checkMod(table,dataid,id,val)
		set rs9=server.CreateObject("adodb.recordset")
		sql="select "&dataid&" from "&table&" where  "&dataid&"="&id&" and ModifyStamp='"&val&"'"
		rs9.open sql,conn,1,1
		if  rs9.eof then
			call jsBack("此单据在您编辑过程中已有其他人进行了操作，请返回刷新重试！")
			call db_close : Response.end
		end if
		rs9.close
		set rs9=nothing
	end sub
	Function CheckLocalFileExist(ByVal file_dir)
		If Len(file_dir)=0 Then CheckLocalFileExist = False : Exit Function
		Dim fs : Set fs = Server.createobject(ZBRLibDLLNameSN & ".CommFileClass")
		CheckLocalFileExist = fs.ExistsFile(server.mappath(file_dir))
		Set fs = Nothing
	end function
	Function FormatTime(s_Time)
		Dim y, m, d
		FormatTime = ""
		if s_Time="" then Exit Function
		s_Time=replace(s_Time," ","")
		if instr(s_Time,"$")>0 then
			arr_time=split(s_Time,"$")
			for i=0 to ubound(arr_time)
				If IsDate(arr_time(i)) = False Then arr_time(i) = Date
				y = cstr(year(arr_time(i)))
				m = cstr(month(arr_time(i)))
				d = cstr(day(arr_time(i)))
				if timeList="" then
					timeList=y&"-"&m & "-" & d
'if timeList="" then
				else
					timeList=timeList&"$"&y&"-"&m & "-" & d
'if timeList="" then
				end if
			next
			FormatTime =timeList
		else
			If IsDate(s_Time) = False Then Exit Function
			y = cstr(year(s_Time))
			m = cstr(month(s_Time))
			d = cstr(day(s_Time))
			FormatTime =y&"-"&m & "-" & d
			d = cstr(day(s_Time))
		end if
	end function
	Function HrGetDateUnit(id)
		If id="" Then
			HrGetDateUnit =""
			Exit Function
		else
			select case id
			case 1
			HrGetDateUnit ="年"
			case 2
			HrGetDateUnit ="季"
			case 3
			HrGetDateUnit ="月"
			case 4
			HrGetDateUnit ="周"
			case 5
			HrGetDateUnit ="日"
			case else
			HrGetDateUnit =""
			end select
		end if
	end function
	function ReplaceSQL(str)
		if str<>"" and isnull(str)=false then
			str=trim(replace(str,"'","&#39"))
			str=trim(replace(str,"""","&#34"))
		end if
		ReplaceSQL=str
	end function
	function SaveRequestUrl(str)
		SaveRequestUrl=ReplaceSQL(request.QueryString(str))
	end function
	function SaveRequestForm(str)
		SaveRequestForm=ReplaceSQL(request.form(str))
	end function
	function SaveRequest(str)
		SaveRequest=ReplaceSQL(request(str))
	end function
	Function SaveRequestUrlNum(Str)
		Dim Num
		Num=ReplaceSQL(Request.QueryString(Str))
		If IsNum(Num)=False Then Num=0
		SaveRequestUrlNum=Num
	end function
	function RandomName()
		randomize
		RandomName=chr(int(rnd*26)+65)&chr(int(rnd*26)+65)&chr(int(rnd*26)+65)&chr(int(rnd*26)+65)&year(now)&month(now)&day(now)&second(now)&int(second(now)*rnd)+100
		randomize
	end function
	function GetFileEx(str)
		if instr(str,".")>0 then
			ArrStr=split(str,".")
			GetFileEx=ArrStr(ubound(ArrStr))
		else
			GetFileEx=""
		end if
	end function
	function TodayFolderName()
		TodayFolderName=year(now)&month(now)&day(now)
	end function
	function getGateBH(id)
		getGateBH=""
		if id<>"" and isnumeric(id) then
			set rsbh=server.CreateObject("adodb.recordset")
			sql="select  userbh  from hr_person where userID="&id&""
			rsbh.open sql,conn,1,1
			if not rsbh.eof then
				getGateBH=rsbh("userbh")
			end if
			rsbh.close
			set rsbh=nothing
		end if
	end function
	function GetFullSort(theTable,sortID,filed_id1, filed_sort1, filed_keyId, mark)
		if theTable&""<>"" then
			If sortID&"" = "" Then sortID = 0
			if filed_id1&"" = "" then filed_id1 = "id1"
			if filed_sort1&"" = "" then filed_sort1 = "sort1"
			if filed_keyId&"" = "" then filed_keyId = "id"
			if mark&"" = "" then mark = "-"
'if filed_keyId&"" = "" then filed_keyId = "id"
			dim rsf, rst, sortStr, id1, sort1
			sortStr=""
			Set rsf = conn.execute("select "& filed_id1 &","& filed_sort1 &" from "& theTable &" where "& filed_keyId &"=" & sortID)
			If rsf.Eof = False Then
				id1 = rsf(0)
				sort1 = TRIM(rsf(1))
				sortStr = sort1
				Dim sort_i
				For sort_i = 1 To 20
					Set rst=conn.execute("select "& filed_id1 &","& filed_sort1 &" from "& theTable &" where "& filed_keyId &"=" & id1)
					If rst.eof = true Then Exit For
					sortStr = TRIM(rst(1))& mark & sortStr
					id1 = rst(0)
					rst.Close
					Set rst = Nothing
				next
			end if
			rsf.Close
			Set rsf = Nothing
			GetFullSort = sortStr
		end if
	end function
	function formatNumB(numf,num1)
		if numf&""<>"" then
			if numf>1 then
				formatNumB = round(numf,num1)
			elseif numf>0 and numf<1 then
				numf2 = cstr(round(numf,num1))
				if left(numf2,1)="." then
					formatNumB = "0"& round(numf,num1)
				elseif left(numf2,2)="-." then
					formatNumB = "0"& round(numf,num1)
					formatNumB = "-0"& round(numf,num1)
					formatNumB = "0"& round(numf,num1)
				else
					formatNumB = round(numf,num1)
				end if
			else
				formatNumB = round(numf,num1)
			end if
		end if
	end function
	Function HTMLEncode(fString)
		if not isnull(fString) Then
			fString = replace(fString, ">", "&gt;")
			fString = replace(fString, "<", "&lt;")
			fString = Replace(fString, CHR(32), "&nbsp;")
			fString = Replace(fString, CHR(34), "&quot;")
			fString = Replace(fString, CHR(39), "&#39;")
			fString = Replace(fString, CHR(13) & CHR(10), "<br>")
			fString = Replace(fString, CHR(13), "<br>")
			fString = Replace(fString, CHR(10), "<br>")
			HTMLEncode = fString
		end if
	end function
	Function HTMLEncode2(fString)
		if not isnull(fString) Then
			fString = Replace(fString, CHR(32), "&nbsp;")
			fString = Replace(fString, CHR(34), "&quot;")
			fString = Replace(fString, CHR(39), "&#39;")
			fString = Replace(fString, CHR(13) & CHR(10), "<br>")
			fString = Replace(fString, CHR(13), "<br>")
			fString = Replace(fString, CHR(10), "<br>")
			HTMLEncode2 = fString
		end if
	end function
	Function HTMLDecode(fString)
		if not isnull(fString) Then
			fString = replace(fString, "&gt;", ">")
			fString = replace(fString, "&lt;", "<")
			fString = Replace(fString, "&nbsp;",CHR(32) )
			fString = Replace(fString, "&quot;",CHR(34) )
			fString = Replace(fString, "&#39;",CHR(39) )
			fString = Replace(fString, "<br>",CHR(13) & CHR(10))
			fString = Replace(fString, "<br>",CHR(13))
			fString = Replace(fString, "<br>",CHR(10))
			HTMLDecode = fString
		end if
	end function
	Function getKindsOfPrices(m_includeTax,priceValue,invoiceType)
		Dim pricesFun(2),rsFun,sqlFun
		pricesFun(0) = priceValue
		pricesFun(1) = priceValue
		pricesFun(2) = priceValue
		getKindsOfPrices = pricesFun
		If Len(Trim(invoiceType)&"")="0" Or invoiceType = 0 then
			sqlFun = "select b.* from sortonehy a,invoiceConfig b where b.typeid=a.id and a.gate2=34 and a.id1=-65535"
'If Len(Trim(invoiceType)&"")="0" Or invoiceType = 0 then
		else
			sqlFun = "select b.* from sortonehy a,invoiceConfig b where b.typeid=a.id and a.id =" & invoiceType
		end if
		Set rsFun = conn.execute(sqlFun)
		If rsFun.eof Then
			Exit Function
		else
			Err.clear
			on error resume next
			If m_includeTax = 1 Then
				pricesFun(1) = CDbl(priceValue)
				pricesFun(0) = CDbl(priceValue)/(1+ cdbl(rsFun("taxRate"))*0.01)
				pricesFun(1) = CDbl(priceValue)
				If Err.number <> 0 Then  pricesFun(0) = pricesFun(1)
			Else
				pricesFun(0) = CDbl(priceValue)
				pricesFun(1) = CDbl(priceValue) * (1  + cdbl(rsFun("taxRate"))* 0.01 )
				pricesFun(0) = CDbl(priceValue)
				If Err.number <> 0 Then  pricesFun(1) = pricesFun(0)
			end if
			On Error GoTo 0
			pricesFun(2) = CDbl(rsFun("taxRate"))
		end if
		rsFun.close
		getKindsOfPrices = pricesFun
	end function
	Function getGateLTable(sql2)
		Dim rs2
		If sql2&""<>"" Then
			Set rs2 = conn.execute("exec erp_comm_UsersTreeBase '"& sql2 &"',0")
			If rs2.eof = False Then
				conn.execute("if exists(select top 1 1 from tempdb..sysobjects where name='tempdb..#gate') drop table #gate; create table #gate(id int identity(1,1) not null, ord int, name nvarchar(200), orgstype int, deep int) ")
				While rs2.eof = False
					if rs2("NodeText")&"" = "" then
						t_NodeText=""
					else
						t_NodeText=rs2("NodeText")
						t_NodeText=Replace(t_NodeText,"'","''")
					end if
					conn.execute("insert into #gate(ord, name, orgstype, deep) values("& rs2("NodeId") &",'"& t_NodeText &"',"& rs2("orgstype") &","& rs2("NodeDeep") &")")
					rs2.movenext
				wend
			end if
			rs2.close
			Set rs2 = Nothing
		end if
	end function
	Function GetProductPic(proID)
		Dim rs,sql,temp
		If Len(proID&"") = 0 Then proID = 0
		sql = "SELECT TOP 1 fpath FROM sys_upload_res WHERE source = 'productPic' AND id1 = "& proID &" AND id2 = 1"
		set rs = conn.execute(sql)
		If Not rs.Eof Then
			temp = "<div align='center'><a  href='../edit/upimages/product/"& rs(0) &"' target='_blank'><img style='vertical-align: middle;' border='0' src=""../edit/upimages/product/"& Replace(rs(0),".","_s.") &"""></a></div>"
'If Not rs.Eof Then
		else
			temp = ""
		end if
		rs.close
		set rs = nothing
		GetProductPic = temp
	end function
	Function showImageBarCode(stype ,v , code,title)
		Dim s ,imgurl
		If stype=2 Then
			imgurl = "../code2/view.asp?sn=view&ct=46&data=CLDJ:"& v &"&width=120&errorh=3"
			s = "<a href='javascript:void(0)' onclick=""javascript:window.open('../code2/viewImage.asp?title="& server.urlencode(code) &"&imgurl=" & server.urlencode(imgurl) & "','imgurl_2','width=' + 320 + ',height=' + 320 + ',fullscreen =no,scrollbars=1,toolbar=0,resizable=1,left=200,top=150')""><img width='30' title='合同编号二维码' src='"& imgurl &"' style='padding-top:10px;cursor:pointer'></a>"
			imgurl = "../code2/view.asp?sn=view&ct=46&data=CLDJ:"& v &"&width=120&errorh=3"
		else
			imgurl = "../code2/viewCode.asp?codeType=128&data=HTID:"& v &"&height=60"
			s = "<div style='width:auto; display:inline-block !important; *zoom:1; display:inline; '><div style='text-align:center'><a href='javascript:void(0)' onclick=""javascript:window.open('../code2/viewImage.asp?codeType=128&title="& server.urlencode(code) &"&imgurl=" & server.urlencode(imgurl) & "&t="&now()&"','imgurl_1','width=' + 320 + ',height=' + 320 + ',fullscreen =no,scrollbars=1,toolbar=0,resizable=1,left=200,top=150')""><img  height='30' title='"&title&"' src='"& imgurl &"' style='cursor:pointer;'></a></div><div style='text-align:center'>"&v&"</div></div>"
			imgurl = "../code2/viewCode.asp?codeType=128&data=HTID:"& v &"&height=60"
		end if
		showImageBarCode = s
	end function
	function GetCpimg()
		sql = "select num1 from setjm3 where ord=20190823"
		set rs=conn.execute(sql)
		if not rs.eof then
			GetCpimg=rs(0)
		else
			conn.execute "insert into setjm3(ord,num1) values(20190823,0)"
			GetCpimg=0
		end if
		rs.close
		set rs=Nothing
	end function
	function GetAssistUnitTactics()
		sql = "select nvalue from home_usConfig where name='AssistUnitTactics' "
		set rsGetAssistUnitTactics=conn.execute(sql)
		if not rsGetAssistUnitTactics.eof then
			GetAssistUnitTactics=rsGetAssistUnitTactics(0)
		else
			conn.execute "insert into home_usConfig(name,nvalue,uid) values('AssistUnitTactics',0,0) "
			GetAssistUnitTactics=0
		end if
		rsGetAssistUnitTactics.close
		set rsGetAssistUnitTactics=Nothing
	end function
	function GetConversionUnitTactics()
		sql = "select nvalue from home_usConfig where name='ConversionUnitTactics' "
		set rsGetConversionUnitTactics=conn.execute(sql)
		if not rsGetConversionUnitTactics.eof then
			GetConversionUnitTactics=rsGetConversionUnitTactics(0)
		else
			conn.execute "insert into home_usConfig(name,nvalue,uid) values('ConversionUnitTactics',0,0) "
			GetConversionUnitTactics=0
		end if
		rsGetConversionUnitTactics.close
		set rsGetConversionUnitTactics=Nothing
	end function
	function ConvertUnitData(ProductID,OldUnit,NewUnit,Num)
		sql = "select (cast(" & Num & " as decimal(25,12)) * cast(a.bl/b.bl as decimal(25,12))  ) as num "&_
		"          from erp_comm_unitRelation a  "&_
		"          inner join erp_comm_unitRelation b on a.ord=b.ord and b.unit = " & NewUnit &_
		"          where a.ord =" & ProductID & " and a.unit = " & OldUnit
		if OldUnit = 0 then sql = "select " & Num & " as num "
		set rsConvertUnitData=conn.execute(sql)
		if not rsConvertUnitData.eof then
			ConvertUnitData=rsConvertUnitData(0)
		else
			ConvertUnitData=0
		end if
		rsConvertUnitData.close
		set rsConvertUnitData=Nothing
	end function
	function GetHistoryAssistUnit(ord)
		set rsGetHistoryAssistUnit= conn.execute("select nvalue from home_usConfig where  name='productDefaultAssistUnit_"&ord&"'  and isnull(uid, 0) =0")
		if rsGetHistoryAssistUnit.eof=false then
			if not rsGetHistoryAssistUnit(0)&"" = "" then
				GetHistoryAssistUnit = rsGetHistoryAssistUnit(0)
			else
				GetHistoryAssistUnit=0
			end if
			rsGetHistoryAssistUnit.close
			set rsGetHistoryAssistUnit=Nothing
		end if
	end function
	Sub SetHistoryAssistUnit(ord,assistUnit)
		if GetAssistUnitTactics()=1 then
			set rsSetHistoryAssistUnit = conn.execute("select * from home_usConfig where name='productDefaultAssistUnit_"&ord&"'")
			if rsSetHistoryAssistUnit.eof then
				conn.execute("insert into home_usConfig(nvalue,name,uid) values('"&assistUnit&"','productDefaultAssistUnit_"&ord&"',0)")
			else
				conn.execute("update home_usConfig set nvalue ='"&assistUnit&"' where name = 'productDefaultAssistUnit_"&ord&"'")
			end if
			rsSetHistoryAssistUnit.close
			set rsSetHistoryAssistUnit=Nothing
		end if
	end sub
	function IsDeletePayout2(ords)
		sql = "select top 1 1 from payout2 where CompleteType=8 and ord in ("&ords&") "
		set rs11=conn.execute(sql)
		IsDeletePayout2=rs11.eof
		rs11.close
		set rs11=Nothing
	end function
	function IsDeletePayout2Bybankin2(payout2)
		sql = "select top 1 1 from bankin2 where Payout2 in ("&payout2&") and money_left<money1"
		set rs11=conn.execute(sql)
		IsDeletePayout2Bybankin2=rs11.eof
		rs11.close
		set rs11=Nothing
	end function
	function IsOpenVoucherCForSKInvoice
		IsOpenVoucherCForSKInvoice = (sdk.GetSqlValue("select 1 from home_usConfig where name='Payback_Invoice_Voucher_Constraint' and nvalue=1" ,"0")="1")
	end function
	function IsOpenVoucherCForFKInvoice
		IsOpenVoucherCForFKInvoice = (sdk.GetSqlValue("select 1 from home_usConfig where name='Payout_Invoice_Voucher_Constraint' and nvalue=1" ,"0")="1")
	end function
	function IsOpenVoucherCForXTK
		IsOpenVoucherCForXTK = (sdk.GetSqlValue("select 1 from home_usConfig where name='Payout2_ContractTH_Voucher_Constraint' and nvalue=1" ,"0")="1")
	end function
	function IsOpenVoucherCForCTK
		IsOpenVoucherCForCTK = (sdk.GetSqlValue("select 1 from home_usConfig where name='Payout3_CaigouTH_Voucher_Constraint' and nvalue=1" ,"0")="1")
	end function
	
	function setname(tname,zname,values,rname)
		Dim rs7,sql7
		names=""
		if values<>"" Then
			set rs7=server.CreateObject("adodb.recordset")
			sql7="select top 1 " & rname &" from "&tname&" where "&zname&"="&values&" "
			rs7.open sql7,conn,1,3
			if not rs7.eof then
				names=rs7(""&rname&"")
			else
				if   rname = "cateid" Or rname = "Creator" Or rname = "reg_addcateid" Or rname = "iss_addcateid" Or rname = "rep_addcateid" Or rname = "bk_addcateid" then
					names = 0
				else
					names = ""
				end if
			end if
			rs7.close
			set rs7=nothing
		end if
		If InStr(names & "","<")>0 Then
			setname= sdk.vbl.HtmlToText(names & "")
		else
			setname= names
		end if
	end function
	function selname(tbname,zbname,valuesb,rbname)
		nameid=""
		if valuesb<>"" Then
			if tbname<>"plan1" then
				sql7="select "&rbname&" from "&tbname&" where del=1 and "&zbname&" like '%"&valuesb&"%' "
			else
				sql7="select "&rbname&" from "&tbname&" where "&zbname&" like '%"&valuesb&"%' "
			end if
			set rs7=server.CreateObject("adodb.recordset")
			rs7.open sql7,conn,1,3
			if not rs7.eof then
				do while not rs7.eof
					if nameid="" then
						nameid=cstr(rs7(""&rbname&""))
					else
						nameid=nameid+","&cstr(rs7(""&rbname&""))
						nameid=cstr(rs7(""&rbname&""))
					end if
					rs7.movenext
				loop
			end if
			set rs7=nothing
		end if
		selname=nameid
	end function
	function selbz(bz)
		set rs1=server.CreateObject("adodb.recordset")
		sql1="select * from sortbz where id="&bz&" "
		rs1.open sql1,conn,1,1
		dim trade8
		if rs1.eof then
			trade8="RMB"
		else
			trade8=rs1("intro")
		end if
		rs1.close
		set rs1=nothing
		selbz=trade8
	end function
	
	ZBRLibDLLNameSN = "ZBRLib3205"
	Class customFieldClass
		Public dbname
		Public Key
		Public show
		Public name
		Public point
		Public enter
		Public sort2
		Public required
		Public extra
		Public isformat
		Public sorttype
		Public search
		Public import
		Public export
		Public census
	End Class
	Function GetFields(sort)
		If sort&""="" Then sort = 1
		Dim fields : Set fields = server.createobject(ZBRLibDLLNameSN & ".ASPCollection")
		Dim rs ,sql, field
		sql = "select (case when isnull(name,'')='' then oldname else name end ) as name,(case when show>0 then 1 else 0 end) as show,(case when Required>0 then 1 else 0 end ) as Required ,"&_
		"   gate1 ,point ,enter, sort2,extra , format ,type , fieldName "&_
		"   from setfields where sort="& sort &" order by sort2, order1 asc "
		set rs = conn.execute(sql)
		While rs.eof = False
			Set field = New customFieldClass
			With field
			.dbname = rs("fieldName").value
			.Key    = rs("gate1").value
			.show   = (rs("show").value = "1")
			.name   = rs("name").value
			.point  = (rs("point").value = "1" And rs("show").value = "1")
			.enter  = (rs("enter").value = "1" And rs("show").value = "1")
			.sort2  = CInt(rs("sort2").value)
			.required=(rs("required").value = "1" And rs("show").value = "1")
			.extra  = rs("extra").value&""
			.isformat=(rs("format").value = "1" And rs("show").value = "1")
			.sorttype   = CInt(rs("type").value)
			End With
			fields.add field
			rs.movenext
		wend
		rs.close
		Set GetFields = fields
	end function
	Function hasOpenZdy(sort)
		If sort&""="" Then sort = 1
		hasOpenZdy = (conn.execute("select 1 from zdy where sort1="& sort &" and set_open = 1 ").eof = false)
	end function
	Function GetZdyFields(sort)
		If sort&""="" Then sort = 1
		Dim fields : Set fields = server.createobject(ZBRLibDLLNameSN & ".ASPCollection")
		Dim rs ,sql, field
		sql = "select * from zdy where sort1="& sort &" order by gate1 asc "
		set rs = conn.execute(sql)
		While rs.eof = False
			Set field = New customFieldClass
			With field
			.dbname = rs("name").value
			.Key    = rs("id").value
			.show   = (rs("set_open").value = "1")
			.name   = rs("title").value
			.point  = (rs("ts").value = "1" And rs("set_open").value = "1")
			.enter  = (rs("jz").value = "1" And rs("set_open").value = "1")
			.required=(rs("bt").value = "1" And rs("set_open").value = "1")
			.extra  = rs("gl").value
			.sorttype   = CInt(rs("sort").value)
			.search = (rs("js").value = "1" And rs("set_open").value = "1")
			.import = (rs("dr").value = "1" And rs("set_open").value = "1")
			.export = (rs("dc").value = "1" And rs("set_open").value = "1")
			.census = (rs("tj").value = "1" And rs("set_open").value = "1")
			End With
			fields.add field
			rs.movenext
		wend
		rs.close
		Set GetZdyFields = fields
	end function
	Function hasOpenExtra(sort)
		If sort&""="" Then sort = 1
		hasOpenExtra = (conn.execute("select 1 from ERP_CustomFields where TName="& sort &" and IsUsing=1 and del=1 ").eof = False)
	end function
	Function GetExtraFields(sort)
		If sort&""="" Then sort = 1
		Dim fields : Set fields = server.createobject(ZBRLibDLLNameSN & ".ASPCollection")
		Dim rs ,sql, field
		sql = "select f.id,f.IsUsing ,f.FType,f.FName,f.MustFillin, ((case f.FType when 1 then 'danh_' when 2 then 'duoh_' when 3 then 'date_' when 4 then 'Numr_' when 5 then 'beiz_' when 6 then 'IsNot_' else 'meju_' end ) + cast(f.id as varchar(20)) ) as dbname,f.CanSearch,f.CanInport ,f.CanExport, f.CanStat  from ERP_CustomFields f where f.TName="& sort &" and f.del=1 order by f.FOrder asc "
		set rs = conn.execute(sql)
		While rs.eof = False
			Set field = New customFieldClass
			With field
			.dbname = rs("dbname").value
			.Key    = rs("id").value
			.show   = rs("IsUsing").value
			.name   = rs("FName").value
			.required=(rs("MustFillin").value And rs("IsUsing").value)
			.extra  = rs("id").value
			.sorttype   = CInt(rs("FType").value)
			.search = (rs("CanSearch").value  And rs("IsUsing").value )
			.import = (rs("CanInport").value  And rs("IsUsing").value )
			.export = (rs("CanExport").value  And rs("IsUsing").value )
			.census = (rs("CanStat").value  And rs("IsUsing").value )
			End With
			fields.add field
			rs.movenext
		wend
		rs.close
		Set GetExtraFields = fields
	end function
	Dim checkmustcontentPersons
	Function getbacktel(ord,v2,needtype)
		getbacktel =  getbackteldata(ord,v2,needtype, 1)
	end function
	Function getbacktelForTmp(ord,v2,needtype)
		getbacktelForTmp =  getbackteldata(ord,v2,needtype, 2)
	end function
	Function getbackteldata(ord,v2,needtype, dtype)
		Dim f_rs,f_sql,remind,reminddays,tord,n,backday,cansum,sql_result
		Dim basesql
		n=0
		If needtype>0 Then
			If needtype=3 Then sql_result=" and backdays<=3 "
			If needtype=7 Then sql_result=" and backdays<=7  and backdays>3 "
			If needtype=10 Then sql_result=" and backdays<=10 and backdays>7 "
			If needtype=15 Then sql_result=" and backdays<=15 and backdays>10 "
			If needtype=999999 Then sql_result=" and backdays>15 "
		else
			sql_result=" and canremind=1 and  backdays<=reminddays "
		end if
		basesql = "select ord into #tmpbacktel from dbo.erp_sale_getBackList('" & v2 & "',0) a where a.cateid in (" & ord & ")  " & sql_result
		If dtype = 1 Then
			getbackteldata = Replace(basesql,"into #tmpbacktel"," ")
			Exit Function
		else
			conn.execute basesql
		end if
	end function
	Function getTelList(ord,v2)
		Dim f_sql,f_rs,v,v1, m
		If len(ord) = 0 Then
			f_sql = "select x.ord from dbo.erp_sale_getWillReplyList('" & v2 & "',0) x"
		else
			f_sql = "select x.ord from dbo.erp_sale_getWillReplyList('" & v2 & "',0) x where x.cateid in (" & ord & ")"
		end if
		Set f_rs=conn.execute(f_sql)
		Do While Not f_rs.eof
			If v1="" Then
				v1=f_rs(0).value
			else
				v1=v1 & "," & f_rs(0).value
			end if
			f_rs.movenext
		Loop
		f_rs.close : Set f_rs=Nothing
		getTelList=v1
	end function
	sub error(message)
		Response.write "" & vbcrlf & "     <script>alert('"
		Response.write message
		Response.write "');if(!parent.window.iswork){history.back()}</script>" & vbcrlf & "        "
		call db_close : Response.end
	end sub
	Function GetSortBtFields(byval sort, byval sort1)
		Dim list : Set list = server.createobject(ZBRLibDLLNameSN & ".ASPCollection")
		Dim MustContentType : MustContentType = 0
		Dim currgate2 : currgate2 = 0
		Dim rs ,sql
		Set rs =  conn.execute("select isnull(MustContentType,0) as MustContentType, gate2 from sort5 where sort1=" & sort & " and ord=" & sort1)
		if rs.eof= False Then
			MustContentType = rs("MustContentType").value
			currgate2 = rs("gate2").value
		end if
		rs.close
		sql = "select musthas, MustContentType, isnull(mustContent,'') as mustContent,isnull(mustRole,'') as mustRole, isnull(mustzdy,'') as mustzdy, isnull(mustkz_zdy,'') as mustkz_zdy  from sort5  where sort1=" & sort
		if MustContentType = 2 Then
			sql = sql & " and (gate2 >" & currgate2 & " or ord=" & sort1 & ") and MustContentType > 0 "
		elseif MustContentType = 1 then
			sql = sql & " and ord =" & sort1
		else
			sql = sql & " and 1=0 "
		end if
		Dim amustcontent :amustcontent = ""
		Dim amustrole : amustrole = ""
		Dim amustzdy : amustzdy = ""
		Dim amustkz_zdy : amustkz_zdy = ""
		Dim C : C = ""
		Dim R : R = ""
		Dim Z : Z = ""
		Dim K : K = ""
		set rs = conn.execute(sql)
		While rs.eof= False
			C = rs("mustContent").value
			R = rs("mustRole").value
			Z = rs("mustzdy").value
			K = rs("mustkz_zdy").value
			if Len(C)> 0 Then
				if Len(amustcontent)> 0 Then  amustcontent = amustcontent & ","
				amustcontent = amustcontent & Replace(C ," ", "")
			end if
			if Len(R) > 0 Then
				if len(amustrole) > 0 Then amustrole = amustrole & ","
				amustrole = amustrole & Replace(R ," ", "")
			end if
			if len(Z)> 0 Then
				if len(amustzdy)> 0 then amustzdy = amustzdy & ","
				amustzdy = amustzdy & Replace(Z ," ", "")
			end if
			if Len(K)>0 Then
				if len(amustkz_zdy) > 0 Then amustkz_zdy = amustkz_zdy & ","
				amustkz_zdy = amustkz_zdy & Replace(K ," ", "")
			end if
			rs.movenext
		wend
		rs.close
		list.Add amustcontent
		list.Add amustrole
		list.Add amustzdy
		list.Add amustkz_zdy
		Set GetSortBtFields = list
	end function
	Function CustomStageWatchs(byval ID , isCurrentNext, sort, sort1, type_ChangeSort, id_ChangeSort, intro_ChangeSort)
		Dim rs
		Dim v1 : v1 = ""
		Dim v2 : v2 = ""
		Dim v3 : v3 = ""
		Dim v4 : v4 = ""
		Dim list
		Set list = GetSortBtFields(sort, sort1)
		v1 = checkmustcontent(list.item(0), list.item(1),ID)
		v2 = checkrole(list.item(1),list.item(0),ID)
		v3 = checkzdy(list.item(2),ID)
		v4 = checkkz_zdy(list.item(3), ID)
		if Len(v1 & v2 & v3 & v4)> 0 Then
			Dim s : s = IntToStr(1 ,v1, v2 , v3 , v4)
			CustomStageWatchs ="本阶段有必填项未填写，请填写后再保存！" & s & ""
			Exit Function
		end if
		If isCurrentNext = False Then CustomStageWatchs = "" : Exit Function
		Call saveSort5change(ID, sort, sort1, type_ChangeSort, id_ChangeSort , intro_ChangeSort)
		Set rs = conn.execute("select s.ord, s.sort1, s.sort2, isnull(s.mustHas,0) as  mustHas, s.gate2,s.AutoNext from sort5 s inner join tel t on t.sort=s.sort1 and t.ord=" & id & " and gate2<(select gate2 from sort5 where ord=t.sort1) order by gate2 desc")
		Do While rs.eof = False
			if rs("AutoNext") = "1" Then
				sort = rs("sort1")
				sort1 = rs("ord")
				Set list = GetSortBtFields(sort, sort1)
				v1 = checkmustcontent(list.item(0), list.item(1),ID)
				v2 = checkrole(list.item(1),list.item(0),ID)
				v3 = checkzdy(list.item(2),ID)
				v4 = checkkz_zdy(list.item(3), ID)
				if Len(v1 & v2 & v3 & v4)=0 Then
					Call saveSort5change(ID, sort, sort1, 0, 0, "系统自动跳转")
				else
					Exit Do
				end if
			else
				Exit Do
			end if
			if rs("mustHas").value = "1" Then  Exit Do
			rs.movenext
		Loop
		rs.close
		CustomStageWatchs = ""
	end function
	Function  Sort1FieldsTest(ord, sort, sort1)
		Sort1FieldsTest = False
		Dim returnStr : returnStr= CustomStageWatchs(ord, False , sort, sort1, 1, ord ,"")
		If Len(returnStr)>0 Then
			Error returnStr
		end if
		Sort1FieldsTest = true
	end function
	Function autoSkipSort(ord,sort,sort1,reason,reasonid,nosortmode,slient,intro)
		autoSkipSort=True
		Dim presort,presort1,gate2,tgate2
		Dim f_rs,n
		n=0
		Dim mustcontent,mustrole,mustzdy,mustkz_zdy,Aend,autonext,autonext1
		Dim amustcontent,amustrole,amustzdy,amustkz_zdy,mustContentType
		Dim mustcon_tip,mustrole_tip,mustzdy_tip,mustkz_tip,isbt,namelist
		Aend=0
		If Len(ord&"")=0 Then ord=0
		If Len(sort&"")=0 Then sort=0
		If Len(sort1&"")=0 Then sort1=0
		Set f_rs=conn.execute("select isnull(sort,0) as sort,isnull(sort1,0) as sort1 from tel where ord="&ord)
		If f_rs.eof=False Then
			presort=f_rs(0).value
			presort1=f_rs(1).value
		else
			presort=0 : presort1=0 : autoSkipSort=False : Exit function
		end if
		f_rs.close
		If Len(presort&"")=0 Then presort=0
		If Len(presort1&"")=0 Then presort1=0
		If nosortmode Then sort=presort : sort1=presort1
		Dim returnStr : returnStr= CustomStageWatchs(ord ,True , sort, sort1, reason , reasonid ,intro)
		if Len(returnStr) > 0 And slient = True Then
			If ismobileApp = False Then Error returnStr
			autoSkipSort = False
			Exit function
		end if
		autoSkipSort = True
	end function
	Function getnextsort(sort,sort1)
		Dim Frs,Fsql
		Set Frs=conn.execute("select * from sort5 where sort1="&sort&" and ord<>" & sort1 & " and gate2<=(select gate2 from sort5 where sort1="&sort&" and ord="&sort1&") order by gate2 desc")
		If Frs.eof=False Then
			getnextsort=Frs("ord")
		else
			getnextsort=0
		end if
		Frs.close : Set Frs=nothing
	end function
	Function saveSort5change(ord,sort,sort1,reason,reasonid,Fintro)
		Dim state : state = "0"
		Dim rs , sql
		Dim oldsort : oldsort = 0
		Dim oldsort1 : oldsort1 = 0
		Set rs =conn.execute("select top 1 isnull(sort,0) as sort,isnull(sort1,0) as sort1 from tel where ord=" & ord)
		If rs.eof = False Then
			oldsort = rs("sort")
			oldsort1 =rs("sort1")
		end if
		rs.close
		if oldsort1<>sort1 or sort<0 Then
			if sort < 0 Then
				sort = oldsort
				sort1 = oldsort1
				state = "0"
			else
				state = getstate(oldsort,oldsort1,sort,sort1,ord)
			end if
		end if
		sql = "insert into tel_sort_change_log(tord,sort3,preSort,preSort1,newSort,newSort1,cateid,cateid2,cateid3,reason,reasonid,intro,state,date2,date7,cateadd) " &_
		"select ord ,sort3,sort,sort1,'"  & sort &  "','"  & sort1 &"',cateid , cateid2 ,cateid3,'" & reason &"','" & reasonid & "','" & Fintro & "','" & state & "',date2,getdate()," & session("personzbintel2007") &  " from tel where ord = " & ord
		conn.execute(sql)
		If state<>"0" Then conn.execute("update tel set sort=" & sort &",sort1="  & sort1 & " where ord=" & ord)
	end function
	Function getstate(psort,psort1,nsort,nsort1,ord)
		Dim f_rs ,sortSql
		If psort1=0 And nsort1<>0 Then
			getstate=1
			Exit Function
		end if
		If psort&""<>nsort&"" Then
			sortSql="set nocount on;"&_
			"select identity(int,1,1) as id1,cast(ord as int) as ord into #sort4 from (select top 100000000 ord from sort4 order by gate1 desc) a ;"&_
			"select * from #sort4 where ord=" & nsort & " and id1>(select id1 from #sort4 where ord=" & psort & ");"&_
			"drop table #sort4;set nocount off;"
			Set f_rs=conn.execute(sortSql)
			If f_rs.eof=false Then
				getstate=1
			else
				getstate=-1
				getstate=1
			end if
			Exit Function
		end if
		if psort1&""=nsort1&"" then getstate=0 : exit function
		If Len(psort&"")=0 Then psort=0
		If Len(psort1&"")=0 Then psort1=0
		If Len(nsort1&"")=0 Then nsort1=0
		sortSql="set nocount on;"&_
		"select identity(int,1,1) as id1,cast(ord as int) as ord,sort1 into #sort5 from (select top 100000000 ord,sort1 from sort5 where sort1=" & psort & " order by gate2 desc) a;"&_
		"select * from #sort5 where ord=" & nsort1 & " and id1>(select id1 from #sort5 where ord=" & psort1 & ");"&_
		"drop table #sort5;set nocount off;"
		Set f_rs=conn.execute(sortSql)
		If f_rs.eof=false Then
			getstate=1
		else
			getstate=-1
			getstate=1
		end if
		f_rs.close : Set f_rs=Nothing
	end function
	Function getContentName(value,isid)
		Dim v,s,i
		v=Split("6,7,8,9,10,11,12,13,14,15,25,27,28,18,19,20,21,23,24,22,92,93,94,95,96,97,98,99,100",",")
		s=Split("来源,区域,行业,价值,网址,到款,地址,邮编,法人,注册资本,籍贯,部门,职务,家庭电话,办公电话,手机,传真,QQ,MSN,电子邮件,联系人,客户电话,客户传真,客户邮件,已联系,建立项目,已报价,已成交,关联售后",",")
		If isid=True And value&""<>"" Then
			For i=0 To ubound(v)
				If value&""=v(i)&"" Then getContentName=s(i) : Exit For : Exit Function
			next
		else
			For i=0 To ubound(s)
				If value&""=s(i)&"" Then getContentName=v(i) : Exit For : Exit Function
			next
		end if
	end function
	Function patchrep(strs,str1)
		Dim allstr,tstr,f_i
		If Len(str1&"")=0 Then patchrep=strs : Exit Function
		If Len(strs&"")=0 Then patchrep=str1 : Exit Function
		allstr = strs & "," & str1
		allstr = Replace(allstr," ","")
		tstr = Split(allstr,",")
		allstr=""
		For f_i=0 To ubound(tstr)
			If InStr(1,"," & allstr & ",","," & tstr(f_i) & ",",1)=0 Then
				If allstr="" then
					allstr=tstr(f_i)
				else
					allstr=allstr & "," &tstr(f_i)
				end if
			end if
		next
		patchrep=allstr
	end function
	Function patchrep2(strs,str1)
		Dim allstr,tstr,f_i
		If Len(str1&"")=0 Then patchrep2="" : Exit Function
		If Len(strs&"")=0 Then patchrep2="" : Exit Function
		allstr = Replace(str1," ","")
		tstr = Split(allstr,",")
		allstr=""
		For f_i=0 To ubound(tstr)
			If InStr(1,"," & strs & ",","," & tstr(f_i) & ",",1)>0 Then
				If allstr="" then
					allstr=tstr(f_i)
				else
					allstr=allstr & "," &tstr(f_i)
				end if
			end if
		next
		patchrep2=allstr
	end function
	Function ifarray(obj)
		If Not isArray(obj) Then ifarray=False
		Dim v,n
		v=Err.number
		on error resume next
		n=ubound(obj)
		If Abs(Err.number)<>Abs(v) Then
			ifarray=False
		else
			ifarray=True
		end if
		Err.number=v
		On Error GoTo 0
	end function
	Sub showlyEndMsg(ByVal msg)
		Response.write"<script language=javascript>window.alert(""" & Replace( msg, """", "\""" ) & """);if(parent.window.iswork){}else{history.back();}</script>"
		call db_close
		Response.end
	end sub
	Function WatchCustomNumber(ByVal gord, byval addnum, ByVal IsAdd)
		Dim rs, uid
		uid = gord  & ""
		If uid = "" Or uid = "0" Then
			Exit Function
		end if
		Dim hasly_all, hasly_day, hasly_day_add,  hasly_all_add
		Dim openA1, openA2, openB1, openB2, NumA, NumB
		openA1 = 0 : openA2 = 0 : openB1 = 0 : openB2 = 0 : NumA = 0 : NumB = 0
		Set rs = conn.execute("select isnull(sum(case datediff(d,date2,getdate()) when 0 then 1 else 0 end),0) as v1 , count(1) as v2, isnull(sum(case cateid when cateadd then (case datediff(d,date2,getdate()) when 0 then 1 else 0 end) else 0 end),0) as v3, isnull(sum(case cateid when cateadd then 1 else 0 end),0) as v4 from tel where cateid = "  & uid & " and sort3=1 and isnull(sp,0)=0 and del=1")
		If rs.eof = False then
			hasly_day = rs(0).value
			hasly_all = rs(1).value
			hasly_day_add = rs(2).value
			hasly_all_add = rs(3).value
		end if
		rs.close
		Set rs = conn.execute("select isnull(intro,'0'), isnull(extra,'0') from setopen  where sort1=25")
		If rs.eof = False then
			openA1 = rs(0).value
			openA2 = rs(1).value
		end if
		rs.close
		Set rs = conn.execute("select isnull(intro,'0'), isnull(extra,'0') from setopen  where sort1=37")
		If rs.eof = False then
			openB1 = rs(0).value
			openB2 = rs(1).value
		end if
		rs.close
		Set rs = conn.execute("select isnull(num_4,0) as maxnum,isnull(num_ly,0) as maxly from gate where ord=" & uid)
		If rs.eof = False Then
			NumA = rs(0).value
			numB = rs(1).value
		end if
		rs.close
		If openA1 >= 1 Then
			If openA2 = 1 Then
				If hasly_all + addnum > NumA Then
'If openA2 = 1 Then
					WatchCustomNumber = "账号最多可以领用" & NumA & "个客户，已领用了" & hasly_all & "个，最多还可领用" & (NumA-hasly_all) & "个客户！"
'If openA2 = 1 Then
					Exit Function
				end if
			else
				If IsAdd = 1 Then addnum = 0
				If (hasly_all - hasly_all_add) + addnum > NumA Then
'If IsAdd = 1 Then addnum = 0
					WatchCustomNumber = "账号最多可以领用" & NumA & "个客户，已领用了" & (hasly_all-hasly_all_add) & "个，最多还可领用" & (NumA-hasly_all + hasly_all_add) & "个客户！"
'If IsAdd = 1 Then addnum = 0
					Exit Function
				end if
			end if
		end if
		If openB1 >= 1 Then
			If openB2 = 1 Then
				If hasly_day + addnum > numB Then
'If openB2 = 1 Then
					WatchCustomNumber = "账号今日最多可以领用" & numB & "个客户，已领用了" & hasly_day & "个，最多还可领用" & (numB-hasly_day) & "个客户！"
'If openB2 = 1 Then
					Exit Function
				end if
			else
				If IsAdd = 1 Then addnum = 0
				If (hasly_day - hasly_day_add) + addnum > numB Then
'If IsAdd = 1 Then addnum = 0
					WatchCustomNumber = "账号今日最多可以领用" & numB & "个客户，已领用了" & (hasly_day-hasly_day_add) & "个，最多还可领用" & (numB-hasly_day + hasly_day_add) & "个客户！"
'If IsAdd = 1 Then addnum = 0
					Exit Function
				end if
			end if
		end if
		WatchCustomNumber = ""
	end function
	sub check_tel_applynum(ByVal gord, byval addnum, ByVal IsAdd)
		message = WatchCustomNumber(gord ,addnum,IsAdd)
		If Len(message)> 0 Then
			showlyEndMsg message
			Exit sub
		end if
	end sub
	Sub salesChangeLog(tord,gord,reason,reasonchildren,f_intro)
		If Len(gord & "") = 0 Then gord = "-1"
'Sub salesChangeLog(tord,gord,reason,reasonchildren,f_intro)
		Dim sql
		sql = " insert into [tel_sales_change_log](tord,sort3,sort,sort1,precateid,newcateid,cateid,date2,date7,reason,reasonchildren,replynum,intro) " &_
		"select ord,sort3,sort,sort1,(case when  '"& reason &"'='1' then 0 else cateid end) as precateid,(case when '"& reason &"'='5' then cateid4 else "& gord &" end) as  newcateid ,'" & session("personzbintel2007") & "' as cateid ,isnull(date2,getdate()) as date2 ,getdate() as date7, '"& reason &"' as reason,'" & reasonchildren &"' as reasonchildren ,(select count(1) from reply where ord2=tel.ord) as replynum,'" & f_intro &"' as intro from tel where ord in (" & tord & ") and (('"& reason &"'<>'1' and isnull(cateid,0)<>"& gord &") or '"& reason &"'='1' ) "
		conn.execute(sql)
	end sub
	Function getOption(HourOrMinute)
		Dim v,vi
		If HourOrMinute="Hour" Then
			For vi=0 To 23
				If vi<10 Then
					v=v & "<option value='0" & vi & "'>0" & vi & "</option>"
				else
					v=v & "<option value='" & vi & "'>" & vi & "</option>"
				end if
			next
		ElseIf HourOrMinute="Minute" Then
			For vi=0 To 55
				If (vi Mod 5)=0 then
					If vi<10 Then
						v=v & "<option value='0" & vi & "'>0" & vi & "</option>"
					else
						v=v & "<option value='" & vi & "'>" & vi & "</option>"
					end if
				end if
			next
		end if
		getOption = v
	end function
	Function isbool(mustcon, strc)
		If InStr(1, "," & mustcon & ",", "," & strc & ",", 1) > 0 Then
			isbool = True
		else
			isbool = False
		end if
	end function
	Function isnuul(boolc, isint, strc)
		Dim ReturnB
		ReturnB = False
		If boolc Then
			If isint > 0 Then
				If strc&"" = "0" Then ReturnB = True
			else
				If Len(strc&"") = 0 Then ReturnB = True
			end if
		end if
		isnuul = ReturnB
	end function
	Function GetFieldID(ByVal name)
		Select Case UCase(Trim(name))
		Case "来源"               : GetFieldID = 6
		Case "区域"               : GetFieldID = 7
		Case "行业"               : GetFieldID = 8
		Case "价值"               : GetFieldID = 9
		Case "网址"               : GetFieldID = 10
		Case "到款"               : GetFieldID = 11
		Case "地址"               : GetFieldID = 12
		Case "邮编"               : GetFieldID = 13
		Case "法人"               : GetFieldID = 14
		Case "注册资本" : GetFieldID = 15
		Case "家庭电话" : GetFieldID = 18
		Case "办公电话" : GetFieldID = 19
		Case "手机"               : GetFieldID = 20
		Case "传真"               : GetFieldID = 21
		Case "电子邮件" : GetFieldID = 22
		Case "QQ"         : GetFieldID = 23
		Case "MSN"                : GetFieldID = 24
		Case "籍贯"               : GetFieldID = 25
		Case "部门"               : GetFieldID = 27
		Case "职务"               : GetFieldID = 28
		Case "联系人"     : GetFieldID = 92
		Case "客户电话" : GetFieldID = 93
		Case "客户传真" : GetFieldID = 94
		Case "客户邮件" : GetFieldID = 95
		Case "已联系"     : GetFieldID = 96
		Case "已项目"     : GetFieldID = 97
		Case "已报价"     : GetFieldID = 98
		Case "已合同"     : GetFieldID = 99
		Case "已收回"     : GetFieldID = 100
		End select
	end function
	Function checkmustcontent(ByVal mustcon,  ByVal mustrole, byval tord)
		checkmustcontent = checkmustcontentBase(mustcon, mustrole, tord, mustcon)
	end function
	Function checkmustcontentBase(ByVal mustcon,  ByVal mustrole, byval tord, ByVal allmustcon)
		Dim Rs, StrR,i,fields,fields1, fid, sql,person_ord
		StrR=""
		Set rs=conn.execute("select top 1 isnull(ly,0),isnull(area,0),isnull(trade,0),isnull(jz,0),len(isnull(url,'')),len(isnull(hk_xz,0)),len(isnull(address,'')),len(isnull(zip,'')),(case when len(isnull(faren,''))>0 or sort2=2 then 1 else 0 end),(case when isnull(zijin,0)>0 or sort2=2 then 1 else 0 end),len(isnull(phone,'')),len(isnull(fax,'')),len(isnull(email,'')) from tel where ord="&tord&"")
		If Not rs.eof Then
			fields=Split("来源,区域,行业,价值,网址,到款,地址,邮编,法人,注册资本,客户电话,客户传真,客户邮件",",")
			For i=0 To ubound(fields)
				fid = GetFieldID(fields(i))
				If isnuul(isbool(mustcon, fid),1,rs(i)) Then
					StrR = StrR & "," & fid
				end if
			next
		end if
		rs.close
		person_ord = ""
		If Len(session("tel_person")&"")>0 And isnumeric(session("tel_person")&"") Then
			person_ord = " and ord ="&session("tel_person")
		end if
		Set rs=conn.execute("select len(isnull(jg,'')),len(isnull(part1,'')),len(isnull(job,'')),len(isnull(phone,'')),len(isnull(phone2,'')),len(isnull(mobile,'')),len(isnull(fax,'')),len(isnull(email,'')),len(isnull(qq,'')),len(isnull(MSN,'')), name,role from person where del<>2 and company="&tord&" "&person_ord)
		checkmustcontentPersons = ""
		Dim itemstr, itemv
		While rs.eof = False
			itemstr = ""
			If isbool(mustcon,GetFieldID("联系人")) Or isbool(mustrole, rs("role").value) then
				fields1=Split("籍贯,部门,职务,办公电话,家庭电话,手机,传真,电子邮件,QQ,MSN",",")
				For i=0 To ubound(fields1)
					itemv = GetFieldID(fields1(i))
					If isnuul(isbool(mustcon,itemv),1, rs(i)) Then
						itemstr = itemstr & "," & itemv
						If InStr(1, "," & strR & "," , "," & itemv & ",", 1) = 0 Then
							strR = strR & "," & itemv
						end if
						If Len(itemstr) > 0 Then
							itemstr = itemstr & ","
						end if
						itemstr = itemstr & itemv
					end if
				next
				If Len(checkmustcontentPersons) > 0 Then
					checkmustcontentPersons = checkmustcontentPersons & "|"
				end if
				checkmustcontentPersons = checkmustcontentPersons & itemstr
			end if
			rs.movenext
		wend
		rs.close
		If isbool(mustcon, GetFieldID("联系人")) Then
			If conn.execute("select 1 from person a where del<>2 and company=" & tord&" "&person_ord).eof Then
				strR = strR & "," & GetFieldID("联系人")
			end if
		end if
		If isbool(mustcon, GetFieldID("已联系")) Then
			Dim resultok
			resultok = True
			If conn.execute("select top 1 1 from reply a inner join tel b on a.ord=b.ord and a.cateid=b.cateid and a.date7 > b.date2 and a.del=1 and a.ord =" & tord).eof=True Then
				resultok =  false
				strR = strR & "," & GetFieldID("已联系")
			end if
			If resultok And Len(mustrole)>0 Then
				arrRole=Split(mustrole,",")
				For i=0 To ubound(arrRole)
					sql = "select 1 from reply a inner join person b on a.del=1 and a.sort1=8 and a.ord2=b.ord " &_
					" and b.del<>2 and b.role='"&arrrole(i)&"' and b.company="& tord &" "&Replace(person_ord,"ord","b.ord") &_
					" and b.company=a.ord inner join tel c on a.ord=c.ord and a.date7 > c.date2"
					If conn.execute(sql).eof=True Then
						strR = strR & "," & GetFieldID("已联系")
						resultok = false
						Exit For
					end if
				next
			end if
			If resultok then
				If isbool(allmustcon, GetFieldID("联系人")) Then
					sql = "select 1 from person a inner join tel c on a.company=c.ord and a.del<>2 and c.ord=" & tord &" "&Replace(person_ord,"ord","a.ord") &_
					" left join reply b on a.ord=b.ord2 and b.sort1=8 and b.del<>2 and b.date7>c.date2 " &_
					" where b.ord is null"
					If conn.execute(sql).eof = false Then
						strR = strR & "," & GetFieldID("已联系")
						resultok = false
					end if
				end if
			end if
		end if
		If isbool(mustcon, GetFieldID("已项目")) Then
			sql = "select top 1 1 from chance where isnull(sp,0)=0 and cateid=(select top 1 cateid from tel where ord="&tord&") and del=1 and charindex('," & tord & ",',','+company+',')>0"
'If isbool(mustcon, GetFieldID("已项目")) Then
			If conn.execute(sql).eof= True Then
				strR = strR & "," & GetFieldID("已项目")
			end if
		end if
		If isbool(mustcon, GetFieldID("已报价")) Then
			sql = "select top 1 1 from price where del=1 and isnull(status,-1) in (-1,1) and cateid=(select top 1 cateid from tel where ord="&tord&") and company=" & tord
'If isbool(mustcon, GetFieldID("已报价")) Then
			If conn.execute(sql).eof=True Then
				strR = strR & "," & GetFieldID("已报价")
			end if
		end if
		If isbool(mustcon, GetFieldID("已合同")) Then
			sql = "select top 1 1 from contract where isnull(sp,0)=0 and cateid=(select top 1 cateid from tel where ord="&tord&") and del=1 and company=" & tord
			If conn.execute(sql).eof=True Then
				strR = strR & "," & GetFieldID("已合同")
			end if
		end if
		If isbool(mustcon, GetFieldID("已收回")) Then
			sql = "select top 1 1 from tousu where del=1 and cateid=(select top 1 cateid from tel where ord="&tord&") and company=" & tord
			If conn.execute(sql).eof=True then
				strR = strR & "," & GetFieldID("已收回")
			end if
		end if
		checkmustcontentBase=StrR
	end function
	Function checkkz_zdy(kzmustcon,tord)
		Dim v ,i, strR
		strR = ""
		v=kzmustcon
		v=Replace(v," ","")
		If v<>"" Then
			v=Split(v,",")
			For i=0 To ubound(v)
				If isnumeric(v(i)) Then
					If conn.execute("select top 1 1 from ERP_CustomValues where FieldsId=" & v(i) & " and OrderId=" & tord & " and isnull(Fvalue,'')<>''").eof=True Then strR = strR & "," & v(i)
				end if
			next
		end if
		checkkz_zdy=strR
	end function
	Function checkzdy(zdymustcon,tord)
		Dim v, i, strR
		strR = ""
		v=zdymustcon
		v=Replace(v," ","")
		If v<>"" Then
			v=Split(v,",")
			For i=0 To ubound(v)
				If isnumeric(v(i)) Then
					If conn.execute("select top 1 1 from tel where isnull(zdy" & v(i) & ",'')<>'' and ord=" & tord ).eof=True Then strR = strR & "," & v(i)
				end if
			next
		end if
		checkzdy=strR
	end function
	Function checkrole(mustrole,mustcon,tord)
		Dim strR,v,i,n
		v=mustrole
		If Len(v&"")>0 Then
			v=Split(v,",")
			For i=0 To ubound(v)
				n=Trim(v(i))
				If Len(n&"")=0 Or isnumeric(n)=False Then n=0
				If isbool(mustcon,96) Then
					If conn.execute("select top 1 1 from person where isnull(role,0)>0 and role=" & n & " and del<>2 and company=" & tord &" and ord in(select ord2 from reply where sort1=8 and del=1)").eof=True Then strR = strR & "," & n
				else
					If conn.execute("select top 1 1 from person where isnull(role,0)>0 and role=" & n & " and del<>2 and company=" & tord ).eof=True Then strR = strR & "," & n
				end if
			next
		end if
		checkrole=strR
	end function
	Function IntToStr(intType,mustConStr,mustRoleStr,mustZdyStr,mustKzStr)
		Dim intlist,nameList,nameList1,nameList2,rss
		intlist=""
		nameList=""
		If intType=1 Then
			If Len(Trim(mustConStr))>0 Then
				intlist=mustConStr
				If Left(intlist,1)="," Then intlist=Right(mustConStr,Len(mustConStr)-1)
'intlist=mustConStr
				Set rss=conn.execute("select gate1,(case when isnull(name,'')='' then oldname else name end ) as name,isnull(show,0) as show,point,enter,format from setfields where gate1 in ( 6,7,8,9,10,11,12,13,14,15,25,27,28,18,19,20,21,23,24,22) order by gate1")
				Do While Not rss.eof
					If isbool(mustConStr,rss(0)) Then nameList2=nameList2 & "【"&rss(1)&"】"
					If (isbool(mustConStr,93) And rss(0)=19) Or (isbool(mustConStr,94) And rss(0)=21) Or (isbool(mustConStr,95) And rss(0)=22) Then nameList1=nameList1 & "【"&rss(1)&"（客户）】"
					rss.movenext
				Loop
				rss.close : Set rss=Nothing
				nameList=nameList & nameList1
				If isbool(mustConStr,92) Then nameList=nameList & "【联系人】"
				nameList=nameList & nameList2
			end if
			If Len(Trim(mustRoleStr))>0 Then nameList=nameList & getmustContent("select ord,sort1 from sort9 where 1=1",1,"ord","sort1",mustRoleStr)
			If Len(Trim(mustZdyStr))>0 Then nameList=nameList & getmustContent("select id,title,name,sort,gl from zdy where sort1=1 and set_open=1 order by gate1 asc",2,"id","title",mustZdyStr)
			If Len(Trim(mustKzStr))>0 Then nameList=nameList & getmustContent("select id,fname from ERP_CustomFields where TName=1 and IsUsing=1 and del=1 order by FOrder asc",3,"id","fname",mustKzStr)
			If Len(Trim(mustConStr))>0 Then
				If isbool(mustConStr,96) Then nameList=nameList & "【已联系】"
				If isbool(mustConStr,97) Then nameList=nameList & "【建立项目】"
				If isbool(mustConStr,98) Then nameList=nameList & "【已报价】"
				If isbool(mustConStr,99) Then nameList=nameList & "【已成交】"
				If isbool(mustConStr,100) Then nameList=nameList & "【关联售后】"
			end if
		end if
		If nameList<>"" Then nameList="\n必填项有：" & nameList
		IntToStr=nameList
	end function
	Public Function getmustContent(sql,keyid,ids,names,model_id)
		Dim f_rs,s
		Set f_rs=conn.execute(sql)
		Do While Not f_rs.eof
			If isbool(model_id,f_rs(ids)) then
				s = s & "【" & f_rs(names) & "】"
			end if
			f_rs.movenext
		Loop
		f_rs.close : Set f_rs=nothing
		getmustContent=s
	end function
	Function canGetCompany(tel_ord,neednum, canly, needsort, intro , needGetApply ,condition,limitsort1,limitsort2,limitsort3,limitsort4,limitsort5,limitsort6,limitsort7,limitsort8,limitsort9, needGetTel, cateid4,sort,sort1,ly,jz,trade,area,zdy5,zdy6, needzdy, ishaszdy5, ishaszdy6)
		Dim islingy,telrs,rs1 , rss ,rss1
		islingy=True
		If Len(tel_ord&"") = 0 Then
			canGetCompany = islingy
			Exit Function
		end if
		If needGetTel = True Then
			set telrs=conn.execute("select * from tel where ord="& tel_ord &" ")
			If telrs.eof = False Then
				cateid4 = telrs("cateid4")
				sort=telrs("sort")
				sort1=telrs("sort1")
				ly=telrs("ly")
				jz=telrs("jz")
				trade=telrs("trade")
				area=telrs("area")
				zdy5=telrs("zdy5")
				zdy6=telrs("zdy6")
			end if
			telrs.close
		end if
		If cateid4&"" = "" Then cateid4 = 0
		If neednum = True Then
			If Len(WatchCustomNumber(member2, 1, 0))>0 Then islingy=False
		else
			islingy = canly
		end if
		If islingy = False Then
			canGetCompany = islingy
			Exit Function
		end if
		If needsort = True Then
			intro = 0
			set rs1=conn.execute("select isnull(intro,0) as intro from setopen where sort1=39 and isnull(intro,0)>0")
			If rs1.eof = False Then
				intro=rs1("intro")
			end if
			rs1.close
		end if
		Dim lysql, qysql
		If intro>0 Then
			If intro=2 Then
				lysql=" and cateid=0"
				qysql=" and ord =0 "
			else
				lysql=" and cateid="& cateid4 &" "
				qysql=" and ord = " & cateid4 &" "
			end if
			If needGetApply Then
				Set rss=conn.execute("select * from tel_apply where 1=1 " & lysql )
				If Not rss.eof Then
					condition=rss("condition")
					limitsort1=rss("limitsort1")
					limitsort2=rss("limitsort2")
					limitsort3=rss("limitsort3")
					limitsort4=rss("limitsort4")
					limitsort5=rss("limitsort5")
					limitsort6=rss("limitsort6")
					If limitsort6&""="" Then limitsort6 = 0
					limitsort7=rss("limitsort7")
					limitsort8=rss("limitsort8")
					limitsort9=rss("limitsort9")
				else
					canGetCompany = islingy
					Exit Function
				end if
				rss.close
			end if
			Dim isfl : isfl=False
			If limitsort1&""<>"" And Len(sort&"")>0 And sort&""<>"0" Then
				If InStr(","&Replace(limitsort1," ","")&",",","&sort&",")>0 Then isfl=True
			ElseIf condition=1 Then
				isfl=True
			ElseIf Len(limitsort1&"")>0 and (Len(sort&"")=0 Or sort&""="0") Then
				isfl=True
			end if
			Dim isgj : isgj=False
			If limitsort2&""<>"" And Len(sort1&"")>0 And sort1&""<>"0" Then
				If InStr(","&Replace(limitsort2," ","")&",",","&sort1&",")>0 Then isgj=True
			ElseIf condition=1 Then
				isgj=True
			ElseIf Len(limitsort2&"")>0 and (Len(sort1&"")=0 Or sort1&""="0") Then
				isgj=True
			end if
			Dim isly : isly=False
			If limitsort3&""<>"" And Len(ly&"")>0 And ly&""<>"0" Then
				If InStr(","&Replace(limitsort3," ","")&",",","&ly&",")>0 Then isly=True
			ElseIf condition=1 Then
				isly=True
			ElseIf Len(limitsort3&"")>0 and (Len(ly&"")=0 Or ly&""="0") Then
				isly=True
			end if
			Dim isjz : isjz=False
			If limitsort4&""<>"" And jz&""<>"0" And Len(jz&"")>0 Then
				If InStr(","&Replace(limitsort4," ","")&",",","&jz&",")>0 Then isjz=True
			ElseIf condition=1 Then
				isjz=True
			ElseIf Len(limitsort4&"")>0 and (Len(jz&"")=0 Or jz&""="0") Then
				isjz=True
			end if
			Dim ishy : ishy=False
			If limitsort5&""<>"" And Len(trade&"")>0 And trade&""<>"0"  Then
				If InStr(","&Replace(limitsort5," ","")&",",","&trade&",")>0 Then ishy=True
			ElseIf condition=1 Then
				ishy=True
			ElseIf Len(limitsort5&"")>0 and (Len(trade&"")>0 Or trade&""="0") Then
				ishy=True
			end if
			Dim isqy : isqy=False
			If limitsort6=1 And Len(area&"")>0 And area&""<>"0" Then
				If conn.execute("select count(id) from tel_area where sort=2 and area="& area &" " & qysql)(0)>0 Then isqy=True
			ElseIf condition=1 Then
				isqy=True
			ElseIf limitsort6=1 and (Len(area&"")=0 Or area&""="0") Then
				isqy=True
			end if
			If needzdy = True Then
				ishaszdy5 = (conn.execute("select 1 from zdy where sort1=1 and set_open=1 and name='zdy5' ").eof = false)
				ishaszdy6 = (conn.execute("select 1 from zdy where sort1=1 and set_open=1 and name='zdy6' ").eof = false)
			end if
			Dim iszdy5 : iszdy5=False
			If ishaszdy5 Then
				If limitsort7&""<>"" And Len(zdy5&"")>0 And zdy5&""<>"0" Then
					If InStr(","&Replace(limitsort7," ","")&",",","&zdy5&",")>0 Then iszdy5=True
				ElseIf condition=1 Then
					iszdy5=True
				ElseIf Len(limitsort7&"")>0 and (Len(zdy5&"")=0 Or zdy5&""="0") Then
					iszdy5=True
				end if
			ElseIf condition=1 Then
				iszdy5=True
			end if
			Dim iszdy6 : iszdy6=False
			If ishaszdy6 Then
				If limitsort8&""<>"" And Len(zdy6&"")>0 And zdy6&""<>"0" Then
					If InStr(","&Replace(limitsort8," ","")&",",","&zdy6&",")>0 Then iszdy6=True
				ElseIf condition=1 Then
					iszdy6=True
				ElseIf Len(limitsort8&"")>0 And (Len(zdy6&"")=0 Or zdy6&""="0") Then
					iszdy6=True
				end if
			ElseIf condition=1 Then
				iszdy6=True
			end if
			Dim iskz : iskz=False
			If limitsort9&""<>"" Then
				Dim kz_zdyfields()
				Dim kz_zdyValue()
				reDim kz_zdyfields(0)
				reDim kz_zdyValue(0)
				Dim j : j=0
				Dim iskz_zdy : iskz_zdy=False
				Set rss1=conn.execute("select id,FValue from ERP_CustomFields f left join (select FieldsID,o.id as FValue from ERP_CustomValues v inner join ERP_CustomOptions o on v.FValue=o.cvalue and o.del=1 where v.OrderID='"& tel_ord &"') a on a.FieldsID = f.id where TName=1 and FType=7 and IsUsing=1 and del=1 order by FOrder asc ")
				While Not rss1.eof
					iskz_zdy=True
					redim Preserve kz_zdyfields(j)
					redim Preserve kz_zdyValue(j)
					kz_zdyfields(j)=rss1("id")
					kz_zdyValue(j)=Trim(rss1("FValue"))
					j=j+1
'kz_zdyValue(j)=Trim(rss1("FValue"))
					rss1.movenext
				wend
				rss1.close
				If iskz_zdy Then
					Dim r , strlm,strlm2 ,strlm_one ,kz_zdy ,kz_id ,kz_str
					strlm=Split(limitsort9,"||")
					strlm2=Split(limitsort9,"||")
					For r=0 To ubound(strlm)
						strlm_one=strlm(r)
						If strlm_one<>"" Then
							kz_zdy=Split(strlm_one,":")
							strlm2(r)=kz_zdy(0)
							strlm(r)=kz_zdy(1)
						end if
					next
					kz_id=Join(strlm2,",")
					kz_str=Join(strlm,",")
					For r=0 To ubound(kz_zdyfields)
						If InStr(","&Replace(kz_id," ",""),","&kz_zdyfields(r)&",")>0 Then
							If InStr(","&Replace(kz_str," ",""),","&kz_zdyValue(r)&",")>0 Or (Len(kz_zdyValue(r))=0 Or kz_zdyValue(r)&""="0") Then
								iskz=True
								If condition=0 Then Exit For
							else
								iskz=False
								If condition=1 Then Exit For
							end if
						end if
					next
				ElseIf condition=1 Then
					iskz=True
				end if
			ElseIf condition=1 Then
				iskz=True
			end if
			If len(limitsort1&"")=0 and len(limitsort2&"")=0 and len(limitsort3&"")=0 and len(limitsort4&"")=0 and len(limitsort5&"")=0 and (len(limitsort6&"")=0 or limitsort6="0") and len(limitsort7&"")=0 and len(limitsort8&"")=0 and len(limitsort9&"")=0 Then
			else
				If condition=1 Then
					If isfl And isgj And isly And isjz And ishy And isqy And iszdy5 And iszdy6 And iskz Then
					else
						islingy=False
					end if
				else
					If (isfl and isgj) Or isly Or isjz Or ishy Or isqy Or iszdy5 Or iszdy6 Or iskz Then
					else
						islingy=False
					end if
				end if
			end if
		end if
		canGetCompany = islingy
	end function
	Function ismobileApp()
		ismobileApp = InStr(Trim(Request.ServerVariables("CONTENT_TYPE")), "application/zsml")>0 Or InStr(Trim(Request.ServerVariables("CONTENT_TYPE")) , "application/json")>0 Or Request.QueryString("__mobile2_debug") = "1"
	end function
	Function WatchCustomExtent(byval uid ,ByVal ID)
		Dim r : r = true
		Dim order1 : order1 = 0
		Dim rs
		Dim resort : resort = ""
		Dim resort1: resort1= ""
		Dim rely : rely =""
		Dim rejz: rejz = ""
		Dim retrade: retrade =""
		Dim rearea: rearea =""
		Dim rezdy5: rezdy5 = ""
		Dim rezdy6: rezdy6 = ""
		Dim rekz : rekz = ""
		Dim telarea : telarea = ""
		if ID> 0 Then
			Set rs = conn.execute("select a.*, b.sex,b.name as person,b.part1,b.job,b.mobile,b.QQ,b.email,b.phone2,b.msn from tel a left join person b on a.person=b.ord where a.ord=" & id )
			If rs.eof = False Then
				order1=rs("order1").value
				resort=rs("sort")
				resort1=rs("sort1")
				rely=rs("ly")
				rejz=rs("jz")
				retrade=rs("trade")
				rearea=rs("area")
				rezdy5=rs("zdy5")
				rezdy6=rs("zdy6")
				telarea = rs("area")
			end if
			rs.close
			Set rs = conn.execute("select id,CValue from ERP_CustomOptions where CFID in (select id from ERP_CustomFields where TName=1 and IsUsing=1 and del=1 and FType=7) and  CValue=(select top 1 FValue from ERP_CustomValues where  FieldsID=ERP_CustomOptions.CFID and OrderID="& id & " )")
			While rs.eof=False
				If Len(rekz)>0 Then rekz = rekz & ","
				rekz = rekz & rs("id")
				rs.movenext
			wend
			rs.close
		end if
		If order1<>1 Then
			Dim intro : intro = 0
			Set rs = conn.execute("select isnull(intro,0) as intro from setopen where sort1=39 and isnull(intro,0)>0")
			If rs.eof = False Then
				intro = rs("intro").value
			else
				WatchCustomExtent = True
				Exit Function
			end if
			rs.close
			Dim lysql: lySql = " and cateid=" & uid &  " and isnull(del,1)=1 "
			Dim qysql: qysql = " and ord=" & uid
			if intro = 2 Then
				lySql = " and cateid=0"
				qysql = " and ord=0 "
			end if
			Dim condition :condition = 0
			Set rs = conn.execute("select * from tel_apply where 1=1 " & lySql)
			If rs.eof = True Then
				WatchCustomExtent = True
				Exit Function
			else
				condition = rs("condition").value
				Dim sort , sort1 ,ly,jz,trade ,area ,zdy5 , zdy6
				If ismobileApp = True Then
					sort = Split(app.mobile("sort1"),",")(0)
					sort1 = Split(app.mobile("sort1"),",")(1)
					ly = app.mobile("ly")
					jz = app.mobile("jz")
					trade = app.mobile("trade")
					area = app.mobile("area")
					zdy5 = app.mobile("zdy5")
					zdy6 = app.mobile("zdy6")
				else
					sort = request("sort")
					sort1 = request("sort1")
					ly = request("ly")
					jz = request("jz")
					trade = request("trade")
					area =  request("area")
					zdy5 = request("zdy5")
					zdy6 = request("zdy6")
				end if
				Dim fields : Set fields = GetFields(1)
				Dim isfl : isfl = tel_canLy(condition, rs("limitsort1").value & "", sort, resort , fields.GetItemByDBname("sort").show)
				Dim isgj : isgj = tel_canLy(condition, rs("limitsort2").value & "", sort1, resort1, fields.GetItemByDBname("sort1").show)
				Dim isly : isly = tel_canLy(condition, rs("limitsort3").value & "", ly, rely, fields.GetItemByDBname("ly").show)
				Dim isjz : isjz = tel_canLy(condition, rs("limitsort4").value & "", jz, rejz, fields.GetItemByDBname("jz").show)
				Dim ishy : ishy = tel_canLy(condition, rs("limitsort5").value & "", trade, retrade, fields.GetItemByDBname("trade").show)
				Dim isqy : isqy = false
				if Len(area&"") = 0 then area = telarea
				if rs("limitsort6")= 1 and Len(area)>0 Then
					isqy = (conn.execute("select top 1 id from tel_area where sort=2 and area=" & area & qysql &"").eof =False )
					if area= rearea Then isqy = true
				elseif rs("limitsort6") = 0 and Len(area)= 0 And fields.GetItemByDBname("area").show=True Then
					isqy = true
				ElseIf condition=1 Then
					isqy = true
				end if
				Dim zdyfields : Set zdyfields = GetZdyFields(1)
				Dim iszdy5 : iszdy5 = tel_canLy(condition, rs("limitsort7").value & "", zdy5, rezdy5, zdyfields.GetItemByDBname("zdy5").show )
				Dim iszdy6 : iszdy6 = tel_canLy(condition, rs("limitsort8").value & "", zdy6, rezdy6, zdyfields.GetItemByDBname("zdy6").show )
				Dim limitsort9 : limitsort9 = rs("limitsort9").value & ""
				Dim iskz : iskz = ExtendedLy(condition, limitsort9, rekz)
				if Len(rs("limitsort1")&"")>0 Or Len(rs("limitsort2")&"")>0 Or Len(rs("limitsort3")&"")>0 Or Len(rs("limitsort4")&"")>0 Or Len(rs("limitsort5")&"")>0 Or rs("limitsort6")=1 Or Len(rs("limitsort7")&"")>0 Or Len(rs("limitsort8")&"")>0 Or Len(limitsort9&"")>0 Then
					if condition = 1 Then
						if isfl = false Or isgj = false or isly = false or isjz = false or ishy = false or isqy = false or iszdy5 = false or iszdy6 = false or iskz = False Then r = false
					else
						if (isfl and isgj) = false and isly = false and isjz = false and ishy = false and isqy = false and iszdy5 = false and iszdy6 = False and iskz = False Then r = false
					end if
				end if
			end if
			rs.close
		end if
		WatchCustomExtent = r
	end function
	Function tel_canLy(ByVal typeCondition ,byval limit ,byval  newValue , byval oldValue , byval show)
		Dim r : r = false
		limit = Replace(limit , " ", "")
		if Len(limit) > 0 And Len(newValue) > 0 Then
			if Len(oldValue)> 0 Then  limit = limit & "," & oldValue
			if instr("," & limit & "," , "," & newValue & ",") > 0 Then  r = true
		elseif  Len(limit) > 0 and Len(newValue)= 0 and show Then
			r = true
		elseif typeCondition = 1 Then
			r = true
		end if
		tel_canLy = r
	end function
	Function ExtendedLy(ByVal typeCondition, Byref limit ,ByVal oldValue)
		Dim i
		Dim r : r = False
		If Len(limit)>0 Then
			Dim kz_id : kz_id = ""
			Dim kz_str : kz_str = ""
			Dim strlm : strlm = Split(limit ,"or")
			For i = 0 To ubound(strlm)
				if Len(strlm(i))> 0 Then
					if len(kz_id)> 0 Then kz_id = kz_id & ","
					if len(kz_str)> 0 Then kz_str = kz_str & ","
					kz_id = kz_id & Split(strlm(i) ,":")(0)
					kz_str = kz_str & Split(strlm(i) ,":")(1)
				end if
				if Len(oldValue)> 0 Then kz_str = kz_str & "," & oldValue
			next
			Dim extrafields : Set extrafields = GetExtraFields(1)
			Dim OID , hasKz , field
			hasKz = False
			For i = 0 To extrafields.count-1
'hasKz = False
				Set field = extrafields.item(i)
				If field.show = True And field.sorttype = 7 Then
					If ismobileApp = True Then
						OID = app.mobile("meju_" & field.Key )
					else
						OID = request("meju_" & field.Key )
					end if
					if instr("," & kz_id & ",","," & field.Key & ",") > 0 Then
						hasKz = True
						if instr("," & kz_str & ",","," & OID & ",") > 0 Or Len(OID)=0 Then
							r = true
							if typeCondition = 0 Then Exit For
						else
							r = false
							if typeCondition = 1 Then Exit For
						end if
					end if
				end if
			next
			If hasKz = False Then
				limit = ""
				If typeCondition = 1 Then r = True
			end if
		elseif typeCondition = 1 Then
			r = true
		end if
		ExtendedLy= r
	end function
	Function CustomReviewWatchs(id)
		Dim r : r = False
		Dim rs , rss
		Dim fields : Set fields = GetFields(1)
		if id = 0 or ( id > 0 And conn.execute("select ord from tel where ord='" & id & "' and (datediff(d,getdate(),date1)>=0 or isnull(sp,0)<>0) ").eof= False ) Then
			Dim condition :condition = 0
			Set rs= conn.execute("select * from tel_review ")
			If rs.eof = False Then
				condition = rs("condition").value
				Dim sort , sort1 ,ly,jz,trade ,area ,zdy5 , zdy6
				If ismobileApp = True Then
					sort = Split(app.mobile("sort1"),",")(0)
					sort1 = Split(app.mobile("sort1"),",")(1)
					ly = app.mobile("ly")
					jz = app.mobile("jz")
					trade = app.mobile("trade")
					area = app.mobile("area")
					zdy5 = app.mobile("zdy5")
					zdy6 = app.mobile("zdy6")
				else
					sort = request("sort")
					sort1 = request("sort1")
					ly = request("ly")
					jz = request("jz")
					trade = request("trade")
					area =  request("area")
					zdy5 = request("zdy5")
					zdy6 = request("zdy6")
				end if
				Dim isfl : isfl = hasReview(condition, rs("limitsort1")&"", sort, fields.GetItemByDBname("sort").show)
				Dim isgj : isgj = hasReview(condition, rs("limitsort2")&"", sort1, fields.GetItemByDBname("sort1").show)
				Dim isly : isly = hasReview(condition, rs("limitsort3")&"", ly, fields.GetItemByDBname("ly").show)
				Dim isjz : isjz = hasReview(condition, rs("limitsort4")&"", jz, fields.GetItemByDBname("jz").show)
				Dim ishy : ishy = hasReview(condition, rs("limitsort5")&"", trade, fields.GetItemByDBname("trade").show)
				Dim isqy : isqy = false
				if rs("limitsort6")= 1 Then
					if Len(area)>0 Then
						isqy = (conn.execute("select top 1 id from tel_area where sort=1 and area=" & area &"").eof =False )
					elseif condition= 1 And fields.GetItemByDBname("area").show=False Then
						isqy = True
					end if
				Elseif condition= 1 Then
					isqy = True
				end if
				Dim zdyfields : Set zdyfields = GetZdyFields(1)
				Dim iszdy5 : iszdy5 = hasReview(condition, rs("limitsort7")&"", zdy5,  zdyfields.GetItemByDBname("zdy5").show )
				Dim iszdy6 : iszdy6 = hasReview(condition, rs("limitsort8")&"", zdy6, zdyfields.GetItemByDBname("zdy6").show )
				Dim limitsort9 : limitsort9 = rs("limitsort9")&""
				Dim iskz : iskz = ExtendedReview(condition, limitsort9)
				if Len(rs("limitsort1")&"")>0 Or Len(rs("limitsort2")&"")>0 Or Len(rs("limitsort3")&"")>0 Or Len(rs("limitsort4")&"")>0 Or Len(rs("limitsort5")&"")>0 Or rs("limitsort6")=1 Or Len(rs("limitsort7")&"")>0 Or Len(rs("limitsort8")&"")>0 Or Len(limitsort9&"")>0 Then
					if condition = 1 Then
						if isfl and isgj and isly and isjz and ishy and isqy and iszdy5 and iszdy6 and iskz Then  r = true
					else
						if (isfl and isgj) or isly or isjz or ishy or isqy or iszdy5 or iszdy6 or iskz Then  r = true
					end if
				end if
			end if
		end if
		CustomReviewWatchs = r
	end function
	Function hasReview(ByVal condition , ByVal limit , ByVal newValue ,ByVal show)
		Dim r : r = false
		limit = Replace(limit, " ", "")
		if Len(limit) > 0 Then
			if Len(newValue) > 0 Then
				If instr("," & limit & "," , "," & newValue & ",") > 0  Then  r = true
			elseif show=False and condition = 1 Then
				r = true
			end if
		elseif condition=1 Then
			r = True
		end if
		hasReview = r
	end function
	Function ExtendedReview(ByVal typeCondition, Byref limit)
		Dim r ,i ,field
		r = False
		If Len(limit)>0 Then
			Dim kz_id : kz_id = ""
			Dim kz_str : kz_str = ""
			Dim strlm : strlm = Split(limit ,"or")
			For i = 0 To ubound(strlm)
				if Len(strlm(i))> 0 Then
					if len(kz_id)> 0 Then kz_id = kz_id & ","
					if len(kz_str)> 0 Then kz_str = kz_str & ","
					kz_id = kz_id & Split(strlm(i) ,":")(0)
					kz_str = kz_str & Split(strlm(i) ,":")(1)
				end if
			next
			Dim extrafields : Set extrafields = GetExtraFields(1)
			Dim OID , hasKz
			hasKz = False
			For i = 0 To extrafields.count-1
'hasKz = False
				Set field = extrafields.item(i)
				If field.show = True And field.sorttype = 7 Then
					If ismobileApp = True Then
						OID = app.mobile("meju_" & field.Key )
					else
						OID = request("meju_" & field.Key )
					end if
					if instr("," & kz_id & ",","," & field.Key & ",") > 0 Then
						hasKz = True
						if instr("," & kz_str & ",","," & OID & ",") > 0 and Len(OID)>0 Then
							r = true
							if typeCondition = 0 Then Exit For
						else
							r = false
							if typeCondition = 1 Then Exit For
						end if
					end if
				end if
			next
			If hasKz = False Then
				limit = ""
				If typeCondition = 1 Then r = True
			end if
		elseif typeCondition = 1 Then
			r = true
		end if
		ExtendedReview = r
	end function
	Public pub_cf,KZ_LIMITID
	Function getExtended(TName,ord)
		Call showExtended(TName,ord,3,1,1)
	end function
	function ShowExtendedByProductGroup(byval TName,byval ord,byval columns, byval col1, byval col2 ,byval isIntro ,byval bzstr ,byval tsstr ,byval oldZdySort ,byval readonly,byval zdygroupid)
		if zdygroupid = 0 then zdygroupid = -1
		dim rss
		Response.write "" & vbcrlf & "       <tr class=""top accordion"" id=""cpBasezdygroup"">" & vbcrlf & "      <td colspan=""6"" class=""accordion-bar-bg"">" & vbcrlf & "           <div  class=""accordion-bar-tit"" style=""padding-top:6px;"">" & vbcrlf & "                   自定义字段 <span class=""accordion-arrow-down""></span>" & vbcrlf & "             </div>" &vbcrlf & "          <div onclick=""app.stopDomEvent();return false"" style=""float:left;padding:5px"">" & vbcrlf & "              &nbsp;" & vbcrlf & "          "
		if readonly then
			dim wsql : wsql = " and  ord="  & clng(zdygroupid)
			if zdygroupid = -1 then wsql=" and tagdata='1' "
'dim wsql : wsql = " and  ord="  & clng(zdygroupid)
			set rss = conn.execute("select ord, sort1, tagdata from sortonehy where gate2=63 and ord=" & zdygroupid)
			if rss.eof = false then
				Response.write rss("sort1").value
			end if
			rss.close
		else
			Response.write "" & vbcrlf & "              <select name=""zdygroupid"" style=""min-width:100px"" onchange=""refreshProductGroupArea("
			rss.close
			Response.write ord
			Response.write ", this)"">" & vbcrlf & "                  "
			set rss = conn.execute("select ord, (case tagdata when '1' then '' else sort1 end) as sort1, tagdata from sortonehy where gate2=63 order by gate1 desc")
			while rss.eof = false
				tagdata = rss("tagdata").value
				sortord =rss("ord").value
				if tagdata = "1" then sortord = 0
				if zdygroupid = sortord then
					Response.write "<option value='" & sortord & "' selected>" & rss("sort1").value & "</option>"
				else
					Response.write "<option value='" & sortord & "'>" & rss("sort1").value & "</option>"
				end if
				rss.movenext
			wend
			rss.close
			Response.write "" & vbcrlf & "              </select>" & vbcrlf & "               <script>" & vbcrlf & "                        function refreshProductGroupArea(billord,  sbox ){" & vbcrlf & "                              var  x = new XMLHttpRequest();" & vbcrlf & "                          x.open(""Get"", window.sysCurrPath + ""inc/GetExtended.ProductGroup.asp?t="" + (new Date()).getTime() + ""&billord="" + billord + ""&groupid="" + sbox.value,  false)" & vbcrlf & "                          x.send();" & vbcrlf & "                               var html = x.responseText;" & vbcrlf & "                              x = null;" & vbcrlf & "                               var myrow = $(""#cpBasezdygroup"");" & vbcrlf & "                         var currgprow = $(""tr.zdyrowgroup1"");" & vbcrlf & "                             currgprow.remove(); "& vbcrlf & "                               if(html.length>0 && html.indexOf(""<tr"")>=0) " & vbcrlf & "                              {" & vbcrlf & "                                               myrow.after(html)" & vbcrlf & "                               }" & vbcrlf & "                               if(window.BillExtSN){" & vbcrlf & "                                   window.BillExtSN.BindKeys = undefined;" & vbcrlf & "                                  jQuery(""input[type=text]"").unbind(""blur"", window.BillExtSN.Refresh).bind(""blur"", window.BillExtSN.Refresh);" & vbcrlf & "                                       jQuery(""input[type=checkbox]"").unbind(""click"", window.BillExtSN.Refresh).bind(""click"", window.BillExtSN.Refresh);" & vbcrlf & "                                     jQuery(""input[type=radio]"").unbind(""click"", window.BillExtSN.Refresh).bind(""click"", window.BillExtSN.Refresh)" & vbcrlf & "                                   jQuery(""select"").unbind(""change"", window.BillExtSN.Refresh).bind(""change"", window.BillExtSN.Refresh);" & vbcrlf & "                                 jQuery(""textarea"").unbind(""blur"", window.BillExtSN.Refresh).bind(""blur"", window.BillExtSN.Refresh);" & vbcrlf &"                                  var data = [];" & vbcrlf & "                                  var CatchFields = [];" & vbcrlf & "                                   var frm = document.getElementsByTagName(""form"")[0];" & vbcrlf & "                                       if (!frm) { return; }" & vbcrlf & "                                   var boxs = jQuery(frm).serializeArray();" & vbcrlf & "                                        for (var i = boxs.length - 1; i >= 0; i--) {" & vbcrlf & "                                           if (i > 0 && boxs[i].name == boxs[i - 1].name) {" & vbcrlf & "                                                        boxs[i - 1].value = boxs[i - 1].value + "","" + boxs[i].value;" & vbcrlf & "                                                      boxs[i].name = """";" & vbcrlf & "                                                } else {" & vbcrlf & "                                                        var n = boxs[i].name;" & vbcrlf & "                                                   var box = document.getElementsByName(n)[0];" & vbcrlf & "                                                        if (box.tagName == ""SELECT"") {" & vbcrlf & "                                                            boxs.push({ name: boxs[i].name + ""_selectvalue"", value: (boxs[i].value + """") });" & vbcrlf & "                                                            boxs[i].value = box.options[box.options.selectedIndex].text;" & vbcrlf & "                                                    }" & vbcrlf & "               }" & vbcrlf & "                                       }" & vbcrlf & "                                       for (var i = 0; i < boxs.length; i++) {" & vbcrlf & "                                         var ibox = boxs[i];" & vbcrlf & "                                             var n = ibox.name;" & vbcrlf & "                                              if (n) {" & vbcrlf & "                                                        CatchFields.push(n);" & vbcrlf & "                                                    if (ibox.value.length < 200) { //200字限制" & vbcrlf & "                                                         data.push(n + ""="" + encodeURIComponent(encodeURIComponent(ibox.value)));" & vbcrlf & "                                                  } else {" & vbcrlf & "                                                                data.push(n + ""="");" & vbcrlf & "                                                       }" & vbcrlf & "                                               }" & vbcrlf & "                                       }" & vbcrlf & "                                       data.push(""__CatchFields="" + encodeURIComponent(CatchFields.join(""|"")));" & vbcrlf & "                                  data.push(""__BillTypeId="" + window.BillExtSN.CodeType);" & vbcrlf & "                                   var xhttp = window.XMLHttpRequest ? (new XMLHttpRequest()):(new ActiveXObject(""Microsoft.XMLHTTP""));" & vbcrlf & "                                      xhttp.open(""POST"", ((window.sysCurrPath ? (window.sysCurrPath + ""../"") : window.SysConfig.VirPath) + ""SYSN/view/comm/GetBHValue.ashx?GB2312=1""), false);" & vbcrlf & "                                      xhttp.setRequestHeader(""content-type"", ""application/x-www-form-urlencoded"");" & vbcrlf & "                                        xhttp.send(data.join(""&""));" & vbcrlf & "                                       var obj = eval(""("" + xhttp.responseText + ""4)"");" & vbcrlf &                                   "  window.BillExtSN.BindKeys = obj.keys; "& vbcrlf &                                   " //window.BillExtSN.ReBindEvt();" & vbcrlf &                         " }" & vbcrlf &                       " } "& vbcrlf &               " </script> "& vbcrlf & ""
		end if
		Response.write "" & vbcrlf & "              </div>" & vbcrlf & "  </tr>" & vbcrlf & "   "
		call ShowExtendedByKZZDY( TName, ord, columns,  col1,  col2 , false , bzstr , tsstr , oldZdySort , readonly, zdygroupid)
		call ShowExtendedByKZZDY( TName, ord, 1,  col1,  columns*2-1 , true , bzstr , tsstr , oldZdySort , readonly, zdygroupid)
	end function
	function ShowExtendedByKZZDY(byval TName,byval ord,byval columns, byval col1, byval col2 ,byval isIntro ,byval bzstr ,byval tsstr ,byval oldZdySort ,byval readonly,byval zdygroupid)
		dim rs_kz_zdy, rs_kz_zdy_88, sql, rs7, sql7 , introsql
		dim  num1, i_jm, j_jm, c_Value,colstr1,colstr2,rssort,moneyDigits,numDigits,priceDigits
		set rssort=conn.execute("select num1 from setjm3 where ord=1")
		if not rssort.eof then
			moneyDigits=rssort(0)
		else
			moneyDigits=2
		end if
		set rssort=conn.execute("select num1 from setjm3 where ord=2019042802")
		if not rssort.eof then
			priceDigits=rssort(0)
		else
			priceDigits=2
		end if
		set rssort=conn.execute("select num1 from setjm3 where ord=88")
		if not rssort.eof then
			numDigits=rssort(0)
		else
			numDigits=2
		end if
		If col1>1 Then colstr1= " colspan='"&col1&"'"
		If col2>1 Then colstr2= " colspan='"&col2&"'"
		if TName=1001 or ord=-1 Then columns=2
'If col2>1 Then colstr2= " colspan='"&col2&"'"
		If ord = "" Then ord=0
		if isIntro=false then
			introsql = " and uitype<>13  "
		else
			introsql = " and uitype=13  "
		end if
		dim id, FName , dname , UiType,MustFillin,TextLen
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		sql="select *,case Id when 1 then 7 when 2 then 8 when 3 then 9 when 4 then 10 when 5 then 11 when 6 then 12 else Id end zdyid, 0 as mustshow, ' ' as arename  "
		sql = sql + " from sys_sdk_BillFieldInfo where billtype="& TName &" and ListType='0' and isused = 1 "& introsql & " and ProductZdyGroupId=" & clng(zdygroupid)
		sql = sql + " order by RootDataType desc, Showindex "
		rs_kz_zdy.open sql,conn,1,1
		num1=rs_kz_zdy.RecordCount
		i_jm=0
		j_jm=1
		if rs_kz_zdy.eof = False then
			Response.write("<tr class='zdyrowgroup" + cstr(abs(zdygroupid*1>0)) + "'>")
'if rs_kz_zdy.eof = False then
			do until rs_kz_zdy.eof
				if clng(i_jm/columns)=i_jm/columns and i_jm<>0 then
					Response.write("</tr><tr class='zdyrowgroup" + cstr(abs(zdygroupid*1>0)) + "'>")
'if clng(i_jm/columns)=i_jm/columns and i_jm<>0 then
					j_jm=j_jm+1
'if clng(i_jm/columns)=i_jm/columns and i_jm<>0 then
				end if
				c_Value=""
				id = rs_kz_zdy("zdyid")
				FName = rs_kz_zdy("title")
				dname = rs_kz_zdy("dbname")
				UiType = rs_kz_zdy("UiType")
				MustFillin = rs_kz_zdy("MustFillin")
				netid = rs_kz_zdy("id")
				TextLen = rs_kz_zdy("TextLen")
				Response.write "" & vbcrlf & "                     <td width=""11%"" align=""right"" "
				Response.write colstr1
				Response.write ">"
				Response.write FName
				Response.write "：</td>" & vbcrlf & "                      <td width=""22%"" "
				if i_jm=num1-1  then
					Response.write "：</td>" & vbcrlf & "                      <td width=""22%"" "
					Response.write "colspan="""
					Response.write col2+(col1+col2)*(j_jm*columns-num1)
					Response.write "colspan="""
					Response.write """ "
				else
					Response.write colstr2
				end if
				Response.write ">" & vbcrlf & "                    "
				if instr(dname,"ext")>0 then
					zid = replace(dname&"","ext","")
					Set rs_kz_zdy_88=conn.execute("select FValue from ERP_CustomValues where FieldsID="& zid &" and OrderID="&ord&" and OrderID>0 ")
					If rs_kz_zdy_88.eof = False  Then c_Value=rs_kz_zdy_88("FValue")
					rs_kz_zdy_88.close
					if readonly then
						select case UiType
						case 31 :
						Response.write "<span class=""gray ewebeditorImg"">&nbsp;"
						Response.write replace(c_Value,",","->")
						Response.write "<span class=""gray ewebeditorImg"">&nbsp;"
						Response.write "</span>"
						case 2 :
						Response.write "<span class=""gray ewebeditorImg"">&nbsp;"
						Response.write getExtendedValue(c_Value,numDigits)
						Response.write "</span>"
						case 3 :
						Response.write "<span class=""gray ewebeditorImg"">&nbsp;"
						Response.write getExtendedValue(c_Value,moneyDigits)
						Response.write "</span>"
						case 3000 :
						Response.write "<span class=""gray ewebeditorImg"">&nbsp;"
						Response.write getExtendedValue(c_Value,priceDigits)
						Response.write "</span>"
						Case Else:
						Response.write "<span class=""gray ewebeditorImg"">&nbsp;"
						Response.write c_Value
						Response.write "</span>"
						end select
					else
						c_Value=replace(replace(c_Value&"","""","&#34;"),"'","&#39;")
						select case UiType
						case 0 :
						Response.write "" & vbcrlf & "                                     <input name=""danh_"
						Response.write zid
						Response.write """ type=""text"" size=""15"" id=""danh_"
						Response.write zid
						Response.write """ value="""
						Response.write c_Value
						Response.write """ dataType=""Limit"" "
						if MustFillin=1  then
							Response.write " min=""1""  msg=""必须在1到"
							Response.write TextLen
							Response.write "个字符之间""  "
						else
							Response.write " msg=""长度不能超过"
							Response.write TextLen
							Response.write "个字"" "
						end if
						Response.write "  max="
						Response.write TextLen
						Response.write " maxlength=""4000"">" & vbcrlf & "                                     "
						case 1:
						Response.write "" & vbcrlf & "                                     <input class=""resetDataPickerBg"" readonly name=""date_"
						Response.write zid
						Response.write """ value="""
						Response.write c_Value
						Response.write """ size=""15"" id=""daysOfMonthPos"" onmouseup=""toggleDatePicker('daysOfMonth_"
						Response.write zid
						Response.write "','date_"
						Response.write zid
						Response.write "')"" dataType=""Limit"" "
						if MustFillin=1 then
							Response.write " min=""1"" "
						end if
						Response.write " max=""500"" msg=""请选择日期"" style=""background-image:url(../images/datePicker.gif);background-position:93px;width:111px;;background-repeat:no-repeat;""> <div id=""daysOfMonth_"
						Response.write " min=""1"" "
						Response.write zid
						Response.write """ style=""POSITION:absolute""></div>" & vbcrlf & "                                  "
						case 2:
						Response.write "" & vbcrlf & "                                     <input name=""Numr_"
						Response.write zid
						Response.write """ type=""text"" value="""
						Response.write c_Value
						Response.write """ size=""15"" id=""Numr_"
						Response.write zid
						Response.write """ onpropertychange=""formatData(this,'number')"" dataType=""Limit"" "
						if MustFillin=1 then
							Response.write " min=""1"" "
						end if
						Response.write "  max=""500""  msg=""必须在1到500个字符"" >" & vbcrlf & "                                  "
						case 3:
						Response.write "" & vbcrlf & "                                     <input name=""danh_"
						Response.write zid
						Response.write """ type=""text"" value="""
						Response.write c_Value
						Response.write """ size=""15"" id=""Numr_"
						Response.write zid
						Response.write """ onpropertychange=""formatData(this,'money')""  dataType=""Limit"" "
						if MustFillin=1 then
							Response.write " min=""1"" "
						end if
						Response.write "  max=""500""  msg=""必须在1到500个字符"" >" & vbcrlf & "                                  "
						case 36:
						Response.write "" & vbcrlf & "                                     <input name=""danh_"
						Response.write zid
						Response.write """ type=""text"" value="""
						Response.write c_Value
						Response.write """ size=""15"" id=""Numr_"
						Response.write zid
						Response.write """  onpropertychange=""formatData(this,'int')""   dataType=""Limit"" "
						if MustFillin=1 then
							Response.write " min=""1"" "
						end if
						Response.write "  max=""500""  msg=""必须在1到500个字符"" >" & vbcrlf & "                                  "
						case 3000:
						Response.write "" & vbcrlf & "                                     <input name=""danh_"
						Response.write zid
						Response.write """ type=""text"" value="""
						Response.write c_Value
						Response.write """ size=""15"" id=""Numr_"
						Response.write zid
						Response.write """ onpropertychange=""formatData(this,'CommPrice')"" dataType=""Limit"" "
						if MustFillin=1 then
							Response.write " min=""1"" "
						end if
						Response.write "  max=""500""  msg=""必须在1到500个字符"" >" & vbcrlf & "                                  "
						case 4:
						Response.write "" & vbcrlf & "                                     <select name=""IsNot_"
						Response.write zid
						Response.write """ id=""IsNot_"
						Response.write zid
						Response.write """  dataType=""Limit"" "
						if MustFillin=1 then
							Response.write " min=""1"" "
						end if
						Response.write "  max=""500""  msg=""必须在1到500个字符"">" & vbcrlf & "                                   <option value=""是"" "
						If c_Value="是" then
							Response.write "selected"
						end if
						Response.write ">是</option>" & vbcrlf & "                                 <option value=""否"" "
						If c_Value="否" then
							Response.write "selected"
						end if
						Response.write ">否</option>" & vbcrlf & "                                 </select>" & vbcrlf & "                                       "
						case 5:
						Response.write "" & vbcrlf & "                                     <select name=""meju_"
						Response.write zid
						Response.write """ id=""meju_"
						Response.write zid
						Response.write """  dataType=""Limit"" "
						if MustFillin=1 then
							Response.write " min=""1"" "
						end if
						Response.write "  max=""500""  msg=""必须在1到500个字符"">" & vbcrlf & "                                   "
						xxsql = "select t1.id, t1.CValue from (select id,CValue from ERP_CustomOptions x  where CFID="& zid &") t1 "
						xxsql = xxsql & " inner join  (select [text], ShowIndex  from  sys_sdk_BillFieldOptionsSource where  Stoped=0 and FieldId=" & netid & "  ) t2  " &_
						" on t1.CValue = t2.[text]  order by t2.showindex "
						set rs7=conn.execute(xxsql)
						do until rs7.eof
							Response.write "" & vbcrlf & "                                             <option value="""
							Response.write rs7("id")
							Response.write """ "
							If rs7("CValue")&""=c_Value&"" then
								Response.write "selected"
							end if
							Response.write ">"
							Response.write rs7("CValue")
							Response.write "</option>" & vbcrlf & "                                            "
							rs7.movenext
						loop
						rs7.close
						Response.write "" & vbcrlf & "                                 </select>" & vbcrlf & "                                   "
						case 54:
						cixx = 0
						xxsql = "select t1.id, t1.CValue from (select id,CValue from ERP_CustomOptions x  where CFID="& zid &") t1 "
						xxsql = xxsql & " inner join  (select [text], ShowIndex  from  sys_sdk_BillFieldOptionsSource where  Stoped=0 and FieldId=" & netid & "  ) t2  " &_
						" on t1.CValue = t2.[text]  order by t2.showindex "
						set rs7=conn.execute(xxsql)
						do until rs7.eof
							Response.write "" & vbcrlf & "                                                      <input name=""danh_"
							Response.write zid
							Response.write """ id=""danh_"
							Response.write zid
							Response.write "_"
							Response.write cixx
							Response.write """ "
							if  instr("," & c_value   & ",", "," & rs7("CValue").value & ",")>0 then Response.write "checked"
							Response.write "  type=""checkbox"" value="""
							Response.write replace(rs7("CValue").value & "", """","&#34")
							Response.write """ >" & vbcrlf & "                                                       <label for=""danh_"
							Response.write zid
							Response.write "_"
							Response.write cixx
							Response.write """>"
							Response.write replace(rs7("CValue").value & "", """","&#34")
							Response.write "</label>" & vbcrlf & "                                             "
							cixx = cixx +1
							Response.write "</label>" & vbcrlf & "                                             "
							rs7.movenext
						loop
						rs7.close
						case 31:
						Response.write "" & vbcrlf & "                                     <select name=""danh_"
						Response.write zid
						Response.write """ id=""danh_"
						Response.write zid
						Response.write """  dataType=""Limit"" "
						if MustFillin=1 then
							Response.write " min=""1"" "
						end if
						Response.write "  max=""500""  msg=""必须在1到500个字符"">" & vbcrlf & "                                   "
						exitsgp = false
						ptxt = ""
						xxsql =  "select  [Text] as cvalue, deep  from sys_sdk_BillFieldOptionsSource a "
						xxsql = xxsql & " where  Stoped=0 and FieldId=" & netid & " "
						xxsql = xxsql & " and ( ParentId=0 or exists(select 1 from  sys_sdk_BillFieldOptionsSource b where a.ParentId=b.id and b.Stoped=0) )"
						xxsql = xxsql & " order by ShowIndex "
						set rs7=conn.execute(xxsql)
						do until rs7.eof
							if rs7("deep").value=0 then
								if exitsgp then Response.write "</optgroup>"
								Response.write " <optgroup label=""" &  rs7("cvalue")  & """>"
								ptxt  = rs7("cvalue").value
								exitsgp = true
							else
								myvalue = ptxt & "," & rs7("CValue")
								Response.write "" & vbcrlf & "                                             <option value="""
								Response.write myvalue
								Response.write """ "
								If myvalue&""=c_Value&"" then
									Response.write "selected"
								end if
								Response.write ">"
								Response.write rs7("CValue")
								Response.write "</option>" & vbcrlf & "                                            "
							end if
							rs7.movenext
						loop
						rs7.close
						if exitsgp then Response.write "</optgroup>"
						Response.write "" & vbcrlf & "                                 </select>" & vbcrlf & "                                   "
						case 10:
						Response.write "" & vbcrlf & "                        <textarea name=""duoh_"
						Response.write zid
						Response.write """ id=""duoh_"
						Response.write zid
						Response.write """ style=""overflow-y:hidden;word-break:break-all;width:160px;height:22px;padding-left:4px;"" onfocus=""this.style.height=this.scrollHeight"" onpropertychange=""this.style.height=this.scrollHeight"" dataType=""Limit"" "
						Response.write zid
						if MustFillin=1 then
							Response.write " min=""1""   msg=""必须在1到"
							Response.write TextLen
							Response.write "个字符之间"" "
						else
							Response.write " msg=""长度不能超过"
							Response.write TextLen
							Response.write "个字"" "
						end if
						Response.write " max="
						Response.write TextLen
						Response.write ">"
						Response.write c_Value
						Response.write "</textarea>" & vbcrlf & "                        "
						case 13:
						Response.write "" & vbcrlf & "                        <textarea name=""beiz_"
						Response.write zid
						Response.write """ id=""beiz_"
						Response.write zid
						Response.write """ dataType=""Limit"" "
						If MustFillin=1 Then
							Response.write "min=""1"""
						end if
						Response.write "" & vbcrlf & "                            max=""4000""  msg=""备注长度不能超过4000个字"" style=""display:none;"" cols=""1"" rows=""1"">"
						if c_Value<>"" then Response.write c_Value End if
						Response.write "</textarea>" & vbcrlf & "                                  <IFRAME ID=""eWebEditor_"
						Response.write zid
						Response.write """ SRC=""../edit/ewebeditor.asp?id=beiz_"
						Response.write zid
						Response.write "&style=news"" FRAMEBORDER=""0"" SCROLLING=""no"" WIDTH=""100%"" HEIGHT=""300"" marginwidth=""1"" marginheight=""1"" name=""wfasdg""></IFRAME>" & vbcrlf & "                        "
						end select
					end if
				else
					dim tbname : tbname = ""
					select case TName
					case 16001 : tbname = "product"
					end select
					if ord<>0 then
						c_Value = sdk.getSqlValue("select "& dname &" from "& tbname & " where ord="& ord,"")
						if UiType<>0 and len(c_Value)>0 and readonly then
							c_Value = sdk.getSqlValue("select sort1 from sortonehy where ord= "& c_Value,"")
						end if
					end if
					if readonly then
						Response.write "<span class=""gray ewebeditorImg"">&nbsp;"
						Response.write c_Value
						Response.write "</span>"
					else
						if UiType=0 then
							c_Value=replace(replace(c_Value&"","""","&#34;"),"'","&#39;")
							Response.write "" & vbcrlf & "                        <input name="""
							Response.write dname
							Response.write """ type=""text"" size=""20"" id="""
							Response.write dname
							Response.write """ value="""
							Response.write c_Value
							Response.write """ "
							if CheckPurview(tsstr,dname)=True then
								Response.write "onChange=""callServer_ts('"
								Response.write id
								Response.write "','"
								Response.write dname
								Response.write "');"""
							end if
							Response.write " dataType=""Limit"" "
							if  CheckPurview(bzstr,dname)=True or MustFillin=1  then
								Response.write " min=""1"" "
							end if
							Response.write "  max=""200""  msg=""必须在1到200个字符之间"">" & vbcrlf & "                        "
						else
							Response.write "" & vbcrlf & "                        <select name="""
							Response.write dname
							Response.write """ "
							if CheckPurview(tsstr,dname)=True then
								Response.write "onChange=""callServer_ts('"
								Response.write id
								Response.write "','"
								Response.write dname
								Response.write "');"""
							end if
							Response.write " id="""
							Response.write dname
							Response.write """   dataType=""Limit"" "
							if  CheckPurview(btstr,dname)=True  then
								Response.write " min=""1"" "
							end if
							Response.write "  max=""50""  msg=""长度不能超过50个字"">" & vbcrlf & "                        "
							dim gl : gl = sdk.getSqlValue("select gl from zdy where sort1= "& oldZdySort & " and name='"& dname &"' ",0)
							set rs7=server.CreateObject("adodb.recordset")
							sql7="select ord,sort1 from sortonehy where gate2="& gl &" order by gate1 desc "
							rs7.open sql7,conn,1,1
							do until rs7.eof
								Response.write "" & vbcrlf & "                            <option value="""
								Response.write rs7("ord")
								Response.write """ "
								if rs7("ord").value &""=c_Value&"" then
									Response.write "selected"
								end if
								Response.write " >"
								Response.write rs7("sort1")
								Response.write "</option>" & vbcrlf & "                            "
								rs7.movenext
							loop
							rs7.close
							set rs7=nothing
							Response.write "" & vbcrlf & "                        </select>" & vbcrlf & "                        "
						end if
					end if
				end if
				Response.write " <span id=""test"
				Response.write id
				Response.write """ class=""red"">"
				if  (MustFillin=1 or CheckPurview(bzstr,dname)=true) and readonly=false Then
					Response.write "*"
				end if
				Response.write "</span>" & vbcrlf & "                      </td>" & vbcrlf & "                   "
				i_jm=i_jm+1
				Response.write "</span>" & vbcrlf & "                      </td>" & vbcrlf & "                   "
				rs_kz_zdy.movenext
			loop
			Response.write("</tr>")
		end if
		rs_kz_zdy.close
		set rs_kz_zdy=nothing
	end function
	Function showExtended(TName,ord,columns,col1,col2)
		dim rs_kz_zdy, rs_kz_zdy_88, sql, rs7, sql7
		dim  num1, i_jm, j_jm, c_Value,colstr1,colstr2
		If col1>1 Then colstr1= " colspan='"&col1&"'"
		If col2>1 Then colstr2= " colspan='"&col2&"'"
		if TName=1001 or ord=-1 Then columns=2
'If col2>1 Then colstr2= " colspan='"&col2&"'"
		If ord = "" Then ord=0
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		sql="select * from ERP_CustomFields where TName="&TName&" "& KZ_LIMITID &" and IsUsing=1 and del=1 and FType<>'5' order by FOrder asc "
		rs_kz_zdy.open sql,conn,1,1
		num1=rs_kz_zdy.RecordCount
		i_jm=0
		j_jm=1
		if rs_kz_zdy.eof = False then
			Response.write("<tr>")
			do until rs_kz_zdy.eof
				if clng(i_jm/columns)=i_jm/columns and i_jm<>0 then
					Response.write("</tr><tr>")
					j_jm=j_jm+1
					Response.write("</tr><tr>")
				end if
				c_Value=""
				Set rs_kz_zdy_88=conn.execute("select FValue from ERP_CustomValues where FieldsID="&rs_kz_zdy("id")&" and OrderID="&ord&" and OrderID>0 ")
				If rs_kz_zdy_88.eof = False  Then c_Value=rs_kz_zdy_88("FValue")
				rs_kz_zdy_88.close
				Response.write "" & vbcrlf & "                      <td width=""11%"" align=""right"" "
				Response.write colstr1
				Response.write ">"
				Response.write rs_kz_zdy("FName")
				Response.write "：</td>" & vbcrlf & "                       <td width=""22%"" "
				if i_jm=num1-1  then
					Response.write "：</td>" & vbcrlf & "                       <td width=""22%"" "
					Response.write "colspan="""
					Response.write col2+(col1+col2)*(j_jm*columns-num1)
					Response.write "colspan="""
					Response.write """ "
				else
					Response.write colstr2
				end if
				Response.write ">" & vbcrlf & "                     "
				if rs_kz_zdy("FType")="1" Then
					Response.write "" & vbcrlf & "                              <input name=""danh_"
					Response.write rs_kz_zdy("id")
					Response.write """ type=""text"" size=""15"" id=""danh_"
					Response.write rs_kz_zdy("id")
					Response.write """ value="""
					Response.write c_Value
					Response.write """ dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1""  msg=""必须在1到200个字符之间""  "
					else
						Response.write " msg=""长度不能超过200个字"" "
					end if
					Response.write "  max=""200"" maxlength=""4000"">" & vbcrlf & "                             "
				Elseif rs_kz_zdy("FType")="2" then
					Response.write "" & vbcrlf & "                              <textarea name=""duoh_"
					Response.write rs_kz_zdy("id")
					Response.write """ id=""duoh_"
					Response.write rs_kz_zdy("id")
					Response.write """ style=""overflow-y:hidden;word-break:break-all;width:160px;height:22px;padding-left:4px;"" onfocus=""this.style.height=this.scrollHeight"" onpropertychange=""this.style.height=this.scrollHeight"" dataType=""Limit"" "
					Response.write rs_kz_zdy("id")
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1""   msg=""必须在1到500个字符之间"" "
					else
						Response.write " msg=""长度不能超过500个字"" "
					end if
					Response.write " max=""500"">"
					Response.write c_Value
					Response.write "</textarea>" & vbcrlf & "                           "
				elseif rs_kz_zdy("FType")="3" Then
					Response.write "" & vbcrlf & "                              <input class=""resetDataPickerBg"" readonly name=""date_"
					Response.write rs_kz_zdy("id")
					Response.write """ value="""
					Response.write c_Value
					Response.write """ size=""15"" id=""daysOfMonthPos"" onmouseup=""toggleDatePicker('daysOfMonth_"
					Response.write rs_kz_zdy("id")
					Response.write "','date_"
					Response.write rs_kz_zdy("id")
					Response.write "')"" dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write " max=""500"" msg=""请选择日期"" style=""background-image:url(../images/datePicker.gif);background-position:93px;width:111px;;background-repeat:no-repeat;""> <div id=""daysOfMonth_"
					Response.write " min=""1"" "
					Response.write rs_kz_zdy("id")
					Response.write """ style=""POSITION:absolute""></div>" & vbcrlf & "                           "
				ElseIf rs_kz_zdy("FType")="4" then
					Response.write "" & vbcrlf & "                              <input name=""Numr_"
					Response.write rs_kz_zdy("id")
					Response.write """ type=""text"" value="""
					Response.write c_Value
					Response.write """ size=""15"" id=""Numr_"
					Response.write rs_kz_zdy("id")
					Response.write """ onkeyup=value=value.replace(/[^\d\.]/g,'') dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write "  max=""500""  msg=""必须在1到500个字符"" >" & vbcrlf & "                           "
				ElseIf rs_kz_zdy("FType")="6" then
					Response.write "" & vbcrlf & "                              <select name=""IsNot_"
					Response.write rs_kz_zdy("id")
					Response.write """ id=""IsNot_"
					Response.write rs_kz_zdy("id")
					Response.write """  dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write "  max=""500""  msg=""必须在1到500个字符"">" & vbcrlf & "                            <option value=""是"" "
					If c_Value="是" then
						Response.write "selected"
					end if
					Response.write ">是</option>" & vbcrlf & "                          <option value=""否"" "
					If c_Value="否" then
						Response.write "selected"
					end if
					Response.write ">否</option>" & vbcrlf & "                          </select>" & vbcrlf & "                               "
				else
					Response.write "" & vbcrlf & "                              <select name=""meju_"
					Response.write rs_kz_zdy("id")
					Response.write """ id=""meju_"
					Response.write rs_kz_zdy("id")
					Response.write """  dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write "  max=""500""  msg=""必须在1到500个字符"">" & vbcrlf & "                           "
					set rs7=conn.execute("select id,CValue from ERP_CustomOptions where CFID="&rs_kz_zdy("id")&" order by id asc ")
					do until rs7.eof
						Response.write "" & vbcrlf & "                                     <option value="""
						Response.write rs7("id")
						Response.write """ "
						If rs7("CValue")&""=c_Value&"" then
							Response.write "selected"
						end if
						Response.write ">"
						Response.write rs7("CValue")
						Response.write "</option>" & vbcrlf & "                                    "
						rs7.movenext
					loop
					rs7.close
					Response.write "" & vbcrlf & "                        </select>" & vbcrlf & "                            "
				end if
				if  rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then
					Response.write " <span class=""red"">*</span>"
				end if
				Response.write "" & vbcrlf & "                     </td>" & vbcrlf & "                   "
				i_jm=i_jm+1
				Response.write "" & vbcrlf & "                     </td>" & vbcrlf & "                   "
				rs_kz_zdy.movenext
			loop
			Response.write("</tr>")
		end if
		rs_kz_zdy.close
		set rs_kz_zdy=nothing
	end function
	Function showExtended2(TName,ord,columns,col1,col2)
		dim rs_kz_zdy, rs_kz_zdy_88, sql, rs7, sql7
		dim  num1, i_jm, j_jm, c_Value,colstr1,colstr2
		If col1>1 Then colstr1= " colspan='"&col1&"'"
		If col2>1 Then colstr2= " colspan='"&col2&"'"
		if TName=1001 or ord=-1 Then columns=2
'If col2>1 Then colstr2= " colspan='"&col2&"'"
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		sql="select * from ERP_CustomFields where TName="&TName&" "& KZ_LIMITID &" and IsUsing=1 and del=1 and FType<>'5' order by FOrder asc "
		rs_kz_zdy.open sql,conn,1,1
		num1=rs_kz_zdy.RecordCount
		i_jm=0
		j_jm=1
		if rs_kz_zdy.eof = False then
			Response.write("<tr>")
			do until rs_kz_zdy.eof
				if clng(i_jm/columns)=i_jm/columns and i_jm<>0 then
					Response.write("</tr><tr>")
					j_jm=j_jm+1
					Response.write("</tr><tr>")
				end if
				c_Value=""
				Set rs_kz_zdy_88=conn.execute("select FValue from ERP_CustomValues where FieldsID="&rs_kz_zdy("id")&" and OrderID="&ord&" and OrderID>0 ")
				If rs_kz_zdy_88.eof = False  Then c_Value=rs_kz_zdy_88("FValue")
				rs_kz_zdy_88.close
				Response.write "" & vbcrlf & "                     <td align=""right"" "
				Response.write colstr1
				Response.write ">"
				Response.write rs_kz_zdy("FName")
				Response.write "：</td>" & vbcrlf & "                      <td "
				if i_jm=num1-1  then
					Response.write "：</td>" & vbcrlf & "                      <td "
					Response.write "colspan="""
					Response.write col2+(col1+col2)*(j_jm*columns-num1)
					Response.write "colspan="""
					Response.write """ "
				else
					Response.write colstr2
				end if
				Response.write ">" & vbcrlf & "                    "
				if rs_kz_zdy("FType")="1" Then
					Response.write "" & vbcrlf & "                             <input name=""danh_"
					Response.write rs_kz_zdy("id")
					Response.write """ type=""text"" size=""15"" id=""danh_"
					Response.write rs_kz_zdy("id")
					Response.write """ value="""
					Response.write c_Value
					Response.write """ dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write "  max=""500""  msg=""必须在1到500个字符"" maxlength=""4000"">" & vbcrlf & "                            "
				Elseif rs_kz_zdy("FType")="2" then
					Response.write "" & vbcrlf & "                             <textarea name=""duoh_"
					Response.write rs_kz_zdy("id")
					Response.write """ id=""duoh_"
					Response.write rs_kz_zdy("id")
					Response.write """ style=""overflow-y:hidden;word-break:break-all;width:160px;height:22px"" onfocus=""this.style.posHeight=this.scrollHeight"" onpropertychange=""this.style.posHeight=this.scrollHeight"" dataType=""Limit"" "
					Response.write rs_kz_zdy("id")
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write " max=""500""  msg=""必须在1到500个字符"">"
					Response.write c_Value
					Response.write "</textarea>" & vbcrlf & "                          "
				elseif rs_kz_zdy("FType")="3" Then
					Response.write "" & vbcrlf & "                             <input readonly name=""date_"
					Response.write rs_kz_zdy("id")
					Response.write """ value="""
					Response.write c_Value
					Response.write """ size=""15"" id=""daysOfMonthPos"" onmouseup=""toggleDatePicker('daysOfMonth_"
					Response.write rs_kz_zdy("id")
					Response.write "','date_"
					Response.write rs_kz_zdy("id")
					Response.write "')"" dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write " max=""500"" msg=""请选择日期"" style=""background-image:url(../images/datePicker.gif);background-position:right;background-repeat:no-repeat;""> <div id=""daysOfMonth_"
					Response.write " min=""1"" "
					Response.write rs_kz_zdy("id")
					Response.write """ style=""POSITION:absolute""></div>" & vbcrlf & "                          "
				ElseIf rs_kz_zdy("FType")="4" then
					Response.write "" & vbcrlf & "                             <input name=""Numr_"
					Response.write rs_kz_zdy("id")
					Response.write """ type=""text"" value="""
					Response.write c_Value
					Response.write """ size=""15"" id=""Numr_"
					Response.write rs_kz_zdy("id")
					Response.write """ onkeyup=value=value.replace(/[^\d\.]/g,'') dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write "  max=""500""  msg=""必须在1到500个字符"" >" & vbcrlf & "                          "
				ElseIf rs_kz_zdy("FType")="6" then
					Response.write "" & vbcrlf & "                             <select name=""IsNot_"
					Response.write rs_kz_zdy("id")
					Response.write """ id=""IsNot_"
					Response.write rs_kz_zdy("id")
					Response.write """  dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write "  max=""500""  msg=""必须在1到500个字符"">" & vbcrlf & "                           <option value=""是"" "
					If c_Value="是" then
						Response.write "selected"
					end if
					Response.write ">是</option>" & vbcrlf & "                         <option value=""否"" "
					If c_Value="否" then
						Response.write "selected"
					end if
					Response.write ">否</option>" & vbcrlf & "                         </select>" & vbcrlf & "                               "
				else
					Response.write "" & vbcrlf & "                             <select name=""meju_"
					Response.write rs_kz_zdy("id")
					Response.write """ id=""meju_"
					Response.write rs_kz_zdy("id")
					Response.write """  dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write "  max=""500""  msg=""必须在1到500个字符"">" & vbcrlf & "                           "
					set rs7=conn.execute("select id,CValue from ERP_CustomOptions where CFID="&rs_kz_zdy("id")&" order by id asc ")
					do until rs7.eof
						Response.write "" & vbcrlf & "                                     <option value="""
						Response.write rs7("id")
						Response.write """ "
						If rs7("CValue")&""=c_Value&"" then
							Response.write "selected"
						end if
						Response.write ">"
						Response.write rs7("CValue")
						Response.write "</option>" & vbcrlf & "                                    "
						rs7.movenext
					loop
					rs7.close
					Response.write "" & vbcrlf & "                        </select>" & vbcrlf & "                            "
				end if
				if  rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then
					Response.write " <span class=""red"">*</span>"
				end if
				Response.write "" & vbcrlf & "                     </td>" & vbcrlf & "                   "
				i_jm=i_jm+1
				Response.write "" & vbcrlf & "                     </td>" & vbcrlf & "                   "
				rs_kz_zdy.movenext
			loop
			Response.write("</tr>")
		end if
		rs_kz_zdy.close
		set rs_kz_zdy=nothing
	end function
	Function getExtendedDeal(TName,ord,repID)
		Call showExtendedDeal(TName,ord,3,1,1,repID)
	end function
	Function showExtendedDeal(TName,ord,columns,col1,col2,repID)
		dim rs_kz_zdy, rs_kz_zdy_88, sql, rs7, sql7
		dim  num1, i_jm, j_jm, c_Value,colstr1,colstr2
		If col1>1 Then colstr1= " colspan='"&col1&"'"
		If col2>1 Then colstr2= " colspan='"&col2&"'"
		columns = 2
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		sql="select * from Copy_CustomFields where TName="&TName&" AND RepairOrder = "&repID&" "& KZ_LIMITID &" and FType<>5 and IsUsing=1 and del=1 order by FOrder asc "
		rs_kz_zdy.open sql,conn,1,1
		num1=rs_kz_zdy.RecordCount
		i_jm=0
		j_jm=1
		if rs_kz_zdy.eof = False then
			Response.write("<tr>")
			do until rs_kz_zdy.eof
				if clng(i_jm/columns)=i_jm/columns and i_jm<>0 then
					Response.write("</tr><tr>")
					j_jm=j_jm+1
					Response.write("</tr><tr>")
				end if
				c_Value=""
				Set rs_kz_zdy_88=conn.execute("select FValue from ERP_CustomValues where FieldsID="&rs_kz_zdy("id")&" and OrderID="&ord&" ")
				If rs_kz_zdy_88.eof = False  Then c_Value=rs_kz_zdy_88("FValue")
				rs_kz_zdy_88.close
				Response.write "" & vbcrlf & "                     <td width=""11%"" align=""right"" "
				Response.write colstr1
				Response.write ">"
				Response.write rs_kz_zdy("FName")
				Response.write "：</td>" & vbcrlf & "                      <td width=""22%"" "
				if i_jm=num1-1  then
					Response.write "：</td>" & vbcrlf & "                      <td width=""22%"" "
					Response.write "colspan="""
					Response.write col2+(col1+col2)*(j_jm*columns-num1)
					Response.write "colspan="""
					Response.write """ "
				else
					Response.write colstr2
				end if
				Response.write ">" & vbcrlf & "                    "
				if rs_kz_zdy("FType")="1" Then
					Response.write "" & vbcrlf & "                             <input name=""danh_"
					Response.write rs_kz_zdy("id")
					Response.write """ type=""text"" size=""15"" id=""danh_"
					Response.write rs_kz_zdy("id")
					Response.write """ value="""
					Response.write c_Value
					Response.write """ dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write "  max=""500""  msg=""必须在1到500个字符"" maxlength=""4000"">" & vbcrlf & "                            "
				Elseif rs_kz_zdy("FType")="2" then
					Response.write "" & vbcrlf & "                             <textarea name=""duoh_"
					Response.write rs_kz_zdy("id")
					Response.write """ id=""duoh_"
					Response.write rs_kz_zdy("id")
					Response.write """ style=""overflow-y:hidden;word-break:break-all;width:160px;height:22px;padding-left:4px;"" onfocus=""this.style.posHeight=this.scrollHeight"" onpropertychange=""this.style.posHeight=this.scrollHeight"" dataType=""Limit"" "
					Response.write rs_kz_zdy("id")
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write " max=""500""  msg=""必须在1到500个字符"">"
					Response.write c_Value
					Response.write "</textarea>" & vbcrlf & "                          "
				Elseif rs_kz_zdy("FType")="5" then
					Response.write "" & vbcrlf & "                             <textarea name=""beiz_"
					Response.write rs_kz_zdy("id")
					Response.write """ id=""beiz_"
					Response.write rs_kz_zdy("id")
					Response.write """ style=""overflow-y:hidden;word-break:break-all;width:160px;height:22px;padding-left:4px;"" onfocus=""this.style.posHeight=this.scrollHeight"" onpropertychange=""this.style.posHeight=this.scrollHeight"" dataType=""Limit"" "
					Response.write rs_kz_zdy("id")
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write " max=""4000""  msg=""必须在1到4000个字符"">"
					Response.write c_Value
					Response.write "</textarea>" & vbcrlf & "                          "
				elseif rs_kz_zdy("FType")="3" Then
					Response.write "" & vbcrlf & "                             <input readonly name=""date_"
					Response.write rs_kz_zdy("id")
					Response.write """ value="""
					Response.write c_Value
					Response.write """ size=""15"" id=""daysOfMonthPos"" onmouseup=""toggleDatePicker('daysOfMonth_"
					Response.write rs_kz_zdy("id")
					Response.write "','date_"
					Response.write rs_kz_zdy("id")
					Response.write "')"" dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write " max=""500"" msg=""请选择日期"" style=""background-image:url(../images/datePicker.gif);background-position:right;background-repeat:no-repeat;""> <div id=""daysOfMonth_"
					Response.write " min=""1"" "
					Response.write rs_kz_zdy("id")
					Response.write """ style=""POSITION:absolute""></div>" & vbcrlf & "                          "
				ElseIf rs_kz_zdy("FType")="4" then
					Response.write "" & vbcrlf & "                             <input name=""Numr_"
					Response.write rs_kz_zdy("id")
					Response.write """ type=""text"" value="""
					Response.write c_Value
					Response.write """ size=""15"" id=""Numr_"
					Response.write rs_kz_zdy("id")
					Response.write """ onkeyup=value=value.replace(/[^\d\.]/g,'') dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write "  max=""500""  msg=""必须在1到500个字符"" >" & vbcrlf & "                  "
				ElseIf rs_kz_zdy("FType")="6" then
					Response.write "" & vbcrlf & "                             <select name=""IsNot_"
					Response.write rs_kz_zdy("id")
					Response.write """ id=""IsNot_"
					Response.write rs_kz_zdy("id")
					Response.write """  dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write "  max=""500""  msg=""必须在1到500个字符"">" & vbcrlf & "                           <option value=""是"" "
					If c_Value="是" then
						Response.write "selected"
					end if
					Response.write ">是</option>" & vbcrlf & "                         <option value=""否"" "
					If c_Value="否" then
						Response.write "selected"
					end if
					Response.write ">否</option>" & vbcrlf & "                         </select>" & vbcrlf & "                               "
				else
					Response.write "" & vbcrlf & "                             <select name=""meju_"
					Response.write rs_kz_zdy("id")
					Response.write """ id=""meju_"
					Response.write rs_kz_zdy("id")
					Response.write """  dataType=""Limit"" "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then
						Response.write " min=""1"" "
					end if
					Response.write "  max=""500""  msg=""必须在1到500个字符"">" & vbcrlf & "                           "
					set rs7=conn.execute("select id,CValue from ERP_CustomOptions where CFID="&rs_kz_zdy("id")&" order by id asc ")
					do until rs7.eof
						Response.write "" & vbcrlf & "                                     <option value="""
						Response.write rs7("id")
						Response.write """ "
						If rs7("CValue")&""=c_Value&"" then
							Response.write "selected"
						end if
						Response.write ">"
						Response.write rs7("CValue")
						Response.write "</option>" & vbcrlf & "                                    "
						rs7.movenext
					loop
					rs7.close
					Response.write "" & vbcrlf & "                        </select>" & vbcrlf & "                            "
				end if
				if  rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then
					Response.write " <span class=""red"">*</span>"
				end if
				Response.write "" & vbcrlf & "                     </td>" & vbcrlf & "                   "
				i_jm=i_jm+1
				Response.write "" & vbcrlf & "                     </td>" & vbcrlf & "                   "
				rs_kz_zdy.movenext
			loop
			Response.write("</tr>")
		end if
		rs_kz_zdy.close
		set rs_kz_zdy=nothing
	end function
	Function showExtendedBzDeal(TName,ord, repID,col1,col2)
		Dim  rs_kz_zdy_8, rs_kz_zdy_88, c_Value,colstr1,colstr2
		if TName=1001 or ord=-1 Then col2=3
'Dim  rs_kz_zdy_8, rs_kz_zdy_88, c_Value,colstr1,colstr2
		If col1>1 Then colstr1= " colspan='"&col1&"'"
		If col2>1 Then colstr2= " colspan='"&col2&"'"
		Set rs_kz_zdy_8=server.CreateObject("adodb.recordset")
		rs_kz_zdy_8.open "select * from Copy_CustomFields where IsUsing=1 and TName="&TName&" AND RepairOrder = "&repID&" "& KZ_LIMITID &" and FType='5' order by FOrder asc",conn,1,1
		If Not rs_kz_zdy_8.eof Then
			Do While Not rs_kz_zdy_8.eof
				If Len(rs_kz_zdy_8("FName")&"") > 0 then
					c_Value=""
					Set rs_kz_zdy_88=conn.execute("select FValue from ERP_CustomValues where FieldsID="&rs_kz_zdy_8("id")&" and OrderID="&ord&" ")
					If Not rs_kz_zdy_88.eof Then c_Value=rs_kz_zdy_88("FValue")
					rs_kz_zdy_88.close
					Response.write "" & vbcrlf & "                         <tr>" & vbcrlf & "                                    <td "
					Response.write colstr1
					Response.write "><div align=""right"">"
					If (rs_kz_zdy_8("MustFillin") Or Len(KZ_LIMITID&"")>0 ) And (rs_kz_zdy_8("FType")=1 Or rs_kz_zdy_8("FType")=2 Or rs_kz_zdy_8("FType")=4) then
						Response.write " &nbsp;<span class=""red"">*&nbsp;</span>"
					end if
					Response.write rs_kz_zdy_8("FName")
					Response.write "：</div></td>" & vbcrlf & "                                    <td "
					Response.write colstr2
					Response.write "><textarea name=""beiz_"
					Response.write rs_kz_zdy_8("id")
					Response.write """ id=""beiz_"
					Response.write rs_kz_zdy_8("id")
					Response.write """ dataType=""Limit""  " & vbcrlf & "                    "
					If Len(KZ_LIMITID&"")>0 Then
						Response.write "min=""1"""
					end if
					Response.write "" & vbcrlf & "                    max=""4000""  msg=""备注长度不能超过4000个字"" style=""display:none;"" cols=""1"" rows=""1"">"
					if c_Value<>"" then Response.write c_Value End if
					Response.write "</textarea>" & vbcrlf & "                              <IFRAME ID=""eWebEditor_"
					Response.write rs_kz_zdy_8("id")
					Response.write """ SRC=""../edit/ewebeditor.asp?id=beiz_"
					Response.write rs_kz_zdy_8("id")
					Response.write "&style=news"" FRAMEBORDER=""0"" SCROLLING=""no"" WIDTH=""100%"" HEIGHT=""300"" marginwidth=""1"" marginheight=""1"" name=""wfasdg""></IFRAME></td>" & vbcrlf & "                         </tr>" & vbcrlf & "                       "
				end if
				rs_kz_zdy_8.movenext
			loop
		end if
		rs_kz_zdy_8.close
		Set rs_kz_zdy_8=Nothing
	end function
	Function getExtended2(TName,ord,ly_str)
		columns=3
		if TName=1001 or ord=-1 Then columns=2
'columns=3
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		sql="select * from ERP_CustomFields where TName="&TName&" "& KZ_LIMITID &" and IsUsing=1 and del=1 and FType<>'5' order by FOrder asc "
		rs_kz_zdy.open sql,conn,1,1
		num1=rs_kz_zdy.RecordCount
		i_jm=0
		j_jm=1
		if Not rs_kz_zdy.eof then
			Response.write("<tr>")
			do until rs_kz_zdy.eof
				if clng(i_jm/columns)=i_jm/columns and i_jm<>0 then
					Response.write("</tr><tr>")
					j_jm=j_jm+1
				end if
				c_Value=""
				Set rs_kz_zdy_88=conn.execute("select FValue from ERP_CustomValues where FieldsID="&rs_kz_zdy("id")&" and OrderID="&ord&" ")
				If Not rs_kz_zdy_88.eof Then c_Value=rs_kz_zdy_88("FValue")
				rs_kz_zdy_88.close
				Response.write "<td width='11%' align='right'>"&rs_kz_zdy("FName")&"：</td><td width='22%' "
				if i_jm=num1-1  Then Response.write "colspan="&(1+2*(j_jm*columns-num1))&" "
				Response.write "<td width='11%' align='right'>"&rs_kz_zdy("FName")&"：</td><td width='22%' "
				Response.write ">"
				if rs_kz_zdy("FType")="1" Then
					Response.write "<input name='danh_"&rs_kz_zdy("id")&"' type='text' size='15' id='danh_"&rs_kz_zdy("id")&"' value='"&c_Value&"' dataType='Limit' "
					if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then Response.write " min='1' "
					Response.write " max='500'  msg='必须在1到500个字符' maxlength='4000'>"
				Elseif rs_kz_zdy("FType")="2" Then
					Response.write "<textarea name='duoh_"&rs_kz_zdy("id")&"' id='duoh_"&rs_kz_zdy("id")&"' style='overflow-y:hidden;word-break:break-all;width:160px;height:22px;padding-left:4px;' onfocus='this.style.posHeight=this.scrollHeight' onpropertychange='this.style.posHeight=this.scrollHeight' dataType='Limit' "
'Elseif rs_kz_zdy("FType")="2" Then
'if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then Response.write " min='1' "
					Response.write " max='500'  msg='必须在1到500个字符'>"&c_Value&"</textarea>"
				elseif rs_kz_zdy("FType")="3" Then
					Response.write "<input readonly name='date_"&rs_kz_zdy("id")&"' value='"&c_Value&"' size='15' id='daysOfMonthPos' onmouseup=""toggleDatePicker('daysOfMonth_"&rs_kz_zdy("id")&"','date_"&rs_kz_zdy("id")&"')"" dataType='Limit' "
'if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then Response.write " min='1' "
					Response.write " max='500' msg='请选择日期' style='background-image:url(../images/datePicker.gif);background-position:right;background-repeat:no-repeat;'> <div id='daysOfMonth_"&rs_kz_zdy("id")&"' style='POSITION:absolute'></div>"
'if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then Response.write " min='1' "
				ElseIf rs_kz_zdy("FType")="4" then
					Response.write "<input name='Numr_"&rs_kz_zdy("id")&"' type='text' value='"&c_Value&"' size='15' id='Numr_"&rs_kz_zdy("id")&"' onkeyup=value=value.replace(/[^\d\.]/g,'') dataType='Limit' "
'if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then Response.write " min='1'  "
					Response.write " max='500'  msg='必须在1到500个字符' >"
				ElseIf rs_kz_zdy("FType")="6" then
					Response.write "<select name='IsNot_"&rs_kz_zdy("id")&"' id='IsNot_"&rs_kz_zdy("id")&"'  dataType='Limit' "
'if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then Response.write " min='1' "
					Response.write " max='500'  msg='必须在1到500个字符'>"
					Response.write "<option value='是' "
					If c_Value="是" Then Response.write " selected "
					Response.write ">是</option>"
					Response.write "<option value='否' "
					If c_Value="否" Then Response.write " selected "
					Response.write ">否</option>"
					Response.write "</select>"
				else
					Response.write "<select name='meju_"&rs_kz_zdy("id")&"' id='meju_"&rs_kz_zdy("id")&"'  dataType='Limit' "
'if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then Response.write " min='1' "
					Response.write " max='500'  msg='必须在1到500个字符'>"
					Response.write "<option value=''></option>"
					ly_sql=""
					If c_Value<>"" And ly_str&""<>"" Then ly_str=ly_str&","&c_Value
					If ly_str&""<>"" Then ly_sql=" and id in ("&ly_str&")"
					set rs7=conn.execute("select id,CValue from ERP_CustomOptions where CFID="&rs_kz_zdy("id")&" "&ly_sql&" order by id asc ")
					do until rs7.eof
						Response.write "<option value='"&rs7("id")&"' "
						If rs7("CValue")&""=c_Value&"" Then Response.write " selected "
						Response.write ">"&rs7("CValue")&"</option>"
						rs7.movenext
					loop
					rs7.close
					Response.write "</select>"
				end if
				if  (rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0) And (rs_kz_zdy("FType")=1 Or rs_kz_zdy("FType")=2 Or rs_kz_zdy("FType")=4)  Then Response.write " &nbsp;<span class='red'>*</span>"
				Response.write "</td>"
				i_jm=i_jm+1
				Response.write "</td>"
				rs_kz_zdy.movenext
			loop
			Response.write("</tr>")
		end if
		rs_kz_zdy.close
		set rs_kz_zdy=nothing
	end function
	Function getExtended1(TName,ord)
		Call showExtended1(TName,ord,1,1,5)
	end function
	Function showExtended1(TName,ord,columns ,col1,col2)
		Dim  rs_kz_zdy_8, rs_kz_zdy_88, c_Value,colstr1,colstr2
		if TName=1001 or ord=-1 Then col2=3
'Dim  rs_kz_zdy_8, rs_kz_zdy_88, c_Value,colstr1,colstr2
		If col1>1 Then colstr1= " colspan='"&col1&"'"
		If col2>1 Then colstr2= " colspan='"&col2&"'"
		Set rs_kz_zdy_8=server.CreateObject("adodb.recordset")
		rs_kz_zdy_8.open "select * from ERP_CustomFields where IsUsing=1 and TName="&TName&" "& KZ_LIMITID &" and FType='5' order by FOrder asc",conn,1,1
		If Not rs_kz_zdy_8.eof Then
			Do While Not rs_kz_zdy_8.eof
				c_Value=""
				Set rs_kz_zdy_88=conn.execute("select FValue from ERP_CustomValues where FieldsID="&rs_kz_zdy_8("id")&" and OrderID="&ord&" ")
				If Not rs_kz_zdy_88.eof Then c_Value=rs_kz_zdy_88("FValue")
				rs_kz_zdy_88.close
				Response.write "" & vbcrlf & "                      <tr>" & vbcrlf & "                            <td width=""11%"" "
				Response.write colstr1
				Response.write "><div align=""right"">"
				If (rs_kz_zdy_8("MustFillin") Or Len(KZ_LIMITID&"")>0 ) And (rs_kz_zdy_8("FType")=1 Or rs_kz_zdy_8("FType")=2 Or rs_kz_zdy_8("FType")=4) then
					Response.write " &nbsp;<span class=""red"">*&nbsp;</span>"
				end if
				Response.write rs_kz_zdy_8("FName")
				Response.write "：</div></td>" & vbcrlf & "                         <td "
				Response.write colstr2
				Response.write "><textarea name=""beiz_"
				Response.write rs_kz_zdy_8("id")
				Response.write """ id=""beiz_"
				Response.write rs_kz_zdy_8("id")
				Response.write """ dataType=""Limit""  " & vbcrlf & "                "
				If Len(KZ_LIMITID&"")>0 Then
					Response.write "min=""1"""
				end if
				Response.write "" & vbcrlf & "                max=""4000""  msg=""备注长度不能超过4000个字"" style=""display:none;"" cols=""1"" rows=""1"">"
				if c_Value<>"" then Response.write c_Value End if
				Response.write "</textarea>" & vbcrlf & "                           <IFRAME ID=""eWebEditor_"
				Response.write rs_kz_zdy_8("id")
				Response.write """ SRC=""../edit/ewebeditor.asp?id=beiz_"
				Response.write rs_kz_zdy_8("id")
				Response.write "&style=news"" FRAMEBORDER=""0"" SCROLLING=""no"" WIDTH=""100%"" HEIGHT=""300"" marginwidth=""1"" marginheight=""1"" name=""wfasdg""></IFRAME></td>" & vbcrlf & "                     </tr>" & vbcrlf & "                   "
				rs_kz_zdy_8.movenext
			loop
		end if
		rs_kz_zdy_8.close
		Set rs_kz_zdy_8=Nothing
	end function
	Function showExtended3(TName,ord,columns ,col1,col2)
		Dim  rs_kz_zdy_8, rs_kz_zdy_88, c_Value,colstr1,colstr2
		if TName=1001 or ord=-1 Then col2=3
'Dim  rs_kz_zdy_8, rs_kz_zdy_88, c_Value,colstr1,colstr2
		If col1>1 Then colstr1= " colspan='"&col1&"'"
		If col2>1 Then colstr2= " colspan='"&col2&"'"
		Set rs_kz_zdy_8=server.CreateObject("adodb.recordset")
		rs_kz_zdy_8.open "select * from ERP_CustomFields where IsUsing=1 and TName="&TName&" "& KZ_LIMITID &" and FType='5' order by FOrder asc",conn,1,1
		If Not rs_kz_zdy_8.eof Then
			Do While Not rs_kz_zdy_8.eof
				c_Value=""
				Set rs_kz_zdy_88=conn.execute("select FValue from ERP_CustomValues where FieldsID="&rs_kz_zdy_8("id")&" and OrderID="&ord&" ")
				If Not rs_kz_zdy_88.eof Then c_Value=rs_kz_zdy_88("FValue")
				rs_kz_zdy_88.close
				Response.write "" & vbcrlf & "                     <tr>" & vbcrlf & "                            <td "
				Response.write colstr1
				Response.write "><div align=""right"">"
				If (rs_kz_zdy_8("MustFillin") Or Len(KZ_LIMITID&"")>0 ) And (rs_kz_zdy_8("FType")=1 Or rs_kz_zdy_8("FType")=2 Or rs_kz_zdy_8("FType")=4) then
					Response.write " &nbsp;<span class=""red"">*&nbsp;</span>"
				end if
				Response.write rs_kz_zdy_8("FName")
				Response.write "：</div></td>" & vbcrlf & "                                <td "
				Response.write colstr2
				Response.write "><textarea name=""beiz_"
				Response.write rs_kz_zdy_8("id")
				Response.write """ id=""beiz_"
				Response.write rs_kz_zdy_8("id")
				Response.write """ dataType=""Limit""  " & vbcrlf & "                "
				If Len(KZ_LIMITID&"")>0 Then
					Response.write "min=""1"""
				end if
				Response.write "" & vbcrlf & "                max=""4000""  msg=""备注长度不能超过4000个字"" style=""display:none;"" cols=""1"" rows=""1"">"
				if c_Value<>"" then Response.write c_Value End if
				Response.write "</textarea>" & vbcrlf & "                          <IFRAME ID=""eWebEditor_"
				Response.write rs_kz_zdy_8("id")
				Response.write """ SRC=""../edit/ewebeditor.asp?id=beiz_"
				Response.write rs_kz_zdy_8("id")
				Response.write "&style=news"" FRAMEBORDER=""0"" SCROLLING=""no"" WIDTH=""100%"" HEIGHT=""300"" marginwidth=""1"" marginheight=""1"" name=""wfasdg""></IFRAME></td>" & vbcrlf & "                     </tr>" & vbcrlf & "                   "
				rs_kz_zdy_8.movenext
			loop
		end if
		rs_kz_zdy_8.close
		Set rs_kz_zdy_8=Nothing
	end function
	Function saveExtended(TName,ord)
		Dim rs_kz_zdy, FValue, OID, sql, id, rs0, rs1
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		sql="select *,(select uitype from sys_sdk_BillFieldInfo m where m.billtype=16001 and m.dbname='ext' +cast(t.id as varchar(12)) ) as utype from ERP_CustomFields t where TName="&TName&" "& KZ_LIMITID &" and IsUsing=1 and del=1 order by FOrder asc "
'set rs_kz_zdy=server.CreateObject("adodb.recordset")
		rs_kz_zdy.open sql,conn,1,1
		If not rs_kz_zdy.eof Then
			Do While Not rs_kz_zdy.eof
				id=rs_kz_zdy("id")
				if rs_kz_zdy("FType")="1" Then
					if rs_kz_zdy("utype")="54" then
						FValue=replace(Trim(request.Form("danh_"&id)),", ",",")
					else
						FValue=Trim(request.Form("danh_"&id))
					end if
				ElseIf rs_kz_zdy("FType")="2" then
					FValue=Trim(request.Form("duoh_"&id))
				ElseIf rs_kz_zdy("FType")="3" then
					FValue=Trim(request.Form("date_"&id))
				ElseIf rs_kz_zdy("FType")="4"  then
					FValue=Trim(request.Form("Numr_"&id))
				ElseIf rs_kz_zdy("FType")="5" then
					FValue=Trim(request.Form("beiz_"&id))
				ElseIf rs_kz_zdy("FType")="6" then
					FValue=Trim(request.Form("IsNot_"&id))
				else
					OID=Trim(request.Form("meju_"&id))
					If OID="" Then OID=0
					Set rs1=server.CreateObject("adodb.recordset")
					rs1.open "select CValue from ERP_CustomOptions where id="&OID,conn,1,1
					If rs1.eof Then
						FValue=""
					else
						FValue=rs1("CValue")
					end if
					rs1.close
					Set rs1=nothing
				end if
				Set rs0=server.CreateObject("adodb.recordset")
				rs0.open "select top 1 * from ERP_CustomValues where FieldsID="&id&" and OrderID="&ord&" ",conn,1,1
				If rs0.eof Then
					If FValue<>"" And not IsNull(FValue) Then
						conn.execute "insert into ERP_CustomValues(FieldsID,OrderID,FValue) values("&id&","&ord&",N'"&FValue&"')"
					end if
				else
					conn.execute "update ERP_CustomValues set FValue=N'"&FValue&"' where FieldsID="&id&" and OrderID="&ord&" "
				end if
				rs0.close
				Set rs0=nothing
				rs_kz_zdy.movenext
			loop
		end if
		rs_kz_zdy.close
		Set rs_kz_zdy=Nothing
	end function
	Function searchExtended(TName,col)
		Dim sqldate
		Dim rs_kz_zdy_2 : set rs_kz_zdy_2=server.CreateObject("adodb.recordset")
		Dim sql2 : sql2="select * from ERP_CustomFields where TName="&TName&" "& KZ_LIMITID &" and IsUsing=1 and del=1 and CanSearch=1 order by FOrder asc "
		Dim str33,id,danh_1,danh_2,Numr_1,Numr_2,beiz_1,beiz_2,IsNot_1,meju_1,duoh_1,duoh_2,date_1,date_2
		rs_kz_zdy_2.open sql2,conn,1,1
		if rs_kz_zdy_2.eof then
		else
			str33=""
			do until rs_kz_zdy_2.eof
				id=rs_kz_zdy_2("id")
				If rs_kz_zdy_2("FType")="1" Then
					danh_1=request("danh_"&id&"_1")
					danh_2=request("danh_"&id&"_2")
					str33=str33+"&danh_"&id&"_1="+danh_1
'danh_2=request("danh_"&id&"_2")
					str33=str33+"&danh_"&id&"_2="+danh_2
'danh_2=request("danh_"&id&"_2")
					If danh_2<>"" Then
						If danh_1=1 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '%"& danh_2 &"%')"
'If danh_1=1 Then
						Elseif danh_1=2 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue not like '%"& danh_2 &"%')"
'Elseif danh_1=2 Then
						Elseif danh_1=3 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue='"& danh_2 &"')"
'Elseif danh_1=3 Then
						Elseif danh_1=4 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue<>'"& danh_2 &"')"
'Elseif danh_1=4 Then
						Elseif danh_1=5 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '"& danh_2 &"%')"
'Elseif danh_1=5 Then
						Elseif danh_1=6 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '%"& danh_2 &"')"
'Elseif danh_1=6 Then
						end if
					end if
				ElseIf rs_kz_zdy_2("FType")="2" Then
					duoh_1=request("duoh_"&id&"_1")
					duoh_2=request("duoh_"&id&"_2")
					str33=str33+"&duoh_"&id&"_1="+duoh_1
'duoh_2=request("duoh_"&id&"_2")
					str33=str33+"&duoh_"&id&"_2="+duoh_2
'duoh_2=request("duoh_"&id&"_2")
					If duoh_2<>"" Then
						If duoh_1=1 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '%"& duoh_2 &"%')"
'If duoh_1=1 Then
						Elseif duoh_1=2 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue not like '%"& duoh_2 &"%')"
'Elseif duoh_1=2 Then
						Elseif duoh_1=3 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue='"& duoh_2 &"')"
'Elseif duoh_1=3 Then
						Elseif duoh_1=4 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue<>'"& duoh_2 &"')"
'Elseif duoh_1=4 Then
						Elseif duoh_1=5 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '"& duoh_2 &"%')"
'Elseif duoh_1=5 Then
						Elseif duoh_1=6 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '%"& duoh_2 &"')"
'Elseif duoh_1=6 Then
						end if
					end if
				ElseIf rs_kz_zdy_2("FType")="3" Then
					date_1=request("date_"&id&"_1")
					date_2=request("date_"&id&"_2")
					str33=str33+"&date_"&id&"_1="+date_1
'date_2=request("date_"&id&"_2")
					str33=str33+"&date_"&id&"_2="+date_2
'date_2=request("date_"&id&"_2")
					If date_1<>"" or date_2<>"" Then
						If date_1<>"" Then
							sqldate=" and (case isDate(FValue) when 1 then  cast(FValue as datetime) else cast('1950-1-1' as datetime) end)>=cast('"& date_1 &"'as datetime)"
'If date_1<>"" Then
						end if
						If date_2<>"" Then
							sqldate=sqldate&" and (case isDate(FValue) when 1 then  cast(FValue as datetime) else cast('1950-1-1' as datetime) end)<=cast('"& date_2 &"' as datetime)"
'If date_2<>"" Then
						end if
						str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&""&sqldate&")"
'If date_2<>"" Then
					end if
				ElseIf rs_kz_zdy_2("FType")="4" Then
					Numr_1=request("Numr_"&id&"_1")
					Numr_2=request("Numr_"&id&"_2")
					str33=str33+"&Numr_"&id&"_1="+Numr_1
'Numr_2=request("Numr_"&id&"_2")
					str33=str33+"&Numr_"&id&"_2="+Numr_2
'Numr_2=request("Numr_"&id&"_2")
					If Numr_2<>"" Then
						If Numr_1=1 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '%"& Numr_2 &"%')"
'If Numr_1=1 Then
						Elseif Numr_1=2 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue not like '%"& Numr_2 &"%')"
'Elseif Numr_1=2 Then
						Elseif Numr_1=3 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue='"& Numr_2 &"')"
'Elseif Numr_1=3 Then
						Elseif Numr_1=4 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue<>'"& Numr_2 &"')"
'Elseif Numr_1=4 Then
						Elseif Numr_1=5 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '"& Numr_2 &"%')"
'Elseif Numr_1=5 Then
						Elseif Numr_1=6 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '%"& Numr_2 &"')"
'Elseif Numr_1=6 Then
						end if
					end if
				ElseIf rs_kz_zdy_2("FType")="5" Then
					beiz_1=request("beiz_"&id&"_1")
					beiz_2=request("beiz_"&id&"_2")
					str33=str33+"&beiz_"&id&"_1="+beiz_1
'beiz_2=request("beiz_"&id&"_2")
					str33=str33+"&beiz_"&id&"_2="+beiz_2
					beiz_2=request("beiz_"&id&"_2")
					If beiz_2<>"" Then
						If beiz_1=1 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '%"& beiz_2 &"%')"
'If beiz_1=1 Then
						Elseif beiz_1=2 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue not like '%"& beiz_2 &"%')"
'Elseif beiz_1=2 Then
						Elseif beiz_1=3 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue='"& beiz_2 &"')"
'Elseif beiz_1=3 Then
						Elseif beiz_1=4 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue<>'"& beiz_2 &"')"
'Elseif beiz_1=4 Then
						Elseif beiz_1=5 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '"& beiz_2 &"%')"
'Elseif beiz_1=5 Then
						Elseif beiz_1=6 Then
							str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '%"& beiz_2 &"')"
'Elseif beiz_1=6 Then
						end if
					end if
				ElseIf rs_kz_zdy_2("FType")="6" Then
					IsNot_1=request("IsNot_"&id&"_1")
					str33=str33+"&IsNot_"&id&"_1="+IsNot_1
'IsNot_1=request("IsNot_"&id&"_1")
					If IsNot_1<>"" Then
						str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue='"& IsNot_1 &"')"
'If IsNot_1<>"" Then
					end if
				else
					meju_1=request("meju_"&id&"_1")
					str33=str33+"&meju_"&id&"_1="+Server.Urlencode(meju_1)
'meju_1=request("meju_"&id&"_1")
					If meju_1<>"" Then
						str_Result=str_Result+" and "&col&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue='"& meju_1 &"')"
'If meju_1<>"" Then
					end if
				end if
				rs_kz_zdy_2.movenext
			Loop
		end if
		rs_kz_zdy_2.close
		Set rs_kz_zdy_2=Nothing
		pub_cf=str33
	end function
	Function Show_Extended_By_Type(TName,typ,ord,columns)
		Dim rs_kz_zdy, rs_kz_zdy_88, num1, i_jm, j_jm, classNamezdy, c_Value,sql,showWhere
		if columns="" or columns=0 then
			columns=3
		else
			columns=cint(columns)
		end if
		if typ="" then
			typ=0
		end if
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		sql="select * from ERP_CustomFields where TName='"&TName&"' and IsUsing=1 and del = 1 and FType in("&typ&") order by FOrder asc "
		rs_kz_zdy.open sql,conn,1,1
		num1=rs_kz_zdy.RecordCount
		i_jm=0
		j_jm=1
		if Not rs_kz_zdy.eof then
			do until rs_kz_zdy.eof
				classNamezdy=""
				If rs_kz_zdy("FType")=5 Then classNamezdy="ywcss2"
				If i_jm=0 Then Response.write("<tr class='"&classNamezdy&"'>")
				if clng(i_jm/columns)=i_jm/columns and i_jm<>0 then
					Response.write("</tr><tr class='"&classNamezdy&"'>")
					j_jm=j_jm+1
					Response.write("</tr><tr class='"&classNamezdy&"'>")
				end if
				Set rs_kz_zdy_88=server.CreateObject("adodb.recordset")
				rs_kz_zdy_88.open "select case when b.ftype=3 and isnull(FValue,'')<>'' then convert(varchar(10),isnull(FValue,''),120) else isnull(FValue,'') end FValue from ERP_CustomValues a inner join ERP_CustomFields b on a.fieldsid = b.id where a.FieldsID='"&rs_kz_zdy("id")&"' and a.OrderID='"&ord&"' ",conn,1,1
				If Not rs_kz_zdy_88.eof Then
					c_Value=rs_kz_zdy_88("FValue")
					if rs_kz_zdy("FType")=2 then
						c_Value=replace(c_Value&"",Chr(13)&Chr(10),"<br>")
					end if
				else
					c_Value=""
				end if
				rs_kz_zdy_88.close
				Set rs_kz_zdy_88=nothing
				Response.write "" & vbcrlf & "                     <td align=""right"" height=""25"">"
				Response.write rs_kz_zdy("FName")
				Response.write "：</td>" & vbcrlf & "                      <td "
				if i_jm=num1-1  then
					Response.write "：</td>" & vbcrlf & "                      <td "
					Response.write "colspan="""
					Response.write 1+2*(j_jm*columns-num1)
					Response.write "colspan="""
					Response.write """"
				end if
				Response.write " class=""gray ewebeditorImg"">&nbsp;"
				Response.write c_Value
				Response.write "</td>" & vbcrlf & "                        "
				i_jm=i_jm+1
				Response.write "</td>" & vbcrlf & "                        "
				rs_kz_zdy.movenext
			loop
			Response.write("</tr>")
		end if
		rs_kz_zdy.close
		set rs_kz_zdy=nothing
	end function
	Function Show_Extended_By_TypeDeal(TName,typ,ord,columns,repID)
		Dim rs_kz_zdy, rs_kz_zdy_88, num1, i_jm, j_jm, classNamezdy, c_Value,sql,showWhere
		if columns="" or columns=0 then
			columns=3
		else
			columns=cint(columns)
		end if
		if typ="" then
			typ=0
		end if
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		sql="select * from Copy_CustomFields where TName='"&TName&"' AND RepairOrder = "&repID&" and IsUsing=1 and del = 1 and FType in("&typ&") order by FOrder asc "
		rs_kz_zdy.open sql,conn,1,1
		num1=rs_kz_zdy.RecordCount
		i_jm=0
		j_jm=1
		if Not rs_kz_zdy.eof then
			do until rs_kz_zdy.eof
				classNamezdy=""
				If rs_kz_zdy("FType")=5 Then classNamezdy="ywcss2"
				If i_jm=0 Then Response.write("<tr class='"&classNamezdy&"'>")
				if clng(i_jm/columns)=i_jm/columns and i_jm<>0 then
					Response.write("</tr><tr class='"&classNamezdy&"'>")
					j_jm=j_jm+1
					Response.write("</tr><tr class='"&classNamezdy&"'>")
				end if
				Set rs_kz_zdy_88=server.CreateObject("adodb.recordset")
				rs_kz_zdy_88.open "select isnull(FValue,'') FValue from ERP_CustomValues where FieldsID='"&rs_kz_zdy("id")&"' and OrderID='"&ord&"' ",conn,1,1
				If Not rs_kz_zdy_88.eof Then
					c_Value=rs_kz_zdy_88("FValue")
					if rs_kz_zdy("FType")=2 then
						c_Value=replace(c_Value&"",Chr(13)&Chr(10),"<br>")
					end if
				else
					c_Value=""
				end if
				rs_kz_zdy_88.close
				Set rs_kz_zdy_88=nothing
				Response.write "" & vbcrlf & "                     <td align=""right"" height=""25"">"
				Response.write rs_kz_zdy("FName")
				Response.write "：</td>" & vbcrlf & "                      <td "
				if i_jm=num1-1  then
					Response.write "：</td>" & vbcrlf & "                      <td "
					Response.write "colspan="""
					Response.write 1+2*(j_jm*columns-num1)
					Response.write "colspan="""
					Response.write """"
				end if
				Response.write " class=""gray ewebeditorImg"">"
				Response.write c_Value
				Response.write "&nbsp;</td>" & vbcrlf & "                  "
				i_jm=i_jm+1
				Response.write "&nbsp;</td>" & vbcrlf & "                  "
				rs_kz_zdy.movenext
			loop
			Response.write("</tr>")
		end if
		rs_kz_zdy.close
		set rs_kz_zdy=nothing
	end function
	Function Show_Extended_By_TypeDealBZ(TName,typ,ord,columns,repID)
		Dim rs_kz_zdy, rs_kz_zdy_88, num1, i_jm, j_jm, classNamezdy, c_Value,sql,showWhere
		if columns="" or columns=0 then
			columns=3
		else
			columns=cint(columns)
		end if
		if typ="" then
			typ=0
		end if
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		sql="select * from Copy_CustomFields where TName='"&TName&"' AND RepairOrder = "&repID&" and IsUsing=1 and del = 1 and FType in("&typ&") order by FOrder asc "
		rs_kz_zdy.open sql,conn,1,1
		num1=rs_kz_zdy.RecordCount
		i_jm=0
		j_jm=1
		if Not rs_kz_zdy.eof then
			do until rs_kz_zdy.eof
				classNamezdy=""
				If rs_kz_zdy("FType")=5 Then classNamezdy="ywcss2"
				Response.write("<tr class='"&classNamezdy&"'>")
				Set rs_kz_zdy_88=server.CreateObject("adodb.recordset")
				rs_kz_zdy_88.open "select isnull(FValue,'') FValue from ERP_CustomValues where FieldsID='"&rs_kz_zdy("id")&"' and OrderID='"&ord&"' ",conn,1,1
				If Not rs_kz_zdy_88.eof Then
					c_Value=rs_kz_zdy_88("FValue")
					if rs_kz_zdy("FType")=2 then
						c_Value=replace(c_Value&"",Chr(13)&Chr(10),"<br>")
					end if
				else
					c_Value=""
				end if
				rs_kz_zdy_88.close
				Set rs_kz_zdy_88=nothing
				Response.write "" & vbcrlf & "                     <td align=""right"" height=""25"">"
				Response.write rs_kz_zdy("FName")
				Response.write "：</td>" & vbcrlf & "                        <td colspan="""
				Response.write columns
				Response.write """ class=""gray ewebeditorImg"">"
				Response.write c_Value
				Response.write "&nbsp;</td>" & vbcrlf & "                    "
				i_jm=i_jm+1
				Response.write "&nbsp;</td>" & vbcrlf & "                    "
				Response.write("</tr>")
				rs_kz_zdy.movenext
			loop
		end if
		rs_kz_zdy.close
		set rs_kz_zdy=nothing
	end function
	Function Show_Extended_By_Type2(TName,typ,ord,columns,sort1,filed1)
		Dim rs_kz_zdy, rs_kz_zdy_88, num1, i_jm, j_jm, classNamezdy, c_Value, FVID
		if columns="" or columns=0 then
			columns=3
		else
			columns=cint(columns)
		end if
		if typ="" then
			typ=0
		end if
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		sql="select * from ERP_CustomFields where TName='"&TName&"' and IsUsing=1 and del=1 and FType in("&typ&") order by FOrder asc "
		rs_kz_zdy.open sql,conn,1,1
		num1=rs_kz_zdy.RecordCount
		i_jm=0
		j_jm=1
		if Not rs_kz_zdy.eof then
			do until rs_kz_zdy.eof
				classNamezdy=""
				If rs_kz_zdy("FType")=5 Then classNamezdy="ywcss2"
				If i_jm=0 Then Response.write("<tr class='"&classNamezdy&"'>")
				if clng(i_jm/columns)=i_jm/columns and i_jm<>0 then
					Response.write("</tr><tr class='"&classNamezdy&"'>")
					j_jm=j_jm+1
					Response.write("</tr><tr class='"&classNamezdy&"'>")
				end if
				Set rs_kz_zdy_88=server.CreateObject("adodb.recordset")
				rs_kz_zdy_88.open "select isnull(FValue,'') FValue,id from ERP_CustomValues where FieldsID='"&rs_kz_zdy("id")&"' and OrderID='"&ord&"' ",conn,1,1
				If Not rs_kz_zdy_88.eof Then
					c_Value=rs_kz_zdy_88("FValue")
					FVID = rs_kz_zdy_88("id")
					if rs_kz_zdy("FType")=2 then
						c_Value=replace(c_Value&"",Chr(13)&Chr(10),"<br>")
					end if
				else
					c_Value=""
				end if
				rs_kz_zdy_88.close
				Set rs_kz_zdy_88=Nothing
				If FVID&"" = "" Then FVID=0
				Response.write "" & vbcrlf & "                      <td align=""right"" height=""25"">"
				Response.write rs_kz_zdy("FName")
				Response.write "：</td>" & vbcrlf & "                       <td "
				if i_jm=num1-1  then
					Response.write "：</td>" & vbcrlf & "                       <td "
					Response.write "colspan="""
					Response.write 1+2*(j_jm*columns-num1)
					Response.write "colspan="""
					Response.write """"
				end if
				Response.write " class=""gray ewebeditorImg"">"
				If rs_kz_zdy("FType")=5 Then
					If c_Value&""<>"" Then
						Dim arr_img
						arr_img = split(c_Value,"<img",-1,1)
'Dim arr_img
						if ubound(arr_img)>0 then
							Response.write "" & vbcrlf & "                                              <a href=""javascript:;"" onClick=""window.open('info.asp?ord="
							Response.write app.base64.pwurl(FVID)
							Response.write "&sort1="
							Response.write sort1
							Response.write "&sort2="
							Response.write filed1
							Response.write "','neww6768999in','width=' + 1600 + ',height=' + 800 + ',fullscreen =no,scrollbars=1,toolbar=0,resizable=1,left=0,top=150');return false;"" onMouseOver=""window.status='none';return true;"" title=""放大查看"">"
							Response.write filed1
							Response.write c_Value
							Response.write "</a>" & vbcrlf & "                           "
						else
							Response.write(c_Value)
						end if
					end if
				else
					Response.write c_Value
				end if
				Response.write "&nbsp;</td>" & vbcrlf & "                   "
				i_jm=i_jm+1
				Response.write "&nbsp;</td>" & vbcrlf & "                   "
				rs_kz_zdy.movenext
			loop
			Response.write("</tr>")
		end if
		rs_kz_zdy.close
		set rs_kz_zdy=nothing
	end function
	Function Del_Extended_Value(TName,ord)
		if ord="" Then ord=0
		sql="delete from ERP_CustomValues where id in(select b.id from ERP_CustomFields  a " _
		& " left join ERP_CustomValues b on a.id=b.fieldsid " _
		& " where a.tname='"&TName&"' and b.orderid in("&ord&")) "
		conn.execute(sql)
	end function
	Function Show_Search_Extended(TName)
		set rs_kz_zdy_2=server.CreateObject("adodb.recordset")
		sql2="select * from ERP_CustomFields where TName='"&TName&"' and IsUsing=1 and del=1 and CanSearch=1 order by FOrder asc "
		rs_kz_zdy_2.open sql2,conn,1,1
		if rs_kz_zdy_2.eof then
		else
			do until rs_kz_zdy_2.eof
				Response.write "" & vbcrlf & "                     <tr onMouseOut=""this.style.backgroundColor=''"" onMouseOver=""this.style.backgroundColor='efefef'"">" & vbcrlf & "                   <td align=""right"">"
				Response.write rs_kz_zdy_2("FName")
				Response.write "：</td>" & vbcrlf & "                      <td align=""left"">" & vbcrlf & "                 "
				If rs_kz_zdy_2("FType")="1" then
					Response.write "" & vbcrlf & "                             <select name=""danh_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_1"">" & vbcrlf & "                              <option value=""1"">包含</option>" & vbcrlf & "                           <option value=""2"">不包含</option>" & vbcrlf & "                         <option value=""3"">等于</option>" & vbcrlf & "                           <option value=""4"">不等于</option>" & vbcrlf & "                         <option value=""5"">以..开始</option>" & vbcrlf & "                               <option value=""6"">以..结束</option>" & vbcrlf & "                             </select>" & vbcrlf & "                               <input name=""danh_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_2"" type=""text"" size=""15"">" & vbcrlf & "                            "
				ElseIf rs_kz_zdy_2("FType")="2" Then
					Response.write "" & vbcrlf & "                             <select name=""duoh_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_1"">" & vbcrlf & "                              <option value=""1"">包含</option>" & vbcrlf & "                           <option value=""2"">不包含</option>" & vbcrlf & "                         <option value=""3"">等于</option>" & vbcrlf & "                           <option value=""4"">不等于</option>" & vbcrlf & "                         <option value=""5"">以..开始</option>" & vbcrlf & "                               <option value=""6"">以..结束</option>" & vbcrlf & "                             </select>" & vbcrlf & "                               <input name=""duoh_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_2"" type=""text"" size=""15"">" & vbcrlf & "                            "
				ElseIf rs_kz_zdy_2("FType")="3" then
					Response.write "" & vbcrlf & "                             <INPUT name=""date_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_1"" size=""11""  id=""date_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_1"" onmouseup=toggleDatePicker(""paydate1div_"
					Response.write rs_kz_zdy_2("id")
					Response.write """,""date.date_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_1"")><DIV id=""paydate1div_"
					Response.write rs_kz_zdy_2("id")
					Response.write """ style=""POSITION: absolute"" name =""paydate1div_"
					Response.write rs_kz_zdy_2("id")
					Response.write """></DIV>&nbsp;-&nbsp;<INPUT name=""date_"
					Response.write rs_kz_zdy_2("id")
					Response.write rs_kz_zdy_2("id")
					Response.write "_2"" size=""11"" id=""date_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_2"" onmouseup=toggleDatePicker(""paydate2div_"
					Response.write rs_kz_zdy_2("id")
					Response.write """,""date.date_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_2"")><DIV id=""paydate2div_"
					Response.write rs_kz_zdy_2("id")
					Response.write """ style=""POSITION: absolute"" name =""paydate2div_"
					Response.write rs_kz_zdy_2("id")
					Response.write """></DIV>" & vbcrlf & "                          "
				ElseIf rs_kz_zdy_2("FType")="4" then
					Response.write "" & vbcrlf & "                             <select name=""Numr_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_1"">" & vbcrlf & "                              <option value=""1"">包含</option>" & vbcrlf & "                           <option value=""2"">不包含</option>" & vbcrlf & "                         <option value=""3"">等于</option>" & vbcrlf & "                           <option value=""4"">不等于</option>" & vbcrlf & "                         <option value=""5"">以..开始</option>" & vbcrlf & "                               <option value=""6"">以..结束</option>" & vbcrlf & "                             </select>" & vbcrlf & "                               <input name=""Numr_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_2"" type=""text"" size=""15"">" & vbcrlf & "                            "
				ElseIf rs_kz_zdy_2("FType")="5" then
					Response.write "" & vbcrlf & "                             <select name=""beiz_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_1"">" & vbcrlf & "                              <option value=""1"">包含</option>" & vbcrlf & "                           <option value=""2"">不包含</option>" & vbcrlf & "                         <option value=""3"">等于</option>" & vbcrlf & "                           <option value=""4"">不等于</option>" & vbcrlf & "                         <option value=""5"">以..开始</option>" & vbcrlf & "                               <option value=""6"">以..结束</option>" & vbcrlf & "                             </select>" & vbcrlf & "                               <input name=""beiz_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_2"" type=""text"" size=""15"">" & vbcrlf & "                            "
				ElseIf rs_kz_zdy_2("FType")="6" then
					Response.write "" & vbcrlf & "                             <select name=""IsNot_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_1"">" & vbcrlf & "                              <option value="""">选择</option>" & vbcrlf & "                            <option value=""是"">是</option>" & vbcrlf & "                            <option value=""否"">否</option>" & vbcrlf & "                            </select>" & vbcrlf & "                               "
				else
					Response.write "" & vbcrlf & "                             <select name=""meju_"
					Response.write rs_kz_zdy_2("id")
					Response.write "_1"">" & vbcrlf & "                              <option value="""">选择</option>" & vbcrlf & "                            "
					Set rs_kz_zdy_8=server.CreateObject("adodb.recordset")
					rs_kz_zdy_8.open "select * from ERP_CustomOptions where CFID="&rs_kz_zdy_2("id")&" ",conn,1,1
					If Not rs_kz_zdy_8.eof Then
						Do While Not rs_kz_zdy_8.eof
							Response.write "" & vbcrlf & "                                             <option value="""
							Response.write rs_kz_zdy_8("CValue")
							Response.write """>"
							Response.write rs_kz_zdy_8("CValue")
							Response.write "</option>" & vbcrlf & "                                            "
							rs_kz_zdy_8.movenext
						Loop
					end if
					rs_kz_zdy_8.close
					Set rs_kz_zdy_8=nothing
					Response.write "" & vbcrlf & "                             </select>" & vbcrlf & "                               "
				end if
				Response.write "" & vbcrlf & "                     </td>" & vbcrlf & "                   </tr>" & vbcrlf & "                   "
				rs_kz_zdy_2.movenext
			loop
		end if
		rs_kz_zdy_2.close
		set rs_kz_zdy_2=Nothing
	end function
	Function Show_Search_Extended_Simple(TName)
		set rs_kz_zdy_2=server.CreateObject("adodb.recordset")
		sql2="select * from ERP_CustomFields where TName='"&TName&"' and IsUsing=1 and del=1 and CanSearch=1 order by FOrder asc "
		rs_kz_zdy_2.open sql2,conn,1,1
		if rs_kz_zdy_2.eof =False then
			do until rs_kz_zdy_2.eof
				Response.write "" & vbcrlf & "                     <tr onMouseOut=""this.style.backgroundColor=''"" onMouseOver=""this.style.backgroundColor='efefef'"">" & vbcrlf & "                   <td align=""right"">"
				Response.write rs_kz_zdy_2("FName")
				Response.write "：</td>" & vbcrlf & "                      <td align=""left"">" & vbcrlf & "                 "
				Select Case rs_kz_zdy_2("FType")
				Case "1" :
				Response.write "" & vbcrlf & "                             <input name=""danh_"
				Response.write rs_kz_zdy_2("id")
				Response.write """ type=""text"" size=""15"">" & vbcrlf & "                              "
				Case "2" :
				Response.write "" & vbcrlf & "                             <input name=""duoh_"
				Response.write rs_kz_zdy_2("id")
				Response.write """ type=""text"" size=""15"">" & vbcrlf & "                              "
				Case "3" :
				Response.write "" & vbcrlf & "                             <INPUT name=""date_"
				Response.write rs_kz_zdy_2("id")
				Response.write "_1"" size=""11""  id=""date_"
				Response.write rs_kz_zdy_2("id")
				Response.write "_1"" onmouseup=toggleDatePicker(""paydate1div_"
				Response.write rs_kz_zdy_2("id")
				Response.write """,""date.date_"
				Response.write rs_kz_zdy_2("id")
				Response.write "_1"")><DIV id=""paydate1div_"
				Response.write rs_kz_zdy_2("id")
				Response.write """ style=""POSITION: absolute"" name =""paydate1div_"
				Response.write rs_kz_zdy_2("id")
				Response.write """></DIV>&nbsp;-&nbsp;<INPUT name=""date_"
				Response.write rs_kz_zdy_2("id")
				Response.write rs_kz_zdy_2("id")
				Response.write "_2"" size=""11"" id=""date_"
				Response.write rs_kz_zdy_2("id")
				Response.write "_2"" onmouseup=toggleDatePicker(""paydate2div_"
				Response.write rs_kz_zdy_2("id")
				Response.write """,""date.date_"
				Response.write rs_kz_zdy_2("id")
				Response.write "_2"")><DIV id=""paydate2div_"
				Response.write rs_kz_zdy_2("id")
				Response.write """ style=""POSITION: absolute"" name =""paydate2div_"
				Response.write rs_kz_zdy_2("id")
				Response.write """></DIV>" & vbcrlf & "                          "
				Case "4" :
				Response.write "" & vbcrlf & "                             <input name=""Numr_"
				Response.write rs_kz_zdy_2("id")
				Response.write """ type=""text"" size=""15"">" & vbcrlf & "                              "
				Case "5" :
				Response.write "" & vbcrlf & "                             <input name=""beiz_"
				Response.write rs_kz_zdy_2("id")
				Response.write """ type=""text"" size=""15"">" & vbcrlf & "                              "
				Case "6" :
				Response.write "" & vbcrlf & "                             <select name=""IsNot_"
				Response.write rs_kz_zdy_2("id")
				Response.write """>" & vbcrlf & "                                <option value="""">选择</option>" & vbcrlf & "                            <option value=""是"">是</option>" & vbcrlf & "                            <option value=""否"">否</option>" & vbcrlf & "                            </select>" & vbcrlf & "                               "
				Case Else
				Response.write "" & vbcrlf & "                             <select name=""meju_"
				Response.write rs_kz_zdy_2("id")
				Response.write """>" & vbcrlf & "                                <option value="""">选择</option>" & vbcrlf & "                            "
				Set rs_kz_zdy_8=server.CreateObject("adodb.recordset")
				rs_kz_zdy_8.open "select * from ERP_CustomOptions where CFID="&rs_kz_zdy_2("id")&" ",conn,1,1
				If Not rs_kz_zdy_8.eof Then
					Do While Not rs_kz_zdy_8.eof
						Response.write "" & vbcrlf & "                                             <option value="""
						Response.write rs_kz_zdy_8("CValue")
						Response.write """>"
						Response.write rs_kz_zdy_8("CValue")
						Response.write "</option>" & vbcrlf & "                                            "
						rs_kz_zdy_8.movenext
					Loop
				end if
				rs_kz_zdy_8.close
				Set rs_kz_zdy_8=nothing
				Response.write "" & vbcrlf & "                             </select>" & vbcrlf & "                               "
				End Select
				Response.write "" & vbcrlf & "                     </td>" & vbcrlf & "                   </tr>" & vbcrlf & "                   "
				rs_kz_zdy_2.movenext
			loop
		end if
		rs_kz_zdy_2.close
		set rs_kz_zdy_2=Nothing
	end function
	Function searchExtended_Simple(TName,keycode)
		Dim rs_kz_zdy_2 ,searchsql
		set rs_kz_zdy_2=server.CreateObject("adodb.recordset")
		Dim sql2 : sql2="select * from ERP_CustomFields where TName="&TName&" "& KZ_LIMITID &" and IsUsing=1 and del=1 and CanSearch=1 order by FOrder asc "
		Dim str33,id,danh,Numr,beiz,IsNot_1,meju,duoh,date_1,date_2
		rs_kz_zdy_2.open sql2,conn,1,1
		if rs_kz_zdy_2.eof=False then
			str33=""
			do until rs_kz_zdy_2.eof
				id=rs_kz_zdy_2("id")
				Select Case rs_kz_zdy_2("FType")
				Case "1" :
				danh=request("danh_"&id&"")
				str33=str33+"&danh_"&id&"="+danh
'danh=request("danh_"&id&"")
				If danh<>"" Then
					searchsql=searchsql+" and "&keycode&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '%"& danh &"%')"
'If danh<>"" Then
				end if
				Case "2" :
				duoh=request("duoh_"&id&"")
				str33=str33+"&duoh_"&id&"="+duoh
'duoh=request("duoh_"&id&"")
				If duoh<>"" Then
					searchsql=searchsql+" and "&keycode&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '%"& duoh &"%')"
'If duoh<>"" Then
				end if
				Case "3" :
				date_1=request("date_"&id&"_1")
				date_2=request("date_"&id&"_2")
				str33=str33+"&date_"&id&"_1="+date_1
'date_2=request("date_"&id&"_2")
				str33=str33+"&date_"&id&"_2="+date_2
'date_2=request("date_"&id&"_2")
				If date_1<>"" or date_2<>"" Then
					Dim sqldate
					If date_1<>"" Then
						sqldate=" and (case isDate(FValue) when 1 then  cast(FValue as datetime) else cast('1950-1-1' as datetime) end)>=cast('"& date_1 &"'as datetime)"
'If date_1<>"" Then
					end if
					If date_2<>"" Then
						sqldate=sqldate&" and (case isDate(FValue) when 1 then  cast(FValue as datetime) else cast('1950-1-1' as datetime) end)<=cast('"& date_2 &"' as datetime)"
'If date_2<>"" Then
					end if
					searchsql=searchsql+" and "&keycode&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" "&sqldate&")"
'If date_2<>"" Then
				end if
				Case "4" :
				Numr=request("Numr_"&id&"")
				str33=str33+"&Numr_"&id&"="+Numr
'Numr=request("Numr_"&id&"")
				If Numr<>"" Then
					searchsql=searchsql+" and "&keycode&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '%"& Numr &"%')"
'If Numr<>"" Then
				end if
				Case "5" :
				beiz=request("beiz_"&id&"")
				str33=str33+"&beiz_"&id&"="+beiz
'beiz=request("beiz_"&id&"")
				If beiz<>"" Then
					searchsql=searchsql+" and "&keycode&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue like '%"& beiz &"%')"
'If beiz<>"" Then
				end if
				Case "6" :
				IsNot_1=request("IsNot_"&id&"")
				str33=str33+"&IsNot_"&id&"_1="+IsNot_1
'IsNot_1=request("IsNot_"&id&"")
				If IsNot_1<>"" Then
					searchsql=searchsql+" and "&keycode&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue='"& IsNot_1 &"')"
'If IsNot_1<>"" Then
				end if
				Case Else
				meju=request("meju_"&id&"")
				str33=str33+"&meju_"&id&"="+Server.Urlencode(meju)
'meju=request("meju_"&id&"")
				If meju<>"" Then
					searchsql=searchsql+" and "&keycode&" in (select OrderID from ERP_CustomValues where FieldsID="&id&" and FValue='"& meju &"')"
'If meju<>"" Then
				end if
				End Select
				rs_kz_zdy_2.movenext
			Loop
		end if
		rs_kz_zdy_2.close
		Set rs_kz_zdy_2=Nothing
		pub_cf=str33
		searchExtended_Simple=searchsql
	end function
	Sub Export_xls_Extended(TName,typ,cols,columns,ord)
		IF typ=1 then
			set rs_kz_zdy=server.CreateObject("adodb.recordset")
			kz_sql="select 1 from erp_customFields  where TName='"&TName&"'  and IsUsing=1 and del=1 and canExport=1 order by FOrder asc"
			rs_kz_zdy.open kz_sql,conn,1,1
			do while not rs_kz_zdy.eof
				xlApplication.ActiveSheet.columns(columns).columnWidth=15
				xlApplication.ActiveSheet.columns(columns).HorizontalAlignment=3
				rs_kz_zdy.movenext
				columns=columns+1
'rs_kz_zdy.movenext
			loop
			rs_kz_zdy.close
			set rs_kz_zdy=nothing
		ElseIf typ=2 then
			set rs_kz_zdy=server.CreateObject("adodb.recordset")
			kz_sql="select FName from erp_customFields  where TName='"&TName&"' and IsUsing=1 and del=1 and canExport=1 order by FOrder asc"
			rs_kz_zdy.open kz_sql,conn,1,1
			do while not rs_kz_zdy.eof
				xlWorksheet.Cells(1,columns).Value = rs_kz_zdy("FName")
				xlWorksheet.Cells(1,columns).font.Size=10
				xlWorksheet.Cells(1,columns).font.bold=true
				rs_kz_zdy.movenext
				columns=columns+1
				rs_kz_zdy.movenext
			loop
			rs_kz_zdy.close
			set rs_kz_zdy =nothing
		ElseIf typ=3 then
			set rs_kz_zdy=server.CreateObject("adodb.recordset")
			kz_sql="select b.FValue from erp_customFields a left join (select fieldsid,fvalue,orderid from erp_customValues where orderid='"&ord&"') b " _
			& " on b.fieldsid=a.id where a.TName='"&TName&"' and a.IsUsing=1 and a.canExport=1 order by a.FOrder asc"
			rs_kz_zdy.open kz_sql,conn,1,1
			do while not rs_kz_zdy.eof
				xlWorksheet.Cells(1+cols,columns).Value = rs_kz_zdy("FValue")
'do while not rs_kz_zdy.eof
				xlWorksheet.Cells(1+cols,columns).font.Size=10
'do while not rs_kz_zdy.eof
				rs_kz_zdy.movenext
				columns=columns+1
				rs_kz_zdy.movenext
			loop
			rs_kz_zdy.close
			set rs_kz_zdy=nothing
		end if
	end sub
	Function dyExtended(TName,columns)
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		kz_sql="select * from ERP_CustomFields where TName="&TName&" and IsUsing=1 and del=1 order by FOrder asc "
		rs_kz_zdy.open kz_sql,conn,1,1
		num1=rs_kz_zdy.RecordCount
		i_jm=0
		j_jm=1
		if rs_kz_zdy.eof then
		else
			Response.write("<table width='100%' border='0' cellpadding='0' cellspacing='0' id='content2' bgcolor='#000000'>")
			Response.write("<tr>")
			do until rs_kz_zdy.eof
				if clng(i_jm/columns)=i_jm/columns and i_jm<>0 then
					Response.write("</tr><tr>")
					j_jm=j_jm+1
					Response.write("</tr><tr>")
				end if
				Response.write "" & vbcrlf & "                     <td width=""42%"" height=""27"" "
				if i_jm=num1-1  then
					Response.write "" & vbcrlf & "                     <td width=""42%"" height=""27"" "
					Response.write "colspan="""
					Response.write 1+2*(j_jm*columns-num1)
					Response.write "colspan="""
					Response.write """"
				end if
				Response.write ">" & vbcrlf & "                            {"
				Response.write rs_kz_zdy("fname")
				Response.write ":<span title=""点击复制"
				Response.write rs_kz_zdy("fname")
				Response.write """ id=""zdy"
				Response.write rs_kz_zdy("id")
				Response.write """ onclick=""if(!copyClick(this.id)){alert('复制成功');}"" style=""cursor:pointer"">expandfield_"
				Response.write rs_kz_zdy("id")
				Response.write "_E</span>}" & vbcrlf & "                   " & vbcrlf & "                        </td>" & vbcrlf & "                   "
				i_jm=i_jm+1
				rs_kz_zdy.movenext
			loop
			Response.write("</tr>")
			Response.write("</table>")
		end if
		rs_kz_zdy.close
		set rs_kz_zdy=nothing
	end function
	Function dyMxExtended(TName,columns)
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		If TName = 28 Then
			kz_sql="select a.id,a.fname,b.sort1 from ERP_CustomFields a inner join sortonehy b on b.ord+200000 = a.tname and b.gate2=3001 and b.del=1 and b.isStop = 0 and a.FType<>'5' and a.id>0 ORDER BY FOrder asc,a.id "
'If TName = 28 Then
		else
			kz_sql="select * from ERP_CustomFields where TName="&TName&" and IsUsing=1 and del=1 order by FOrder asc "
		end if
		rs_kz_zdy.open kz_sql,conn,1,1
		num1=rs_kz_zdy.RecordCount
		i_jm=0
		j_jm=1
		if rs_kz_zdy.eof then
		else
			Response.write("<table width='100%' border='0' cellpadding='0' cellspacing='0' id='content2' bgcolor='#000000'>")
			Response.write("<tr>")
			do until rs_kz_zdy.eof
				if clng(i_jm/columns)=i_jm/columns and i_jm<>0 then
					Response.write("</tr><tr>")
					j_jm=j_jm+1
					Response.write("</tr><tr>")
				end if
				Response.write "" & vbcrlf & "                     <td width=""42%"" height=""27"" "
				if i_jm=num1-1  then
					Response.write "" & vbcrlf & "                     <td width=""42%"" height=""27"" "
					Response.write "colspan="""
					Response.write 1+2*(j_jm*columns-num1)
					Response.write "colspan="""
					Response.write """"
				end if
				Response.write ">" & vbcrlf & "                            {"
				Response.write rs_kz_zdy("fname")
				Response.write "["
				Response.write rs_kz_zdy("sort1")
				Response.write "]：<span title=""点击复制"
				Response.write rs_kz_zdy("fname")
				Response.write """ id=""zdy"
				Response.write rs_kz_zdy("id")
				Response.write """ onclick=""if(!copyClick(this.id)){alert('复制成功');}"" style=""cursor:pointer"">Extended_"
				Response.write rs_kz_zdy("id")
				Response.write "_E</span>}" & vbcrlf & "                   " & vbcrlf & "                        </td>" & vbcrlf & "                   "
				i_jm=i_jm+1
				rs_kz_zdy.movenext
			loop
			Response.write("</tr>")
			Response.write("</table>")
		end if
		rs_kz_zdy.close
		set rs_kz_zdy=nothing
	end function
	Function dyExtended_kz(TName,columns)
		Response.write "" & vbcrlf & "     <table width='100%' border='0' cellpadding='4' cellspacing='1' id='content2' bgcolor='#C0CCDD'>" & vbcrlf & "         <tr class=top><td colspan="""
		Response.write columns
		Response.write """><strong>【公共字段】</strong></td></tr>" & vbcrlf & "         <td width=""33%"" height=""27"">{税号:<span title=""点击复制税号"" id=""zdy_taxno"" onclick=""if(!copyClick(this.id)){alert('复制成功');}"" style=""cursor:pointer"">expandfield_taxno_E</span>}</td>" & vbcrlf & "           "
		If columns = 1 Then Response.write "</tr><tr>"
		Response.write "" & vbcrlf & "             <td width=""33%"" height=""27"">{公司地址:<span title=""点击复制公司地址"" id=""zdy_addr"" onclick=""if(!copyClick(this.id)){alert('复制成功');}"" style=""cursor:pointer"">expandfield_addr_E</span>}</td>" & vbcrlf & "             "
		If 2 mod columns = 0 Then Response.write "</tr><tr>"
		Response.write "" & vbcrlf & "             <td width=""33%"" height=""27"">{公司电话:<span title=""点击复制公司电话"" id=""zdy_phone"" onclick=""if(!copyClick(this.id)){alert('复制成功');}"" style=""cursor:pointer"">expandfield_phone_E</span>}</td>" & vbcrlf & "           "
		If 3 mod columns = 0 Then Response.write "</tr><tr>"
		Response.write "" & vbcrlf & "             <td width=""33%"" height=""27"">{开户行:<span title=""点击复制开户行"" id=""zdy_bank"" onclick=""if(!copyClick(this.id)){alert('复制成功');}"" style=""cursor:pointer"">expandfield_bank_E</span>}</td>" & vbcrlf & "         "
		If 4 mod columns = 0 Then Response.write "</tr><tr>"
		Response.write "" & vbcrlf & "             <td width=""33%"" height=""27"">{开户行账号:<span title=""点击复制开户行账号"" id=""zdy_account"" onclick=""if(!copyClick(this.id)){alert('复制成功');}"" style=""cursor:pointer"">expandfield_account_E</span>}</td>" & vbcrlf & "           "
		If 5 mod columns = 0 Then
			Response.write "</tr>"
		else
			Response.write "<td colspan="&(columns-(5 mod columns))&"></td></tr>"
			Response.write "</tr>"
		end if
		Set rs =conn.execute("select ord,sort1 from sortonehy where gate2="&TName&" and isnull(id1,0)=0")
		If rs.eof= False Then
			While rs.eof = False
				set rs_kz_zdy=server.CreateObject("adodb.recordset")
				kz_sql="select * from ERP_CustomFields where TName="&(rs("ord")*1+100000)&" and IsUsing=1 and del=1 order by FOrder asc "
'set rs_kz_zdy=server.CreateObject("adodb.recordset")
				rs_kz_zdy.open kz_sql,conn,1,1
				if rs_kz_zdy.eof= False Then
					Response.write "<tr class=top><td colspan="""
					Response.write columns
					Response.write """><strong>【"
					Response.write rs("sort1")
					Response.write "】</strong></td></tr>"
					num1 = 0
					do until rs_kz_zdy.eof
						If num1 Mod columns = 0 Then Response.write "<tr>"
						Response.write "" & vbcrlf & "                                              <td width=""33%"" height=""27"">" & vbcrlf & "                                                        {"
						Response.write rs_kz_zdy("fname")
						Response.write ":<span title=""点击复制"
						Response.write rs_kz_zdy("fname")
						Response.write """ id=""zdy"
						Response.write rs_kz_zdy("id")
						Response.write """ onclick=""if(!copyClick(this.id)){alert('复制成功');}"" style=""cursor:pointer"">expandfield_"
						Response.write rs_kz_zdy("id")
						Response.write "_E</span>}                                    " & vbcrlf & "                                                </td>" & vbcrlf & "                                           "
						num1=num1+1
						If num1 Mod columns = 0 Then Response.write "</tr>"
						rs_kz_zdy.movenext
					Loop
					If num1 Mod columns > 0  Then Response.write "<td colspan="&columns-(num1 Mod columns)&"></td></tr>"
'Loop
				end if
				rs_kz_zdy.close
				set rs_kz_zdy=Nothing
				rs.movenext
			wend
		end if
		rs.close
		Response.write "" & vbcrlf & "      </table>" & vbcrlf & "        "
	end function
	Function isUsingExtend(TName)
		Dim rs,sql
		Set rs = server.CreateObject("adodb.recordset")
		sql =        "SELECT TOP 1 ID FROM ERP_CustomFields WHERE TName = "& TName &" AND IsUsing=1 AND del=1 AND FType <> '5' " &_
		"UNION " &_
		"SELECT TOP 1 ID FROM zdy WHERE sort1 = "& TName &" AND set_open = 1"
		rs.open sql,conn,1,1
		If Not rs.Eof Then
			isUsingExtend = True
		else
			isUsingExtend = False
		end if
		rs.close
		set rs = nothing
	end function
	Function getExtendedCount(TName)
		getExtendedCount = sdk.getSqlValue("select count(1) from ERP_CustomFields where TName="&TName&" "& KZ_LIMITID &" and IsUsing=1 and del=1", 0)
	end function
	Function showExtended_byListHeader(TName, ord, classStr)
		dim rs_kz_zdy, rs_kz_zdy_88, sql, rs7, sql7
		sql="select FName from ERP_CustomFields where TName="&TName&" "& KZ_LIMITID &" and IsUsing=1 and del=1 order by FOrder asc "
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		rs_kz_zdy.open sql,conn,1,1
		While rs_kz_zdy.eof = False
			Response.write "" & vbcrlf & "              <td width=""11%"" align=""center"" "
			Response.write classStr
			Response.write ">"
			Response.write rs_kz_zdy("FName")
			Response.write "</td>" & vbcrlf & " "
			rs_kz_zdy.movenext
		wend
		rs_kz_zdy.close
		Set rs_kz_zdy = Nothing
	end function
	Function showExtended_byLIsttdStr(TName, ord, classStr)
		dim rs_kz_zdy, rs_kz_zdy_88, sql, rs7, sql7, retStr
		retStr = ""
		sql="select * from ERP_CustomFields where TName="&TName&" "& KZ_LIMITID &" and IsUsing=1 and del=1 order by FOrder asc "
		set rs_kz_zdy=server.CreateObject("adodb.recordset")
		rs_kz_zdy.open sql,conn,1,1
		While rs_kz_zdy.eof = False
			retStr = retStr & "<td height=""30"" width=""10%"" class="""& classStr &""">"
			if rs_kz_zdy("FType")="1" Then
				retStr = retStr & "<input name=""danh_"& rs_kz_zdy("id") &""" type=""text"" size=""15"" id=""danh_"& rs_kz_zdy("id") &""" value="""& c_Value &""" dataType=""Limit"""
				if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then retStr = retStr & " min=""1"""
				retStr = retStr & " max=""500""  msg=""必须在1到500个字符"" maxlength=""4000"">"
			Elseif rs_kz_zdy("FType")="2" then
				retStr = retStr & "<textarea name=""duoh_"& rs_kz_zdy("id") &""" id=""duoh_"& rs_kz_zdy("id") &""" style=""overflow-y:hidden;word-break:break-all;width:160px;height:22px"" onfocus=""this.style.posHeight=this.scrollHeight"" onpropertychange=""this.style.posHeight=this.scrollHeight"" dataType=""Limit"""
				if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then retStr = retStr & " min=""1"" "
				retStr = retStr & "max=""500""  msg=""必须在1到500个字符"">"& c_Value &"</textarea>"
			elseif rs_kz_zdy("FType")="3" Then
				retStr = retStr & "<input readonly name=""date_"& rs_kz_zdy("id") &""" value="""& c_Value &""" size=""15"" id=""daysOfMonthPos"" onmouseup=""toggleDatePicker('daysOfMonth_"& rs_kz_zdy("id") &"','date_"& rs_kz_zdy("id") &"')"" dataType=""Limit"""
				if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then retStr = retStr & " min=""1"""
				retStr = retStr & " max=""500"" msg=""请选择日期"" style=""background-image:url(../images/datePicker.gif);background-position:right;background-repeat:no-repeat;""> <div id=""daysOfMonth_"& rs_kz_zdy("id") &""" style=""POSITION:absolute""></div>"
'if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then retStr = retStr & " min=""1"""
			ElseIf rs_kz_zdy("FType")="4" then
				retStr = retStr & "<input name=""Numr_"& rs_kz_zdy("id") &""" type=""text"" value="""& c_Value &""" size=""8"" id=""Numr_"& rs_kz_zdy("id") &""" onkeyup=""value=value.replace(/[^\d\.]/g,'')"" dataType=""Limit"""
				if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then retStr = retStr & " min=""1"" "
				retStr = retStr & "max=""500""  msg=""必须在1到500个字符"" >"
			Elseif rs_kz_zdy("FType")="5" then
				retStr = retStr & "<textarea name=""beiz_"& rs_kz_zdy("id") &""" id=""beiz_"& rs_kz_zdy("id") &""" style=""overflow-y:hidden;word-break:break-all;width:160px;height:22px"" onfocus=""this.style.posHeight=this.scrollHeight"" onpropertychange=""this.style.posHeight=this.scrollHeight"" dataType=""Limit"""
				if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  then retStr = retStr & " min=""1"""
				retStr = retStr & "max=""500""  msg=""必须在1到500个字符"">"& c_Value &"</textarea>"
			ElseIf rs_kz_zdy("FType")="6" then
				retStr = retStr & "<select name=""IsNot_"& rs_kz_zdy("id") &""" id=""IsNot_"& rs_kz_zdy("id") &"""  dataType=""Limit"""
				if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then retStr = retStr & " min=""1"""
				retStr = retStr & " max=""500""  msg=""必须在1到500个字符"">"
				retStr = retStr & "<option value=""是"""
				If c_Value="是" Then retStr = retStr & " selected"
				retStr = retStr & ">是</option>"
				retStr = retStr & "<option value=""否"""
				If c_Value="否" Then retStr = retStr & "selected"
				retStr = retStr & ">否</option>"
				retStr = retStr & "</select>"
			ElseIf rs_kz_zdy("FType")="7" then
				retStr = retStr & "<select name=""meju_" & rs_kz_zdy("id") &""" id=""meju_"& rs_kz_zdy("id") &"""  dataType=""Limit"""
				if rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then retStr = retStr & " min=""1"""
				retStr = retStr & " max=""500""  msg=""必须在1到500个字符"">"
				set rs7=conn.execute("select id,CValue from ERP_CustomOptions where CFID="&rs_kz_zdy("id")&" order by id asc ")
				do until rs7.eof
					retStr = retStr & "<option value="""& rs7("id") &""""
					If rs7("CValue")=c_Value Then retStr = retStr & " selected"
					retStr = retStr & ">"& rs7("CValue") &"</option>"
					rs7.movenext
				loop
				rs7.close
				retStr = retStr & "</select>"
			end if
			if  rs_kz_zdy("MustFillin") Or Len(KZ_LIMITID&"")>0  Then
				retStr = retStr & "&nbsp;<span class=""red"">*</span>"
			end if
			retStr = retStr & "</td>"
			rs_kz_zdy.movenext
		wend
		rs_kz_zdy.close
		Set rs_kz_zdy = Nothing
		showExtended_byLIsttdStr = retStr
	end function
	Function getExtendedValue(c_Value,priceDigits)
		if c_Value ="" then
			getExtendedValue=""
		else
			getExtendedValue=FormatNumber(zbcdbl(c_Value),priceDigits,-1,0,0)
			getExtendedValue=""
		end if
	end function
	
	If request("remind") <> "" Then
		Response.write "" & vbcrlf & "<script language=""javascript"">" & vbcrlf & "try{" & vbcrlf & "       jQuery(function(){" & vbcrlf & "              jQuery('form').each(function(){" & vbcrlf & "                 jQuery('<input type=""hidden"" name=""remind"" value="""
		Response.write Request("remind")
		Response.write """/>').appendTo(this);" & vbcrlf & "               });" & vbcrlf & "     });" & vbcrlf & "}catch(e){}" & vbcrlf & "</script>" & vbcrlf & ""
	end if
	ZBRLibDLLNameSN = "ZBRLib3205"
	Function CreateReminderHelper(ByRef cn,cfgId,subCfgId)
		Dim remind
		Set remind = New Reminder
		Set remind.cn = cn
		Call remind.init(cfgId,subCfgId)
		Set CreateReminderHelper = remind
	end function
	Function CreateReminderHelperByRs(ByRef cn,ByRef rs)
		Dim remind
		Set remind = New Reminder
		Set remind.cn = cn
		Call remind.initByRs(rs)
		Set CreateReminderHelperByRs = remind
	end function
	Dim Global_Power
	Sub InitGlobalPower(ByRef cn)
		Dim sql,rs
		sql = "select a.sort1,a.sort2,isnull(b.qx_open,0) qx_open," &_
		"(case when b.qx_intro is null or datalength(b.qx_intro)=0 then '-255' else b.qx_intro end) qx_intro," &_
		"isnull(a.sort,1) qx_type, " &_
		"from qxlblist a  with(nolock) " &_
		"left join power b  with(nolock) on b.sort1=a.sort1 and b.sort2=a.sort2 and b.ord=" & session("personzbintel2007")
		Set rs = cn.execute(sql)
		If rs.eof = False Then
			Global_Power = rs.getRows()
		end if
		rs.close
		Set rs=Nothing
	end sub
	Class Reminder
		Public cn
		Private configId
		Private base64
		Private power
		Private regEx
		Private uid
		Private actDate
		Private m_subCfgId
		Private m_name
		Private m_setjmId
		Private m_mCondition
		Private m_remindMode
		Private m_qxlb
		Private m_listqx
		Private m_detailqx
		Private m_detailOpen
		Private m_detailIntro
		Private m_moreLinkUrl
		Private m_detailLinkUrl
		Private m_moreLinkUrl_mobile
		Private m_detailLinkUrl_mobile
		Private m_hasModule
		Private m_canCancel
		Private m_jointly
		Private m_num1
		Private m_opened
		Private m_gate1
		Private m_tq1
		Private m_fw1
		Private m_canShow
		Private m_remindCount
		Private m_titleMaxLength
		Private m_subSql
		Private m_lastReloadDate
		Private m_MOrderSetting
		Private m_MBusinessType
		Private m_canTQ
		Private m_fwSetting
		Private m_isMobileMode
		Private m_colCount
		Public displaySqlOnCount
		Public displaySqlOnShow
		Public isCleanMode
		Public dateBegin
		Public pageSize
		Public pageIndex
		Public showStatusField
		Private recCount
		Private pageCount
		Private m_existsPowerIntro
		Private m_expiCount
		Private m_UsingPowerCache
		Private m_cacheHelper
		Private m_cacheExpiredCondition
		Private m_usingLv2Cache
		Private m_hasAltField
		Private Function hasAltField(rs)
			If isEmpty(m_hasAltField) Then
				m_hasAltField = hasFieldInRs(rs,"canCancelAlt")
			end if
			hasAltField = m_hasAltField
		end function
		Public Sub setMobileMode
			m_isMobileMode = True
		end sub
		Public Property Get canCancel
		canCancel = m_canCancel
		End Property
		Public Property Get colCount
		colCount = iif(m_isMobileMode,m_colCount,-1)
'Public Property Get colCount
		End Property
		Public Property Get mobileDetailLinkUrl
		mobileDetailLinkUrl = m_detailLinkUrl_mobile
		End Property
		Private m_hasStatField
		Private Function hasStatField(rs)
			If isEmpty(m_hasStatField) Then
				m_hasStatField = hasFieldInRs(rs,"orderStat")
			end if
			hasStatField = m_hasStatField
		end function
		Private m_hasInfoField
		Private Function hasInfoField(rs)
			If isEmpty(m_hasInfoField) Then
				m_hasInfoField = hasInfoField = hasFieldInRs(rs,"otherInfo")
			end if
			hasInfoField = m_hasInfoField
		end function
		Public Property Get numDigit
		numDigit = cn.execute("select num1 from setjm3  with(nolock) where ord=88")(0)
		End Property
		Public Property Get moneyDigit
		moneyDigit = cn.execute("select num1 from setjm3  with(nolock) where ord=1")(0)
		End Property
		Public Property Get hlDigit
		hlDigit = cn.execute("select num1 from setjm3 with(nolock)  where ord=87")(0)
		End Property
		Public Property Get zkDigit
		zkDigit = cn.execute("select num1 from setjm3  with(nolock) where ord=2014053101")(0)
		End Property
		Public Property Get usingLv2Cache
		usingLv2Cache = m_usingLv2Cache
		End Property
		Public Property Let usingLv2Cache(v)
		m_usingLv2Cache = v
		End Property
		Public Property Get subSql
		subSql = m_subSql
		End Property
		Public Property Get lastReloadDate
		lastReloadDate = m_lastReloadDate
		End Property
		Public Property Get subConfigId
		subConfigId = m_subCfgId
		End Property
		Public Property Get moreLink
		moreLink = moreLinkURL()
		End Property
		Public Property Get num1
		num1 = m_num1
		End Property
		Public Property Let num1(v)
		m_num1 = v
		End Property
		Public Property Get gate1
		gate1 = m_gate1
		End Property
		Public Property Get name
		name = m_name
		End Property
		Public Property Get fw1
		fw1 = m_fw1
		End Property
		Public Property Get tq1
		tq1 = m_tq1
		End Property
		Public Property Get canTQ
		canTQ = m_canTQ
		End Property
		Public Property Get fwSetting
		fwSetting = m_fwSetting
		End Property
		Public Property Get setjmId
		setjmId = m_setjmId
		End Property
		Public Property Get canShow
		If isEmpty(m_canShow) Then
			If m_opened = False And isCleanMode <> True Then
				m_canShow = False
			else
				m_canShow = m_hasModule
			end if
		end if
		canShow = m_canShow
		End Property
		Public Property Get isOpened
		isOpened = m_opened
		End Property
		Public Property Get hasModule
		hasModule = m_hasModule
		End Property
		Private Sub class_initialize
			Set base64 = server.createobject(ZBRLibDLLNameSN &".Base64Class")
			Set power = server.createobject(ZBRLibDLLNameSN &".PowerClass")
			power.PowerCache = True
			uid = session("personzbintel2007")
			If uid = "" Then uid = 0
			actDate = session("timezbintel2007")
			If actDate = "" Then actDate = now
			session("timezbintel2007") = actDate
			Set regEx =New RegExp
			regEx.Pattern = "<[^>]+>"
			Set regEx =New RegExp
			regEx.IgnoreCase = True
			regEx.Global = True
			m_subCfgId = 0
			m_subSql = ""
			isCleanMode = False
			dateBegin = IIf(request.querystring("__dt")="",dateadd("m",-3,date),request.querystring("__dt"))
			isCleanMode = False
			pageSize = IIf(request.querystring("__pageSize")="",10,request.querystring("__pageSize"))
			pageIndex = IIf(request.querystring("__pageIndex")="",1,request.querystring("__pageIndex"))
			pageSize = CLng(pageSize)
			pageIndex = CLng(pageIndex)
			recCount = 0
			pageCount = 0
			displaySqlOnCount = False
			displaySqlOnShow = False
			redim m_existsPowerIntro(0)
			If isEmpty(Global_Power) Then
				m_UsingPowerCache = False
			else
				m_UsingPowerCache = True
			end if
			m_usingLv2Cache = False
			showStatusField = True
			m_isMobileMode = False
		end sub
		Public Function listSQL(mode)
			dim ismobile: ismobile= instr(1,mode & "","mobileplus:",1) = 1
			Dim sql,cateCondition,tmpCondition,qOpen,qIntro,fields,orderBy
			Dim withoutCateCondition,cancelCondition,withoutCancelCondition,i,withoutOrderBy,cancelJoinTable
			mode = replace(mode & "", "mobileplus:", "")
			withoutCateCondition = instr(1,mode,"withoutCateCondition",1) > 0
			withoutCancelCondition = instr(1,mode,"withoutCancelCondition",1) > 0
			withoutOrderBy = InStr(1,mode,"withoutOrderBy",1) > 0
			dim icsql : icsql = ""
			if ismobile then
				icsql = "union select cateid, reminderId from reminderPersonsForMobPush  with(nolock) where cateid=" & uid
			end if
			mode = LCase(Split(mode,"_")(0))
			cancelJoinTable = "left join (" & vbcrlf &_
			"select cateid as isCanceled,reminderId from reminderPersons  with(nolock)  where cateid=" & uid & " " & vbcrlf & icsql & vbcrlf &_
			") __rp on __rp.reminderId=a.id " & vbcrlf
			cancelCondition = " and __rp.isCanceled is null "
			Select Case m_setjmId
			Case 1:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"p.cateid")
			sql = "select COUNT(*) REMIND_CNT from plan1 p with(nolock) "&_
			"where complete='1' and option1<>'1' and "&_
			"(startdate1<'" & dateadd("d",m_tq1,date) & "' or "&_
			"(startdate1='" & dateadd("d",m_tq1,date) & "' and "&_
			"(starttime1<'"&hour(time)&"' or starttime1='"&hour(time)&"'and starttime2<'"&minute(time)&"')"&_
			")"&_
			") [CATECONDITION] [ORDERBY]"
			fields = "ord [id],intro title,case when startdate1 is null then convert(varchar(10),date1,21) + ' ' + time1 + ':' + time2 "&_
			"else convert(varchar(10),startdate1,21) + ' ' + starttime1 + ':" &_
			"datediff(s,'&actDate&"
			orderBy = "order by startdate1 desc,date8 desc "
			Case 2:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " and charindex(',"&uid&",',','+alt+',')<=0 "
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) "&_
			" [CANCELJOINTABLE] " & _
			"inner join learntz b on a.orderId=b.ord and b.del=1 " &_
			" where a.reminderConfig=" & configId & " [CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "isnull(b.ord,0) [id],isnull(b.title,'【已删除数据】') title,isnull(convert(varchar(19),b.date7,21),'----') dt,"&_
			"datediff(s,' & actDate & ',isnull(b.date7,'2000-01-01"
'where a.reminderConfig= & configId &  [CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by a.id desc"
			Case 4:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.ecateid")
			cateCondition = cateCondition & " and datediff(d,getdate(),b.stime) <= " & m_tq1
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) "&_
			" [CANCELJOINTABLE] " & _
			"inner join importantMsg b on a.orderId=b.id and b.del=1 AND b.metype = "& m_subCfgId &" " &_
			"left join tel c on b.t_ord=c.ord " & vbcrlf &_
			" where c.del=1 and b.state<>2 and a.reminderConfig=" & configId & " [CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],isnull(c.name,'【已删除数据】') title,isnull(convert(varchar(19),b.stime,21),'----') dt,"&_
			" where c.del=1 and b.state<>2 and a.reminderConfig=" & configId & " [CATECONDITION] [CANCELCONDITION] [ORDERBY]" &_
			"case when year(b.stime)<year(getdate()) then -1 else datediff(s,'&actDate&"
'where c.del=1 and b.state<>2 and a.reminderConfig= & configId &  [CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by b.stime desc"
			Case 7:
			Dim nowDays : nowDays = datediff("d",CDate(year(date)&"-01-01"),date)
'Case 7:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			if m_fw1&""="0" then
				if qOpen=3 then
					cateCondition=""
				elseif qOpen=1 then
					cateCondition=cateCondition & " and (tl.cateid in ("&qIntro&") "&_
					"or tl.share='1' "&_
					"or charindex(',"&uid&",',','+tl.share+',')>0) "
'or tl.share='1
				else
					cateCondition=cateCondition & " and (tl.share='1' or charindex(',"&uid&",',','+tl.share+',')>0) "
'or tl.share='1
				end if
			else
				cateCondition=cateCondition & " and tl.cateid="&uid&" or (tl.share='1' or charindex(',"&uid&",',','+tl.share+',')>0) "
'or tl.share='1
			end if
			cateCondition=cateCondition & " and bDays - "&nowDays&" >=0 and bDays - "&nowDays&" <= " & m_tq1 & " " & vbcrlf
'or tl.share='1
			sql = """" & vbcrlf &_
			"select COUNT(*) REMIND_CNT " & vbcrlf &_
			"from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join person p  with(nolock) on a.reminderConfig = 7 and a.orderId=p.ord and p.del=1 and p.sort3=1 and p.bDays >= 0 " & vbcrlf &_
			"left join tel tl on tl.ord = p.company " & vbcrlf &_
			"where 1=1 [CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "p.ord [id]," & _
			"case when bDays - "&nowDays&" = 0 then p.name+CHAR(11)+CHAR(12)+'今日生日'" & _
			"else p.name+CHAR(11)+CHAR(12)+'还差'+cast(bDays - &nowDays& as varchar)+'天" &_
			"end as title," & _
			"convert(varchar(10),dateadd(d,p.bDays,'"&year(date)&"-01-01'),121)+'@'+cast(p.birthdayType as varchar) dt," & _
			"-1 as newTag,a.id [rid],tl.cateid "
			orderBy = "order by p.bDays asc"""
			Case 9:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"d.cateid")
			cateCondition = cateCondition & " and datediff(d,getdate(),c.date2)<=" & m_tq1
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join caigoulist c  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = c.id and c.del=1 " & vbcrlf &_
			"inner join caigou d  with(nolock) on d.ord=c.caigou " & vbcrlf &_
			"inner join product b  with(nolock) on b.ord=c.ord " & vbcrlf &_
			"where d.del=1 and isnull(d.status,-1) IN (-1,1) and c.alt=1 [CATECONDITION] [CANCELCONDITION] [ORDERBY]"
'inner join product b  with(nolock) on b.ord=c.ord  & vbcrlf &_
			fields = "c.id [id],d.title+'['+b.title+']' title,convert(varchar(10),c.date2,23) dt,datediff(s,'""&actDate&""',a.inDate) newTag,a.id [rid],c.cateid"""
'inner join product b  with(nolock) on b.ord=c.ord  & vbcrlf &_
			orderBy = "order by c.date2 desc,c.date7 desc"""
			Case 11:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"c.cateid")
			cateCondition = cateCondition & " and datediff(d,getdate(),c.date1)<=" & m_tq1
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join payback c  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = c.ord and c.del=1 and c.complete='1' " & vbcrlf &_
			"left join contract ct  with(nolock) on ct.ord=c.contract " & vbcrlf &_
			"left join sortbz bz  with(nolock) on bz.id=ct.bz " & vbcrlf &_
			"where 1=1 [CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "c.ord [id],'@code:""'+isnull(bz.intro,'RMB')+' "" & FormatNumber('+CAST(c.money1 AS VARCHAR)+'," & moneyDigit & ",-1,0,-1)' title,convert(varchar(10),c.date1,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],c.cateid"
'where 1=1 [CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by c.date1 desc,c.date7 desc"
			Case 12:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"c.cateid")
			cateCondition = cateCondition & " and datediff(d,getdate(),c.date1)<=" & m_tq1
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join payout c  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = c.ord and c.del=1 and c.complete='1' " & vbcrlf &_
			"left join (select ord,bz,0 cls from caigou union all select ID as ord,14 bz, 2 cls from M_OutOrder union all select ID as ord,bz, (case isnull(wwType,0) when 0 then 5 when 1 then 4 else 2 end) cls from M2_OutOrder  with(nolock) ) ct on ct.ord=c.contract and ct.cls=isnull(c.cls,0) " & vbcrlf &_
			"left join sortbz bz on bz.id=ct.bz " & vbcrlf &_
			"where 1=1 [CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "c.ord [id],'@code:""'+isnull(bz.intro,'RMB')+' "" & FormatNumber('+CAST(c.money1 AS VARCHAR)+'," & moneyDigit & ",-1,0,-1)' title,convert(varchar(10),c.date1,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],c.cateid"
'where 1=1 [CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by c.date1 desc,c.date7 desc"
			Case 21:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If m_fw1&""="0" Then
				If qOpen = 3 Then
					cateCondition = ""
				ElseIf qOpen=1 Then
					cateCondition = " and cateid is not null and cateid<>0 and cateid in ("&qIntro&") "
					tmpCondition = " and (cateid is not null and cateid<>0)"
				else
					cateCondition = " and 1=2"
				end if
			else
				cateCondition = " and cateid=" & uid
			end if
			cateCondition = " and ("&_
			"(1=1"&cateCondition&") or charindex(',"&uid&",',','+replace(cast(share as varchar(8000)),' ','')+',')>0 or share='1'"&_
			"cateCondition = "" and ("""&_
			") " & tmpCondition & vbcrlf
			cateCondition = cateCondition & " and datediff(d,getdate(),b.date2)<=" & m_tq1
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join contract b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 and isnull(b.status,-1) in (-1,1)  " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title,convert(varchar(10),b.date2,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = "order by b.date2 desc,b.date7 desc"
			Case 22:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				tmpCondition = ""
			ElseIf qOpen=1 Then
				tmpCondition = " and addcate in ("&qIntro&") "
			else
				tmpCondition = " and 1=2"
			end if
			If m_fw1&""="0" Then
				cateCondition = tmpCondition & " and isnull(catelead,0) > 0 "
			else
				cateCondition = tmpCondition & " and catelead=" & uid
			end if
			sql="select COUNT(*) REMIND_CNT from tousu  with(nolock) where del=1 [CATECONDITION] and result1=0 [ORDERBY]"
			fields = "ord [id],title,date1 dt,datediff(s,'" & actDate & "',isnull(date7,'2000-01-01')) newTag,0 [rid],addcate cateid"
			sql="select COUNT(*) REMIND_CNT from tousu  with(nolock) where del=1 [CATECONDITION] and result1=0 [ORDERBY]"
			orderBy = "order by date1 desc,date7 desc"
			Case 23:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " and datediff(d,getdate(),c.date2)<=" & m_tq1
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join contractlist c  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = c.id and c.del=1 " & vbcrlf &_
			"inner join contract b  with(nolock) on b.ord=c.contract and b.del=1 and isnull(b.status,-1) in (-1,1)  " & vbcrlf &_
			"left join product p  with(nolock) on p.ord=c.ord and p.del=1 " & vbcrlf &_
			"where 1=1 [CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "c.id [id],b.title+'['+isnull(p.title,'产品被删除')+']' title,convert(varchar(10),c.date2,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
'where 1=1 [CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by c.date2 desc,c.date7 desc"
			Case 39:
			cateCondition = "and learnhd.cateid="&uid
			sql="SELECT COUNT(*) REMIND_CNT FROM replyhd  with(nolock) "&_
			"LEFT JOIN learnhd  with(nolock) ON replyhd.ord = learnhd.ord "&_
			"where learnhd.del=1 and replyhd.alt=1 [CATECONDITION] [ORDERBY]"
			fields = "replyhd.id as [id],learnhd.title as title,replyhd.date7 as dt,-1 newTag,0 [rid],learnhd.cateid as cateid,learnhd.ord as ord"
'where learnhd.del=1 and replyhd.alt=1 [CATECONDITION] [ORDERBY]
			orderBy = "order by replyhd.date7 desc"
			Case 68:
			cateCondition = "and CHARINDEX(',"&uid&",',','+c.RemindPerson+',')>0 " & vbcrlf &_
			"AND daysFromNow <=  & (m_tq1 * 24)"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join ku b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id " & vbcrlf &_
			"inner join product c  with(nolock) on c.ord=b.ord " & vbcrlf &_
			"inner join sortck ck  with(nolock) on b.ck=ck.ord and ck.del=1 " &_
			"IIf(withoutCateCondition,"""",""and (cast(ck.intro as varchar(10))='0' "&_
			"or CHARINDEX(',&uid&,',','+cast(ck.intro as varchar(4000))+'," &_
			"IIf(withoutCateCondition,"""",""and (cast(ck.intro as varchar(10))='0' "&_
			"where isnull(b.locked,0)=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],c.title,"&_
			"CONVERT(varchar(10),dateadd(hh,a.daysFromNow,'"&date&"'),23) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],0 cateid"
			orderBy = "ORDER BY dt DESC,id DESC"
			Case 74:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and creator in ("&qIntro&") "
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = cateCondition & " AND cateid=" & uid
			sql="SELECT COUNT(*) REMIND_CNT FROM sale_proposal  with(nolock) WHERE ISNULL(alt,0) = 0 AND del = 0 [CATECONDITION] [ORDERBY]"
			fields = "[id],title,ServerTime dt,datediff(s,'" & actDate & "',isnull(ServerTime,'2000-01-01')) newTag,0 [rid],ISNULL(creator,0) cateid"
			orderBy = "ORDER BY ServerTime DESC,id DESC"
			Case 73:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and cateid in ("&qIntro&") "
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = cateCondition &  "AND NextOperator=" & uid &" "& cateCondition
			sql="SELECT COUNT(*) REMIND_CNT FROM sale_Complaints  with(nolock) WHERE del=0 and ISNULL(alt,0) = 0 [CATECONDITION] [ORDERBY]"
			fields = "[id],title,ServerTime dt,datediff(s,'" & actDate & "',isnull(ServerTime,'2000-01-01')) newTag,0 [rid],ISNULL(cateid,0) cateid"
			orderBy = "ORDER BY ServerTime DESC,id DESC"
			Case 72:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and cateid in ("&qIntro&") "
			else
				cateCondition = " and 1=2"
			end if
			sql="SELECT COUNT(*) REMIND_CNT FROM Sale_CallBack  with(nolock) where Del=1 and cateid=" & uid &_
			" and dbo.dateDiffByDay(ybackTime,2,0,"& m_tq1 &",GETDATE())>=0 and isback=0 and isnull(setalt,0)=0 "& cateCondition & " [ORDERBY]"
			fields = "[id],title,CONVERT(varchar, ybackTime,20) dt,-1 newTag,0 [rid],cateid"
			orderBy = "ORDER BY ServerTime DESC,id DESC"
			Case 100:
			sql = "select COUNT(*) REMIND_CNT from notebook with(nolock)  "&_
			"where (del=1 or del is null) and alt=0 and complete<>2 and cateid =" & uid &_
			"and datediff(d,getdate(),date7) <= " & m_tq1 & " [ORDERBY]"
			fields = "ord [id],'@code:htmldecode(rs(""real_title""))' title,convert(varchar,date7,120) dt,-1 newTag,0 [rid],cateid,cast(intro as varchar(8000)) real_title" &_
			"and datediff(d,getdate(),date7) <= " & m_tq1 & " [ORDERBY]"
			orderBy = "order by date7 desc"
			Case 101:
			sql = "    select COUNT(*) REMIND_CNT "&_
			"from learn  with(nolock) where (cateid=" & uid & " or CHARINDEX('," & uid & ",' , ','+share+',') > 0 or share = '1') " &_
			"and CHARINDEX(',&uid&,',','+alt+',"
			fields = "[id],title,convert(varchar,date7,120) dt,-1 newTag,0 [rid],cateid"
'sql = "    select COUNT(*) REMIND_CNT "&_
			orderBy = "order by date7 desc"
			Case 102:
			cateCondition = getCondition(m_qxlb,m_listqx,"a.AddUser")
			sql= "SELECT COUNT(*) REMIND_CNT " & vbcrlf &_
			"FROM RepairOrder a  with(nolock) left join ( " &_
			"select id,title from Comm_ProcessSet  with(nolock) where type=1 " &_
			") b on b.id = a.ProcessID  where a.id in( "& vbcrlf &_
			"select a.id FROM RepairOrder a  with(nolock) " & vbcrlf &_
			"left join ( " & vbcrlf &_
			"select id,title from Comm_ProcessSet  with(nolock) where type=1 " & vbcrlf &_
			") b on b.id = a.ProcessID " & vbcrlf &_
			"left join ( " & vbcrlf &_
			"SELECT distinct a.RepairOrder,a.ProcessID,a.DealPerson,ActualBeginTime,NodeID FROM RepairDeal a  with(nolock) " & vbcrlf &_
			"LEFT JOIN Copy_ProcessNodeSet b with(nolock)  ON b.ID = a.NodeID AND b.del = 1 " & vbcrlf &_
			"WHERE a.del = 1 AND a.CurrentStatus = 0 " & vbcrlf &_
			") c on c.RepairOrder=a.id and c.ProcessID=a.ProcessID " & vbcrlf &_
			"WHERE a.del = 1 " & vbcrlf &_
			"and (a.Status = 0 or a.Status = 1) " & vbcrlf &_
			"and isnull(c.DealPerson,a.DealPerson) = " & uid &" "&_
			"and datediff(d,getdate(),isnull(c.ActualBeginTime,'1900-01-01'))<= " & m_tq1 & " " &_
			"and isnull(c.DealPerson,a.DealPerson) = " & uid &" "&_
			"cateCondition & "") [ORDERBY]"""
			fields = "a.[id],b.title+'['+a.Title+']' title,convert(varchar,a.addTime,120) dt,-1 newTag,0 [rid],a.AddUser cateid"
'cateCondition & ") [ORDERBY]"
			orderBy = "order by a.addTime desc"
			Case 103:
			cateCondition = getCondition(m_qxlb,m_listqx,"MainExecutor")
			sql = "select COUNT(*) REMIND_CNT from (" & vbcrlf &_
			"select a.id,c.title+'['+b.name+']' title,convert(varchar,BeginTimePlan,120) dt,"& vbcrlf &_
			"a.BeginTimePlan,MainExecutor from ChanceProcRunLogs a  with(nolock) " & vbcrlf &_
			"inner join chanceProcNodesBak b  with(nolock) on a.ProcNodesBak = b.id " & vbcrlf &_
			"inner join chance c  with(nolock) on c.ord=a.chance AND c.del = 1 " & vbcrlf &_
			"where " & vbcrlf & _
			"(" & vbcrlf &_
			"(a.Status=0 and MainExecutor="&uid&")" & vbcrlf &_
			" or " & vbcrlf & _
			"(" & vbcrlf & _
			"(a.Status=1 or a.Status=9) " & vbcrlf &_
			" and " & vbcrlf &_
			"(MainExecutor="&uid&" or charindex(',"&uid&",',','+a.Executors+',')>0) " & vbcrlf &_
			" and " & vbcrlf &_
			")" & vbcrlf & _
			")" & vbcrlf &_
			" and datediff(d,getdate(),BeginTimePlan)<="& m_tq1&" " & cateCondition & vbcrlf &_
			") a [ORDERBY]"
			fields = "[id],title,dt,-1 newTag,0 [rid],MainExecutor cateid"
') a [ORDERBY]
			orderBy = "order by BeginTimePlan desc"
			Case 216:
			Dim sort46Open,sort47Open,rs_setting
			Set rs_setting = cn.execute("select intro from setopen  with(nolock) where sort1=46 union all select 0")
			sort46Open = rs_setting("intro")
			rs_setting.close
			Set rs_setting = cn.execute("select intro from setopen  with(nolock) where sort1=47 union all select 0")
			sort47Open = rs_setting("intro")
			rs_setting.close
			Set rs_setting = Nothing
			Call fillinPower(1,18,qOpen,qIntro)
			qIntro = IIF(qIntro&""="","0",qIntro)
			if sort46Open<>0 and sort46Open<>"" then
				if qOpen = 1 then
					if sort46Open = 1 then
						if sort47Open = 1 then
							cateCondition = cateCondition & " and (order1<>2 and (cateadd in("& qIntro &"))) "
						elseif sort47Open = 2 then
							cateCondition = cateCondition & " and (order1<>2 and (cateidgq in("& qIntro &"))) "
						else
							cateCondition = cateCondition & " and (order1<>2 and (cateidgq in("& qIntro &") or cateadd in("& qIntro &"))) "
						end if
					elseif sort46Open=2 then
						if sort47Open=1 then
							cateCondition = cateCondition & " and (cateadd in("& qIntro &")) "
						elseif sort47Open = 2 then
							cateCondition = cateCondition & " and (cateidgq in("& qIntro &")) "
						elseif sort47Open = 3 then
							cateCondition = cateCondition & " and (cateid in("& qIntro &")) "
						else
							cateCondition = cateCondition & " and (cateidgq in("& qIntro &") or cateadd in(" & qIntro & ")) "
						end if
					end if
				ElseIf qOpen <> 3 And qOpen & "" <> "" Then
					cateCondition = cateCondition & " and 1=2 "
				end if
			end if
			Call fillinPower(1,6,qOpen,qIntro)
			tmpCondition = "" & _
			" AND (" & vbcrlf &_
			"(" & vbcrlf &_
			"order1 = 3 and (" & vbcrlf &_
			"qOpen & ""=3 or ("" & qOpen & ""=1 and charindex(','+cast(b.cateid4 as varchar)+',',',"" & qIntro & "",')>0)" & vbcrlf &_
			")" & vbcrlf &_
			") " & vbcrlf &_
			"OR (isnull(order1,0) = 0  AND cateid4 = "& uid &" )" & vbcrlf &_
			") "
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a with(nolock)  " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join tel b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & tmpCondition & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.name title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid,"&_
			"(CASE WHEN order1 <> 3 THEN 1 ELSE 0 END) canCancelAlt," & vbcrlf &_
			"(case WHEN order1 = 3 then 10 else 12 end) orderStat"
			orderBy = "order by a.inDate desc,b.ord desc"
			Case 104:
			cateCondition = " AND (charindex(',"&uid&",',','+b.share+',')>0 or share='1') "
'Case 104:
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join tel b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.name title,convert(varchar(19),b.date1,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = "order by a.inDate desc,b.ord desc"
			Case 54:
			cateCondition = " AND (CHARINDEX(',"&uid&",',','+b.share+',')>0 OR share='1') "
'Case 54:
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN chance b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(19),b.date1,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 201:
			cateCondition = " AND (CHARINDEX(',"&uid&",',','+b.share+',')>0 OR share='1') "
'Case 201:
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN contract b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(10),b.date3,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 202:
			cateCondition = " AND (CHARINDEX(',"&uid&",',','+b.share+',')>0 OR share='1') "
'Case 202:
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN tousu b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(19),b.date7,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.addcate [cateid]"
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 203:
			Dim workPosition : workPosition = cn.execute("SELECT workPosition FROM gate WHERE ord = "& uid)(0).value
			cateCondition = " AND (CHARINDEX(',"&uid&",',','+cast(b.share1 as varchar(8000))+',')>0 OR CHARINDEX(',"&uid&",',','+cast(b.share2 as varchar(8000))+',')>0 OR CHARINDEX(',"&workPosition&",',','+cast(b.postView as varchar(8000))+',')>0 OR CHARINDEX(',"&workPosition&",',','+cast(b.postDown as varchar(8000))+',')>0) "
'Dim workPosition : workPosition = cn.execute("SELECT workPosition FROM gate WHERE ord = "& uid)(0).value
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN document b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND b.del=1 AND (b.sp = 0 AND b.cateid_sp = 0)" & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title title,convert(varchar(19),b.date7,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.addcate [cateid]"
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 64:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND ((cateid_sp = "& uid &" AND sp > 0) OR (cateid_sp = 0  AND ((ISNULL(cateid,0) = 0 AND addcate = " & uid & ") or (ISNULL(cateid,0) > 0 AND cateid = " & uid & ")))) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN chance b ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND (b.del = 1 OR b.del = 3)  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid, " &_
			"(CASE WHEN (cateid_sp = 0 OR sp < 0) THEN 1 ELSE 0 END) canCancelAlt," &_
			"(case sp when -1 then 12 when 0 then 11 else 10 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 53:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateadd")
			cateCondition = cateCondition & " AND ((cateid_sp = "& uid &" AND sp > 0) OR (cateid_sp = "& uid &" AND sp=-1) OR (cateid_sp = 0  AND cateadd = "& uid &" )) "
'cateCondition = getCondition(m_qxlb,m_listqx,"b.cateadd")
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join tel b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.name title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid,"&_
			"(CASE WHEN (cateid_sp = 0 OR sp < 0) THEN 1 ELSE 0 END) canCancelAlt," &_
			"(case when sp<0 then 15 when cateid_sp = 0 then 14 else 13 end) orderStat"
			orderBy = "order by a.inDate desc,b.ord desc"
			Case 13:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND b.ord in ( SELECT mr.ord FROM dbo.price mr  with(nolock)   "&_
			"   inner join sp_ApprovalInstance c  with(nolock) on c.gate2=13001 and c.PrimaryKeyID = mr.ord and c.BillPattern in (0,1)  "&_
			"   WHERE mr.del<>2 and ((mr.status in (-1,0,1) and isnull(mr.Cateid,mr.Addcate) =" & uid &") "&_
			"   or (mr.status in (2,4,5) and charindex('," & uid &",',','+ c.SurplusApprover +',')>0))) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN price b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND (b.del = 1 OR b.del = 3) " & vbcrlf &_
			"inner join sp_ApprovalInstance c on c.gate2=13001 and c.PrimaryKeyID = b.ord and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid,"&_
			"(case when c.ApprovalFlowStatus in (-1,0,1,3) then 1 else 0 end) canCancelAlt," &_
			"(case status when 0 then 16 when 4 then 10 when 5 then 8 when 2 then 12 else 11 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 14:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND b.ord in ( SELECT mr.ord FROM dbo.contract mr  with(nolock)   "&_
			"   inner join sp_ApprovalInstance c  with(nolock) on c.gate2=11001 and c.PrimaryKeyID = mr.ord and c.BillPattern in (0,1)  "&_
			"   WHERE mr.del<>2 and ((mr.status in (-1,0,1) and case when isnull(mr.Cateid,0)>0 then mr.Cateid else mr.Addcate end =" & uid &") "&_
			"   or (mr.status in (2,4,5) and charindex('," & uid &",',','+ c.SurplusApprover +',')>0))) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN contract b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND (b.del = 1 OR b.del = 3) "&vbcrlf &_
			"inner join sp_ApprovalInstance c on c.gate2=11001 and c.PrimaryKeyID = b.ord and c.BillPattern in (0,1) " &_
			"WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid,"&_
			"(case when c.ApprovalFlowStatus in (-1,0,1,3) then 1 else 0 end) canCancelAlt," &_
			"(case status when 0 then 16 when 4 then 10 when 5 then 8 when 2 then 12 else 11 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 69:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND ((cateid_sp = "& uid &" AND sp > 0) OR (cateid_sp = 0  AND addcate = " & uid & "))  "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN contractth b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND (b.del = 1 OR b.del = 3) WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid,"&_
			"(CASE WHEN (cateid_sp = 0 OR sp < 0) THEN 1 ELSE 0 END) canCancelAlt, " &_
			"(case sp when -1 then 12 when 0 then 11 else 10 end) orderStat" &_
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 16:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.cateid="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.cateid="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN caigou b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND (b.del = 1 OR b.del = 3) "&_
			"inner join sp_ApprovalInstance c on c.gate2=73001 and c.PrimaryKeyID = b.ord and c.BillPattern in (0,1) " &_
			"WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid,"&_
			" 0 canCancelAlt,(case b.status when -1 then 17 when 0 then 16 when 1 then 11 when 2 then 12 when 3 then 9 when 4 then 10 when 5 then 8 else 10 end)  orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 60:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND ( (kg = "& uid &" AND complete1 = 1 and isnull(b.status,-1) in (-1,1)) OR (complete1 > 1  AND cateid = "& uid &" ) ) "
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN kuin b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND b.del = 1 WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid,"&_
			"(CASE WHEN (kg = 0 OR complete1 IN (2,3)) THEN 1 ELSE 0 END) canCancelAlt, " &_
			"(case isnull(status,-1) when 1 then 11 else 17 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 61001:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.cateid="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.cateid="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join kuin b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c on c.gate2=61001 and c.PrimaryKeyID = b.ord and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title,b.date7 dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.date7 desc"
			Case 62001:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.cateid="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.cateid="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join kuout b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=62001 and c.PrimaryKeyID = b.ord and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title,b.date7 dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.date7 desc"
			Case 23701:
			DIM MCYG,MCBJ
			MCYG=FALSE
			MCBJ=FALSE
			if ZBRuntime.MC(14000) then
				MCYG=TRUE
			end if
			if ZBRuntime.MC(4000) then
				MCBJ=TRUE
			end if
			sql ="select COUNT(*) REMIND_CNT from"& _
			"("& _
			"select A.id,A.cateid,1 ismode,title,date1,date7  from"& _
			"("& _
			"select "& _
			"cai.id,count(c.id) cid,count(x.id)xid,cai.date7,cai.date1,cai.title,cai.cateid "& _
			"from caigou_yg cai  with(nolock)  "& _
			"inner join caigoulist_yg c  with(nolock) on  cai.id=c.caigou "& _
			"left join xunjialist x  with(nolock) on c.id=x.caigoulist_yg and x.caigoulist_yg>0 and x.del=1 "& _
			"left join xunjia xu  with(nolock) on xu.id=x.xunjia and xu.fromtype<>0 "&_
			"left join gate g  with(nolock) on g.ord=cai.cateid  "& _
			"left join power p  with(nolock) on p.ord="&uid&" and p.sort1=25 and p.sort2=1"&_
			"                                 ""where  cai.del=1 and cai.status=0  AND '""&MCYG&""'='TRUE'   and ISNULL(cai.xunjia,0)=0 and needxj=1 and (p.qx_open=3 or  CHARINDEX(','+CAST(cai.cateid AS VARCHAR(20))+',',','+CAST(p.qx_intro AS VARCHAR(8000))+',') > 0) GROUP BY cai.id,cai.date7,cai.date1,cai.title,g.name,cai.cateid,cai.ygid " & _
			")A WHERE (A.cid>0 AND xid=0) or(A.cid>0 And xid>0 And xid<A.cid)  "& _
			"union all  "& _
			"select p.ord,p.cateid cateid,0 ismode,p.title,p.date1,p.date7 from price p  with(nolock) "& _
			"left join gate gg  with(nolock) on gg.ord=p.addcate "& _
			" left join power po  with(nolock) on po.ord="&uid&" and po.sort1=4 and po.sort2=1"&_
			"where (p.complete=1 or p.complete=8) and p.del=1 AND '"&MCBJ&"'='TRUE' and p.xj=1 and  exists(select 1 from pricelist  with(nolock) where price =p.ord AND xunjiastatus!=1)"&_
			"AND NOT exists(select 1 from xunjialist a  with(nolock)  "&_
			"inner join xunjia b  with(nolock) on a.xunjia=b.id and b.del=1 "&_
			"INNER join tel c on a.gys=c.ord and c.sort3=2 "&_
			"where b.price=p.ord)"&_
			" and (po.qx_open=3 or CHARINDEX(','+CAST(p.cateid AS VARCHAR(20))+',',','+CAST(po.qx_intro AS VARCHAR(8000))+',') > 0)"& _
			"where b.price=p.ord)"&_
			")C left join power pow on pow.ord= "&uid&"  and pow.sort1=24 and pow.sort2=13    WHERE (pow.qx_open=3 or CHARINDEX(','+CAST(C.cateid AS VARCHAR(20))+',',','+CAST(pow.qx_intro AS VARCHAR(8000))+',') > 0) AND 1=1"& _
			"where b.price=p.ord)"&_
			"[ORDERBY]"
			fields = "C.id [id],(case when C.ismode=1 THEN '来自预购:'+ C.title else '来自报价:'+ C.title end) title,0 [rid],C.cateid,-1 newTag, CAST(CONVERT(varchar(10), C.date1 , 120)as datetime)  dt"
'[ORDERBY]
			orderBy = "ORDER BY C.date7 DESC"
			Case 61:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND ( (kg = "& uid &" AND complete1 = 1 and isnull(b.status,-1) in (-1,1)) ) "
'cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN kuout b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND b.del = 1 WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid,"&_
			"(CASE WHEN (kg = 0 OR complete1 IN (2,3)) THEN 1 ELSE 0 END) canCancelAlt, " &_
			"(case isnull(status,-1) when 1 then 11 else 17 end) orderStat"
'(CASE WHEN (kg = 0 OR complete1 IN (2,3)) THEN 1 ELSE 0 END) canCancelAlt,  &_
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 62:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND ( ("& iif(openPower(33,16) > 0,"1=1","1=2") &" AND complete1 = 0) OR (complete1 = 1  AND cateid = "& uid &" ) ) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN send b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND (b.del = 1 OR b.del = 3) WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid,"&_
			"(CASE WHEN (addcate = 0 OR complete1 = 1) THEN 1 ELSE 0 END) canCancelAlt," &_
			"(case complete1 when 0 then 10 when 1 then 11 else 10 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 50:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.Creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN payoutsure b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ID AND b.del = 1  " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=44011 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.ID DESC"
			Case 43012:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.Creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.Creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.Creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock)  " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN PaybackInvoiceSure b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ID AND b.del = 1  " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=43012 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.ID DESC"
			Case 44012:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.Creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.Creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.Creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN PayoutInvoiceSure b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ID AND b.del = 1  " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=44012 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.ID DESC"
			Case 65:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.cateid="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.cateid="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN bankin2 b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND (b.del = 1 OR b.del = 3) " & vbcrlf &_
			" inner join sp_ApprovalInstance c on c.gate2=43001 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			" WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],cast(b.title as varchar(8000)) title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid,"&_
			"(CASE WHEN (cateid_sp = 0 OR sp < 0) THEN 1 ELSE 0 END) canCancelAlt," &_
			"(case status_sp when 2 then 12 when 1 then 11 else 10 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 206:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN bankout2 b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND (b.del = 1 OR b.del = 3) " & vbcrlf &_
			" inner join sp_ApprovalInstance c  with(nolock) on c.gate2=44001 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			" WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],cast(b.title as varchar(8000)) title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator as cateid,"&_
			"(CASE WHEN (ISNULL(cateid_sp,0) = 0 OR ISNULL(sp,0) < 0) THEN 1 ELSE 0 END) canCancelAlt," &_
			"(case status_sp when 2 then 12 when 1 then 11 else 10 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 205:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.addcate")
			cateCondition = cateCondition & " AND ((cateid_sp = "& uid &" AND complete = 2) OR (complete = 3  AND addcate = "& uid &" )) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN caigouQC b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND b.del = 1 WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.addcate [cateid],"&_
			"(CASE WHEN (cateid_sp = 0 OR complete < 0 OR complete = 3) THEN 1 ELSE 0 END) canCancelAlt, " &_
			"(case complete when -1 then 12 when 3 then 11 else 10 end) orderStat"
'(CASE WHEN (cateid_sp = 0 OR complete < 0 OR complete = 3) THEN 1 ELSE 0 END) canCancelAlt,  &_
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 40:
			cateCondition = getCondition(m_qxlb,m_listqx,"addcateid")
			cateCondition = cateCondition & " AND ((cateid_sp = "& uid &" AND complete not in (1,3)) OR (complete in (1,3) AND addcateid = "& uid &" )) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN paysq b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND (b.del = 1 OR b.del = 3) WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.addcateid [cateid],"&_
			"(CASE WHEN complete in (1,3) THEN 1 ELSE 0 END) canCancelAlt," &_
			"(case complete when 3 then 12 when 1 then 11 else 10 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 41:
			cateCondition = getCondition(m_qxlb,m_listqx,"cateid")
			cateCondition = cateCondition & " AND ((cateid_sp = "& uid &" AND complete not in (2,3)) OR (complete in (2,3) AND cateid = "& uid &" )) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN paybx b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND (b.del = 1 OR b.del = 3) WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid [cateid],"&_
			"(CASE WHEN (cateid_sp = 0 OR sp_id < 0) THEN 1 ELSE 0 END) canCancelAlt," &_
			"(case complete when 2 then 12 when 3 then 11 else 10 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 42:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.sorce2")
			cateCondition = cateCondition & " AND ((isnull(gate_sp,0) = "& uid &" AND sp_id > 0) OR (isnull(sp_id,0) = 0  AND sorce2 = "& uid &" )) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN payjk b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND (b.del = 1 OR b.del = 3) WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.sorce2 [cateid],"&_
			"(CASE WHEN (isnull(gate_sp,0) = 0 OR sp_id < 0) THEN 1 ELSE 0 END) canCancelAlt," &_
			"(case sp_id when -1 then 12 when 0 then 11 else 10 end) orderStat"
'(CASE WHEN (isnull(gate_sp,0) = 0 OR sp_id < 0) THEN 1 ELSE 0 END) canCancelAlt, &_
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"""
			Case 43:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND ((cateid_sp = "& uid &" AND complete IN (7,11)) OR ((complete = 8 OR complete = 12)  AND addcate = "& uid &" )) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN pay b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND (b.del = 1 OR b.del = 3) WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid,"&_
			"(CASE WHEN (cateid_sp = 0 OR complete = 8 OR complete = 12) THEN 1 ELSE 0 END) canCancelAlt," &_
			"(case complete when 12 then 12 when 8 then 11 else 10 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 71:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_NeedPerson b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(19),b.indate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 44:
			cateCondition = getCondition(m_qxlb,m_listqx,"c.use_cateid")
			cateCondition = cateCondition &" AND d.send_cateid = "& uid &" "
			sql = "SELECT COUNT(*) REMIND_CNT FROM (" & vbcrlf &_
			"select distinct b.id [id],c.use_title title,convert(varchar(19),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,b.id [rid],c.use_cateid [cateid],a.inDate,c.id cid " & vbcrlf &_
			"from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN O_MeetingSummary b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id " & vbcrlf &_
			"INNER JOIN O_MeetingUse c  with(nolock) ON c.id = b.sum_metId " & vbcrlf &_
			"INNER JOIN O_SummarySend d  with(nolock) ON d.send_meetingid = b.id " & vbcrlf &_
			"WHERE 1 = 1 AND d.send_type = 1 AND d.send_issucceed = 1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] "&vbcrlf &_
			") bbb [ORDERBY]"
			fields = "[id],title,dt,newTag,[rid],[cateid],inDate,cid"
			orderBy = "ORDER BY inDate DESC,cid DESC"
			Case 56:
			tmpCondition = ""
			If m_fw1&""="0" Then
				tmpCondition = ""
			else
				tmpCondition = " and c.cateid=" & uid & " "
			end if
			cateCondition = "and (" & vbcrlf
			Call fillinPower(1,5,qOpen,qIntro)
			cateCondition = cateCondition & " ( c.sort1=1 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (c.cateid is not null and c.cateid<>0 and c.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(2,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( c.sort1=8 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (c.cateid is not null and c.cateid<>0 and c.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(3,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( c.sort1=2 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (c.cateid is not null and c.cateid<>0 and c.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(4,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( c.sort1=3 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (c.cateid is not null and c.cateid<>0 and c.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(5,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( c.sort1=4 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (c.cateid is not null and c.cateid<>0 and c.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(22,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( c.sort1=5 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (c.cateid is not null and c.cateid<>0 and c.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(41,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( c.sort1=6 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (c.cateid is not null and c.cateid<>0 and c.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(42,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( c.sort1=7 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (c.cateid is not null and c.cateid<>0 and c.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(75,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( c.sort1=75 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (c.cateid is not null and c.cateid<>0 and c.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(95,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( c.sort1=102001 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (c.cateid is not null and c.cateid<>0 and c.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(96,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( c.sort1=102002 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (c.cateid is not null and c.cateid<>0 and c.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			cateCondition = cateCondition & " ) "
			cateCondition = " and (( 1=1 " & tmpCondition & " " & cateCondition & ") or c.share='1' or charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(cast(c.share as varchar(8000)),' ','')+',')>0)" & vbcrlf
			cateCondition = cateCondition & " ) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN dianping b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id " &_
			"INNER JOIN reply c  with(nolock) ON c.id = b.ord " &_
			"LEFT JOIN tel d  with(nolock) ON d.ord = c.ord " &_
			"WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.intro title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],0 [cateid]"
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 57:
			cateCondition = " AND isnull(order1,0) = "& uid &" "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN plan1 b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord WHERE b.complete='2' " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.intro title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],0 [cateid]"
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 58:
			cateCondition = " AND isnull(cateid,0) = "& uid &" "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN plan2 b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ord AND b.type IN (17,12,13,14,15,16) WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],cast(b.intro as varchar(8000)) title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],0 [cateid]"
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 18:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN payback b  with(nolock) ON a.reminderConfig=" & configId & " AND (a.orderId = -b.ord or a.orderId = b.ord) AND b.del = 1 AND complete = '3' WHERE 1 = 1 " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],'@code:FormatNumber('+CAST(b.money1 AS VARCHAR)+'," & moneyDigit & ",-1,0,-1)' title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "ORDER BY a.inDate DESC,b.ord DESC"
			Case 207:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.ret_addcateid")
			cateCondition = cateCondition & " AND ((ret_bcateid = "& uid &" AND ret_state = 1 ) OR (ret_state > 1 AND Exit Sub_addcateid = "& uid &" )) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN O_proReturn b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND b.ret_del = 1 WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.ret_title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.ret_addcateid [cateid],"&_
			"(CASE WHEN (ret_bcateid = 0 OR ret_state > 1) THEN 1 ELSE 0 END) canCancelAlt, " &_
			"(case ret_state when 3 then 12 when 2 then 11 else 10 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 208:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.get_addcateid")
			cateCondition = cateCondition & " AND ((get_storecateid = "& uid &" AND get_store = 2 ) OR (get_store <> 2 AND get_addcateid = "& uid &" )) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN O_productOut b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND b.get_del = 1 WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.get_title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.get_addcateid [cateid],"&_
			"(CASE WHEN (get_storecateid = 0 OR get_store <> 2) THEN 1 ELSE 0 END) canCancelAlt, " &_
			"(case get_store when 3 then 12 when 1 then 11 else 10 end) orderStat"
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 8:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			cateCondition = " and ((1=1" & cateCondition & ") or CHARINDEX(',"&uid&",',','+b.share+',')>0 OR share='0') "
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) "&_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN learnhd b  with(nolock) on a.orderId = b.ord AND b.del = 1 " &_
			" WHERE a.reminderConfig=" & configId & " [CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "ISNULL(b.ord,0) [id],isnull(b.title,'【已删除数据】') title,isnull(convert(varchar(19),b.date7,21),'----') dt,"&_
			"DATEDIFF(s,' & actDate & "
			orderBy = "ORDER BY a.id DESC"
			Case 209:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.creator")
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN payoutsure b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.ID AND b.del = 1  " & vbcrlf &_
			"left join sortbz d  with(nolock) on d.id=b.bz " & vbcrlf &_
			"WHERE 1 = 1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ID [id],  '@code:""'+b.title+'('+isnull(d.intro,'RMB')+' "" & FormatNumber('+CAST(b.money1 AS VARCHAR)+'," & moneyDigit & ",-1,0,-1)&""'+')'+'""' title,"&_
			"convert(varchar(19),a.inDate,21) dt,datediff(s,'&actDate&"
			orderBy = "ORDER BY a.inDate DESC,b.ID DESC"
			Case 210:
			cateCondition = " AND ((b.khzt <> 1 AND EXISTS (SELECT 1 FROM hr_perform_sp_list  with(nolock) WHERE sortID = b.sortid AND sp_id = "& uid &")) OR (b.khzt = 1 AND (CAST(b.user_list AS VARCHAR) = '0' OR CHARINDEX(',"& uid &",' , ','+ CAST(b.user_list AS VARCHAR) +',') > 0)) )"
'Case 210:
			cateCondition = cateCondition & " AND DATEDIFF(d,sp_Time1,GETDATE()) >= 0 AND DATEDIFF(d,sp_Time2,GETDATE()) <= 0 "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN hr_perform_sort b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND b.del = 0 WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator [cateid]"
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 211:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN paybackInvoice b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND b.del = 1 " & vbcrlf &_
			"left join sortbz c  with(nolock) on c.id=b.bz " & vbcrlf &_
			"WHERE 1 = 1 AND b.isInvoiced <> 3  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],'@code:""'+isnull(c.intro,'RMB')+' "" & FormatNumber('+CAST(b.money1 AS VARCHAR)+'," & moneyDigit & ",-1,0,-1)' title,convert(varchar(10),b.invoiceDate,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 212:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN payoutInvoice b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND b.del = 1 " & vbcrlf &_
			"WHERE 1 = 1 AND b.del = 1 AND b.isInvoiced in (1,2) " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.[id],'@code:FormatNumber('+CAST(b.money1 AS VARCHAR)+'," & moneyDigit & ",-1,0,-1)' title,convert(varchar(19),b.invoiceDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid "
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 10:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"c.cateid")
			cateCondition = cateCondition & " AND datediff(d,getdate(),b.date2)<=" & m_tq1
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN kujhlist b  with(nolock) on a.reminderConfig="&configId&" and a.orderId=b.id and b.del=1 " & vbcrlf &_
			"inner Join kujh c  with(nolock) on b.kujh=c.ord and c.del=1 " & vbcrlf &_
			"inner join product d on d.ord=b.ord " & vbcrlf &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],c.title+'('+d.title+')' title,CONVERT(VARCHAR(10),b.date2,23) dt,DATEDIFF(s,'"&actDate&"',a.inDate) newTag,a.id [rid],c.cateid [cateid]"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by b.date2 DESC,b.date7 DESC"
			Case 20:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			storelist_sort5 = "0"
			Set rsUsConfig= conn.execute("select isnull(tvalue,'0') tvalue from home_usConfig where name='storelist_sort5' and isnull(uid, 0) =" &  session("personzbintel2007") )
			If rsUsConfig.eof= False Then
				storelist_sort5=rsUsConfig("tvalue")
			end if
			rsUsConfig.close
			showKuLimitZeroSQL = ""
			if storelist_sort5 = "0" then
				showKuLimitZeroSQL = " and (isnull(b.alert1,0)>0 or isnull(b.alert2,0)>0)"
			end if
			showzore =0
			Set rsUsConfig= conn.execute("select (case cast(tvalue as varchar(10)) when '1' then 1 else 0 end) v from home_usConfig  with(nolock) where uid="& session("personzbintel2007") &" and name='storelist_sort1' ")
			if rsUsConfig.eof=false  then
				showzore = rsUsConfig("v").value
			end if
			rsUsConfig.close
			unkuinwarning = 0
			if showzore="1" then
				Set rsUsConfig= conn.execute("select (case cast(tvalue as varchar(10)) when '1' then 1 else 0 end) v from home_usConfig  with(nolock) where uid="& session("personzbintel2007") &" and name='storelist_warning' ")
				if rsUsConfig.eof=false  then
					unkuinwarning = rsUsConfig("v").value
				end if
				rsUsConfig.close
			end if
			showZeroSQL = ""
			if showzore = "0" then
				showZeroSQL = " and isnull(b.ku_num,0)>0 "
			else
				if unkuinwarning="0" then
					showZeroSQL = " and exists(select 1 from ku where ord =a.ord) "
				end if
			end if
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen = 1 Then
				cateCondition = " and charindex(','+cast(b.addcate as varchar)+',',',"&qIntro&",')>0 "
'ElseIf qOpen = 1 Then
			else
				cateCondition = " and 1=2 "
			end if
			If withoutCateCondition Then
				tmpCondition = ""
			else
				tmpCondition = "inner join sortck subc on subc.id = suba.ck "& vbcrlf &_
				"and subc.del=1 "& vbcrlf &_
				"and ("& vbcrlf &_
				"charindex('," & uid & ",',','+replace(cast(subc.intro as varchar(4000)),' ','')+',')>0 "& vbcrlf &_
				"and ("& vbcrlf &_
				"or replace(cast(subc.intro as varchar(4000)),' ','') = '0'"& vbcrlf &_
				")"
			end if
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN ("&vbcrlf & _
			"SELECT a.ord,addcate,title," & vbcrlf & _
			"(CASE WHEN Isnull(aleat1, 0) = 0 THEN 0 ELSE Isnull(aleat1,0) END) AS alert1, " & vbcrlf & _
			"(CASE WHEN Isnull(aleat2, 0) = 0 THEN 0 ELSE Isnull(aleat2,0) END) AS alert2, " & vbcrlf & _
			"date7,Isnull(ku_num, 0) ku_num " & vbcrlf & _
			"FROM product a " & vbcrlf & _
			"LEFT JOIN ("&vbcrlf & _
			"SELECT ord,Sum(numjb) AS ku_num FROM ("&vbcrlf & _
			"SELECT suba.ord," & vbcrlf & _
			"(CASE WHEN suba.unit = subb.unitjb THEN num2 " & vbcrlf & _
			"ELSE num2 * Isnull((SELECT TOP 1 bl FROM jiage  with(nolock) WHERE product = suba.ord AND unit = suba.unit),0) " & vbcrlf & _
			"END) numjb " & vbcrlf & _
			"FROM ku suba  with(nolock) " & vbcrlf & _
			"INNER JOIN product subb  with(nolock) ON suba.ord = subb.ord " & vbcrlf & _
			"tmpCondition" & vbcrlf &_
			") subaa " & vbcrlf & _
			"GROUP BY ord " & vbcrlf & _
			") AS b ON a.ord = b.ord " & vbcrlf & _
			"WHERE a.del = 1 "& showZeroSQL&" AND (isnull(ku_num,0)<=aleat1 or isnull(ku_num,0)>aleat2) " & vbcrlf & _
			") AS b ON a.orderid = b.ord "& showKuLimitZeroSQL &" AND a.reminderConfig=" & configId & " " & vbcrlf & _
			"WHERE 1 = 1 " & vbcrlf & _
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title," &_
			"CASE WHEN [Ku_num]<[alert1] then '↓'+cast(dbo.formatnumber([Ku_num]," & numDigit & ",0) as nvarchar(50)) " & _
			"WHEN [Ku_num]>[alert2] then '↑" &_
			"END dt," &_
			"DATEDIFF(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.addcate [cateid]"
			orderBy = "order by title desc,date7 desc"
			Case 49:
			cateCondition = getCondition(m_qxlb,m_listqx,"c.personID")
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_person_health c  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = c.id " & vbcrlf &_
			"INNER JOIN hr_person b  with(nolock) ON b.userID = c.personID " & vbcrlf & _
			"where 1=1 AND Isnull(c.alt, 1) < 2 and b.del = 0 AND c.lastdate IS NOT NULL "&_
			"AND c.zhouqi IS NOT NULL AND b.nowstatus NOT IN (2,3,4) " & vbcrlf &_
			"and DATEDIFF(m,GETDATE(),b.contractEnd)>0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]" & vbcrlf
			fields = "c.id [id],b.username title,CONVERT(VARCHAR(10)," & _
			"(CASE c.unit " & vbcrlf & _
			"WHEN 1 THEN Dateadd(yyyy, c.zhouqi, c.lastdate) " & vbcrlf & _
			"WHEN 2 THEN Dateadd(qq, c.zhouqi, c.lastdate) " & vbcrlf & _
			"WHEN 3 THEN Dateadd(m, c.zhouqi, c.lastdate) " & vbcrlf & _
			"WHEN 4 THEN Dateadd(ww, c.zhouqi, c.lastdate) " & vbcrlf & _
			"WHEN 5 THEN Dateadd(d, c.zhouqi, c.lastdate) " & vbcrlf & _
			"ELSE NULL " & vbcrlf & _
			"END )" & vbcrlf &_
			",23) dt,DATEDIFF(s,'"&actDate&"',a.inDate) newTag,a.id [rid],c.personID [cateid]"
			orderBy = "order by dt DESC"
			Case 66:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND datediff(d,getdate(),b.date2)<=" & m_tq1 & " "
			cateCondition = cateCondition & " and charindex('," & uid &",',','+cast(isnull(b.alt,'') as varchar(4000))+',')=0"
			cateCondition = cateCondition & " AND datediff(d,getdate(),b.date2)<=" & m_tq1 & " "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN " & vbcrlf & _
			"(" & vbcrlf &_
			"SELECT z.id,t.name,t.cateid,s.title,z.date2,cast(isnull(z.alt,'') as varchar(4000)) alt,t.share " & vbcrlf & _
			"FROM tel t  with(nolock) " & vbcrlf & _
			"INNER JOIN sortFieldsContent z  with(nolock) " & vbcrlf & _
			"ON z.ord = t.ord " & vbcrlf & _
			"AND z.del = 1 " & vbcrlf & _
			"AND t.del = 1 " & vbcrlf & _
			"AND z.sort = 1 " & vbcrlf & _
			"AND t.sort3 = 2 " & vbcrlf & _
			"AND t.isNeedQuali = 1 " & vbcrlf & _
			"AND ISNULL(t.status_sp_qualifications, 0) = 0 " & vbcrlf & _
			"AND LEN(z.date2) > 0 " & vbcrlf & _
			"AND LEN(CAST(z.share AS VARCHAR(10))) > 0 " & vbcrlf & _
			"AND CHARINDEX(',"& uid &",', ',' + CAST(z.share AS VARCHAR(4000)) + ',') > 0 " & vbcrlf & _
			"AND LEN(CAST(z.share AS VARCHAR(10))) > 0 " & vbcrlf & _
			"INNER JOIN sortClass s with(nolock)  " & vbcrlf & _
			"ON z.sortid = s.id " & vbcrlf & _
			"AND ISNULL(s.isStop, 0) = 0 " & vbcrlf & _
			"AND s.sort1 = 2 " & vbcrlf & _
			") b ON a.orderID = b.id AND a.reminderConfig=" & configId & " " & vbcrlf & _
			"WHERE 1 = 1 " & vbcrlf & _
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.name title,CONVERT(VARCHAR(10),b.date2,23) dt,DATEDIFF(s,'"&actDate&"',b.date2) newTag,a.id [rid],b.cateid [cateid]"
			orderBy = "order by b.date2 DESC"
			Case 67:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND datediff(d,getdate(),b.date2)<=" & m_tq1 & " "
			cateCondition = cateCondition & " and charindex('," & uid &",',','+cast(isnull(b.alt,'') as varchar(4000))+',')=0"
			cateCondition = cateCondition & " AND datediff(d,getdate(),b.date2)<=" & m_tq1 & " "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN " & vbcrlf & _
			"("&_
			"SELECT z.id,t.name,t.cateid,s.title,z.date2,cast(isnull(z.alt,'') as varchar(4000)) alt,t.share " & vbcrlf & _
			"FROM tel t  with(nolock) " & vbcrlf & _
			"INNER JOIN sortFieldsContent z  with(nolock) " & vbcrlf & _
			"ON z.ord = t.ord " & vbcrlf & _
			"AND z.del = 1 " & vbcrlf & _
			"AND t.del = 1 " & vbcrlf & _
			"AND z.sort = 1 " & vbcrlf & _
			"AND t.sort3 = 1 " & vbcrlf & _
			"AND t.isNeedQuali = 1 " & vbcrlf & _
			"AND ISNULL(t.status_sp_qualifications, 0) = 0 " & vbcrlf & _
			"AND LEN(z.date2) > 0 " & vbcrlf & _
			"AND LEN(CAST(z.share AS VARCHAR(10))) > 0 " & vbcrlf & _
			"AND CHARINDEX(',"& uid &",', ',' + CAST(z.share AS VARCHAR(4000)) + ',') > 0 " & vbcrlf & _
			"AND LEN(CAST(z.share AS VARCHAR(10))) > 0 " & vbcrlf & _
			"INNER JOIN sortClass s  with(nolock) " & vbcrlf & _
			"ON z.sortid = s.id " & vbcrlf & _
			"AND ISNULL(s.isStop, 0) = 0 " & vbcrlf & _
			"AND s.sort1 = 2 " & vbcrlf & _
			") b ON a.orderID = b.id AND a.reminderConfig=" & configId & " " & vbcrlf & _
			"WHERE 1 = 1 " & vbcrlf & _
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.name title,CONVERT(VARCHAR(10),b.date2,23) dt,DATEDIFF(s,'"&actDate&"',b.date2) newTag,a.id [rid],b.cateid [cateid]"
			orderBy = "ORDER BY b.date2 DESC"
			Case 213:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND a.daysFromNow<=" & m_tq1
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN " & vbcrlf & _
			"( " & vbCrLf &_
			"  SELECT a.id,a.date1,a.date7,a.cateid,ISNULL(a.money1,0) money1,b.intro bz FROM paybackinvoice a  with(nolock)  " & vbCrLf &_
			"  INNER JOIN sortbz b  with(nolock) ON b.id = a.bz " & vbCrLf &_
			"  WHERE a.del = 1 AND isInvoiced = 0  AND ISNULL(a.cateid,0) <> 0 " & vbCrLf &_
			") b ON a.orderID = b.id AND a.reminderConfig=" & configId & " " & vbCrLf &_
			"WHERE 1 = 1 " & vbcrlf & _
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],'@code:""'+isnull(b.bz,'RMG')+' "" & FormatNumber('+CAST(b.money1 AS VARCHAR)+'," & moneyDigit & ",-1,0,-1)' title,CONVERT(VARCHAR(10),b.date1,23) dt,DATEDIFF(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "ORDER BY b.date1 DESC,b.date7 DESC"
			Case 214:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND a.daysFromNow<=" & m_tq1
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN payoutInvoice b  with(nolock) ON a.orderID = b.id AND a.reminderConfig=" & configId & " " & vbCrLf &_
			"left JOIN sortbz d  with(nolock) ON d.id = b.bz " & vbCrLf &_
			"WHERE 1 = 1 AND b.del = 1 AND b.isInvoiced in (0,11) " & vbcrlf & _
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.[id],'@code:""'+isnull(d.intro,'RMB')+' "" & FormatNumber('+CAST(b.money1 AS VARCHAR)+'," & moneyDigit & ",-1,0,-1)' title,CONVERT(VARCHAR(10),b.date1,23) dt,DATEDIFF(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "ORDER BY b.date1 DESC,b.date7 DESC"
			Case 52:
			cateCondition = cateCondition & " AND daysFromNow <= " & m_tq1 * 24
			sql = "" &_
			"SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join ku k  with(nolock) on a.orderId=k.id and a.reminderConfig=" & configId &" " & vbcrlf &_
			"INNER JOIN product p  with(nolock) ON p.ord = k.ord " & vbcrlf &_
			"INNER JOIN sortck ck  with(nolock) ON k.ck = ck.ord AND ck.del = 1 " & vbcrlf &_
			"where (" & vbcrlf & _
			"CAST(ISNULL(ck.intro,'') AS VARCHAR(4000)) = '0' " & vbcrlf &_
			"OR CHARINDEX(',"&uid&",', ',' + CAST(ck.intro AS VARCHAR(4000)) + ',') > 0 " & vbcrlf &_
			"CAST(ISNULL(ck.intro,'') AS VARCHAR(4000)) = '0' " & vbcrlf &_
			") " & vbcrlf &_
			"AND p.del = 1 " & vbcrlf &_
			"AND k.num2 > 0 " & vbcrlf &_
			"AND p.RemindNum > 0 " & vbcrlf &_
			"AND CHARINDEX(',"&uid&",', ',' + ISNULL(p.RemindPerson, '') + ',') > 0 " & vbcrlf &_
			"AND p.RemindNum > 0 " & vbcrlf &_
			"AND k.dateyx IS NOT NULL " & vbcrlf &_
			"AND ISNULL(k.locked, 0) = 0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "k.id [id],p.title,CONVERT(VARCHAR(10),k.dateyx,23) dt,DATEDIFF(s,'"&actDate&"',a.inDate) newTag,a.id [rid],p.addcate [cateid]"
			orderBy = "ORDER BY k.dateyx DESC,p.date7 DESC"
			Case 51:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.addcateid")
			cateCondition = cateCondition & " AND a.daysFromNow<=" & m_tq1 & " AND b.addcateid = "& uid &" "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN " & vbcrlf & _
			"( " & vbCrLf &_
			"  SELECT a.id,d.id lid, c.bk_name, a.ld_rettime, d.addcateid " & vbcrlf &_
			"  FROM O_Lendbookmx a  with(nolock) " & vbcrlf &_
			"  LEFT JOIN O_Lendbook d  with(nolock) ON a.Ld_fid=d.id " & vbcrlf &_
			"  LEFT JOIN O_regbook c  with(nolock) ON a.Ld_bkid=c.id " & vbcrlf &_
			"  WHERE a.ld_num > (SELECT isnull(sum(Ret_num),0) AS Ret_num FROM O_RetBookmx  with(nolock) WHERE Ret_bkid=a.id) " & vbcrlf &_
			") b ON a.orderID = b.id AND a.reminderConfig=" & configId & " " & vbCrLf &_
			"WHERE 1 = 1 " & vbcrlf & _
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.lid [id],b.bk_name title,CONVERT(VARCHAR(10),b.ld_rettime,23) dt,DATEDIFF(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.addcateid [cateid]"
			orderBy = "ORDER BY b.ld_rettime DESC"
			Case 59:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.userId")
			cateCondition = cateCondition & " AND DATEDIFF(d,getdate(),b.Reguldate)<=" & m_tq1 & " "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN " & vbcrlf & _
			"( " & vbCrLf &_
			"  SELECT a.ID,a.Reguldate,a.UserId,a.userName name " & vbcrlf &_
			"  FROM hr_person a  with(nolock) " & vbcrlf &_
			"  WHERE  a.nowStatus = 5 AND a.del = 0 " & vbcrlf &_
			") b ON a.orderID = b.id AND a.reminderConfig=" & configId & " " & vbCrLf &_
			"WHERE 1 = 1 " & vbcrlf & _
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.name title,CONVERT(VARCHAR(10),b.Reguldate,23) dt,DATEDIFF(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.UserId [cateid]"
			orderBy = "ORDER BY b.Reguldate DESC"
			Case 215:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND a.daysFromNow<=" & m_tq1 & " "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN " & vbcrlf & _
			"Chance b  with(nolock) ON a.orderID = b.ord AND a.reminderConfig=" & configId & " " & vbCrLf &_
			"WHERE 1 = 1 AND b.del = 1 AND b.cateid > 0 " & vbcrlf & _
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,'距离回收' + CAST(daysFromNow AS VARCHAR) + '天' dt,DATEDIFF(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid [cateid]"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "ORDER BY b.date7 DESC"
			Case 300:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.addcate")
			cateCondition = cateCondition & " AND a.daysFromNow<=" & m_tq1 & " "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN " & vbcrlf & _
			"document b  with(nolock) ON a.orderID = b.id AND a.reminderConfig=" & configId & " " & vbCrLf &_
			"WHERE 1 = 1 AND b.del = 1  AND validity = 2 AND (b.sp = 0 AND b.cateid_sp = 0) AND b.addcate = "& uid &" " & vbcrlf & _
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title title,CONVERT(VARCHAR(10),b.date4,23) dt,DATEDIFF(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.addcate [cateid]"
			orderBy = "ORDER BY b.date7 DESC"
			Case 301:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.addcate")
			cateCondition = cateCondition & " AND a.daysFromNow<=" & m_tq1 & " "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN " & vbcrlf & _
			"documentlist b  with(nolock) ON a.orderID = b.id AND a.reminderConfig=" & configId & " " & vbCrLf &_
			"inner join document d on d.id = b.document "  & vbCrLf &_
			"WHERE 1 = 1 AND d.del = 1 and b.del=1  AND b.l_validity = 2 AND (d.sp = 0 AND d.cateid_sp = 0) AND d.addcate = "& uid &" " & vbcrlf & _
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.oldname title,CONVERT(VARCHAR(10),b.l_date4,23) dt,DATEDIFF(s,'"&actDate&"',a.inDate) newTag,a.id [rid],d.addcate [cateid]"
			orderBy = "ORDER BY b.date7 DESC"
			Case 105:
			tmpCondition = getConditionByFW(m_qxlb,m_listqx,"b.reg_addcateid")
			If withoutCateCondition Then tmpCondition = ""
			cateCondition = getConditionByFW(m_qxlb,15,"b.prod_addcateid")
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join o_product b on a.reminderConfig=" & configId & " and a.orderId = b.id " & vbcrlf &_
			"inner join ( " & vbcrlf &_
			"select replace(prod_id,' ','') as ProductID,replace(prod_unit,' ','') as UnitId,sum(prod_num) as ku_num " & vbcrlf &_
			"from o_kuinlist a  with(nolock) " & vbcrlf &_
			"left join o_kuin b  with(nolock) on a.reg_fid=b.id " & vbcrlf &_
			"where 1=1 " & tmpCondition & " " & vbcrlf &_
			"group by prod_id,prod_unit " & vbcrlf &_
			") c on b.id=c.ProductID and a.daysFromNow=c.UnitId " & vbcrlf &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.prod_name title,(" & _
			"CASE when [Ku_num]<[prod_less] then '↓'+cast(dbo.formatnumber([Ku_num]," & numDigit & ",0) as nvarchar(50)) " & _
			"fields = ""b.id [id],b.prod_name title,(""" &_
			"when [Ku_num]>[prod_more] then '↑"
			fields = "b.id [id],b.prod_name title,(" & _
			"end " & _
			") dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.prod_addcateid cateid"
			orderBy = "order by b.prod_name desc"
			Case 106:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join tel b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.name title,'距离回收' + cast(daysFromNow as varchar) + '天' dt,"&_
			"datediff(s,'&actDate&" &_
			orderBy = "order by daysFromNow asc"
			Case 107:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_AppHoliday b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where (" & vbcrlf &_
			"KQClass in (" & vbcrlf &_
			"select id from hr_KQClass  with(nolock) where sortID=1 and del=0 " & vbcrlf &_
			") or KQClass=1 " & vbcrlf &_
			") and del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(19),startTime,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 108:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_AppHoliday b with(nolock)  on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where (" & vbcrlf &_
			"KQClass in (" & vbcrlf &_
			"select id from hr_KQClass  with(nolock) where sortID=2 and del=0 " & vbcrlf &_
			") or KQClass=2 " & vbcrlf &_
			") and del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(19),startTime,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 109:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_AppHoliday b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where (" & vbcrlf &_
			"KQClass in (" & vbcrlf &_
			"select id from hr_KQClass  with(nolock) where sortID=3 and del=0 " & vbcrlf &_
			") or KQClass=3 " & vbcrlf &_
			") and del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(19),startTime,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 110:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((sp=-1 or sp=0) and cateid="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"cateCondition = cateCondition & ""and (""" & vbcrlf &_
			"or (sp>0 and cateid_sp=&uid&) /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join wages b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"where del=1 and isnull(salaryClass,0)>0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],title,cast(year(date2) as varchar)+'年'+cast(month(date2) as varchar)+'月' dt,"&_
			"datediff(s,'&actDate&" &_
			"(case when sp=-1 or sp=0 then 1 else 0 end) canCancelAlt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],cateid,"&_
			"(case sp when -1 then 12 when 0 then 11 else 10 end) orderStat"
			orderBy = "order by b.date7 desc,b.date3 desc"
			Case 111:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((sp=-1 or sp=0) and cateid="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"cateCondition = cateCondition & ""and (""" & vbcrlf &_
			"or (sp>0 and cateid_sp=&uid&) /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join wages b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"where del=1 and isnull(salaryClass,0)=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],title,cast(year(date2) as varchar)+'年'+cast(month(date2) as varchar)+'月' dt,"&_
			"datediff(s,'&actDate&" &_
			"(case when sp=-1 or sp=0 then 1 else 0 end) canCancelAlt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],cateid,"&_
			"(case sp when -1 then 12 when 0 then 11 else 10 end) orderStat"
			orderBy = "order by b.date7 desc,b.date3 desc"
			Case 217:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.designer")
			cateCondition = cateCondition & " AND ( (cateid_sp = "& uid &" AND id_sp > 0) OR (cateid_sp = 0  AND designer = "& uid &" ) ) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			" INNER JOIN design b  with(nolock) ON a.reminderConfig="& configId &" AND a.orderId = b.id and b.del=1 AND b.designstatus in (7,8,9) WHERE 1 = 1"& vbcrlf &_
			" [CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id], b.title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.designer as cateid,"&_
			"(CASE WHEN (cateid_sp = 0 OR id_sp < 0) THEN 1 ELSE 0 END) canCancelAlt," &_
			"(case id_sp when -1 then 12 when 0 then 11 else 10 end) orderStat"
'(CASE WHEN (cateid_sp = 0 OR id_sp < 0) THEN 1 ELSE 0 END) canCancelAlt, &_
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 218:
			cateCondition = getCondition(m_qxlb,15,"c.designer")
			cateCondition = cateCondition & " AND  charindex(',"& uid &",',','+replace(reminders,' ','')+',')>0 "
			cateCondition = getCondition(m_qxlb,15,"c.designer")
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			" INNER JOIN reply b  with(nolock) ON a.reminderConfig="& configId &" AND a.orderId = b.id AND b.del=1 and b.sort1 = 5029 "& vbcrlf &_
			" inner join design c  with(nolock) on c.id = b.ord2       "&_
			" where b.del =1 " & vbcrlf &_
			" [CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id], b.title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid], b.cateid "
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 112:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and cateid_moi in ("&qIntro&") "
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = cateCondition & " and Cateid_MOI=" & uid
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M_ManuOrderIssueds b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,a.inDate dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
			orderBy = "order by b.inDate desc"
			Case 113:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and b.id in (select distinct b.id from reminderQueue a  with(nolock) " & vbcrlf &_
				"inner join M2_WorkAssigns b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
				"left join gate g1  with(nolock) on CHARINDEX(','+CONVERT(nvarchar(100),g1.ord)+',',','+b.Cateid_WA+',')>0" & vbcrlf &_
				"left join dbo.power plist  with(nolock) ON plist.ord = "& uid &" AND plist.sort1 = 54 AND plist.sort2 = 1" & vbcrlf &_
				"where b.del=1 and b.ptype=0 and tempSave=0 and b.[status]<>2 AND ISNULL(b.SPStatus,-1) IN(-1,1)" & vbcrlf &_
				"and (plist.qx_open = 3 OR CHARINDEX(','+CAST(g1.ord AS VARCHAR(20))+',',','+CAST(plist.qx_intro AS VARCHAR(8000))+',') > 0))"
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = cateCondition & " and charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(Cateid_WA,' ','')+',')>0"
			cateCondition = " and 1=2"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_WorkAssigns b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join product p  with(nolock) on p.ord = b.productid "&_
			"where b.del=1 and ptype=0 and tempSave=0 and b.[status]<>2 AND ISNULL(b.SPStatus,-1) IN(-1,1) and CONVERT(varchar(10),b.inDate,120) <= CONVERT(varchar(10),GETDATE(),120)"&_
			"inner join product p  with(nolock) on p.ord = b.productid "&_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title +' ('+ p.title +')' as title,a.inDate dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by b.inDate desc"
			Case 224:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and b.id in (select distinct b.id from reminderQueue a  with(nolock) " & vbcrlf &_
				"inner join erp_M2_WorkAssigns_status b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
				"left join gate g1  with(nolock) on CHARINDEX(','+CONVERT(nvarchar(100),g1.ord)+',',','+b.Cateid_WA+',')>0" & vbcrlf &_
				"left join dbo.power plist  with(nolock) ON plist.ord = "& uid &" AND plist.sort1 = 54 AND plist.sort2 = 1" & vbcrlf &_
				"where b.del=1 and b.ptype=0 and tempSave=0 and b.[status]<>2 and b.wastatus!='生产完毕' AND ISNULL(b.SPStatus,-1) IN(-1,1)" & vbcrlf &_
				"and (plist.qx_open = 3 OR CHARINDEX(','+CAST(g1.ord AS VARCHAR(20))+',',','+CAST(plist.qx_intro AS VARCHAR(8000))+',') > 0))"
			else
				cateCondition = " and 1=2"
			end if
			If m_fw1&""="1" Then
				tmpCondition = " and charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(Cateid_WA,' ','')+',')>0"
'If m_fw1&""="1" Then
			end if
			cateCondition =  " " & tmpCondition & " " & cateCondition & " and datediff(d,getdate(),b.dateEnd)<=" & m_tq1 & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join erp_M2_WorkAssigns_status b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join product p  with(nolock) on p.ord = b.productid "&_
			"where b.del=1 and b.ptype=0 and tempSave=0 and b.[status]<>2 and b.wastatus!='生产完毕' AND ISNULL(b.SPStatus,-1) IN(-1,1)" &_
			"inner join product p  with(nolock) on p.ord = b.productid "&_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title +' ('+ p.title +')' as title ,b.dateEnd dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by b.DateEnd, b.inDate desc"
			Case 225:
			tmpCondition = ""
			cateCondition = ""
			sql = "select COUNT(*) REMIND_CNT from dbo.v_attendance_GetRemind a   with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"where exists(select top 1 g.ord from dbo.gate g  with(nolock) where g.ord="& uid &" and g.orgsid=a.orgsid and g.Partadmin=1)" &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "a.Id [id],a.userName as title,a.WorkLong,a.RemindUnit,GETDATE() as dt,a.LogDate as newTag,a.Id [rid],a.Id cateid"
			orderBy = "order by a.LogDate desc"
			Case 5013:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = ""
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = cateCondition & " and charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(Cateid_WA,' ','')+',')>0"
			cateCondition = " and 1=2"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_WorkAssigns b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join product p  with(nolock) on p.ord = b.productid "&_
			"where b.del=1 and b.ptype=1 and tempSave=0 and b.[status]<>2 and CONVERT(varchar(10),b.inDate,120) = CONVERT(varchar(10),GETDATE(),120)" & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title +' ('+ p.title +')' as title,a.inDate dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by b.inDate desc"
			Case 54015:
			tmpCondition = ""
			cateCondition = ""
			sql = "select COUNT(*) REMIND_CNT from erp_fn_GetForSJWorkAssigns(''," & uid & ") a " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_WorkAssigns b  with(nolock) on a.ID=b.ID "&_
			"where " &_
			" exists(" &_
			"SELECT 1 from dbo.gate gt  with(nolock) " &_
			"inner join power sjpow  with(nolock) ON sjpow.ord =" & uid & " AND sjpow.sort1 =(case isnull(b.ptype,0) when 0 then 54 else 62 end) and sjpow.sort2=1 " &_
			"WHERE  (sjpow.qx_open = 3 OR CHARINDEX(','+CAST(gt.ord AS VARCHAR(20))+',',','+CAST(sjpow.qx_intro AS VARCHAR(8000))+',') > 0) " &_
			"and CHARINDEX(','+CAST(gt.ord AS VARCHAR(20))+',',','+ISNULL(b.Cateid_WA,-1)+',') > 0)" &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "a.Id [id],a.title as title,a.inDate as dt,datediff(s,'"&actDate&"',a.inDate) as newTag,a.Id [rid],a.Creator cateid"
			orderBy = "order by a.inDate desc"
			Case 54106:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			cateCondition = ""
			cateCondition = cateCondition & " and (charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(cast(QcCateid as varchar(12)),' ','')+',')>0 or exists(" &_
			"select top 1 1 from dbo.M2_OneSelfQualityTestingTaskList ttl  with(nolock) " &_
			" where ttl.TaskID=b.ID and charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(cast(ttl.QcCateid as varchar(12)),' ','')+',')>0))"
			sql = "select COUNT(*) REMIND_CNT from (select MAX(b.id) as ID,b.orderId,reminderConfig,max(inDate) inDate from reminderQueue b  with(nolock) group by b.orderId,reminderConfig) a """ & vbcrlf &_
			"[CANCELJOINTABLE] " & _
			"inner join M2_OneSelfQualityTestingTask b with(nolock)  on a.reminderConfig=" & configId & " and a.orderId = b.id " & vbcrlf &_
			"where b.[QCStatus]<>2 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title +' ('+ b.TaskBh +')' as title,convert(varchar(10),b.TaskDate,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by b.inDate desc"
			Case 5014:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If m_fw1&""="2" Then
				If qOpen = 3 Then
					tmpCondition = ""
				ElseIf qOpen=1 Then
					tmpCondition = " and b.id in (select distinct b.id from M2_WorkAssigns b  with(nolock)  " & vbcrlf &_
					"inner join gate g1  with(nolock) on CHARINDEX(','+CONVERT(nvarchar(100),g1.ord)+',',','+b.Cateid_WA+',')>0" & vbcrlf &_
					"tmpCondition = "" and b.id in (select distinct b.id from M2_WorkAssigns b  with(nolock)  """ & vbcrlf &_
					"where g1.ord in (& qIntro &) )"
				else
					tmpCondition = " and 1=2"
				end if
			else
				tmpCondition = " and charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(Cateid_WA,' ','')+',')>0 "
				tmpCondition = " and 1=2"
			end if
			cateCondition =  " " & tmpCondition & " " & cateCondition & " and datediff(d,getdate(),b.dateEnd)<=" & m_tq1 & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_WorkAssigns b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join product p  with(nolock) on p.ord = b.productid "&_
			"where b.del=1 and ptype=1 and tempSave=0 and b.[status]<>2 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title +' ('+ p.title +')' as title ,b.dateEnd dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by b.inDate desc "
			Case 114:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.creator")
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M_ManuPlans b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 and b.status=3 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,a.inDate dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
			orderBy = "order by b.inDate desc"
			Case 115:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.creator")
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M_ManuOrders b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 and b.status=3 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,a.inDate dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
			orderBy = "order by b.inDate desc"
			Case 116:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.creator")
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M_OutOrder b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 and b.status=3 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,a.inDate dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
			orderBy = "order by b.inDate desc"
			Case 117:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.creator")
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M_MaterialProgres b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,a.inDate dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
			orderBy = "order by b.inDate desc"
			Case 118:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.creator")
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M_QualityTestings b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where b.qtype<>1 and del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,a.inDate dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
			orderBy = "order by b.inDate desc"
			Case 119:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.creator")
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M_QualityTestings b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where b.qtype=1 and del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,a.inDate dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
			orderBy = "order by b.inDate desc"
			Case 120:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join tel b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.name title,'距离保护到期' + cast(daysFromNow as varchar) + '天' dt,"&_
			"datediff(s,'&actDate&"
			orderBy = "order by daysFromNow asc"
			Case 121:
			cateCondition = getConditionByFW(m_qxlb,m_listqx,"b.cateid")
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join tel b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.name title,'下次联系：' + convert(varchar(10),dateadd(d,daysFromNow,'2014-01-01'),23) dt,"&_
			"datediff(s,'&actDate&"
			orderBy = "order by daysFromNow asc"
			Case 122:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_ret_plan b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 123:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_Resume b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.keyword title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 124:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_interview b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],dbo.HrGetResumeName(b.resumeID) title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 125:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_train_plan b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 126:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_expaper b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 127:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_person_salary b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],ISNULL((SELECT TOP 1 name FROM gate  with(nolock) WHERE ord = b.cateid), '用户' + CAST(b.cateid AS varchar(10)) + '【已删】') title,"&_
			"convert(varchar(10),a.inDate,21) dt," &_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 128:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a with(nolock)  " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_person_contract b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 129:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_regime b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 130:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_positive b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 131:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a with(nolock)  " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_leave b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 132:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_Transfer b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 133:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_off_staff b with(nolock)  on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.gateName title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 134:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=3 or status=2) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_reinstate b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.gateName title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=3 or status=2 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 135:
			Set rs_setting = cn.execute("select workPosition FROM gate  with(nolock) WHERE ord ="& uid &"")
			workPosition = rs_setting("workPosition")
			If Len(workPosition&"") = 0 Then workPosition = 0
			rs_setting.close
			cateCondition = "and (" & vbcrlf &_
			"((spFlag=1 or spFlag=-1) and addcate="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"cateCondition = ""and (""" & vbcrlf &_
			"or ((spFlag=2 or spFlag=3) and cateid_sp=&uid&) /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join document b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"left join power p  with(nolock) on p.ord="& uid &" and sort1=78 and sort2=1 " & vbcrlf &_
			"left join power p1  with(nolock) on p1.ord="& uid &" and p1.sort1=78 and p1.sort2=16 "&_
			"where  del=1 " & vbcrlf &_
			"and (p1.qx_open = 3  OR (CHARINDEX(','+CAST(b.addcate AS VARCHAR(20))+',',','+CAST(p1.qx_intro AS VARCHAR(max))+',') > 0)"& vbcrlf &_
			"where  del=1 " & vbcrlf &_
			"or (b.addcate="& uid &" and  (b.spFlag = 1 or b.spFlag=-1)) "&_
			"where  del=1 " & vbcrlf &_
			" ) "& vbcrlf &_
			"and (p.qx_open = 3 OR (CHARINDEX(','+CAST(b.addcate AS VARCHAR(20))+',',','+CAST(p.qx_intro AS VARCHAR(max))+',') > 0"& vbcrlf &_
			" ) "& vbcrlf &_
			"or  CHARINDEX(','+ CONVERT(varchar(20),"& uid &") +',', ','+isnull(cast(b.share1 as varchar(8000)),0)+',')>0  " & vbcrlf &_
			" ) "& vbcrlf &_
			"or CHARINDEX(','+ CONVERT(varchar(20),"& workPosition &") +',', ','+isnull(cast(b.postDown as varchar(8000)),0)+',')>0  "&_
			" ) "& vbcrlf &_
			"or CHARINDEX(','+ CONVERT(varchar(20),"& workPosition &") +',', ','+isnull(cast(b.postView as varchar(8000)),0)+',')>0  "&_
			" ) "& vbcrlf &_
			"or (b.addcate="& uid &" and  (b.spFlag = 1 or b.spFlag=-1)) "&_
			" ) "& vbcrlf &_
			"or  CHARINDEX(','+ CONVERT(varchar(20),"& uid &") +',', ','+isnull(cast(b.share2 as varchar(8000)),0)+',')>0  ))" & vbcrlf &_
			" ) "& vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.addcate cateid," &_
			"(case when spFlag=1 or spFlag=-1 then 1 else 0 end) canCancelAlt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.addcate cateid," &_
			"datediff(s,'&actDate&"
			orderBy = "order by b.id desc"
			Case 136:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If m_fw1&""="0" Then
				If qOpen = 3 Then
					cateCondition = ""
				ElseIf qOpen=1 Then
					cateCondition = " and cateid is not null and cateid<>0 and cateid in ("&qIntro&") "
					tmpCondition = " and (cateid is not null and cateid<>0)"
				else
					cateCondition = " and 1=2"
				end if
			else
				cateCondition = " and cateid=" & uid
			end if
			cateCondition = " " & cateCondition & " " & tmpCondition & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join xunjia b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(10),b.date7,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = "order by b.date7 desc"
			Case 137:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If m_fw1&""="0" Then
				If qOpen = 3 Then
					cateCondition = ""
				ElseIf qOpen=1 Then
					cateCondition = " and ("_
					&" (addcate is not null and addcate<>0 and addcate in ("&qIntro&")) "_
					&" or (catelead is not null and catelead<>0 and catelead in ("&qIntro&")) "_
					&" or (cate1 is not null and cate1<>0 and cate1 in ("&qIntro&")) "_
					&" or (cate2 is not null and cate2<>0 and cate2 in ("&qIntro&")) "_
					&" or (cate3 is not null and cate3<>0 and cate3 in ("&qIntro&")) "_
					&" or (cate4 is not null and cate4<>0 and cate4 in ("&qIntro&")) "_
					&" or (cate5 is not null and cate5<>0 and cate5 in ("&qIntro&")) "_
					&" or (cate6 is not null and cate6<>0 and cate6 in ("&qIntro&")) "_
					&" or (cate7 is not null and cate7<>0 and cate7 in ("&qIntro&")) "_
					&" or (cate8 is not null and cate8<>0 and cate8 in ("&qIntro&")) "_
					&" or (member1 is not null and member1<>0 and member1 in ("&qIntro&")) "_
					&" or share='0' or charindex(',"&uid&",',','+replace(share,' ','')+',')>0 "_
					&" or (member1 is not null and member1<>0 and member1 in ("&qIntro&")) "_
					&" )"
				else
					cateCondition = " and 1=2"
				end if
			else
				cateCondition = " and ("_
				&" (addcate is not null and addcate<>0 and addcate ="&uid&") "_
				&" or (catelead is not null and catelead<>0 and catelead in ("&uid&")) "_
				&" or (cate1 is not null and cate1<>0 and cate1 in ("&uid&")) "_
				&" or (cate2 is not null and cate2<>0 and cate2 in ("&uid&")) "_
				&" or (cate3 is not null and cate3<>0 and cate3 in ("&uid&")) "_
				&" or (cate4 is not null and cate4<>0 and cate4 in ("&uid&")) "_
				&" or (cate5 is not null and cate5<>0 and cate5 in ("&uid&")) "_
				&" or (cate6 is not null and cate6<>0 and cate6 in ("&uid&")) "_
				&" or (cate7 is not null and cate7<>0 and cate7 in ("&uid&")) "_
				&" or (cate8 is not null and cate8<>0 and cate8 in ("&uid&")) "_
				&" or (member1 is not null and member1<>0 and member1 in ("&uid&")) "_
				&" or share='0' or charindex(',"&uid&",',','+replace(share,' ','')+',')>0 "_
				&" or (member1 is not null and member1<>0 and member1 in ("&uid&")) "_
				&" )"
			end if
			cateCondition = " " & cateCondition & " " & tmpCondition & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join tousu b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title,convert(varchar(19),b.date7,"& iif(m_isMobileMode,"21","23") &") dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.addcate cateid"
			orderBy = "order by b.date7 desc"
			Case 138:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = ""
				tmpCondition = " and (catein = " & uid & ") "
			ElseIf qOpen=1 Then
				cateCondition = " and cateid is not null and cateid<>0 and cateid in ("&qIntro&") "
				tmpCondition = " and (catein = " & uid & ") "
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = cateCondition & tmpCondition
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join kumove b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"where del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid cateid"
			orderBy = "order by b.ord desc"
			Case 139:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.addcate")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=0 or status=4) and addcate="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=1 or status=2) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join maintain b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"where del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.addcate cateid," &_
			"(case when status=0 or status=4 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 0 then 11 when 4 then 12 else 10 end) orderStat"
			orderBy = "order by b.ord desc"
			Case 140:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and cateid is not null and cateid<>0 and cateid in ("&qIntro&") "
			else
				cateCondition = " and 1=2"
			end if
			tmpCondition = ""
			If m_fw1&""="0" Then
				tmpCondition = " "
			else
				tmpCondition = " and cateid=" & uid
			end if
			cateCondition = " " & cateCondition & " " & tmpCondition & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join caigou b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title,convert(varchar(10),b.date7,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = "order by b.date7 desc"
			Case 141:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If m_fw1&""="0" Then
				If qOpen = 3 Then
					cateCondition = ""
				ElseIf qOpen=1 Then
					cateCondition = " and cateid is not null and cateid<>0 and cateid in ("&qIntro&") "
					tmpCondition = " and (cateid is not null and cateid<>0)"
				else
					cateCondition = " and 1=2"
				end if
			else
				cateCondition = " and cateid=" & uid
			end if
			cateCondition = " " & cateCondition & " " & tmpCondition & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join caigou_yg b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(10),b.date7,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = "order by b.date7 desc"
			Case 142:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = ""
				tmpCondition = " and (cateout = " & uid & ") "
			ElseIf qOpen=1 Then
				cateCondition = " and cateid is not null and cateid<>0 and cateid in ("&qIntro&") "
				tmpCondition = " and (cateout = " & uid & ") "
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = cateCondition & tmpCondition
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join kumove b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"where del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid cateid"
			orderBy = "order by b.ord desc"
			Case 143:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and cateid is not null and cateid<>0 and cateid in ("&qIntro&") "
			else
				cateCondition = " and 1=2"
			end if
			Call fillinPower(24,13,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition &  " and cateid is not null and cateid<>0 and cateid in ("&qIntro&") "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			Call fillinPower(4,14,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition &  " and cateid is not null and cateid<>0 and cateid in ("&qIntro&") "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & tmpCondition
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join price b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del in (3,1) and complete in (1,8)  " & vbcrlf &_
			"where del in (3,1) " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(10),b.date1,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid cateid"
			orderBy = "order by b.ord desc"
			Case 144:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = ""
				tmpCondition = " and (Inspector = " & uid & ") "
			ElseIf qOpen=1 Then
				cateCondition = " and addcate is not null and addcate<>0 and addcate in ("&qIntro&") "
				tmpCondition = " and (Inspector = " & uid & ") "
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = cateCondition & tmpCondition
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join caigouqc b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del = 1 and b.complete in (0,1)  " & vbcrlf &_
			"where del =1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.addcate cateid"
			orderBy = "order by b.id desc"
			Case 145:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status=0 or status=3) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=1 or status=2) and cateid_sp="&uid&") /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join budget b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"where del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=0 or status=3 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 0 then 11 when 3 then 12 else 10 end) orderStat"
			orderBy = "order by b.ord desc"
			Case 146:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If m_fw1="0" Then
				tmpCondition = ""
			else
				tmpCondition = " and (cateid=" & uid & ") "
			end if
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and ((cateid is not null and cateid<>0 and cateid in ("&qIntro&")) or share='1' or charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(cast(share as varchar(8000)),' ','')+',')>0) "
'ElseIf qOpen=1 Then
			else
				cateCondition = " and (share='1' or charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(cast(share as varchar(8000)),' ','')+',')>0)"
'ElseIf qOpen=1 Then
			end if
			cateCondition = " " & tmpCondition & " " & cateCondition & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join chance b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title,convert(varchar(19),b.date7,"& iif(m_isMobileMode,"21","23") &") dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = "order by b.date7 desc"
			Case 147:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If m_fw1="0" Then
				tmpCondition = ""
			else
				tmpCondition = " and ((order1=1 or order1=2) and cateid=" & uid & ") "
			end if
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and ((cateid is not null and cateid<>0 and cateid in ("&qIntro&")) or share='1' or charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(cast(share as varchar(8000)),' ','')+',')>0) "
'ElseIf qOpen=1 Then
			else
				cateCondition = " and (share='1' or charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(cast(share as varchar(8000)),' ','')+',')>0)"
'ElseIf qOpen=1 Then
			end if
			cateCondition = " " & tmpCondition & " " & cateCondition & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join tel b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"where del =1 and isnull(sp,0)=0 and sort3=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.name [title],convert(varchar(19),b.date2,"& iif(m_isMobileMode,"21","23") &") dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = " order by b.date2 desc "
			Case 148:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateadd")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((isnull(status_sp_qualifications,0)=0 or status_sp_qualifications=4) and isnull(cateid,cateadd)="&uid&") " & vbcrlf &_
			"/*审批通过或终止的提醒给采购人员或添加人*/" & vbcrlf &_
			"or " & vbcrlf &_
			"((status_sp_qualifications=1 or status_sp_qualifications=2) and cateid_sp_qualifications="&uid&") " & vbcrlf &_
			"/*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join sortFieldsContent c  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = c.id and c.del = 1 " & vbcrlf &_
			"inner join tel b  with(nolock) on c.ord = b.ord and b.del=1 " & vbcrlf &_
			"where b.del=1 and sort3=2 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "c.id [id],b.name title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateadd cateid," &_
			"(case when isnull(status_sp_qualifications,0)=0 or status_sp_qualifications=4 then 1 else 0 end) canCancelAlt,"&_
			"(case isnull(status_sp_qualifications,0) when 0 then 11 when 4 then 12 else 10 end) orderStat"
			orderBy = "order by b.ord desc"
			Case 149:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateadd")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"((status_sp_qualifications=0 or status_sp_qualifications=4) and isnull(cateid,cateadd)=" & uid & ") " & vbcrlf &_
			"/*审批通过或终止的提醒给销售人员或添加人*/" & vbcrlf &_
			"or "&_
			"((status_sp_qualifications=1 or status_sp_qualifications=2) and cateid_sp_qualifications=" & uid & ") " & vbcrlf &_
			"/*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join sortFieldsContent c  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = c.id and c.del = 1 " & vbcrlf &_
			"inner join tel b  with(nolock) on c.ord = b.ord and b.del=1 " & vbcrlf &_
			"where b.sort3=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "c.id [id],b.name title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateadd cateid," &_
			"(case when isnull(status_sp_qualifications,0)=0 or status_sp_qualifications=4 then 1 else 0 end) canCancelAlt,"&_
			"(case isnull(status_sp_qualifications,0) when 0 then 11 when 4 then 12 else 10 end) orderStat"
			orderBy = "order by b.ord desc"
			Case 70:
			cateCondition = " @MyPower_1_102 and (" & vbcrlf &_
			"((use_complete=4 or use_complete=3) and use_addcateid="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((use_complete=1 or use_complete=2) and use_cateid_sp="&uid&" @MyPower_16_102) /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				tmpCondition = ""
			ElseIf qOpen=1 Then
				tmpCondition = " and use_addcateid is not null and use_addcateid<>0 and use_addcateid in ("&qIntro&") "
			else
				tmpCondition = " and 1=2"
			end if
			cateCondition = Replace(cateCondition,"@MyPower_1_102",tmpCondition)
			tmpCondition = ""
			cateCondition = Replace(cateCondition,"@MyPower_16_102",tmpCondition)
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join O_carUse b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.use_id and b.use_del=1 " & vbcrlf &_
			"inner join gate g  with(nolock) on b.use_cateid = g.ord " & vbcrlf &_
			"where use_del=1 and use_type=1 and b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.use_id [id],g.name title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.use_addcateid cateid," &_
			"(case when use_complete=3 or use_complete=4 then 1 else 0 end) canCancelAlt,"&_
			"(case use_complete when 3 then 11 when 4 then 12 else 10 end) orderStat"
			orderBy = "order by b.use_id desc"
			Case 150:
			cateCondition = " @MyPower_1_102 and (" & vbcrlf &_
			"((status=2 or status=3) and creator="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or ((status=0 or status=1) and cateid_sp="&uid&" @MyPower_16_102) /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				tmpCondition = ""
			ElseIf qOpen=1 Then
				tmpCondition = " and creator is not null and creator<>0 and creator in ("&qIntro&") "
			else
				tmpCondition = " and 1=2"
			end if
			cateCondition = Replace(cateCondition,"@MyPower_1_102",tmpCondition)
			tmpCondition = ""
'cateCondition = Replace(cateCondition,"@MyPower_16_102",tmpCondition)
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join hr_perform_ss b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=0 " & vbcrlf &_
			"where del=0 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when status=2 or status=3 then 1 else 0 end) canCancelAlt,"&_
			"(case status when 3 then 11 when 2 then 12 else 10 end) orderStat"
			orderBy = "order by b.id desc"
			Case 151:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If m_fw1&""="0" Then
				tmpCondition = ""
			else
				tmpCondition = " and cateid=" & uid & " "
			end if
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and ((addcate is not null and addcate<>0 and addcate in ("&qIntro&")) or share='1' or charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(cast(share as varchar(8000)),' ','')+',')>0) "
'ElseIf qOpen=1 Then
			else
				cateCondition = " and (1=2 or charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(cast(share as varchar(8000)),' ','')+',')>0)"
'ElseIf qOpen=1 Then
			end if
			cateCondition = " " & tmpCondition & " " & cateCondition & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join contract b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 and isnull(b.status,-1) in (-1,1) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"where del =1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title [title],convert(varchar(19),b.date7,"& iif(m_isMobileMode,"21","23") &") dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = "order by b.date1 desc,b.date7 desc"
			Case 152:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If m_fw1&""="0" Then
				tmpCondition = ""
			else
				tmpCondition = " and cateid=" & uid & " "
			end if
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and ((addcate is not null and addcate<>0 and addcate in ("&qIntro&"))) "
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = " " & tmpCondition & " " & cateCondition & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join price b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del in (1,3) and complete not in (1,8) " & vbcrlf &_
			"where del in (1,3) " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title [title],convert(varchar(10),b.date7,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = "order by b.date1 desc,b.date7 desc"
			Case 153:
			cateCondition = " @MyPower_1_102 and (" & vbcrlf &_
			"((complete1<>1) and cateid="&uid&") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (complete1=1 and kg="&uid&" @MyPower_16_102) /*待审批的提醒给审批人*/" & vbcrlf &_
			")"
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				tmpCondition = ""
			ElseIf qOpen=1 Then
				tmpCondition = " and cateid is not null and cateid<>0 and cateid in ("&qIntro&") "
			else
				tmpCondition = " and 1=2"
			end if
			cateCondition = Replace(cateCondition,"@MyPower_1_102",tmpCondition)
			tmpCondition = ""
'cateCondition = Replace(cateCondition,"@MyPower_16_102",tmpCondition)
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join kumove b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"where del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.title title,convert(varchar(10),a.inDate,21) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid cateid," &_
			"(case when complete1<>1 then 1 else 0 end) canCancelAlt,"&_
			"(case when complete1=4 or complete1=3 or complete1=5 then 11 when complete1=2 then 12 else 10 end) orderStat"
			orderBy = "order by b.ord desc"
			Case 154:
			tmpCondition = ""
			If m_fw1&""="0" Then
				tmpCondition = ""
			else
				tmpCondition = " and b.cateid=" & uid & " "
			end if
			cateCondition = "and (" & vbcrlf
			Call fillinPower(1,5,qOpen,qIntro)
			cateCondition = cateCondition & " ( b.sort1=1 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (b.cateid is not null and b.cateid<>0 and b.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(2,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( b.sort1=8 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (b.cateid is not null and b.cateid<>0 and b.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(3,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( b.sort1=2 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (b.cateid is not null and b.cateid<>0 and b.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(4,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( b.sort1=3 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (b.cateid is not null and b.cateid<>0 and b.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(5,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( b.sort1=4 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (b.cateid is not null and b.cateid<>0 and b.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(22,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( b.sort1=5 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (b.cateid is not null and b.cateid<>0 and b.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(41,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( b.sort1=6 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (b.cateid is not null and b.cateid<>0 and b.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(42,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( b.sort1=7 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (b.cateid is not null and b.cateid<>0 and b.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(75,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( b.sort1=75 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (b.cateid is not null and b.cateid<>0 and b.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(95,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( b.sort1=102001 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (b.cateid is not null and b.cateid<>0 and b.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			Call fillinPower(96,5,qOpen,qIntro)
			cateCondition = cateCondition & " or ( b.sort1=102002 "
			If qOpen = 3 Then
				cateCondition = cateCondition & ""
			ElseIf qOpen=1 Then
				cateCondition = cateCondition & " and (b.cateid is not null and b.cateid<>0 and b.cateid in ("&qIntro&")) "
			else
				cateCondition = cateCondition & " and 1=2"
			end if
			cateCondition = cateCondition & " ) "
			cateCondition = cateCondition & " ) "
			cateCondition = " and (( 1=1 " & tmpCondition & " " & cateCondition & ") or b.share='1' or charindex(','+cast(" & uid & " as varchar(12))+',',','+replace(cast(b.share as varchar(8000)),' ','')+',')>0)" & vbcrlf
			cateCondition = cateCondition & " ) "
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join reply b with(nolock)  on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 and ISNULL(b.alt,0) = 0 and b.id1 is null " & vbcrlf &_
			"inner join tel t  with(nolock) on t.ord = b.ord and t.del=1 and t.sort3=1 " & vbcrlf &_
			"where b.del =1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],cast(b.intro as varchar(8000)) [title],convert(varchar(19),b.date7,"& iif(m_isMobileMode,"21","23") &") dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = "order by b.date7 desc"
			Case 155:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = " and iss_cateid=" & uid & " "
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and ((iss_addcateid is not null and iss_addcateid<>0 and iss_addcateid in ("&qIntro&") and car_addcateid in ("&qIntro&"))) "
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = " " & tmpCondition & " " & cateCondition & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a with(nolock)  " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join O_insure b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.iss_id and b.iss_del=1 and b.iss_warn = 1 and DATEDIFF(D,GETDATE(),b.iss_endtime)<= "& m_tq1 &" " & vbcrlf &_
			" inner join O_carData c  with(nolock) on c.car_id = b.iss_carid "& vbcrlf &_
			" inner join O_carSet s  with(nolock) on s.setType=3 and s.id=b.iss_type "&_
			"where iss_del =1 and b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.iss_id [id],c.car_code+' ('+s.setname+')' title,iss_endtime dt,"&_
			"datediff(s,'&actDate&"
			orderBy = "order by iss_endtime desc"
			Case 157:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and (isnull(t.cateid,u.cateid) is not null and isnull(t.cateid,u.cateid)<>0 and u.cateid in ("&qIntro&")) "
			else
				cateCondition = " and 1=2 "
			end if
			tmpCondition = ""
			If m_fw1&""="2" Then
				tmpCondition = " and (isnull(t.cateid,0)=" & uid & " or isnull(u.cateid,0)=" & uid & ") "
			else
				tmpCondition = " and isnull(u.cateid,0)=" & uid & " "
			end if
			cateCondition = " " & tmpCondition & " " & cateCondition & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from MMsg_User u  with(nolock) " & vbcrlf &_
			"inner join ( " & vbcrlf &_
			"select userid,1 cnt,createtime lastTime from MMsg_Message  with(nolock) " & vbcrlf &_
			"where sendOrReceive = 1 and readed = 0 " & vbcrlf &_
			"and datediff(hh,dateadd(s,createTime,'1970-1-1 0:0:0'),getdate()) < 56 " & vbcrlf &_
			"where sendOrReceive = 1 and readed = 0 " & vbcrlf &_
			") m on u.id=m.userid " & vbcrlf &_
			"left join (" & vbcrlf &_
			"    select p.ord,tl.cateid from person p  with(nolock) " & vbcrlf &_
			"    left join tel tl on tl.ord = p.company " & vbcrlf &_
			") t on u.person=t.ord " & vbcrlf &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [ORDERBY]"
			fields = "u.id [id],u.nickname + '(' + cast(cnt as varchar) + ')' title,dateadd(hh,8,dateadd(s,lastTime,'1970-1-1 0:0:0')) dt,"&_
			"datediff(s,'&actDate&',dateadd(hh,8,dateadd(s,lastTime,'1970-1-1 0:0:0"
'[CATECONDITION] [ORDERBY]
			orderBy = "order by m.lastTime desc"
			Case 219:
			cateCondition =  " AND (charindex(',"& uid &",',','+replace(share,' ','')+',')>0 or b.share='1' or exists(select 1 from noticelist  with(nolock) where notice = b.id and cateid = "& uid &") ) "
'Case 219:
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			" INNER JOIN notice b  with(nolock) ON a.reminderConfig="& configId &" AND a.orderId = b.id AND b.del=1 "& vbcrlf &_
			" where b.del =1 " & vbcrlf &_
			" [CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id], b.title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid], b.creator as cateid "
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 220:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & " AND b.Id in ( SELECT mr.Id FROM dbo.caigou_yg mr  with(nolock)   "&_
			"   inner join sp_ApprovalInstance c  with(nolock) on c.gate2=72001 and c.PrimaryKeyID = mr.Id and c.BillPattern in (0,1)  "&_
			"   WHERE mr.del<>2 and ((mr.status in (-1,0,1) and isnull(mr.Cateid,mr.Addcate) =" & uid &") "&_
			"   or (mr.status in (2,4,5) and charindex('," & uid &",',','+ c.SurplusApprover +',')>0))) "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"INNER JOIN caigou_yg b  with(nolock) ON a.reminderConfig=" & configId & " AND a.orderId = b.id AND (b.del = 1 OR b.del = 3) WHERE 1 = 1  " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title title,convert(varchar(19),a.inDate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid,"&_
			"0 canCancelAlt, " &_
			"(case status when -1 then 17 when 0 then 16 when 1 then 11 when 2 then 12 when 3 then 9 when 4 then 10 when 5 then 8 else 10 end) orderStat"
'0 canCancelAlt,  &_
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 17:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If m_fw1&""="0" Then
				tmpCondition = ""
			else
				tmpCondition = " and ord=" & uid & " "
			end if
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and ((ord is not null and ord<>0 and ord in ("&qIntro&"))) "
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = " " & tmpCondition & " " & cateCondition & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join "& vbcrlf &_
			" (select *,(select TOP 1 id from hr_person  with(nolock) where del = 0 AND userid=ord) as id from gate_person where del=1) "& vbcrlf &_
			" b on a.reminderConfig=" & configId & " and a.orderId = b.id and nowStatus not in (2,4) " & vbcrlf &_
			"where b.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.name title,date3 dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.ord cateid"
			orderBy = "order by date3 desc"
			Case 156:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If Me.isSupperAdmin Then
				tmpCondition = ""
			else
				tmpCondition = " and 1 = 2 "
			end if
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and ((ord is not null and ord<>0 and ord in ("&qIntro&"))) "
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = " " & tmpCondition & " " & cateCondition & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join gate b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ord and b.del=1 " & vbcrlf &_
			"where del =1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ord [id],b.name title,date3 dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.ord cateid"
			orderBy = "order by date3 desc"
			Case 222:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If sdk.power.existsPower(80,17) Then
				cateCondition = "  "
			else
				cateCondition = " and 1=2"
			end if
			cateCondition =  cateCondition &" AND ((b.DisposeUser=" & uid & " and b.TreatmentStatus = -1) ) "
			cateCondition = " and 1=2"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join HrKQ_AttendanceAppeal b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.ID " & vbcrlf &_
			"left join HrKQ_AttendanceType c with(nolock)  on c.onlyid = b.reason " &_
			"where 1 =1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.ID [id],c.title title,b.CreateDate dt, datediff(s,'"& actDate &"',a.inDate) newTag,a.id [rid],b.userid cateid"
			orderBy = "order by b.CreateDate desc"
			Case 223 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.createID")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.CreateID="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (4,5) and charindex(',"& uid &",',','+ c.Approver +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.CreateID="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join HrKQ_AttendanceApply b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.isdel=0 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=8 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.CreateDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.createid cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.CreateDate desc"
			Case 52001 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_ManuPlansPre b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=52001 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 51005 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_BOM b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=51005 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 54001 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_ManuOrders b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=54001 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 54002 :
			Dim qxOpen,qxIntro
			Call fillInPower(m_qxlb,m_listqx,qxOpen,qxIntro)
			If qxOpen = 3 Then
				cateCondition = ""
			ElseIf qxOpen = 1 Then
				cateCondition = " and b.id in (select distinct b.id from reminderQueue a  with(nolock) " & vbcrlf &_
				"inner join M2_WorkAssigns b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
				"left join gate g1  with(nolock) on CHARINDEX(','+CONVERT(nvarchar(100),g1.ord)+',',','+b.Cateid_WA+',')>0" & vbcrlf &_
				"left join dbo.power plist  with(nolock) ON plist.ord = "& uid &" AND plist.sort1 = 54 AND plist.sort2 = 1" & vbcrlf &_
				"where b.del=1 and b.ptype=0 and tempSave=0 and b.[status]<>2" & vbcrlf &_
				"and (plist.qx_open = 3 OR CHARINDEX(','+CAST(g1.ord AS VARCHAR(20))+',',','+CAST(plist.qx_intro AS VARCHAR(8000))+',') > 0))"
'where b.del=1 and b.ptype=0 and tempSave=0 and b.[status]<>2 & vbcrlf &_
			else
				cateCondition = " and 1=2"
			end if
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_WorkAssigns b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c with(nolock) on c.gate2=54002 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 54003 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_OutOrder b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=54003 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 52002 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_ManuPlans b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=52002 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 55001 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_MaterialOrders b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 and b.MaterialType in (1,2) " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=55001 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 55006 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_MaterialOrders b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 and b.MaterialType = 3 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=55006 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 56001 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.Approver +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_PriceRate b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=56001 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 55002 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a with(nolock)  " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_MaterialRegisters b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 and b.OrderType = 2 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=55002 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 55003 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_MaterialRegisters b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 and b.OrderType = 3 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=55003 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 56007 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.Approver +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_TimeWages b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=56007 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 56008 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.Approver +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_Wage_JS b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c with(nolock)  on c.gate2=56008 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 160 :
			cateCondition =  " AND "& uid &"=b.cateid "
			sql = "SELECT COUNT(*) REMIND_CNT FROM reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			" INNER JOIN M2_RewardPunish b  with(nolock) ON a.reminderConfig="& configId &" AND a.orderId = b.id AND b.del=1 "& vbcrlf &_
			" where b.del =1 " & vbcrlf &_
			" [CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id], b.title,convert(varchar(10),b.RPdate,21) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid], b.creator as cateid "
			orderBy = "ORDER BY a.inDate DESC,b.id DESC"
			Case 54007:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and M2WFPA.id in (select  M2WFPA.id from reminderQueue a  with(nolock) " & vbcrlf &_
				"inner join (SELECT M2WFPA.ID FROM M2_WFP_Assigns M2WFPA  with(nolock) " & vbcrlf &_
				"left join erp_Gxdqtx_status M2WA  with(nolock) on M2WFPA.WAID = M2WA.ID and M2WA.del = 1 and M2WA.tempSave = 0 " & vbcrlf &_
				"left join M2_WorkingProcedures M2WP  with(nolock) on M2WP.ID = M2WFPA.WPID  " & vbcrlf &_
				"left join gate g1  with(nolock) on CHARINDEX(','+CONVERT(nvarchar(100),g1.ord)+',',','+isnull(M2WFPA.cateid,'')+','+isnull(M2WA.Cateid_WA,'')+','+isnull(M2WP.Wheelman,'')+',')>0  " & vbcrlf &_
				"left join M2_WorkingProcedures M2WP  with(nolock) on M2WP.ID = M2WFPA.WPID  " & vbcrlf &_
				"left join dbo.power plist  with(nolock) ON plist.ord = "& uid &" and plist.sort1=5031 AND plist.sort2=1" & vbcrlf &_
				" where M2WFPA.del=1 and isnull(M2WFPA.isOut,0)=0  and tempSave=0 " & vbcrlf &_
				" AND (plist.qx_open = 3 or dbo.existsPower2(plist.qx_intro, isnull(M2WFPA.cateid, '') + ',' + isnull(M2WA.Cateid_WA, ''), ',') = 1) "& vbcrlf &_
				" where M2WFPA.del=1 and isnull(M2WFPA.isOut,0)=0  and tempSave=0 " & vbcrlf &_
				" AND M2WA.[Status]<>2  AND M2WA.wastatus!='生产完毕' AND ISNULL(M2WA.SPStatus,-1) IN(-1,1)"& vbcrlf &_
				" where M2WFPA.del=1 and isnull(M2WFPA.isOut,0)=0  and tempSave=0 " & vbcrlf &_
				" AND ISNULL(M2WFPA.Finished, 0) = 0"& vbcrlf &_
				" AND NOT EXISTS(SELECT 1 FROM M2_CostComputation  with(nolock) WHERE complete1=1 and datediff(mm,date1,M2WA.DateStart)=0)  GROUP BY M2WFPA.ID)  M2WFPA  ON  a.reminderConfig= " & configId & "  and a.orderId = M2WFPA.id) "
			else
				cateCondition = " and 1=2"
			end if
			If m_fw1&""="1" Then
				tmpCondition = " and charindex(','+cast(" & uid & " as varchar(12))+',',','+isnull(M2WFPA.cateid,'')+','+isnull(M2WA.Cateid_WA,'')+','+isnull(M2WP.Wheelman,'')+',')>0"
'If m_fw1&""="1" Then
			else
				tmpCondition = " and (plist.qx_open = 3  OR CHARINDEX(','+CAST(g1.ord AS VARCHAR(20))+',',','+CAST(plist.qx_intro AS VARCHAR(8000))+',') > 0)"
'If m_fw1&""="1" Then
			end if
			cateCondition =  " " & tmpCondition & " " & cateCondition & " and datediff(d,getdate(),M2WFPA.dateEnd)<=" & m_tq1 & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join (SELECT  M2WFPA.id,M2WA.title,M2WP.WPName,M2WFPA.DateEnd,M2WFPA.cateid,M2WA.indate  from M2_WFP_Assigns M2WFPA   with(nolock)    " & vbcrlf &_
			"left join erp_Gxdqtx_status M2WA  with(nolock) on M2WFPA.WAID = M2WA.ID and M2WA.del = 1 and M2WA.tempSave = 0  " & vbcrlf &_
			"left join M2_WorkingProcedures M2WP  with(nolock) on M2WP.ID = M2WFPA.WPID   " & vbcrlf &_
			"left join gate g1  with(nolock) on CHARINDEX(','+CONVERT(nvarchar(100),g1.ord)+',',','+isnull(M2WFPA.cateid,'')+','+isnull(M2WA.Cateid_WA,'')+','+isnull(M2WP.Wheelman,'')+',')>0 " & vbcrlf &_
			"left join M2_WorkingProcedures M2WP  with(nolock) on M2WP.ID = M2WFPA.WPID   " & vbcrlf &_
			"left join dbo.power plist  with(nolock) ON plist.ord = "& uid &" and plist.sort1=5031 AND plist.sort2=1 " & vbcrlf &_
			"WHERE  M2WFPA.del=1 and isnull(M2WFPA.isOut,0)=0  and charindex(','+cast(" & uid & " as varchar(12))+',',','+isnull(M2WFPA.cateid,'')+','+isnull(M2WA.Cateid_WA,'')+','+isnull(M2WP.Wheelman,'')+',')>0 and tempSave=0 " & vbcrlf &_
			" AND M2WA.[Status]<>2  AND M2WA.wastatus!='生产完毕' AND ISNULL(M2WA.SPStatus,-1) IN(-1,1) "& vbcrlf &_
			" AND ISNULL(M2WFPA.Finished, 0) = 0"& vbcrlf &_
			" AND NOT EXISTS(SELECT 1 FROM M2_CostComputation  with(nolock) WHERE complete1=1 and datediff(mm,date1,M2WA.DateStart)=0) "& vbcrlf &_
			"[CATECONDITION]  "& vbcrlf &_
			" GROUP BY  M2WFPA.id,M2WA.title,M2WP.WPName,M2WFPA.DateEnd,M2WFPA.cateid,M2WA.indate) M2WFPA ON  a.reminderConfig=" & configId & " and a.orderId = M2WFPA.id  "& vbcrlf &_
			"[CANCELCONDITION] [ORDERBY]"
			fields = "M2WFPA.id,isnull(M2WFPA.title,'')+'['+ISNULL(M2WFPA.WPName,'')+']' as title ,convert(varchar(10),M2WFPA.DateEnd,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],M2WFPA.cateid"
'[CANCELCONDITION] [ORDERBY]
			orderBy = "order by M2WFPA.indate desc"
			Case 540071:
			tmpCondition = ""
			cateCondition = ""
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_WFP_Assigns wfpa  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = wfpa.id and wfpa.del=1 and isnull(wfpa.ExecTask,0) = 1 " & vbcrlf &_
			"inner join M2_WorkAssigns wa  with(nolock) on wfpa.waid = wa.id and wa.del=1 " & vbcrlf &_
			"inner join M2_WorkingProcedures wp  with(nolock) on wfpa.wpid = wp.id and wp.del=1 " & vbcrlf &_
			"where 1=1 and (dbo.existsPower2(wp.wheelman,'" & uid & "',',') = 1 or dbo.existsPower2(wfpa.cateid,'" & uid & "',',') = 1)" & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "wfpa.id [id],wa.title+'('+wp.WPName+')' as title,wa.inDate dt,datediff(s,'"&actDate&"',wa.inDate) newTag,a.id [rid],(wa.Cateid_WA+','+wp.wheelman+','+wfpa.cateid) cateid"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by wa.inDate desc"
			Case 540072:
			tmpCondition = ""
			cateCondition = ""
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_WFPTask_Assigns task  with(nolock) on a.reminderConfig=""" & configId & " and a.orderId = task.id and task.beginStatus = 0 and not exists(select top 1 1 from M2_ProcedureProgres  with(nolock) where del = 1 and TaskID = task.ID) and dbo.existsPower2(task.cateid,'" & uid & "',',') = 1" & vbcrlf &_
			"inner join M2_WFP_Assigns wfpa  with(nolock) on task.wfpaid = wfpa.id and wfpa.del=1 " & vbcrlf &_
			"inner join M2_WorkAssigns wa  with(nolock) on wfpa.waid = wa.id and wa.del=1 " & vbcrlf &_
			"inner join M2_WorkingProcedures wp  with(nolock) on wfpa.wpid = wp.id and wp.del=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "task.id [id],wa.title+'('+wp.WPName+')' as title,task.inDate dt,datediff(s,'"&actDate&"',task.inDate) newTag,a.id [rid],(wa.Cateid_WA+','+wp.wheelman+','+wfpa.cateid) cateid"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by task.inDate desc"
			Case 540073:
			tmpCondition = ""
			cateCondition = ""
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join (" & vbcrlf &_
			"   select isnull(batchid,id) id,indate,creator,wfpaid from M2_ProcedureProgres with(nolock) " & vbcrlf &_
			"   where del = 1 and checkresult = 2 and CheckPerson = "& uid &_
			"   group by isnull(batchid,id),indate,creator,wfpaid" & vbcrlf &_
			") aa on a.reminderConfig =  " & configId & " and a.orderId = aa.id" & vbcrlf &_
			"inner join M2_WFP_Assigns wfpa  with(nolock) on aa.wfpaid = wfpa.id and wfpa.del=1 " & vbcrlf &_
			"inner join M2_WorkAssigns wa  with(nolock) on wa.id = wfpa.waid " & vbcrlf &_
			"inner join M2_WorkingProcedures wp  with(nolock) on wfpa.wpid = wp.id and wp.del=1" & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "aa.[id],wa.title+'('+wp.WPName+')' as title,aa.inDate dt,datediff(s,'"&actDate&"',aa.inDate) newTag,a.[id] [rid],(wa.Cateid_WA+','+wp.wheelman+','+wfpa.cateid+','+cast(aa.Creator as varchar(20))) cateid"
'[CATECONDITION] [CANCELCONDITION] [ORDERBY]
			orderBy = "order by aa.inDate desc"
			Case 51001:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			cateCondition = " and charindex(','+CAST(" & uid & " as varchar(10))+',',','+replace(CONVERT(VARCHAR(8000),remindPerson),' ','')+',')>0 " &_
			"AND DATEDIFF(d, GETDATE() ,(CASE remindunit WHEN 1 THEN DATEADD(HOUR,remindcyc,begindate)  " &_
			"  WHEN 2 THEN DATEADD(DAY,remindcyc,begindate) END))<=" & m_tq1
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_MachineComponent b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id,b.title,convert(varchar(10),(CASE remindunit WHEN 1 THEN DATEADD(HOUR,remindcyc,begindate) "  &_
			"  WHEN 2 THEN DATEADD(DAY,remindcyc,begindate) END),23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.remindPerson as cateid"
			orderBy = "order by (CASE remindunit WHEN 1 THEN DATEADD(HOUR,remindcyc,begindate) "  &_
			"  WHEN 2 THEN DATEADD(DAY,remindcyc,begindate) END) desc,b.indate desc"
			Case 55004 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_MaterialRegisters b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 and b.OrderType = 1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=55004 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.date1 dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.date1 desc"
			Case 51011:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			cateCondition = " and charindex(','+CAST(" & uid & " as varchar(10))+',',','+replace(CONVERT(VARCHAR(8000),cateid),' ','')+',')>0 " &_
			"AND DATEDIFF(d, GETDATE() ,(CASE Unit2 WHEN 0 THEN DATEADD(MINUTE,num2,date1) " &_
			"  WHEN 1 THEN DATEADD(HOUR,num2,date1) WHEN 2 THEN DATEADD(DAY,num2,date1) WHEN 3 THEN DATEADD(MONTH,num2,date1) " &_
			"  WHEN 4 THEN DATEADD(YEAR,num2,date1) end))<=" & m_tq1
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a with(nolock)  " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_maintain b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id,b.title,convert(varchar(10),(CASE Unit2 WHEN 0 THEN DATEADD(MINUTE,num2,date1) " & vbcrlf &_
			"  WHEN 1 THEN DATEADD(HOUR,num2,date1) WHEN 2 THEN DATEADD(DAY,num2,date1) WHEN 3 THEN DATEADD(MONTH,num2,date1) " & vbcrlf &_
			"  WHEN 4 THEN DATEADD(YEAR,num2,date1) end),23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid"
			orderBy = "order by (CASE Unit2 WHEN 0 THEN DATEADD(MINUTE,num2,date1) " & vbcrlf &_
			"  WHEN 1 THEN DATEADD(HOUR,num2,date1) WHEN 2 THEN DATEADD(DAY,num2,date1) WHEN 3 THEN DATEADD(MONTH,num2,date1) " & vbcrlf &_
			"  WHEN 4 THEN DATEADD(YEAR,num2,date1) end) desc,b.indate desc"
			Case 54013:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If m_fw1&""="1" Then
				tmpCondition = " AND b.ourperson="& uid &""
			end if
			cateCondition = " where isnull(ool.Mergeinx,0)>=0 " & tmpCondition & " AND (plist.qx_open = 3  OR CHARINDEX(','+CAST(b.ourperson AS VARCHAR(20))+',',','+CAST(plist.qx_intro AS VARCHAR(8000))+',') > 0) AND DATEDIFF(d, GETDATE() ,DateDelivery)<=" & m_tq1
			tmpCondition = " AND b.ourperson="& uid &""
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			"inner join M2_OutOrder b  with(nolock) on b.wwType=0 and  a.reminderConfig=" & configId & " and a.orderId = b.id " & vbcrlf &_
			"inner join M2_OutOrderlists ool  with(nolock) on ool.outID = b.ID " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"left join dbo.power plist  with(nolock) ON plist.ord = & uid & AND plist.sort1 = 5025 AND plist.sort2 = 1" & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id,b.title,convert(varchar(10),ool.DateDelivery,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
			orderBy = "order by ool.DateDelivery desc,b.indate desc"
			Case 54016:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			If m_fw1&""="1" Then
				tmpCondition = " AND b.ourperson="& uid &""
			end if
			cateCondition = " where isnull(ool.Mergeinx,0)>=0 " & tmpCondition & " AND (plist.qx_open = 3  OR CHARINDEX(','+CAST(b.ourperson AS VARCHAR(20))+',',','+CAST(plist.qx_intro AS VARCHAR(8000))+',') > 0) AND DATEDIFF(d, GETDATE() ,DateDelivery)<=" & m_tq1
'tmpCondition = " AND b.ourperson="& uid &""
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			"inner join M2_OutOrder b  with(nolock) on b.wwType=1 and a.reminderConfig=" & configId & " and a.orderId = b.id " & vbcrlf &_
			"inner join M2_OutOrderlists ool  with(nolock) on ool.outID = b.ID " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"left join dbo.power plist  with(nolock) ON plist.ord = "& uid &" AND plist.sort1 = 5026 AND plist.sort2 = 1" & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id,b.title,convert(varchar(10),ool.DateDelivery,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
			orderBy = "order by ool.DateDelivery desc,b.indate desc"
			Case 54006:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a   with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_OutOrder b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=54006 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 51003 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_WorkingFlows b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=51003 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.WFName,b.indate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.indate desc"
			Case 51005 :
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_BOM b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=51005 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.inDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 54009:
			Call fillinPower(m_qxlb,m_listqx,qOpen,"b.creator")
			cateCondition = cateCondition &" and CKUser ="& uid &_
			"   and ool.QTResult>0 and isnull(b.CkStatus,0)=0  AND DATEDIFF(d, GETDATE() ,QTDate)<=" & m_tq1
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_QualityTestings b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id " & vbcrlf &_
			"inner join (select QTID,sum(QTResult) QTResult from M2_QualityTestingLists  with(nolock) where del=1 group by QTID) ool on ool.QTID = b.ID " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id,b.title,convert(varchar(10),b.QTDate,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
			orderBy = "order by b.QTDate desc"
			Case 54004:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition =cateCondition & " and CKUser ="& uid &_
			" and ool.QTResult>0 and isnull(b.CkStatus,0)=0 AND DATEDIFF(d, GETDATE() ,QTDate)<=" & m_tq1
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_QualityTestings b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id " & vbcrlf &_
			"inner join (select QTID,sum(QTResult) QTResult from M2_QualityTestingLists  with(nolock) where del=1 group by QTID) ool on ool.QTID = b.ID " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id,b.title,convert(varchar(10),b.QTDate,23) dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
			orderBy = "order by b.QTDate desc"
			Case 57004:
			tmpCondition = ""
			cateCondition = ""
			sql = "select COUNT(*) REMIND_CNT from (" & vbcrlf &_
			" SELECT t.ID,t.Title,t.TaskDate,t.Creator,tl.QcCateid FROM dbo.M2_GXQualityTestingTask t  with(nolock) " & vbcrlf &_
			" INNER JOIN dbo.M2_GXQualityTestingTaskList tl  with(nolock) ON t.ID = tl.TaskID " & vbcrlf &_
			" WHERE tl.QCStatus != 2 GROUP BY t.ID,t.Title,t.TaskDate,t.Creator,tl.QcCateid " & vbcrlf &_
			" ) a " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"where a.QcCateid ="& uid &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "a.ID [id],a.Title as title,a.TaskDate as dt,a.TaskDate as newTag,a.ID [rid],a.Creator cateid"
			orderBy = "order by a.TaskDate desc"
			Case 56004 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_Wage_JJ b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=56004 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.CountDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 56008 :
			cateCondition = getCondition(m_qxlb,m_listqx,"b.creator")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (c.ApprovalFlowStatus in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(c.ApprovalFlowStatus in (0,1,2,3)  and b.creator="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join M2_Wage_JS b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=56008 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,b.CountDate dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.inDate desc"
			Case 45001:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(b.[status] in (0,1,2,3)  and b.cateid="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (b.[status] in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(b.[status] in (0,1,2,3)  and b.cateid="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join bankin b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=45001 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(10),b.date3 ,120) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.date7 desc"
			Case 45002:
			cateCondition = getCondition(m_qxlb,m_listqx,"b.cateid")
			cateCondition = cateCondition & "and (" & vbcrlf &_
			"(b.[status] in (0,1,2,3)  and b.cateid="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			"or (b.[status] in (2,4,5) and charindex(',"& uid &",',','+ c.SurplusApprover +',')>0) /*待审批的提醒给审批人*/" & vbcrlf &_
			"(b.[status] in (0,1,2,3)  and b.cateid="& uid &") /*审批通过或终止的提醒给添加人*/" & vbcrlf &_
			")"
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join bankout b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"inner join sp_ApprovalInstance c  with(nolock) on c.gate2=45002 and c.PrimaryKeyID = b.id and c.BillPattern in (0,1) " &_
			"where 1=1 " & vbcrlf &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id [id],b.title,convert(varchar(10),b.date3 ,120) dt,"&_
			"datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.cateid," &_
			"(case when c.ApprovalFlowStatus in (0,1,2,3) then 1 else 0 end) canCancelAlt,"&_
			" (case c.ApprovalFlowStatus when 3 then 9 when 4 then 10 when 1 then 11 when 5 then 8 when 2 then 12 else 16 end) orderStat"
			orderBy = "order by b.date7 desc"
			Case 47003:
			Call fillinPower(m_qxlb,m_listqx,qOpen,qIntro)
			tmpCondition = ""
			If qOpen = 3 Then
				cateCondition = ""
			ElseIf qOpen=1 Then
				cateCondition = " and b.id in (select distinct b.id from reminderQueue a  with(nolock) " & vbcrlf &_
				"inner join AcceptanceDraft b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
				"left join gate g1  with(nolock) on g1.ord = b.creator" & vbcrlf &_
				"left join dbo.power plist  with(nolock) ON plist.ord = "& uid &" AND plist.sort1 = 1101 AND plist.sort2 = 1" & vbcrlf &_
				"where b.del=1" & vbcrlf &_
				"and (plist.qx_open = 3 OR CHARINDEX(','+CAST(g1.ord AS VARCHAR(20))+',',','+CAST(plist.qx_intro AS VARCHAR(8000))+',') > 0))"
			else
				cateCondition = " and 1=2"
			end if
			If m_fw1&""="1" Then
				tmpCondition = " and "& uid &" = creator"
			end if
			cateCondition =  " " & tmpCondition & " " & cateCondition & " and datediff(d,getdate(),b.LimitEndDate)<=" & m_tq1 & vbcrlf
			sql = "select COUNT(*) REMIND_CNT from reminderQueue a  with(nolock) " & vbcrlf &_
			" [CANCELJOINTABLE] " & _
			"inner join AcceptanceDraft b  with(nolock) on a.reminderConfig=" & configId & " and a.orderId = b.id and b.del=1 " & vbcrlf &_
			"where b.del=1" &_
			"[CATECONDITION] [CANCELCONDITION] [ORDERBY]"
			fields = "b.id,b.sn title ,b.LimitEndDate dt,datediff(s,'"&actDate&"',a.inDate) newTag,a.id [rid],b.creator cateid"
			orderBy = "order by b.LimitEndDate"
			Case Else :
			sql = ""
			fields = ""
			End Select
			If withoutOrderBy Then
				sql = Replace(sql,"[ORDERBY]","")
			end if
			If mode = "cnt" Then
				sql = Replace(sql,"[ORDERBY]","")
			ElseIf mode = "top" Then
				sql = Replace(Replace(sql,"COUNT(*) REMIND_CNT","top " & (m_num1) & " " & fields),"[ORDERBY]", orderBy)
			ElseIf mode = "all" Then
				sql = Replace(Replace(sql,"COUNT(*) REMIND_CNT",fields),"[ORDERBY]", orderBy)
			ElseIf mode = "ids" Then
				fields = Split(fields,"[id],")(0)
				sql = Replace(Replace(sql,"COUNT(*) REMIND_CNT","top 100 percent " & fields & "id"),"[ORDERBY]", orderBy)
			ElseIf mode = "rids" Then
				fields = Split(fields,",")
				Dim findFlag
				findFlag = False
				For i = 0 To ubound(fields)
					If InStr(1,fields(i),"[rid]",1)>0 Then
						sql = Replace(Replace(sql,"COUNT(*) REMIND_CNT","top 100 percent " & fields(i)),"[ORDERBY]", orderBy)
						findFlag = True
						Exit For
					end if
				next
				If findFlag = False Then
					Response.write "sql语句里面缺少rid字段，无法提取该字段的语句"
					Response.end
				end if
			else
				Response.write "不支持的模式参数"
				Response.end
			end if
			If withoutCateCondition Then
				sql = Replace(sql,"[CATECONDITION]","")
			else
				sql = Replace(sql,"[CATECONDITION]",cateCondition)
			end if
			If withoutCancelCondition Then
				sql = Replace(Replace(sql,"[CANCELCONDITION]",""),"[CANCELJOINTABLE]","")
			else
				sql = Replace(Replace(sql,"[CANCELCONDITION]",cancelCondition),"[CANCELJOINTABLE]",cancelJoinTable)
			end if
			listSQL = sql
		end function
		Public Property Get remindCount
		Dim sql,rs
		If isEmpty(m_remindCount) Then
			If m_hasModule = False Then
				m_remindCount = 0
			else
				If isCleanMode Then
					sql = "select count(*) from reminderQueue a  with(nolock) "&_
					"inner join (" & listSQL("all_withoutCateCondition_withoutOrderBy_withoutCancelCondition") & ") b on a.id=b.rid " &_
					"where datediff(s,a.inDate,'"&dateBegin&"')>=0"
				else
					sql = listSQL("cnt")
				end if
				If displaySqlOnCount = true Then
					Response.write "<div style='border:1px solid red'>"&_
					"m_name&""(""&configId&"")---remindCount:<br>""&Replace(server.HTMLEncode(sql),vbcrlf,""<br>"")&""""&_"
					Response.write "<div style='border:1px solid red'>"&_
					"</div>"
				end if
				on error resume next
				Err.clear
				If m_usingLv2Cache And isCleanMode <> True Then
					m_remindCount = CLng(m_cacheHelper.GetCacheRecord(sql,m_cacheExpiredCondition,True,True,uid&"-"&configId&"-"&m_subCfgId&"-count")(0))
'If m_usingLv2Cache And isCleanMode <> True Then
				else
					m_remindCount = CLng(Me.cn.execute(sql)(0))
				end if
				If Err.number <> 0 Then
					Response.Clear()
					Response.write "提醒【"&m_name&"("&configId&")】读取过程中，以下语句执行错误：<br><hr>"
					Response.write Replace(server.HTMLEncode(sql),vbcrlf,"<br>") & "<hr>" & _
					"cacheExpiredCondition:<br>" & Replace(m_cacheExpiredCondition,vbcrlf,"<br>")
					Response.end
				end if
				On Error GoTo 0
			end if
		end if
		remindCount = m_remindCount
		End Property
		Public Sub remindShow
			If m_hasModule = False Then Exit Sub
			on error resume next
			Dim rs,sql,i,j
			Set rs = server.CreateObject("adodb.recordset")
			If isCleanMode Then
				If pageIndex < 1 Then pageIndex = 1
				sql = "select b.*,convert(varchar(19),a.inDate,21) inDate from reminderQueue a  with(nolock) "&_
				"inner join (" & listSQL("all_withoutCateCondition_withoutCancelCondition_withoutOrderBy") & ") b on a.id=b.rid "&_
				"where datediff(s,a.inDate,'"&dateBegin&"')>=0"
				rs.open sql,cn,1,1
				recCount = rs.RecordCount
				rs.PageSize = pageSize
				pageCount = rs.pageCount
				If CLng(pageIndex) > CLng(pageCount) Then pageIndex = pageCount
				If rs.eof = False Then
					rs.AbsolutePage = pageIndex
				end if
				If Err.number <> 0 Then
					Response.Clear()
					Response.write "提醒【"&m_name&"("&configId&")】读取过程中，以下语句执行错误：<br><hr>"
					Response.write Replace(server.HTMLEncode(sql),vbcrlf,"<br>") & "<hr>" & _
					"cacheExpiredCondition:<br>" & Replace(m_cacheExpiredCondition,vbcrlf,"<br>")
					Response.end
				end if
			else
				sql = listSQL("top")
				If m_usingLv2Cache Then
					Set rs = m_cacheHelper.GetCacheRecord(sql,m_cacheExpiredCondition,True,True,uid&"-"&configId&"-"&m_subCfgId&"list")
'If m_usingLv2Cache Then
				else
					rs.open sql,cn,1,1
				end if
				If Err.number <> 0 Then
					Response.Clear()
					Response.write "提醒【"&m_name&"("&configId&")】读取过程中，以下语句执行错误：<br><hr>"
					Response.write Replace(server.HTMLEncode(sql),vbcrlf,"<br>") & "<hr>" & _
					"cacheExpiredCondition:<br>" & Replace(m_cacheExpiredCondition,vbcrlf,"<br>")
					Response.end
				end if
			end if
			If displaySqlOnShow = true Then
				Response.write "<div style='border:1px solid red'>"&_
				"m_name&""(""&configId&"")---remindShow:<br>""&Replace(server.HTMLEncode(sql),vbcrlf,""<br>"")&""""&_"
				Response.write "<div style='border:1px solid red'>"&_
				"</div>"
			end if
			Response.write "" & vbcrlf & "             <table width=""100%"" border=""0"" cellpadding=""6"" cellspacing=""1"" " & vbcrlf & "                 "
			Response.write IIf(isCleanMode,"style='table-layout:fixed;'","")
			Response.write " bgcolor=""#C0CCDD"" class=""reminder home detailTable"" " & vbcrlf & "                    cfgId="""
			Response.write configId
			Response.write """ subId="""
			Response.write m_subCfgId
			Response.write """>" & vbcrlf & "                "
			If isCleanMode <> True Then
				Response.write "" & vbcrlf & "                     <tr class=""top tbheader OnlyHeader"">" & vbcrlf & "                              <td colspan=""2"" valign=""center"" height=""30"" onMouseOut=""RemObj.toggleBar(this,false);"" onmouseover=""RemObj.toggleBar(this,true);"">" & vbcrlf & "                                        <span style=""float:left"">"
				Response.write m_name
				Response.write "(<a href="""
				Response.write moreLinkURL()
				Response.write """ style='color:red'>"
				Response.write remindCount
				Response.write "</a>)</span>" & vbcrlf & "                                 <span class=""alt_title"" style=""float:left;display:none;"">" & vbcrlf & "                                           <a href=""javascript:void(0)"" onclick=""altChgOrder("
				Response.write m_setjmId
				Response.write ","
				Response.write m_subCfgId
				Response.write ",1,this)"" title=""左移"">←</a>" & vbcrlf & "                                               <a href=""javascript:void(0)"" onclick=""altChgOrder("
				Response.write m_setjmId
				Response.write ","
				Response.write m_subCfgId
				Response.write ",2,this)"" title=""上移"">↑</a>" & vbcrlf & "                                               <a href=""javascript:void(0)"" onclick=""altChgOrder("
				Response.write m_setjmId
				Response.write ","
				Response.write m_subCfgId
				Response.write ",3,this)"" title=""下移"">↓</a>" & vbcrlf & "                                               <a href=""javascript:void(0)"" onclick=""altChgOrder("
				Response.write m_setjmId
				Response.write ","
				Response.write m_subCfgId
				Response.write ",4,this)"" title=""右移"">→</a>" & vbcrlf & "                                               <a href=""javascript:void(0)"" onclick=""altChgOrder("
				Response.write m_setjmId
				Response.write ","
				Response.write m_subCfgId
				Response.write ",5,this)"" title=""关闭"">×</a>" & vbcrlf & "                                       </span>" & vbcrlf & "                                 <span style=""float:right;"">"
				Response.write getMoreLink()
				Response.write "</span>" & vbcrlf & "                      "
				If m_remindMode = "CYCLE" Then
					Response.write "" & vbcrlf & "                                     <span class=""alt_refreshBtn"" style=""float:right;padding-right:10px;"">" & vbcrlf & "                                               <img src=""../images/refresh.png"" class=""alt_refreshImg"" border=""0"" width=""12px"" alt=""手动更新""" & vbcrlf & "                                                    style=""cursor:pointer;"" onclick=""RemObj.refresh("
'If m_remindMode = "CYCLE" Then
					Response.write m_setjmId
					Response.write ","
					Response.write m_subCfgId
					Response.write ",this);""/>" & vbcrlf & "                                        </span>" & vbcrlf & "                                 <span class=""alt_refreshTime"" style=""float:right;font-weight:normal;padding-right:10px;"">上次更新："
					Response.write m_subCfgId
					Response.write m_lastReloadDate
					Response.write "</span>" & vbcrlf & "                                      "
				end if
				Response.write "" & vbcrlf & "                             </td>" & vbcrlf & "                   </tr>" & vbcrlf & "                   "
			Else
				Response.write "" & vbcrlf & "                     <tr class=""top"">" & vbcrlf & "                          <td width=""36"">&nbsp;</td>" & vbcrlf & "                                <td>主题</td>" & vbcrlf & "                           <td width=""150"">添加时间</td>" & vbcrlf & "                             <td width=""150"" style=""text-align:center"">" & vbcrlf & "                                  <select onchange=""loadList("
'Else
				Response.write pageIndex
				Response.write ",this.value);"">" & vbcrlf & "                                           <option value=""10"" "
				Response.write IIf(pageSize=10," selected","")
				Response.write ">每页显示10条</option>" & vbcrlf & "                                               <option value=""20"" "
				Response.write IIf(pageSize=20," selected","")
				Response.write ">每页显示20条</option>" & vbcrlf & "                                               <option value=""30"" "
				Response.write IIf(pageSize=30," selected","")
				Response.write ">每页显示30条</option>" & vbcrlf & "                                               <option value=""50"" "
				Response.write IIf(pageSize=50," selected","")
				Response.write ">每页显示50条</option>" & vbcrlf & "                                               <option value=""100"" "
				Response.write IIf(pageSize=100," selected","")
				Response.write ">每页显示100条</option>" & vbcrlf & "                                              <option value=""200"" "
				Response.write IIf(pageSize=200," selected","")
				Response.write ">每页显示200条</option>" & vbcrlf & "                                      </select>" & vbcrlf & "                               </td>" & vbcrlf & "                   </tr>" & vbcrlf & "                   "
			end if
			i = 0
			If rs.eof Then
				If remindCount > 0 Then
					Response.write "" & vbcrlf & "                     <tr><td colspan=""4"" align=""center"">您设置的显示行数为0，无信息可显示</td></tr>" & vbcrlf & "                      "
				else
					Response.write "" & vbcrlf & "                     <tr><td colspan=""4"" style=""height:107px"" align=""center"">没有信息！</td></tr>" & vbcrlf & "                  "
				end if
			else
				While rs.eof = False And ((isCleanMode = True And i < pageSize) Or isCleanMode = False)
					Response.write "" & vbcrlf & "                     <tr onMouseOut=""this.style.backgroundColor=''"" onMouseOver=""this.style.backgroundColor='efefef'"">" & vbcrlf & "                           "
					If isCleanMode = True Then
						Response.write "<td><input type='checkbox' class='delRids' value='" & rs("rid") & "'/></td>" & vbcrlf
					end if
					Response.write "" & vbcrlf & "                             <td class=""name"" width=""57%"">"
					Response.write getTitleHTML(rs)
					Response.write "</td>" & vbcrlf & "                                <td align=""center"">"
					Response.write getDtHTML(rs)
					Response.write "</td>" & vbcrlf & "                                "
					If isCleanMode = True Then
						Response.write "" & vbcrlf & "                             <td align=""center""><input type=""button"" onclick=""dropRemind("
						Response.write rs("rid")
						Response.write ");"" value=""清理此提醒"" class=""anybutton2""/></td>" & vbcrlf & "                              "
					end if
					Response.write "" & vbcrlf & "                     </tr>" & vbcrlf & "                           "
					i=i+1
					Response.write "" & vbcrlf & "                     </tr>" & vbcrlf & "                           "
					rs.movenext
				wend
			end if
			If  isCleanMode <> True Then
				If remindCount > 0 Then
					For j=i To m_num1 - 1
'If remindCount > 0 Then
						Response.write "<tr onMouseOut=""this.style.backgroundColor=''"" onMouseOver=""this.style.backgroundColor='efefef'"">"&_
						"<td class=""name"" colspan=""4"">&nbsp;</td>"&_
						"</tr>"
					next
				end if
			else
				Response.write "" & vbcrlf & "                     <tr>" & vbcrlf & "                            <td><input type='checkbox' onclick=""checkAll(this);""/></td>" & vbcrlf & "                               <td colspan=""3"" align=""right"">" & vbcrlf & "                                      <table style=""width:100%"" border=""0"" cellspacing=""0"" cellpadding=""0"">" & vbcrlf & "                                           <tr>" & vbcrlf & "                                                    <td width=""100px"">" & vbcrlf & "                                                             <input type=""button"" value=""批量清理"" class=""anybutton2"" onclick=""dropRemind();""/>" & vbcrlf & "                                                      </td>" & vbcrlf & "                                                   <td align=""right"">" & vbcrlf & "                                                                共"
				Response.write recCount
				Response.write "条&nbsp;"
				Response.write pageSize
				Response.write "/页&nbsp;"
				Response.write pageIndex
				Response.write "/"
				Response.write pageCount
				Response.write "页" & vbcrlf & "                                                             <input type=""text"" id=""jppgidx"" style=""width:40px"" maxlength=""8"" value="""
				Response.write pageIndex
				Response.write """ " & vbcrlf & "                                                                  onfocus=""this.select();""" & vbcrlf & "                                                                  onkeydown=""pageKeyup(this);""" & vbcrlf & "                                                                      title=""按回车可翻页""" & vbcrlf & "                                                              />" & vbcrlf & "                                                              <input type=""button"" value=""跳转"" class=""page"" onclick=""if(!isNaN($('#jppgidx').val())) loadList($('#jppgidx').val(),"
				Response.write pageSize
				Response.write ")""/>" & vbcrlf & "                                                               <input type=""button"" value=""首页"" class=""page"" onclick=""loadList("
				Response.write 1&","&pageSize
				Response.write ");""/>" & vbcrlf & "                                                              <input type=""button"" value=""上页"" class=""page"" onclick=""loadList("
				Response.write (pageIndex-1)&","&pageSize
				Response.write ");""/>" & vbcrlf & "                                                              <input type=""button"" value=""下页"" class=""page"" onclick=""loadList("
				Response.write (pageIndex+1)&","&pageSize
				Response.write ");""/>" & vbcrlf & "                                                              <input type=""button"" value=""尾页"" class=""page"" onclick=""loadList("
				Response.write pageCount&","&pageSize
				Response.write ");""/>" & vbcrlf & "                                                      </td>" & vbcrlf & "                                           </tr>" & vbcrlf & "                                   </table>" & vbcrlf & "                                </td>" & vbcrlf & "                   </tr>" & vbcrlf & "                   "
			end if
			Response.write "" & vbcrlf & "              </table>" & vbcrlf & "                "
			If Err.number<>0 Then
				dim errtxt
				errtxt = err.Description
				if instr(errtxt,"未找到项目")>0 then
					errtxt = errtxt & " <br>sql查询需要提供【rid】,【cateid】,【title】,【newTag】列，请检查SQL是否正确支持。"
				end if
				Response.write Replace("以下语句执行错误：<br>" & server.HTMLEncode(sql) & "<div style='padding:10px;background-color:#ffff00'>错误提示语：" & errtxt & "</div>", vbcrlf , "<br>")
				errtxt = errtxt & " <br>sql查询需要提供【rid】,【cateid】,【title】,【newTag】列，请检查SQL是否正确支持。"
				cn.close
				Response.end
			end if
		end sub
		Public Function getTitleHTML(ByRef rs)
			Dim ttArr,ttStr
			Select Case m_setjmId
			Case 7:
			ttArr = Split(rs("title"),Chr(11)&Chr(12))
			If m_isMobileMode Then
				getTitleHTML = getTitleHTML & ttArr(0)'rs("title")
			else
				getTitleHTML = getTitleHTML & "<span style='float:left;color:#5b7cae'>"&getTitleLink(ttArr(0),rs("id"),rs("cateid")) & "</span>"
				getTitleHTML = getTitleHTML & "<span style='float:right;'>("&ttArr(1)&")</span>"
			end if
			Case 225:
			Dim showTitle2
			showTitle2 = rs("title")
			If InStr(rs("title"),"@code:") > 0 Then
				showTitle2 = eval(REPLACE(rs("title"),"@code:",""))
			end if
			If m_isMobileMode Then
				getTitleHTML = getTitleHTML & showTitle2
			else
				getTitleHTML = getTitleHTML & "<table width=""100%"" border=""0"" cellspacing=""0"" cellpadding=""0"">"
				getTitleHTML = getTitleHTML & "     <tr>"&_
				"<td style=""background-Color:transparent;"">" &_
				"getTitleLink(showTitle2,rs(""id""),rs(""cateid""))" &_
				"<span style='float:right;'>"&rs("WorkLong")&"小时</span>" &_
				"IIf(rs(""newTag"")>=0,""<span class='alt_tx'></span>"","""")" &_
				"</td>" &_
				"</table>"
			end if
			Case Else:
			Dim showTitle
			showTitle = rs("title")
			If InStr(rs("title"),"@code:") > 0 Then
				showTitle = eval(REPLACE(rs("title"),"@code:",""))
			end if
			If m_isMobileMode Then
				getTitleHTML = getTitleHTML & showTitle
			else
				getTitleHTML = getTitleHTML & "<table width=""100%"" border=""0"" cellspacing=""0"" cellpadding=""0"">"
				getTitleHTML = getTitleHTML & "     <tr>"&_
				"<td style=""background-Color:transparent;color:#5b7cae"">" &_
				"getTitleLink(showTitle,rs(""id""),rs(""cateid""))" &_
				"IIf(rs(""newTag"")>=0,""<span class='alt_tx'></span>"","""")" &_
				"</td>"
			end if
			If hasStatField(rs) And showStatusField Then
				If rs("orderStat")>0 Then
					If m_isMobileMode Then
						getTitleHTML = getTitleHTML & Chr(11) & Chr(12) & "(" & getOrderStat(rs("orderStat")) & ")"
					else
						getTitleHTML = getTitleHTML & "<td width='80px' style=""background-Color:transparent;"">("&getOrderStat(rs("orderStat"))&")</td>"
'getTitleHTML = getTitleHTML & Chr(11) & Chr(12) & "(" & getOrderStat(rs("orderStat")) & ")"
					end if
				end if
			end if
			If Not m_isMobileMode Then
				getTitleHTML = getTitleHTML & "     </tr>" &_
				"</table>"
			end if
			End Select
		end function
		Public Function getDtHTML(ByRef rs)
			Dim dtArr,dtStr,dtType
			If isCleanMode Then
				getDtHTML = getDtHTML & rs("inDate")
			else
				If configId = 7 Then
					If m_isMobileMode Then
						dtArr = Split(rs("dt"),"@")
						dtStr = dtArr(0)
						dtType = dtArr(1)
						getDtHTML = getDtHTML & dtStr
					else
						Dim nlObj
						Set nlObj = New hlxNongLiGongLi
						dtArr = Split(rs("dt"),"@")
						dtStr = dtArr(0)
						dtType = dtArr(1)
						If dtType="2" Then
							getDtHTML = getDtHTML & "农历"&nlObj.getYearStr(dtStr)&"年"&_
							"nlObj.NongliMonth(nlObj.getMonthStr(dtStr))&""月""&_"
							nlObj.NongliDay(nlObj.getDayStr(dtStr))
						ElseIf dtType="3" Then
							getDtHTML = getDtHTML & "农历"&nlObj.getYearStr(dtStr)&"年闰"&_
							"nlObj.NongliMonth(nlObj.getMonthStr(dtStr))&""月""&_"
							nlObj.NongliDay(nlObj.getDayStr(dtStr))
						else
							getDtHTML = getDtHTML & "公历"&nlObj.getYearStr(dtStr)&"年"&_
							"nlObj.getMonthStr(dtStr)&""月""&_"
							nlObj.getDayStr(dtStr)&"日"
						end if
					end if
				else
					getDtHTML = getDtHTML & rs("dt")
				end if
			end if
			Dim canCancelAlt : canCancelAlt = False
			If m_canCancel = True And isCleanMode <> True And Not m_isMobileMode Then
				If hasAltField(rs) Then
					If CLng(rs("canCancelAlt")) = 1 Then
						canCancelAlt = True
					else
						canCancelAlt = False
					end if
				else
					canCancelAlt = True
				end if
				If canCancelAlt = True Then
					getDtHTML = getDtHTML & _
					"<img src='../images/alt3.gif' " &_
					"style='cursor:pointer;' " &_
					"onClick=""RemObj.cancel('" & rs("id") & "','" & rs("rid") & "'," & m_setjmId & "," & m_subCfgId & ")"" " &_
					"alt='取消提醒'"  &_
					"border='0'" &_
					"/>"
				end if
			end if
		end function
		Public Sub appendRemind(oid)
			Call appendRemindWithStat(oid,0)
		end sub
		Public Sub appendRemindWithStat(oid,stat)
			Call appendRemindWithInfo(oid,stat,"")
		end sub
		Public Sub appendRemindWithInfo(oid,stat,inf)
			Dim sql
			oid = Replace(oid," ","")
			If oid = "" Then
				Response.write "方法调用缺少必要的参数"
				Response.end
			end if
			sql = "select [id] from reminderQueue a  with(nolock) where reminderConfig=" & configId & " and subCfgId=" & m_subCfgId &_
			" And orderId in (" & oid & ") and orderStat=" & stat
			Me.cn.execute "delete reminderPersons where reminderId in ("&sql&")"
			Me.cn.execute "update reminderQueue set inDate =getdate() where id in ("&oid&")"
			Me.cn.execute "insert into reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,orderStat,otherInfo,inDate) " & _
			"select "&configId&","&m_subCfgId&_
			",cast(short_str as int),0,"&stat&",'"&inf&"',getdate() from dbo.split('"&oid&"',',') where cast(short_str as int) not in ("&Replace(sql,"[id]","[orderID]")&")"
		end sub
		Public Sub dropRemindByOID(oid)
			Call dropRemindByOidAndStat(oid,0)
		end sub
		Public Sub dropRemindByOidAndStat(oid,stat)
			If m_remindMode <> "PASSIVE" And m_remindMode <> "CYCLE" Then
				Response.write m_remindMode & "模式下不支持此过程调用！"
				Response.end
			end if
			oid = Replace(oid," ","")
			If oid = "" Then
				Response.write "方法调用缺少必要的参数"
				Response.end
			end if
			Me.cn.execute "delete reminderPersons where reminderId in " & _
			"(select id from reminderQueue  with(nolock) where orderId in (" & oid & ") and subCfgId="&m_subCfgId&_
			" and orderStat="&stat&" and reminderConfig=" & configId &")"
			Me.cn.execute "delete reminderQueue where orderId in (" & oid & ") and subCfgId="&m_subCfgId&_
			" and orderStat="&stat&" and reminderConfig=" & configId
		end sub
		Public Sub dropRemindByRID(rid)
			If m_remindMode <> "PASSIVE" And m_remindMode <> "CYCLE" Then
				Response.write m_remindMode & "模式下不支持此过程调用！"
				Response.end
			end if
			If rid = "" Then
				Response.write "方法调用缺少必要的参数"
				Response.end
			end if
			Me.cn.execute "delete reminderPersons where reminderId in (" & rid & ")"
			Me.cn.execute "delete reminderQueue where id in (" & rid & ")"
		end sub
		Public Sub cancelRemind(rid)
			Dim sql,rs,id
			If rid&""<>"0" And rid&""<>"" Then
				sql = iif(instr(rid,",")>0 , " id in (" & rid & ")", "id=" & rid)
				sql = "select id from reminderQueue  with(nolock) where " & sql
				Set rs=Me.cn.execute(sql)
				If rs.eof=True Then rs.close : Exit Sub
				While rs.eof = False
					id = CLng(rs(0))
					If canCancelOrder(id) Then
						If m_remindMode = "PASSIVE" Or m_remindMode = "CYCLE" Then
							If m_jointly = True Then
								If m_remindMode = "CYCLE" Then
									Me.cn.execute "insert into reminderPersons(reminderId,cateid) " & vbcrlf &_
									"select distinct "&id&",isnull(cateid," & uid & ") from setjm a  with(nolock) where ord="&m_setjmId&" " & vbcrlf &_
									"and not exists (select top 1 1 from reminderPersons  with(nolock) where reminderId="&id&" and cateid=isnull(a.cateid," & uid & "))"
								Else
									Call Me.dropRemindByRID(rid)
								end if
							else
								Me.cn.execute "if not exists (select 1 from reminderPersons  with(nolock) where reminderId=" & id & " and cateid=" & uid & ") " & vbcrlf &_
								"insert into reminderPersons(reminderId,cateid) values("&id&","&uid&")"
							end if
						end if
					end if
					rs.movenext
				wend
				rs.close
				set rs = nothing
			end if
		end sub
		Public Sub cancelRemindByOid(oid)
			Dim sql,rs,id,result,success
			If oid&""<>"0" And oid&""<>"" Then
				sql = "select distinct rid,cast(title as nvarchar(200)) as title from (" & listSql("all_withoutOrderBy") & ") a where [id] in (" & oid & ")"
				Set rs=Me.cn.execute(sql)
				If rs.eof=True Then Exit Sub
				result = ""
				While rs.eof = False
					id = CLng(rs("rid"))
					If canCancelOrder(id) Then
						If m_remindMode = "PASSIVE" Or m_remindMode = "CYCLE" Then
							If m_jointly = True Then
								If m_remindMode = "CYCLE" Then
									Me.cn.execute "insert into reminderPersons(reminderId,cateid) " & vbcrlf &_
									"select distinct "&id&",isnull(cateid," & uid & ") from setjm a  with(nolock) where ord="&m_setjmId&" " & vbcrlf &_
									"and not exists (select top 1 1 from reminderPersons  with(nolock) where reminderId="&id&" and cateid=isnull(a.cateid," & uid & ") )"
								Else
									Call Me.dropRemindByRID(rid)
								end if
							else
								Me.cn.execute "if not exists (select 1 from reminderPersons  with(nolock) where reminderId=" & id & " and cateid=" & uid & ") " & vbcrlf &_
								"insert into reminderPersons(reminderId,cateid) values("&id&","&uid&")"
							end if
						end if
						success = "true"
					else
						success = "false"
					end if
					result = result & "{""id"":"&id&",""name"":"""&IIF(Len(rs("title"))>0,rs("title"),"无标题")&""",""success"":"&success&"}"
					rs.movenext
					If rs.eof=False Then result = result & ","
				wend
				If Len(result)>0 Then
					Response.write "[" & result & "]"
				end if
			end if
		end sub
		Public Sub reloadRemind(withoutLimit)
			Dim sql,condition,qOpen,qIntro,fields,orderBy,rs,cfgId,cateid,rType,rAdvance,topNum,tmpCondition,lastReloadDate
			Me.cn.cursorLocation = 3
			If withoutLimit <> True Then
				sql = "select lastReloadDate from reminderConfigs  with(nolock) where setjmId=" & m_setjmId
				Set rs=Me.cn.execute(sql)
				If rs.eof Then
					Response.write "读取配置失败，请联系管理员"
					Response.end
				else
					lastReloadDate = now
					If datediff("s",rs(0),lastReloadDate) < RELOAD_INTERVAL_LIMIT And datediff("s",rs(0),lastReloadDate) > 0 Then
						Response.write "请不要频繁进行更新操作"
						Response.end
					end if
				end if
			else
				lastReloadDate = now
			end if
			sql = "select top 0 id,reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate into #reminderQueue from reminderQueue"
			Me.cn.execute sql
			Set rs = Me.cn.execute("select isnull(max(tq1),0) tq1 from setjm  with(nolock) where intro='1' and ord=" & m_setjmId)
			If rs.eof Then
				rAdvance = 0
			else
				rAdvance = rs(0)
			end if
			Select Case m_setjmId
			Case 7:
			Dim nowDays : nowDays = datediff("d",CDate(year(date)&"-01-01"),date)
'Case 7:
			sql = "exec erp_PersonBirthdayUpdate "&year(date)&",0"
			Me.cn.execute sql
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select "&m_setjmId&",0,a.ord,year(getdate())+(case when isnull(a.bDays - "&nowDays&",0)=0 then 0 else 1 end)*100000,"&_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"a.bDays - "&nowDays&",getdate() " & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"From person a  with(nolock) " & vbcrlf &_
			"where bDays - "&nowDays&" >=0 and bDays - "&nowDays&" <= " & rAdvance & " " & vbcrlf &_
			"From person a  with(nolock) " & vbcrlf &_
			"and a.ord not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"order by a.bDays,a.ord"
			Me.cn.execute sql
			Case 9:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select " & m_setjmId & ",0,id,datediff(d,'2000-01-01',date2),datediff(d,getdate(),date2),getdate() from caigoulist a with(nolock)  " & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"where del=1 and alt=1 " & vbcrlf & _
			"and a.id not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"and datediff(d,getdate(),date2)<=" & rAdvance & " and datediff(m,getdate(),date2)>=-" & AUTO_CLEAR_INTERVAL & " " & vbcrlf &_
			"and a.id not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"order by date2 desc,date7 desc"
			Me.cn.execute sql
			Case 11:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select "&m_setjmId&",0,ord,datediff(d,'2000-01-01',date1),datediff(d,getdate(),date1),getdate() from payback a with(nolock)  " & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"where del=1 and complete='1' " & vbcrlf &_
			"and datediff(d,getdate(),date1)<=" & rAdvance & " " & vbcrlf &_
			"and a.ord not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"order by date1 desc,date7 desc"
			Me.cn.execute sql
			Case 209:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select "&m_setjmId&",0,id,datediff(d,'2000-01-01',applydate),datediff(d,getdate(),applydate),getdate() from payoutsure a  with(nolock) " & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"where del=1 and (complete='0' and status in (-1,1) or complete='3')" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"and datediff(d,getdate(),applydate)<=" & rAdvance & " " & vbcrlf &_
			"and a.id not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"order by applydate desc,InDate desc"
			Me.cn.execute sql
			Case 12:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select "&m_setjmId&",0,ord,datediff(d,'2000-01-01',date1),datediff(d,getdate(),date1),getdate() from payout a  with(nolock) " & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"where del=1 and complete='1' " & vbcrlf &_
			"and datediff(d,getdate(),date1)<=" & rAdvance & " " & vbcrlf &_
			"and a.ord not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"order by date1 desc,date7 desc"
			Me.cn.execute sql
			Case 21:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select " & m_setjmId & ",0,ord,datediff(d,'2000-01-01',date2),datediff(d,getdate(),date2),getdate() from contract a with(nolock)  " & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"where del=1 " & vbcrlf & _
			"and a.ord not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"and datediff(d,getdate(),date2)<=" & rAdvance & " and datediff(m,getdate(),date2)>=-" & AUTO_CLEAR_INTERVAL & " " & vbcrlf &_
			"and a.ord not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"order by date2 desc,date7 desc"
			Me.cn.execute sql
			Case 23:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select " & m_setjmId & ",0,id,datediff(d,'2000-01-01',date2),datediff(d,getdate(),date2),getdate() from contractlist a with(nolock)  " & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"where a.del=1 and a.num2<a.num1 " & vbcrlf & _
			"and a.id not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"and datediff(d,getdate(),date2)<=" & rAdvance & " and datediff(m,getdate(),date2)>=-" & AUTO_CLEAR_INTERVAL & " " & vbcrlf &_
			"and a.id not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"order by date2 desc,date7 desc"
			Me.cn.execute sql
			Case 68:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select " & m_setjmId & ",0,ku.id," & vbcrlf &_
			"MaintainUnit*10000 + MaintainNum * 10 + cast(ISNULL(m.date1,ISNULL(ku.datesc,'1970-1-1')) as int)," & vbcrlf &_
			"select " & m_setjmId & ",0,ku.id," & vbcrlf &_
			"datediff(hh,'"&date&"',ISNULL(m.date1,ISNULL(ku.datesc,'1970-1-1'))) + " & vbcrlf &_
			"select " & m_setjmId & ",0,ku.id," & vbcrlf &_
			"case " & vbcrlf &_
			"when MaintainUnit = 1 then MaintainNum " & vbcrlf &_
			"when MaintainUnit = 2 then MaintainNum * 24 " & vbcrlf &_
			"when MaintainUnit = 3 then MaintainNum * 24 * 7 " & vbcrlf &_
			"when MaintainUnit = 4 then MaintainNum * 24 * 30 " & vbcrlf &_
			"when MaintainUnit = 5 then MaintainNum * 24 * 365 " & vbcrlf &_
			"end " & vbcrlf &_
			",getdate() " & vbcrlf &_
			"from product p  with(nolock) " & vbcrlf &_
			"inner join ku  with(nolock) on p.ord=ku.ord and ku.num2<>0 and LEN(ku.datesc)>0 and p.del=1 " & vbcrlf &_
			"and ISNULL(p.MaintainNum,0)>0 and datalength(p.RemindPerson)>0 " & vbcrlf &_
			"left join ( " & vbcrlf &_
			"select m1.ord yhord,m2.ord,m2.ku,m3.date1 from maintain m1  with(nolock) " & vbcrlf &_
			"inner join ( " & vbcrlf &_
			"select maintain,ord,ku from maintainlist  with(nolock) " & vbcrlf &_
			"where del=1 " & vbcrlf &_
			"group by maintain,ord,ku " & vbcrlf &_
			") m2 on m2.maintain=m1.ord " & vbcrlf &_
			"inner join ( " & vbcrlf &_
			"select m2.ord, m2.ku, max(m1.date1) date1 " & vbcrlf &_
			"from maintain m1  with(nolock) " & vbcrlf &_
			"inner join maintainlist m2  with(nolock) on m2.maintain=m1.ord and m2.del=1 " & vbcrlf &_
			"inner join product p  with(nolock) on p.ord=m2.ord and p.del=1 " & vbcrlf &_
			"and ISNULL(p.MaintainNum,0)>0 and datalength(p.RemindPerson)>0 " & vbcrlf &_
			"where m1.del=1 and isnull(m1.status,0)=0 " & vbcrlf &_
			"group by m2.ord,m2.ku " & vbcrlf &_
			")m3 on m2.ord=m3.ord and m2.ku=m3.ku " & vbcrlf &_
			"where m1.del=1 and isnull(m1.status,0)=0 and m1.date1=m3.date1 " & vbcrlf &_
			") m on m.ku=ku.id and p.ord=m.ord " & vbcrlf &_
			"where isnull(ku.locked,0)=0 and len(ISNULL(m.date1,ku.datesc))>0 " & vbcrlf &_
			"and datediff(hh,'"&date&"',ISNULL(m.date1,ISNULL(ku.datesc,'1970-1-1'))) + " & vbcrlf &_
			"where isnull(ku.locked,0)=0 and len(ISNULL(m.date1,ku.datesc))>0 " & vbcrlf &_
			"case " & vbcrlf &_
			"when MaintainUnit = 1 then MaintainNum " & vbcrlf &_
			"when MaintainUnit = 2 then MaintainNum * 24 " & vbcrlf &_
			"when MaintainUnit = 3 then MaintainNum * 24 * 7 " & vbcrlf &_
			"when MaintainUnit = 4 then MaintainNum * 24 * 30 " & vbcrlf &_
			"when MaintainUnit = 5 then MaintainNum * 24 * 365 " & vbcrlf &_
			"end <= " & (rAdvance * 24)
			Me.cn.execute sql
			Case 105:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select "&m_setjmId&",0,ProductID,datediff(mi,'2014-01-01',getdate()),b.UnitId,getdate() " & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"from o_product a  with(nolock) " & vbcrlf &_
			"inner join ( " & vbcrlf &_
			"select replace(prod_id,' ','') as ProductID,replace(prod_unit,' ','') as UnitId,sum(prod_num) as ku_num " & vbcrlf &_
			"from o_kuinlist a  with(nolock) " & vbcrlf &_
			"inner join o_kuin b  with(nolock) on a.reg_fid=b.id " & vbcrlf &_
			"group by prod_id,prod_unit " & vbcrlf &_
			") b on a.id=b.ProductID " & vbcrlf &_
			"where " & vbcrlf &_
			"(case when Ku_num>prod_more and prod_more<>0 then "&_
			"(convert(decimal,(Ku_num-prod_more))/convert(decimal,prod_more))*100 else 0 end) > 0 " & vbcrlf &_
			"(case when Ku_num>prod_more and prod_more<>0 then "&_
			" or " & vbcrlf &_
			"(case when Ku_num<prod_less and prod_less<>0 then "&_
			"(convert(decimal,(prod_less-Ku_num))/convert(decimal,prod_less))*100 else 0 end) > 0 "
'(case when Ku_num<prod_less and prod_less<>0 then &_
			Me.cn.execute sql
			Case 106:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select distinct "&m_setjmId&",0,ord,isnull(min(type1),0) * 100000 + min(backdays),min(backdays),getdate() " & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"from dbo.erp_sale_getBackList('"&date&"',0) where canremind=1 and backdays<=reminddays " & vbcrlf &_
			"group by ord"
			Me.cn.execute sql
			Case 120:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select distinct "&m_setjmId&",0,a.ord,datediff(d,'2014-01-01',getdate()),datediff(d,'" & date & "',datepro+isnull(b.num2,0)),getdate() "&_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"from tel as a WITH(NOLOCK) "& vbcrlf &_
			"inner join num_bh b on a.sort1=b.kh and a.cateid=b.cateid "& vbcrlf &_
			"where a.profect1=1 "& vbcrlf &_
			"and datediff(d,'" & date & "',datepro+isnull(b.num2,0)) <= isnull(b.num3,0) "& vbcrlf &_
			"where a.profect1=1 "& vbcrlf &_
			"and a.del=1 and isnull(a.sp,0)=0 and a.sort3=1"
			Me.cn.execute sql
			Case 121:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select distinct "&m_setjmId&",0,ord,datediff(d,'2014-01-01',getdate()),datediff(d,'2014-01-01',isnull(nextReply,EndReplyDate)),getdate() "&_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"from dbo.erp_sale_getWillReplyList('"&date&"',0) "
			Me.cn.execute sql
			Case 10:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT " & m_setjmId & ",0,a.id,DATEDIFF(d,'2000-01-01',a.date2),DATEDIFF(d,GETDATE(),a.date2),GETDATE() FROM kujhlist a  with(nolock) " & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"WHERE a.del = 1 AND a.num1 > a.num2 " & vbcrlf & _
			"AND a.id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"AND DATEDIFF(d,GETDATE(),a.date2)<=" & rAdvance & " AND DATEDIFF(m,GETDATE(),a.date2)>=-" & AUTO_CLEAR_INTERVAL & " " & vbcrlf &_
			"AND a.id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"ORDER BY a.date2 DESC,a.date7 DESC"
			Me.cn.execute sql
			Case 20:
			storelist_sort5 = "0"
			Set rsUsConfig= conn.execute("select isnull(tvalue,'0') tvalue from home_usConfig where name='storelist_sort5' and isnull(uid, 0) =" &  session("personzbintel2007") )
			If rsUsConfig.eof= False Then
				storelist_sort5=rsUsConfig("tvalue")
			end if
			rsUsConfig.close
			showKuLimitZeroSQL = ""
			if storelist_sort5 = "0" then
				showKuLimitZeroSQL = " and (isnull(a.alert1,0)>0 or isnull(a.alert2,0)>0)"
			end if
			showzore =0
			Set rsUsConfig= conn.execute("select (case cast(tvalue as varchar(10)) when '1' then 1 else 0 end) v from home_usConfig  with(nolock) where uid="& session("personzbintel2007") &" and name='storelist_sort1' ")
			if rsUsConfig.eof=false  then
				showzore = rsUsConfig("v").value
			end if
			rsUsConfig.close
			unkuinwarning = 0
			if showzore="1" then
				Set rsUsConfig= conn.execute("select (case cast(tvalue as varchar(10)) when '1' then 1 else 0 end) v from home_usConfig  with(nolock) where uid="& session("personzbintel2007") &" and name='storelist_warning' ")
				if rsUsConfig.eof=false  then
					unkuinwarning = rsUsConfig("v").value
				end if
				rsUsConfig.close
			end if
			showZeroSQL = ""
			if showzore = "0" then
				showZeroSQL = " and isnull(b.ku_num,0)>0 "
			else
				if unkuinwarning="0" then
					showZeroSQL = " and exists(select 1 from ku where ord =a.ord) "
				end if
			end if
			sql = "" & vbcrlf &_
			"select cateid from setjm a " & vbcrlf &_
			"inner join (" & vbcrlf &_
			"select ord from (" & vbcrlf &_
			"select ord from power  with(nolock) where (sort1=31 and sort2=13 and qx_open>0) " & vbcrlf &_
			"union all " & vbcrlf &_
			"select ord from power  with(nolock) where (sort1=31 and sort2=16 and qx_open>0) " & vbcrlf &_
			") a group by ord having count(*)=2 " & vbcrlf &_
			"union " & vbcrlf &_
			"select ord from (" & vbcrlf &_
			"select ord from power  with(nolock) where (sort1=32 and sort2=13 and qx_open>0) " & vbcrlf &_
			"union all " & vbcrlf &_
			"select ord from power  with(nolock) where (sort1=32 and sort2=16 and qx_open>0) " & vbcrlf &_
			") a group by ord having count(*)=2" & vbcrlf &_
			") b on a.cateid=b.ord " & vbcrlf &_
			"where a.intro=1 and a.ord=" & m_setjmId
			Set rs = Me.cn.execute(sql)
			While rs.eof = False
				sql = "" & vbcrlf &_
				"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
				"SELECT " & m_setjmId & ",0,a.ord,DATEDIFF(mi,'2000-01-01',a.date7),DATEDIFF(d,GETDATE(),a.date7),GETDATE() " & vbcrlf &_
				"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
				"FROM (" & vbcrlf &_
				"SELECT a.ord,addcate,title," & vbcrlf & _
				"(CASE WHEN Isnull(aleat1, 0) = 0 THEN 0 ELSE Isnull(aleat1, 0) END )  AS alert1, " & vbcrlf & _
				"(CASE WHEN Isnull(aleat2, 0) = 0 THEN 0 ELSE Isnull(aleat2, 0) END )  AS alert2, " & vbcrlf & _
				"date7,Isnull(ku_num, 0) ku_num " & vbcrlf & _
				"FROM product a  with(nolock) " & vbcrlf & _
				"LEFT JOIN (" & vbcrlf &_
				"SELECT ord,Sum(numjb) AS ku_num FROM ("&vbcrlf &_
				"SELECT suba.ord," & vbcrlf & _
				"(CASE " & vbcrlf & _
				"WHEN suba.unit = subb.unitjb THEN num2 " & vbcrlf & _
				"ELSE num2 * Isnull((SELECT TOP 1 bl FROM jiage WHERE  product = suba.ord AND unit = suba.unit), 0) " & vbcrlf & _
				"END) numjb " & vbcrlf & _
				"FROM ku suba  with(nolock) " & vbcrlf & _
				"INNER JOIN product subb  with(nolock) ON suba.ord = subb.ord " & vbcrlf & _
				"inner join sortck subc  with(nolock) on subc.id = suba.ck "& vbcrlf &_
				"and subc.del=1 "& vbcrlf &_
				"and ("& vbcrlf &_
				"charindex('," & rs(0) & ",',','+replace(cast(subc.intro as varchar(4000)),' ','')+',')>0 "& vbcrlf &_
				"and ("& vbcrlf &_
				"or replace(cast(subc.intro as varchar(4000)),' ','') = '0'"& vbcrlf &_
				")" & vbcrlf &_
				") subaa " & vbcrlf & _
				"GROUP BY ord " & vbcrlf & _
				") AS b ON a.ord = b.ord " & vbcrlf & _
				"WHERE a.del = 1 "& showZeroSQL&" AND (isnull(ku_num,0)<=aleat1 or isnull(ku_num,0)>aleat2)" & vbcrlf & _
				") AS a " & vbcrlf & _
				"WHERE not a.date7 is NULL "& showKuLimitZeroSQL &" " & vbcrlf & _
				"AND a.ord NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
				"ORDER BY a.date7 DESC"
				Me.cn.execute sql
				rs.movenext
			wend
			rs.close
			Case 49:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT " & m_setjmId & ",0,a.id,DATEDIFF(mi,'2000-01-01',a.lastdate)+100000*isnull(a.zhouqi,0),DATEDIFF(d,GETDATE(),a.lastdate),GETDATE() " & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"FROM " & vbcrlf & _
			"(SELECT a.id,a.personID, b.username,a.lastdate,a.zhouqi, " & vbcrlf & _
			"  (CASE a.unit " & vbcrlf & _
			"     WHEN 1 THEN Dateadd(yyyy, a.zhouqi, a.lastdate) " & vbcrlf & _
			"     WHEN 2 THEN Dateadd(qq, a.zhouqi, a.lastdate) " & vbcrlf & _
			"     WHEN 3 THEN Dateadd(m, a.zhouqi, a.lastdate) " & vbcrlf & _
			"     WHEN 4 THEN Dateadd(ww, a.zhouqi, a.lastdate) " & vbcrlf & _
			"     WHEN 5 THEN Dateadd(d, a.zhouqi, a.lastdate) " & vbcrlf & _
			"     ELSE NULL " & vbcrlf & _
			"  END ) AS nextdate, " & vbcrlf & _
			"  Isnull(a.alt, 1) AS alt " & vbcrlf & _
			"FROM   hr_person_health a  with(nolock) " & vbcrlf & _
			"       INNER JOIN hr_person b  with(nolock) ON b.userID = a.personID " & vbcrlf & _
			"WHERE  b.del = 0 AND a.lastdate IS NOT NULL AND a.zhouqi IS NOT NULL AND b.nowstatus NOT IN (2,3,4) " & vbcrlf & _
			") a " & vbcrlf & _
			"WHERE 1 = 1 AND a.alt < 2 " & vbcrlf & _
			"AND a.id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"AND DATEDIFF(d,GETDATE(),a.nextdate)<=" & rAdvance &_
			"AND DATEDIFF(m,GETDATE(),a.nextdate)>=-" & AUTO_CLEAR_INTERVAL & " " & vbcrlf &_
			"AND DATEDIFF(d,GETDATE(),a.nextdate)<=" & rAdvance &_
			"ORDER BY a.lastdate DESC"
			Me.cn.execute sql
			Case 66:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT " & m_setjmId & ",0,a.id,DATEDIFF(mi,'2000-01-01',a.date2),DATEDIFF(d,GETDATE(),a.date2),GETDATE() " & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"FROM " & vbcrlf & _
			"(SELECT z.id,t.name,t.cateid,s.title,z.date2,ISNULL(z.alt, '') alt " & vbcrlf & _
			"FROM   tel t  with(nolock) " & vbcrlf & _
			"INNER JOIN sortFieldsContent z " & vbcrlf & _
			"       ON z.ord = t.ord " & vbcrlf & _
			"          AND z.del = 1 " & vbcrlf & _
			"          AND t.del = 1 " & vbcrlf & _
			"          AND z.sort = 1 " & vbcrlf & _
			"          AND t.sort3 = 2 " & vbcrlf & _
			"          AND t.isNeedQuali = 1 " & vbcrlf & _
			"          AND ISNULL(t.status_sp_qualifications, 0) = 0 " & vbcrlf & _
			"          AND LEN(z.date2) > 0 " & vbcrlf & _
			"          AND LEN(CAST(z.share AS VARCHAR(10))) > 0 " & vbcrlf & _
			"          AND CHARINDEX(',"& uid &",', ',' + CAST(z.share AS VARCHAR(4000)) + ',') > 0 " & vbcrlf & _
			"          AND LEN(CAST(z.share AS VARCHAR(10))) > 0 " & vbcrlf & _
			"INNER JOIN sortClass s " & vbcrlf & _
			"       ON z.sortid = s.id " & vbcrlf & _
			"          AND ISNULL(s.isStop, 0) = 0 " & vbcrlf & _
			"          AND s.sort1 = 2 " & vbcrlf & _
			") a " & vbcrlf & _
			"WHERE 1 = 1 " & vbcrlf & _
			"AND a.id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"AND DATEDIFF(d,GETDATE(),a.date2)<=" & rAdvance & " AND DATEDIFF(m,GETDATE(),a.date2)>=-" & AUTO_CLEAR_INTERVAL & " " & vbcrlf &_
			"AND a.id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"ORDER BY a.date2 DESC"
			Me.cn.execute sql
			Case 67:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT " & m_setjmId & ",0,a.id,DATEDIFF(mi,'2000-01-01',a.date2),DATEDIFF(d,GETDATE(),a.date2),GETDATE() " & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"FROM " & vbcrlf & _
			"(SELECT z.id,t.name,t.cateid,s.title,z.date2,ISNULL(z.alt, '') alt " & vbcrlf & _
			"FROM   tel t  with(nolock) " & vbcrlf & _
			"INNER JOIN sortFieldsContent z " & vbcrlf & _
			"       ON z.ord = t.ord " & vbcrlf & _
			"          AND z.del = 1 " & vbcrlf & _
			"          AND t.del = 1 " & vbcrlf & _
			"          AND z.sort = 1 " & vbcrlf & _
			"          AND t.sort3 = 1 " & vbcrlf & _
			"          AND t.isNeedQuali = 1 " & vbcrlf & _
			"          AND ISNULL(t.status_sp_qualifications, 0) = 0 " & vbcrlf & _
			"          AND LEN(z.date2) > 0 " & vbcrlf & _
			"          AND LEN(CAST(z.share AS VARCHAR(10))) > 0 " & vbcrlf & _
			"          AND CHARINDEX(',"& uid &",', ',' + CAST(z.share AS VARCHAR(4000)) + ',') > 0 " & vbcrlf & _
			"          AND LEN(CAST(z.share AS VARCHAR(10))) > 0 " & vbcrlf & _
			"INNER JOIN sortClass s " & vbcrlf & _
			"       ON z.sortid = s.id " & vbcrlf & _
			"          AND ISNULL(s.isStop, 0) = 0 " & vbcrlf & _
			"          AND s.sort1 = 2 " & vbcrlf & _
			") a " & vbcrlf & _
			"WHERE 1 = 1 " & vbcrlf & _
			"AND a.id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"AND DATEDIFF(d,GETDATE(),a.date2)<=" & rAdvance & " AND DATEDIFF(m,GETDATE(),a.date2)>=-" & AUTO_CLEAR_INTERVAL & " " & vbcrlf &_
			"AND a.id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"ORDER BY a.date2 DESC"
			Me.cn.execute sql
			Case 213:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT "&m_setjmId&",0,a.id,DATEDIFF(d,'2000-01-01',a.date1),DATEDIFF(d,GETDATE(),a.date1),GETDATE() " & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"FROM ( " & vbCrLf &_
			"  SELECT a.id,a.date1,a.date7 FROM paybackinvoice a   with(nolock) " & vbCrLf &_
			"  INNER JOIN sortbz b ON b.id = a.bz " & vbCrLf &_
			"  WHERE a.del = 1 AND isInvoiced = 0  AND ISNULL(a.cateid,0) <> 0 " & vbCrLf &_
			") a " & vbCrLf &_
			"WHERE 1 =1 " & vbcrlf &_
			"AND DATEDIFF(d,GETDATE(),a.date1)<=" & rAdvance & " " & vbcrlf &_
			"AND a.id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"ORDER BY a.date1 DESC,a.date7 DESC"
			Me.cn.execute sql
			Case 214:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT "&m_setjmId&",0,id,DATEDIFF(d,'2000-01-01',date1),DATEDIFF(d,GETDATE(),date1),GETDATE() " & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"FROM payoutInvoice  with(nolock) WHERE del = 1 AND isInvoiced=0 " & vbCrLf &_
			"AND DATEDIFF(d,GETDATE(),date1)<=" & rAdvance & "  " & vbcrlf &_
			"AND id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"ORDER BY date1 DESC,date7 DESC"
			Me.cn.execute sql
			Case 52:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT "&m_setjmId&",0,id,RemindNum*100+RemindUnit*10+cast(getdate() as int)," & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"isnull(daysFromNow,0) - " & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"isnull(case " & vbcrlf &_
			"when RemindUnit = 1 then RemindNum " & vbcrlf &_
			"when RemindUnit = 2 then RemindNum * 24 " & vbcrlf &_
			"when RemindUnit = 3 then RemindNum * 24 * 7 " & vbcrlf &_
			"when RemindUnit = 4 then RemindNum * 24 * 30 " & vbcrlf &_
			"when RemindUnit = 5 then RemindNum * 24 * 365 " & vbcrlf &_
			"end,0)" & vbcrlf &_
			",GETDATE() " & vbcrlf &_
			"FROM ( " & vbCrLf &_
			"SELECT p.ord, p.title, p.addcate, k.dateyx, k.id,ISNULL(p.RemindUnit,0) RemindUnit,ISNULL(p.RemindNum,0) RemindNum," & vbcrlf &_
			"datediff(hh,getdate(),k.dateyx) daysFromNow " & vbcrlf &_
			"FROM ku k  with(nolock) " & vbcrlf &_
			"INNER JOIN product p  with(nolock) ON p.ord = k.ord " & vbcrlf &_
			"INNER JOIN sortck ck  with(nolock) ON k.ck = ck.ord AND ck.del = 1 " & vbcrlf &_
			"WHERE (CAST(ISNULL(ck.intro,'') AS VARCHAR(4000))='0' OR CHARINDEX(',"&uid&",',','+CAST(ck.intro AS VARCHAR(4000))+',')>0) " & vbcrlf &_
			"INNER JOIN sortck ck  with(nolock) ON k.ck = ck.ord AND ck.del = 1 " & vbcrlf &_
			"AND p.del = 1 " & vbcrlf &_
			"AND k.num2 > 0 " & vbcrlf &_
			"AND p.RemindNum > 0 " & vbcrlf &_
			"AND k.dateyx IS NOT NULL " & vbcrlf &_
			"AND ISNULL(k.locked, 0) = 0 " & vbcrlf &_
			") a " & vbCrLf &_
			"WHERE 1 =1 " & vbcrlf &_
			"AND daysFromNow <= " & (rAdvance*24) & " " & vbcrlf &_
			"AND ord NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"ORDER BY dateyx DESC"
			Me.cn.execute sql
			Case 51:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT "&m_setjmId&",0,id,DATEDIFF(d,'2000-01-01',ld_rettime),DATEDIFF(d,GETDATE(),ld_rettime),GETDATE() " & vbcrlf &_
			"FROM ( " & vbCrLf &_
			"  SELECT a.id, c.bk_name, a.ld_rettime, d.addcateid " & vbcrlf &_
			"  FROM O_Lendbookmx a with(nolock)  " & vbcrlf &_
			"  LEFT JOIN O_Lendbook d  with(nolock) ON a.Ld_fid=d.id " & vbcrlf &_
			"  LEFT JOIN O_regbook c  with(nolock) ON a.Ld_bkid=c.id " & vbcrlf &_
			"  WHERE a.ld_num > (SELECT isnull(sum(Ret_num),0) AS Ret_num FROM O_RetBookmx WHERE Ret_bkid=a.id) " & vbcrlf &_
			") a " & vbCrLf &_
			"WHERE 1 =1 " & vbcrlf &_
			"AND DATEDIFF(d,GETDATE(),ld_rettime)<=" & rAdvance & " " & vbcrlf &_
			"AND id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"ORDER BY ld_rettime DESC"
			Me.cn.execute sql
			Case 59:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT "&m_setjmId&",0,id,DATEDIFF(d,'2000-01-01',Reguldate),DATEDIFF(d,GETDATE(),Reguldate),GETDATE() " & vbcrlf &_
			"FROM ( " & vbCrLf &_
			"  SELECT a.ID,a.Reguldate " & vbcrlf &_
			"  FROM hr_person a  with(nolock) " & vbcrlf &_
			"  WHERE  a.nowStatus = 5 AND a.del = 0 " & vbcrlf &_
			") a " & vbCrLf &_
			"WHERE 1 =1 " & vbcrlf &_
			"AND DATEDIFF(d,GETDATE(),Reguldate)<=" & rAdvance & " " & vbcrlf &_
			"AND id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"ORDER BY Reguldate DESC"
			Me.cn.execute sql
			Case 215:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT "&m_setjmId&",0,chanceID,DATEDIFF(d,'2000-01-01',GETDATE()) * 1000 + backdays,backDays,GETDATE() " & vbcrlf &_
			"FROM dbo.erp_chance_callbackList('"& Now() &"') a" & vbCrLf &_
			"WHERE 1 =1 AND a.backdays <= ISNULL((SELECT ISNULL(tq1,5) FROM setjm WHERE cateid = "& uid &" AND ord = "&m_setjmId&" AND intro = '1'),5)  " & vbcrlf &_
			"AND chanceID NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"ORDER BY chanceID DESC"
			Me.cn.execute sql
			Case 300:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT "&m_setjmId&",0,id,ISNULL(DATEDIFF(d,'2000-01-01',date4),0),ISNULL(DATEDIFF(d,GETDATE(),date4),0),GETDATE() " & vbcrlf &_
			"FROM document with(nolock)  " & vbCrLf &_
			"WHERE del = 1 AND validity = 2 AND (sp = 0 AND cateid_sp = 0) AND addcate = "& uid &" AND date4 is not null  " & vbcrlf &_
			"AND id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"ORDER BY id DESC"
			Me.cn.execute sql
			Case 301:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT "&m_setjmId&",0,l.id,ISNULL(DATEDIFF(d,'2000-01-01',l.l_date4),0),ISNULL(DATEDIFF(d,GETDATE(),l.l_date4),0),GETDATE() " & vbcrlf &_
			"FROM documentlist l  with(nolock) " & vbCrLf &_
			"inner join document d on d.id = l.document "&  vbCrLf &_
			"WHERE d.del = 1 and l.del=1 AND l.l_validity = 2 AND (d.sp = 0 AND d.cateid_sp = 0) AND l.l_date4 is not null  " & vbcrlf &_
			"AND l.id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"ORDER BY l.id DESC"
			Me.cn.execute sql
			Case 155:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT " & m_setjmId & ",0,a.iss_id,DATEDIFF(mi,'2000-01-01',a.iss_endtime),DATEDIFF(d,GETDATE(),a.iss_endtime),GETDATE() " & vbcrlf &_
			"FROM " & vbcrlf & _
			"O_insure a  with(nolock) " & vbcrlf & _
			"WHERE a.del=1 " & vbcrlf & _
			"AND a.iss_id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"AND DATEDIFF(d,GETDATE(),a.iss_endtime)<=" & rAdvance & " AND DATEDIFF(m,GETDATE(),a.iss_endtime)>=-" & AUTO_CLEAR_INTERVAL & " " & vbcrlf &_
			"ORDER BY a.iss_endtime DESC"
			Me.cn.execute sql
			Case 17:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT " & m_setjmId & ",0,a.id,DATEDIFF(mi,'2000-01-01',a.date3),DATEDIFF(d,GETDATE(),a.date3),GETDATE() " & vbcrlf &_
			"FROM " & vbcrlf & _
			"(select *,(select TOP 1 id from hr_person  with(nolock) where del = 0 AND userid=ord) as id from gate_person) a " & vbcrlf & _
			"WHERE 1 = 1 " & vbcrlf & _
			"and a.id IS NOT NULL " & vbcrlf & _
			"AND a.id NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"AND DATEDIFF(d,GETDATE(),a.date3)<=" & rAdvance & " AND DATEDIFF(m,GETDATE(),a.date3)>=-" & AUTO_CLEAR_INTERVAL & " " & vbcrlf &_
			"ORDER BY a.date3 DESC"
			Me.cn.execute sql
			Case 156:
			sql = "" & vbcrlf &_
			"INSERT INTO #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"SELECT " & m_setjmId & ",0,a.ord,DATEDIFF(mi,'2000-01-01',a.date3),DATEDIFF(d,GETDATE(),a.date3),GETDATE() " & vbcrlf &_
			"FROM " & vbcrlf & _
			"gate a " & vbcrlf & _
			"WHERE 1 = 1 " & vbcrlf & _
			"and a.ord IS NOT NULL " & vbcrlf & _
			"AND a.ord NOT IN (SELECT orderId FROM #reminderQueue WHERE reminderConfig = "&m_setjmId&")" & vbcrlf &_
			"AND DATEDIFF(d,GETDATE(),a.date3)<=" & rAdvance & " AND DATEDIFF(m,GETDATE(),a.date3)>=-" & AUTO_CLEAR_INTERVAL & " " & vbcrlf &_
			"ORDER BY a.date3 DESC"
			Me.cn.execute sql
			Case 224:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select " & m_setjmId & ",0,id,datediff(d,'2000-01-01',dateEnd),datediff(d,getdate(),dateEnd),getdate() from M_WorkAssigns a " & vbcrlf &_
			"left join (" & vbcrlf & _
			"  --需要质检的工序中-质检通过数量最少的数量值" & vbcrlf & _
			"  select M_WorkAssigns , min(pnum) as pnum " & vbcrlf & _
			"  from " & vbcrlf & _
			"(" & vbcrlf & _
			"            select n.id as M_WorkAssigns, w.id ,sum(isnull(r.num1,0)) as pnum " & vbcrlf & _
			"            from M_WorkAssigns n with(nolock) " & vbcrlf & _
			"            inner join M_WFP_Assigns w on w.WFid = n.WProID and w.result=1 --工艺流程中需要质检的工序" & vbcrlf & _
			"            from M_WorkAssigns n with(nolock) " & vbcrlf & _
			"            left join M_ProcedureProgres r on r.[Procedure]=w.id and r.del=0 and r.result = 1 --质检通过" & vbcrlf & _
			"            from M_WorkAssigns n with(nolock) " & vbcrlf & _
			"            group by n.id , w.id" & vbcrlf & _
			"    ) s group by M_WorkAssigns" & vbcrlf & _
			") d on d.M_WorkAssigns = a.id" & vbcrlf & _
			"left join (" & vbcrlf & _
			"    select m.WAID , sum(NumQualified) as qnum ,max(m.MPDate) as newInDate" & vbcrlf & _
			"   from M_MaterialProgres m " & vbcrlf & _
			"   inner join M_MaterialProgresDetail t on t.MPID = m.id and m.del=0 and t.del=0" & vbcrlf & _
			"   group by m.WAID" & vbcrlf & _
			") c on c.WAID = a.id" & vbcrlf & _
			"where a.del=0 " & vbcrlf &_
			"and (case when (isnull(d.pnum,-1)=-1 or isnull(d.pnum,-1)>=a.NumMake ) and isnull(c.qnum,0)>=a.NumMake then 1 else 0 end) = 0 " & vbcrlf &_
			"and a.id not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"and datediff(d,getdate(),dateEnd)<=" & rAdvance & " and datediff(m,getdate(),dateEnd)>=-" & AUTO_CLEAR_INTERVAL & " " & vbcrlf &_
			"order by dateEnd desc,indate desc"
			Me.cn.execute sql
			Case 47003:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select " & m_setjmId & ",0,id,datediff(d,'2000-01-01',LimitEndDate),datediff(d,getdate(),LimitEndDate),getdate() from AcceptanceDraft a  with(nolock) " & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"where a.del=1 " & vbcrlf &_
			"and a.id not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"and datediff(d,getdate(),LimitEndDate)<=" & rAdvance & " and datediff(m,getdate(),LimitEndDate)>=-" & AUTO_CLEAR_INTERVAL & " " & vbcrlf &_
			"and a.id not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"order by LimitEndDate"
			Me.cn.execute sql
			Case 51011:
			sql = "" & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"select " & m_setjmId & ",0,id,datediff(d,'2000-01-01',date1),datediff(d,getdate(),date1),getdate() from dbo.M2_maintain a  with(nolock) " & vbcrlf &_
			"insert into #reminderQueue(reminderConfig,subCfgId,orderId,reloadFlag,daysFromNow,inDate) " & vbcrlf &_
			"where 1=1 " & vbcrlf & _
			"and a.id not in (select orderId from #reminderQueue where reminderConfig="&m_setjmId&")" & vbcrlf &_
			"AND DATEDIFF(d, GETDATE() ,(CASE Unit2 WHEN 0 THEN DATEADD(MINUTE,num2,date1) " & vbcrlf &_
			"WHEN 1 THEN DATEADD(HOUR,num2,date1) WHEN 2 THEN DATEADD(DAY,num2,date1) WHEN 3 THEN DATEADD(MONTH,num2,date1) " & vbcrlf &_
			"WHEN 4 THEN DATEADD(YEAR,num2,date1) end))<=" & rAdvance & " " & vbcrlf &_
			"order by date1 desc"
			Me.cn.execute sql
			End Select
			sql = "select * from setjm  with(nolock) where intro='1' and ord=" & m_setjmId
			Set rs = Me.cn.execute(sql)
			While rs.eof = False
				cfgId = rs("ord")
				cateid = rs("cateid")
				rType = rs("fw1")
				rAdvance = rs("tq1")
				topNum = rs("num1")
				Select Case cfgId
				Case Else :
				End Select
				rs.movenext
			wend
			cn.execute "exec erp_UpdateReminderQueue " & configId & "," & m_subCfgId & ",'" & lastReloadDate & "'"
		end sub
		Public Function getRemindIdByOID(oid)
			getRemindIdByOID = getRemindIdByOIDAndStat(oid,0)
		end function
		Public Function getRemindIdByOIDAndStat(oid,stat)
			Dim sql,rs
			sql = "select top 1 id from reminderQueue  with(nolock) where reminderConfig=" & configId & " and subCfgId="&m_subCfgId&_
			" and orderId=" & oid & " and orderStat=" & stat & " and id in " &_
			"("&listSql("rids")&")"
			Set rs = Me.cn.execute(sql)
			If rs.eof Then
				getRemindIdByOIDAndStat = -1
'If rs.eof Then
			else
				getRemindIdByOIDAndStat = CLng(rs(0))
			end if
		end function
		Public Function canCancelOrder(rid)
			If rid <= 0 Then
				canCancelOrder = False
			else
				Dim rs,sql
				sql = Me.listSql("all_withoutOrderBy")
				If InStr(sql,"canCancelAlt")>0 Then
					sql = "select top 1 * from (" & sql & ") a where rid=" & rid & " and canCancelAlt = 1"
				else
					sql = "select top 1 * from (" & sql & ") a where rid=" & rid
				end if
				Set rs = cn.execute(sql)
				If rs.eof Then
					canCancelOrder = False
				else
					canCancelOrder = Me.cn.execute("select top 1 reminderId from reminderPersons  with(nolock) where reminderId = " & rid & " and cateid=" & uid).eof
				end if
			end if
		end function
		Private Function getConditionByFW(s1,s2,cateField)
			Dim qOpen,qIntro
			Call fillInPower(s1,s2,qOpen,qIntro)
			if m_fw1&""="0" Then
				if qOpen = 3 then
					getConditionByFW = ""
				elseif qOpen = 1 then
					getConditionByFW=" and "&cateField&" in ("&qIntro&") "
				else
					getConditionByFW=" and 1=2 "
				end if
			else
				getConditionByFW=" and "&cateField&"="&uid&" and ("&qOpen&"=3 or ("&qOpen&"=1 and CHARINDEX(','+cast("&cateField&" as varchar)+',', ',"&qIntro&",') > 0))"
'getConditionByFW=" and 1=2 "
			end if
		end function
		Private Function getConditionWithShare(s1,s2,cateField,shareField)
			Dim qOpen,qIntro
			Call fillInPower(s1,s2,qOpen,qIntro)
			if qOpen = 3 then
				getConditionWithShare = ""
			elseif qOpen = 1 then
				getConditionWithShare = " AND ("&cateField&" IN ("&qIntro&") OR ("&shareField&" = '1' OR CHARINDEX(',"& uid &",', ',' + "& shareField &" + ',') > 0  ))"
'elseif qOpen = 1 then
			else
				getConditionWithShare = " AND ("&shareField&" = '1' OR CHARINDEX(',"& uid &",', ',' + "& shareField &" + ',') > 0  )"
'elseif qOpen = 1 then
			end if
		end function
		Private Function getCondition(s1,s2,cateField)
			Dim qOpen,qIntro
			Call fillInPower(s1,s2,qOpen,qIntro)
			if qOpen = 3 then
				getCondition = ""
			elseif qOpen = 1 then
				getCondition=" and "&cateField&" in ("&qIntro&") "
			else
				getCondition=" and "&cateField&"=0 and ("&qOpen&"=3 or ("&qOpen&"=1 and CHARINDEX(','+cast("&cateField&" as varchar)+',', ',"&qIntro&",') > 0))"
'getCondition=" and "&cateField&" in ("&qIntro&") "
			end if
		end function
		Private Sub findPower(arrPower,ByVal find_s1,ByVal find_s2,ByRef qx_open,ByRef qx_intro,ByRef qx_type)
			Dim i
			For i = 0 To ubound(arrPower,2)
				If find_s1 = arrPower(0,i) And find_s2 = arrPower(1,i) Then
					qx_open = arrPower(2,i)
					qx_intro = arrPower(3,i)
					qx_type = arrPower(4,i)
					Exit Sub
				end if
			next
			qx_open = 0
			qx_intro = "-255"
			qx_open = 0
			qx_type = 1
		end sub
		Private Sub fillInPower(s1,s2,ByRef qx_open,ByRef qx_intro)
			Dim rsPower
			If m_UsingPowerCache Then
				Call findPower(Global_Power,s1,s2,qx_open,qx_intro,"")
			else
				Set rsPower = Me.cn.execute("select qx_open,qx_intro from power  with(nolock) where ord="&uid&" and sort1="&s1&" and sort2="&s2)
				if rsPower.eof then
					qx_open = 0
					qx_intro = "-222"
					qx_open = 0
				else
					qx_open=rsPower("qx_open")
					If rsPower("qx_intro") & "" = "" Or Len(rsPower("qx_intro"))=0 Then
						qx_intro = "-222"
'If rsPower("qx_intro") & "" = "" Or Len(rsPower("qx_intro"))=0 Then
					else
						qx_intro = rsPower("qx_intro")
					end if
				end if
				rsPower.close
				set rsPower=Nothing
			end if
		end sub
		Public Sub initByRs(ByRef rs)
			Dim subRs
			configId = rs("id")
			m_subSql = rs("subSql")
			m_subCfgId = rs("subCfgId")
			If m_subCfgId > 0 Then
				Set subRs = Me.cn.execute(m_subSql&" and id="&m_subCfgId)
				If subRs.eof Then
					m_hasModule = False
					Exit Sub
				else
					m_name = Me.cn.execute(m_subSql&" and id="&m_subCfgId)(1)
				end if
			else
				m_name = rs("name")
			end if
			m_setjmId = rs("setjmId")
			m_mCondition = rs("mCondition")
			m_remindMode = rs("remindMode")
			m_qxlb = rs("qxlb")
			m_listqx = rs("listqx")
			m_detailqx = rs("detailqx")
			m_num1 = rs("num1")
			m_opened = (rs("opened") = "1")
			m_gate1 = rs("gate1")
			m_tq1 = rs("tq1")
			If m_tq1 & "" = "" Then  m_tq1 = 0
			m_fw1 = rs("fw1")
			m_moreLinkUrl = rs("moreLinkUrl")
			m_detailLinkUrl = rs("detailLinkUrl")
			m_moreLinkUrl_mobile = rs("moreLinkUrl_mobile")
			m_detailLinkUrl_mobile = rs("detailLinkUrl_mobile")
			m_canCancel = rs("canCancel")
			m_jointly = rs("jointly")
			m_titleMaxLength = rs("titleMaxLength")
			m_lastReloadDate = rs("lastReloadDate")
			m_MOrderSetting = rs("MOrderSetting")
			m_MBusinessType = rs("MBusinessType")
			m_cacheExpiredCondition = rs("cacheExpiredCondition") & ""
			m_canTQ = rs("canTQ")
			m_fwSetting = rs("fwSetting")
			If m_usingLv2Cache = True And Len(m_cacheExpiredCondition) > 0 Then
				m_cacheExpiredCondition = base64.URLDecode(base64.Base64Decode(m_cacheExpiredCondition))
				m_cacheExpiredCondition = m_cacheExpiredCondition & ";" & vbcrlf &_
				"select reminderId from ReminderPersons a  with(nolock) "&_
				"inner join reminderQueue b  with(nolock) on a.reminderId=b.id and a.cateid=" & uid &" "&_
				"and b.reminderConfig="&configId&";" & vbcrlf &_
				"select '" & Date &"' from qxlb  with(nolock) where sort1=1 "
			end if
			If Len(m_mCondition) = 0 Then
				m_hasModule = True
			else
				on error resume next
				m_hasModule = eval(base64.URLDecode(base64.Base64Decode(m_mCondition)))
				If Abs(Err.number)>0 Then
					m_hasModule = False
				end if
				On Error GoTo 0
			end if
			If m_usingLv2Cache = True Then
				Set m_cacheHelper = server.createobject(ZBRLibDLLNameSN & ".PageClass")
				Call m_cacheHelper.init(Me)
			end if
		end sub
		Public Sub init(cfgId,subCfgId)
			If InStr(cfgId,",") > 0 Then
				cfgId = Split(cfgId,",")(0)
			end if
			If Not isnumeric(cfgId) Or cfgId&""="" Then
				Response.write "参数cfgId不正确，类初始化失败！"
				Response.end
			end if
			configId = cfgId
			Dim sql,rs
			If subCfgId > 0 Then
				m_subCfgId = subCfgId
				sql = "select a.*,isnull(b.num1,4) num1,isnull(b.intro,'0') opened,isnull(b.gate1,1) gate1,b.tq1,b.fw1,"&subCfgId&" subCfgId from reminderConfigs a  with(nolock) " &_
				"left join setjm b  with(nolock) on a.setjmId=b.ord and b.cateid="&uid&" and b.subCfgId="&subCfgId&" where a.id=" & configId
			else
				sql = "select a.*,isnull(b.num1,4) num1,isnull(b.intro,'0') opened,isnull(b.gate1,1) gate1,b.tq1,b.fw1,0 subCfgId from reminderConfigs a  with(nolock) " &_
				"left join setjm b  with(nolock) on a.setjmId=b.ord and b.cateid="&uid&" where a.id=" & configId
			end if
			Set rs = Me.cn.execute(sql)
			If rs.eof Then
				Response.write "错误：未能读取到提醒配置信息！"
				Response.end
			end if
			Call initByRs(rs)
			rs.close
			Set rs=Nothing
		end sub
		Private Function getMoreLink()
			getMoreLink = "<a href=""" & moreLinkURL() & """><font style='font-weight:normal;'>更多&gt;&gt;&gt;</font></a>"
'Private Function getMoreLink()
		end function
		Public Function moreLinkURL()
			moreLinkURL = replaceTemplete(iif(m_isMobileMode,m_moreLinkURL_mobile,m_moreLinkURL))
		end function
		Private Function replaceTemplete(v)
			Dim r
			r = Replace(v,"@subId",m_subCfgId)
			r = Replace(r,"@date",date)
			r = Replace(r,"@MOrderId",m_MOrderSetting)
			r = Replace(r,"@cfgId",m_setjmId)
			replaceTemplete = r
		end function
		Private Function getTitleLink(title,orderId,cateid)
			If orderId&"" = "" Or orderId&"" = "0" Then
				getTitleLink = "【已删除数据】"
				Exit Function
			end if
			title = regEx.replace(title&"","")
			Dim url : url = m_detailLinkUrl
			If m_titleMaxLength > 0 Then
				If Len(title) > m_titleMaxLength Then title = Left(title,m_titleMaxLength-1) & "..."
'If m_titleMaxLength > 0 Then
			end if
			If title = "" Then title = "【无标题】"
			If Len(url&"") = 0 Then
				getTitleLink = title
				Exit Function
			end if
			If InStr(url,"@encodeId") > 0 Then
				url = Replace(url,"@encodeId",base64.pwurl(orderId))
			else
				url = Replace(url,"@id",orderId)
			end if
			url = replaceTemplete(url)
			If hasDetailPower(cateid) Then
				getTitleLink = "<a href='javascript:void(0)' class='remind_detail_link' onclick=""RemObj.openWin('" & url & "','remindWin"&configId&"');"">" & title & "</a>"
			else
				getTitleLink = title
			end if
		end function
		Public Function hasDetailPower(cateid)
			If m_detailqx = 0 Then
				hasDetailPower = True
			ElseIf existsPowerIntro(m_qxlb,m_detailqx,cateid) Then
				hasDetailPower = True
			else
				hasDetailPower = False
			end if
		end function
		Private Function getOrderStat(st)
			Select Case st
			Case 1:
			getOrderStat = "共享"
			Case 2:
			getOrderStat = "取消共享"
			Case 8 :
			getOrderStat = "审批中"
			Case 9 :
			getOrderStat = "待提交"
			Case 10:
			getOrderStat = "待审批"
			Case 11:
			getOrderStat = "审批通过"
			Case 12:
			getOrderStat = "审批退回"
			Case 16:
			getOrderStat = "未通过"
			Case 13:
			getOrderStat = "待审核"
			Case 14:
			getOrderStat = "审核通过"
			Case 15:
			getOrderStat = "审核退回"
			case 17:
			getOrderStat = "无需审批"
			Case Else
			End Select
		end function
		Private Function hasFieldInRs(ByRef r,ByVal fd)
			Dim kk
			For kk=0 To r.fields.count - 1
'Dim kk
				If r.fields(kk).name = fd Then
					hasFieldInRs = True
					Exit Function
				end if
			next
			hasFieldInRs = False
		end function
		Private Function openPower(x1,x2)
			Dim sql1,rs1,isOpen
			if x1<>"" and x2<>"" Then
				If m_UsingPowerCache Then
					Call findPower(Global_Power,x1,x2,isOpen,"","")
					openPower = isOpen
				else
					set rs1=server.CreateObject("adodb.recordset")
					sql1="select qx_open from power  with(nolock)  where ord="&uid&" and sort1="&x1&" and sort2="&x2&""
					rs1.open sql1,cn,1,1
					if rs1.eof Then
						openPower=0
						If x2=19 Then
							If cn.execute("select 1 from power with(nolock)  where ord="&uid&" and sort1="&x1&"").eof Then openPower = 1
						end if
					else
						openPower=rs1("qx_open")
					end if
					rs1.close
					set rs1=nothing
				end if
			else
				openPower=0
			end if
		end function
		Private Function IIf(e,v1,v2)
			If e = True Then
				iif = v1
			else
				iif = v2
			end if
		end function
		Public Function existsPowerIntro(byval sort1,byval sort2, byval CreatorID)
			Dim sql_qx,qx_type,qx_open,qx_intro
			dim i , item, hs, rs_qx
			hs = false
			for i = 0 to ubound(m_existsPowerIntro)
				if isarray(m_existsPowerIntro(i)) then
					item = m_existsPowerIntro(i)
					if item(0) = sort1 and item(1) = sort2 then
						qx_type = item(2)
						qx_open = item(3)
						qx_intro = item(4)
						hs = true
						exit for
					end if
				end if
			next
			if hs = false then
				sql_qx="select isnull(sort,0) as sort from qxlblist  with(nolock) where sort1=" & sort1 & " and sort2="& sort2
				set rs_qx=cn.execute(sql_qx)
				if not rs_qx.eof then
					qx_type=rs_qx(0)
				else
					qx_type=0
				end if
				rs_qx.close
				sql_qx="select isnull(qx_open,0) as qx_open,isnull(qx_intro,'') as qx_intro from [power]  with(nolock) where sort1=" & sort1 & " and sort2="&sort2&" and ord=" & uid
				set rs_qx=cn.execute(sql_qx)
				if not rs_qx.eof then
					qx_open=rs_qx(0)
					qx_intro=rs_qx(1)
				else
					qx_open=0
					qx_intro=""
				end if
				rs_qx.close
				set rs_qx=nothing
				redim preserve m_existsPowerIntro(m_expiCount)
				m_existsPowerIntro(m_expiCount) = split(sort1 & chr(1) & sort2 & chr(1) & qx_type & chr(1) & qx_open & chr(1) & qx_intro, chr(1))
				m_expiCount = m_expiCount+ 1
			end if
			if len(qx_open & "") = 0 then qx_open = 0
			qx_open = clng(qx_open)
			if qx_type = 1 then
				existsPowerIntro = (qx_open = 1)
			else
				if qx_open = 3 then
					existsPowerIntro = true
				elseif qx_open = 1 then
					existsPowerIntro =  CheckIntro(qx_intro,CreatorID&"")>0 And CreatorID > 0
				else
					existsPowerIntro = false
				end if
			end if
		end function
		private function CheckIntro(str1,str2)
			dim ids: ids = split(replace(str2 & ""," ",""),",")
			dim inx : inx = 0
			for n=0 to ubound(ids)
				if ids(n)&""<>"" and ids(n)&""<>"0" then
					inx = instr(","&replace(str1 & ""," ","")&",",","& ids(n) &",")
					if inx>0 then exit for
				end if
			next
			CheckIntro = inx
		end function
		Public Property Get user
		user = session("personzbintel2007") & ""
		If Len(user) = 0 Then
			user = request.querystring("__sys_uid_sign")
			if isnumeric(user)= false then
				user = 0
			else
				user = clng(user)
			end if
		end if
		End Property
		Public Property Get isAdmin
		dim rs
		if len(is_admin) = 0 then
			Set rs = cn.execute("select top1 from gate  with(nolock) where ord=" & me.user)
			if rs.eof then
				is_admin = false
			else
				is_admin = (rs.fields(0).value & "" = "1")
			end if
			rs.close
		end if
		isAdmin = is_admin
		End Property
		Public Property Get isSupperAdmin
		Dim rs
		If Len(is_supperadmin) = 0 Then
			If Me.isAdmin  Then
				Set rs = cn.execute("select qx_open from power  with(nolock) where sort1=66 and sort2=12 and ord=" & Me.User & " and qx_open=1")
				is_supperadmin = Not rs.eof
				rs.close
			else
				is_supperadmin = false
			end if
		end if
		isSupperAdmin = is_supperadmin
		End Property
		Private Function HTMLDecode(fString)
			if not isnull(fString) Then
				fString = replace(fString, "&gt;", ">")
				fString = replace(fString, "&lt;", "<")
				fString = Replace(fString, "&nbsp;",CHR(32) )
				fString = Replace(fString, "&quot;",CHR(34) )
				fString = Replace(fString, "&#39;",CHR(39) )
				fString = Replace(fString, "",CHR(13))
				fString = Replace(fString, "</P><P>",CHR(10) & CHR(10))
				fString = Replace(fString, "<br>",CHR(10))
				HTMLDecode = fString
			end if
		end function
	End Class
	Class StringBuffer
		Private m_idx
		Private m_contents
		Private m_maxIdx
		Public Sub push(v)
			m_contents(m_idx) = v : m_idx = m_idx + 1
'Public Sub push(v)
			If m_idx > m_maxIdx Then
				m_maxIdx = m_maxIdx + 500
'If m_idx > m_maxIdx Then
				ReDim Preserve m_maxIdx(m_maxIdx)
			end if
		end sub
		Public Property Get toString
		toString = Join(m_contents,"")
		End Property
		Private Sub Class_Initialize
			m_idx = 0
			m_maxIdx = 500
			ReDim m_contents(m_maxIdx)
		end sub
		Private Sub Class_Teriminate
			Erase m_contents
		end sub
	End Class
	Class ReminderList
		Private m_reminders()
		Public m_rIdx
		Public m_popIdx
		Public Sub push(remindObj)
			m_rIdx = m_rIdx + 1
'Public Sub push(remindObj)
			ReDim Preserve m_reminders(m_rIdx)
			Set m_reminders(m_rIdx) = remindObj
		end sub
		Public Function pop
			If Me.hasRemind = False Then Exit Function
			Set pop = m_reminders(m_popIdx)
			m_popIdx = m_popIdx + 1
			Set pop = m_reminders(m_popIdx)
		end function
		Public Property Get reminders
		reminders = m_reminders
		End Property
		Public Property Get hasRemind
		hasRemind = m_rIdx >=0 And m_popIdx <= m_rIdx
		End Property
		Private Sub Class_Initialize
			m_rIdx = -1
'Private Sub Class_Initialize
			m_popIdx = 0
		end sub
		Private Sub Class_Teriminate
			Dim i
			For i = 0 To ubound(m_reminders)
				Set m_reminders(i) = Nothing
			next
		end sub
	end class
	
	Response.expires=-1
	Response.AddHeader"pragma","no-cache"
	Response.AddHeader"cache-control","no-store"
	sqltext="delete from pay where complete=11 and sp is null and cateid_sp is null and addcate = " & session("personzbintel2007")
	conn.execute(sqltext)
	sqltext="delete from payjk where spstate=5 and del=3"
	sqltext="delete from payjk where spstate=5 and sp_id is null and gate_sp is null AND del <> 7"
	if request("ret")<>"" then
		m1=request("ret")
		m2=request("ret2")
	else
		m1=request("rett")
		m2=request("rett2")
	end if
	typ=request("typ")
	A=request("A")
	B=request("B")
	C=request("C")
	D=request("D")
	title=request("title")
	intro=request("intro")
	money1=request("money1")
	money12=request("money12")
	money2=request("money2")
	money22=request("money22")
	returnMoney1 = Request("returnMoney1")
	returnMoney2 = Request("returnMoney2")
	dkMoney1 = Request("dkMoney1")
	dkMoney2 = Request("dkMoney2")
	NoreturnMoney1 = Request("NoreturnMoney1")
	NoreturnMoney2 = Request("NoreturnMoney2")
	tjr=request("tjr")
	jkr=request("jkr")
	listbz=request("listbz")
	px=request("px")
	remind = Request("remind")
	if open_6_1=3 then
		Str_Result=""
	elseif open_6_1=1 then
		Str_Result=" and a.sorce2 in ("&intro_6_1&")"
	else
		Str_Result=" and a.sorce2=0"
	end if
	if listbz<>"" then
		listbz=cdbl(listbz)
		Str_Result = Str_Result + "and a.bz="&listbz&" "
		listbz=cdbl(listbz)
	end if
	if typ="" or isnull(typ) then
		typ="0"
	end if
	if typ="3333333" or typ="5555555" then
		new_list="<span class='alt_tx'></span>"
		timelg=session("timezbintel2007")
		if typ="3333333" and timelg<>"" then
			noalt1=" and a.date7>'"&timelg&"'"
		end if
		if open_6_1=3 then
			Str_Result_42=""
		elseif open_6_1=1 then
			Str_Result_42=" and a.sorce2 in ("&intro_6_1&")"
		else
			Str_Result_42=" and a.sorce2=0"
		end if
		Str_Result="and (a.gate_sp="&session("personzbintel2007")&" and a.sp_id>0 and a.del=1 and a.spstate in (2,5) "&Str_Result_42&") "&noalt1&""
	end if
	dim vcStr
	vcStr="and (a.gate_sp="&session("personzbintel2007")&" and a.sp_id>0 and a.del=1 and a.spstate in (2,5) "&Str_Result&") "&noalt1&""
	W1   =replace(request("W1")," ","")
	W2   =replace(request("W2")," ","")
	W3   =replace(request("W3")," ","")
	if W1="" then W1=0
	if W2="" then W2=0
	if W3="" then W3=0
	W3=getW3(W1,W2,W3)
	W3=getLimitedW3(W3,2,1,0,session("personzbintel2007"))
	W4=replace(replace(W3,"0",""),",","")
	strtmp=getW1W2(W3)
	tmparr=split(strtmp,";")
	W1=tmparr(0)
	W2=tmparr(1)
	if W4<>"" and not isnull(W4) then
		Str_Result = Str_Result + " and a.sorce2 in ("&W3&")  "
'if W4<>"" and not isnull(W4) then
	end if
	if typ="0" then
		Str_Result=Str_Result&" and  (a.del=1 or a.del=3) "
	elseif typ="1" then
		Str_Result = Str_Result + " and  a.del=1 and (a.spstate=1 or a.spstate=4 or (a.spstate is null)) "
'elseif typ="1" then
	elseif typ="4" then
		Str_Result = Str_Result + " and  (a.del=1 or a.del=3) and a.spstate=2 "
'elseif typ="4" then
	elseif typ="3" then
		Str_Result = Str_Result + " and a.del=1 and a.spstate=3 "
'elseif typ="3" then
	elseif typ="2" then
		Str_Result = Str_Result + " and a.del=1 and a.spstate=5 "
'elseif typ="2" then
	elseif typ="5" then
		Str_Result = Str_Result + " and ((a.del=1 and a.spstate=5) or ((a.del=1 or a.del=3) and a.spstate=2))"
'elseif typ="5" then
	elseif typ<>"3333333" and typ<>"5555555" then
		Str_Result = Str_Result + " and a.del=1 and a.gate_sp="&typ&" and a.spstate in(2,5) "
'elseif typ<>"3333333" and typ<>"5555555" then
	end if
	if title<>"" then
		Str_Result=Str_Result&" and  a.title like '%"&title&"%' "
	end if
	if intro<>"" then
		Str_Result = Str_Result + " and  a.note like '%"&intro&"%' "
'if intro<>"" then
	end if
	if money1<>"" then
		if isnumeric(money1)=false then
			Response.write("<script>alert('请输入合法金额');window.location=('jklist.asp');</script>")
			call db_close : Response.end
		else
			Str_Result = Str_Result + "and  a.allmoney >="&Replace(money1,",","")&" "
			call db_close : Response.end
		end if
	end if
	if money12<>"" then
		if isnumeric(money12)=false then
			Response.write("<script>alert('请输入合法金额');window.location=('jklist.asp');</script>")
			call db_close : Response.end
		else
			Str_Result = Str_Result + "and  a.allmoney <="&Replace(money12,",","")&" "
			call db_close : Response.end
		end if
	end if
	if money2<>"" then
		if isnumeric(money2)=false then
			Response.write("<script>alert('请输入合法金额');window.location=('jklist.asp');</script>")
			call db_close : Response.end
		else
			Str_Result = Str_Result + "and isnull(a.spmoney,0) >="&Replace(money2,",","")&" "
			call db_close : Response.end
		end if
	end if
	if money22<>"" then
		if isnumeric(money22)=false then
			Response.write("<script>alert('请输入合法金额');window.location=('jklist.asp');</script>")
			call db_close : Response.end
		else
			Str_Result = Str_Result + "and isnull(a.spmoney,0) <="&Replace(money22,",","")&" "
			call db_close : Response.end
		end if
	end if
	if returnMoney1<>"" then
		if isnumeric(returnMoney1)=false then
			Response.write("<script>alert(’请输入合法金额’);window.location=('jklist.asp');</script>")
			call db_close : Response.end
		else
			Str_Result = Str_Result + "and returnMoney >= "&Replace(returnMoney1,",","")&" "
			call db_close : Response.end
		end if
	end if
	if returnMoney2<>"" then
		if isnumeric(returnMoney2)=false then
			Response.write("<script>alert('请输入合法金额');window.location=('jklist.asp');</script>")
			call db_close : Response.end
		else
			Str_Result = Str_Result + "and returnMoney <= "&Replace(returnMoney2,",","")&" "
			call db_close : Response.end
		end if
	end if
	if dkMoney1<>"" then
		if isnumeric(dkMoney1)=false then
			Response.write("<script>alert('请输入合法金额');window.location=('jklist.asp');</script>")
			call db_close : Response.end
		else
			Str_Result = Str_Result + "and dkmoney >= "&Replace(dkMoney1,",","")&" "
			call db_close : Response.end
		end if
	end if
	if dkMoney2<>"" then
		if isnumeric(dkMoney2)=false then
			Response.write("<script>alert('请输入合法金额');window.location=('jklist.asp');</script>")
			call db_close : Response.end
		else
			Str_Result = Str_Result + "and dkmoney <= "&Replace(dkMoney2,",","")&" "
			call db_close : Response.end
		end if
	end if
	if NoreturnMoney1<>"" then
		if isnumeric(NoreturnMoney1)=false then
			Response.write("<script>alert('请输入合法金额');window.location=('jklist.asp');</script>")
			call db_close : Response.end
		else
			Str_Result = Str_Result + "and NoreturnMoney >= "&Replace(NoreturnMoney1,",","")&" "
			call db_close : Response.end
		end if
	end if
	if NoreturnMoney2<>"" then
		if isnumeric(NoreturnMoney2)=false then
			Response.write("<script>alert('请输入合法金额');window.location=('jklist.asp');</script>")
			call db_close : Response.end
		else
			Str_Result = Str_Result + "and NoreturnMoney <= "&Replace(NoreturnMoney2,",","")&" "
			call db_close : Response.end
		end if
	end if
	if tjr<>"" then
		perid=selname("gate","name",tjr,"ord")
		if perid="" or isnull(perid) then perid=0
		Str_Result = Str_Result + "and  a.addcate in ("&perid&") "
'if perid="" or isnull(perid) then perid=0
	end if
	if jkr<>"" then
		perid=selname("gate","name",jkr,"ord")
		if perid="" or isnull(perid) then perid=0
		Str_Result = Str_Result + "and  a.sorce2 in ("&perid&") "
'if perid="" or isnull(perid) then perid=0
	end if
	if D<>"" then
		if A="zt" then
			Str_Result=Str_Result&" and  a.title like '%"&D&"%' "
		elseif A="ry" then
			perid=selname("gate","name",D,"ord")
			if perid="" or isnull(perid) then perid=0
			Str_Result = Str_Result + "and  a.sorce2 in ("&perid&") "
'if perid="" or isnull(perid) then perid=0
		elseif A="sqje" then
			if isnumeric(D)=false then
				Response.write("<script>alert('请输入合法金额');window.location=('jklist.asp');</script>")
				call db_close : Response.end
			else
				Str_Result = Str_Result + "and  a.allmoney ="&Replace(D,",","")&" "
				call db_close : Response.end
			end if
		elseif A="spje" then
			if isnumeric(D)=false then
				Response.write("<script>alert('请输入合法金额');window.location=('jklist.asp');</script>")
				call db_close : Response.end
			else
				Str_Result = Str_Result + "and  a.spmoney ="&Replace(D,",","")&" "
				call db_close : Response.end
			end if
		elseif A="jksm" then
			Str_Result = Str_Result + "and  a.note like '%"&D&"%' "
'elseif A="jksm" then
		end if
	end if
	if C<>"" then
		if B="kh" then
			telid=selname("tel","name",C,"ord")
			if trim(telid)<>"" then
				Str_Result = Str_Result + "and a.tel in ("&telid&") "
'if trim(telid)<>"" then
			end if
		elseif B="lxr" then
			perid=selname("person","name",C,"ord")
			if trim(perid)<>"" then
				Str_Result = Str_Result + "and a.person in ("&perid&") "
'if trim(perid)<>"" then
			end if
		elseif B="xm" then
			chid=selname("chance","title",C,"ord")
			if trim(chid)<>"" then
				Str_Result = Str_Result + "and a.chance in ("&chid&") "
'if trim(chid)<>"" then
			end if
		elseif B="ht" then
			conid=selname("contract","title",C,"ord")
			if trim(conid)<>"" then
				Str_Result = Str_Result + "and a.contract in ("&conid&") "
'if trim(conid)<>"" then
			end if
		elseif B="sh" then
			shid=selname("tousu","title",C,"ord")
			if trim(shid)<>"" then
				Str_Result = Str_Result + "and a.shouhou in ("&shid&") "
'if trim(shid)<>"" then
			end if
		elseif B="rc" then
			rcid=selname("plan1","intro",C,"ord")
			if trim(rcid)<>"" then
				Str_Result = Str_Result + "and a.richeng in ("&rcid&") "
'if trim(rcid)<>"" then
			end if
		elseif B="gys" then
			gysid=selname("tel","name",C,"ord")
			if trim(gysid)<>"" then
				Str_Result = Str_Result + "and a.iwork in ("&gysid&") "
'if trim(gysid)<>"" then
			end if
		elseif B="cg" then
			cgid=selname("caigou","title",C,"ord")
			if trim(cgid)<>"" then
				Str_Result = Str_Result + "and a.caigou in ("&cgid&") "
'if trim(cgid)<>"" then
			end if
		elseif B="fh" then
			fhid=selname("send","title",C,"ord")
			if trim(fhid)<>"" then
				Str_Result = Str_Result + "and a.fahuo in ("&fhid&") "
'if trim(fhid)<>"" then
			end if
		end if
	end if
	Call searchExtended(1001,"a.id")
	if m1<>"" then
		Str_Result = Str_Result + " and  datejk>='"&m1&" 00:00:00' "
'if m1<>"" then
	end if
	if m2<>"" then
		Str_Result = Str_Result + " and  datejk<='"&m2&" 23:59:59' "
'if m2<>"" then
	end if
	If remind <> "" Then
		Set helper = CreateReminderHelper(conn,remind,0)
		Str_Result = Str_Result& " and a.id in (" & helper.listSQL("ids") & ")"
	end if
	page_count=request.QueryString("page_count")
	if page_count="" then
		page_count=15
	end if
	currpage=Request("currpage")
	if currpage<="0" or currpage="" then
		currpage=1
	end if
	currpage=clng(currpage)
	pxResult=""
	if px="" then
		px=5
	end if
	if px=1 then
		pxResult=" order by a.title desc,a.date7 desc"
	elseif px=2 then
		pxResult=" order by a.title asc,a.date7 desc"
	elseif px=3 then
		pxResult=" order by a.datejk desc,a.date7 desc"
	elseif px=4 then
		pxResult=" order by a.datejk asc,a.date7 desc"
	elseif px=5 then
		pxResult=" order by a.date7 desc"
	elseif px=6 then
		pxResult=" order by a.date7 asc"
	elseif px=7 then
		pxResult=" order by name desc,a.date7 desc"
	elseif px=8 then
		pxResult=" order by name asc,a.date7 desc"
	elseif px=9 then
		pxResult=" order by a.allmoney desc,a.date7 desc"
	elseif px=10 then
		pxResult=" order by a.allmoney asc,a.date7 desc"
	elseif px=11 then
		pxResult=" order by a.spmoney desc,a.date7 desc"
	elseif px=12 then
		pxResult=" order by a.spmoney asc,a.date7 desc"
	end if
	REF=request.ServerVariables("HTTP_REFERER")
	if instr(REF,"mReportSearch.asp")>0 then
		isRsearch=1
	else
		isRsearch=0
	end if
	Response.write "" & vbcrlf & "<!DOCTYPE HTML PUBLIC ""-//W3C//DTD HTML 4.01 Transitional//EN""" & vbcrlf & """http://www.w3.org/TR/html4/loose.dtd"">" & vbcrlf & "<html>" & vbcrlf & "<head>" & vbcrlf & "<meta http-equiv=""Content-Type"" content=""text/html; charset=UTF-8"">" & vbcrlf & "<title>"
	isRsearch=0
	Response.write title_xtjm
	Response.write "</title>" & vbcrlf & "<link rel=""stylesheet"" type=""text/css"" href=""../inc/themes/default/easyui.css?ver="
	Response.write Application("sys.info.jsver")
	Response.write """>" & vbcrlf & "<link rel=""stylesheet"" type=""text/css"" href=""../inc/themes/icon.css?ver="
	Response.write Application("sys.info.jsver")
	Response.write """>" & vbcrlf & "<style>" & vbcrlf & ".ser_btn input[type='text']{height:20px;line-height:20px;}" & vbcrlf & ".ser_btn select{position:relative;top:1px;*top:0}" & vbcrlf & "</style>" & vbcrlf & "<script type=""text/javascript"" src=""../inc/jquery-1.4.2.min.js?ver="
	'Response.write Application("sys.info.jsver")
	Response.write Application("sys.info.jsver")
	Response.write """></script>" & vbcrlf & "<script type=""text/javascript"" src=""../inc/jquery.easyui.min.js?ver="
	Response.write Application("sys.info.jsver")
	Response.write """></script>" & vbcrlf & "<script language=""javascript"">" & vbcrlf & "if(window.opener){" & vbcrlf & " opener.top.jkchildWindow=window;" & vbcrlf & "        "
	if request.QueryString("child")<>"true" and isRsearch=0 Then
		Response.write "" & vbcrlf & "     window.opener.location.reload();" & vbcrlf & "        "
	end if
	Response.write "" & vbcrlf & "}" & vbcrlf & "</script>" & vbcrlf & "<link href=""../inc/cskt.css?ver="
	Response.write Application("sys.info.jsver")
	Response.write """ rel=""stylesheet"" type=""text/css"">" & vbcrlf & "</head>" & vbcrlf & "<body  "
	if open_6_8=0 then
		Response.write " oncontextmenu=""return false"" onselectstart=""return false"" ondragstart=""return false"" onbeforecopy=""return false"" oncopy=document.selection.empty()"
	end if
	Response.write " onMouseOver=""window.status='none';return true;"">" & vbcrlf & "<table width=""100%"" border=""0"" cellspacing=""0"" cellpadding=""0"">" & vbcrlf & "<tr>" & vbcrlf & "    <td width=""100%"" valign=""top"">" & vbcrlf & "     <table width=""100%"" border=""0"" cellpadding=""0"" cellspacing=""0"" background=""../images/m_mpbg.gif"">" & vbcrlf & "      <form action=""jklist.asp?px="
	Response.write px
	Response.write "&page_count="
	Response.write page_count
	Response.write "&typ="
	Response.write typ
	Response.write """ method=""get""　id=""demo"" onsubmit=""return Validator.Validate(this,2)"" name=""date"" >" & vbcrlf & "          <tr>" & vbcrlf & "            <td class=""place"">费用借款列表</td>" & vbcrlf & "            <td><A class='px_btn' onclick=""Myopen(User);return false;"" href=""javascript:void(0)"">排序规则<IMG src=""../images/i10.gif"" alt=""排序规则"" width=""9"" height=""5"" border=""0""></A></td>" & vbcrlf & "            <td align=""right""> <font id=""kh"">" & vbcrlf & "                <select name=""select2""  onChange=""if(this.selectedIndex && this.selectedIndex!=0){gotourl(this.value);}"" >" & vbcrlf & "<option>-请选择-</option>" & vbcrlf & "                                       <option value=""page_count=10"" "
	Response.write typ
	if page_count=10 then
		Response.write "selected"
	end if
	Response.write ">每页显示10条</option>" & vbcrlf & "                                       <option value=""page_count=20"" "
	if page_count=20 then
		Response.write "selected"
	end if
	Response.write ">每页显示20条</option>" & vbcrlf & "                                       <option value=""page_count=30"" "
	if page_count=30 then
		Response.write "selected"
	end if
	Response.write ">每页显示30条</option>" & vbcrlf & "                                       <option value=""page_count=50"" "
	if page_count=50 then
		Response.write "selected"
	end if
	Response.write ">每页显示50条</option>" & vbcrlf & "                                       <option value=""page_count=100"" "
	if page_count=100 then
		Response.write "selected"
	end if
	Response.write ">每页显示100条</option>" & vbcrlf & "                                      <option value=""page_count=200"" "
	if page_count=200 then
		Response.write "selected"
	end if
	Response.write ">每页显示200条</option>" & vbcrlf & "                        </select>" & vbcrlf & "             </font></td>" & vbcrlf & "            <td width=""3""><img src=""../images/m_mpr.gif"" width=""3"" height=""32"" /></td>" & vbcrlf & "          </tr>" & vbcrlf & "      </table>" & vbcrlf & " <table width=""100%"" border=""0"" cellpadding=""3"" cellspacing=""1"" bgcolor=""#C0CCDD"" id=""content"">" & vbcrlf & "  <tr>" & vbcrlf & "    <td colspan=""13"" class='ser_btn' align=""right"" style=""height:50px;;border-top:#C0CCDD 0px solid;border-left:#C0CCDD 0px solid;border-right:#C0CCDD 1px solid;padding-top:0;padding-bottom:0;"">" & vbcrlf & "                 "
	sql8="select bz from setbz"
	set rs8=conn.execute(sql8)
	bz=rs8("bz")
	set rs8=nothing
	Response.write "" & vbcrlf & "                     <select name=""listbz"">" & vbcrlf & "                    <option value="""">币种</option>" & vbcrlf & "                    "
	sql8="select id,sort1 from sortbz order by gate1 desc"
	set rs8=server.CreateObject("adodb.recordset")
	rs8.open sql8,conn,1,1
	if bz<>0 then
		if not rs8.eof then
			do while not rs8.eof
				Response.write "" & vbcrlf & "                     <option value="""
				Response.write rs8("id")
				Response.write """ "
				if cdbl(rs8("id"))=listbz then Response.write "selected"
				Response.write ">"
				Response.write rs8("sort1")
				Response.write "</option>" & vbcrlf & "                    "
				rs8.movenext
			loop
		end if
	else
		Response.write "" & vbcrlf & "                     <option value=""14"" "
		if listbz="14" then
			Response.write "selected"
		end if
		Response.write ">人民币</option>" & vbcrlf & "                     "
	end if
	set rs8=nothing
	Response.write "" & vbcrlf & "                     </select>" & vbcrlf & "                         <select name=""typ"" id=""typ"">" & vbcrlf & "                              <option value=""0"" "
	if typ="0" then Response.write "selected"
	Response.write ">全部</option>" & vbcrlf & "                               <option value=""1"" "
	if typ="1" then Response.write "selected"
	Response.write ">审批通过</option>" & vbcrlf & "                           <option value=""2"" "
	if typ="2" then Response.write "selected"
	Response.write ">待审批</option>" & vbcrlf & "                             <option value=""4"" "
	if typ="4" then Response.write "selected"
	Response.write ">审批中</option>" & vbcrlf & "                             <option value=""3"" "
	if typ="3" then Response.write "selected"
	Response.write ">审批未通过</option>" & vbcrlf & "                   </select>" & vbcrlf & "                       "
	type_tj_v = request.querystring("type_tj")
	If Len(type_tj_v & "") = 0 Then
		type_tj_v = request.form("type_tj")
		If Len(type_tj_v) > 0 then
			type_tj = type_tj_v
		end if
	end if
	Response.write "&nbsp;自：<INPUT readonly=""true"" name=ret size=9  id=daysOfMonthPos  onmousedown=""datedlg.show()"" value="""
	Response.write m1
	Response.write """>&nbsp;至：<INPUT name=ret2 readonly=""true"" size=9  id=daysOfMonth2Pos onmousedown=""datedlg.show()"" value="""
	Response.write m2
	Response.write """>&nbsp;<input type='hidden' name='type_tj' value='"
	Response.write type_tj_v
	Response.write "'>"
	
	Response.write "" & vbcrlf & "                     <select name=""A"">" & vbcrlf & "                         <option value=""zt"" "
	if A="zt" then Response.write "selected"
	Response.write ">借款主题</option>" & vbcrlf & "                           <option value=""ry"" "
	if A="ry" then Response.write "selected"
	Response.write ">借款人员</option>" & vbcrlf & "                           <option value=""sqje"" "
	if A="sqje" then Response.write "selected"
	Response.write ">借款金额</option>" & vbcrlf & "                           <option value=""spje"" "
	if A="spje" then Response.write "selected"
	Response.write ">审批金额</option>" & vbcrlf & "                           <option value=""jksm"" "
	if A="jksm" then Response.write "selected"
	Response.write ">借款概要</option>" & vbcrlf & "                   </select>" & vbcrlf & "                       <input name=""D"" type=""text"" size=""10""  value="""
	Response.write D
	Response.write """/>" & vbcrlf & "                         <input type=""submit"" name=""Submit422"" value=""检索""  class=""anybutton2""/>" & vbcrlf & "                        <input type=""button"" name=""openbn"" id=""openbn"" value=""高级检索""  class=""anybutton2"" onclick=""$('#w').show();$('#w').window('open');$('#hideDiv').show();""/>" & vbcrlf & "                         "
	if open_6_10=1 or open_6_10=3 then
		Response.write "" & vbcrlf & "        <input type=""button"" name=""Submitdel2"" value=""导出"" onClick=""if(confirm('确认导出为EXCEL文档？')){exportExcel({debug:false,page:'../out/xls_jk.asp'})}"" class=""anybutton2""/>" & vbcrlf & "        "
	end if
	if open_6_7=1 or open_6_7=3 then
		Response.write "" & vbcrlf & "          <input type=""button""  name=""print"" onclick="";window.print();return   false;"" value=""打印""  class=""anybutton2""/>" & vbcrlf & "           "
	end if
	Response.write "</td>" & vbcrlf & "        </tr>" & vbcrlf & "   </form>" & vbcrlf & " <tr class=""top"">" & vbcrlf & "    <td width=""4%"" align=""center"" ><div align=""center"">选择</div></td>" & vbcrlf & "    <td width=""12%"" height=""26""  ><div align=""center"">借款主题</div></td>" & vbcrlf & "         <td width=""8%""><div align=""center"">借款编号</div></td>" & vbcrlf & "      <td width=""6%"" ><div align=""center"" >借款日期</div></td>" & vbcrlf & "    <td width=""7%"" ><div align=""center"" >借款人员</div></td>" & vbcrlf & "    <td width=""5%"" ><div align=""center"" >出账状态</div></td>" & vbcrlf & "    <td width=""7%"" ><div align=""center"" >借款金额</div></td>" & vbcrlf & "        <td width=""7%"" ><div align=""center"">审批金额</div></td>" & vbcrlf & "     <td width=""7%"" ><div align=""center"">返还金额</div></td>" & vbcrlf & "     <td width=""7%"" ><div align=""center"">抵扣金额</div></td>" & vbcrlf & "     <td width=""7%"" ><div align=""center"">未返还金额</div></td>" & vbcrlf & "       <td width=""6%"" ><div align=""center"">状态</div></td>" & vbcrlf & "         <td width=""16%"" ><div align=""center"">操作</div></td>" & vbcrlf & "      </tr>" & vbcrlf & "   "
	dim n
	n=0
	all1=0
	all2=0
	all3=0
	all4=0
	allm1=0
	allm2=0
	allm3=0
	allm5=0
	sqltext=" update a set payid = 3 FROM payjk AS a  where payid = 2 and not exists(select 1 from pay where complete in (7,8,11,12) and jkid=a.id) and ISNULL(a.spmoney,0)>ISNULL((SELECT ISNULL(SUM(dkmoney),0) AS dkmoney from dk where del=1 and jkid=a.id ),0) "
	conn.execute(sqltext)
	Dim tableSQL
	tableSQL = "SELECT a.*,(case when isnull(k.cnum,0)>0 then 1 else 0 end ) as hascz,b.name,ISNULL(c.returnMoney,0) returnMoney,ISNULL(d.dkmoney,0) dkmoney,(case when isnull(k.cnum,0)>0 then isnull(a.spmoney,0)-ISNULL(c.returnMoney,0)-ISNULL(d.dkmoney,0) else 0 end) as NoreturnMoney,case when exists(select top 1 1 from  PrinterInfo a1 where a1.sort = 22  and a1.formid = a.id) then '<span style=''color:#009900''>[已打印]</span>' else '<span  style=''color:#FF0000''>[未打印]</span>' end  as printStatus " &_
	"FROM payjk AS a WITH(NOLOCK)" &_
	"INNER JOIN gate AS b WITH(NOLOCK) ON b.ord = a.sorce2 "&_
	"LEFT JOIN "&_
	"( SELECT jkid,returnMoney FROM "&_
	"    (SELECT ISNULL(SUM(p.money1),0) returnMoney,jkid "&_
	"    FROM pay p WITH(NOLOCK) "&_
	"    left JOIN bank b WITH(NOLOCK) ON b.gl = p.ord AND b.sort = 4 AND b.del = 1 "&_
	"    WHERE p.complete in (7,8,11) AND p.del=1 "&_
	"     GROUP BY jkid " &_
	"    ) x "&_
	") c ON c.jkid = a.id "&_
	"LEFT JOIN  "&_
	"(SELECT ISNULL(SUM(dkmoney),0) AS dkmoney,jkid FROM dk WITH(NOLOCK) WHERE del=1 GROUP BY jkid)  "&_
	"d ON d.jkid=a.id "&_
	"left join (select gl,count(id) as cnum from bank where sort=50 and del=1 group by gl ) k on k.gl = a.id"
	set rs=server.CreateObject("adodb.recordset")
	sql="select isnull(sum(allmoney),0) as allmoney, isnull(sum(spmoney),0) as spmoney , isnull(sum(returnMoney),0) as returnMoney , isnull(sum(dkmoney),0) as dkmoney, isnull(sum(allm5),0) as allm5,isnull(sum(NoreturnMoney),0) as NoreturnMoney  from (SELECT allmoney, spmoney, returnmoney, dkmoney "&_
	", isnull((select top 1 1 from bank where sort=50 and del=1 and gl=a.id),0)*(isnull(spmoney,0)-isnull(returnmoney,0)-isnull(dkmoney,0)) as allm5,NoreturnMoney FROM ( "& tableSQL & ") a WHERE a.id>0 AND 1=1 "&Str_Result & ") tt"
	rs.open sql,conn,3,1
	If not rs.eof Then
		
		allm1 =zbcdbl( rs("allmoney"))
		allm2 =zbcdbl( rs("spmoney"))
		allm3 =zbcdbl( rs("returnMoney"))
		allm4 =zbcdbl( rs("dkmoney"))
		allm5 = zbcdbl(rs("allm5"))
	end if
	rs.close
	Set rs=nothing
	set rs=server.CreateObject("adodb.recordset")
	sql="SELECT a.*,isnull(p.money1,0) as jkmoney1,(case when isnull(s.snum,0)>0 then 1 else 0 end) as hasbank,(case when isnull(y.ynum,0)=0 and isnull(x.xnum,0)=0 then 1 else 0 end) as candel "&_
	"FROM ( "& tableSQL & ") a "&_
	"   left join (select jkid,sum(money1) as money1 from pay WITH(NOLOCK) where del=1 and complete in (7,8,11) group by jkid) p on p.jkid=a.id "&_
	"   left join (select bz,count(id) as snum from sortbank where charindex(',"&session("personzbintel2007")&",',','+cast(person as varchar(4000))+',')>0 group by bz) s on s.bz=a.bz "&_
	"   left join (select jkid ,count(ord) as ynum from pay WITH(NOLOCK) where (del=1 or del=2) and complete in (7,8,11) group by jkid)  y on y.jkid = a.id "&_
	"   left join (select k.jkid,count(j.id) as xnum from paybx j WITH(NOLOCK) inner join dk k on k.bxid=j.id where (j.del=1 or j.del=2) group by k.jkid ) x on x.jkid = a.id "&_
	"   WHERE a.id>0 AND 1=1 "&Str_Result&" "&pxResult&" "
	set rscount=conn.execute(sql)
	rs.open sql,conn,1,1
	if rs.eof then
		Response.write "<table><tr><td>没有信息!</td></tr><tr><td height='80'>&nbsp;</td></tr></table>"
	else
		rs.PageSize=page_count
		PageCount=clng(rs.PageCount)
		if CurrPage>=PageCount then
			CurrPage=PageCount
		end if
		BookNum=rs.RecordCount
		rs.absolutePage = CurrPage
		Response.write "" & vbcrlf & "     <form name=""form1"" method=""post"" action=""deletejkall.asp?"
		Response.write sdk.ReturnURL("")
		Response.write """ >" & vbcrlf & "        "
		do until rs.eof
			trade6 = rs("name") : bz=rs("bz") : cateid=rs("sorce2")
			if bz="" or isnull(bz) then bz=14
			trade8=selbz(bz)
			if trade8="" or isnull(trade8) then trade8="RMB"
			Response.write "" & vbcrlf & "      <tr onmouseout=""this.style.backgroundColor=''"" onmouseover=""this.style.backgroundColor='efefef'"">" & vbcrlf & "     <td align=""center""><div align=""center""><span class=""red"">" & vbcrlf & "       "
			if open_6_3=3 or CheckPurview(intro_6_3,trim(cateid))=True then
				Response.write "" & vbcrlf & "          <input name=""selectid"" type=""checkbox"" id=""selectid"" value="""
				Response.write rs("id")
				Response.write """>" & vbcrlf & "     "
			end if
			Response.write "" & vbcrlf & "          </span></div></td>" & vbcrlf & "          <td><div align=""left"">" & vbcrlf & "            "
			if open_6_14=3 or CheckPurview(intro_6_14,trim(cateid))=True then
				Response.write "" & vbcrlf & "                      <a href=""javascript:void(0);"" onClick=""javascript:window.open('jkdetail.asp?ord="
				Response.write pwurl(rs("id"))
				Response.write "','neww3win','width=' + 1200 + ',height=' + 600 + ',fullscreen =no,scrollbars=1,toolbar=0,resizable=1,left=100,top=100')"">"
				Response.write pwurl(rs("id"))
				Response.write left(rs("title"),30)
				Response.write "</a>" & vbcrlf & ""
			else
				Response.write left(rs("title"),30)
			end if
			if  timelg<>"" and datediff("s",timelg,rs("date7"))>0 then respone.write new_list
			Response.write rs("printStatus")
			Response.write "<span style=""color:red""></span> </div></td>" & vbcrlf & "             <td><div align=""left"">"
			Response.write rs("bh")
			Response.write "</div></td>" & vbcrlf & "        <td><div align=""center"">"
			Response.write rs("datejk")
			Response.write "</div></td>" & vbcrlf & "           <td class=""func""><div align=""center"">"
			Response.write trade6
			Response.write "</div></td>" & vbcrlf & "           <td><div align=""center"" >"
			hascz = (rs("hascz")&""="1")
			If hascz Then Response.write "已出账" Else Response.write "未出账"
			Response.write "</div></td>" & vbcrlf & "           <td><div align=""right"">"
			Response.write trade8
			Response.write Formatnumber(zbcdbl(rs("allmoney")),num_dot_xs,-1)
			Response.write trade8
			Response.write "</div></td>" & vbcrlf & "           <td><div align=""right"">" & vbcrlf & "           "
			spmoney=zbcdbl(rs("spmoney"))
			if zbcdbl(rs("spmoney"))=0 or isnull(zbcdbl(rs("spmoney"))) or zbcdbl(rs("spmoney"))="" then spmoney=0
			Response.write (trade8&""&Formatnumber(spmoney,num_dot_xs,-1))
'if zbcdbl(rs("spmoney"))=0 or isnull(zbcdbl(rs("spmoney"))) or zbcdbl(rs("spmoney"))="" then spmoney=0
			Response.write "</div></td>" & vbcrlf & "           "
			jkmoney1=zbcdbl(rs("jkmoney1"))
			dmoney1 =zbcdbl( rs("dkmoney"))
			if dmoney1="" or isnull(dmoney1) then dmoney1=0
			if jkmoney1="" or isnull(jkmoney1) then jkmoney1=0
			alldmoney1=cdbl(alldmoney1)+cdbl(dmoney1)
'if jkmoney1="" or isnull(jkmoney1) then jkmoney1=0
			Response.write "" & vbcrlf & "              <td><div align=""right"">" & vbcrlf & "           " & vbcrlf & "                "
			paymoney=zbcdbl(rs("returnMoney"))
			Response.write trade8&""&Formatnumber(paymoney,num_dot_xs,-1)
'paymoney=zbcdbl(rs("returnMoney"))
			Response.write "" & vbcrlf & "              " & vbcrlf & "                </div></td>" & vbcrlf & "             <td><div align=""right"">"
			Response.write trade8&Formatnumber(dmoney1,num_dot_xs,-1)
			Response.write "</div></td>" & vbcrlf & "           <td><div align=""right"">"
			Response.write trade8
			If hascz Then
				Dim wfhm : wfhm = Formatnumber(spmoney-paymoney-dmoney1,num_dot_xs,-1)
'If hascz Then
				all4 = all4 +  wfhm*1
'If hascz Then
				Response.write wfhm
			else
				Response.write Formatnumber(0,num_dot_xs,-1)
				Response.write wfhm
			end if
			Response.write "</div></td>" & vbcrlf & "           <td><div align=""center"">"
			Select Case rs("spstate")&""
			Case "","1","4" : Response.write "审批通过"
			Case "2" : Response.write "审批中"
			Case "3" : Response.write "审批未通过"
			Case "5" : Response.write "待审批"
			End Select
			Response.write "</div></td>" & vbcrlf & "           <td width=""15%"" class=""func""><div align=""center"">" & vbcrlf & ""
			If remind <> "" Then
				rid = helper.getRemindIdByOID(rs("id"))
				if helper.canCancelOrder(rid) then
					Response.write "" & vbcrlf & "                       <img src=""../images/alt3.gif"" alt=""取消提醒"" border=""0"" style=""cursor:hand"" rid="""
					Response.write rid
					Response.write """ class=""cancelBtn"">" & vbcrlf & ""
				end if
			end if
			spmoney=zbcdbl(rs("spmoney"))
			if spmoney="" or isnull(spmoney) then spmoney=0
			sm=Formatnumber(Formatnumber(spmoney,num_dot_xs,-1)-Formatnumber(jkmoney1,num_dot_xs,-1)-Formatnumber(dmoney1,num_dot_xs,-1),num_dot_xs,-1)
'if spmoney="" or isnull(spmoney) then spmoney=0
			if open_6_14=3 or CheckPurview(intro_6_14,trim(cateid))=True then
				Response.write "" & vbcrlf & "               <input type=""button"" name=""Submit53"" value=""详情""  onClick=""javascript:window.open('jkdetail.asp?ord="
				Response.write pwurl(rs("id"))
				Response.write "','neww3win','width=' + 1200 + ',height=' + 600 + ',fullscreen =no,scrollbars=1,toolbar=0,resizable=1,left=100,top=100')""/>" & vbcrlf & "               "
				Response.write pwurl(rs("id"))
			end if
			if rs("payid")=3 and (open_6_13=3 or CheckPurview(intro_6_13,trim(cateid))=True) and zbcdbl(rs("spmoney"))>0 and sm>0 then
				Response.write "" & vbcrlf & "             <input type=""button"" name=""Submit33"" value=""返还""  onClick=""javascript:window.location=('addfh.asp?ord="
				Response.write pwurl(rs("id"))
				Response.write "')""/>" & vbcrlf & "             "
			end if
			If rs("spstate")&""="5" And (rs("gate_sp")&""="" Or rs("gate_sp")&""="0") And (rs("addcate")&""=session("personzbintel2007")&"" Or rs("sorce2")&""=session("personzbintel2007")&"") Then
				Response.write "<input type=""button"" name=""Submit"" value=""提交"" onClick=""window.open('../inc/CommSPSet.asp?ord="
				Response.write pwurl(rs("id"))
				Response.write "&sort1=6&setproc=1&remind=42','neww3win','width=' + 700 + ',height=' + 400 + ',fullscreen =no,scrollbars=1,toolbar=0,resizable=1,left=100,top=100');"">" & vbcrlf & "                     "
				Response.write pwurl(rs("id"))
			Elseif (open_6_16=3 or CheckPurview(intro_6_16,trim(cateid))=True) and trim(rs("gate_sp"))=trim(session("personzbintel2007")) and (rs("spstate")="2" or rs("spstate")="5") and (rs("payid")&""="4" Or (rs("payid")&""="7" And rs("gate_sp")&""<>"" And rs("gate_sp")&""<>"0")) then
				Response.write "" & vbcrlf & "             <input type=""button"" name=""Submit33"" value=""审批""  onClick=""javascript:window.open('setjk.asp?"
				Response.write sdk.ReturnURL("ord=" & pwurl(rs("id")) &"")
				Response.write "','neww4win','width=' + 1000 + ',height=' + 600 + ',fullscreen =no,scrollbars=1,toolbar=0,resizable=1,left=100,top=100')""/>" & vbcrlf & "               "
				Response.write sdk.ReturnURL("ord=" & pwurl(rs("id")) &"")
			end if
			hasbank = (rs("hasbank")&""="1")
			If hascz Then conn.execute("update payjk set payid = 3 where id ="&rs("id"))
			if (rs("payid")=1 Or rs("payid")=7) And hascz = false and (open_6_20=3 or CheckPurview(intro_6_20,trim(cateid))) And (rs("spstate")&""="" or rs("spstate")=1 or rs("spstate")=4) and hasbank then
				Response.write "" & vbcrlf & "              <input type=""button"" name=""Submit53"" value=""出账""  onClick=""javascript:window.location=('jkbank1.asp?"
				Response.write sdk.ReturnURL("ord=" & pwurl(rs("id")) &"")
				Response.write "')""/>" & vbcrlf & "             "
			end if
			if hascz=false and rs("spstate")="5" and (open_6_17=3 or CheckPurview(intro_6_17,trim(cateid))=True) then
				Response.write "" & vbcrlf & "               <input type=""button"" name=""Submit53"" value=""修改""  onClick=""javascript:window.location=('jkupdate.asp?"
				Response.write sdk.ReturnURL("ord=" & pwurl(rs("id")) &"")
				Response.write "')""/>" & vbcrlf & "             "
			end if
			candel = (rs("candel")&""="1")
			if candel = true and (open_6_3=3 or CheckPurview(intro_6_3,trim(cateid))=True)  then
				Response.write "" & vbcrlf & "               <input type=""button"" name=""Submit"" value=""删除"" onClick=""if(confirm('确认删除？')){window.location.href='Deletejk.asp?"
				Response.write sdk.ReturnURL("ord=" & pwurl(rs("id")) &"")
				Response.write "'}""/>" & vbcrlf & "               "
			end if
			Response.write "" & vbcrlf & "               </div></td>" & vbcrlf & "   </tr>" & vbcrlf & "           "
			all1=cdbl(rs("allmoney"))+cdbl(all1)
			Response.write "" & vbcrlf & "               </div></td>" & vbcrlf & "   </tr>" & vbcrlf & "           "
			all2=cdbl(spmoney)+cdbl(all2)
			Response.write "" & vbcrlf & "               </div></td>" & vbcrlf & "   </tr>" & vbcrlf & "           "
			all3=cdbl(paymoney)+cdbl(all3)
			Response.write "" & vbcrlf & "               </div></td>" & vbcrlf & "   </tr>" & vbcrlf & "           "
			n=n+1
			Response.write "" & vbcrlf & "               </div></td>" & vbcrlf & "   </tr>" & vbcrlf & "           "
			if n>=rs.PageSize then exit do
			rs.movenext
		loop
		Response.write "" & vbcrlf & "     <tr onmouseout=""this.style.backgroundColor=''"" onmouseover=""this.style.backgroundColor='efefef'"">" & vbcrlf & "     <td height=""27"" colspan=""6""><div align=""right"">本页合计：</div></td>" & vbcrlf & "          <td class=""red""><div align=""right"">"
		if listbz<>"" then
			Response.write trade8
			Response.write "&nbsp;"
		end if
		Response.write Formatnumber(all1,num_dot_xs,-1)
		Response.write "&nbsp;"
		Response.write "</div></td>" & vbcrlf & "    <td class=""red""><div align=""right"">"
		if listbz<>"" then
			Response.write trade8
			Response.write "&nbsp;"
		end if
		Response.write Formatnumber(all2,num_dot_xs,-1)
		Response.write "&nbsp;"
		Response.write "</div></td>" & vbcrlf & "    <td class=""red""><div align=""right"">"
		if listbz<>"" then
			Response.write trade8
			Response.write "&nbsp;"
		end if
		Response.write Formatnumber(all3,num_dot_xs,-1)
		Response.write "&nbsp;"
		Response.write "</div></td>" & vbcrlf & "    <td class=""red""><div align=""right"">"
		if listbz<>"" then
			Response.write trade8
			Response.write "&nbsp;"
		end if
		Response.write Formatnumber(alldmoney1,num_dot_xs,-1)
		Response.write "&nbsp;"
		Response.write "</div></td>" & vbcrlf & "    <td class=""red""><div align=""right"">"
		if listbz<>"" then
			Response.write trade8
			Response.write "&nbsp;"
		end if
		Response.write Formatnumber(all4,num_dot_xs,-1)
		Response.write "&nbsp;"
		Response.write "</div></td>" & vbcrlf & "    <td colspan=""3""></td>" & vbcrlf & "   </tr>" & vbcrlf & "   <tr onmouseout=""this.style.backgroundColor=''"" onmouseover=""this.style.backgroundColor='efefef'"">" & vbcrlf & "     <td height=""27"" colspan=""6""><div align=""right"">所有合计：</div></td>" & vbcrlf & "          <td class=""red""><div align=""right"">"
		if listbz<>"" then
			Response.write trade8
			Response.write "&nbsp;"
		end if
		Response.write Formatnumber(allm1,num_dot_xs,-1)
		Response.write "&nbsp;"
		Response.write "</div></td>" & vbcrlf & "    <td class=""red""><div align=""right"">"
		if listbz<>"" then
			Response.write trade8
			Response.write "&nbsp;"
		end if
		Response.write Formatnumber(allm2,num_dot_xs,-1)
		Response.write "&nbsp;"
		Response.write "</div></td>" & vbcrlf & "    <td class=""red""><div align=""right"">"
		if listbz<>"" then
			Response.write trade8
			Response.write "&nbsp;"
		end if
		Response.write Formatnumber(allm3,num_dot_xs,-1)
		Response.write "&nbsp;"
		Response.write "</div></td>" & vbcrlf & "    <td class=""red""><div align=""right"">"
		if listbz<>"" then
			Response.write trade8
			Response.write "&nbsp;"
		end if
		Response.write Formatnumber(allm4,num_dot_xs,-1)
		Response.write "&nbsp;"
		Response.write "</div></td>" & vbcrlf & "    <td class=""red""><div align=""right"">"
		if listbz<>"" then
			Response.write trade8
			Response.write "&nbsp;"
		end if
		Response.write Formatnumber(allm5,num_dot_xs,-1)
		Response.write "&nbsp;"
		Response.write "</div></td>" & vbcrlf & "    <td colspan=""3""></td>" & vbcrlf & "   </tr>" & vbcrlf & "             </table>" & vbcrlf & "    </td>" & vbcrlf & "  </tr>" & vbcrlf & "        <tr>" & vbcrlf & "    <td  class=""page"">" & vbcrlf & "       <table width=""100%"" border=""0"" align=""left"" >" & vbcrlf & "  <tr>" & vbcrlf & "    <td width=""8%"" height=""30""><div align=""center"">全选" & vbcrlf & "          <input type=""checkbox"" name=""checkbox2"" id=""chkall"" value=""chkall"" onClick=""mm()"">" & vbcrlf & "    </div></td>" & vbcrlf & "    <td >"
		if open_6_3=1 or open_6_3=3 then
			Response.write "" & vbcrlf & "     <input class=""resetElementHidden"" type=image src=""../images/m_an_del.gif""   onClick=""return test();""  name=submit><input style=""display:none;"" class=""resetElementShow anybutton"" type=submit  value='批量删除' onClick=""return test();""  name=submit>" & vbcrlf & "      "
		end if
		Response.write "" & vbcrlf & "      </td>" & vbcrlf & "    <td width=""85%""><div align=""right"">" & vbcrlf & "    "
		Response.write rs.RecordCount
		Response.write "个 | "
		Response.write currpage
		Response.write "/"
		Response.write rs.pagecount
		Response.write "页 | &nbsp;"
		Response.write rs.pagesize
		Response.write "条信息/页&nbsp;&nbsp;" & vbcrlf & "                <input  name=""cpage"" id=""cpage"" type=""text"" onkeyup=""value=value.replace(/[^\d]/g,'')"" size=""3"" maxlength='8'>" & vbcrlf & "     &nbsp;<input type=""button"" name=""btntz"" value=""跳转""  class=""anybutton2"" onClick=""gotourl('currPage='+document.getElementById('cpage').value);""/>" & vbcrlf & "    "
		if currpage=1 then
			Response.write "" & vbcrlf & "    <input type=""button"" name=""Submit4"" value=""首页"" class=""page""/> <input type=""button"" name=""Submit42"" value=""上一页""  class=""page""/>" & vbcrlf & "    "
		else
			Response.write "" & vbcrlf & "    <input type=""button"" name=""Submit4"" value=""首页"" class=""page"" onClick=""gotourl('currPage=1')""/> <input type=""button"" name=""Submit42"" value=""上一页""  onClick=""gotourl('currPage="
			Response.write  currpage -1
			Response.write "')"" class=""page""/>" & vbcrlf & "    "
		end if
		if currpage=rs.pagecount then
			Response.write "" & vbcrlf & "    <input type=""button"" name=""Submit43"" value=""下一页""  class=""page""/> <input type=""button"" name=""Submit44"" value=""尾页""  class=""page""/>" & vbcrlf & "    "
		else
			Response.write "" & vbcrlf & "   <input type=""button"" name=""Submit43"" value=""下一页""  onClick=""gotourl('currPage="
			Response.write  currpage + 1
			Response.write "')"" class=""page""/> <input type=""button"" name=""Submit43"" value=""尾页""  onClick=""gotourl('currPage="
			Response.write  rs.PageCount
			Response.write "')"" class=""page""/>" & vbcrlf & "    "
		end if
		Response.write "" & vbcrlf & "    </div></td>" & vbcrlf & "  </tr>" & vbcrlf & " </form>" & vbcrlf & "</table>" & vbcrlf & ""
	end if
	rs.close
	set rs=Nothing
	Response.write "" & vbcrlf & "    </td>" & vbcrlf & "  </tr>" & vbcrlf & "</table>" & vbcrlf & "<div id=""User"" style=""position:absolute;width:150; height:200;display:none;"">" & vbcrlf & "<table width=""150"" height=""310""  border=""0"" cellpadding=""-2"" cellspacing=""-2"">" & vbcrlf & "  <tr>" & vbcrlf & "    <td height=""192"">" & vbcrlf & "        <table width=""150"" height=""192"" bgcolor=""#ecf5ff"" border=""0"" >" & vbcrlf & "          <tr valign=""middle"">" & vbcrlf & "            <td height=""24"" colspan=""2"">&nbsp;&nbsp;<a href=""###"" onClick=""gotourl('px=1')""><font color=""#2F496E"">按借款主题排序(降)</font></a></td>" & vbcrlf & "          </tr>" & vbcrlf & "                   <tr  valign=""middle"">" & vbcrlf & "            <td height=""24"" colspan=""2"">&nbsp;&nbsp;<a href=""###"" onClick=""gotourl('px=2')""><font color=""#2F496E"">按借款主题排序(升)</font></a> </td>" & vbcrlf & "          </tr>" & vbcrlf & "               <tr  valign=""middle"">" & vbcrlf & "            <td height=""24"" colspan=""2"">&nbsp;&nbsp;<a href=""###"" onClick=""gotourl('px=3')""><font color=""#2F496E"">按借款日期排序(降)</font></a> </td>" & vbcrlf & "          </tr>" & vbcrlf & "                   <tr  valign=""middle"">" & vbcrlf & "            <tdheight=""24"" colspan=""2"">&nbsp;&nbsp;<a href=""###"" onClick=""gotourl('px=4')""><font color=""#2F496E"">按借款日期排序(升)</font></a> </td>" & vbcrlf & "          </tr>" & vbcrlf & "            <tr  valign=""middle"">" & vbcrlf & "            <td height=""24"" colspan=""2"">&nbsp;&nbsp;<a href=""###"" onClick=""gotourl('px=5')""><font color=""#2F496E"">按添加日期排序(降)</font></a> </td>" & vbcrlf & "          </tr>" & vbcrlf & "                <tr  valign=""middle"">" & vbcrlf & "            <td height=""24"" colspan=""2"">&nbsp;&nbsp;<a href=""###"" onClick=""gotourl('px=6')""><font color=""#2F496E"">按添加日期排序(升)</font></a> </td>" & vbcrlf & "          </tr>" & vbcrlf & "               <tr  valign=""middle"">" & vbcrlf & "            <td height=""24"" colspan=""2"">&nbsp;&nbsp;<a href=""###"" onClick=""gotourl('px=7')""><font color=""#2F496E"">按借款人员排序(降)</font></a> </td>" & vbcrlf & "          </tr>" & vbcrlf & "            <tr  valign=""middle"">" & vbcrlf & "            <td height=""24"" colspan=""2"">&nbsp;&nbsp;<a href=""###"" onClick=""gotourl('px=8')""><font color=""#2F496E"">按借款人员排序(升)</font></a> </td>" & vbcrlf & "          </tr>" & vbcrlf & "           <tr  valign=""middle"">" & vbcrlf & "            <td height=""24"" colspan=""2"">&nbsp;&nbsp;<a href=""###"" onClick=""gotourl('px=9')""><font color=""#2F496E"">按借款金额排序(降)</font></a> </td>" & vbcrlf & "          </tr>" & vbcrlf & "               <tr  valign=""middle"">" & vbcrlf & "            <td height=""24"" colspan=""2"">&nbsp;&nbsp;<a href=""###"" onClick=""gotourl('px=10')""><font color=""#2F496E"">按借款金额排序(升)</font></a> </td>" & vbcrlf & "          </tr>" & vbcrlf & "               <tr  valign=""middle"">" & vbcrlf & "            <td height=""24"" colspan=""2"">&nbsp;&nbsp;<a href=""###"" onClick=""gotourl('px=11')""><font color=""#2F496E"">按审批金额排序(降)</font></a> </td>" & vbcrlf & "          </tr>" & vbcrlf & "               <tr  valign=""middle"">" & vbcrlf & "            <td height=""24"" colspan=""2"">&nbsp;&nbsp;<a href=""###"" onClick=""gotourl('px=12')""><font color=""#2F496E"">按审批金额排序(升)</font></a> </td>" & vbcrlf & "          </tr>" & vbcrlf & "        </table>" & vbcrlf& "    </td>" & vbcrlf & "  </tr>" & vbcrlf & "</table>" & vbcrlf & "</div>" & vbcrlf & "<script language=javascript>" & vbcrlf & "function test()" & vbcrlf & "{" & vbcrlf & "  if(!confirm('确认删除吗？')) return false;" & vbcrlf & "}" & vbcrlf & "function mm()" & vbcrlf & "{" & vbcrlf & "   var a = document.getElementsByTagName(""input"");" & vbcrlf & "   var b=document.getElementById(""chkall"");" & vbcrlf & "   if(b.checked==true)" & vbcrlf & "    {" & vbcrlf & "               for (var i=0; i<a.length; i++)" & vbcrlf & "          {" & vbcrlf & "               if (a[i].type == ""checkbox"")" & vbcrlf & "                      { a[i].checked = true;}" & vbcrlf & "              }" & vbcrlf & "   }" & vbcrlf & "   else" & vbcrlf & "   {" & vbcrlf & "                for (var i=0; i<a.length; i++)" & vbcrlf & "          {" & vbcrlf & "               if (a[i].type == ""checkbox"")" & vbcrlf & "                      {a[i].checked = false;}" & vbcrlf & "         }" & vbcrlf & "   }" & vbcrlf & "}" & vbcrlf &"</script>" & vbcrlf & "" & vbcrlf & "<div id=""w"" title=""高级检索""  style=""width:550px;height:450px;padding:5px;background: #fafafa;top:60px;display:none;""  class=""easyui-window""  closed=""true"" >" & vbcrlf & "<form method=""get"" action=""jklist.asp"" id=""date1"" onSubmit=""return Validator.Validate(this,2)"" name=""date22"">" & vbcrlf & "<div id=""hideDiv"" style=""border-style: none; border-width: 0px; border-color: inherit; margin: 0px; display:none; padding:0px;"">" & vbcrlf & "                       <div region=""center"" border=""false"" style=""padding:5px;background:#fff;border:1px solid #ccc; width:500px"">" & vbcrlf & "                               <div region=""south"" border=""false"" style=""text-align:right;height:30px;line-height:30px;"">" & vbcrlf & "                            <a class=""easyui-linkbutton""  href=""###"" onClick=""document.getElementById('date1').submit()"">确认</a>" & vbcrlf & "                         <a class=""easyui-linkbutton"" href=""###"" onClick=""$('#w').window('close');"">取消</a>" & vbcrlf & "                     </div>" & vbcrlf & "                  <table width=""100%"" border=""0"" cellpadding=""6"" cellspacing=""1"" bgcolor=""#C0CCDD"" id=""content"">" & vbcrlf & "<tr onMouseOut=this.style.backgroundColor="""" onMouseOver=this.style.backgroundColor=""ecf5ff"">" & vbcrlf & vbcrlf & "          <td width=""20%"" class=""func""><div align=""right"">借款主题</div></td>" & vbcrlf & "                  <td width=""80%""><label>" & vbcrlf & "                  <input name=""title"" type=""text"" id=""title"">" & vbcrlf & "          </label></td>" & vbcrlf & "              </tr>" & vbcrlf & "               <tr onMouseOut=this.style.backgroundColor="""" onMouseOver=this.style.backgroundColor=""ecf5ff"">" & vbcrlf & "                 <td width=""20%""><div align=""right"">借款概要</div></td>" & vbcrlf & "                 <td width=""80%""><input name=""intro"" type=""text"" id=""intro""></td>" & vbcrlf & "               </tr>" & vbcrlf & "                          "
	call Show_Search_Extended(1001)
	Response.write "" & vbcrlf & "               <tr onMouseOut=this.style.backgroundColor="""" onMouseOver=this.style.backgroundColor=""ecf5ff"">" & vbcrlf & "                 <td width=""20%""><div align=""right"">借款金额</div></td>" & vbcrlf & "                 <td width=""80%""><input name=""money1"" type=""text"" class=""easyui-numberbox"" id=""money1"" size=""10"" maxlength=""10"" min=""0"" max=""999999999"" precision=""2""  value=""0"">" & vbcrlf & "                   -" & vbcrlf & "                 <input name=""money12"" type=""text"" id=""money12"" size=""10"" maxlength=""10"" class=""easyui-numberbox"" min=""0"" max=""999999999"" precision=""2""  value=""999999999""></td>" & vbcrlf & "               </tr>" & vbcrlf & "                      <tr onMouseOut=this.style.backgroundColor="""" onMouseOver=this.style.backgroundColor=""ecf5ff"">" & vbcrlf & "                 <td width=""20%""><div align=""right"">审批金额</div></td>" & vbcrlf & "                 <td width=""80%""><input name=""money2"" type=""text""  class=""easyui-numberbox"" id=""money2"" size=""10"" maxlength=""10"" min=""0"" max=""999999999"" precision=""2""  value=""0"">" & vbcrlf & "                   -" & vbcrlf & "                 <input name=""money22"" type=""text"" id=""money22"" size=""10"" maxlength=""10"" class=""easyui-numberbox"" min=""0"" max=""999999999"" precision=""2""  value=""999999999""></td>" & vbcrlf & "               </tr>" & vbcrlf & "               <tr onMouseOut=this.style.backgroundColor="""" onMouseOver=this.style.backgroundColor=""ecf5ff"">  " & vbcrlf & "                 <td width=""20%""><div align=""right"">返还金额</div></td>  " & vbcrlf & "                 <td width=""80%""><input name=""returnMoney1"" type=""text""  class=""easyui-numberbox"" id=""returnMoney1"" size=""10"" maxlength=""10"" min=""0"" max=""999999999"" precision=""2""  value=""0"">  " & vbcrlf & "                   -  " & vbcrlf & "                 <input name=""returnMoney2"" type=""text"" id=""returnMoney2"" size=""10"" maxlength=""10"" class=""easyui-numberbox"" min=""0"" max=""999999999"" precision=""2""  value=""999999999""></td>  " & vbcrlf & "               </tr>  " & vbcrlf & "               <tr onMouseOut=this.style.backgroundColor="""" onMouseOver=this.style.backgroundColor=""ecf5ff"">  " & vbcrlf & "                 <td width=""20%""><div align=""right"">抵扣金额</div></td>  " & vbcrlf & "                 <td width=""80%""><input name=""dkMoney1"" type=""text""  class=""easyui-numberbox"" id=""dkMoney1"" size=""10"" maxlength=""10"" min=""0"" max=""999999999"" precision=""2""  value=""0"">  " & vbcrlf & "                   -  " & vbcrlf & "                 <input name=""dkMoney2"" type=""text"" id=""dkMoney2"" size=""10"" maxlength=""10"" class=""easyui-numberbox"" min=""0"" max=""999999999"" precision=""2""  value=""999999999""></td>  " & vbcrlf & "               </tr>  " & vbcrlf & "               <tr onMouseOut=this.style.backgroundColor="""" onMouseOver=this.style.backgroundColor=""ecf5ff"">  " & vbcrlf & "                 <td width=""20%""><div align=""right"">未返还金额</div></td>  " & vbcrlf & "                 <td width=""80%""><input name=""NoreturnMoney1"" type=""text""  class=""easyui-numberbox"" id=""NoreturnMoney1"" size=""10"" maxlength=""10"" min=""0"" max=""999999999"" precision=""2""  value=""0"">  " & vbcrlf & "                   -  " & vbcrlf & "                 <input name=""NoreturnMoney2"" type=""text"" id=""NoreturnMoney2"" size=""10"" maxlength=""10"" class=""easyui-numberbox"" min=""0"" max=""999999999"" precision=""2""  value=""999999999""></td>  " & vbcrlf & "               </tr>  " & vbcrlf & "               " & vbcrlf & "               <tr onMouseOut=this.style.backgroundColor="""" onMouseOver=this.style.backgroundColor=""ecf5ff"">" & vbcrlf & "                 <td width=""20%""><div align=""right"">借款时间</div></td>" & vbcrlf & "                 <td width=""80%"">" & vbcrlf & "                                 <INPUT name=""rett"" size=""9"" readonly id=""duepaydate1divPos"" onmouseup=toggleDatePicker(""duepaydate1div"",""date.rett"") value="""
	Response.write m1
	Response.write """>" & vbcrlf & "                                        <DIV id=""duepaydate1div"" style=""POSITION: absolute;z-index:10"" name =""duepaydate1div""></DIV>-" & vbcrlf & "         <INPUT name=""rett2"" size=""9"" readonly id=""duepaydate2divPos"" onmouseup=toggleDatePicker(""duepaydate2div"",""date.rett2"") value="""
	Response.write m1
	Response.write m2
	Response.write """>" & vbcrlf & "        <DIV id=""duepaydate2div"" style=""POSITION: absolute;z-index:10"" name =""duepaydate2div""></DIV>                           </td>" & vbcrlf & "               </tr>" & vbcrlf & "               <tr onMouseOut=this.style.backgroundColor="""" onMouseOver=this.style.backgroundColor=""ecf5ff"">" & vbcrlf & "                 <td width=""20%""><div align=""right"">借款状态</div></td>" & vbcrlf & "                 <td width=""80%""><select name=""typ"" id=""typ"">" & vbcrlf & "                          <option value=""0"" >全部</option>" & vbcrlf & "                      <option value=""1"" >审批通过</option>" & vbcrlf & "                      <option value=""2"" >待审批</option>" & vbcrlf & "                                 <option value=""4"" >审批中</option>" & vbcrlf & "                            <option value=""3"" >审批未通过</option>" & vbcrlf & "                      </select>" & vbcrlf & "                   </td>" & vbcrlf & "               </tr>" & vbcrlf & "                        <tr onMouseOut=this.style.backgroundColor="""" onMouseOver=this.style.backgroundColor=""ecf5ff"">" & vbcrlf & "                 <td width=""20%""><div align=""right"">币种</div></td>" & vbcrlf & "                 <td width=""80%"">" & vbcrlf & "                                <select name=""listbz"">" & vbcrlf & "                            "
	sql8="select bz from setbz"
	set rs8=conn.execute(sql8)
	bz=rs8("bz")
	set rs8=nothing
	Response.write "" & vbcrlf & "                             <option value="""">币种</option>" & vbcrlf & "                            "
	sql8="select id,sort1 from sortbz order by gate1 desc"
	set rs8=server.CreateObject("adodb.recordset")
	rs8.open sql8,conn,1,1
	if bz<>0 then
		if not rs8.eof then
			do while not rs8.eof
				Response.write "" & vbcrlf & "                             <option value="""
				Response.write rs8("id")
				Response.write """ "
				if cdbl(rs8("id"))=listbz then Response.write "selected"
				Response.write ">"
				Response.write rs8("sort1")
				Response.write "</option>" & vbcrlf & "                            "
				rs8.movenext
			loop
		end if
	else
		Response.write "" & vbcrlf & "                             <option value=""14"">人民币</option>" & vbcrlf & "                                "
	end if
	set rs8=nothing
	Response.write "" & vbcrlf & "                             </select>" & vbcrlf & "                                </td>" & vbcrlf & "               </tr>" & vbcrlf & "                         <tr onMouseOut=this.style.backgroundColor="""" onMouseOver=this.style.backgroundColor=""ecf5ff"">" & vbcrlf & "                 <td width=""20%""><div align=""right"">借款人员</div></td>" & vbcrlf & "                 <td width=""80%"">"
	if sort_zjjg="" or isnull(sort_zjjg) then
		sort_zjjg=1
	end if
	set rs1=server.CreateObject("adodb.recordset")
	sql1="select sort1,qx_open,w1,w2,w3 from power2  where cateid="&session("personzbintel2007")&" and sort1="&sort_zjjg&" "
	rs1.open sql1,conn,1,1
	if rs1.eof then
		open_1_1=0
	else
		open_1_1=rs1("qx_open")
		w1=rs1("w1")
		w2=rs1("w2")
		w3=rs1("w3")
	end if
	rs1.close
	set rs1=nothing
	if open_1_1=1 then
		str_w1="and ord in ("&w1&")"
		str_w2="and ord in ("&w2&")"
		str_w3="and ord in ("&w3&")"
	elseif open_1_1=3 then
		str_w1=""
		str_w2=""
		str_w3=""
	else
		str_w1="and ord=0"
		str_w2="and ord=0"
		str_w3="and ord=0"
	end if
	Correct_W1=0
	Correct_W2=0
	Correct_W3=user_list
	if Correct_W3<>"" and Correct_W3<>"0" then
		tmp=split(getW1W2(Correct_W3),";")
		Correct_W1=tmp(0)
		Correct_W2=tmp(1)
	end if
	Dim SeaStr
	SeaStr = ""
	If IsType = 1 Then
		If Len(dongjie)>0 And dongjie=1 then
			SeaStr = SeaStr & " or del = 2"
		end if
		If Len(huishouzhan)>0 And huishouzhan=1 then
			SeaStr = SeaStr & " or del = 5"
		end if
	end if
	ReDim d_at(54)
	d_at(0) = "Class UserTreeNodeItem"
	d_at(1) = "  Public Nodes,  NodeText,  NodeId,  orgstype,  wsign,del, parent, checked"
	d_at(4) = "  Public Sub setparent(ByRef p) : Set parent = p : End sub"
	d_at(5) = "  Public Function GetJSON()"
	d_at(6) = "          GetJSON = ""{text:"""""" & NodeText & """""",value:"" & NodeId & "",datas:[0,"" & orgstype & ""],wsign:"" & wsign & "", checked:"" & Abs(checked) & "",nodes:"" & nodes.GetJSON & "",del:"" & del & "" }"""
	d_at(7) = "  End function"
	d_at(8) = "End Class"
	d_at(11) = "Class UserTreeNodeList"
	d_at(12) = "        public items,  count, curr"
	d_at(13) = "        Public Sub setcurr(ByRef c)"
	d_at(14) = "                Set curr = c"
	d_at(15) = "        End sub"
	d_at(17) = "        Public Sub Dispose"
	d_at(18) = "                Dim i : Set curr = nothing"
	d_at(19) = "                For i = 0 To count-1"
'd_at(18) = "                Dim i : Set curr = nothing"
	d_at(20) = "                        items(i).Dispose :  Set items(i) = nothing"
	d_at(21) = "                Next"
	d_at(22) = "                Erase items"
	d_at(23) = "        End sub"
	d_at(24) = "        Public function Add(ByRef rs, ByRef w3v, ByRef orgsv, byref realw3)"
	d_at(25) = "                Dim item : Set item = New UserTreeNodeItem"
	d_at(26) = "                If isobject(curr) then  item.setparent curr"
	d_at(27) = "                item.nodetext = rs(""NodeText"").value"
	d_at(28) = "                item.nodeid = rs(""NodeId"").value"
	d_at(29) = "                item.del = rs(""del"").value"
	d_at(30) = "                item.orgstype =  rs(""orgstype"").value"
	d_at(31) = "                item.wsign = rs(""wsign"").value"
	d_at(32) = "                If item.wsign = 3 Then "
	d_at(33) = "                         item.checked = InStr("","" & w3v & "","",  "","" & item.nodeid & "","") > 0 " & vbcrlf & _
	"   if item.checked then " & vbcrlf & _
	"           if len(realw3)>0 then realw3 = realw3 & "","" " & vbcrlf & _
	"           realw3 = realw3 & item.nodeid " & vbcrlf &_
	"   end if"
	d_at(34) = "                Else"
	d_at(35) = "                         item.checked = InStr("","" & orgsv & "","",  "","" & item.nodeid & "","") > 0"
	d_at(36) = "                End If"
	d_at(37) = "                ReDim Preserve items(count)"
	d_at(38) = "                Set items(count) = item"
	d_at(39) = "                Set Add = item"
	d_at(40) = "                count = count + 1"
'd_at(39) = "                Set Add = item"
	d_at(41) = "        End Function"
	d_at(42) = "        Public Function GetJSON"
	d_at(43) = "                Dim i, html "
	'd_at(44) = "                If count>0 Then "
	d_at(45) = "                        ReDim html(count-1)"
''d_at(44) = "                If count>0 Then "
	d_at(46) = "                        For i = 0 To count -1 "
''d_at(44) = "                If count>0 Then "
	d_at(47) = "                                html(i) = items(i).getJSON()"
	d_at(48) = "                        Next"
	d_at(49) = "                        GetJSON = ""["" & Join(html,"","") & ""]"""
	d_at(50) = "                Else"
	d_at(51) = "                        GetJSON = ""[]"""
	d_at(52) = "                End if"
	d_at(53) = "        End function"
	d_at(54) = "End Class"
	execute "On Error Resume Next : ExecuteGlobal Join(d_at, vbcrlf)"
	ReDim d_at(61)
	d_at(0) = "'复选树" & vbCrLf
	d_at(1) = "Function CBaseUserTreeHtml(ByVal sql, ByVal orgsname, ByVal w1name, ByVal w2name, ByVal w3name, ByVal orgsvalue, ByVal w1value,  ByVal w2value,  ByVal w3value)" & vbCrLf
	d_at(2) = " CBaseUserTreeHtml = CBaseUserTreeHtmlCore(sql, orgsname, w1name, w2name, w3name, orgsvalue, w1value, w2value, w3value, ""checkbox"", """")" & vbCrLf
	d_at(3) = "End Function" & vbCrLf
	d_at(4) = "'单选树" & vbCrLf
	d_at(5) = "Function CBaseUserTreeHtmlRadio(ByVal sql, ByVal orgsname, ByVal w1name, ByVal w2name, ByVal w3name, ByVal orgsvalue, ByVal w1value,  ByVal w2value,  ByVal w3value)" & vbCrLf
	d_at(6) = " CBaseUserTreeHtmlRadio = CBaseUserTreeHtmlCore(sql, orgsname, w1name, w2name, w3name, orgsvalue, w1value, w2value, w3value, ""radio"", """")" & vbCrLf
	d_at(7) = "End Function" & vbCrLf
	d_at(8) = "'带事件的单选树" & vbCrLf
	d_at(9) = "Function CBaseUserTreeHtmlRadioCE(ByVal sql, ByVal orgsname, ByVal w1name, ByVal w2name, ByVal w3name, ByVal orgsvalue, ByVal w1value,  ByVal w2value,  ByVal w3value, ByVal changeEvent)" & vbCrLf
	d_at(10) = "        CBaseUserTreeHtmlRadioCE = CBaseUserTreeHtmlCore(sql, orgsname, w1name, w2name, w3name, orgsvalue, w1value, w2value, w3value, ""radio"",  changeEvent)" & vbCrLf
	d_at(11) = "End Function" & vbCrLf
	d_at(12) = "'生成树基本方法" & vbCrLf
	d_at(13) = "Function CBaseUserTreeHtmlCore(byref sql, byref orgsname, byref w1name, byref w2name, byref w3name, byref orgsvalue, byref w1value,  byref w2value,  byref w3value, ByVal checktype, ByVal changeEvent)" & vbCrLf
	d_at(14) = "        Dim htmlid,  htmlsortid, rs, pdeep, currdeep, i, fc, nd, basenodes, nodes, realw3" & vbCrLf
	d_at(15) = "        Randomize :     pdeep =  0 : fc = 0" & vbCrLf
	d_at(16) = "        w3value = Replace(w3value & """","" "","""")" & vbCrLf
	d_at(17) = "        orgsvalue = Replace(orgsvalue & """", "" "" , """")" & vbCrLf
	d_at(18) = "        htmlsortid =CLng(rnd*1000000)" & vbCrLf
	d_at(19) = "        htmlid = ""basetreedata"" & htmlsortid" & vbCrLf  & " on error resume next " & vbcrlf & "if isobject(conn) = false then set conn = cn" & vbcrlf
	d_at(20) = "        on error resume next : Set rs = conn.execute(""exec erp_comm_UsersTreeBase '"" & Replace(sql, ""'"", ""''"") & ""',0"")" & vbCrLf
	d_at(21) = "  if err.number <> 0 then CBaseUserTreeHtmlCore = ""UsersTreeBase错误，SQL:"" & ""exec erp_comm_UsersTreeBase '"" & Replace(sql, ""'"", ""''"") & ""',0"" & "","" & err.description : exit function" & vbcrlf
	d_at(22) = "        Set basenodes = New UserTreeNodeList" & vbCrLf
	d_at(23) = "        Set nodes = basenodes" & vbCrLf
	d_at(24) = "        while rs.eof = False" & vbCrLf
	d_at(25) = "                currdeep =  rs(""NodeDeep"").value" & vbCrLf
	d_at(26) = "                If currdeep > pdeep Then " & vbCrLf
	d_at(27) = "                        Set nodes = nd.nodes" & vbCrLf
	d_at(28) = "                ElseIf currdeep<pdeep then" & vbCrLf
	d_at(29) = "                        For i = currdeep To pdeep" & vbCrLf
	d_at(30) = "                                Set nd = nd.parent" & vbCrLf
	d_at(31) = "                        Next" & vbCrLf
	d_at(32) = "                        If nd Is Nothing Then Err.rasie ""1212"", ""asa"", currdeep & ""=="" & pdeep" & vbCrLf
	d_at(33) = "                        Set nodes = nd.nodes" & vbCrLf
	d_at(34) = "                End If" & vbCrLf
	d_at(35) = "                Set nd = nodes.Add(rs, w3value, orgsvalue, realw3)" & vbCrLf
	d_at(36) = "                pdeep = currdeep" & vbCrLf
	d_at(37) = "                rs.movenext" & vbCrLf
	d_at(38) = "        wend" & vbCrLf
	d_at(39) = "        rs.close" & vbCrLf
	d_at(40) = "       Set rs = Nothing" & vbCrLf
	d_at(41) = "       Dim json : json = ""{nodes:"" & basenodes.getJSON & ""}""" & vbCrLf
	d_at(42) = "       Set nodes = basenodes.Items(0).nodes" & vbCrLf
	d_at(43) = "       For i = 0 To nodes.count-1" & vbCrLf
'd_at(42) = "       Set nodes = basenodes.Items(0).nodes" & vbCrLf
	d_at(44) = "               If nodes.items(i).orgstype = 0 Then" & vbCrLf
	d_at(45) = "                       fc = fc + 1" & vbCrLf
'd_at(44) = "               If nodes.items(i).orgstype = 0 Then" & vbCrLf
	d_at(46) = "               End if" & vbCrLf
	d_at(47) = "       next" & vbCrLf
	d_at(48) = "       basenodes.dispose" & vbCrLf
	d_at(49) = "       Set basenodes = nothing" & vbCrLf
	d_at(50) = "       json = Replace(json,"""""""",""&#34;"")" & vbCrLf
	d_at(51) = "       json = Replace(json,""<"",""&#60;"")" & vbCrLf
	d_at(52) = "       json = Replace(json,"">"",""&#62;"")" & vbCrLf
	d_at(53) = "       json = Replace(json,""&"",""&#38;"")" & vbCrLf
	d_at(54) = "       Dim inputhtml :  inputhtml = """"" & vbCrLf
	d_at(55) = "       If Len(orgsname)>0 Then inputhtml = inputhtml & ""<input checked type='"" & checktype & ""' style='display:none' id='"" & htmlid & ""_orgs' name='"" & orgsname & ""' value='"" &  orgsvalue & ""'>""" & vbCrLf
	d_at(56) = "       If Len(w1name)>0 Then inputhtml = inputhtml & ""<input checked type='"" & checktype & ""' style='display:none'  id='"" & htmlid & ""_w1' name='"" & w1name & ""' value='"" &  w1value & ""'>""" & vbCrLf
	d_at(57) = "       If Len(w2name)>0 Then inputhtml = inputhtml & ""<input checked type='"" & checktype & ""' style='display:none'  id='"" & htmlid & ""_w2' name='"" & w2name & ""' value='"" &  w2value & ""'>""" & vbCrLf
	d_at(58) = "       If Len(w3name)>0 Then inputhtml = inputhtml & ""<input checked type='"" & checktype & ""' style='display:none'  id='"" & htmlid & ""_w3' name='"" & w3name & ""' value='"" &  realw3 & ""'>""" & vbCrLf
	d_at(59) = "       If Len(changeEvent) > 0 Then changeEvent = "" changeEvent="""""" & Replace(changeEvent,"""""""",""&#34;"") & """""" """ & vbCrLf
	d_at(60) = "       CBaseUserTreeHtmlCore = (inputhtml & ""<iframe ""& changeEvent &"" id='"" & htmlid & ""' json="""""") &  json & ("""""" scrolling='no' frameborder='0' src='"" & sdk.getvirpath & ""sdk/baseusertree.htm?checktype="" & checktype &""&signid="" & htmlid & ""' style='background-color:white;display:block;width:96%;height:"" & ((fc+2)*20+12) & ""px'></iframe>"")" & vbCrLf
	d_at(61) = "End function"
	execute "On Error Resume Next : ExecuteGlobal Join(d_at, vbcrlf)"
	If Len(Correct_W3)=0 Then Correct_W3 = request.form("W3") & ""
	If Len(Correct_W3)=0 Then Correct_W3 = request.querystring("W3") & ""
	Response.write  CBaseUserTreeHtml("select ord,orgsid from gate where 1=1 "&str_w3&" and (del=1 "&SeaStr&")","orgsid", "W1","W2","W3",  "", w1, w2, Correct_W3)
	Response.write "</td>" & vbcrlf & "                           </tr>" & vbcrlf & "              </table>" & vbcrlf & "                  </div><br />" & vbcrlf & "                    <div region=""south"" border=""false"" style=""text-align:right;height:27px;line-height:27px;padding-top:5px"">" & vbcrlf & "                             <a class=""easyui-linkbutton""  href=""###"" onClick=xt/javascript"">" & vbcrlf & "function Myopen(divID){" & vbcrlf & "   if(divID.style.display==""""){" & vbcrlf & "              divID.style.display=""none""" & vbcrlf & "        }else{" & vbcrlf & "          divID.style.display=""""" & vbcrlf & "    }" & vbcrlf & "       divID.style.left=300;" & vbcrlf & "   divID.style.top=20;" & vbcrlf & "}" & vbcrlf & "</script>" & vbcrlf & "" & vbcrlf & "<script language=""javascript"">" & vbcrlf & ""
	if remind<>"" then
		Response.write "" & vbcrlf & "jQuery(function(){" & vbcrlf & "   BindCancelEvents({cfgId:"
		Response.write remind
		Response.write "});" & vbcrlf & "});" & vbcrlf & ""
	end if
	Response.write "" & vbcrlf & "</script>" & vbcrlf & ""
	action1="费用借款列表"
	call close_list(1)
	Response.write "" & vbcrlf & "</body>" & vbcrlf & "</html>"
	
%>