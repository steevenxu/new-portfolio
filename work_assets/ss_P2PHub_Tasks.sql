//Notes
Copyright (c) 2017 by Yardi Systems, Inc.
  Package Name 

  DESCRIPTION
	This package contains the Task setup used in the P2PHub plugin schema
  NOTES    

  MODIFIED
	Created by - Steven Xu
	
This Schema file creates the tasks used by the P2PHub plugin

P2PHub V2 - February 18th 2019 Matt Thorne

P2P-Audit
P2P-ExportIR
P2P-OOOClean
P2P-PSNotify
P2P-Rebuild
VC-Sync
YMP-ImportIR
YMP-Sync

//End Notes

//SQL
DECLARE @P2PHubVersion VARCHAR
DECLARE @hTask NUMERIC
DECLARE @hTaskStep NUMERIC
DECLARE @htaskStep2 NUMERIC
DECLARE @hRecSch NUMERIC
DECLARE @hTSStepTemplate NUMERIC
DECLARE @hTSStepTemplate2 NUMERIC


SELECT @P2PHubVersion = svalue
FROM paramopt2
WHERE stype = 'P2PHUBVERSIONNUMBER'

IF (
		SELECT count(*)
		FROM tssteptemplate
		WHERE scode = 'apptask'
		) > 0
BEGIN
	SELECT @hTSStepTemplate = hmy
	FROM TSStepTemplate
	WHERE lower(scode) = 'apptask'
END
ELSE
BEGIN
	INSERT INTO sysexceptionlog (
		huser
		,dtdatetime
		,stype
		,sexceptiontext
		)
	VALUES (
		0
		,GetDate()
		,'P2PHub PI' + @P2PHubVersion + ' Schema'
		,'Service Manager schema does not exist in this DB, so Tasks have not been setup successfully'
		)
END

IF (
		SELECT count(*)
		FROM tssteptemplate
		WHERE scode = 'apptask'
		) > 0
BEGIN
	SELECT @hTSStepTemplate2 = hmy
	FROM TSStepTemplate
	WHERE lower(scode) = 'YSTOREDPROCEDURE'
END
ELSE
BEGIN
	INSERT INTO sysexceptionlog (
		huser
		,dtdatetime
		,stype
		,sexceptiontext
		)
	VALUES (
		0
		,GetDate()
		,'P2PHub PI' + @P2PHubVersion + ' Schema'
		,'Service Manager schema does not exist in this DB, so Tasks have not been setup successfully'
		)
END

/* Create the P2P-Audit Task*/
IF NOT EXISTS (
		SELECT *
		FROM TSStepDetail
		WHERE sValue = 'YSI.Utils.PayScan.dll#YSI.Utils.PayScan.TaskClasses.ysiAuditHistoryTask'
		)  AND @hTSStepTemplate > 0 AND @hTSStepTemplate2 > 0
