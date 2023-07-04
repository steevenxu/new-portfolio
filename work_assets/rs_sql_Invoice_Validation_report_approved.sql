//NOTES 

NAME: rs_sql_Invoice_Validation_report.txt 
DESCRIPTION: NOTES: Validate_Invoice_Register Report created as per the requirement.
END NOTES
End Database
End Notes Title Invoice validation report 

//END NOTES


//SQL
Select
	S1
SELECT
	Invoice #,
	IR_Ctrl #,
	VendorCode VendorCode,
	ValidationError,
	upostdate
FROM
	(
		SELECT
			DISTINCT wfts.sName CurrentStep,
			tr.hMy IR_Ctrl #,
			mm.scode PO_SCode,
			r.uLastName + ' (' + rtrim(r.ucode) + ')' Payee,
			p.sCode PropCode,
			tr.uRef Invoice #,
			tr.sTotalAmount Amount,
			'(' + pmu.uName + ')' CreatedBy,
			dbo.Validate_IR_10777408(
				tr.hmy,
				#windowDays#) ValidationError,
				tr.istatus trstatus,
				V.UCODE VendorCode,
				tr.upostdate upostdate
				FROM
					GLInvRegTrans Tr
					INNER JOIN GlInvRegDetail d ON (
						tr.hMy = d.hInvorRec
						ANd Tr.iStatus = 3
						AND isNUll(Tr.iStatus, 0) <> 4
					)
					INNER JOIN property p ON d.hProp = p.hMy
					LEFT JOIN MM2PODET mmdt ON (d.hPODet = mmdt.hmy)
					LEFT JOIN mm2po mm ON (mmdt.hPO = mm.hmy)
					LEFT JOIN wf_tran_header wfth ON wfth.hrecord = tr.hmy
					AND wfth.itype = 20003
					LEFT JOIN wf_tran_step wfts ON wfts.htranheader = wfth.hmy
					AND wfts.bCurrent = - 1 rs_sql_Invoice_Validation_report_approved
					LEFT JOIN acct ac ON (d.hAcct = ac.hMy)
					LEFT JOIN acct acOff ON tr.HOFFSETACCT = acOff.HMY
					LEFT OUTER JOIN person r ON (tr.hPerson = r.hMy)
					LEFT JOIN VENDOR V ON V.HMYPERSON = tr.HPERSON
					LEFT JOIN pmuser pmu ON (Tr.HUSERCREATEDBY = pmu.hmy) #condition1#
					#condition6#
			) XX
		Where
			XX.ValidationError is not null #condition2#
			#condition3#
			#condition4#
			#condition5#
		ORDER BY
			IR_Ctrl #
			/ /
	end
select
	< < Include Read_committed.txt > > / / Columns / / Type Name Head1 Head2 Head3 Head4 Show Color Formula Drill Key Width T,
,
,
,
,
	Invoice #,               Y,      ,       ,       ,       ,     200,
	T,
,
,
,
,
	IR_Ctrl #,               Y,      ,       ,       ,       ,     200,
	T,
,
,
,
,
	VendorCode #,               Y,      ,       ,       ,       ,     200,
	T,
,
,
,
,
	ValidationError,
	Y,
,
,
,
,
	800,
	T,
,
,
,
,
	uPostDate,
	N,
,
,
,
,
	100,
	/ /
End columns / / Filter / / Type,
DataTyp,
Name,
Caption,
Key,
List,
Val1,
Val2,
Mandatory,
Multi - Type,
Select
	C,
	I,
	hProp,
	* Property,
,
	61,
	p.hMy = #hProp#,     																									,         N,           	,      Y,                    
	0,
	T,
	"vendor.uCode",
	"Vendor",
,
	"Select uCode, uLastName from vendor v inner join GLInvRegTrans tr on tr.HPERSON = v.hmyperson inner join person r ON tr.hPerson = r.hMy",
	"VendorCode IN ('#vendor.uCode#')",
,
	N,
,
	Y 0,
	T,
	tr.uRef,
	Invoice #,     		,      	  ,           Invoice# like '#tr.uRef#%',     																				,          ,           	,      Y,                   
	R,
	I,
	beg :end,
	Ctrl #,  		,      	  ,				IR_Ctrl# Between #beg# AND #end#, 									,					 ,						,  		 Y,                  
	R,
	M,
	begmonth :endmonth,
	Post month,
,
,
	uPostDate Between '#begmonth#'
	AND '#endmonth#',
,
,
,
	Y,
	0,
	T,
	windowDays,
	Insurance expiration window #,     		,      	  ,          ,     																				,          Y,           	,      Y,                   
	/ /
end filter

//END SQL