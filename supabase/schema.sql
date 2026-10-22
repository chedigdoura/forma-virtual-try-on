-- FORMA Lens: stock and order backend for the static GitHub Pages storefront.
-- Run this complete file once in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.inventory (
  product_id text primary key,
  name text not null,
  category text not null check (category in ('lens','solutions','drops')),
  description text not null default '',
  image_url text not null default '',
  market_price_min numeric(10,3) not null default 0 check (market_price_min >= 0),
  market_price_max numeric(10,3) not null default 0 check (market_price_max >= market_price_min),
  sale_price numeric(10,3) not null default 0 check (sale_price >= 0),
  stock integer not null default 0 check (stock >= 0),
  available boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  ref text not null unique,
  created_at timestamptz not null default now(),
  status text not null default 'À traiter' check (status in ('À traiter','Confirmée','Expédiée','Terminée','Annulée')),
  customer_name text not null,
  phone text not null,
  address text not null,
  city text not null,
  total numeric(10,3) not null check (total >= 0)
);

create table if not exists public.order_items (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id text not null references public.inventory(product_id),
  product_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(10,3) not null check (unit_price >= 0)
);

alter table public.inventory enable row level security;
alter table public.admin_users enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create or replace function public.is_forma_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users a
    where a.user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_forma_admin() from public;
grant execute on function public.is_forma_admin() to authenticated;

drop policy if exists "Public reads available stock" on public.inventory;
create policy "Public reads available stock" on public.inventory
  for select to anon, authenticated using (available and stock > 0);
drop policy if exists "Admins manage stock" on public.inventory;
create policy "Admins manage stock" on public.inventory
  for all to authenticated using (public.is_forma_admin()) with check (public.is_forma_admin());

drop policy if exists "Admins read own admin row" on public.admin_users;
create policy "Admins read own admin row" on public.admin_users
  for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "Admins read orders" on public.orders;
create policy "Admins read orders" on public.orders
  for select to authenticated using (public.is_forma_admin());
drop policy if exists "Admins update orders" on public.orders;
create policy "Admins update orders" on public.orders
  for update to authenticated using (public.is_forma_admin()) with check (public.is_forma_admin());

drop policy if exists "Admins read order items" on public.order_items;
create policy "Admins read order items" on public.order_items
  for select to authenticated using (public.is_forma_admin());

grant select on public.inventory to anon, authenticated;
grant select on public.admin_users to authenticated;
grant insert, update, delete on public.inventory to authenticated;
grant select, update on public.orders to authenticated;
grant select on public.order_items to authenticated;

create or replace function public.place_order(
  p_customer_name text,
  p_phone text,
  p_address text,
  p_city text,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_item jsonb;
  v_line jsonb;
  v_product public.inventory%rowtype;
  v_product_id text;
  v_quantity integer;
  v_order_id uuid;
  v_ref text := 'FL-' || to_char(clock_timestamp(),'YYMMDDHH24MISS') || '-' || left(gen_random_uuid()::text,4);
  v_total numeric(10,3) := 0;
  v_lines jsonb := '[]'::jsonb;
begin
  if nullif(trim(p_customer_name),'') is null or length(p_customer_name) > 120 then
    raise exception 'Nom invalide.';
  end if;
  if nullif(trim(p_phone),'') is null or length(p_phone) > 40 then
    raise exception 'Téléphone invalide.';
  end if;
  if nullif(trim(p_address),'') is null or length(p_address) > 300 then
    raise exception 'Adresse invalide.';
  end if;
  if nullif(trim(p_city),'') is null or length(p_city) > 100 then
    raise exception 'Ville invalide.';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) < 1 or jsonb_array_length(p_items) > 30 then
    raise exception 'Panier invalide.';
  end if;
  if (select count(*) from jsonb_array_elements(p_items)) <>
     (select count(distinct value->>'product_id') from jsonb_array_elements(p_items)) then
    raise exception 'Le panier contient une référence en double.';
  end if;

  for v_item in select value from jsonb_array_elements(p_items) loop
    v_product_id := v_item->>'product_id';
    v_quantity := (v_item->>'quantity')::integer;
    if v_quantity < 1 then raise exception 'Quantité invalide.'; end if;
    select * into v_product from public.inventory i where i.product_id = v_product_id for update;
    if not found or not v_product.available or v_product.stock < v_quantity or v_product.sale_price <= 0 then
      raise exception 'Un produit n’est plus disponible ou le stock a changé.';
    end if;
    v_total := v_total + v_product.sale_price * v_quantity;
    v_lines := v_lines || jsonb_build_array(jsonb_build_object(
      'product_id', v_product.product_id,
      'product_name', v_product.name,
      'quantity', v_quantity,
      'unit_price', v_product.sale_price
    ));
  end loop;

  insert into public.orders(ref, customer_name, phone, address, city, total)
  values(v_ref, trim(p_customer_name), trim(p_phone), trim(p_address), trim(p_city), v_total)
  returning id into v_order_id;

  for v_line in select value from jsonb_array_elements(v_lines) loop
    update public.inventory i
      set stock = i.stock - (v_line->>'quantity')::integer,
          available = (i.stock - (v_line->>'quantity')::integer) > 0,
          updated_at = now()
      where i.product_id = v_line->>'product_id';
    insert into public.order_items(order_id, product_id, product_name, quantity, unit_price)
    values(v_order_id, v_line->>'product_id', v_line->>'product_name',
           (v_line->>'quantity')::integer, (v_line->>'unit_price')::numeric);
  end loop;

  return jsonb_build_object('id',v_order_id,'ref',v_ref,'total',v_total);
