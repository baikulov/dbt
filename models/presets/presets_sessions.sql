with
data as ( 
  Select
    d.date as date,
    d.sessionId as sessionId,
    source,
    medium,
    campaign,
    adContent,
    keyword,
    fullReferrer,
    country,
    region,
    city,
    latitude,
    longitude,
    language,
    screenResolution,
    browser,
    browserVersion,
    operatingSystem,
    operatingSystemVersion,
    deviceCategory
  FROM {{ ref('stg_sessions_devices') }} as d
  INNER JOIN {{ ref('stg_sessions_sources') }} as s
  ON s.sessionId = d.sessionId
  AND s.date = d.date
  INNER JOIN {{ ref('stg_sessions_geo') }} as g
  ON g.sessionId = d.sessionId
  AND g.date = d.date
  GROUP BY
    d.date,
    d.sessionId,
    source,
    medium,
    campaign,
    adContent,
    keyword,
    fullReferrer,
    country,
    region,
    city,
    latitude,
    longitude,
    language,
    screenResolution,
    browser,
    browserVersion,
    operatingSystem,
    operatingSystemVersion,
    deviceCategory
)
select
  *
FROM data