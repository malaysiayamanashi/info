-- MY × Yamanashi public community board
-- Run once in Supabase Dashboard → SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.community_events (
  id uuid primary key default gen_random_uuid(),
  event_date date not null,
  title text not null check (char_length(btrim(title)) between 2 and 100),
  description text not null default '' check (char_length(description) <= 1000),
  image_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  event_date date not null,
  title text not null check (char_length(btrim(title)) between 3 and 100),
  body text not null check (char_length(btrim(body)) between 3 and 1500),
  source_url text check (source_url is null or (char_length(source_url) <= 500 and source_url ~ '^https?://')),
  image_url text,
  video_url text check (video_url is null or (char_length(video_url) <= 1000 and video_url ~ '^https?://')),
  category text not null default 'general' check (category in ('general','university','islamic')),
  created_at timestamptz not null default now()
);
alter table public.community_posts add column if not exists video_url text;
alter table public.community_posts add column if not exists category text not null default 'general';
do $$ begin
  if not exists (select 1 from pg_constraint where conname='community_posts_category_check' and conrelid='public.community_posts'::regclass) then
    alter table public.community_posts add constraint community_posts_category_check check (category in ('general','university','islamic'));
  end if;
end $$;

-- A single administrator-managed video shown in the Latest updates spotlight.
create table if not exists public.featured_video (
  id integer primary key default 1 check (id = 1),
  title text not null default 'From Yamanashi, for our community' check (char_length(title) between 2 and 100),
  caption text not null default '' check (char_length(caption) <= 500),
  media_url text not null check (char_length(media_url) <= 1000 and media_url ~ '^https?://'),
  updated_at timestamptz not null default now()
);

create table if not exists public.restaurants (
  slug text primary key check (char_length(btrim(slug)) between 2 and 80),
  region_slug text not null default 'yamanashi' check (char_length(btrim(region_slug)) between 2 and 60),
  region_name text not null default 'Yamanashi' check (char_length(btrim(region_name)) between 2 and 80),
  area_slug text not null check (char_length(btrim(area_slug)) between 2 and 60),
  area_name text not null check (char_length(btrim(area_name)) between 2 and 80),
  name text not null check (char_length(btrim(name)) between 2 and 100),
  category text not null default 'Restaurant' check (char_length(btrim(category)) between 2 and 60),
  description text not null default '' check (char_length(description) <= 1000),
  map_url text check (map_url is null or (char_length(map_url) <= 500 and map_url ~ '^https?://')),
  image_url text,
  image_source_url text check (image_source_url is null or (char_length(image_source_url) <= 1000 and image_source_url ~ '^https?://')),
  created_at timestamptz not null default now()
);

alter table public.restaurants add column if not exists region_slug text not null default 'yamanashi';
alter table public.restaurants add column if not exists region_name text not null default 'Yamanashi';
alter table public.restaurants add column if not exists image_source_url text;
create table if not exists public.food_areas (
  id uuid primary key default gen_random_uuid(),
  region_slug text not null check (char_length(btrim(region_slug)) between 2 and 60),
  region_name text not null check (char_length(btrim(region_name)) between 2 and 80),
  area_slug text not null check (char_length(btrim(area_slug)) between 2 and 60),
  area_name text not null check (char_length(btrim(area_name)) between 2 and 80),
  is_nationwide boolean not null default false,
  created_at timestamptz not null default now(),
  unique (region_slug, area_slug)
);
insert into public.food_areas (region_slug,region_name,area_slug,area_name,is_nationwide) values
  ('yamanashi','Yamanashi','kofu','Kofu',false),
  ('tokyo','Tokyo','shinjuku','Shinjuku',false),
  ('tokyo','Tokyo','ueno','Ueno',false),
  ('tokyo','Tokyo','akihabara','Akihabara',false),
  ('konbini','Konbini','konbini','Konbini',true),
  ('grocery','Grocery','grocery','Grocery',true)
on conflict (region_slug,area_slug) do update set region_name=excluded.region_name,area_name=excluded.area_name,is_nationwide=excluded.is_nationwide;
update public.restaurants set region_slug='yamanashi',region_name='Yamanashi' where area_slug='kofu';
update public.restaurants set region_slug='tokyo',region_name='Tokyo' where area_slug in ('shinjuku','ueno','akihabara');
update public.restaurants set region_slug='konbini',region_name='Konbini' where area_slug='konbini';
update public.restaurants set region_slug=area_slug,region_name=area_name where area_slug not in ('kofu','shinjuku','ueno','akihabara','konbini') and region_slug='yamanashi' and region_name='Yamanashi';
insert into public.food_areas (region_slug,region_name,area_slug,area_name,is_nationwide)
select distinct region_slug,region_name,area_slug,area_name,region_slug in ('konbini','grocery') from public.restaurants
on conflict (region_slug,area_slug) do nothing;

