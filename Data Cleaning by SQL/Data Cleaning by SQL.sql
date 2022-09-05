/*
Cleaning data with SQL
*/

Select *
from master..NashvilleHousing

-- Standardize Date Format
Select SaleDateConverted, CONVERT(Date, SaleDate)
from master..NashvilleHousing

	-- Could not convert directly
Update NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

	-- Create the temp column to convert Date
ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted= CONVERT(Date, SaleDate)

-- Populate Property Address data
Select *
from master..NashvilleHousing
order by ParcelID


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From master..NashvilleHousing a 
Join master..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From master..NashvilleHousing a 
Join master..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID] <> b.[UniqueID ]
Where a.PropertyAddress is null

-- Breaking out Address into individual Columns (Address, City, State)
Select PropertyAddress
from master..NashvilleHousing

Select
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as State
From master..NashvilleHousing

	-- Address Column
ALTER TABLE NashvilleHousing
Add PropertyAddressSplit nvarchar(255);

Update NashvilleHousing
SET PropertyAddressSplit= SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) 

	-- City Column
ALTER TABLE NashvilleHousing
Add PropertyAddressCity nvarchar(255);

Update NashvilleHousing
SET PropertyAddressCity= SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

	-- Double check
Select PropertyAddress, PropertyAddressSplit, PropertyAddressCity
from master..NashvilleHousing

	-- Split State

Select OwnerAddress
From master..NashvilleHousing

Select 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From master..NashvilleHousing


ALTER TABLE NashvilleHousing
Add OwnerSplitAddress nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress= PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity= PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
Add OwnerSplitState nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState= PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

Select OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
From master..NashvilleHousing


-- Change Y and N to Yes and No in "Sold as Vacant" field

	-- Pre-check data
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From master..NashvilleHousing
Group by SoldAsVacant

	-- Try to preprocess it
Select 
	SoldAsVacant,
	CASE When SoldAsVacant='Y' Then 'Yes'
		 When SoldAsVacant='N' Then 'No'
		 ELSE SoldAsVacant
		 END
From master..NashvilleHousing

	-- Update table
Update NashvilleHousing
SET SoldAsVacant =  CASE When SoldAsVacant='Y' Then 'Yes'
		 When SoldAsVacant='N' Then 'No'
		 ELSE SoldAsVacant
		 END

	-- Double check again
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From master..NashvilleHousing
Group by SoldAsVacant

-- Remove Duplicates

	-- check duplicated rows
WITH RowNumCTE AS (
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
From master..NashvilleHousing
)
Select *
From RowNumCTE
Where row_num > 1
Order By PropertyAddress

	-- Remove them out of DB
WITH RowNumCTE AS (
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
From master..NashvilleHousing
)
DELETE
From RowNumCTE
Where row_num > 1

-- Delete Unused Columns
Select *
From master..NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
