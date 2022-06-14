with
-- выбираем последнюю дату загрузки для каждого идентификатора сессии
max_datetime as (
  Select
    ga_dimension6,
    max(insert_date) as insert_date
  FROM {{ source('src_dbt', 'src_ga_export_events') }}
  WHERE match(ga_dimension1, '^\\d.*') -- исключаем сессии с неправильным id
  --AND ga_date >= toDate(NOW()) - 10 # отключена, пока данных не много
  GROUP BY ga_dimension6
),
-- выбираем все записи из источника
data as (
  Select *
  FROM {{ source('src_dbt', 'src_ga_export_events') }}
  WHERE match(ga_dimension1, '^\\d.*') -- исключаем сессии с неправильным id
  --AND ga_date >= toDate(NOW()) - 10 # отключена, пока данных не много
),
-- переименовываем столбцы и объединяем строки с последней актуальной записью
jn as (
  select
    ga_date as date,
    ga_pagePath as pagePath,
    ga_eventCategory as eventCategory,
    ga_eventAction as eventAction,
    ga_eventLabel as eventLabel,
    ga_dimension1 as sessionId,
    ga_dimension6 as hitId,
    ga_totalEvents as totalEvents,
    insert_date
  FROM data
  INNER JOIN max_datetime using(insert_date, ga_dimension6)
  Where ga_totalEvents = 1
),
-- временное решение пока не будут пофикшены дубли в отправке с клиента
# временное решение пока не будут пофикшены дубли в отправке с клиента
duplicates as (
  select hitId, count(hitId) as cnt
  FROM jn
  GROUP BY hitId
  HAVING cnt > 1
),
final as (
    Select *
    FROM jn
    WHERE hitId not in (Select hitId FRom duplicates)
)
select
  date,
  pagePath,
  eventCategory,
  eventAction,
  eventLabel,
  sessionId,
  hitId
FROM final
GROUP BY
  date,
  pagePath,
  eventCategory,
  eventAction,
  eventLabel,
  sessionId,
  hitId