end;
$$;
revoke all on function public.place_order(text,text,text,text,jsonb) from public;
grant execute on function public.place_order(text,text,text,text,jsonb) to anon, authenticated;

insert into public.inventory(product_id,name,category,description,image_url,market_price_min,market_price_max,sale_price,stock,available)
values
('lens-lentilles-wonderlook','Lentilles Wonderlook','lens','Boîte de 5 paires · port 1 mois · sans correction','https://tunislenses.com/wp-content/uploads/2026/10/wl-box-duo.webp',120,120,0,0,false),
('lens-3d-colors','3D Colors','lens','La paire · port jusqu’à 6 mois · sans correction','https://tunislenses.com/wp-content/uploads/2026/10/3d-pack-family.jpg',90,90,0,0,false),
('lens-soft-vision-color','Soft Vision Color','lens','Boîte de 2 lentilles · durée annoncée trimestrielle · options correctrices selon disponibilité','https://azzabioptic.com/wp-content/uploads/2025/09/9-2-299x299.jpg.webp',70,70,0,0,false),
('lens-lentilles-bella-elite','Lentilles Bella Elite','lens','Lentilles colorées · prix selon la teinte et la variante','https://ecom-cdn.magrabi.com/prod/files/123943008/cl_product_image/en_US/magrabi_ecommerce/1239430_0.jpg',140,140,0,0,false),
('lens-adore-tri-grey','Adore Tri Grey','lens','Paire de lentilles colorées · port trimestriel · retrait en boutique indiqué','https://blink.bg/image/cache/catalog/incoming/image/data/Cvetni/adore-tritone-color-lenses-copy-1200x1200.webp',100,100,0,0,false),
('lens-aqua-blue','Aqua Blue','lens','Lentilles colorées · teinte Aqua Blue · retrait en boutique indiqué','https://azzabioptic.com/wp-content/uploads/2025/09/9-2-299x299.jpg.webp',60,60,0,0,false),
('lens-biofinity','Biofinity','lens','Boîte de 3 · prix affiché par AZZABI Optic · correction à choisir','https://azzabioptic.com/wp-content/uploads/2025/09/1-5-1-800x800.jpg',80,80,0,0,false),
('lens-clariti-1-day','Clariti 1 Day','lens','Prix affiché · conditionnement et correction à confirmer sur la fiche source','https://images.tcdn.com.br/img/img_prod/1294871/lente_de_contato_clariti_1_day_miopia_2_20250827082805_0b1f532a7de3.png',160,160,0,0,false),
('solutions-eye-care-pharma-souples','Eye Care Pharma Souples','solutions','Solution d’entretien pour lentilles souples','https://www.parashop.tn/image/cache/catalog/produits/eye-care/eye-care-pharma-souples-solution-lentilles-550x550.jpg',30,35,0,0,false),
('solutions-c-lens-plus','C Lens Plus','solutions','Solution d’entretien pour lentilles de contact','https://paraland.tn/9425-thickbox_default/c-lens-plus-solution-lentilles-180ml.jpg',17.39,17.395,0,0,false),
('drops-uniflow-eye-care','Uniflow Eye Care','drops','Gouttes oculaires d’hydratation · consulter la notice','https://mypharma.tn/891-large_default/eye-care-uniflow-gouttes-oculaires-d-hydratation-10ml.jpg',26,27.517,0,0,false),
('drops-innoxa-hydralose','Innoxa Hydralose','drops','Gouttes hydratantes · prix promotionnel affiché sur la fiche source','https://www.illicopharma.com/113517-thickbox_default/innoxa-hydralose-gouttes-oculaires-hydratantes-10ml.jpg',35.1,35.1,0,0,false),
('drops-visionlux-plus','Visionlux Plus','drops','Flacon 10 ml · prix repéré sur une parapharmacie tunisienne','https://1001para.tn/25522-large_default/visionlux-plus-gouttes-oculaire-10-ml.jpg',46.635,46.635,0,0,false)
on conflict (product_id) do nothing;

-- After adding the administrator under Supabase Authentication > Users, run:
-- insert into public.admin_users(user_id,email)
-- select id,email from auth.users where email = 'YOUR_ADMIN_EMAIL'
-- on conflict (user_id) do nothing;
