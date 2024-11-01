
-- =============================================
-- Developer:      IvanIvanov
-- Requestor:      PetrPetrov
-- Create date:    2024-11-08
-- Description:    ��������/����������/ ������� ������� �������� ��������� �������� 4-� ����������� ������              
 -- =============================================

 -- �������� �������

 CREATE TABLE DWH.db_schema.Marginality_Mes_Price_week_MM
 (
	[nomenkl] [varchar](36) NOT NULL, -- �������� ��� ������ � ����������� �� �������������� ������ � ����� ��������
	[week_num] [int] NULL,
	[factor_name] [varchar](42) NOT NULL,
	[factor_value] [numeric](38, 6) NULL,
	[kolvo] [decimal](38, 2) NULL
)

 -- �������� ���������

CREATE PROCEDURE DWH.db_schema.p_Marginality_Mes_Price_week_MM

AS
BEGIN

    -- ����� ������� ����������� ������ 
	DECLARE @cur_week_num int = 
	(SELECT 
		<week_num> -- �������� ����� ������
	 FROM <Calendar> -- ������������� ���������� ��������� �������� (��� �������� ��� �������)
	 WHERE [Date] = CAST(getdate() as date))
	
	-- ������ ������� 4� ��������� �������� (���������) ������
	DECLARE @start_date date = --<������ ���� ������ @cur_week_num - 4>
						
	-- ����� ������� 4� ��������� �������� (���������) ������
	DECLARE @end_date date = --<��������� ���� ������ @cur_week_num - 1>


	-- ������� ������ � ������ ������� ��������/������ �� ������ ������������� �����-�����
	DROP TABLE IF EXISTS #mart_price_stage

	SELECT 
		   s.doc_date                                           -- ���� ������� 
		  ,s.nomenkl                                            -- ������� (�������������) ������
		  ,s.kolvo                                              -- ���������� ������ ���������������� �������� � ������
		  ,s.price                                              -- ��������� �� ������� ������ � ������ � ������ ���������� ������
		  ,s.discount                                           -- �������� ������ �� ������� ���������������� ������
		  ,s.price + s.discount as initial_price                -- ��������� �� ������� ������ � ������ ��� ����� ���������� ������
		  ,s.cost_price                                         -- ������������� ������� ������ � ������ ������
		  ,s.discount_type_name									-- �������������/��� ������
		  ,cal.week_num                                         -- �������� �����(�������������) ������ (�� �������������� �����������-���������)
	INTO #mart_price_stage
	FROM <Sales_table> s                                        -- ������������� ������� ������ �� ������ �����-�����
	LEFT JOIN <Calendar> cal on cal.cal_date = s.doc_date
	WHERE 1=1
		  and s.doc_date between @start_date and @end_date

	-- ������ price, initial_price � ���-�� �� ��.

	DROP TABLE IF EXISTS #initial_price

	SELECT nomenkl
		  ,week_num
		  ,SUM(kolvo*initial_price)/SUM(kolvo) as initial_price_per_item
		  ,SUM(kolvo*price)/SUM(kolvo) as price_per_item
		  ,SUM(kolvo) as kolvo
	INTO #initial_price
	FROM #mart_price_stage
	GROUP BY
		   nomenkl
		  ,week_num

	-- ������ ������ ������ �� ����� �� �����-������

	DROP TABLE IF EXISTS #discount_total

	SELECT  nomenkl
		   ,discount_type_name
		   ,week_num
		   ,SUM(discount*kolvo) as discount
	INTO #discount_total
	FROM #mart_price_stage
	WHERE discount_type_name != '��� ������' -- ���������� ��������� ������, ��� ������ �� ���������������
	GROUP BY
		    nomenkl
		   ,week_num
		   ,discount_type_name

    -- ������ ������ ������ �� ����� �� ��.

	DROP TABLE IF EXISTS #discount_by_type

	SELECT 
		 c.nomenkl
		,c.discount_type_name
		,c.week_num
		,c.discount*1.0/p.kolvo*1.0 as discount_by_type_per_item
	INTO #discount_by_type
	FROM #discount_total c
	LEFT JOIN #initial_price p on c.nomenkl = p.nomenkl and c.week_num = p.week_num

	-- ���������� �������

	DROP TABLE IF EXISTS #mart_price_core

	SELECT 
		 nomenkl
		,week_num
		,discount_by_type_per_item as factor_value
		,discount_type_name as factor_name
	INTO #mart_price_core
	FROM #discount_by_type
	UNION ALL
	SELECT 
		nomenkl
		,week_num
		,initial_price_per_item as factor_value
		,'������� ��' as factor_name  -- ��� ��������� ������ ���������� ���������������, 
		                              -- ������ �������� ��� ������� � �������� �������� �������������
									  -- ��������������� �� ��������� �������� ������ � ����� �����������
	FROM #initial_price


	TRUNCATE TABLE DWH.db_schema.Marginality_Mes_Price_week_MM

	INSERT INTO DWH.db_schema.Marginality_Mes_Price_week_MM
										   (nomenkl
										   ,week_num
										   ,factor_name
										   ,factor_value
										   ,kolvo)
	SELECT 
		mp.nomenkl
		,mp.week_num
		,mp.factor_name
		,mp.factor_value
		,ipr.kolvo
	FROM #mart_price_core mp
	LEFT JOIN #initial_price ipr on mp.nomenkl = ipr.nomenkl and mp.week_num =ipr.week_num

END



