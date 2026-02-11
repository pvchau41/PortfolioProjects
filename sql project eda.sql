-- Exploratory Data Analysis --

SELECT * 
FROM layoffs_staging2;

/* view the max people laid off, along with the max percentage of a commpany that has been laid off*/
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

/* view the companies that let go 100% of their company*/
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

/* view companies and the total amount they laid off*/
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

/* shows which industries lay off the most and least */
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

/* view the countries and the total amount laid off from each*/
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

/* since the United States was the number one country, we inspected the total laid off by year */
SELECT YEAR(date), country, SUM(total_laid_off)
FROM layoffs_staging2
WHERE country = 'United States'
GROUP BY YEAR(date)
ORDER BY 1 DESC;

/* to see the total laid off per month of each year */
SELECT SUBSTRING( `date`, 1, 7) AS MONTHYEAR, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING( `date`, 1, 7) IS NOT NULL 
GROUP BY MONTHYEAR
ORDER BY 1 ASC;

/* to see how each total laid off per month of each year adds to the rolling total */
WITH Rolling_Total AS
( 
SELECT SUBSTRING( `date`, 1, 7) AS MONTHYEAR, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING( `date`, 1, 7) IS NOT NULL
GROUP BY MONTHYEAR
ORDER BY 1 ASC
)
SELECT `MONTHYEAR`, total_off, SUM(total_off) OVER(ORDER BY `MONTHYEAR`) AS rolling_total
FROM Rolling_Total;

/* sees the company and what year had the most laid off */
SELECT company, YEAR(`date`) AS YEAR, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, year
ORDER BY 3 desc;

/* created a ranking of the top 5 companies that laid the most people off in each year */
WITH company_year (company, years, total_laid_off) AS 
( 
SELECT company, YEAR(`date`) AS YEAR, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), company_years_rank AS
(SELECT *, 
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS RANKING
FROM company_year
WHERE years IS NOT NULL
)
SELECT *
FROM company_years_rank
WHERE RANKING <=5;

/* the average layoff percentage per industry in order to see which industries are in need of help */
SELECT industry, ROUND(AVG(percentage_laid_off), 2) AS avg_layoff_percentage
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
GROUP BY industry
ORDER BY avg_layoff_percentage DESC;

/* creates 4 subgroups of layoff percentage and how many events occurred in each */
SELECT 
  CASE
    WHEN percentage_laid_off = 1 THEN '100%'
    WHEN percentage_laid_off >= 0.5 THEN '50–99%'
    WHEN percentage_laid_off >= 0.25 THEN '25–49%'
    ELSE '<25%'
  END AS layoff_severity,
  COUNT(*) AS events
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
GROUP BY layoff_severity
ORDER BY events DESC;

/* how many severe events each country has experienced */
SELECT country,
       COUNT(*) AS severe_events
FROM layoffs_staging2
WHERE percentage_laid_off >= 0.5
GROUP BY country
ORDER BY severe_events DESC;

/* shows the average percentage laid off per month in each year */
SELECT SUBSTRING( `date`, 1, 7) AS MONTHYEAR, ROUND(AVG(percentage_laid_off), 2) AS avg_percentage_off
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
GROUP BY SUBSTRING( `date`, 1, 7)
ORDER BY SUBSTRING( `date`, 1, 7);