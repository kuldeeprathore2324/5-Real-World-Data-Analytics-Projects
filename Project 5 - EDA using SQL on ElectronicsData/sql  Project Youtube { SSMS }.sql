create database campusx

drop table electronicsdata
truncate table electronicsdata

select * from electronicsdata

set sql_safe_updates =0

LOAD DATA INFILE "E:/ElectronicsData.csv"
INTO TABLE electronicsdata
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


-- VIEW OF THE DATA
SELECT * FROM electronicsdata
select count(distinct title) from electronicsdata


-- DESCRIBING OUR DATA ( NUMBER OF COLUMNS TYPE OF REACH COLUMN , IF THERE IS ANY  PRIMARY KEY , SECONDARY KEY ETC., THIS GIVE US OUR FIRST IMPRESSION ABOUT DATA)
Describe electronicsdata 


-- FEATURE ENGINEERING.
Select * from electronicsdata


-- SUB CATEGORY
SELECT * FROM ELECTRONICSDATA ORDER BY RAND() LIMIT 5 
SELECT  DISTINCT  `SUB CATEGORY` FROM ELECTRONICSDATA

-- CLEANING PRICE COLUMN 
    'cleaning $ part'
select replace(Price , '$', '') as price from electronicsdata   -- replace $
update electronicsdata     -- updating it
set  price =  replace(replace(Price , '$', ''), ',','')


       'cleaning through part'

select price ,replace(substring_index(replace(price, "-", ""),"through", 1),",","")+replace(substring_index(replace(price, "-", ""),"through", -1), ",","")as total
 from electronicsdata where price  like "%through%" group by price 
 

update electronicsdata   -- updating
set price = (replace(substring_index(replace(price, "-", ""),"through", 1),",","")+replace(substring_index(replace(price, "-", ""),"through", -1), ",",""))/2
 where price  like "%through%"
 
------------------------  

select * from electronicsdata


-- CLEANING DISCOUNT COLUMN.

      "Forming Discount_given Column."
      
SELECT *,       -- logic
  case when  discount  like "%No Discount%" then "NO"
  else "Yes"  end as "Discount given"
        FROM electronicsdata 
        
alter  table electronicsdata          -- added new column.
add  column discount_given varchar(3) after Discount;
        
update electronicsdata       -- add values to the column.
set  discount_given = case when discount like "%No Discount%" then "No" else  "Yes" end 

     "Forming MRP Column"
     

select * from electronicsdata
Alter table electronicsdata    -- created column
add  column MRP decimal (20,2) after Price 

select discount, price  ,          -- logic
    CASE WHEN DISCOUNT LIKE "%No Discount%" then price
         when discount like "%After%"   then  round(price+ regexp_replace(discount , '[^0-9]',''),2)
	else round(price*1.27,2) end as Disocunted_amount 
from electronicsdata

update electronicsdata
set MRP = case 
   WHEN DISCOUNT LIKE "%No Discount%" then price
  when discount like "%After%"   then  round(price+ regexp_replace(discount , '[^0-9]',''),2)
	else round(price*1.27,2)  end 



      "Discount column name change and cardinality reduction"
alter table electronicsdata change column Discount Discount_type text;   -- change column name

select discount_type, case   -- Logic
          when discount_type like "%No Discount%"  then "No Discount"  
          when Discount_type like "%Price valid%"  then "Price Valid Discount" 
          when discount_type like "%After%"  then "Flat Discount Offers"
           else "Special Discount" end  as Dis
          from electronicsdata

update electronicsdata
set discount_type = case       -- application.
          when discount_type like "%No Discount%"  then "No Discount"  
          when Discount_type like "%Price valid%"  then "Price Valid Discount" 
          when discount_type like "%After%"  then "Flat Discount Offers"
          "Special Discount" end
          
          
          
select * from electronicsdata



-- dropping the currency column
alter table electronicsdata
drop column Currency

                   -- Cleaning rating column


-- extracting rating only

alter table electronicsdata 
add  column Average_Rating  decimal(5,2) after rating   -- changing column name

select rating, REGEXP_SUBSTR(rating, '[0-9]') AS extracted_rating from electronicsdata  -- extract first number before decimal only.
SELECT rating,REGEXP_SUBSTR(rating, '[0-9]+(\\.[0-9]+)?') AS extracted_rating FROM electronicsdata;  -- extract after decimal only

update  electronicsdata                     -- updating data  in rating column
set average_rating = REGEXP_SUBSTR(rating, '[0-9]+(\\.[0-9]+)?') ; 