BEGIN
	INSERT INTO TSTask (
		sCode
		,sName
		,sDesc
		,bSysTask
		)
	VALUES (
		'P2P-Audit'
		,'Audit History Task'
		,'This task moves data from the AuditHistory table to the AuditHistoryBackup table, enabling it for viewing from the front end of Voyager.
It is intended that this task be run nightly, outside of business hours. 
The task was created by the P2PHub plugin v' + @P2PHubVersion + '. Please see documentation for additional information.'
		,0
		)

	SELECT @htask = (
			SELECT min(hmy)
			FROM tstask
			WHERE scode = 'P2P-Audit'
			)

	INSERT INTO TSStep (
		hTSStepTemplate
		,hTSTask
		,sName
		,sDesc
		,iOrder
		,bInactive
		,bExecuteOnFailureOnly
		)
	VALUES (
		@hTSStepTemplate
		,@htask
		,'AuditHistory task step'
		,'Executes a YSI.Net class'
		,1
		,- 1
		,0
		)

	SELECT @htaskStep = (
			SELECT min(hmy)
			FROM tsstep
			WHERE htstask = @htask
			)

	INSERT INTO TSStep (
		hTSStepTemplate
		,hTSTask
		,sName
		,sDesc
		,iOrder
		,bInactive
		,bExecuteOnFailureOnly
		)
	VALUES (
		@hTSStepTemplate2
		,@htask
		,'Audit History Backup Stored Proc'
		,'Backup step incase of failure. Executes a Stored Procedure called ForceAuditHistory'
		,2
		,- 1
		,- 1
		)

	SELECT @htaskStep2 = (
			SELECT max(hmy)
			FROM tsstep
			WHERE htstask = @htask
			)

	INSERT INTO TSStepDetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@htaskStep
		,'ClassName'
		,'YSI.Utils.PayScan.dll#YSI.Utils.PayScan.TaskClasses.ysiAuditHistoryTask'
		,0
		)

	INSERT INTO TSStepDetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@htaskStep
		,'PropertySecurityUser'
		,''
		,0
		)

	INSERT INTO TSStepDetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@htaskStep
		,'URL'
		,'&DUMMYDATA=1'
		,0
		)

	INSERT INTO TSStepDetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@htaskStep2
		,'ProcedureName'
		,'ForceAuditHistory'
		,0
		)

	INSERT INTO TSStepDetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@htaskStep2
		,'ProcedureParameters'
		,''
		,0
		)

	INSERT INTO TSStepDetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@htaskStep2
		,'PropertySecurityUser'
		,''
		,0
		)

	INSERT INTO RecurSched (
		iPrimaryPattern
		,iEndType
		,dtStart
		,dtEnd
		,iOccurrences
		,iDayPattern
		,iDayEveryNbrOfDays
		,iDayEveryNbrOfMinutes
		,iDayEveryNbrOfTimes
		,iDayEveryNbrOfHours
		,sDayLastStartTime
		,iWkEveryNbrOfWeeks
		,bAllDayTask
		,bWkSunday
		,bWkMonday
		,bWkTuesday
		,bWkWednesday
		,bWkThursday
		,bWkFriday
		,bWkSaturday
		,iMthPattern
		,iMthEveryNbrOfMonths
		,iMthDayOfMonth
		,iMthWeekOfMonth
		,iMthDayOfWeek
		,iMthNbrDaysToAdd
		,iYrPattern
		,iYrMonthOfYear
		,iYrDayOfMonth
		,iYrWeekOfMonth
		,iYrDayOfWeek
		,sMonthPickedDays
		,hUserCreated
		,dtCreated
		,hUserLastModified
		,dtLastModified
		)
	VALUES (
		0
		,1
		,convert(DATETIME, '07/01/2014', 101)
		,convert(DATETIME, '07/31/2014', 101)
		,0
		,0
		,1
		,0
		,0
		,0
		,'12:00:00 AM'
		,1
		,0
		,0
		,- 1
		,0
		,0
		,0
		,0
		,0
		,0
		,1
		,1
		,1
		,1
		,0
		,0
		,1
		,1
		,1
		,1
		,''
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		)

	SELECT @hRecSch = @@identity

	INSERT INTO RecurSchedDailyTime (
		hRecurSched
		,dTimeStart
		,dDuration
		,bFirstSchedTime
		,bLastSchedTime
		)
	VALUES (
		@hRecSch
		,288000000000
		,18000000000
		,- 1
		,- 1
		)

	INSERT INTO TSSchedule (
		hTSTask
		,hYardiSchedule
		,sName
		,sDesc
		,bInactive
		,dtLastRun
		,iStatus
		,iTimeOut
		,iPriority
		,bNotifyOnFailure
		,sNotifyOnFailureList
		,bNotifyOnSuccess
		,sNotifyOnSuccessList
		)
	VALUES (
		@htask
		,@hRecSch
		,'P2P-Audit'
		,'P2P-Audit'
		,0
		,NULL
		,0
		,0
		,0
		,0
		,''
		,0
		,''
		)
END
ELSE
BEGIN
	INSERT INTO sysexceptionlog (
		huser
		,dtdatetime
		,stype
		,sexceptiontext
		)
	VALUES (
		0
		,GetDate()
		,'P2PHub PI' + @P2PHubVersion + ' Schema'
		,'The P2P-AuditHist task was not created'
		)
END

/* Create P2P-ExportIR Task*/
IF NOT EXISTS (
		SELECT *
		FROM TSStepDetail
		WHERE sValue = 'YSI.P2PHub.dll#YSI.P2PHub.TaskClasses.ExportInvoiceRegister'
		)  AND @hTSStepTemplate > 0 AND @hTSStepTemplate2 > 0

