# Stylish Admin

A Flutter + Supabase e-commerce app with a desktop-first admin panel and a customer-facing storefront.

This project includes:
- storefront browsing for products, categories, offers, cart, wishlist, and checkout
- admin management for dashboard, categories, products, orders, users, promotions, and audit logs
- Supabase integration for auth, database, and storage

## Highlights

### Storefront
- product catalog with categories and offers
- product details with sizes, reviews, and related items
- cart and checkout flow
- coupon validation
- wishlist support
- profile and settings

### Admin Panel
- live dashboard overview with real KPIs, alerts, recent orders, and business health
- category management:
  - create, edit, delete
  - visibility
  - sort order
  - image upload or URL fallback
- product management:
  - create, edit, delete
  - stock, status, featured, sale price
  - main image and gallery uploads
  - bulk actions
  - CSV/XLSX import and export
  - import audit before save
- order management:
  - list and search orders
  - date filters
  - payment and delivery filters
  - status updates
  - export to Excel
- user management:
  - profile editing
  - role updates
- promotions:
  - coupons
  - banners
  - offers
- audit log viewer for admin activity

## Tech Stack

- Flutter
- Dart
- Supabase
- flutter_bloc
- shared_preferences
- image_picker
- excel / csv / spreadsheet_decoder

## Project Structure

```text
lib/
  app/
  core/
    api/
    config/
    constants/
    navigation/
    services/
    utils/
  pages/
    admin/
      data/
      screens/
      widgets/
    auth/
    cart/
    home/
    product/
    settings/
  root.dart
  main.dart
```

## Getting Started

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Supabase

Update the Supabase project values in:

- [lib/core/config/supabase_options.dart](lib/core/config/supabase_options.dart)

Make sure your Supabase project is set up with the tables and storage buckets used by the app.

## Required Supabase Tables

The app expects these main tables:

- `profiles`
- `categories`
- `products`
- `offers`
- `orders`
- `order_items`
- `coupons`
- `banners`
- `admin_audit_logs`

Optional but supported:

- `cart_items`
- `wishlist_items`

## Required Storage Buckets

Recommended buckets:

- `categories`
- `products`
- `avatars`
- `promotions`

The app has a few safe fallbacks for older bucket names, but the buckets above are the clean setup.

## Admin Role

Only admin accounts can access the admin panel.

Your `profiles` table should include a `role` column, and admin users should have:

```text
role = 'admin'
```

Regular users should have:

```text
role = 'user'
```

## Running the App

### Web

```bash
flutter run -d chrome
```

### Android / Emulator

```bash
flutter run
```

## Testing

Static analysis:

```bash
flutter analyze
```

Widget tests:

```bash
flutter test
```

## Current Notes

- the dashboard uses live data from products, categories, users, orders, coupons, banners, and offers
- missing optional tables like `cart_items` and `wishlist_items` degrade more safely now
- storefront promotions can read from both `offers` and active `banners`
- order totals now correctly save discount amounts in checkout flows

## Recommended Next Improvements

- add deeper automated tests for checkout, admin CRUD, and dashboard loading
- add monthly charts for sales and orders
- add invoice / receipt generation
- add stronger audit logging on all admin mutations
- add end-to-end Supabase policy documentation

## License

Private project. Update this section if you want to publish or share it publicly.
