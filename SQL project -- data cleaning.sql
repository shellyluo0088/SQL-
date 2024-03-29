## We are going to use the Nashvile housing dataset for this SQL data cleaning project:
#-----------------------------------------------------------------------------
#Step1: Import dataset into MySQL:

CREATE DATABASE IF NOT EXISTS data_cleaning;
USE data_cleaning;

DROP TABLE IF EXISTS housing_data;
CREATE TABLE housing_data
(UniqueID VARCHAR(250),
ParcelID VARCHAR(250),
LandUse VARCHAR(250),
PropertyAddress VARCHAR(250),
SaleDate VARCHAR(250),
SalePrice VARCHAR(250),
LegalReference VARCHAR(250),
SoldAsVacant VARCHAR(250),
OwnerName VARCHAR(250),
OwnerAddress VARCHAR(250),
Acreage VARCHAR(250),
TaxDistrict VARCHAR(250),
LandValue VARCHAR(250),
BuildingValue VARCHAR(250),
TotalValue VARCHAR(250),
YearBuilt VARCHAR(250),
Bedrooms VARCHAR(250),
FullBath VARCHAR(250),
HalfBath VARCHAR(250)
);


#---------------------------------------------------------------------------
#Step2: Standardlize date Format
SELECT *
FROM housing_data;

ALTER TABLE housing_data
Add SaleDateConverted Date;

UPDATE housing_data
SET SaleDateConverted = DATE(STR_TO_DATE(SaleDate, '%Y-%m-%d'));

#---------------------------------------------------------------------------
#Step3: Populate Property address data
# There are some empty strings for "PropertyAddress" column, 
#but we can populate them by using the ParcelID as a reference point:
#By examing data, we can see that the properties have the same ParcelID should have the same property address:

SELECT *
FROM housing_data
WHERE housing_data.PropertyAddress = NULL OR housing_data.PropertyAddress = "";

UPDATE housing_data
SET PropertyAddress = CASE PropertyAddress WHEN "" THEN NULL 
ELSE PropertyAddress END;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM housing_data a
JOIN housing_data b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE housing_data a
JOIN housing_data b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress IS NULL;

#-------------------------------------------
#Step4: Breaking Out address into individual columns (address, city, state)
SELECT PropertyAddress
From housing_data;

#update propertyaddress column:
SELECT 
SUBSTRING(PropertyAddress, 1, position("," IN PropertyAddress) - 1) AS Address, 
SUBSTRING(PropertyAddress, position(','IN PropertyAddress) + 1 , length(PropertyAddress)) as City
FROM housing_data;

ALTER TABLE housing_data
Add PropertySplitAddress varchar(250);

Update housing_data
SET PropertySplitAddress = substring(PropertyAddress, 1, position("," IN PropertyAddress) - 1);

ALTER TABLE housing_data
Add PropertySplitCity varchar(250);

Update housing_data
SET PropertySplitCity = SUBSTRING(PropertyAddress, position(','IN PropertyAddress) + 1 , length(PropertyAddress));

Select *
From housing_data;

#update OwnerAddress column:
Select OwnerAddress
From housing_data;

#Remember that we can use PARSENAME function in Microsoft SQL Server:
#Select
#PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
#,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
#,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
#From housing_data;


SELECT OwnerAddress, SUBSTRING_INDEX(OwnerAddress,',',1) AS Address, 
SUBSTRING(PropertyAddress, position(','IN PropertyAddress) + 1 , length(PropertyAddress)) AS City,
SUBSTRING_INDEX(OwnerAddress,',', -1) AS State
FROM housing_data;

#update OwnerAddress column:
ALTER TABLE housing_data
Add OwnerSplitAddress varchar(250);

Update housing_data
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress,',',1);


ALTER TABLE housing_data
Add OwnerSplitCity varchar(250);

Update housing_data
SET OwnerSplitCity = SUBSTRING(PropertyAddress, position(','IN PropertyAddress) + 1 , length(PropertyAddress));

ALTER TABLE housing_data
Add OwnerSplitState varchar(250);

Update housing_data
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress,',', -1);

SELECT *
FROM housing_data;

#Step5: Change Y and N to "yes" and "no" in "Sold as Vacant" field (using CASE statement)
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From housing_data
Group by SoldAsVacant
order by 2;



Select SoldAsVacant, 
CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From housing_data;


Update housing_data
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;



#---------------------------------------------------------------------------
#Step 6: Remove duplicates (CTE and window function)
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From housing_data
)
DELETE
From housing_data 
USING housing_data 
JOIN RowNumCTE 
	ON housing_data.UniqueID = RowNumCTE.UniqueID
Where row_num > 1;


#---------------------------------------------------------------------------
#Step7: Delete unused columns

Select *
From housing_data;


ALTER TABLE housing_data
DROP `OwnerAddress`, 
DROP `TaxDistrict`, 
DROP `PropertyAddress`,
DROP `SaleDate`;

#---------------------------------------------------------------------------