BEGIN
	/*Task Setup*/
	-- Create the Task
	INSERT INTO TSTask (
		sCode
		,sName
		,sDesc
		,bSysTask
		)
	VALUES (
		'P2P-ExportIR'
		,'Export IR Images'
		,'This task exports IR images to PDF, based on the parameters supplied. Optionally it can read from a table in the DB to determine what IRs need processing.
This task is created by the P2PHub Plugin v' + @P2PHubVersion + '. Schema.
Please see documentation for additional information.'
		,0
		)

	SELECT @hTask = (
			SELECT min(hmy)
			FROM tstask
			WHERE scode = 'P2P-ExportIR'
			)

	-- Create the Task Step
	INSERT INTO TSStep (
		hTSStepTemplate
		,hTSTask
		,sName
		,sDesc
		,iOrder
		,bInactive
		,bExecuteOnFailureOnly
		)
	VALUES (
		@hTSStepTemplate
		,@hTask
		,'IR Image Export Task Step'
		,'Do not run this task without consulting documentation first'
		,1
		,- 1
		,0
		)

	SELECT @hTaskStep = hmy
	FROM tsstep
	WHERE htstask = @hTask

	-- Create the Task Step Detail line
	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'ClassName'
		,'YSI.P2PHub.dll#YSI.P2PHub.TaskClasses.ExportInvoiceRegister'
		,0
		)

	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'PropertySecurityUser'
		,''
		,0
		)

	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'URL'
		,'&GroupBy=IR&ZipFiles=1&DeltaInvDateFrom=-7'
		,0
		)

	INSERT INTO RecurSched (
		iPrimaryPattern
		,iEndType
		,dtStart
		,dtEnd
		,iOccurrences
		,iDayPattern
		,iDayEveryNbrOfDays
		,iDayEveryNbrOfMinutes
		,iDayEveryNbrOfTimes
		,iDayEveryNbrOfHours
		,sDayLastStartTime
		,iWkEveryNbrOfWeeks
		,bAllDayTask
		,bWkSunday
		,bWkMonday
		,bWkTuesday
		,bWkWednesday
		,bWkThursday
		,bWkFriday
		,bWkSaturday
		,iMthPattern
		,iMthEveryNbrOfMonths
		,iMthDayOfMonth
		,iMthWeekOfMonth
		,iMthDayOfWeek
		,iMthNbrDaysToAdd
		,iYrPattern
		,iYrMonthOfYear
		,iYrDayOfMonth
		,iYrWeekOfMonth
		,iYrDayOfWeek
		,sMonthPickedDays
		,hUserCreated
		,dtCreated
		,hUserLastModified
		,dtLastModified
		)
	VALUES (
		0
		,1
		,convert(DATETIME, '07/01/2014', 101)
		,convert(DATETIME, '07/31/2014', 101)
		,0
		,0
		,1
		,0
		,0
		,0
		,'12:00:00 AM'
		,1
		,0
		,0
		,- 1
		,0
		,0
		,0
		,0
		,0
		,0
		,1
		,1
		,1
		,1
		,0
		,0
		,1
		,1
		,1
		,1
		,''
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		)

	SELECT @hRecSch = @@identity

	INSERT INTO RecurSchedDailyTime (
		hRecurSched
		,dTimeStart
		,dDuration
		,bFirstSchedTime
		,bLastSchedTime
		)
	VALUES (
		@hRecSch
		,288000000000
		,18000000000
		,- 1
		,- 1
		)

	INSERT INTO TSSchedule (
		hTSTask
		,hYardiSchedule
		,sName
		,sDesc
		,bInactive
		,dtLastRun
		,iStatus
		,iTimeOut
		,iPriority
		,bNotifyOnFailure
		,sNotifyOnFailureList
		,bNotifyOnSuccess
		,sNotifyOnSuccessList
		)
	VALUES (
		@hTask
		,@hRecSch
		,'P2P-ExportIR'
		,'P2P-ExportIR'
		,0
		,NULL
		,0
		,0
		,0
		,0
		,''
		,0
		,''
		)
END
ELSE
BEGIN
	INSERT INTO sysexceptionlog (
		huser
		,dtdatetime
		,stype
		,sexceptiontext
		)
	VALUES (
		0
		,GetDate()
		,'P2PHub PI' + @P2PHubVersion + ' Schema'
		,'The P2P-ExportIR task was not created'
		)
END

--Create the P2P-OOOCleanup Task
IF NOT EXISTS (
		SELECT hmy
		FROM TSTask
		WHERE sCode = 'P2P-OOOClean'
		)   AND @hTSStepTemplate > 0 AND @hTSStepTemplate2 > 0
BEGIN
	-- Create the Task
	INSERT INTO TSTask (
		sCode
		,sName
		,sDesc
		,bSysTask
		)
	VALUES (
		'P2P-OOOClean'
		,'P2P Out Of Office Cleanup'
		,'This task backs up the two tables used for Out of office entries, and then deletes the originals if the expiration date is before today.
It is intended that this task be run nightly, outside of business hours. 
The task was created by the P2PHub plugin v' + @P2PHubVersion + '. Please see documentation for additional information.'
		,0
		)

	SELECT @hTask = @@IDENTITY

	-- Create the Task Step
	INSERT INTO TSStep (
		hTSStepTemplate
		,hTSTask
		,sName
		,sDesc
		,iOrder
		,bInactive
		,bExecuteOnFailureOnly
		)
	VALUES (
		@hTSStepTemplate
		,@hTask
		,'Out Of office cleanup step'
		,'This task fires a SP that backs up all out of office entries whose end date is before today, and then deletes them.'
		,1
		,- 1
		,0
		)

	SELECT @hTaskStep = @@IDENTITY

	-- Create the Task Step Detail line
	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'ProcedureName'
		,'P2P-OOOClean'
		,0
		)

	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'ProcedureParameters'
		,''
		,0
		)

	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'PropertySecurityUser'
		,''
		,0
		)

	INSERT INTO RecurSched (
		iPrimaryPattern
		,iEndType
		,dtStart
		,dtEnd
		,iOccurrences
		,iDayPattern
		,iDayEveryNbrOfDays
		,iDayEveryNbrOfMinutes
		,iDayEveryNbrOfTimes
		,iDayEveryNbrOfHours
		,sDayLastStartTime
		,iWkEveryNbrOfWeeks
		,bAllDayTask
		,bWkSunday
		,bWkMonday
		,bWkTuesday
		,bWkWednesday
		,bWkThursday
		,bWkFriday
		,bWkSaturday
		,iMthPattern
		,iMthEveryNbrOfMonths
		,iMthDayOfMonth
		,iMthWeekOfMonth
		,iMthDayOfWeek
		,iMthNbrDaysToAdd
		,iYrPattern
		,iYrMonthOfYear
		,iYrDayOfMonth
		,iYrWeekOfMonth
		,iYrDayOfWeek
		,sMonthPickedDays
		,hUserCreated
		,dtCreated
		,hUserLastModified
		,dtLastModified
		)
	VALUES (
		0
		,1
		,convert(DATETIME, '07/01/2014', 101)
		,convert(DATETIME, '07/31/2014', 101)
		,0
		,0
		,1
		,0
		,0
		,0
		,'12:00:00 AM'
		,1
		,0
		,0
		,- 1
		,0
		,0
		,0
		,0
		,0
		,0
		,1
		,1
		,1
		,1
		,0
		,0
		,1
		,1
		,1
		,1
		,''
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		)

	SELECT @hRecSch = @@identity

	INSERT INTO RecurSchedDailyTime (
		hRecurSched
		,dTimeStart
		,dDuration
		,bFirstSchedTime
		,bLastSchedTime
		)
	VALUES (
		@hRecSch
		,288000000000
		,18000000000
		,- 1
		,- 1
		)

	INSERT INTO TSSchedule (
		hTSTask
		,hYardiSchedule
		,sName
		,sDesc
		,bInactive
		,dtLastRun
		,iStatus
		,iTimeOut
		,iPriority
		,bNotifyOnFailure
		,sNotifyOnFailureList
		,bNotifyOnSuccess
		,sNotifyOnSuccessList
		)
	VALUES (
		@htask
		,@hRecSch
		,'P2P-OOOClean'
		,'P2P-OOOClean'
		,0
		,NULL
		,0
		,0
		,0
		,0
		,''
		,0
		,''
		)
