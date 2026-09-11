create extension if not exists pgcrypto;

create type public.user_role as enum ('customer','admin');
create type public.order_status as enum ('pending','payment_pending','paid','processing','ready_for_pickup','shipped','delivered','cancelled','refunded');
create type public.fulfillment_type as enum ('shipping','pickup');
create type public.discount_type as enum ('percent','fixed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null default 'customer',
  first_name text,
  last_name text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  label text,
  full_name text not null,
  line1 text not null,
  line2 text,
  city text not null,
  state text not null,
  postal_code text not null,
  country_code text not null default 'US',
  phone text,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  image_url text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories(id) on delete set null,
  name text not null,
  slug text not null unique,
  description text,
  brand text,
  country_of_origin text,
  ingredients text,
  allergens text,
  is_featured boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  sku text not null unique,
  name text not null default 'Standard',
  price_cents integer not null check (price_cents >= 0),
  compare_at_price_cents integer check (compare_at_price_cents is null or compare_at_price_cents >= 0),
  stock_quantity integer not null default 0 check (stock_quantity >= 0),
  low_stock_threshold integer not null default 5 check (low_stock_threshold >= 0),
  weight_grams integer,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  storage_path text not null,
  alt_text text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.favorites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

create table public.carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references public.profiles(id) on delete cascade,
  session_token text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (user_id is not null or session_token is not null)
);

create table public.cart_items (
  id uuid primary key default gen_random_uuid(),
  cart_id uuid not null references public.carts(id) on delete cascade,
  variant_id uuid not null references public.product_variants(id) on delete cascade,
  quantity integer not null default 1 check (quantity > 0),
  created_at timestamptz not null default now(),
  unique (cart_id, variant_id)
);

create table public.shipping_methods (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  price_cents integer not null default 0 check (price_cents >= 0),
  estimated_days_min integer,
  estimated_days_max integer,
  fulfillment_type public.fulfillment_type not null default 'shipping',
  is_active boolean not null default true
);

create table public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  description text,
  discount_type public.discount_type not null,
  discount_value integer not null check (discount_value > 0),
  minimum_order_cents integer not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  usage_limit integer,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  order_number text not null unique,
  status public.order_status not null default 'pending',
  fulfillment_type public.fulfillment_type not null default 'shipping',
  email text not null,
  phone text,
  shipping_name text,
  shipping_line1 text,
  shipping_line2 text,
  shipping_city text,
  shipping_state text,
  shipping_postal_code text,
  shipping_country_code text default 'US',
  subtotal_cents integer not null default 0,
  discount_cents integer not null default 0,
  shipping_cents integer not null default 0,
  tax_cents integer not null default 0,
  total_cents integer not null default 0,
  coupon_code text,
  payment_provider text,
  payment_reference text,
  customer_note text,
  placed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  variant_id uuid references public.product_variants(id) on delete set null,
  sku text,
  product_name text not null,
  variant_name text,
  unit_price_cents integer not null,
  quantity integer not null check (quantity > 0),
  line_total_cents integer not null,
  created_at timestamptz not null default now()
);

create table public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  status public.order_status not null,
  note text,
  changed_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  title text,
  body text,
  is_approved boolean not null default false,
  created_at timestamptz not null default now(),
  unique (product_id, user_id)
);

create table public.site_content (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,first_name,last_name)
  values(new.id,new.raw_user_meta_data->>'first_name',new.raw_user_meta_data->>'last_name')
  on conflict(id) do nothing;
  return new;
end;$$;

create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;

alter table public.profiles enable row level security;
alter table public.addresses enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.product_images enable row level security;
alter table public.favorites enable row level security;
alter table public.carts enable row level security;
alter table public.cart_items enable row level security;
alter table public.shipping_methods enable row level security;
alter table public.coupons enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;
alter table public.reviews enable row level security;
alter table public.site_content enable row level security;

create policy "catalog categories are public" on public.categories for select using (is_active or public.is_admin());
create policy "catalog products are public" on public.products for select using (is_active or public.is_admin());
create policy "catalog variants are public" on public.product_variants for select using (is_active or public.is_admin());
create policy "product images are public" on public.product_images for select using (true);
create policy "shipping methods are public" on public.shipping_methods for select using (is_active or public.is_admin());
create policy "approved reviews are public" on public.reviews for select using (is_approved or user_id=auth.uid() or public.is_admin());
create policy "users read own profile" on public.profiles for select using (id=auth.uid() or public.is_admin());
create policy "users update own profile" on public.profiles for update using (id=auth.uid()) with check (id=auth.uid());
create policy "users manage own addresses" on public.addresses for all using (user_id=auth.uid() or public.is_admin()) with check (user_id=auth.uid() or public.is_admin());
create policy "users manage own favorites" on public.favorites for all using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "users manage own carts" on public.carts for all using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "users manage own cart items" on public.cart_items for all using (exists(select 1 from public.carts c where c.id=cart_id and c.user_id=auth.uid())) with check (exists(select 1 from public.carts c where c.id=cart_id and c.user_id=auth.uid()));
create policy "users read own orders" on public.orders for select using (user_id=auth.uid() or public.is_admin());
create policy "users read own order items" on public.order_items for select using (exists(select 1 from public.orders o where o.id=order_id and (o.user_id=auth.uid() or public.is_admin())));
create policy "users read own order history" on public.order_status_history for select using (exists(select 1 from public.orders o where o.id=order_id and (o.user_id=auth.uid() or public.is_admin())));
create policy "users create reviews" on public.reviews for insert with check (user_id=auth.uid());
create policy "users update own reviews" on public.reviews for update using (user_id=auth.uid()) with check (user_id=auth.uid());

create policy "admins manage categories" on public.categories for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage products" on public.products for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage variants" on public.product_variants for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage images" on public.product_images for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage shipping" on public.shipping_methods for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage coupons" on public.coupons for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage orders" on public.orders for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage order items" on public.order_items for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage order history" on public.order_status_history for all using (public.is_admin()) with check (public.is_admin());
create policy "admins manage reviews" on public.reviews for all using (public.is_admin()) with check (public.is_admin());
create policy "site content is public" on public.site_content for select using (true);
create policy "admins manage site content" on public.site_content for all using (public.is_admin()) with check (public.is_admin());

insert into public.categories(name,slug,sort_order) values
('Grains & Cereals','grains-cereals',10),
('Beans & Pulses','beans-pulses',20),
('Oils & Cooking','oils-cooking',30),
('Spices & Seasonings','spices-seasonings',40),
('Snacks & Treats','snacks-treats',50),
('Tea, Drinks & Beverages','tea-drinks-beverages',60),
('Dried Fish & Meats','dried-fish-meats',70),
('Household Essentials','household-essentials',80)
on conflict(slug) do nothing;

insert into public.shipping_methods(name,description,price_cents,estimated_days_min,estimated_days_max,fulfillment_type) values
('Standard Delivery','Standard U.S. delivery',799,2,5,'shipping'),
('Store Pickup','Pickup from Zim Tuckshop',0,0,0,'pickup');

insert into public.site_content(key,value) values
('homepage','{"announcement":"More Than Groceries. A Taste of Home.","heroTitle":"A Taste of Home No Matter Where You Are","heroBody":"Authentic African food, everyday essentials and family favourites from across the continent — delivered to your door."}'::jsonb)
on conflict(key) do nothing;
