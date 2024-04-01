/*

Cleaning Data in SQL Queries

*/

select *
from PortfolioProject.dbo.NashvilleHousing

-------------------------------------------------------------------------------------------

-- Standardise sale date format

select SaleDate, convert(date, SaleDate)
from PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
Set SaleDate = CONVERT(date, SaleDate)

---

ALTER TABLE NashvilleHousing 
add SaleDateConverted Date;

UPDATE NashvilleHousing
Set SaleDateConverted = CONVERT(date, SaleDate)

select SaleDateConverted, convert(date, SaleDate)
from PortfolioProject.dbo.NashvilleHousing

-------------------------------------------------------------------------------------------

-- Populate property address data
-- note that if you order by ParcelID, there are duplicate addresses

select *
from PortfolioProject.dbo.NashvilleHousing
--where PropertyAddress is null
order by ParcelID

-- do a self join and replace the null address where the parcelID matches
-- ISNULL checks if 1. is NULL and replaces with 2.

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
	, ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-------------------------------------------------------------------------------------------

-- Breaking out address into individual columns (address, city, state)
-- only delimiter is comma (,)
-- use substring and character index
-- Looks at PropertyAddress, looks at first value and goes until comma (but comma stays in the output) and gives the number

select PropertyAddress
from PortfolioProject.dbo.NashvilleHousing
--where PropertyAddress is null
--order by ParcelID

select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address
from PortfolioProject.dbo.NashvilleHousing


ALTER TABLE NashvilleHousing 
add PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing 
add PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

select PropertySplitAddress, PropertySplitCity
from PortfolioProject.dbo.NashvilleHousing


-- OwnerAddress split with parse name
-- PARSENAME useful for full stops not commas

select OwnerAddress
from PortfolioProject.dbo.NashvilleHousing

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'),  3) as address
, PARSENAME(REPLACE(OwnerAddress, ',', '.'),  2) as city
, PARSENAME(REPLACE(OwnerAddress, ',', '.'),  1) as state
from PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing 
add OwnerSplitAddress nvarchar(255);

ALTER TABLE NashvilleHousing 
add OwnerSplitCity nvarchar(255);

ALTER TABLE NashvilleHousing 
add OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),  3)

UPDATE NashvilleHousing
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),  2)

UPDATE NashvilleHousing
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),  1)

select OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
from PortfolioProject.dbo.NashvilleHousing

-------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field
-- there's more Y/N than Yes/No

select SoldAsVacant
, CASE when SoldAsVacant = 'Y' then 'Yes'
		When SoldAsVacant = 'N' then 'No'
		ELSE SoldAsVacant
		END
from PortfolioProject.dbo.NashvilleHousing

Update NashvilleHousing
Set SoldAsVacant = 
	CASE when SoldAsVacant = 'Y' then 'Yes'
		When SoldAsVacant = 'N' then 'No'
		ELSE SoldAsVacant
		END

select distinct(SoldAsVacant), count(SoldAsVacant)
from PortfolioProject.dbo.NashvilleHousing
group by SoldAsVacant
order by 2 desc

-------------------------------------------------------------------------------------------

-- Remove duplicates
-- not used a lot in queries, temp tables would remove duplicates
-- CTE (basically a temp table) and find duplicate row
-- could use rank, orderrank, rownumber
-- partition by what should be unique in each row and order by soemthing unique

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
from PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)
Select *
-- DELETE 
-- replace Select with DELETE
From RowNumCTE 
Where row_num > 1
order by PropertyAddress

-----------------------------------------------------------------------------------------------

-- Remove unused columns
-- this happens more for views not really the raw data

Select *
from PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
Drop COLUMN SaleDate, OwnerAddress, TaxDistrict, PropertyAddress




-----------------------------------------------------------------------------------------------
-- for self study
-- every computer is different and configured differently 
-- ETL?

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO



