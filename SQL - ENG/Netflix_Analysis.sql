--I've created a database called Netflix Analysis, imported the table from an Excel file available in the folder, 
--and named it dbo.Netflix_Main
--If you would like to execute the code, please do the same.

--Because my computer was using a polish locale system setting, I weren't able to import the data from CSV file
--without encountering any errors or having missing data. 
--In that situation, I decided to split the values in the CSV file and change it to an Excel file.
--This allowed the data to be properly loaded into SQL, however, left some more cleaning to do. 

USE [Netflix Analysis]
SELECT *
FROM dbo.Netflix_Main

--PLEASE NOTE--
--The below data cleaning code may not work as expected in this SQL file as the table has already been modified
--by it. To check the functionality of the entire code, I recommend creating a new SQL file, importing the Excel file and then 
--running the code. Everything below Calculations section is working correctly. 

---------DATA CLEANING---------

--Checking the Datatype for all columns
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Netflix_Main'

--Deleting the unnecessary columns
ALTER TABLE dbo.Netflix_Main
DROP COLUMN show_id, title, cast, release_year, rating, duration, description

--Removing the whitespaces 
UPDATE dbo.Netflix_Main
SET type = TRIM(type)

UPDATE dbo.Netflix_Main
SET director = TRIM(director)

UPDATE dbo.Netflix_Main
SET country = TRIM(country)

UPDATE dbo.Netflix_Main
SET date_added = TRIM(date_added)

UPDATE dbo.Netflix_Main
SET listed_in = TRIM(listed_in)

--Removing leading and trailing delimiters 
Update dbo.Netflix_Main SET 
type = CASE WHEN type LIKE ', %' THEN RIGHT(type, LEN(type)-2) ELSE type END,
director = CASE WHEN director LIKE ', %' THEN RIGHT(director, LEN(director)-2) ELSE director END,
country = CASE WHEN country LIKE ', %' THEN RIGHT(country, LEN(country)-2) ELSE country END,
date_added = CASE WHEN date_added LIKE ', %' THEN RIGHT(date_added, LEN(date_added)-2) ELSE date_added END,
listed_in = CASE WHEN listed_in LIKE ', %' THEN RIGHT(listed_in, LEN(listed_in)-2) ELSE listed_in END

Update dbo.Netflix_Main SET 
type = CASE WHEN type LIKE ',%' THEN RIGHT(type, LEN(type)-1) ELSE type END,
director = CASE WHEN director LIKE ',%' THEN RIGHT(director, LEN(director)-1) ELSE director END,
country = CASE WHEN country LIKE ',%' THEN RIGHT(country, LEN(country)-1) ELSE country END,
date_added = CASE WHEN date_added LIKE ',%' THEN RIGHT(date_added, LEN(date_added)-1) ELSE date_added END,
listed_in = CASE WHEN listed_in LIKE ',%' THEN RIGHT(listed_in, LEN(listed_in)-1) ELSE listed_in END

Update dbo.Netflix_Main SET 
type = CASE WHEN type LIKE '% ,' THEN LEFT(type, LEN(type)-2) ELSE type END,
director = CASE WHEN director LIKE '% ,' THEN LEFT(director, LEN(director)-2) ELSE director END,
country = CASE WHEN country LIKE '% ,' THEN LEFT(country, LEN(country)-2) ELSE country END,
date_added = CASE WHEN date_added LIKE '% ,' THEN LEFT(date_added, LEN(date_added)-2) ELSE date_added END,
listed_in = CASE WHEN listed_in LIKE '% ,' THEN LEFT(listed_in, LEN(listed_in)-2) ELSE listed_in END

Update dbo.Netflix_Main SET 
type = CASE WHEN type LIKE '%,' THEN LEFT(type, LEN(type)-1) ELSE type END,
director = CASE WHEN director LIKE '%,' THEN LEFT(director, LEN(director)-1) ELSE director END,
country = CASE WHEN country LIKE '%,' THEN LEFT(country, LEN(country)-1) ELSE country END,
date_added = CASE WHEN date_added LIKE '%,' THEN LEFT(date_added, LEN(date_added)-1) ELSE date_added END,
listed_in = CASE WHEN listed_in LIKE '%,' THEN LEFT(listed_in, LEN(listed_in)-1) ELSE listed_in END

--Changing the data type
ALTER TABLE dbo.Netflix_Main
ALTER COLUMN date_added DATE

--Deleting the Null values from the key column - date_added
DELETE FROM dbo.Netflix_Main
WHERE date_added IS NULL

--Adding new columns based on date_added column
ALTER TABLE dbo.Netflix_Main
ADD day AS DATEPART(dd, date_added)

ALTER TABLE dbo.Netflix_Main
ADD month AS DATEPART(mm, date_added)

ALTER TABLE dbo.Netflix_Main
ADD year AS DATEPART(yyyy, date_added)

--Creating additional tables, as well as trimming the values, renaming the columns, and deleting the null values.

--COUNTRY--
SELECT *
INTO Netflix_Country
FROM dbo.Netflix_Main
CROSS APPLY STRING_SPLIT(country, ',')

ALTER TABLE dbo.Netflix_Country
DROP COLUMN country

EXEC sp_rename 'dbo.Netflix_Country.value', 'country', 'COLUMN'

UPDATE dbo.Netflix_Country
SET country = TRIM(country)

DELETE FROM dbo.Netflix_Country
WHERE country IS NULL

--CATEGORY--
SELECT *
INTO Netflix_Category
FROM dbo.Netflix_Main
CROSS APPLY STRING_SPLIT(listed_in, ',')

ALTER TABLE dbo.Netflix_Category
DROP COLUMN listed_in

EXEC sp_rename 'dbo.Netflix_Category.value', 'listed_in', 'COLUMN'

UPDATE dbo.Netflix_Category
SET listed_in = TRIM(listed_in)

DELETE FROM dbo.Netflix_Category
WHERE listed_in IS NULL

--DIRECTOR--
SELECT *
INTO Netflix_Director
FROM dbo.Netflix_Main
CROSS APPLY STRING_SPLIT(director, ',')

ALTER TABLE dbo.Netflix_Director
DROP COLUMN director

EXEC sp_rename 'dbo.Netflix_Director.value', 'director', 'COLUMN'

UPDATE dbo.Netflix_Director
SET director = TRIM(director)

DELETE FROM dbo.Netflix_Director
WHERE director IS NULL

--All the tables after cleaning

SELECT *
FROM dbo.Netflix_Main

SELECT *
FROM dbo.Netflix_Country

SELECT *
FROM dbo.Netflix_Category

SELECT *
FROM dbo.Netflix_Director

---------CALCULATIONS---------

----------MOVIES----------

--Number of Movies added year by year
SELECT year, COUNT(*) AS 'Number of Movies' 
FROM dbo.Netflix_Main
WHERE type = 'Movie'
GROUP BY year
ORDER BY year


--The most frequent movie production country year by year
SELECT year, country, [No. of Movies/Country]
FROM
(
	SELECT year, country, COUNT(*) AS 'No. of Movies/Country',
	MAX(COUNT(*)) OVER (PARTITION BY year) AS 'Max No. of Movies/Year'
	FROM dbo.Netflix_Country
	WHERE type = 'Movie'
	GROUP BY year, country
) AS Count_and_Max
WHERE [No. of Movies/Country] = [Max No. of Movies/Year]
ORDER BY year


--The most frequent movie production country in general
SELECT TOP (1) country, COUNT(*) AS 'No.'
FROM dbo.Netflix_Country
WHERE type = 'Movie'
GROUP BY country
ORDER BY [No.] DESC


