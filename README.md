# SACO Management

Multi-brand distribution for **SACO** — sell by product code (FIABILA, YC, …).

## Setup (production)

After ERPNext setup wizard:

```bash
bench --site YOUR_SITE execute saco_management.setup.saco_setup.run
```

This creates:
- Item custom fields (Brand, Net Weight, Carton Packing)
- Item Groups + Price Lists per brand
- **261 items** from bundled FIABILA + YC base price lists
- Selling defaults for **Sales Invoice → Delivery Note** workflow

## Import another brand later

```bash
bench --site YOUR_SITE execute saco_management.setup.import_items.run \
  --kwargs '{"xlsx_path": "/path/PRICE LIST NEWBRAND.xlsx", "brand": "NEWBRAND"}'
```

Excel format: row 1 title, row 3 headers with `CODE`, `DESCRIPTION`, `PRICE` (optional `N.W`, `CTN PACKING`, `BARCODE`).

## Workflow

1. **Sales Invoice** — add lines by item code (`FL001`, `YC229`, …); leave **Update Stock** unchecked
2. Submit invoice
3. **Create → Delivery Note** from the invoice
4. Submit delivery note to reduce stock

## Development

```bash
rsync -a --exclude '.git' apps/saco_management/ ~/saco_erp/
```
