This tool queries BigCommerce's GraphQL endpoint to pull SKU (product-level, not variant-level) and Price values and compares them against Celerant to identify price mismatches. It specifically ONLY looks at products in BigCommerce that are "in stock" in order to weed out inactive items with sale prices.

NOTE: This tool is not perfect at all and mismatches can falsely appear several ways:
1. When Product Codes get reused in Celerant. For example if there are two "40000" products in Celerant and BigCommerce has a product page for one of those, there's a chance this tool will reference the wrong price that will depend *which* product was set up in BigCommerce relative to the order the product was entered in Celerant.

2. When there is variant/sku-level pricing. If a particular product has a base price of 54.95 in Celerant but some skus are 59.95, the Celerant price being referenced will likely be the max for that product while BigCommerce operates the opposite way where it'll look at the base price which is most often the smallest/cheapest variant when multiples exist. This is most noticeable in pet food and pet apparel.

Therefore, use this tool merely as a guide to understand which products warrant investigation.