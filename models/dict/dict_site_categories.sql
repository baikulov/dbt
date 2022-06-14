WITH
-- находим нужные страницы по событиям и проставляем pageType
t as (
  SELECT 
    replaceAll(url, '.php', '') as pagePath,
    ifNull(name, 'Неизвестно') as category_name,
    ifNull(type, 'Неизвестно') as category_type
  FROM {{ source('src_dbt', 'src_dict_site_categories') }}
)
Select
  pagePath,
  category_name,
  category_type
FROM t
GROUP BY
  pagePath,
  category_name,
  category_type