create table if not exists public.mosque_places (
  slug text primary key check (char_length(btrim(slug)) between 2 and 80),
  area_name text not null check (char_length(btrim(area_name)) between 2 and 80),
  name text not null check (char_length(btrim(name)) between 2 and 100),
  description text not null default '' check (char_length(description) <= 1000),
  map_url text check (map_url is null or (char_length(map_url) <= 500 and map_url ~ '^https?://')),
  image_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.community_info (
  key text primary key check (key = 'students'),
  title text not null default 'Malaysian student community' check (char_length(title) <= 100),
  body text not null default '' check (char_length(body) <= 1500),
  student_count text not null default 'To be updated' check (char_length(student_count) <= 50),
  updated_at timestamptz not null default now()
);

create table if not exists public.site_media (
  key text primary key check (key = 'homepage-hero'),
  image_url text not null check (char_length(image_url) <= 1000 and image_url ~ '^https?://'),
  updated_at timestamptz not null default now()
);

create table if not exists public.student_bulletin (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('update','introduction')),
  author_name text not null default 'Malaysian student' check (char_length(btrim(author_name)) between 2 and 60),
  program text check (program is null or char_length(program) <= 100),
  title text not null check (char_length(btrim(title)) between 3 and 100),
  body text not null check (char_length(btrim(body)) between 3 and 1000),
  image_url text check (image_url is null or (char_length(image_url) <= 1000 and image_url ~ '^https?://')),
  status text not null default 'pending' check (status in ('pending','published','rejected')),
  created_at timestamptz not null default now()
);
alter table public.student_bulletin add column if not exists image_url text;
do $$ begin
  if not exists (select 1 from pg_constraint where conname='student_bulletin_image_url_check' and conrelid='public.student_bulletin'::regclass) then
    alter table public.student_bulletin add constraint student_bulletin_image_url_check check (image_url is null or (char_length(image_url) <= 1000 and image_url ~ '^https?://'));
  end if;
end $$;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text,
  login_email text,
  created_at timestamptz not null default now()
);
alter table public.admin_users add column if not exists username text;
alter table public.admin_users add column if not exists login_email text;
create unique index if not exists admin_users_username_unique on public.admin_users (lower(username)) where username is not null;
alter table public.admin_users enable row level security;
revoke all on public.admin_users from anon, authenticated;
grant select on public.admin_users to authenticated;
drop policy if exists "Admins can read own role" on public.admin_users;
create policy "Admins can read own role" on public.admin_users for select to authenticated using (user_id = (select auth.uid()));

create or replace function public.is_site_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.admin_users where user_id = (select auth.uid())); $$;
revoke all on function public.is_site_admin() from public;
grant execute on function public.is_site_admin() to authenticated;

-- Login is handled by the admin-login Edge Function. It checks username/password
-- in public.key, then creates a Supabase Auth session for the linked admin.
revoke all on table public.key from anon, authenticated;
drop function if exists public.admin_login_identity(text);
drop function if exists public.check_test_credentials(text, text);
notify pgrst, 'reload schema';

create table if not exists public.ride_offers (
  id uuid primary key default gen_random_uuid(),
  owner_name text not null default 'Student organizer' check (char_length(btrim(owner_name)) between 2 and 60),
  location text not null check (char_length(btrim(location)) between 2 and 100),
  destination text not null check (char_length(btrim(destination)) between 2 and 100),
  vehicle text not null check (char_length(btrim(vehicle)) between 2 and 40),
  capacity integer not null check (capacity between 1 and 30),
  created_at timestamptz not null default now()
);
alter table public.ride_offers add column if not exists owner_name text not null default 'Student organizer';

create table if not exists public.ride_passengers (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid not null references public.ride_offers(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 2 and 60),
  is_waitlisted boolean not null default false,
  manage_token_hash text,
  created_at timestamptz not null default now()
);
alter table public.ride_passengers add column if not exists is_waitlisted boolean not null default false;
alter table public.ride_passengers add column if not exists manage_token_hash text;
create unique index if not exists ride_passengers_unique_name
  on public.ride_passengers (ride_id, lower(btrim(name)));

