with
-- выбираем последнюю дату загрузки для каждого идентификатора сессии
max_datetime as (
  Select
    ga_dimension1,
    max(insert_date) as insert_date
  FROM {{ source('src_dbt', 'src_ga_export_devices') }}
  WHERE match(ga_dimension1, '^\\d.*') -- исключаем сессии с неправильным id
  --AND ga_date >= toDate(NOW()) - 10 # отключена, пока данных не много
  GROUP BY ga_dimension1
),
-- выбираем все записи из источника
data as (
  Select *
  FROM {{ source('src_dbt', 'src_ga_export_devices') }}
  WHERE match(ga_dimension1, '^\\d.*') -- исключаем сессии с неправильным id
  --AND ga_date >= toDate(NOW()) - 10 # отключена, пока данных не много
),
-- переименовываем столбцы и объединяем строки с последней актуальной записью
jn as (
  select
    ga_date as date,
    ga_browser as browser,
    ga_browserVersion as browserVersion,
    ga_operatingSystem as operatingSystem,
    ga_operatingSystemVersion as operatingSystemVersion,
    ga_deviceCategory as deviceCategory,
    ga_dimension1 as sessionId,
    ga_sessions as sessions,
    insert_date
  FROM data
  INNER JOIN max_datetime using(insert_date, ga_dimension1)
  Where ga_sessions = 1
),

-- временное решение пока не будут пофикшены дубли в отправке с клиента
duplicates as (
  select sessionId, count(sessionId) as cnt
  FROM jn
  GROUP BY sessionId
  HAVING cnt > 1
),

final as (
  Select *
  FROM jn
  WHERE sessionId not in (Select sessionId FRom duplicates)
)
select
  date,
  browser,
  browserVersion,
  operatingSystem,
  operatingSystemVersion,
  deviceCategory,
  sessionId
FROM final
GROUP BY
  date,
  browser,
  browserVersion,
  operatingSystem,
  operatingSystemVersion,
  deviceCategory,
  sessionId