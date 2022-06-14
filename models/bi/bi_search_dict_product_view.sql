WITH
-- данные по категориям
src_cat as (
	SELECT
		pagePath,
		category_name,
		category_type
	FROM {{ ref('dict_site_categories') }}
),
-- данные по типам страниц
src_dict as (
	SELECT
		pagePath as pageUrl,
		pageType
	FROM {{ ref('dict_pagetype') }}
),
-- находим самое лучшее пересечение между справочниками
jn as (
	SELECT *, position(pageUrl, pagePath) as position
	FROM src_dict
	CROSS JOIN src_cat 
	WHERE position > 0
),
-- ищем минимальное значение т.к. матчим по совпадению в начале строки
aux_min as (
	SELECT
		pageUrl,
		min(position) as position
	FROM jn
	GROUP BY pageUrl
),
-- находим пересечения
jn_pageUrl as (
	SELECT *
	FROM jn
	INNER JOIN aux_min
	ON jn.pageUrl = aux_min.pageUrl
	AND jn.position = aux_min.position
	WHERE pagePath != '/'
),
-- находим все пересечения между справочниками и указываем соответствие если есть совпадение
jn_final as (
	SELECT
		pageUrl,
		pageType,
		category_name,
		category_type
	FROM src_dict
	LEFT JOIN jn_pageUrl using(pageUrl)
)
SELECT
	pageUrl,
	pageType,
	CASE
		WHEN category_name = '' THEN 'not set'
		ELSE category_name
	END as category_name,
	CASE
		WHEN category_type = '' THEN 'not set'
		ELSE category_type
	END as category_type	
FROM jn_final