create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_slug text not null check (char_length(btrim(restaurant_slug)) between 2 and 80),
  name text not null check (char_length(btrim(name)) between 2 and 100),
  price_yen integer not null check (price_yen between 0 and 100000),
  ingredients text not null default '' check (char_length(ingredients) <= 1000),
  halal_status text not null default 'unconfirmed' check (halal_status in ('unconfirmed', 'asked', 'confirmed')),
  image_url text,
  created_at timestamptz not null default now()
);
alter table public.menu_items add column if not exists name_romaji text not null default '';
alter table public.menu_items add column if not exists name_japanese text not null default '';
-- Allow additional community-listed restaurant and konbini keys if this script is rerun.
alter table public.menu_items drop constraint if exists menu_items_restaurant_slug_check;
alter table public.menu_items add constraint menu_items_restaurant_slug_check
  check (char_length(btrim(restaurant_slug)) between 2 and 80);

insert into public.restaurants (slug,region_slug,region_name,area_slug,area_name,name,category,description,map_url,image_url,image_source_url) values
  ('mos-burger-kofu','yamanashi','Yamanashi','kofu','Kofu','MOS Burger','Burger restaurant','Student recommendation · menu details can be added by the community.','https://www.google.com/maps/search/?api=1&query=MOS+Burger+Kofu+Ekimae','https://dynamic-media-cdn.tripadvisor.com/media/photo-o/11/63/0a/4c/photo0jpg.jpg?h=1200&s=1&w=1200',null),
  ('saizeriya-kofu','yamanashi','Yamanashi','kofu','Kofu','Saizeriya Kofu','Fast food restaurant','Kofu branch · add menu information from current branch labels.','https://www.google.com/maps/search/?api=1&query=Saizeriya+Kofu+Yamanashi','https://ximg.retty.me/crop/s400x400/q80/dal/-/retty/img_repo/2l/01/26623191.jpg',null),
  ('lawson','konbini','Konbini','konbini','Konbini','Lawson','Konbini','Nationwide chain · check current product labels at your local branch.','https://www.google.com/maps/search/?api=1&query=Lawson+convenience+store+Japan','https://commons.wikimedia.org/wiki/Special:FilePath/Japan_LAWSON_2026.jpg?width=1200','https://commons.wikimedia.org/wiki/File:Japan_LAWSON_2026.jpg'),
  ('seven-eleven','konbini','Konbini','konbini','Konbini','7-Eleven','Konbini','Nationwide chain · check current product labels at your local branch.','https://www.google.com/maps/search/?api=1&query=7-Eleven+convenience+store+Japan','https://commons.wikimedia.org/wiki/Special:FilePath/7-Eleven_Oita-Matsubaramachi-Store.jpg?width=1200','https://commons.wikimedia.org/wiki/File:7-Eleven_Oita-Matsubaramachi-Store.jpg')
on conflict (slug) do update set region_slug=excluded.region_slug,region_name=excluded.region_name,area_slug=excluded.area_slug,area_name=excluded.area_name,name=excluded.name,category=excluded.category,description=excluded.description,map_url=excluded.map_url,image_url=coalesce(public.restaurants.image_url,excluded.image_url),image_source_url=coalesce(public.restaurants.image_source_url,excluded.image_source_url);

-- Preserve menu entries from earlier versions by creating a generic directory record for their keys.
insert into public.restaurants (slug,area_slug,area_name,name,category,description)
select distinct mi.restaurant_slug,'other','Other areas',mi.restaurant_slug,'Restaurant','Existing community menu entry.'
from public.menu_items mi left join public.restaurants r on r.slug=mi.restaurant_slug
where r.slug is null
on conflict (slug) do nothing;

alter table public.menu_items drop constraint if exists menu_items_restaurant_slug_fkey;
alter table public.menu_items add constraint menu_items_restaurant_slug_fkey
  foreign key (restaurant_slug) references public.restaurants(slug) on update cascade on delete cascade;

insert into public.menu_items (restaurant_slug,name,name_romaji,name_japanese,price_yen,ingredients,halal_status)
select r.slug, m.name, m.romaji, m.japanese, 0, 'Listed as a halal menu recommendation by the student community. Check the current package label at the branch.', 'confirmed'
from public.restaurants r
cross join (values ('Onigiri','Onigiri','おにぎり'),('Fried fish','Furai fish','フライドフィッシュ')) as m(name,romaji,japanese)
where r.slug in ('lawson','seven-eleven')
  and not exists (select 1 from public.menu_items old where old.restaurant_slug=r.slug and lower(old.name)=lower(m.name));