END
ELSE
BEGIN
	INSERT INTO sysexceptionlog (
		huser
		,dtdatetime
		,stype
		,sexceptiontext
		)
	VALUES (
		0
		,GetDate()
		,'P2PHub PI' + @P2PHubVersion + ' Schema'
		,'The P2P-OOOCleanup task was not created'
		)
END

-- Create P2P-PSNotify
IF NOT EXISTS (
		SELECT *
		FROM tstask
		WHERE scode = 'P2P-PSNotify'
		)   AND @hTSStepTemplate > 0 AND @hTSStepTemplate2 > 0
BEGIN
	INSERT INTO TSTask (
		sCode
		,sName
		,sDesc
		,bSysTask
		)
	VALUES (
		'P2P-PSNotify'
		,'PAYScan Daily Approval Summary Notification'
		,'This task sends a summary notification to all approvers in the system, for objects that are actively in a workflow.
It is intended that this task be run in the early AM, before the start of business each day. 
The task was created by the P2PHub plugin v' + @P2PHubVersion + '. Please see documentation for additional information.'
		,0
		)

	SELECT @htask = (
			SELECT min(hmy)
			FROM tstask
			WHERE scode = 'P2P-PSNotify'
			)

	INSERT INTO TSStep (
		hTSStepTemplate
		,hTSTask
		,sName
		,sDesc
		,iOrder
		,bInactive
		,bExecuteOnFailureOnly
		)
	VALUES (
		@hTSStepTemplate
		,@htask
		,'PAYScan Approval Summary Notification'
		,'Executes a YSI.Net class'
		,1
		,- 1
		,0
		)

	SELECT @htaskStep = (
			SELECT max(hmy)
			FROM tsstep
			WHERE htstask = @htask
			)

	INSERT INTO TSStepDetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@htaskStep
		,'ClassName'
		,'YSI.Utils.AppServices.dll#YSI.Utils.AppServices.ysiNotificationAppTask'
		,0
		)

	INSERT INTO TSStepDetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@htaskStep
		,'PropertySecurityUser'
		,''
		,0
		)

	INSERT INTO TSStepDetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@htaskStep
		,'URL'
		,'NotificationName=P2PHub - ApprovalSummary'
		,0
		)

	INSERT INTO RecurSched (
		iPrimaryPattern
		,iEndType
		,dtStart
		,dtEnd
		,iOccurrences
		,iDayPattern
		,iDayEveryNbrOfDays
		,iDayEveryNbrOfMinutes
		,iDayEveryNbrOfTimes
		,iDayEveryNbrOfHours
		,sDayLastStartTime
		,iWkEveryNbrOfWeeks
		,bAllDayTask
		,bWkSunday
		,bWkMonday
		,bWkTuesday
		,bWkWednesday
		,bWkThursday
		,bWkFriday
		,bWkSaturday
		,iMthPattern
		,iMthEveryNbrOfMonths
		,iMthDayOfMonth
		,iMthWeekOfMonth
		,iMthDayOfWeek
		,iMthNbrDaysToAdd
		,iYrPattern
		,iYrMonthOfYear
		,iYrDayOfMonth
		,iYrWeekOfMonth
		,iYrDayOfWeek
		,sMonthPickedDays
		,hUserCreated
		,dtCreated
		,hUserLastModified
		,dtLastModified
		)
	VALUES (
		0
		,1
		,convert(DATETIME, '07/01/2014', 101)
		,convert(DATETIME, '07/31/2014', 101)
		,0
		,0
		,1
		,0
		,0
		,0
		,'12:00:00 AM'
		,1
		,0
		,0
		,- 1
		,0
		,0
		,0
		,0
		,0
		,0
		,1
		,1
		,1
		,1
		,0
		,0
		,1
		,1
		,1
		,1
		,''
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		)

	SELECT @hRecSch = @@identity

	INSERT INTO RecurSchedDailyTime (
		hRecurSched
		,dTimeStart
		,dDuration
		,bFirstSchedTime
		,bLastSchedTime
		)
	VALUES (
		@hRecSch
		,288000000000
		,18000000000
		,- 1
		,- 1
		)

	INSERT INTO TSSchedule (
		hTSTask
		,hYardiSchedule
		,sName
		,sDesc
		,bInactive
		,dtLastRun
		,iStatus
		,iTimeOut
		,iPriority
		,bNotifyOnFailure
		,sNotifyOnFailureList
		,bNotifyOnSuccess
		,sNotifyOnSuccessList
		)
	VALUES (
		@htask
		,@hRecSch
		,'P2P-PSNotify'
		,'P2P-PSNotify'
		,0
		,NULL
		,0
		,0
		,0
		,0
		,''
		,0
		,''
		)
