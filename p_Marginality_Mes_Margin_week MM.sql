
-- =============================================
-- Developer:      IvanIvanov
-- Requestor:      PetrPetrov
-- Create date:    2024-11-08
-- Description:    —оздание/обновление/ витрины ќ—Ќќ¬Ќџ’ факторов последних закрытых 4-х календарных недель              
 -- =============================================

-- —ќ«ƒјЌ»≈ ¬»“–»Ќџ

CREATE TABLE DWH.db_schema.Marginality_Mes_Margin_week_MM
(
	[nomenkl] [varchar](36) NOT NULL, -- выберите тип данных в зависимости от идентификатора товара в вашей компании
	[week_num] [int] NULL,
	[kolvo] [decimal](38, 2) NULL,
	[price] [decimal](38, 4) NULL,
	[cost_price] [decimal](38, 4) NULL,
	[price_per_item] [decimal](38, 6) NULL,
	[cost_price_per_item] [decimal](38, 6) NULL
)

-- —ќ«ƒјЌ»≈ ѕ–ќ÷≈ƒ”–џ

CREATE PROCEDURE DWH.db_schema.p_Marginality_Mes_Margin_week_MM

AS
BEGIN

    -- номер текущей календарной недели 
	DECLARE @cur_week_num int = 
	(SELECT 
		<week_num> -- сквозной номер недели
	 FROM <Calendar> -- корпоративный справочник календарь компании (или локально дл€ проекта)
	 WHERE [Date] = CAST(getdate() as date))
	
	-- начало периода 4х последних закрытых (прошедших) недель
	DECLARE @start_date date = --<первый день недели @cur_week_num - 4>
						
	-- конец периода 4х последних закрытых (прошедших) недель
	DECLARE @end_date date = --<последний день недели @cur_week_num - 1>
   
	-- витрина продаж на уровне гранул€рности товар-заказ
	DROP TABLE IF EXISTS #mart_margin

	SELECT 
		   s.doc_date                                           -- дата продажи 
		  ,s.nomenkl                                            -- артикул (идентификатор) товара
		  ,s.kolvo                                              -- количество товара соответствующего артикула в заказе
		  ,s.price                                              -- стоимость за единицу товара в заказе с учЄтом применЄнных скидок
		  ,s.cost_price                                         -- себестоимость единицы товара в данном заказе
		  ,cal.week_num                                         -- сквозной номер(идентификатор) недели (из корпоративного справочника-календар€)
	INTO #mart_margin
	FROM <Sales_table> s                                        -- корпоративна€ витрина продаж на уровне заказ-товар
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
	   ,SUM(m.kolvo) as kolvo                                               -- количество проданных штук конкретного артикула за неделю
	   ,SUM(m.price*m.kolvo) as price                                       -- стоимость проданного товара за неделю с учЄтом применЄнных скидок
	   ,SUM(m.cost_price*m.kolvo) as cost_price                             -- себестоимость проданного товара за неделю
	   ,SUM(m.price*m.kolvo)/SUM(m.kolvo) as price_per_item                 -- средн€€ стоимость единицы товара за неделю с учЄтом применЄнных скидок
	   ,SUM(m.cost_price*m.kolvo)/SUM(m.kolvo) as cost_price_per_item       -- средн€€ себестоимость единицы товара за неделю с учЄтом применЄнных скидок
	FROM #mart_margin m
	GROUP BY
		m.nomenkl
	   ,m.week_num

END