insert into public.menu_items (restaurant_slug,name,name_romaji,name_japanese,price_yen,ingredients,halal_status)
select 'mos-burger-kofu','Fish burger','Fish burger','フィッシュバーガー',0,'Student recommendation. Add the current branch price and ingredients after confirming the exact item.','unconfirmed'
where not exists (select 1 from public.menu_items where restaurant_slug='mos-burger-kofu' and lower(name)='fish burger');
update public.menu_items set name_romaji='Onigiri',name_japanese='おにぎり' where lower(name)='onigiri' and restaurant_slug in ('lawson','seven-eleven') and (name_romaji='' or name_japanese='');
update public.menu_items set name_romaji='Furai fish',name_japanese='フライドフィッシュ' where lower(name)='fried fish' and restaurant_slug in ('lawson','seven-eleven') and (name_romaji='' or name_japanese='');
update public.menu_items set name_romaji='Fish burger',name_japanese='フィッシュバーガー' where restaurant_slug='mos-burger-kofu' and lower(name)='fish burger' and (name_romaji='' or name_japanese='');

insert into public.mosque_places (slug,area_name,name,description,map_url,image_url) values
  ('kofu-mosque','Kofu, Yamanashi','Kofu Mosque','Local prayer space and community contact. Confirm visiting details and prayer schedule before travel.','https://www.google.com/maps/search/?api=1&query=Kofu+Mosque+Yamanashi','https://commons.wikimedia.org/wiki/Special:FilePath/Kofu_Masjid.JPG')
on conflict (slug) do nothing;

insert into public.community_info (key,title,body,student_count) values
  ('students','Student voices at Yamanashi','Share campus notes, helpful tips, and opt-in student introductions. Contributions appear after admin review.','Student voices')
on conflict (key) do nothing;
update public.community_info set title='Student voices at Yamanashi' where key='students' and title='Students at the University of Yamanashi';
update public.community_info set body='Share campus notes, helpful tips, and opt-in student introductions. Contributions appear after admin review.' where key='students' and body='Share opt-in community information and practical guidance. Never publish personal details without permission.';
update public.community_info set student_count='Student voices' where key='students' and student_count='To be updated';

alter table public.community_events enable row level security;
alter table public.community_posts enable row level security;
alter table public.ride_offers enable row level security;
alter table public.ride_passengers enable row level security;
alter table public.menu_items enable row level security;
alter table public.restaurants enable row level security;
alter table public.food_areas enable row level security;
alter table public.mosque_places enable row level security;
alter table public.community_info enable row level security;
alter table public.site_media enable row level security;
alter table public.student_bulletin enable row level security;
alter table public.featured_video enable row level security;

revoke all on public.community_events, public.community_posts, public.ride_offers, public.ride_passengers, public.menu_items, public.restaurants, public.food_areas, public.mosque_places, public.community_info, public.site_media, public.student_bulletin, public.featured_video from anon, authenticated;
grant select on public.community_events, public.community_posts, public.menu_items to anon, authenticated;
grant select on public.featured_video to anon, authenticated;
grant select, insert on public.ride_offers to anon, authenticated;
grant select, insert, update, delete on public.ride_offers to authenticated;
grant select (id, ride_id, name, is_waitlisted, created_at) on public.ride_passengers to anon, authenticated;
grant insert, update, delete on public.ride_passengers to authenticated;
grant select on public.restaurants, public.food_areas, public.mosque_places, public.community_info, public.site_media to anon, authenticated;
grant select, insert on public.student_bulletin to anon, authenticated;
grant update, delete on public.student_bulletin to authenticated;
grant insert, update, delete on public.community_events, public.community_posts, public.menu_items, public.restaurants, public.food_areas, public.mosque_places, public.community_info to authenticated;
grant insert, update, delete on public.site_media to authenticated;
grant insert, update, delete on public.featured_video to authenticated;

