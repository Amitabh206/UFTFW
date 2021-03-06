'Set Email_Send = 'True' for sending the mail or set it to 'False'
Email_Send = "True"
StrEmailTo = "jaganathan.subramani@fireeye.com;pavankumar.burudu@FireEye.com;amitabh.sinha@FireEye.com"
StrEmailFrom = "jaganathan.subramani@fireeye.com"

'******************************************************************************************'**************************
'Killing excel process as it consumes more memory, also ensuring that excel doesnot hang from Quick Test Professional
'******************************************************************************************'**************************
Dim objWMIService, objProcess, colProcess
Dim strComputer, strProcessKill
strComputer = "."
strProcessKill = "'EXCEL.exe'"
 
Set objWMIService = GetObject("winmgmts:"&"{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
 
Set colProcess = objWMIService.ExecQuery ("Select * from Win32_Process Where Name = " & strProcessKill)
For Each objProcess in colProcess
	objProcess.Terminate()
Next

'******************************************************************************************'**************************
'Execution from UFT
'******************************************************************************************'**************************
Dim dDate,strFoldername
dDate=Now()
strFoldername="Report_"&Month(dDate)&"-"&Day(dDate)&"-"&Year(dDate)&"-"&hour(dDate)&"-"&Minute(dDate)
strDatenTime= Month(dDate)&"-"&Day(dDate)&"-"&Year(dDate)&"-"&hour(dDate)&"-"&Minute(dDate)
dim fso: set fso = CreateObject("Scripting.FileSystemObject")

' directory in which this script is currently running
CurrentDirectory = fso.GetAbsolutePathName(".")
'CurrentDirectory = "C:\Impact\IFS_ProductSuite"
		
Set objExcel = createobject("excel.application")
objExcel.Workbooks.Open CurrentDirectory&"\TestScriptsList.xlsx"
objExcel.Application.Visible = false

Set objSheet = objExcel.ActiveWorkbook.Worksheets("ScriptsList")
 
'Get the max row occupied in the excel file 
iRowCount = objSheet.UsedRange.Rows.Count
'msgbox iRowCount
Set UftApplication = CreateObject("QuickTest.Application")
Set qtApp=CreateObject("QuickTest.Application")
Set qtResultOpt=CreateObject("QuickTest.RunResultsOptions")
qtResultOpt.ResultsLocation= "C:\fireeye-automation\Results\TempResults"
UftApplication.Launch
UftApplication.Visible = true
'To read the data from the entire Excel file
For  i = 2 to iRowCount
	strValue = objSheet.Cells(i,5).Value	
	If ucase(strValue) = "YES" Then
		strTestScript = objSheet.Cells(i,4).Value
		'Msgbox strTestScript
		TestScriptPath = CurrentDirectory&"\ScenarioScripts\"&strTestScript
		UftApplication.Options.Run.RunMode = "Normal"
		UftApplication.Options.Run.ViewResults = False
		UftApplication.Open TestScriptPath, True
		UftApplication.Test.Environment.Value("FolderName")=strFoldername
		UftApplication.Test.Environment.Value("ExecutionType")="Batch"
		UftApplication.Test.Save
		UftApplication.Test.Run	qtResultOpt 

	End If
Next
'Msgbox "Execution Over"
'UftApplication.Open CurrentDirectory&"\ScenarioScripts\SAP_ResultsSummary"
'UftApplication.Test.Environment.Value("FolderName")=strFoldername
'UftApplication.Test.Environment.Value("ExecutionType")="Batch"
'UftApplication.Test.Save
'UftApplication.Test.Run
UftApplication.Quit
Set UftTest = Nothing
Set UftApplication = Nothing
'Msgbox "UFT Tool closure"
objExcel.ActiveWorkbook.Close
objExcel.Application.Quit
Set objSheet = Nothing
Set objExcel = Nothing
'Msgbox "Excel closure"
'******************************************************************************************'**************************
'Killing excel process as it consumes more memory, also ensuring that excel doesnot hang from Quick Test Professional
'******************************************************************************************'************************** 
'Msgbox "Start Excel kill"
Set objWMIService = GetObject("winmgmts:"&"{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
 
Set colProcess = objWMIService.ExecQuery ("Select * from Win32_Process Where Name = " & strProcessKill)
For Each objProcess in colProcess
	objProcess.Terminate()
Next

'******************************************************************************************'**************************
'Zip the Results folder and send a mail to desired recipients
'******************************************************************************************'************************** 
If Email_Send = "TRUE" Then		
	strFiletoZip = "C:\Fireeye_Automation_Lightning\Results\"&strFoldername
	'msgbox "strFoldername = "&strFoldername
	Call Results_to_ZipFile(strFiletoZip)
	WScript.Sleep(10000)
	StrBody = "Hi,"&chr(10)&"Please find attached the detailed report with the results of test cases executed.Also find the Summary report for quick reference."&chr(10)&chr(10)&"Note:To view detailed report kindly save the zip folder,extract it and view the Results."&chr(10)&chr(10)&"Thanks."
	Call SendCDOMessage(StrEmailTo,StrEmailFrom,"ISS BizApps Automation Execution Report - "&strDatenTime,StrBody)
End If 	

	Public Function Results_to_ZipFile(FileName)
		On Error Resume Next 
		strReportPath =FileName
		'msgbox "strReportPath = "&strReportPath
		zipFile=strReportPath & ".zip"
		'msgbox "zipFile = "&zipFile
			
    
		Set objFSO = CreateObject("Scripting.FileSystemObject") 
		If (objFSO.FolderExists(strReportPath)) Then
			'msgbox "Entered the if loop of zipping the file"
			'Create the basis of a zip file.
			CreateObject("Scripting.FileSystemObject") _
			.CreateTextFile(zipFile, True) _
			.Write "PK" & Chr(5) & Chr(6) & String(18, vbNullChar)
			Set objSA = CreateObject("Shell.Application") 
			'msgbox "Add the folder to the Zip"
			' Add the folder to the Zip
			Set objZip = objSA.NameSpace(zipFile)
			Set objFolder = objSA.NameSpace(strReportPath) 
			objZip.CopyHere(objFolder.Items)
			'Wait(10)'In case the Folder is large.
			WScript.Sleep(10000)
			Set objSA =Nothing
			Set objZip =Nothing
			Set objFolder =Nothing
			
			'ReportEvent_FN "PASS","File Zip","File Zip successful"    
			'msgbox "zip successful"
				

		Else
			'ReportEvent_FN "WARNING","Folder not found", "The Folder '" & strReportPath & "' is not present, No results to upload"
			'msgbox "folder not found"
		End If
		Set objFSO =Nothing
	End Function



	Public Function SendCDOMessage(EmailTo, EmailFrom, EmailSubject, MessageBody)
		On Error Resume Next 
		Set myMail=CreateObject("CDO.Message")
		myMail.Subject=EmailSubject
		myMail.From=EmailFrom
		myMail.To=EmailTo
		myMail.TextBody=MessageBody
		myMail.AddAttachment strFiletoZip&".zip"
		myMail.AddAttachment strFiletoZip&"\SummaryChart.html"
		myMail.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2

		myMail.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "owaex.fireeye.com"

		myMail.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25

		myMail.Configuration.Fields.Update
		myMail.Send
		set myMail=nothing
	End Function