END
ELSE
BEGIN
	INSERT INTO sysexceptionlog (
		huser
		,dtdatetime
		,stype
		,sexceptiontext
		)
	VALUES (
		0
		,GetDate()
		,'P2PHub PI' + @P2PHubVersion + ' Schema'
		,'The P2P-PSNotify task was not created'
		)
END

-- Create P2P-Rebuild Task
IF NOT EXISTS (
		SELECT *
		FROM TSStepDetail
		WHERE sValue = 'YSI.utils.appservices.dll#YSI.Utils.AppServices.TaskClasses.ysiRebuildWorkflowApproverTask'
		)  AND @hTSStepTemplate > 0 AND @hTSStepTemplate2 > 0
BEGIN
	/*Task Setup*/
	-- Create the Task
	INSERT INTO TSTask (
		sCode
		,sName
		,sDesc
		,bSysTask
		)
	VALUES (
		'P2P-Rebuild'
		,'Rebuild Workflow Approvers'
		,'This task pre-calculates who the approvers for a given object in a workflow should be, and stores those values in the DB.
It is intended that this task be run nightly, outside of business hours. 
The task was created by the P2PHub plugin v' + @P2PHubVersion + '. Please see documentation for additional information.'
		,0
		)

	SELECT @hTask = (
			SELECT min(hmy)
			FROM tstask
			WHERE scode = 'P2P-Rebuild'
			)

	-- Create the Task Step
	INSERT INTO TSStep (
		hTSStepTemplate
		,hTSTask
		,sName
		,sDesc
		,iOrder
		,bInactive
		,bExecuteOnFailureOnly
		)
	VALUES (
		@hTSStepTemplate
		,@hTask
		,'Rebuild Workflow Approvers'
		,'This task rebuilds the Workflow Approvers for all objects that are actively in workflows.'
		,1
		,- 1
		,0
		)

	SELECT @hTaskStep = hmy
	FROM tsstep
	WHERE htstask = @hTask

	-- Create the Task Step Detail line
	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'ClassName'
		,'YSI.utils.appservices.dll#YSI.Utils.AppServices.TaskClasses.ysiRebuildWorkflowApproverTask'
		,0
		)

	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'PropertySecurityUser'
		,''
		,0
		)

	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'URL'
		,''
		,0
		)

	INSERT INTO RecurSched (
		iPrimaryPattern
		,iEndType
		,dtStart
		,dtEnd
		,iOccurrences
		,iDayPattern
		,iDayEveryNbrOfDays
		,iDayEveryNbrOfMinutes
		,iDayEveryNbrOfTimes
		,iDayEveryNbrOfHours
		,sDayLastStartTime
		,iWkEveryNbrOfWeeks
		,bAllDayTask
		,bWkSunday
		,bWkMonday
		,bWkTuesday
		,bWkWednesday
		,bWkThursday
		,bWkFriday
		,bWkSaturday
		,iMthPattern
		,iMthEveryNbrOfMonths
		,iMthDayOfMonth
		,iMthWeekOfMonth
		,iMthDayOfWeek
		,iMthNbrDaysToAdd
		,iYrPattern
		,iYrMonthOfYear
		,iYrDayOfMonth
		,iYrWeekOfMonth
		,iYrDayOfWeek
		,sMonthPickedDays
		,hUserCreated
		,dtCreated
		,hUserLastModified
		,dtLastModified
		)
	VALUES (
		0
		,1
		,convert(DATETIME, '07/01/2014', 101)
		,convert(DATETIME, '07/31/2014', 101)
		,0
		,0
		,1
		,0
		,0
		,0
		,'12:00:00 AM'
		,1
		,0
		,0
		,- 1
		,0
		,0
		,0
		,0
		,0
		,0
		,1
		,1
		,1
		,1
		,0
		,0
		,1
		,1
		,1
		,1
		,''
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		)

	SELECT @hRecSch = @@identity

	INSERT INTO RecurSchedDailyTime (
		hRecurSched
		,dTimeStart
		,dDuration
		,bFirstSchedTime
		,bLastSchedTime
		)
	VALUES (
		@hRecSch
		,288000000000
		,18000000000
		,- 1
		,- 1
		)

	INSERT INTO TSSchedule (
		hTSTask
		,hYardiSchedule
		,sName
		,sDesc
		,bInactive
		,dtLastRun
		,iStatus
		,iTimeOut
		,iPriority
		,bNotifyOnFailure
		,sNotifyOnFailureList
		,bNotifyOnSuccess
		,sNotifyOnSuccessList
		)
	VALUES (
		@hTask
		,@hRecSch
		,'P2P-Rebuild'
		,'P2P-Rebuild'
		,0
		,NULL
		,0
		,0
		,0
		,0
		,''
		,0
		,''
		)