drop policy if exists "Public read community events" on public.community_events;
create policy "Public read community events" on public.community_events for select to anon, authenticated using (true);
drop policy if exists "Visitors may add community events" on public.community_events;
drop policy if exists "Site admins manage community events" on public.community_events;
create policy "Site admins manage community events" on public.community_events for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop policy if exists "Public read community posts" on public.community_posts;
create policy "Public read community posts" on public.community_posts for select to anon, authenticated using (true);
drop policy if exists "Visitors may publish community posts" on public.community_posts;
drop policy if exists "Site admins manage community posts" on public.community_posts;
create policy "Site admins manage community posts" on public.community_posts for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop policy if exists "Public read site media" on public.site_media;
create policy "Public read site media" on public.site_media for select to anon, authenticated using (true);
drop policy if exists "Site admins manage site media" on public.site_media;
create policy "Site admins manage site media" on public.site_media for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop policy if exists "Public read featured video" on public.featured_video;
create policy "Public read featured video" on public.featured_video for select to anon, authenticated using (true);
drop policy if exists "Site admins manage featured video" on public.featured_video;
create policy "Site admins manage featured video" on public.featured_video for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop policy if exists "Public read ride offers" on public.ride_offers;
create policy "Public read ride offers" on public.ride_offers for select to anon, authenticated using (true);
drop policy if exists "Visitors may offer rides" on public.ride_offers;
create policy "Visitors may offer rides" on public.ride_offers for insert to anon, authenticated with check (true);
drop policy if exists "Site admins manage ride offers" on public.ride_offers;
create policy "Site admins manage ride offers" on public.ride_offers for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop policy if exists "Public read ride passengers" on public.ride_passengers;
create policy "Public read ride passengers" on public.ride_passengers for select to anon, authenticated using (true);
drop policy if exists "Site admins manage ride passengers" on public.ride_passengers;
create policy "Site admins manage ride passengers" on public.ride_passengers for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop policy if exists "Public read menu items" on public.menu_items;
create policy "Public read menu items" on public.menu_items for select to anon, authenticated using (true);
drop policy if exists "Visitors may add menu items" on public.menu_items;
drop policy if exists "Site admins manage menu items" on public.menu_items;
create policy "Site admins manage menu items" on public.menu_items for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop policy if exists "Public read restaurants" on public.restaurants;
create policy "Public read restaurants" on public.restaurants for select to anon, authenticated using (true);
drop policy if exists "Site admins manage restaurants" on public.restaurants;
create policy "Site admins manage restaurants" on public.restaurants for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop policy if exists "Public read food areas" on public.food_areas;
create policy "Public read food areas" on public.food_areas for select to anon, authenticated using (true);
drop policy if exists "Site admins manage food areas" on public.food_areas;
create policy "Site admins manage food areas" on public.food_areas for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop policy if exists "Public read mosque places" on public.mosque_places;
create policy "Public read mosque places" on public.mosque_places for select to anon, authenticated using (true);
drop policy if exists "Site admins manage mosque places" on public.mosque_places;
create policy "Site admins manage mosque places" on public.mosque_places for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop policy if exists "Public read community info" on public.community_info;
create policy "Public read community info" on public.community_info for select to anon, authenticated using (true);
drop policy if exists "Site admins manage community info" on public.community_info;
create policy "Site admins manage community info" on public.community_info for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop policy if exists "Public read published student bulletin" on public.student_bulletin;
create policy "Public read published student bulletin" on public.student_bulletin for select to anon, authenticated using (status = 'published');
drop policy if exists "Admins read all student bulletin entries" on public.student_bulletin;
create policy "Admins read all student bulletin entries" on public.student_bulletin for select to authenticated using (public.is_site_admin());
drop policy if exists "Visitors submit pending student bulletin entries" on public.student_bulletin;
create policy "Visitors submit pending student bulletin entries" on public.student_bulletin for insert to anon, authenticated with check (status = 'pending');
drop policy if exists "Site admins manage student bulletin entries" on public.student_bulletin;
create policy "Site admins manage student bulletin entries" on public.student_bulletin for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop function if exists public.join_ride(uuid, text);
create function public.join_ride(p_ride_id uuid, p_name text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_capacity integer;
  v_count integer;
  v_passenger_id uuid;
  v_manage_token text := encode(extensions.gen_random_bytes(32), 'hex');
begin
  if p_name is null or char_length(btrim(p_name)) not between 2 and 60 then
    return jsonb_build_object('status','invalid_name');
  end if;

  select capacity into v_capacity
  from public.ride_offers
  where id = p_ride_id
  for update;

  if not found then return jsonb_build_object('status','not_found'); end if;

  if exists (
    select 1 from public.ride_passengers
    where ride_id = p_ride_id and lower(btrim(name)) = lower(btrim(p_name))
  ) then return jsonb_build_object('status','duplicate'); end if;

  select count(*) into v_count from public.ride_passengers where ride_id = p_ride_id and not is_waitlisted;
  if v_count >= v_capacity then
    return jsonb_build_object('status','full');
  end if;
  insert into public.ride_passengers (ride_id, name, is_waitlisted, manage_token_hash)
  values (p_ride_id, btrim(p_name), false, encode(extensions.digest(v_manage_token, 'sha256'), 'hex'))
  returning id into v_passenger_id;
  return jsonb_build_object('status','joined','id',v_passenger_id,'token',v_manage_token);
end;
$$;
revoke all on function public.join_ride(uuid, text) from public;
grant execute on function public.join_ride(uuid, text) to anon, authenticated;

create or replace function public.update_ride_passenger(p_passenger_id uuid, p_manage_token text, p_name text)
returns text language plpgsql security definer set search_path = '' as $$
begin
  if p_name is null or char_length(btrim(p_name)) not between 2 and 60 then return 'invalid_name'; end if;
  update public.ride_passengers set name = btrim(p_name)
  where id = p_passenger_id and manage_token_hash = encode(extensions.digest(p_manage_token, 'sha256'), 'hex');
  if found then return 'updated'; end if;
  if exists(select 1 from public.ride_passengers where id=p_passenger_id) then return 'not_owner'; end if;
  return 'not_found';
exception when unique_violation then return 'duplicate';
end;
$$;
revoke all on function public.update_ride_passenger(uuid,text,text) from public;
grant execute on function public.update_ride_passenger(uuid,text,text) to anon, authenticated;

create or replace function public.remove_ride_passenger(p_passenger_id uuid, p_manage_token text)
returns text language plpgsql security definer set search_path = '' as $$
begin
  delete from public.ride_passengers
  where id = p_passenger_id and manage_token_hash = encode(extensions.digest(p_manage_token, 'sha256'), 'hex');
  if found then return 'removed'; end if;
  if exists(select 1 from public.ride_passengers where id=p_passenger_id) then return 'not_owner'; end if;
  return 'not_found';
end;
$$;
revoke all on function public.remove_ride_passenger(uuid,text) from public;
grant execute on function public.remove_ride_passenger(uuid,text) to anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('community-images', 'community-images', true, 4194304, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 4194304,
  allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "Visitors may upload community images" on storage.objects;
drop policy if exists "Site admins may upload community images" on storage.objects;
create policy "Site admins may upload community images" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'community-images' and public.is_site_admin());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('community-videos', 'community-videos', true, 52428800, array['video/mp4','video/webm'])
on conflict (id) do update set public = true, file_size_limit = 52428800,
  allowed_mime_types = array['video/mp4','video/webm'];

drop policy if exists "Site admins may upload community videos" on storage.objects;
create policy "Site admins may upload community videos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'community-videos' and public.is_site_admin());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('student-submissions', 'student-submissions', true, 3145728, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 3145728,
  allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "Visitors may upload student bulletin photos" on storage.objects;
create policy "Visitors may upload student bulletin photos" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'student-submissions' and name like 'submissions/%');

