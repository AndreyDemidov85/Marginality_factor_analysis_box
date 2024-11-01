
-- =============================================
-- Developer:      IvanIvanov
-- Requestor:      PetrPetrov
-- Create date:    2024-11-08
-- Description:    ��������/����������/ ������� �������� �������� ��������� �������� 4-� ����������� ������              
 -- =============================================

-- �������� �������

CREATE TABLE DWH.db_schema.Marginality_Mes_Margin_week_MM
(
	[nomenkl] [varchar](36) NOT NULL, -- �������� ��� ������ � ����������� �� �������������� ������ � ����� ��������
	[week_num] [int] NULL,
	[kolvo] [decimal](38, 2) NULL,
	[price] [decimal](38, 4) NULL,
	[cost_price] [decimal](38, 4) NULL,
	[price_per_item] [decimal](38, 6) NULL,
	[cost_price_per_item] [decimal](38, 6) NULL
)

-- �������� ���������

CREATE PROCEDURE DWH.db_schema.p_Marginality_Mes_Margin_week_MM

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
   
	-- ������� ������ �� ������ ������������� �����-�����
	DROP TABLE IF EXISTS #mart_margin

	SELECT 
		   s.doc_date                                           -- ���� ������� 
		  ,s.nomenkl                                            -- ������� (�������������) ������
		  ,s.kolvo                                              -- ���������� ������ ���������������� �������� � ������
		  ,s.price                                              -- ��������� �� ������� ������ � ������ � ������ ���������� ������
		  ,s.cost_price                                         -- ������������� ������� ������ � ������ ������
		  ,cal.week_num                                         -- �������� �����(�������������) ������ (�� �������������� �����������-���������)
	INTO #mart_margin
	FROM <Sales_table> s                                        -- ������������� ������� ������ �� ������ �����-�����
	LEFT JOIN <Calendar> cal on cal.cal_date = s.doc_date
	WHERE 1=1
		  and s.doc_date between @start_date and @end_date

	TRUNCATE TABLE DWH.db_schema.Marginality_Mes_Margin_week_MM

	INSERT INTO DWH.db_schema.Marginality_Mes_Margin_week_MM
									   (nomenkl
									   ,week_num
									   ,kolvo
									   ,price
									   ,cost_price
									   ,price_per_item
									   ,cost_price_per_item)
	SELECT
		m.nomenkl
	   ,m.week_num                                                            
	   ,SUM(m.kolvo) as kolvo                                               -- ���������� ��������� ���� ����������� �������� �� ������
	   ,SUM(m.price*m.kolvo) as price                                       -- ��������� ���������� ������ �� ������ � ������ ���������� ������
	   ,SUM(m.cost_price*m.kolvo) as cost_price                             -- ������������� ���������� ������ �� ������
	   ,SUM(m.price*m.kolvo)/SUM(m.kolvo) as price_per_item                 -- ������� ��������� ������� ������ �� ������ � ������ ���������� ������
	   ,SUM(m.cost_price*m.kolvo)/SUM(m.kolvo) as cost_price_per_item       -- ������� ������������� ������� ������ �� ������ � ������ ���������� ������
	FROM #mart_margin m
	GROUP BY
		m.nomenkl
	   ,m.week_num

END