END
ELSE
BEGIN
	INSERT INTO sysexceptionlog (
		huser
		,dtdatetime
		,stype
		,sexceptiontext
		)
	VALUES (
		0
		,GetDate()
		,'P2PHub PI' + @P2PHubVersion + ' Schema'
		,'The P2P-Rebuild task was not created'
		)
END

-- Create VC-Sync Task
IF NOT EXISTS (
		SELECT *
		FROM TSStepDetail
		WHERE sValue = 'YSI.VendorCafe.dll#YSI.VendorCafe.TaskClasses.ysiReSyncEntityTask'
		)  AND @hTSStepTemplate > 0 AND @hTSStepTemplate2 > 0
BEGIN
	INSERT INTO TSTask (
		sCode
		,sName
		,sDesc
		,bSysTask
		)
	VALUES (
		'VC-Sync'
		,'Sync VENDORCafe Vendors'
		,'This task syncs VENDORCafe vendors to the VC servers.
It is intended that this task be run nightly, outside of business hours. 
The task was created by the P2PHub plugin v' + @P2PHubVersion + '. Please see documentation for additional information.'
		,0
		)

	SELECT @hTask = (
			SELECT min(hmy)
			FROM tstask
			WHERE scode = 'VC-Sync'
			)

	INSERT INTO TSStep (
		hTSStepTemplate
		,hTSTask
		,sName
		,sDesc
		,iOrder
		,bInactive
		,bExecuteOnFailureOnly
		)
	VALUES (
		@hTSStepTemplate
		,@hTask
		,'Sync Yardi VENDORCafe Vendors'
		,'This task synchronizes vendors to Yardi VENDORCafe servers'
		,1
		,- 1
		,0
		)

	SELECT @hTaskStep = hmy
	FROM tsstep
	WHERE htstask = @hTask

	INSERT INTO TSStepDetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'ClassName'
		,'YSI.VendorCafe.dll#YSI.VendorCafe.TaskClasses.ysiReSyncEntityTask'
		,0
		)

	INSERT INTO TSStepDetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,''
		,''
		,0
		)

	INSERT INTO TSStepDetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'URL'
		,'&user=vcyardi'
		,0
		)

	INSERT INTO RecurSched (
		iPrimaryPattern
		,iEndType
		,dtStart
		,dtEnd
		,iOccurrences
		,iDayPattern
		,iDayEveryNbrOfDays
		,iDayEveryNbrOfMinutes
		,iDayEveryNbrOfTimes
		,iDayEveryNbrOfHours
		,sDayLastStartTime
		,iWkEveryNbrOfWeeks
		,bAllDayTask
		,bWkSunday
		,bWkMonday
		,bWkTuesday
		,bWkWednesday
		,bWkThursday
		,bWkFriday
		,bWkSaturday
		,iMthPattern
		,iMthEveryNbrOfMonths
		,iMthDayOfMonth
		,iMthWeekOfMonth
		,iMthDayOfWeek
		,iMthNbrDaysToAdd
		,iYrPattern
		,iYrMonthOfYear
		,iYrDayOfMonth
		,iYrWeekOfMonth
		,iYrDayOfWeek
		,sMonthPickedDays
		,hUserCreated
		,dtCreated
		,hUserLastModified
		,dtLastModified
		)
	VALUES (
		0
		,1
		,convert(DATETIME, '07/01/2014', 101)
		,convert(DATETIME, '07/31/2014', 101)
		,0
		,0
		,1
		,0
		,0
		,0
		,'12:00:00 AM'
		,1
		,0
		,0
		,- 1
		,0
		,0
		,0
		,0
		,0
		,0
		,1
		,1
		,1
		,1
		,0
		,0
		,1
		,1
		,1
		,1
		,''
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		)

	SELECT @hRecSch = @@identity

	INSERT INTO RecurSchedDailyTime (
		hRecurSched
		,dTimeStart
		,dDuration
		,bFirstSchedTime
		,bLastSchedTime
		)
	VALUES (
		@hRecSch
		,288000000000
		,18000000000
		,- 1
		,- 1
		)

	INSERT INTO TSSchedule (
		hTSTask
		,hYardiSchedule
		,sName
		,sDesc
		,bInactive
		,dtLastRun
		,iStatus
		,iTimeOut
		,iPriority
		,bNotifyOnFailure
		,sNotifyOnFailureList
		,bNotifyOnSuccess
		,sNotifyOnSuccessList
		)
	VALUES (
		@hTask
		,@hRecSch
		,'VC-Sync'
		,'VC-Sync'
		,0
		,NULL
		,0
		,0
		,0
		,0
		,''
		,0
		,''
		)