select * from electronicsdata -- changing column name



-- extrating numbers of rating
select * from electronicsdata
alter table electronicsdata add column Reviews_Count int  after rating -- addded new column to extract  number of reviews

select rating, regexp_substr(rating , '[0-9]+(?= reviews)')  from electronicsdata   -- logic
update electronicsdata                    -- updating
set reviews_count= regexp_substr(rating , '[0-9]+(?= reviews)') 



alter table electronicsdata
drop column rating

select * from electronicsdata

                                      -- GETTING COMPANY NAME
ALTER TABLE  ELECTRONICSDATA     -- added column for the same 
add COLUMN Brandname VARCHAR(30)

select title ,substring_index(title , ' ', 1) from electronicsdata  -- logic
update electronicsdata
set brandname= substring_index(title , ' ', 1)      -- after this step check distinct
select  distinct(brandname) from electronicsdata

select *  from electronicsdata where substring_index(title , ' ',1) like "%$%"    -- to look where does $ comes from 


update electronicsdata
set brandname=  'Nintendo' where substring_index(title , ' ',1) like "%$%"

UPDATE electronicsdata
SET Brandname = "Apple"
WHERE Brandname LIKE '%mac%' OR Brandname LIKE '%ipad%' or Brandname LIKE '%Airpods%' ;

select * from electronicsdata order by price

select  distinct(brandname) from electronicsdata
------------------------------------------         -- EDA                   ---------------------------------------

-- GLIMPSE OF DATA
SELECT * FROM ELECTRONICSDATA  LIMIT 5  -- ESSANCE  OF DATA
SELECT * FROM ELECTRONICSDATA ORDER BY RAND() LIMIT 5 


-- NUMERICAL COLUMNS ANALYSIS.(PRICE)
-- 1 CHECKING FOR NULL
SELECT COUNT(*) FROM ELECTRONICSDATA WHERE  PRICE IS NULL 

-- 2 FINDING , MIN , MAX ,AVG, STD
SELECT MIN(price) as minimum ,
MAX(PRICE) AS MAXIMUM, 
AVG(PRICE) AS AVERAGE,
STD(PRICE) AS STD
from electronicsdata             -- error

select * from electronicsdata

DELETE FROM ELECTRONICSDATA
WHERE `Sub Category`  = 'Home Security Systems & Cameras'   -- removing the row

ALTER TABLE ELECTRONICSDATA
MODIFY COLUMN PRICE DECIMAL(20,2);                -- change datatype

SELECT 
    MIN(price) AS minimum,
    MAX(price) AS maximum, 
    AVG(price) AS average,
	STD(price) AS std
    from electronicsdata;



-- 3 PERCENTILE COUNT

drop procedure   GetPriceByPercentile

SELECT DISTINCT price, ROUND(PERCENT_RANK() OVER (ORDER BY price), 2) AS percentile FROM ELECTRONICSDATA

DELIMITER //
CREATE PROCEDURE GetPriceByPercentile(IN percentileValue DECIMAL(3, 2), OUT price_limit DECIMAL(10, 2))
BEGIN
    SELECT MAX(Price)
    INTO price_limit
    FROM (
        SELECT DISTINCT price, ROUND(PERCENT_RANK() OVER (ORDER BY price), 2) AS percentile FROM ELECTRONICSDATA
    ) AS k
    WHERE percentile = percentileValue;
END //
DELIMITER ;


CALL GetPriceByPercentile(0.26, @q12);
SET @q1 = ROUND((@q11+@q12)/2, 2);
select @q2
select @q1 as Q1,@q2 as Median , @q3 as Q3         -- MEAN > MEDIAN {POSTIVE SKEWED}

SELECT @Q2

-- 4 OUTLIERS
SELECT * FROM  ELECTRONICSDATA WHERE PRICE <(@q1-1.5*(@q3-@q1)) OR PRICE >(@q3+1.5*(@q3-@q1))  -- OUTLIERS  ON positive side 


-- 5 CREATE DATA AS PER BUCKETS/PLOT HISTOGRAM
SELECT BUCKETS, REPEAT("*" , COUNT(*)/5) FROM 
(
SELECT PRICE , 
CASE 
  WHEN PRICE BETWEEN 0 AND 500  THEN '0-0.5K'
  WHEN PRICE BETWEEN 501 AND 1500 THEN '0.5K- 1.5K'
  WHEN PRICE BETWEEN 1501 AND 3000  THEN '1.5K- 3K'
  WHEN PRICE BETWEEN 3001 AND  6000 THEN '3K- 6K'
  ELSE '>6K'
  END AS 'BUCKETS'
  FROM ELECTRONICSDATA
)K 
GROUP BY BUCKETS



                    -------------------------       -- CATEGORICAL COLUMNS           -----------------------
