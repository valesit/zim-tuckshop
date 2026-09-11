# Zim Tuckshop database design

The Supabase schema is designed around the main ecommerce workflows.

## Main entities

- `profiles` — customer and admin profile data linked to Supabase Auth
- `addresses` — saved customer shipping addresses
- `categories` — product categories
- `products` — shared product information
- `product_variants` — SKU, price and inventory for each sellable variant
- `product_images` — Supabase Storage paths for product images
- `favorites` — customer wishlists
- `carts` and `cart_items` — shopping basket data
- `shipping_methods` — shipping and pickup options
- `coupons` — discount codes
- `orders` and `order_items` — completed customer orders and immutable purchase snapshots
- `order_status_history` — order tracking history
- `reviews` — moderated customer product reviews
- `site_content` — editable homepage and merchandising content

## Relationship overview

```text
auth.users
  └── profiles
      ├── addresses
      ├── favorites ── products
      ├── carts ── cart_items ── product_variants ── products
      ├── orders ── order_items ── products / product_variants
      │   └── order_status_history
      └── reviews ── products

categories ── products ── product_images
                    └──── product_variants
```

## Design choices

**Products and variants:** Product details live once in `products`. Price, SKU and stock are stored in `product_variants`, allowing package sizes and future options without redesigning the schema.

**Historical order accuracy:** `order_items` stores the product name, SKU and price at checkout so old orders remain accurate even if catalog data changes later.

**Security:** Row Level Security allows public catalog reads while customer profile, address, cart and order data is restricted to the signed-in customer. Admin access is controlled through `profiles.role`.

**Payments:** Only payment provider references belong in the database. Raw card details should never be stored in Supabase.

**Images:** Product images should be stored in a Supabase Storage bucket such as `product-images`, with the object path stored in `product_images.storage_path`.

## Recommended next setup steps

1. Create the Supabase project.
2. Run `supabase/migrations/001_initial_schema.sql`.
3. Create `product-images` and `site-assets` Storage buckets.
4. Create the initial administrator account and change its `profiles.role` to `admin`.
5. Add Supabase project URL and anon key to the Next.js environment configuration.
6. Build checkout through trusted server-side code and integrate the selected payment provider.
