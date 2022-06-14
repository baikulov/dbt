{{
    config(
        tags=['hits', 'presets'],
        engine='MergeTree()'
    )
}}
WITH
-- находим порядок просмотра страниц
pageview_seq as (
	SELECT
		sessionId,
		hitId,
		row_number() over(partition by sessionId Order By hitTimestamp) as pageview_sequence
	FROM {{ ref('stg_postfix_hits') }}
	WHERE hitType = 'pageview'
),
is_last_page as (
-- находим первую и последнюю страницу
	SELECT sessionId,  max(pageview_sequence) as max_page, min(pageview_sequence) as min_page
	FROM pageview_seq
	GROUP BY sessionId
),
-- джоним порядок страниц к основной таблице
with_pageview_seq as (
	SELECT *
	FROM {{ ref('stg_postfix_hits') }}
	LEFT JOIN pageview_seq using(sessionId, hitId)
),
-- джоним первую и псоледнюю страницу к основной и проставляем значения 0 или 1
final as (
	Select *,
		CASE
			WHEN pageview_sequence = max_page THEN 1
			ELSE 0
		END as isLastPage,
		CASE
			WHEN pageview_sequence = min_page THEN 1
			ELSE 0
		END as isFirstPage
	FROM with_pageview_seq
	LEFT JOIN is_last_page using(sessionId)
),
attrib_event as (
	SELECT *,
		max(pageview_sequence) OVER(partition by sessionId ORDER BY hits_sequence ROWS BETWEEN unbounded PRECEDING AND CURRENT ROW) as attributed_event
	FROM final	
)
SELECT
	date,
	clientId,
	sessionId,
	hitId,
	hitTimestamp,
	hitType,
	eventCategory,
	eventAction,
	eventLabel,
	pageUrl,
	pagePath,
	hits_sequence,
	pageview_sequence,
	attributed_event,
	isLastPage,
	isFirstPage
FROM attrib_event