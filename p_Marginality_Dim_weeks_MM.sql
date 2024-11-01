
-- =============================================
-- Developer:      IvanIvanov
-- Requestor:      PetrPetrov
-- Create date:    2024-11-08
-- Description:    ��������/����������/ ����������� ��������� �������� 4-� ������            
-- =============================================

-- �������� �������

CREATE TABLE DWH.db_schema.p_Marginality_Dim_weeks_MM
(
	[week_num] [int] NOT NULL,
	[week_start] [date] NULL,
	[week_end] [date] NULL
)

-- �������� ���������

CREATE PROCEDURE DWH.db_schema.p_Marginality_Dim_weeks_MM

AS
BEGIN

    -- ����� ������� ����������� ������ 
	DECLARE @cur_week_num int = 
	(
	 SELECT 
		<week_num> -- �������� ����� ������
	 FROM <Calendar> -- ������������� ���������� ��������� �������� (��� �������� ��� �������)
	 WHERE [Date] = CAST(getdate() as date)
	 )

	TRUNCATE TABLE DWH.db_schema.Marginality_Dim_weeks_MM
	
	INSERT INTO DWH.db_schema.Marginality_Dim_weeks_MM
           (week_num
           ,week_start
           ,week_end)
	SELECT 
		DISTINCT
		 <week_num>     -- �������� ����� ������
		,<week_start>   -- ���� ������ ������
		,<week_end>     -- ���� ��������� ������ 
	FROM <Calendar> -- ������������� ���������� ��������� �������� (��� �������� ��� �������)
	WHERE <week_num> between @cur_week_num - 4 and @cur_week_num - 1

END



