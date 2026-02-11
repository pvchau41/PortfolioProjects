-- Data Cleaning --

SELECT *
FROM layoffs;

-- Removing Duplicates --

/* creates a new table and replaces the information from the original table */
CREATE TABLE layoffs_staging 
LIKE layoffs;

SELECT *
FROM  layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

/* adds a new column to show the entry number (if this is greater than 1, we know there are duplicates)*/
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

/* creates a cte with this row number in order to add a filter*/
WITH cte_duplicates AS 
(
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num 
FROM layoffs_staging
)
SELECT *
FROM cte_duplicates
WHERE row_num > 1;

SELECT *
FROM layoffs_staging
WHERE company = '#Paid';


/* since I cannot use the delete statement for the current table, I am creating a new table in order to delete the duplicates using row_num */
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

/* removing duplicates*/
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SET SQL_SAFE_UPDATES = 0;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

-- Standardizing Data --

SELECT company, TRIM(company)
FROM layoffs_staging2;

/* removing any spaces before company name*/
UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT company
FROM layoffs_staging2;


SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

/* since there were different variations of the industry "Crypto", I made sure they had the same format and spelling*/
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
FROM layoffs_staging2;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

/* fixed the format for all entries with "United States" similar to what I did with "Crypto"*/
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

/* changing date column to date type column and a better format*/
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Null Values --
/*viewing table where null values exist*/
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

/* viewing to see if there are missing values within industries*/
SELECT *
FROM layoffs_staging2 
WHERE industry IS NULL
OR industry = '';

/*planning to update the missing values with other values in "Airbnb" for example*/
SELECT * 
FROM layoffs_staging2
WHERE company = 'Airbnb';


UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

/* performing a self join to make it easier to update the missing values with other values about the same company from another entry*/
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    WHERE (t1.industry IS NULL OR t1.industry ='')
    AND t2.industry IS NOT NULL;
 
 /* updating industry name from similar entries from the same company*/
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

/* since we cannot update these values like names, we delete them since they are useless to us*/
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

/* remove row_num since we do not need it anymore*/
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

/* fully clean dataset to my liking*/
SELECT *
FROM layoffs_staging2;