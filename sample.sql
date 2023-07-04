// SQL --SP CREATION--
IF (
    SELECT
        count(*)
    FROM
        sys.TABLES
    WHERE
        NAME = 'CustomExportTable'
) > 0 DROP TABLE CustomExportTable BEGIN CREATE TABLE [CustomExportTable] (
    [hMy] NUMERIC(18, 0) IDENTITY,
    [hRecord] NUMERIC(32, 0) NOT NULL,
    [dtStamp] [datetime] NOT NULL
)
END / /
END SQL / / SQL IF (
    SELECT
        OBJECT_ID('CustomExportIRImages')
) IS NOT NULL BEGIN DROP PROCEDURE CustomExportIRImages
END
GO
    CREATE PROCEDURE CustomExportIRImages AS BEGIN TRUNCATE TABLE glinvregexportdetail
INSERT INTO
    glinvregexportdetail (
        hrecord,
        ipage,
        hbatch,
        hfile,
        istatus,
        dtexported,
        sresult
    )
SELECT
    g.hmy,
    s.ipage,
    0,
    0,
    0,
    NULL,
    NULL
FROM
    glinvregtrans g
    JOIN sysscanimage s ON g.hmy = s.hrecord
    AND s.itype = 20003
WHERE
    1 = 1
    AND g.hmy NOT IN (
        SELECT
            hrecord
        FROM
            CustomExportTable
    )
INSERT INTO
    CustomExportTable (hrecord, dtstamp)
SELECT
    DISTINCT hrecord,
    GETDATE()
FROM
    GLInvRegExportDetail
END
GO
    --task creation
    BEGIN TRANSACTION IF NOT EXISTS (
        SELECT
            *
        FROM
            TSStepDetail tsd
            JOIN TSStep ts on ts.hmy = tsd.htsstep --this is the ClassName field on task runner step detail--
        WHERE
            tsd.sValue = 'YSI.P2PHub.dll#YSI.P2PHub.TaskClasses.ExportInvoiceRegister'
            AND ts.sname = 'IrExpTsk6' --IMPORTANT VARIABLE NAME--
    ) BEGIN DECLARE @hTask NUMERIC DECLARE @hTaskStep NUMERIC DECLARE @hRecSch NUMERIC DECLARE @hVolume NUMERIC DECLARE @hStepValue INT DECLARE @hPropLen NUMERIC DECLARE @tempvar VARCHAR
SELECT
    @hPropLen = count(*)
FROM
    listprop l
    JOIN property p ON p.hmy = l.hproplist
WHERE
    p.scode = 'all'
set
    @hStepValue = 1 --export starts on step 1, sp is 0
SELECT
    @hVolume = count(sys.ipage)
from
    glinvregtrans gl
    join glinvregdetail gld on gld.hinvorrec = gl.hmy
    join property p on p.hmy = gld.hprop
    join sysscanimage sys on sys.hrecord = gld.hinvorrec
where
    p.hmy in (
        select
            l.hproperty
        from
            listprop l
            join property p on p.hmy = l.hproplist
        where
            p.scode = 'all'
    ) --IMPORTANT VARIABLE NAME--
    and gl.istatus = 4 --inserting task--
INSERT INTO
    TSTask (sCode, sName, sDesc, bSysTask)
VALUES
    (
        'IrExpTsk6',
        'invoice image export task',
        'this task exports all invoice images for a set list of properties',
        0
    ) --assigning the first instance of task to @htask variable - need to modify scode--		
SELECT
    @hTask = (
        SELECT
            min(hmy)
        FROM
            tstask
        WHERE
            scode = 'IrExpTsk6'
    ) --inserting task step--
INSERT INTO
    TSStep (
        hTSStepTemplate,
        hTSTask,
        sName,
        sDesc,
        iOrder,
        bInactive,
        bExecuteOnFailureOnly
    )
VALUES
    (
        (
            SELECT
                min(hmy)
            FROM
                TSStepTemplate
            WHERE
                lower(scode) = 'YSTOREDPROCEDURE'
        ),
        @hTask,
        'Invoice Image Export Task',
        'Invoice Image Export Task Task Task',
        0,
        0,
        -1
    )
SELECT
    @hTaskStep = (
        SELECT
            max(hmy) --changed from min() to max() as the taskstep will grow
        FROM
            tsstep
        WHERE
            htstask = @hTask
    ) --inserting task detail--
