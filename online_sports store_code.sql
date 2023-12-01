/*Count the total number of products, along with 
the number of non-missing values in description, listing_price, and last_visited*/
select count(i.product_id) as Total_no_of_products,
count(i.description) as description
,count(f.listing_price) as listing_price, 
count(t.last_visited) as last_visited
from info i
JOIN finance f on i.product_id=f.product_id
join traffic t on f.product_id=t.product_id


/*Find out how listing_price varies between Adidas and Nike products.*/
select  b.brand,cast(f.listing_price as integer),
count(f.product_id) as no_of_products from finance f
join brands b on f.product_id=b.product_id
where b.brand in('Adidas','Nike')
and f.listing_price>0
GROUP by b.brand, f.listing_price
order by f.listing_price desc

/*Create labels for products grouped by price range and brand.*/
select b.brand,count(f.*),
sum(f.revenue) as total_revenue,
case 
when f.listing_price <42 then 'Budget'
when f.listing_price >=42 and f.listing_price <74 then 'Average'
when f.listing_price >=74 and f.listing_price <129 then 'Expensive'
else 'Elite'
end as price_category from brands b
inner join finance f using (product_id)
where brand is not null
group by b.brand,price_category
order by total_revenue desc

/*Calculate the average discount offered by brand.*/
select  b.brand, round(avg(f.discount)*100 ,4)as avg_discount from finance f
join brands b on f.product_id=b.product_id
group by  b.brand
HAVING b.brand IS NOT NULL;

/*Calculate the correlation between reviews and revenue.*/
select corr(f.revenue,r.reviews) review_revenue_corr
from finance f join
reviews r using(product_id)

/*Split description into bins in increments of one 
hundred characters, and calculate average rating by for each bin.*/
select trunc(length(i.description),-2) as description_length,
round(avg(r.rating::numeric),2) as average_rating
from info  i
join reviews as r on i.product_id=r.product_id
where i.description is not null
group by description_length
order by description_length

/*Count the number of reviews per brand per month.*/
select b.brand,DATE_PART('month', t.last_visited) AS month, 
count(r.reviews) as no_of_reviews
from brands b join reviews r using(product_id)
join traffic t using(product_id)
where b.brand is not null
AND DATE_PART('month', t.last_visited) IS NOT NULL
group by b.brand,month
ORDER BY b.brand, month;

/*Create the footwear CTE, then calculate the number of products 
and average revenue from these items.*/
with footwear as(SELECT i.description, f.revenue
    FROM info AS i
    INNER JOIN finance AS f 
        ON i.product_id = f.product_id
    WHERE i.description ILIKE '%shoe%'
        OR i.description ILIKE '%trainer%'
        OR i.description ILIKE '%foot%'
        AND i.description IS NOT NULL)

SELECT COUNT(*) AS num_footwear_products,
 percentile_disc(0.5) WITHIN GROUP (ORDER BY revenue) 
 AS median_footwear_revenue
FROM footwear;


/*Copy the code used to create footwear then use 
a filter to return only products that are not in the CTE.*/

WITH footwear AS
(
    SELECT i.description, f.revenue
    FROM info AS i
    INNER JOIN finance AS f 
        ON i.product_id = f.product_id
    WHERE i.description ILIKE '%shoe%'
        OR i.description ILIKE '%trainer%'
        OR i.description ILIKE '%foot%'
        AND i.description IS NOT NULL
)

SELECT COUNT(i.*) AS num_clothing_products, 
    percentile_disc(0.5) WITHIN GROUP (ORDER BY f.revenue) AS median_clothing_revenue
FROM info AS i
INNER JOIN finance AS f on i.product_id = f.product_id
WHERE i.description NOT IN (SELECT description FROM footwear);
