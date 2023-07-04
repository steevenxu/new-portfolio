//NOTES
NAME:			Audit History Setup Package
AUTHOR:			Steven Xu
PURPOSE:		This package sets up the Audit History task including the step 2 Stored Procedure that runs on step 1 failure.

//END NOTES

//SQL
IF (
		SELECT OBJECT_ID('ForceAuditHistory')
		) IS NOT NULL
	DROP PROCEDURE ForceAuditHistory
GO

CREATE PROCEDURE ForceAuditHistory
AS
BEGIN
	-- Perform the movement from one table to the next
	INSERT INTO audithistorybackup (
		hRecord,
		iType,
		hPMUser,
		dtLogDate,
		sLog,
		sTransactionId,
		hParentrecord,
		sRecordIdentifier,
		sRecordCode,
		hParentRecordobjectType,
		iEvent,
		sLogtype,
		hRootRecord,
		iRootRecordObjectType
		)
	SELECT hRecord,
		iType,
		hPMUser,
		dtLogDate,
		sLog,
		sTransactionId,
		hParentrecord,
		sRecordIdentifier,
		sRecordCode,
		hParentRecordobjectType,
		iEvent,
		sLogtype,
		hRootRecord,
		iRootRecordObjectType
	FROM audithistory

	-- Delete the original records so the audit history table becomes managable again
	DELETE ah
	FROM audithistory ah
	JOIN audithistorybackup bu ON bu.dtlogdate = ah.dtlogdate
		AND bu.hrecord = ah.hrecord
		AND bu.itype = ah.itype
END
GO
IF NOT EXISTS (
		SELECT *
		FROM TSStepDetail
		WHERE sValue = 'YSI.Utils.PayScan.dll#YSI.Utils.PayScan.TaskClasses.ysiAuditHistoryTask'
		)