-- Enable Supabase Realtime for the shared boards, without duplicate publication entries.
do $$
declare
  t text;
begin
  foreach t in array array['community_events','community_posts','featured_video','site_media','ride_offers','ride_passengers','menu_items','restaurants','mosque_places','community_info','student_bulletin'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end;
$$;


-- Student proposed activities and public marketplace
create table if not exists public.student_activities (
  id uuid primary key default gen_random_uuid(),
  organizer_name text not null default 'Student organizer' check (char_length(btrim(organizer_name)) between 2 and 60),
  category text not null check (category in ('social','food','hiking','sports','study','other')),
  event_date date not null,
  title text not null check (char_length(btrim(title)) between 3 and 100),
  location text not null check (char_length(btrim(location)) between 2 and 100),
  description text not null default '' check (char_length(description) <= 1000),
  image_url text check (image_url is null or (char_length(image_url) <= 1000 and image_url ~ '^https?://')),
  status text not null default 'pending' check (status in ('pending','published','rejected')),
  created_at timestamptz not null default now()
);
alter table public.student_activities add column if not exists image_url text;
alter table public.student_activities alter column organizer_name set default 'Student organizer';
alter table public.student_activities alter column location set default 'Details to be shared';
create table if not exists public.activity_signups (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.student_activities(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 2 and 60),
  manage_token_hash text not null,
  created_at timestamptz not null default now(),
  unique (activity_id, name)
);
create unique index if not exists activity_signups_unique_name on public.activity_signups (activity_id, lower(btrim(name)));
create table if not exists public.marketplace_posts (
  id uuid primary key default gen_random_uuid(),
  seller_name text not null check (char_length(btrim(seller_name)) between 2 and 60),
  business_type text not null check (char_length(btrim(business_type)) between 2 and 80),
  title text not null check (char_length(btrim(title)) between 3 and 100),
  body text not null check (char_length(btrim(body)) between 3 and 1000),
  business_url text check (business_url is null or (char_length(business_url) <= 1000 and business_url ~ '^https://')),
  media_url text check (media_url is null or (char_length(media_url) <= 1000 and media_url ~ '^https://')),
  media_type text check (media_type is null or media_type in ('image','video')),
  manage_token_hash text,
  status text not null default 'pending' check (status in ('pending','published','rejected')),
  created_at timestamptz not null default now()
);
alter table public.marketplace_posts add column if not exists manage_token_hash text;
alter table public.student_activities enable row level security;
alter table public.activity_signups enable row level security;
alter table public.marketplace_posts enable row level security;
revoke all on public.student_activities, public.activity_signups, public.marketplace_posts from anon, authenticated;
grant select on public.student_activities, public.activity_signups, public.marketplace_posts to anon, authenticated;
grant insert on public.student_activities to anon, authenticated;
revoke insert on public.marketplace_posts from anon, authenticated;
grant update, delete on public.student_activities, public.activity_signups, public.marketplace_posts to authenticated;
drop policy if exists "Public read approved activities" on public.student_activities;
create policy "Public read approved activities" on public.student_activities for select to anon, authenticated using (status='published');
drop policy if exists "Admins read all activities" on public.student_activities;
create policy "Admins read all activities" on public.student_activities for select to authenticated using (public.is_site_admin());
drop policy if exists "Visitors suggest activities for review" on public.student_activities;
create policy "Visitors suggest activities for review" on public.student_activities for insert to anon, authenticated with check (status='pending');
drop policy if exists "Admins manage activities" on public.student_activities;
create policy "Admins manage activities" on public.student_activities for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());
drop policy if exists "Public read names on published activities" on public.activity_signups;
create policy "Public read names on published activities" on public.activity_signups for select to anon, authenticated using (exists(select 1 from public.student_activities a where a.id=activity_id and a.status='published'));
drop policy if exists "Admins read all activity signups" on public.activity_signups;
create policy "Admins read all activity signups" on public.activity_signups for select to authenticated using (public.is_site_admin());
drop policy if exists "Public read approved marketplace posts" on public.marketplace_posts;
create policy "Public read approved marketplace posts" on public.marketplace_posts for select to anon, authenticated using (status='published');
drop policy if exists "Admins read all marketplace posts" on public.marketplace_posts;
create policy "Admins read all marketplace posts" on public.marketplace_posts for select to authenticated using (public.is_site_admin());
drop policy if exists "Visitors submit marketplace posts for review" on public.marketplace_posts;
drop policy if exists "Admins manage marketplace posts" on public.marketplace_posts;
create policy "Admins manage marketplace posts" on public.marketplace_posts for all to authenticated using (public.is_site_admin()) with check (public.is_site_admin());

