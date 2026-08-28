# KAAPAV storefront implementation boundary

The three HTML files are visual storefront options. The catalogue site is not part of the customer journey.

## Customer-facing route contract

- Store: `/shop`
- Necklaces: `/shop/category/all-jewellery-necklace-19`
- Earrings: `/shop/category/all-jewellery-earrings-21`
- Bracelets: `/shop/category/all-jewellery-bracelets-13`
- Rings: `/shop/category/all-jewellery-rings-20`
- Bestsellers: `/shop/category/all-jewellery-12?category=12&search=&order=&tags=16`
- Product detail: use the product's Odoo `website_url` / `website_link`

## Odoo integration seam

The visual classes are intentionally independent of the product source:

- `.hero-product` / `.showcase` / `.product` are presentation components.
- `.grid` is the product collection container.
- `.card` is the product card.
- `.media`, `.body`, `.price`, and `.view` are stable card slots.

For a live Odoo QWeb theme, replace the small preview `fetch()` adapter with an Odoo loop:

```xml
<div class="grid">
  <t t-foreach="products" t-as="product">
    <a class="card glass"
       t-att-href="product.website_url"
       t-att-data-oe-model="'product.template'"
       t-att-data-oe-id="product.id">
      <div class="media">
        <img t-att-src="image_data_uri(product.image_1920)"
             t-att-alt="product.name" loading="lazy"/>
      </div>
      <div class="body">
        <small t-esc="product.public_categ_ids[:1].name"/>
        <h3 t-esc="product.name"/>
        <div class="row">
          <span class="price" t-esc="product.website_price"/>
          <span class="view">View &#8599;</span>
        </div>
      </div>
    </a>
  </t>
</div>
```

Keep Odoo's native commerce actions and routes for cart, checkout, wishlist, account, taxes, delivery, and payment. The design layer should not recreate those systems. The current preview uses the Kaapav worker only to show real products while choosing the visual direction; that adapter can be removed when the QWeb product loop is installed.

## Recommended Odoo structure

1. Put the selected option's CSS in the website theme asset bundle.
2. Convert the selected HTML sections into QWeb snippets/templates.
3. Bind the product grid and hero product to `product.template` data.
4. Keep the existing Odoo `/shop`, cart, checkout, payment, and customer routes.
5. Add the Kaapav logo as a theme asset instead of an external catalogue asset.
