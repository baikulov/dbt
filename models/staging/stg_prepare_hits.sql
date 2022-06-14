{{
    config(
        materialized='table',
        tags=['presets'],
        engine='MergeTree()',
		order_by=('hitType'),
      	partition_by=('date')
    )
}}

WITH
events as (
	SELECT
		date,
        replaceRegexpAll(hitId, '_.*', '') as clientId,
		sessionId,
		hitId,
		toInt64(replaceRegexpAll(hitId, '.*_', '')) as hitTimestamp,
		'event' as hitType,
		pagePath as pageUrl,
		replaceRegexpAll(pagePath, '\?.*', '') as pagePath,
		eventCategory,
		eventAction,
		eventLabel		
	FROM {{ ref('stg_sessions_events') }}
	WHERE eventCategory in ('Interactions', 'Non_Interactions', 'E-commerce')
),
pages as (
	SELECT
		date,
        replaceRegexpAll(hitId, '_.*', '') as clientId,
		sessionId,
		hitId,
		toInt64(replaceRegexpAll(hitId, '.*_', '')) as hitTimestamp,
		'pageview' as hitType,
		pagePath as pageUrl,
		replaceRegexpAll(pagePath, '\?.*', '') as pagePath,
		'pageview' as eventCategory,
		'pageview' as eventAction,
		'pageview' as eventLabel		
	FROM {{ ref('stg_sessions_pages') }}
),
un as (
	SELECT *
	FROM events
	UNION ALL
	SELECT *
	FROM pages
)
Select
	date,
	clientId,
	sessionId,
	hitId,
	hitTimestamp,
	hitType,
	pageUrl,
	pagePath,
	eventCategory,
	eventAction,
	eventLabel
FROM un