WITH
-- находим дубли хитов если есть
duplicates as (
	select
	    hitId,
	    count(*) as n_records
	from {{ ref('stg_prepare_hits') }}
	where hitId is not null
	group by hitId
	having count(*) > 1
),
-- выбираем их в отдельную таблицу
t as (
	SELECT
		clientId,
		hitId,
        hitType,
		pagePath,
		hitTimestamp
	FROM {{ ref('stg_prepare_hits') }}
	WHERE hitId in (SELECT hitId FROM duplicates)
	ORDER BY clientId, hitTimestamp
),
-- считаем для каждой записи с дублем, количество предыдущих строчек, Чтобы потом это значение прибавить к timestamp
count_duplicates as (
	SELECT
		*,
		COUNT(*) OVER(partition by clientId, hitTimestamp ORDER BY hitTimestamp ROWS BETWEEN unbounded PRECEDING AND CURRENT ROW) as cnt
	FROM t
),
-- высчитываем новые значения
new_data as (
	Select
		clientId,
		hitId,
        hitType,
		pagePath,
		hitTimestamp,
		CONCAT(clientId, '_', toString(hitTimestamp + cnt)) as new_hitId,
		hitTimestamp + cnt as new_timestamp
	FROM count_duplicates
),
-- заменяем дубли хитов в исходной таблице
fix_hitId as (
    SELECT
         date,
        clientId,
        sessionId,
        CASE
            WHEN new_hitId != '' THEN new_hitId
            ELSE t.hitId
        END as hitId,
        CASE
            WHEN new_timestamp != 0 THEN new_timestamp
            ELSE t.hitTimestamp
        END as hitTimestamp,
        hitType,
        pageUrl,
        pagePath,
        eventCategory,
        eventAction,
        eventLabel
    FROM {{ ref('stg_prepare_hits') }} as t
    LEFT JOIN new_data as n
    ON t.clientId = n.clientId
    AND t.hitId = n.hitId
    AND t.hitType = n.hitType
    AND t.pagePath = n.pagePath
),
-- запрашиваем данные для расчета оконок
t as (
	SELECT
		*,
		row_number() over(partition by sessionId order by hitTimestamp) as rn
	FROM fix_hitId
),
t2 as (
	SELECT
		*,
		CASE
        	WHEN rn = 1 and hitType = 'event' THEN 'fix'
            ELSE 'non_fix'
        END as fix_pageview
	FROM t	 
),
-- добавляем pageview в сессии с багом
fix as (
    Select *
    FROM t2
    UNION ALL
    Select
    date,
    clientId,
    sessionId,
    CONCAT(clientId, '_', toString(hitTimestamp)) as hitId, --генерируем hitId
    hitTimestamp - 100 as hitTimestamp, --отнимаем из timestamp первого евента 0.1сек, чтобы не совпадали значения
    'pageview' as hitType,
    pageUrl,
    pagePath,
    'pageview' as eventCategory,
    'pageview' as eventAction,
    'pageview' as eventLabel,
	0 as rn,
    fix_pageview
FROM t2
WHERE fix_pageview = 'fix'
)
SELECT
    date,
    clientId,
    sessionId,
    hitId,
    hitTimestamp,
    hitType,
    pageUrl,
    replaceAll(pagePath, '.php', '') as pagePath,
    eventCategory,
    eventAction,
    eventLabel,
    rn,
    fix_pageview,
    row_number() over(partition by sessionId Order By hitTimestamp) as hits_sequence
FROM fix