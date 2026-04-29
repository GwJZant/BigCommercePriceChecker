# Load the configuration file
$configFile = "$PSScriptRoot\config.json"

if (Test-Path $configFile) {
    # Read the file and convert JSON into a PowerShell Object
    $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
} else {
    Write-Host "ERROR: config.json not found!" -ForegroundColor Red
    exit
}

# Setup API Credentials
$token = $config.BigCommerce.Token
$url   = $config.BigCommerce.GraphQLEndpoint

$allBcPrices    = @{} # A 'Hash Table' to store SKU => Price for fast lookup
$hasNextPage    = $true
$endCursor      = $null
$productCount   = 0
$nullSkuCount   = 0
$noVariantCount = 0

# Ask for Username and Password in the console
$passSecure = Read-Host "Enter $($config.Celerant.Username) SQL Password" -AsSecureString

Write-Host "Fetching all products from BigCommerce (this may take a minute)..." -ForegroundColor Cyan

while ($hasNextPage) {
	# If we have a cursor, we tell GraphQL where to start the next page
    $after = if ($endCursor) { "after: `"$endCursor`"" } else { "" }
	
	# 2. Define the GraphQL Query
	# This asks for 50 products, their SKU, and their current price
	$graphQuery = @{
		query = "query {
			site {
				products (first: 50 $after) {
					pageInfo { hasNextPage endCursor }
					edges {
						node {
							entityId
							sku
							prices {
								price {
									value
								}
							}
						}
					}
				}
			}
		}"
	} | ConvertTo-Json
	
	$headers = @{
		"Authorization" = "Bearer $token"
		"Content-Type"  = "application/json"
	}

	$response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $graphQuery
	
	# Write-Host "Debug: hasNextPage = $($response.data.site.products.pageInfo.hasNextPage) | Cursor = $($response.data.site.products.pageInfo.endCursor)"

	# Drill down into the data
	$bcProducts = $response.data.site.products.edges

	foreach ($productEdge in $bcProducts) {
		$p = $productEdge.node
		$productCount++
		
		if ($p.sku) {
			$allBcPrices[$p.sku] = [decimal]$($p.prices.price.value)
			# Write-Host "SKU: $($p.sku) Price: $($p.prices.price.value)"
		} else {
			Write-Host "No SKU from entity: $($p.entityId) Price: $($p.prices.price.value)"
		}			
	}
	
	# Check if there's another page
    $hasNextPage = $response.data.site.products.pageInfo.hasNextPage
    $endCursor   = $response.data.site.products.pageInfo.endCursor

	if ($productCount % 500 -eq 0) {
		Write-Host "Collected $($allBcPrices.Count) SKUs from $($productCount) Products so far..."
	}
}

Write-Host "Total: Collected $($allBcPrices.Count) SKUs from $($productCount) Products."

# Connect to Celerant Database
Write-Host "Connecting to Celerant Database and comparing prices..." -ForegroundColor Cyan

# Convert to plain text for the SQL Driver
$passPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($passSecure)
)

# Set up SQL parameters
$sqlParams = @{
    ServerInstance         = $config.Celerant.ServerInstance
    Database               = $config.Celerant.Database
    Query                  = "SELECT DISTINCT styles.STYLE AS SKU, tickets.PRICE AS PRICE FROM TB_STYLES styles
								INNER JOIN VW_TICKETS tickets
								ON tickets.STYLE_ID = styles.STYLE_ID
								AND tickets.STORE_ID = 1
								WHERE styles.OF5 = ''
								AND styles.STATUS_FINISH = 'N';" # Adjust your query here
	Username               = $config.Celerant.Username
	Password               = $passPlain
	Encrypt                = "Mandatory"
	TrustServerCertificate = $true
}

try {
    $posData = Invoke-Sqlcmd @sqlParams
    
    $mismatches = @()
    $notFoundInBC = 0
    $foundInBC = 0

    foreach ($row in $posData) {
        $sku = $row.SKU
        $posPrice = [decimal]$row.Price
		$bcPrice = [decimal]$allBcPrices[$sku]
		
		if ($allBcPrices.ContainsKey($sku)) {
			# Write-Host "Match found for $($sku)! BigCommerce Price: $bcPrice Celerant Price: $posPrice"
			$foundInBC++
			
			if ($allBcPrices[$sku] -ne $posPrice) {
				$mismatches += [PSCustomObject]@{
                    SKU      = $sku
                    PosPrice = $posPrice
                    BcPrice  = $bcPrice
                    Diff     = $posPrice - $bcPrice
                }
			}
		} else {
			$notFoundInBC++
		}
    }

    # Final Report
    Write-Host "`nComparison Complete!" -ForegroundColor Green
    Write-Host "Mismatches Found: $($mismatches.Count)"
    Write-Host "SKUs in POS but missing in BC: $notFoundInBC"
	
	if ($mismatches.Count -gt 0) {
        $mismatches | Sort-Object SKU | Export-Csv -Path ".\PriceMismatches.csv" -NoTypeInformation
        Write-Host "Results exported to PriceMismatches.csv" -ForegroundColor Yellow
    }
} catch {
    Write-Host "SQL Error: $_" -ForegroundColor DarkRed
}

