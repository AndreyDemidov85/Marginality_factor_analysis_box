
-- =============================================
-- Developer:      IvanIvanov
-- Requestor:      PetrPetrov
-- Create date:    2024-11-08
-- Description:    ��������/����������/ ����������� ��������� ��������� �������� 4-� ������            
-- =============================================

-- �������� �������

CREATE TABLE DWH.db_schema.Marginality_Dim_Products_week_MM 
(
	[nomenkl] [varchar](36) NOT NULL, -- �������� ��� ������ � ����������� �� �������������� ������ � ����� ��������
	[cd_category] [varchar](255) NULL,
	[cd_sub_category_1] [varchar](255) NULL,
	[brand_name] [varchar](255) NULL,
	[manager] [varchar](60) NULL
) 

-- �������� ���������

CREATE PROCEDURE DWH.db_schema.p_Marginality_Dim_Products_week_MM 

AS
BEGIN

	TRUNCATE TABLE DWH.db_schema.Marginality_Dim_Products_week_MM

	INSERT INTO DWH.db_schema.Marginality_Dim_Products_week_MM
			   (nomenkl
			   ,cd_category
			   ,cd_sub_category_1
			   ,brand_name
			   ,manager)
	-- ����� ��������� ������ ������ � �������� �������
	-- ����������� ����������� ����� ��������� � ����������� �� ���������
	-- � ����������� ������ �������
	SELECT mm.nomenkl                       -- ������� (�������������) ������
		  ,dp.cd_category                   -- ������ ��������� ������
		  ,dp.cd_sub_category_1             -- ��������� ������ 
		  ,dp.brand_name                    -- ����� ������
		  ,dp.manager                       -- ������������ �������� 
	FROM (
	      SELECT 
			DISTINCT nomenkl
		  FROM DWH.db_schema.Marginality_Mes_Margin_week_MM
		  ) mm -- ������� �������� �������� ��������� �������� 4-� ����������� ������
	LEFT JOIN <Dim_Products> dp ON mm.nomenkl = dp.nomenkl -- ������������� ���������� ������� ��������
	                                                       -- ��� ����� ������ �� ���������� �����������

END