END
ELSE
BEGIN
	INSERT INTO sysexceptionlog (
		huser
		,dtdatetime
		,stype
		,sexceptiontext
		)
	VALUES (
		0
		,GetDate()
		,'P2PHub PI' + @P2PHubVersion + ' Schema'
		,'The VC-Sync task was not created'
		)
END

/*Create the YMP EDI IMPORT TASK*/
-- Create Task
IF NOT EXISTS (
		SELECT *
		FROM TSStepDetail
		WHERE sValue = 'YSI.SiteStuff.dll#YSI.SiteStuff.TaskClasses.SiteStuffImportInvoiceTask'
		)  AND @hTSStepTemplate > 0 AND @hTSStepTemplate2 > 0
BEGIN
	/*Task Setup*/
	-- Create the Task
	INSERT INTO TSTask (
		sCode
		,sName
		,sDesc
		,bSysTask
		)
	VALUES (
		'YMP-ImportIR'
		,'Import Electronic Invoices into Voyager from YMP'
		,'This task imports electronic invoices from the Yardi Marketplace servers into Voyager.
It is intended that this task be run nightly, outside of business hours. 
The task was created by the P2PHub plugin v' + @P2PHubVersion + '. Please see documentation for additional information.'
		,0
		)

	SELECT @hTask = (
			SELECT min(hmy)
			FROM tstask
			WHERE scode = 'YMP-ImportIR'
			)

	-- Create the Task Step
	INSERT INTO TSStep (
		hTSStepTemplate
		,hTSTask
		,sName
		,sDesc
		,iOrder
		,bInactive
		,bExecuteOnFailureOnly
		)
	VALUES (
		@hTSStepTemplate
		,@hTask
		,'Import EDI Invoices Step'
		,'This task imports electronic invoices from the Yardi Marketplace servers into Voyager'
		,1
		,- 1
		,0
		)

	SELECT @hTaskStep = hmy
	FROM tsstep
	WHERE htstask = @hTask

	-- Create the Task Step Detail line
	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'ClassName'
		,'YSI.SiteStuff.dll#YSI.SiteStuff.TaskClasses.SiteStuffImportInvoiceTask'
		,0
		)

	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'PropertySecurityUser'
		,''
		,0
		)

	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'URL'
		,'&username=yprocure'
		,0
		)

	INSERT INTO RecurSched (
		iPrimaryPattern
		,iEndType
		,dtStart
		,dtEnd
		,iOccurrences
		,iDayPattern
		,iDayEveryNbrOfDays
		,iDayEveryNbrOfMinutes
		,iDayEveryNbrOfTimes
		,iDayEveryNbrOfHours
		,sDayLastStartTime
		,iWkEveryNbrOfWeeks
		,bAllDayTask
		,bWkSunday
		,bWkMonday
		,bWkTuesday
		,bWkWednesday
		,bWkThursday
		,bWkFriday
		,bWkSaturday
		,iMthPattern
		,iMthEveryNbrOfMonths
		,iMthDayOfMonth
		,iMthWeekOfMonth
		,iMthDayOfWeek
		,iMthNbrDaysToAdd
		,iYrPattern
		,iYrMonthOfYear
		,iYrDayOfMonth
		,iYrWeekOfMonth
		,iYrDayOfWeek
		,sMonthPickedDays
		,hUserCreated
		,dtCreated
		,hUserLastModified
		,dtLastModified
		)
	VALUES (
		0
		,1
		,convert(DATETIME, '07/01/2014', 101)
		,convert(DATETIME, '07/31/2014', 101)
		,0
		,0
		,1
		,0
		,0
		,0
		,'12:00:00 AM'
		,1
		,0
		,0
		,- 1
		,0
		,0
		,0
		,0
		,0
		,0
		,1
		,1
		,1
		,1
		,0
		,0
		,1
		,1
		,1
		,1
		,''
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		)

	SELECT @hRecSch = @@identity

	INSERT INTO RecurSchedDailyTime (
		hRecurSched
		,dTimeStart
		,dDuration
		,bFirstSchedTime
		,bLastSchedTime
		)
	VALUES (
		@hRecSch
		,288000000000
		,18000000000
		,- 1
		,- 1
		)

	INSERT INTO TSSchedule (
		hTSTask
		,hYardiSchedule
		,sName
		,sDesc
		,bInactive
		,dtLastRun
		,iStatus
		,iTimeOut
		,iPriority
		,bNotifyOnFailure
		,sNotifyOnFailureList
		,bNotifyOnSuccess
		,sNotifyOnSuccessList
		)
	VALUES (
		@htask
		,@hRecSch
		,'YMP-ImportIR'
		,'YMP-ImportIR'
		,0
		,NULL
		,0
		,0
		,0
		,0
		,''
		,0
		,''
		)
