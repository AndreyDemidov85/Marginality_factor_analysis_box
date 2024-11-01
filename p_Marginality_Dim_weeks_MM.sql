
-- =============================================
-- Developer:      IvanIvanov
-- Requestor:      PetrPetrov
-- Create date:    2024-11-08
-- Description:    Создание/обновление/ справочника последних закрытых 4-х недель            
-- =============================================

-- СОЗДАНИЕ ВИТРИНЫ

CREATE TABLE DWH.db_schema.p_Marginality_Dim_weeks_MM
(
	[week_num] [int] NOT NULL,
	[week_start] [date] NULL,
	[week_end] [date] NULL
)

-- СОЗДАНИЕ ПРОЦЕДУРЫ

CREATE PROCEDURE DWH.db_schema.p_Marginality_Dim_weeks_MM

AS
BEGIN

    -- номер текущей календарной недели 
	DECLARE @cur_week_num int = 
	(
	 SELECT 
		<week_num> -- сквозной номер недели
	 FROM <Calendar> -- корпоративный справочник календарь компании (или локально для проекта)
	 WHERE [Date] = CAST(getdate() as date)
	 )

	TRUNCATE TABLE DWH.db_schema.Marginality_Dim_weeks_MM
	
	INSERT INTO DWH.db_schema.Marginality_Dim_weeks_MM
           (week_num
           ,week_start
           ,week_end)
	SELECT 
		DISTINCT
		 <week_num>     -- сквозной номер недели
		,<week_start>   -- дата начала недели
		,<week_end>     -- дата окончания недели 
	FROM <Calendar> -- корпоративный справочник календарь компании (или локально для проекта)
	WHERE <week_num> between @cur_week_num - 4 and @cur_week_num - 1

END



