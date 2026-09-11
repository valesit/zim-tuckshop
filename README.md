# Zim Tuckshop

E-commerce platform for African groceries and everyday essentials.

## Direction
- Pan-African product positioning
- USD pricing
- Clean white + deep green visual system
- Search-first shopping experience
- Featured products and curated collections
- Customer accounts, cart, checkout and order history
- WhatsApp support
- Supabase for authentication, Postgres and product media

## Suggested stack
- Next.js + TypeScript
- Supabase Auth / Postgres / Storage
- Stripe or another U.S.-supported payment processor

## Initial pages
- `/` Home
- `/shop` Product catalog
- `/product/[slug]` Product detail
- `/cart` Cart
- `/account` Customer account
- `/admin` Store admin

## Supabase
Run `supabase/migrations/001_initial_schema.sql` in a new Supabase project.

The schema supports customers, addresses, categories, products, variants, inventory, carts, orders, discounts, reviews and admin access controls.
