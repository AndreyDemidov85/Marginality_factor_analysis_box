
-- =============================================
-- Developer:      IvanIvanov
-- Requestor:      PetrPetrov
-- Create date:    2024-11-08
-- Description:    Создание/обновление/ справочника продуктов последних закрытых 4-х недель            
-- =============================================

-- СОЗДАНИЕ ВИТРИНЫ

CREATE TABLE DWH.db_schema.Marginality_Dim_Products_week_MM 
(
	[nomenkl] [varchar](36) NOT NULL, -- выберите тип данных в зависимости от идентификатора товара в вашей компании
	[cd_category] [varchar](255) NULL,
	[cd_sub_category_1] [varchar](255) NULL,
	[brand_name] [varchar](255) NULL,
	[manager] [varchar](60) NULL
) 

-- СОЗДАНИЕ ПРОЦЕДУРЫ

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
	-- набор атрибутов товара выбран в качестве примера
	-- используйте необходимый набор атрибутов в зависимости от специфики
	-- и потребности вашего бизнеса
	SELECT mm.nomenkl                       -- артикул (идентификатор) товара
		  ,dp.cd_category                   -- группа категорий товара
		  ,dp.cd_sub_category_1             -- категория товара 
		  ,dp.brand_name                    -- бренд товара
		  ,dp.manager                       -- категорийный менеджер 
	FROM (
	      SELECT 
			DISTINCT nomenkl
		  FROM DWH.db_schema.Marginality_Mes_Margin_week_MM
		  ) mm -- витрина ОСНОВНЫХ факторов последних закрытых 4-х календарных недель
	LEFT JOIN <Dim_Products> dp ON mm.nomenkl = dp.nomenkl -- корпоративный справочник товаров компании
	                                                       -- или набор данных из нескольких спрвочников

END



