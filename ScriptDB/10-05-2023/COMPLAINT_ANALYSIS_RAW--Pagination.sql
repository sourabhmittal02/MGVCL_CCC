USE [AVVNL_CALL_CENTER]
GO
/****** Object:  StoredProcedure [dbo].[COMPLAINT_ANALYSIS_RAW]    Script Date: 10-05-2023 10:06:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[COMPLAINT_ANALYSIS_RAW]
@OFFICE_ID VARCHAR(10)=1100000,
@START_TIME DATETIME='2022-11-10 00:00:00.000',
@END_TIME DATETIME='2023-01-18 13:19:18.710',
@STARTROWINDEX INT=150, 
@MAXIMUMROWS INT =150, 
@TOTALRECORDS INT=1000 OUTPUT  
AS
BEGIN
	DECLARE @OFFICE_CODE VARCHAR(10),
	@WHERE_CLAUSE nvarchar(MAX),
	@QRY VARCHAR(MAX),
	@LEFT nvarchar(10)
	
	SET @OFFICE_CODE= CASE WHEN SUBSTRING(@OFFICE_ID,6,1)<>0 THEN @OFFICE_ID when SUBSTRING(@OFFICE_ID,5,1)<>0 AND SUBSTRING(@OFFICE_ID,6,1)=0 THEN left(@OFFICE_ID,5)
	when SUBSTRING(@OFFICE_ID,4,1)<>0 AND SUBSTRING(@OFFICE_ID,5,1)=0 THEN left(@OFFICE_ID,4)
	when SUBSTRING(@OFFICE_ID,2,1)<>0 AND SUBSTRING(@OFFICE_ID,4,1)=0 THEN left(@OFFICE_ID,2) 
	when SUBSTRING(@OFFICE_ID,1,1)<>0 AND SUBSTRING(@OFFICE_ID,2,1)=0 THEN left(@OFFICE_ID,1) END

	SET @LEFT= CASE WHEN SUBSTRING(@OFFICE_ID,6,1)<>0 THEN '7' when SUBSTRING(@OFFICE_ID,5,1)<>0 AND SUBSTRING(@OFFICE_ID,6,1)=0 THEN '5'
	when SUBSTRING(@OFFICE_ID,4,1)<>0 AND SUBSTRING(@OFFICE_ID,5,1)=0 THEN '4'
	when SUBSTRING(@OFFICE_ID,2,1)<>0 AND SUBSTRING(@OFFICE_ID,4,1)=0 THEN '2' 
	when SUBSTRING(@OFFICE_ID,1,1)<>0 AND SUBSTRING(@OFFICE_ID,2,1)=0 THEN '1' END

	IF(@OFFICE_ID=0)
	BEGIN
		SELECT CONVERT(VARCHAR,A.OFFICE_CODE)+'-'+B.OFFICE_NAME SDO_NAME,KNO KNUMBER,A.TIME_STAMP REGISTRATION_OF_COMPLAINT,A.COMPLAINT_NO,A.RESOLVED_DATE COMPLAINT_CLOSE_DATE,
		CAST( CAST((DATEDIFF(MINUTE,A.TIME_STAMP,A.RESOLVED_DATE)) AS int) / 60 AS varchar) + ':'  + right('0' + CAST(CAST((DATEDIFF(MINUTE,A.TIME_STAMP,A.RESOLVED_DATE)) AS int) % 60 AS varchar(2)),2) RESOLUTION_IN_HH_MM
		INTO #TEMP
		FROM COMPLAINT(NOLOCK) A 
		LEFT OUTER JOIN MST_OFFICE(NOLOCK) B
		ON A.OFFICE_CODE=B.OFFICE_ID
		LEFT OUTER JOIN CLOSE_COMPLAINT(NOLOCK) C
		ON A.COMPLAINT_NO=C.COMPLAINT_NO 
		WHERE A.TIME_STAMP BETWEEN CASE WHEN ISNULL(@START_TIME,'')='' THEN '1900-01-01' ELSE @START_TIME END AND CASE WHEN ISNULL(@END_TIME,'')='' THEN GETDATE() ELSE @END_TIME END
		SELECT @TOTALRECORDS = COUNT(*) FROM #TEMP
		IF @MAXIMUMROWS= -1
			SET @MAXIMUMROWS=@TOTALRECORDS
		SELECT * FROM #TEMP ORDER BY COMPLAINT_NO ASC OFFSET @STARTROWINDEX ROWS FETCH NEXT @MAXIMUMROWS ROWS ONLY  
	END
	ELSE 
	BEGIN
		SELECT CONVERT(VARCHAR,A.OFFICE_CODE)+'-'+B.OFFICE_NAME SDO_NAME,KNO KNUMBER,A.TIME_STAMP REGISTRATION_OF_COMPLAINT,A.COMPLAINT_NO,A.RESOLVED_DATE COMPLAINT_CLOSE_DATE,
		CAST( CAST((DATEDIFF(MINUTE,A.TIME_STAMP,A.RESOLVED_DATE)) AS int) / 60 AS varchar) + ':'  + right('0' + CAST(CAST((DATEDIFF(MINUTE,A.TIME_STAMP,A.RESOLVED_DATE)) AS int) % 60 AS varchar(2)),2) RESOLUTION_IN_HH_MM
		INTO #TEMP1
		FROM COMPLAINT(NOLOCK) A 
		LEFT OUTER JOIN MST_OFFICE(NOLOCK) B
		ON A.OFFICE_CODE=B.OFFICE_ID
		LEFT OUTER JOIN CLOSE_COMPLAINT(NOLOCK) C
		ON A.COMPLAINT_NO=C.COMPLAINT_NO 
		WHERE A.TIME_STAMP BETWEEN CASE WHEN ISNULL(@START_TIME,'')='' THEN '1900-01-01' ELSE @START_TIME END AND CASE WHEN ISNULL(@END_TIME,'')='' THEN GETDATE() ELSE @END_TIME END
		AND LEFT(OFFICE_CODE,@LEFT) =LEFT(@OFFICE_CODE,@LEFT)
		SELECT @TOTALRECORDS = COUNT(*) FROM #TEMP1
		IF @MAXIMUMROWS= -1
			SET @MAXIMUMROWS=@TOTALRECORDS
		SELECT * FROM #TEMP1 ORDER BY COMPLAINT_NO ASC OFFSET @STARTROWINDEX ROWS FETCH NEXT @MAXIMUMROWS ROWS ONLY  
	END
END