--The most frequent category of movies year by year
SELECT year, listed_in, [No. of Movies/Category]
FROM
(
	SELECT year, listed_in, COUNT(*) AS 'No. of Movies/Category',
	MAX(COUNT(*)) OVER (PARTITION BY year) AS 'Max No. of Movies/Year'
	FROM dbo.Netflix_Category
	WHERE type = 'Movie'
	GROUP BY year, listed_in
) AS Count_and_Max
WHERE [No. of Movies/Category] = [Max No. of Movies/Year]
ORDER BY year


--The most frequent category of movies in general
SELECT TOP (1) listed_in, COUNT(*) AS 'No.'
FROM dbo.Netflix_Category
WHERE type = 'Movie'
GROUP BY listed_in
ORDER BY [No.] DESC


--The most frequent director of movies year by year
SELECT year, director, [No. of Movies/Director]
FROM
(
	SELECT year, director, COUNT(*) AS 'No. of Movies/Director',
	MAX(COUNT(*)) OVER (PARTITION BY year) AS 'Max No. of Movies/Year'
	FROM dbo.Netflix_Director
	WHERE type = 'Movie'
	GROUP BY year, director
) AS Count_and_Max
WHERE [No. of Movies/Director] = [Max No. of Movies/Year]
ORDER BY year


--The most frequent director of movies in general
SELECT TOP (1) director, COUNT(*) AS 'No.'
FROM dbo.Netflix_Director
WHERE type = 'Movie'
GROUP BY director
ORDER BY [No.] DESC

----------TV SHOWS----------

--Number of TV Shows added year by year
SELECT year, COUNT(*) AS 'Number of TV Shows' 
FROM dbo.Netflix_Main
WHERE type = 'TV Show'
GROUP BY year
ORDER BY year


--The most frequent tv show production country year by year
SELECT year, country, [No. of TV Shows/Country]
FROM
(
	SELECT year, country, COUNT(*) AS 'No. of TV Shows/Country',
	MAX(COUNT(*)) OVER (PARTITION BY year) AS 'Max No. of TV Shows/Year'
	FROM dbo.Netflix_Country
	WHERE type = 'TV Show'
	GROUP BY year, country
) AS Count_and_Max
WHERE [No. of TV Shows/Country] = [Max No. of TV Shows/Year]
ORDER BY year


--The most frequent tv show production country in general
SELECT TOP (1) country, COUNT(*) AS 'No.'
FROM dbo.Netflix_Country
WHERE type = 'TV Show'
GROUP BY country
ORDER BY [No.] DESC


--The most frequent category of tv shows year by year
SELECT year, listed_in, [No. of TV Shows/Category]
FROM
(
	SELECT year, listed_in, COUNT(*) AS 'No. of TV Shows/Category',
	MAX(COUNT(*)) OVER (PARTITION BY year) AS 'Max No. of TV Shows/Year'
	FROM dbo.Netflix_Category
	WHERE type = 'TV Show'
	GROUP BY year, listed_in
) AS Count_and_Max
WHERE [No. of TV Shows/Category] = [Max No. of TV Shows/Year]
ORDER BY year

--The most frequent category of tv shows in general
SELECT TOP (1) listed_in, COUNT(*) AS 'No.'
FROM dbo.Netflix_Category
WHERE type = 'TV Show'
GROUP BY listed_in
ORDER BY [No.] DESC


--The most frequent director of tv shows year by year
SELECT year, director, [No. of TV Shows/Director]
FROM
(
	SELECT year, director, COUNT(*) AS 'No. of TV Shows/Director',
	MAX(COUNT(*)) OVER (PARTITION BY year) AS 'Max No. of TV Shows/Year'
	FROM dbo.Netflix_Director
	WHERE type = 'TV Show'
	GROUP BY year, director
) AS Count_and_Max
WHERE [No. of TV Shows/Director] = [Max No. of TV Shows/Year]
ORDER BY year


--The most frequent director of tv shows in general
SELECT TOP (2) director, COUNT(*) AS 'No.'
FROM dbo.Netflix_Director
WHERE type = 'TV Show'
GROUP BY director
ORDER BY [No.] DESC