WITH
-- находим нужные страницы по событиям и проставляем pageType
t as (
  Select 
    pagePath,
    CASE
      WHEN eventAction like '%cardPage_%' THEN 'ProductPage'
      WHEN eventAction like '%productCategory_%' THEN 'ListingPage'
      WHEN eventAction like '%navCategory_%' THEN 'NavPage'
      WHEN pagePath = '/search' THEN 'SearchResults'
      WHEN pagePath = '/' THEN 'MainPage'
      WHEN pagePath like '%/checkout%' THEN 'CheckoutPage'
      WHEN pagePath like '%/services%' THEN 'ServicePage'
      WHEN pagePath in ('/payments', '/order', '/delivery', '/insurance', '/guarantee', '/documents') THEN 'PaymentsAndDeliveryPage'
      WHEN pagePath in ('/contacts', '/about', '/financial', '/power_of_attorney', '/vacancies', '/contacts', '/partners', '/press', '/feedback', '/objects') THEN 'ContactsPage'
      WHEN match(pagePath, 'expo|news|articles') THEN 'PressPage'
      ELSE 'InfoPage'
    END as pageType
  FROM {{ ref('presets_hits') }}
  GROUP BY pagePath, pageType
)
Select
  pagePath,
  max(pageType) as pageType
FROM t
GROUP BY
	pagePath