END
ELSE
BEGIN
	INSERT INTO sysexceptionlog (
		huser
		,dtdatetime
		,stype
		,sexceptiontext
		)
	VALUES (
		0
		,GetDate()
		,'P2PHub PI' + @P2PHubVersion + ' Schema'
		,'The YMP-ImportIR task was not created'
		)
END

/*Create the YMP Sync Task*/
IF NOT EXISTS (
		SELECT *
		FROM TSStepDetail
		WHERE sValue = 'YSI.SiteStuff.dll#YSI.SiteStuff.TaskClasses.SiteStuffSyncEntitiesTask'
		)   AND @hTSStepTemplate > 0 AND @hTSStepTemplate2 > 0
BEGIN
	/*Task Setup*/
	-- Create the Task
	INSERT INTO TSTask (
		sCode
		,sName
		,sDesc
		,bSysTask
		)
	VALUES (
		'YMP-Sync'
		,'Sync Contacts/Properties/Users to Yardi Marketplace'
		,'This task synchronizes Users, Vendors, and Properties to the Yardi Marketplace servers.
It is intended that this task be run nightly, outside of business hours. 
The task was created by the P2PHub plugin v' + @P2PHubVersion + '. Please see documentation for additional information.'
		,0
		)

	SELECT @hTask = (
			SELECT min(hmy)
			FROM tstask
			WHERE scode = 'YMP-Sync'
			)

	-- Create the Task Step
	INSERT INTO TSStep (
		hTSStepTemplate
		,hTSTask
		,sName
		,sDesc
		,iOrder
		,bInactive
		,bExecuteOnFailureOnly
		)
	VALUES (
		@hTSStepTemplate
		,@hTask
		,'Sync Yardi Marketplace Data Step'
		,'This task syncronizes Users, Vendors, and Properties to the Yardi Marketplace servers.'
		,1
		,- 1
		,0
		)

	SELECT @hTaskStep = hmy
	FROM tsstep
	WHERE htstask = @hTask

	-- Create the Task Step Detail line
	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'ClassName'
		,'YSI.SiteStuff.dll#YSI.SiteStuff.TaskClasses.SiteStuffSyncEntitiesTask'
		,0
		)

	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'URL'
		,'&username=yprocure'
		,0
		)

	INSERT INTO tsstepdetail (
		hTSStep
		,sName
		,sValue
		,bPassword
		)
	VALUES (
		@hTaskStep
		,'PropertySecurityUser'
		,''
		,0
		)

	INSERT INTO RecurSched (
		iPrimaryPattern
		,iEndType
		,dtStart
		,dtEnd
		,iOccurrences
		,iDayPattern
		,iDayEveryNbrOfDays
		,iDayEveryNbrOfMinutes
		,iDayEveryNbrOfTimes
		,iDayEveryNbrOfHours
		,sDayLastStartTime
		,iWkEveryNbrOfWeeks
		,bAllDayTask
		,bWkSunday
		,bWkMonday
		,bWkTuesday
		,bWkWednesday
		,bWkThursday
		,bWkFriday
		,bWkSaturday
		,iMthPattern
		,iMthEveryNbrOfMonths
		,iMthDayOfMonth
		,iMthWeekOfMonth
		,iMthDayOfWeek
		,iMthNbrDaysToAdd
		,iYrPattern
		,iYrMonthOfYear
		,iYrDayOfMonth
		,iYrWeekOfMonth
		,iYrDayOfWeek
		,sMonthPickedDays
		,hUserCreated
		,dtCreated
		,hUserLastModified
		,dtLastModified
		)
	VALUES (
		0
		,1
		,convert(DATETIME, '07/01/2014', 101)
		,convert(DATETIME, '07/31/2014', 101)
		,0
		,0
		,1
		,0
		,0
		,0
		,'12:00:00 AM'
		,1
		,0
		,0
		,- 1
		,0
		,0
		,0
		,0
		,0
		,0
		,1
		,1
		,1
		,1
		,0
		,0
		,1
		,1
		,1
		,1
		,''
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		,0
		,convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		)

	SELECT @hRecSch = @@identity

	INSERT INTO RecurSchedDailyTime (
		hRecurSched
		,dTimeStart
		,dDuration
		,bFirstSchedTime
		,bLastSchedTime
		)
	VALUES (
		@hRecSch
		,288000000000
		,18000000000
		,- 1
		,- 1
		)

	INSERT INTO TSSchedule (
		hTSTask
		,hYardiSchedule
		,sName
		,sDesc
		,bInactive
		,dtLastRun
		,iStatus
		,iTimeOut
		,iPriority
		,bNotifyOnFailure
		,sNotifyOnFailureList
		,bNotifyOnSuccess
		,sNotifyOnSuccessList
		)
	VALUES (
		@htask
		,@hRecSch
		,'YMP-Sync'
		,'YMP-Sync'
		,0
		,NULL
		,0
		,0
		,0
		,0
		,''
		,0
		,''
		)
END
ELSE
BEGIN
	INSERT INTO sysexceptionlog (
		huser
		,dtdatetime
		,stype
		,sexceptiontext
		)
	VALUES (
		0
		,GetDate()
		,'P2PHub PI' + @P2PHubVersion + ' Schema'
		,'The YMP-Sync task was not created'
		)
END
//END SQL