/ / NOTES Script 
Name: Pkg_Case10777408.pkg Client 
Name: 
Client PIN: 
Created By: Steven Xu 
Description: created to store the validation errors in IR
/* Package is case specific */
/ /
END NOTES / / SQL IF (
	SELECT
		Object_Id('Validate_IR_10777408')
) IS NOT NULL DROP FUNCTION Validate_IR_10777408
GO
	CREATE FUNCTION dbo.Validate_IR_10777408 (
		@nIRCtrlNo NUMERIC,
		@vExpirationDaysWindowSize NUMERIC
	) RETURNS VARCHAR(1000) AS BEGIN DECLARE @sError VARCHAR(1000)
SELECT
	@sError = COALESCE(@sError + ', ' + CHAR(13) + CHAR(10), '') + XX.Error
FROM
	(
		SELECT
			'Invalid or missing account.' Error
		FROM
			(
				SELECT
					ROW_NUMBER() OVER (
						ORDER BY
							HMY
					) AS ID,
					HINVORREC,
					hACCT
				FROM
					GLInvRegDetail
				WHERE
					HINVORREC = @nIRCtrlNo
			) X
		WHERE
			hAcct IS NULL
		UNION
		SELECT
			'Invalid or missing account on row # ' + convert(VARCHAR(100), X.ID) Error
		FROM
			(
				SELECT
					ROW_NUMBER() OVER (
						ORDER BY
							HMY
					) AS ID,
					HINVORREC,
					hACCT
				FROM
					GLInvRegDetail
				WHERE
					HINVORREC = @nIRCtrlNo
			) X
		WHERE
			hAcct IS NULL
		UNION
		SELECT
			'Total amount does not match detail amounts.'
		FROM
			(
				SELECT
					CASE
						WHEN SUM(glD.SAMOUNT) <> glR.STOTALAMOUNT THEN 0
						ELSE 1
					END TotalMatch
				FROM
					GLInvRegTrans glR
					INNER JOIN GLInvRegDetail glD ON glR.HMY = glD.HINVORREC
				WHERE
					HINVORREC = @nIRCtrlNo
				GROUP BY
					glD.HINVORREC,
					glR.STOTALAMOUNT
			) X
		WHERE
			isNULL(X.TotalMatch, 0) = 0
		UNION
		SELECT
			'Detail Amount cannot be zero.'
		FROM
			(
				SELECT
					SUM(sAmount) detailTotal
				FROM
					GLInvRegDetail
				WHERE
					HINVORREC = @nIRCtrlNo
			) X
		WHERE
			isNULL(X.detailTotal, 0) = 0
		UNION
		SELECT
			'PO validation failed.'
		FROM
			(
				SELECT
					Count(*) mismatchCount
				FROM
					mm2po PO
					INNER JOIN Mm2poDet Pdt ON Po.Hmy = PDt.HPo
					INNER JOIN GlInvRegDetail IRD ON PDt.Hmy = IRD.HPoDet
					INNER JOIN GlINvRegTrans IR ON IRd.Hinvorrec = IR.HMY
					AND PO.Hvendor <> IR.HPerson
				WHERE
					IRD.HINVORREC = @nIRCtrlNo
			) X
		WHERE
			isNULL(X.mismatchCount, 0) <> 0
		UNION
		SELECT
			'Payee doesn''t match PO''s vendor.'
		FROM
			(
				SELECT
					Count(*) mismatchCount
				FROM
					mm2po PO
					INNER JOIN Mm2poDet Pdt ON Po.Hmy = PDt.HPo
					INNER JOIN GlInvRegDetail IRD ON PDt.Hmy = IRD.HPoDet
					INNER JOIN GlINvRegTrans IR ON IRd.Hinvorrec = IR.HMY
					AND PO.Hvendor <> IR.HPerson
				WHERE
					IRD.HINVORREC = @nIRCtrlNo
			) X
		WHERE
			isNULL(X.mismatchCount, 0) <> 0
		UNION
		SELECT
			'Invoice Property doesn''t match PO''s Property.'
		FROM
			(
				SELECT
					Count(*) mismatchCount
				FROM
					mm2po PO
					INNER JOIN Mm2poDet Pdt ON Po.Hmy = PDt.HPo
					INNER JOIN GlInvRegDetail IRD ON PDt.Hmy = IRD.HPoDet
					INNER JOIN GlINvRegTrans IR ON IRd.Hinvorrec = IR.HMY
					AND PDt.HPROP <> IRD.HPROP
				WHERE
					IRD.HINVORREC = @nIRCtrlNo
			) X
		WHERE
			isNULL(X.mismatchCount, 0) <> 0
		UNION
		SELECT
			X.InsuranceException
		FROM
			(
				SELECT
					CASE
						WHEN (
							isNULL(datediff(day, getdate(), V.DDATEWCINSUR), 0) > 0
							AND isNULL(datediff(day, getdate(), V.DDATEWCINSUR), 0) <= @vExpirationDaysWindowSize
						)
						OR (
							isNULL(datediff(day, getdate(), V.DDATELIABINSUR), 0) > 0
							AND isNULL(datediff(day, getdate(), V.DDATELIABINSUR), 0) <= @vExpirationDaysWindowSize
						) THEN 'Vendor insurance will expire within ' + convert(VARCHAR, @vExpirationDaysWindowSize) + ' days'
						WHEN (
							isNULL(datediff(day, getdate(), V.DDATEWCINSUR), 0) < 0
						)
						OR (
							isNULL(datediff(day, getdate(), V.DDATELIABINSUR), 0) < 0
						) THEN 'Vendor insurance expired'
					END InsuranceException
				FROM
					GlINvRegTrans IR
					INNER JOIN Vendor V ON IR.HPERSON = V.HMYPERSON
				WHERE
					IR.HMY = @nIRCtrlNo
			) X
		UNION
		SELECT
			'Invalid PO number.'
		FROM
			(
				SELECT
					count(*) invalidPO
				FROM
					GlINvRegTrans gl2
					INNER JOIN GlInvRegDetail gl1 ON (gl1.HINVORREC = gl2.hmy)
				WHERE
					isnull(gl1.hPODet, 0) <> 0
					AND NOT EXISTS (
						SELECT
							1
						FROM
							mm2poDet
						WHERE
							hmy = gl1.hPODet
					)
					AND gl2.hmy = @nIRCtrlNo
			) X
		WHERE
			X.invalidPO > 0
	) XX RETURN @sError
END / /
END SQL