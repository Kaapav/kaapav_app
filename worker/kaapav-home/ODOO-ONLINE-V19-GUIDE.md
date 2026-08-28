# KAAPAV on Odoo Online v19

This is the Odoo Online implementation for the KAAPAV redesign. It uses Website Editor building blocks and native Odoo eCommerce routes, so it does not depend on `catalogue.kaapav.com` and does not require installing a custom module.

## Files

- `kaapav-odoo-v19-widget.html` — paste-ready homepage widget.
- `kaapav-odoo-v19-luxury-glass.html` — the full luxury-glass visual adaptation of `kaapav-real-redesign.html`, ready for one Odoo Embed Code block.
- `kaapav-real-redesign.html` — standalone visual reference/preview. Use this for design review; use the smaller widget for Odoo Online.

## Install the widget

1. Open the Odoo **Website** app and open the homepage. For a safe first pass, create a temporary page such as `/kaapav-preview` and test there.
2. Click **Edit**.
3. From **Inner Content**, drag **Embed Code** to the location where the KAAPAV hero should appear.
4. Select the block, open **Style**, choose **Edit**, remove the placeholder code, and paste the complete contents of `kaapav-odoo-v19-luxury-glass.html`.
5. Save, preview the page on desktop and mobile, then publish when the links and spacing are correct.

The code is deliberately wrapped in `#kpv-home`, so its CSS should not change Odoo's native header, cart, checkout, or footer.

## Keep commerce native

Do not rebuild cart, checkout, payment, login, or wishlist in the widget. Keep Odoo's native header and commerce blocks. The widget buttons already point to native routes:

- `/shop` — all products
- `/shop/category/...` — category pages
- `/shop/cart` — cart
- `/web/login` — login
- `/my/orders` — customer orders

After inserting the widget, add Odoo's native **Products** building block underneath it for the live product grid. Configure its category, number of products, sorting, image ratio, and price display in the block options. This keeps stock, price, variants, add-to-cart, and product URLs connected to Odoo.

## Connect categories and products

The widget category links use the current KAAPAV route slugs. If Odoo v19 generated different slugs in your database, open each category page, copy its URL, and replace the corresponding `href` in the widget.

To confirm categories:

1. Go to **Website → eCommerce → Products**.
2. Open a product and check **Sales → eCommerce shop → Categories**.
3. Assign the product to the right eCommerce category.
4. Verify the category page and the Products block on the homepage.

## Logo and imagery

The widget uses `/web/image/website/3/logo/KAAPAV`, matching the current KAAPAV website. If the logo does not appear in your database, change `3` to your website ID or use the Website Editor's image picker.

For the final art direction, upload the KAAPAV campaign image to the Odoo media library and use it in a separate image/banner block beside or above the widget. The current widget intentionally uses lightweight CSS art, so the page works immediately without external image hosting.

## Header and footer

Use Odoo's existing header for search, account, cart, and mobile navigation. Edit its colors and spacing through **Website → Edit → Theme/Style**. Keep one header only; do not paste a second navigation bar into the embed block.

Keep the existing KAAPAV footer and update its visible policy text there. Preserve the current business details, WhatsApp link, return policy, shipping policy, and SEO keyword links.

## Important Odoo Online limitation

Odoo Online is not the same as Odoo.sh or self-hosted Odoo. You should not try to install a local `__manifest__.py` custom website module into Odoo Online. For this implementation, use Website Editor blocks, native eCommerce blocks, theme settings, and scoped Embed Code.

Avoid placing important business logic or inventory synchronization inside an Embed Code block. Odoo must remain the source of truth for stock, prices, orders, payment, and returns.

Also avoid relying on custom JavaScript inside Embed Code. Odoo may sanitize or remove scripts during editing, and a CSS/HTML widget is more stable on Odoo Online. If a future feature genuinely needs JavaScript, first confirm that it can be added through your Odoo deployment's supported website asset mechanism.

## SEO checklist before publishing

- Keep one visible H1 on the homepage: “Jewellery that speaks to your soul.”
- Set the page title to something like `KAAPAV | Contemporary Fashion Jewellery for Women`.
- Add a concise meta description mentioning artificial/fashion jewellery, Indian shipping, and easy returns.
- Give every uploaded campaign/product image descriptive alt text.
- Keep category names as real links, not clickable text with no destination.
- Test canonical URLs, mobile layout, product pages, add-to-cart, checkout, payment, and the return-policy page.

## Rollback

Unpublish the preview page or remove the Embed Code block. The widget does not modify products, inventory, orders, or Odoo settings.
