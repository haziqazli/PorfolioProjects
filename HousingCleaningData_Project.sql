--Project Nashville Housing 
--(Cleaning Data in SQL Queries)


--import and check data
select *
from dbo.nashvilleHousing$

-- 1) Standardize Date Format

select SaleDate 
from PortfolioProject.dbo.nashvilleHousing$
-- As we can see the date in SaleDate column is not standardize
-- we need to change the date format

update nashvilleHousing$
set SaleDate = CONVERT(date,saledate)

--due to no change from convert for saledate column
--need to alter table as saledateconverted

ALTER TABLE Nashvillehousing$
add SaleDateConverted Date;

update nashvilleHousing$
set SaleDateConverted = CONVERT(date,saledate)

select SaleDateConverted, convert(date,saledate)
from PortfolioProject.dbo.nashvilleHousing$


--2) Populated Property Address Data

select *
from PortfolioProject.dbo.nashvilleHousing$
where PropertyAddress is null

-- from table it shows that there 29 values of null in the PropertyAdress 

select ParcelID, PropertyAddress 
from PortfolioProject.dbo.nashvilleHousing$
order by ParcelID

-- it shows that same ParcelID = same PropertyAddress, 
-- means that we can populated the Null value in PropertyAddress by referring to ParcelID 

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
from PortfolioProject.dbo.nashvilleHousing$ a
Join PortfolioProject.dbo.nashvilleHousing$ b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-- from here it shows that, yes same parcelID should have same PropertyAddress
-- for next step is we need to populated the Null value with the data that have same ParcelID

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.nashvilleHousing$ a
Join PortfolioProject.dbo.nashvilleHousing$ b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

update a
set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.nashvilleHousing$ a
Join PortfolioProject.dbo.nashvilleHousing$ b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-- there is no null value in PropertyAddress column


--3) Breaking out Address into Individual Columns (Address, City, State) from 'PropertyAddress' using SUBTRING METHOD

select PropertyAddress 
from PortfolioProject.dbo.nashvilleHousing$

-- as we can see there is address and city in one column
-- we need to separate that into two column by using SUBTRING METHOD

select 
SUBSTRING(propertyAddress, 1 , CHARINDEX(',' , PropertyAddress) -1) as Address
, SUBSTRING(propertyAddress, CHARINDEX(',' , PropertyAddress) +1 , LEN(PropertyAddress)) as Address
from PortfolioProject.dbo.nashvilleHousing$

-- we already separete the address and city into two column, now insert it into our data

ALTER TABLE Nashvillehousing$
add PropertySplitAddress Nvarchar(225);

update nashvilleHousing$
set PropertySplitAddress = SUBSTRING(propertyAddress, 1 , CHARINDEX(',' , PropertyAddress) -1)

ALTER TABLE Nashvillehousing$
add PropertySplitCity Nvarchar(225);

update nashvilleHousing$
set PropertySplitCity = SUBSTRING(propertyAddress, CHARINDEX(',' , PropertyAddress) +1 , LEN(PropertyAddress))

select *
from PortfolioProject.dbo.nashvilleHousing$

-- PropertySplitAddress and PropertySplitCity are inserted in the table


--4) Breaking out Address into Individual Columns (Address, City, State) from 'OwnerAddress' using PARSENAME METHOD
select OwnerAddress
from PortfolioProject.dbo.nashvilleHousing$

-- Based on table, it shows that Address, City and State are in the same column
-- we can split the contents by using PARSENAME METHOD

SELECT
PARSENAME(Owneraddress, 1)
from PortfolioProject.dbo.nashvilleHousing$

--nothing change because it containts ',' and '.' in the column
--need to replace the ',' and '.' first

SELECT
PARSENAME(REPLACE(Owneraddress, ',', '.'), 3)
, PARSENAME(REPLACE(Owneraddress, ',', '.'), 2)
, PARSENAME(REPLACE(Owneraddress, ',', '.'), 1)
from PortfolioProject.dbo.nashvilleHousing$

--now, the contents aready split
-- insert the split Address, City and State in the table

ALTER TABLE Nashvillehousing$
add OwnerSplitAddress Nvarchar(225);

update nashvilleHousing$
set OwnerSplitAddress = PARSENAME(REPLACE(Owneraddress, ',', '.'), 3)

ALTER TABLE Nashvillehousing$
add OwnerSplitCity Nvarchar(225);

update nashvilleHousing$
set OwnerSplitCity = PARSENAME(REPLACE(Owneraddress, ',', '.'), 2)

ALTER TABLE Nashvillehousing$
add OwnerSplitState Nvarchar(225);

update nashvilleHousing$
set OwnerSplitState = PARSENAME(REPLACE(Owneraddress, ',', '.'), 1)

select *
from PortfolioProject.dbo.nashvilleHousing$

-- all Owner Split Address, City and State are inserted in the table

select SoldAsVacant
from PortfolioProject.dbo.nashvilleHousing$

-- from the 'SoldAsVacant' column it contains of Yes, No, Y and N
-- can use DISTINCT to identify it

select DISTINCT (SoldAsVacant)
from PortfolioProject.dbo.nashvilleHousing$

-- now, we need to identify how many of N, Y in the column
-- by using COUNT

select DISTINCT (SoldAsVacant), COUNT(SoldAsVacant)
from PortfolioProject.dbo.nashvilleHousing$
Group by SoldAsVacant
Order by 2

-- After identify, now can need to change Y into Yes and N into NO

select SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant 
			END
from PortfolioProject.dbo.nashvilleHousing$

-- now we already change Y and N into Yes and No
-- then we need insert it on the table

Update nashvilleHousing$
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant 
			END 

select DISTINCT (SoldAsVacant), COUNT(SoldAsVacant)
from PortfolioProject.dbo.nashvilleHousing$
Group by SoldAsVacant
Order by 2

-- in the SoldAsVacant only have Yes and No


-- 5) Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num

From PortfolioProject.dbo.nashvilleHousing$
)
SELECT * 
From RowNumCTE
WHERE row_num > 1
order by PropertyAddress

-- there are 104 rows of duplicate
-- now we need to delete all duplicate rows

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num

From PortfolioProject.dbo.nashvilleHousing$
)
DELETE 
From RowNumCTE
WHERE row_num > 1

-- all 104 rows of duplicated has been deleted
-- can checked in the table

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num

From PortfolioProject.dbo.nashvilleHousing$
)
SELECT * 
From RowNumCTE
WHERE row_num > 1
order by PropertyAddress

-- 6) DELETE Unused Column

SELECT *
From PortfolioProject.dbo.nashvilleHousing$

-- we can see there are few column need to be delete because we already modified the data previously
-- for example ; saledate, PropertyAddress and OwnerAddress

ALTER TABLE PortfolioProject.dbo.nashvilleHousing$
DROP COLUMN saledate, PropertyAddress, OwnerAddress

SELECT *
From PortfolioProject.dbo.nashvilleHousing$

-- All 3 columns have been deleted