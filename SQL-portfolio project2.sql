OBJECTIVES:
• Tell the story of the company’s growth, using trended performance data
• Use the database to explain some of the details around your growth story, and quantify the revenue impact of some of your wins
• Analyze current performance, and use that data available to assess upcoming opportunities

-- 7 questions from the manager as below

/*
1.Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions 
and orders so that we can showcase the growth there?   
*/

SELECT 
    left(website_sessions.created_at, 7) AS yearmonth,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM
    website_sessions
        LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at < '2012-11-27'
        AND utm_source = 'gsearch'
GROUP BY 1
ORDER BY 1;
 
 
/*
2. Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and 
brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell. 
*/

SELECT 
    LEFT(website_sessions.created_at, 7) AS yearmonth,
    COUNT(DISTINCT CASE
            WHEN utm_campaign = 'nonbrand' THEN website_sessions.website_session_id
            ELSE NULL
        END) AS nonbrand_sessions,
    COUNT(DISTINCT CASE
            WHEN utm_campaign = 'nonbrand' THEN orders.order_id
            ELSE NULL
        END) AS nonbrand_orders,
    COUNT(DISTINCT CASE
            WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id
            ELSE NULL
        END) AS brand_sessions,
    COUNT(DISTINCT CASE
            WHEN utm_campaign = 'brand' THEN orders.order_id
            ELSE NULL
        END) AS brand_orders
FROM
    website_sessions
        LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at < '2012-11-27'
        AND utm_source = 'gsearch'
      GROUP BY 1
ORDER BY 1;

/*
3.While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device 3 type?
 I want to flex our analytical muscles a little and show the board we really know our traffic sources.
 */
 
SELECT 
    LEFT(website_sessions.created_at, 7) AS yearmonth,
       COUNT(DISTINCT CASE
            WHEN device_type = 'desktop' THEN website_sessions.website_session_id
            ELSE NULL
        END) AS desktop_sessions,
    COUNT(DISTINCT CASE
            WHEN device_type = 'desktop' THEN orders.order_id
            ELSE NULL
        END) AS desktop_orders,
    COUNT(DISTINCT CASE
            WHEN device_type = 'mobile' THEN website_sessions.website_session_id
            ELSE NULL
        END) AS mobile_sessions,
    COUNT(DISTINCT CASE
            WHEN device_type = 'mobile' THEN orders.order_id
            ELSE NULL
        END) AS mobile_orders
FROM
    website_sessions
        LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at < '2012-11-27'
        AND utm_source = 'gsearch'
         and utm_campaign='nonbrand'
GROUP BY 1
ORDER BY 1;

/*
4.I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from 4 Gsearch. 
Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?
*/

# first, find the various utm sources and refers to see the traffic we are getting

SELECT distinct utm_source,
utm_campaign,
http_referer
 FROM mavenfuzzyfactory.website_sessions
where created_at<'2012-11-27';

# then the output

SELECT 
    LEFT(website_sessions.created_at, 7) AS yearmonth,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT CASE
            WHEN utm_source = 'gsearch' THEN website_sessions.website_session_id
            ELSE NULL
        END) AS gsearch_paid_sessions,
    COUNT(DISTINCT CASE
            WHEN utm_source = 'bsearch' THEN website_sessions.website_session_id
            ELSE NULL
        END) AS bsearch_paid_sessions,
    COUNT(DISTINCT CASE
            WHEN
                utm_source is NULL
                    AND http_referer IS NOT NULL
            THEN
                website_sessions.website_session_id
            ELSE NULL
        END) AS organic_search_sessions,
    COUNT(DISTINCT CASE
            WHEN
                utm_source is NULL
                    AND http_referer IS NULL
            THEN
                website_sessions.website_session_id
            ELSE NULL
        END) AS direct_typein_sessions
FROM
    website_sessions
WHERE
    website_sessions.created_at < '2012-11-27'
GROUP BY 1
ORDER BY 1;

/*
5.I’d like to tell the story of our website performance improvements over the course of the first 8 months. 
 Could you pull session to order conversion rates, by month?
 */
 
 SELECT 
    LEFT(website_sessions.created_at, 7) AS yearmonth,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conversion_rate
FROM
    website_sessions
        LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at < '2012-11-27'
GROUP BY 1
ORDER BY 1;

/*
6.For the landing page test you analyzed previously, it would be great to show a full conversion funnel from each 
of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 – Jul 28).
*/