drop function if exists public.join_activity(uuid,text);
create function public.join_activity(p_activity_id uuid,p_name text) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_signup_id uuid; v_token text:=encode(extensions.gen_random_bytes(32),'hex');
begin
 if p_name is null or char_length(btrim(p_name)) not between 2 and 60 then return jsonb_build_object('status','invalid_name'); end if;
 if not exists(select 1 from public.student_activities where id=p_activity_id and status='published') then return jsonb_build_object('status','not_found'); end if;
 insert into public.activity_signups(activity_id,name,manage_token_hash) values(p_activity_id,btrim(p_name),encode(extensions.digest(v_token,'sha256'),'hex')) returning id into v_signup_id;
 return jsonb_build_object('status','joined','id',v_signup_id,'token',v_token);
exception when unique_violation then return jsonb_build_object('status','duplicate');
end; $$;
revoke all on function public.join_activity(uuid,text) from public;
grant execute on function public.join_activity(uuid,text) to anon,authenticated;
create or replace function public.update_activity_signup(p_signup_id uuid,p_manage_token text,p_name text) returns text language plpgsql security definer set search_path='' as $$
begin
 if p_name is null or char_length(btrim(p_name)) not between 2 and 60 then return 'invalid_name'; end if;
 update public.activity_signups set name=btrim(p_name) where id=p_signup_id and manage_token_hash=encode(extensions.digest(p_manage_token,'sha256'),'hex');
 if found then return 'updated'; end if;
 if exists(select 1 from public.activity_signups where id=p_signup_id) then return 'not_owner'; end if; return 'not_found';
exception when unique_violation then return 'duplicate'; end; $$;
revoke all on function public.update_activity_signup(uuid,text,text) from public;
grant execute on function public.update_activity_signup(uuid,text,text) to anon,authenticated;
create or replace function public.remove_activity_signup(p_signup_id uuid,p_manage_token text) returns text language plpgsql security definer set search_path='' as $$
begin
 delete from public.activity_signups where id=p_signup_id and manage_token_hash=encode(extensions.digest(p_manage_token,'sha256'),'hex');
 if found then return 'removed'; end if; if exists(select 1 from public.activity_signups where id=p_signup_id) then return 'not_owner'; end if; return 'not_found';
