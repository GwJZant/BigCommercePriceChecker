This tool queries BigCommerce's GraphQL endpoint to pull SKU (product-level, not variant-level) and Price values and compares them against Celerant to identify price mismatches. It specifically ONLY looks at products in BigCommerce that are "in stock" in order to weed out inactive items with sale prices.

This tool requires SQL database credentials. If you do not have them, ask AJ.

HOW TO USE:

1a. Right-click BigCommercePriceChecker.ps1 and select "Run with PowerShell". 

1b. Alternatively, Shift + Right-click anywhere in the folder (don't Shift + Right-click the file itself) and select "Open PowerShell window here" to open a PowerShell window first. This will make it so the command prompt window won't close as soon as this tool finishes which will let you inspect the output if you wish. To run the script with this method, type (or copy and paste) the following:

./BigCommercePriceChecker.ps1

2. When prompted, enter the password to the SQL database.

3. Allow script to run to completion then open the resulting PriceMismatches.csv file. This file is sorted by SKU but I recommend adding a filter and sorting the price difference column to allow you to cherry pick what data you wish to see.

NOTE: This tool is not perfect at all and mismatches can falsely appear several ways:

1. When Product Codes get reused in Celerant. For example if there are two "40000" products in Celerant and BigCommerce has a product page for one of those, there's a chance this tool will reference the wrong price that will depend *which* product was set up in BigCommerce relative to the order the product was entered in Celerant.

2. When there is variant/sku-level pricing. If a particular product has a base price of 54.95 in Celerant but some skus are 59.95, the Celerant price being referenced will likely be the max for that product while BigCommerce operates the opposite way where it'll look at the base price which is most often the smallest/cheapest variant when multiples exist. This is most noticeable in pet food and pet apparel.

3. I believe that, with the way products USED to be imported or configured in BigCommerce, there can be prices that are hidden. I haven't seen this happen too often but I have definitely encountered more than one product that GraphQL said the price was one value but when I viewed the product page, that particular price was nowhere to be found even among variants.

If the difference in price between Celerant and BigCommerce is large (greater than $10 for footwear, greater than $2 for pet supplies) it probably indicates there are variants with different pricing. If the price difference is smaller than that, it's probably a sign that a price change happened in Celerant that didn't happen in BigCommerce. Do not ignore the former though because a price change still could have been missed. Additionally, it's not a bad idea to copy the skus of products with variable variant pricing and search them in Celerant to verify the pricing on those is accurate.

This tool would provide much more reliable data if the BigCommerce GraphQL API reliably pulled in all skus but it seems like internally there may have been some things that have changed over the years resulting in variants not appearing in the variants data objects despite appearing as variants in the web interface. Unless and until I can find a solution to that, the data provided will be sketchy. 

All that being said, the information that matters most is the products where **BigCommerce's price is LOWER than Celerant's price**. Sometimes, prices on BigCommerce are slightly higher than in-store and that is intentional, however the inverse should not be true without promos being involved. Therefore, use this tool merely as a guide to understand which products warrant investigation.