INSERT INTO
    TSStepDetail (
        hTSStep,
        sName,
        sValue,
        bPassword
    )
VALUES
    (
        @hTaskStep,
        'ProcedureName',
        'CustomExportIRImages',
        0
    )
INSERT INTO
    TSStepDetail (
        hTSStep,
        sName,
        sValue,
        bPassword
    )
VALUES
    (
        @hTaskStep,
        'ProcedureParameters',
        '',
        0
    )
INSERT INTO
    TSStepDetail (
        hTSStep,
        sName,
        sValue,
        bPassword
    )
VALUES
    (
        @hTaskStep,
        'PropertySecurityUser',
        '',
        0
    ) --now creating actual export task steps--
    WHILE (@hStepValue <= @hPropLen) BEGIN
    /* 	SELECT @tempvar =   
     cast(pr.scode as varchar)
     from
     property p
     join listprop l on l.hproplist = p.hmy
     join property pr on pr.hmy = l.hproperty
     where
     p.scode = 'all'
     order by pr.scode offset (@hStepValue-1) row
     FETCH NEXT 1 ROW ONLY */
INSERT INTO
    TSStep (
        hTSStepTemplate,
        hTSTask,
        sName,
        sDesc,
        iOrder,
        bInactive,
        bExecuteOnFailureOnly
    )
VALUES
    (
        (
            SELECT
                MIN(hmy)
            FROM
                TSStepTemplate
            WHERE
                LOWER(scode) = 'apptask'
        ),
        @hTask,
        'Invoice Export ' + CAST(@hStepValue as varchar),
        'This task exports',
        @hStepValue --this would need to be int auto-increment, so new variable staring at 1 (since 0 is the SP)
,
        0,
        0
    )
SELECT
    @hTaskStep = (
        SELECT
            max(hmy) --changing the select to now match the last entry in the task step
        FROM
            tsstep
        WHERE
            htstask = @hTask
    )
INSERT INTO
    tsstepdetail (
        hTSStep,
        sName,
        sValue,
        bPassword
    )
VALUES
    (
        @hTaskStep,
        'ClassName',
        'YSI.P2PHub.dll#YSI.P2PHub.TaskClasses.ExportInvoiceRegister',
        0
    )
INSERT INTO
    tsstepdetail (
        hTSStep,
        sName,
        sValue,
        bPassword
    )
VALUES
    (
        @hTaskStep,
        'PropertySecurityUser',
        '',
        0
    )
INSERT INTO
    tsstepdetail (
        hTSStep,
        sName,
        sValue,
        bPassword
    )
VALUES
    (
        @hTaskStep,
        'URL',
        '&Property=' +(
            SELECT
                pr.scode
            from
                property p
                join listprop l on l.hproplist = p.hmy
                join property pr on pr.hmy = l.hproperty
            where
                p.scode = 'all'
            order by
                pr.scode offset (@hStepValue -1) row FETCH NEXT 1 ROW ONLY
        ) + '&InvDateFrom=01/01/2018&ZipFiles=1&OverrideLimiter=1&ExportPath=\\asp1\hfs\hUsersdefpaths\Nicolosi and Fitch\Live\InvoiceRegisterExport\'+(SELECT  
																																														pr.scode from
																																														  property p
																																														  join listprop l on l.hproplist = p.hmy
																																														  join property pr on pr.hmy = l.hproperty
																																														where
																																															p.scode = ' all '
																																														order by pr.scode offset (@hStepValue-1) row
																																														FETCH NEXT 1 ROW ONLY)+' \ & GroupBy = IR ' --property, InvDateFrom, ExportPath need to be changed to varchar"
        ,0
        )
	
	SET @hStepValue = @hStepValue + 1

END

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
			,convert(DATETIME, ' 07 / 01 / 2014 ', 101)
			,convert(DATETIME, ' 07 / 31 / 2014 ', 101)
			,0
			,0
			,1
			,0
			,0
			,0
			,' 12 :00 :00 AM '
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
			,convert(DATETIME, ' 08 / 01 / 2014 06 :17 :24PM ', 101)
			,0
			,convert(DATETIME, ' 08 / 01 / 2014 06 :17 :24PM ', 101)
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
			,' InvImgExport '
			,' Invoice Image Export '
			,0
			,NULL
			,0
			,0
			,0
			,0
			,''
			,0
			,0
			)

END

IF @@error > 0
	GOTO ROLL_BACK

COMMIT

RETURN

ROLL_BACK:

ROLLBACK

//END SQL