end; $$;
revoke all on function public.remove_activity_signup(uuid,text) from public;
grant execute on function public.remove_activity_signup(uuid,text) to anon,authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('student-marketplace','student-marketplace',true,52428800,array['image/jpeg','image/png','image/webp','video/mp4','video/webm']) on conflict(id) do update set public=true,file_size_limit=52428800,allowed_mime_types=array['image/jpeg','image/png','image/webp','video/mp4','video/webm'];
drop policy if exists "Visitors upload student marketplace media" on storage.objects;
create policy "Visitors upload student marketplace media" on storage.objects for insert to anon,authenticated with check(bucket_id='student-marketplace' and name like 'marketplace/%');
drop policy if exists "Admins manage activity marketplace media" on storage.objects;
create policy "Admins manage activity marketplace media" on storage.objects for all to authenticated using(bucket_id='student-marketplace' and public.is_site_admin()) with check(bucket_id='student-marketplace' and public.is_site_admin());
do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='student_activities') then alter publication supabase_realtime add table public.student_activities; end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='activity_signups') then alter publication supabase_realtime add table public.activity_signups; end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='marketplace_posts') then alter publication supabase_realtime add table public.marketplace_posts; end if;
end $$;
notify pgrst,'reload schema';


-- Clearly labeled demo data for the Activities and Marketplace tabs.
-- Safe to rerun: the sample rows are inserted only once.
insert into public.student_activities (organizer_name,category,event_date,title,location,description,status)
select 'MY × Yamanashi demo','food',current_date + 14,'Demo BBQ meetup','Kofu Park (sample venue; confirm before meeting)','Sample activity only. This BBQ listing demonstrates the attendee sign-up and live count. Confirm the real date, venue and details before attending.','published'
where not exists (select 1 from public.student_activities where title='Demo BBQ meetup' and organizer_name='MY × Yamanashi demo');

insert into public.marketplace_posts (seller_name,business_type,title,body,business_url,media_url,media_type,status)
select 'Demo student business','Cakes & desserts','Demo: Malaysian student cake business','Sample listing only. Replace this text with real cake options, prices and order details before publishing a real business.',null,null,null,'published'
where not exists (select 1 from public.marketplace_posts where title='Demo: Malaysian student cake business' and seller_name='Demo student business');
notify pgrst,'reload schema';


-- Anonymous marketplace submissions receive a private edit token; they cannot delete posts.
drop function if exists public.submit_marketplace_post(text,text,text,text,text,text,text);
create function public.submit_marketplace_post(p_seller_name text,p_business_type text,p_title text,p_body text,p_business_url text,p_media_url text,p_media_type text) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_id uuid; v_token text:=encode(extensions.gen_random_bytes(32),'hex');
begin
 if p_seller_name is null or char_length(btrim(p_seller_name)) not between 2 and 60 then return jsonb_build_object('status','invalid_seller'); end if;
 insert into public.marketplace_posts(seller_name,business_type,title,body,business_url,media_url,media_type,manage_token_hash,status)
 values(btrim(p_seller_name),btrim(p_business_type),btrim(p_title),btrim(p_body),nullif(btrim(p_business_url),''),nullif(btrim(p_media_url),''),nullif(btrim(p_media_type),''),encode(extensions.digest(v_token,'sha256'),'hex'),'pending') returning id into v_id;
 return jsonb_build_object('status','submitted','id',v_id,'token',v_token);
end; $$;
revoke all on function public.submit_marketplace_post(text,text,text,text,text,text,text) from public;
grant execute on function public.submit_marketplace_post(text,text,text,text,text,text,text) to anon,authenticated;
create or replace function public.update_marketplace_post(p_post_id uuid,p_manage_token text,p_seller_name text,p_business_type text,p_title text,p_body text,p_business_url text,p_media_url text,p_media_type text) returns text language plpgsql security definer set search_path='' as $$
begin
 if p_seller_name is null or char_length(btrim(p_seller_name)) not between 2 and 60 then return 'invalid_seller'; end if;
 update public.marketplace_posts set seller_name=btrim(p_seller_name),business_type=btrim(p_business_type),title=btrim(p_title),body=btrim(p_body),business_url=nullif(btrim(p_business_url),''),media_url=nullif(btrim(p_media_url),''),media_type=nullif(btrim(p_media_type),''),status='pending'
 where id=p_post_id and manage_token_hash=encode(extensions.digest(p_manage_token,'sha256'),'hex');
 if found then return 'updated'; end if;
 if exists(select 1 from public.marketplace_posts where id=p_post_id) then return 'not_owner'; end if; return 'not_found';
end; $$;
revoke all on function public.update_marketplace_post(uuid,text,text,text,text,text,text,text,text) from public;
grant execute on function public.update_marketplace_post(uuid,text,text,text,text,text,text,text,text) to anon,authenticated;
notify pgrst,'reload schema';
