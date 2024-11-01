
-- =============================================
-- Developer:      IvanIvanov
-- Requestor:      PetrPetrov
-- Create date:    2024-11-08
-- Description:    Создание/обновление/ витрины ЦЕНОВЫХ факторов последних закрытых 4-х календарных недель              
 -- =============================================

 -- СОЗДАНИЕ ВИТРИНЫ

 CREATE TABLE DWH.db_schema.Marginality_Mes_Price_week_MM
 (
	[nomenkl] [varchar](36) NOT NULL, -- выберите тип данных в зависимости от идентификатора товара в вашей компании
	[week_num] [int] NULL,
	[factor_name] [varchar](42) NOT NULL,
	[factor_value] [numeric](38, 6) NULL,
	[kolvo] [decimal](38, 2) NULL
)

 -- СОЗДАНИЕ ПРОЦЕДУРЫ

CREATE PROCEDURE DWH.db_schema.p_Marginality_Mes_Price_week_MM

AS
BEGIN

    -- номер текущей календарной недели 
	DECLARE @cur_week_num int = 
	(SELECT 
		<week_num> -- сквозной номер недели
	 FROM <Calendar> -- корпоративный справочник календарь компании (или локально для проекта)
	 WHERE [Date] = CAST(getdate() as date))
	
	-- начало периода 4х последних закрытых (прошедших) недель
	DECLARE @start_date date = --<первый день недели @cur_week_num - 4>
						
	-- конец периода 4х последних закрытых (прошедших) недель
	DECLARE @end_date date = --<последний день недели @cur_week_num - 1>


	-- витрина продаж с учётом ценовых факторов/скидок на уровне гранулярности товар-заказ
	DROP TABLE IF EXISTS #mart_price_stage

	SELECT 
		   s.doc_date                                           -- дата продажи 
		  ,s.nomenkl                                            -- артикул (идентификатор) товара
		  ,s.kolvo                                              -- количество товара соответствующего артикула в заказе
		  ,s.price                                              -- стоимость за единицу товара в заказе с учётом применённых скидок
		  ,s.discount                                           -- величина скидки на единицу соответствующего товара
		  ,s.price + s.discount as initial_price                -- стоимость за единицу товара в заказе без учёта применённых скидок
		  ,s.cost_price                                         -- себестоимость единицы товара в данном заказе
		  ,s.discount_type_name									-- идентификатор/тип скидки
		  ,cal.week_num                                         -- сквозной номер(идентификатор) недели (из корпоративного справочника-календаря)
	INTO #mart_price_stage
	FROM <Sales_table> s                                        -- корпоративная витрина продаж на уровне заказ-товар
	LEFT JOIN <Calendar> cal on cal.cal_date = s.doc_date
	WHERE 1=1
		  and s.doc_date between @start_date and @end_date

	-- расчёт price, initial_price и кол-во на шт.

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

	-- расчёт объема скидки по типам на товар-период

	DROP TABLE IF EXISTS #discount_total

	SELECT  nomenkl
		   ,discount_type_name
		   ,week_num
		   ,SUM(discount*kolvo) as discount
	INTO #discount_total
	FROM #mart_price_stage
	WHERE discount_type_name != 'Без скидок' -- необходимо исключить строки, где скидка не предоставлялась
	GROUP BY
		    nomenkl
		   ,week_num
		   ,discount_type_name

    -- расчёт объема скидки по типам на шт.

	DROP TABLE IF EXISTS #discount_by_type

	SELECT 
		 c.nomenkl
		,c.discount_type_name
		,c.week_num
		,c.discount*1.0/p.kolvo*1.0 as discount_by_type_per_item
	INTO #discount_by_type
	FROM #discount_total c
	LEFT JOIN #initial_price p on c.nomenkl = p.nomenkl and c.week_num = p.week_num

	-- объединяем метрики

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
		,'Влияние ЦО' as factor_name  -- как отдельный фактор выделяется ЦеноОбразование, 
		                              -- фактор применим при наличии в компании процесса динамического
									  -- ценообразования на основании парсинга данных о ценах конкурентов
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