-- 1 CHECKING FOR NULL VALUES
SELECT COUNT(*) FROM ELECTRONICSDATA WHERE `SUB CATEGORY` IS NULL

-- 2 COUNT OF COMPANY/PIE CHART
SELECT `sub category`, COUNT(`sub category`) AS sub_category_count FROM electronicsdata GROUP BY `sub category`;


 -------------------------       -- BIVARIATE ANALYSIS  (NUMERICAL - NUMERICAL ANALYSIS)          -----------------------
                      
-- 1 SCATTER PLOt
SELECT aVERAGE_RATING , REVIEWS_COUNT FROM ELECTRONICSDATA    -- increase in count of reviews leads to increase in average reatings.

-- 2  COVRIANCE 
	SELECT 
		round((SUM((AvERAGE_RATING - (SELECT AVG(AVERAGE_RATING) FROM ELECTRONICSDAta)) * (reviews_count - (SELECT AVG(reviews_count) FROM electronicsdata ))) / (COUNT(*) - 1)),2) AS covariance
	FROM electronicsdata;     -- POSITIVE RELATION
    
-- 3 CORRELATION
SELECT
    ROUND((round((SUM((AvERAGE_RATING - (SELECT AVG(AVERAGE_RATING) FROM ELECTRONICSDAta)) * (reviews_count - (SELECT AVG(reviews_count) FROM electronicsdata )))
    / (COUNT(*) - 1)),2))/(STD(AVERAGE_RATING)* STD(REVIEWS_COUNT)),2) AS CORRELATION
FROM ELECTRONICSDATA   -- very weak positive linear relationship

-- 
4 SLOPE OF LINEAR REGRESSION
SELECT 
    SUM((PRICE - (SELECT AVG(PRICE) FROM ELECTRONICSDATA)) * (MRP - (SELECT AVG(MRP) FROM ELECTRONICSDATA))) / 
    SUM(POWER(PRICE - (SELECT AVG(PRICE) FROM ELECTRONICSDATA), 2)) AS slope
FROM ELECTRONICSDATA;   -- For example, if the Price of a product increases by $10, the MRP would increase by $3,770 (10 * 377),  FOR PRICE AND SALES WE CAN SEE THIS 

SELECT * FROM ELECTRONICSDATA



 -------------------------       -- BIVARIATE ANALYSIS  (CATEGORICAL - CATEGORICAL ANALYSIS)          -------------------------
 
 -- 1 COTINGENCY TABLE (COUNT OF CATEGORY EACH COMPANY IS DEALING IN)
 SELECT BRANDNAME , 
     COUNT(DISTINCT(`SUB CATEGORY`)) AS Sectors
     FROM ELECTRONICSDATA 
GROUP BY BRANDNAME
 
 
  -------------------------       -- BIVARIATE ANALYSIS  (NUMERICAL CATEGORICAL - NUMERICAL 	 ANALYSIS)          -----------------------------
 
 
 -- 2 GROUPED SUMMARY STATISTICS Grouped Summary Statistics (Mean, Variance, Standard Deviation)
SELECT bRANDNAME, 
       ROUND(AVG(pRICE),2) AS mean,
       ROUND(mIN(pRICE),2) AS mINIMUM,
       ROUND(MAX(PRICE),2) AS MAXIMUM,
       ROUND(STDDEV(pRICE),2) AS stddev
FROM ELECTRONICSDATA
GROUP BY BRANDNAME;             -- MORE CONSISTENCY IN PRICES IN CATEORIES LIKE MASINGO , ALLSTATE, BEATS, SANDISK, INSTA360 ETC

-- HERE WE DO THINGS LIKE MEAN ALAYSIS , VARINACE ANALYSIS ETC ACROSS CATEGORIES

 SELECT * FROM electronicsdata
 
 
 -- MUTIVARIATE ANALYSIS
 
 -- 1  COVRIANCE 
	SELECT   `SUB CATEGORY` , 
		round((SUM((AvERAGE_RATING - (SELECT AVG(AVERAGE_RATING) FROM ELECTRONICSDAta)) * (reviews_count - (SELECT AVG(reviews_count) FROM electronicsdata ))) / (COUNT(*) - 1)),2) AS covariance
	FROM electronicsdata
    GROUP BY `SUB CATEGORY`
 