#identify each pageview as specific funnel step
create temporary table session_level_made_it_flags5
select
website_session_id,
max(homepage)as saw_homepage,
max(custom_lander)as saw_custom_lander,
max(products_page)as product_made_it,
max(mrfuzzy_page)as mrfuzzy_made_it,
max(cart_page)as cart_made_it,
max(shipping_page)as shipping_made_it,
max(billing_page)as billing_made_it,
max(thankyou_page)as thankyou_made_it
from(
select 
website_sessions.website_session_id,
website_pageviews.pageview_url,
website_pageviews.created_at as pageview_created_at,
case when pageview_url ='/home' then 1 else 0 end as homepage,
case when pageview_url ='/lander-1' then 1 else 0 end as custom_lander,
case when pageview_url ='/products' then 1 else 0 end as products_page,
case when pageview_url ='/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
case when pageview_url ='/cart' then 1 else 0 end as cart_page,
case when pageview_url ='/shipping' then 1 else 0 end as shipping_page,
case when pageview_url ='/billing' then 1 else 0 end as billing_page,
case when pageview_url ='/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
left join website_pageviews
on website_sessions.website_session_id=website_pageviews.website_session_id
where website_sessions.created_at between'2012-06-19'and '2012-07-28'
and utm_source = 'gsearch'
and website_sessions.utm_campaign ='nonbrand'
order by
website_sessions.website_session_id,
website_pageviews.created_at
)as pageview_level
group by 
website_session_id;

# final output:part 1--building funnel steps
 SELECT 
    CASE WHEN saw_homepage = 1 THEN 'saw_homepage'
    WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'check logic'
    END AS segment,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE
            WHEN product_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS to_products,
    COUNT(DISTINCT CASE
            WHEN mrfuzzy_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE
            WHEN cart_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS to_cart,
    COUNT(DISTINCT CASE
            WHEN shipping_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS to_shipping,
    COUNT(DISTINCT CASE
            WHEN billing_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS to_billing,
    COUNT(DISTINCT CASE
            WHEN thankyou_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS to_thankyou
FROM
    session_level_made_it_flags5
GROUP BY 1;
# final output:step 2--click through rate
select 
CASE WHEN saw_homepage = 1 THEN 'saw_homepage'
    WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'check logic'
    END AS segment,
count(distinct case when product_made_it=1 then website_session_id else null end)/
count(distinct website_session_id)as landingpage_click_rt,
count(distinct case when mrfuzzy_made_it=1 then website_session_id else null end)/
count(distinct case when product_made_it=1 then website_session_id else null end)as products_click_rt,
count(distinct case when cart_made_it=1 then website_session_id else null end)/
count(distinct case when mrfuzzy_made_it=1 then website_session_id else null end)as mrfuzzy_click_rt,
count(distinct case when shipping_made_it=1 then website_session_id else null end)/
count(distinct case when cart_made_it=1 then website_session_id else null end)as cart_click_rt,
count(distinct case when billing_made_it=1 then website_session_id else null end)/
count(distinct case when shipping_made_it=1 then website_session_id else null end)as shipping_click_rt,
count(distinct case when thankyou_made_it=1 then website_session_id else null end)/
count(distinct case when billing_made_it=1 then website_session_id else null end)as billing_click_rt
from session_level_made_it_flags5
group by 1;

/*
7.I’d love for you to quantify the impact of our billing test, as well. Please analyze the lift generated from the test 
(Sep 10 – Nov 10), in terms of revenue per billing page session, and then pull the number of billing page sessions 
for the past month to understand monthly impact.
*/

select
billing_version_seen,
count(distinct website_session_id)as sessions,
sum(price_usd)/count(distinct website_session_id)as revenue_per_billing_page_seen
from(
select 
website_pageviews.website_session_id,
website_pageviews.pageview_url as billing_version_seen,
orders.order_id,
orders.price_usd
from website_pageviews
left join orders
on orders.website_session_id=website_pageviews.website_session_id
where website_pageviews.created_at >'2012-09-10'
and website_pageviews.created_at < '2012-11-10'
and website_pageviews.pageview_url in ('/billing','/billing-2')
)as billing_pageviews_and_order
group by 
billing_version_seen;
-- $22.83 revenue per billing page seen for the old version
-- $31.34 revenue per billing page seen for the new version
-- lift:$8.51

# final output
select 
count(website_session_id)as billing_sessions_last_month
from website_pageviews
where website_pageviews.created_at >'2012-10-27'
and website_pageviews.created_at < '2012-11-27'
and website_pageviews.pageview_url in ('/billing','/billing-2')

--1193 billing sessions last month,lift$8.51 per session
--value of billing test $ 10152 for the last month