BEGIN
	DECLARE @hAuditTask NUMERIC
	DECLARE @hAuditTaskStep NUMERIC
	DECLARE @hAuditTaskStep2 NUMERIC
	DECLARE @hRecSch NUMERIC

	INSERT INTO TSTask (
		sCode,
		sName,
		sDesc,
		bSysTask
		)
	VALUES (
		'AuditHist',
		'Audit History Task',
		'Task  for AuditHistory report',
		0
		)

	SELECT @hAuditTask = (
			SELECT min(hmy)
			FROM tstask
			WHERE scode = 'Audithist'
			)

	INSERT INTO TSStep (
		hTSStepTemplate,
		hTSTask,
		sName,
		sDesc,
		iOrder,
		bInactive,
		bExecuteOnFailureOnly
		)
	VALUES (
		(
			SELECT hmy
			FROM TSStepTemplate
			WHERE lower(scode) = 'apptask'
			),
		@hAuditTask,
		'Application Task for AuditHistory',
		'Executes YSI.NET Class',
		1,
		0,
		0
		)

	SELECT @hAuditTaskStep = (
			SELECT min(hmy)
			FROM tsstep
			WHERE htstask = @hAuditTask
			)

	INSERT INTO TSStep (
		hTSStepTemplate,
		hTSTask,
		sName,
		sDesc,
		iOrder,
		bInactive,
		bExecuteOnFailureOnly
		)
	VALUES (
		(
			SELECT min(hmy)
			FROM TSStepTemplate
			WHERE lower(scode) = 'YSTOREDPROCEDURE'
			),
		@hAuditTask,
		'Audit History Backup SPROC',
		'Backup step incase of failure. Executes a Stored Procedure called ForceAuditHistory',
		2,
		0,
		- 1
		)

	SELECT @hAuditTaskStep2 = (
			SELECT max(hmy)
			FROM tsstep
			WHERE htstask = @hAuditTask
			)

	INSERT INTO TSStepDetail (
		hTSStep,
		sName,
		sValue,
		bPassword
		)
	VALUES (
		@hAuditTaskStep,
		'ClassName',
		'YSI.Utils.PayScan.dll#YSI.Utils.PayScan.TaskClasses.ysiAuditHistoryTask',
		0
		)

	INSERT INTO TSStepDetail (
		hTSStep,
		sName,
		sValue,
		bPassword
		)
	VALUES (
		@hAuditTaskStep,
		'PropertySecurityUser',
		'',
		0
		)

	INSERT INTO TSStepDetail (
		hTSStep,
		sName,
		sValue,
		bPassword
		)
	VALUES (
		@hAuditTaskStep,
		'URL',
		'&DUMMYDATA=1',
		0
		)

	INSERT INTO TSStepDetail (
		hTSStep,
		sName,
		sValue,
		bPassword
		)
	VALUES (
		@hAuditTaskStep2,
		'ProcedureName',
		'ForceAuditHistory',
		0
		)

	INSERT INTO TSStepDetail (
		hTSStep,
		sName,
		sValue,
		bPassword
		)
	VALUES (
		@hAuditTaskStep2,
		'ProcedureParameters',
		'',
		0
		)

	INSERT INTO TSStepDetail (
		hTSStep,
		sName,
		sValue,
		bPassword
		)
	VALUES (
		@hAuditTaskStep2,
		'PropertySecurityUser',
		'',
		0
		)

	INSERT INTO RecurSched (
		iPrimaryPattern,
		iEndType,
		dtStart,
		dtEnd,
		iOccurrences,
		iDayPattern,
		iDayEveryNbrOfDays,
		iDayEveryNbrOfMinutes,
		iDayEveryNbrOfTimes,
		iDayEveryNbrOfHours,
		sDayLastStartTime,
		iWkEveryNbrOfWeeks,
		bAllDayTask,
		bWkSunday,
		bWkMonday,
		bWkTuesday,
		bWkWednesday,
		bWkThursday,
		bWkFriday,
		bWkSaturday,
		iMthPattern,
		iMthEveryNbrOfMonths,
		iMthDayOfMonth,
		iMthWeekOfMonth,
		iMthDayOfWeek,
		iMthNbrDaysToAdd,
		iYrPattern,
		iYrMonthOfYear,
		iYrDayOfMonth,
		iYrWeekOfMonth,
		iYrDayOfWeek,
		sMonthPickedDays,
		hUserCreated,
		dtCreated,
		hUserLastModified,
		dtLastModified
		)
	VALUES (
		0,
		1,
		convert(DATETIME, '07/01/2014', 101),
		convert(DATETIME, '07/31/2014', 101),
		0,
		0,
		1,
		0,
		0,
		0,
		'12:00:00 AM',
		1,
		0,
		0,
		- 1,
		0,
		0,
		0,
		0,
		0,
		0,
		1,
		1,
		1,
		1,
		0,
		0,
		1,
		1,
		1,
		1,
		'',
		0,
		convert(DATETIME, '08/01/2014 06:17:24PM', 101),
		0,
		convert(DATETIME, '08/01/2014 06:17:24PM', 101)
		)

	SELECT @hRecSch = @@identity

	INSERT INTO RecurSchedDailyTime (
		hRecurSched,
		dTimeStart,
		dDuration,
		bFirstSchedTime,
		bLastSchedTime
		)
	VALUES (
		@hRecSch,
		288000000000,
		18000000000,
		- 1,
		- 1
		)

	INSERT INTO TSSchedule (
		hTSTask,
		hYardiSchedule,
		sName,
		sDesc,
		bInactive,
		dtLastRun,
		iStatus,
		iTimeOut,
		iPriority,
		bNotifyOnFailure,
		sNotifyOnFailureList,
		bNotifyOnSuccess,
		sNotifyOnSuccessList
		)
	VALUES (
		@hAuditTask,
		@hRecSch,
		'Audit History',
		'Audit History',
		0,
		NULL,
		0,
		0,
		0,
		0,
		'',
		0,
		0
		)
END
// END SQL