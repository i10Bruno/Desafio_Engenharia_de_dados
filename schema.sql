CREATE TABLE "customers" (
    "id" INTEGER PRIMARY KEY,
    "person_type" TEXT,
    "legal_name" TEXT,
    "trade_name" TEXT,
    "tax_id" TEXT,
    "state_registration" TEXT,
    "email" TEXT,
    "phone" TEXT,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

CREATE TABLE "addresses" (
    "id" INTEGER PRIMARY KEY,
    "customer_id" INTEGER,
    "address_type" TEXT,
    "postal_code" TEXT,
    "street" TEXT,
    "number" INTEGER,
    "complement" TEXT,
    "district" TEXT,
    "city" TEXT,
    "state" TEXT,
    "country" TEXT,
    "is_primary" BOOLEAN,
    FOREIGN KEY ("customer_id") REFERENCES "customers"("id")
);

CREATE TABLE "attributes" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT,
    "data_type" TEXT
);

CREATE TABLE "brands" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT,
    "country" TEXT,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

CREATE TABLE "categories" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT,
    "slug" TEXT,
    "parent_category_id" INTEGER,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP,
    FOREIGN KEY ("parent_category_id") REFERENCES "categories"("id")
);

CREATE TABLE "locations" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT,
    "location_type" TEXT,
    "postal_code" TEXT,
    "street" TEXT,
    "number" INTEGER,
    "complement" TEXT,
    "district" TEXT,
    "city" TEXT,
    "state" TEXT,
    "country" TEXT,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

CREATE TABLE "employees" (
    "id" INTEGER PRIMARY KEY,
    "full_name" TEXT,
    "cpf" TEXT,
    "email" TEXT,
    "role" TEXT,
    "primary_location_id" INTEGER,
    "hire_date" DATE,
    "termination_date" DATE,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP,
    FOREIGN KEY ("primary_location_id") REFERENCES "locations"("id")
);

CREATE TABLE "orders" (
    "id" INTEGER PRIMARY KEY,
    "order_number" TEXT,
    "channel" TEXT,
    "customer_id" INTEGER,
    "salesperson_id" INTEGER,
    "location_id" INTEGER,
    "status" TEXT,
    "subtotal" NUMERIC,
    "discount_amount" NUMERIC,
    "total" NUMERIC,
    "placed_at" TIMESTAMP,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP,
    FOREIGN KEY ("customer_id") REFERENCES "customers"("id"),
    FOREIGN KEY ("salesperson_id") REFERENCES "employees"("id"),
    FOREIGN KEY ("location_id") REFERENCES "locations"("id")
);

CREATE TABLE "fiscal_invoices" (
    "id" INTEGER PRIMARY KEY,
    "order_id" INTEGER,
    "nfe_number" TEXT,
    "nfe_access_key" TEXT,
    "series" TEXT,
    "issued_at" TIMESTAMP,
    "status" TEXT,
    "total_amount" NUMERIC,
    "xml_storage_uri" TEXT,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP,
    FOREIGN KEY ("order_id") REFERENCES "orders"("id")
);

CREATE TABLE "suppliers" (
    "id" INTEGER PRIMARY KEY,
    "legal_name" TEXT,
    "trade_name" TEXT,
    "country" TEXT,
    "tax_id" TEXT,
    "tax_id_type" TEXT,
    "email" TEXT,
    "phone" TEXT,
    "contact_name" TEXT,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP
);

CREATE TABLE "purchase_orders" (
    "id" INTEGER PRIMARY KEY,
    "po_number" TEXT,
    "supplier_id" INTEGER,
    "buyer_id" INTEGER,
    "destination_location_id" INTEGER,
    "status" TEXT,
    "currency" TEXT,
    "subtotal" NUMERIC,
    "total" NUMERIC,
    "placed_at" TIMESTAMP,
    "expected_delivery_at" TIMESTAMP,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP,
    FOREIGN KEY ("supplier_id") REFERENCES "suppliers"("id"),
    FOREIGN KEY ("buyer_id") REFERENCES "employees"("id"),
    FOREIGN KEY ("destination_location_id") REFERENCES "locations"("id")
);

CREATE TABLE "goods_receipts" (
    "id" INTEGER PRIMARY KEY,
    "purchase_order_id" INTEGER,
    "received_by_employee_id" INTEGER,
    "received_at" TIMESTAMP,
    "notes" TEXT,
    "created_at" TIMESTAMP,
    FOREIGN KEY ("purchase_order_id") REFERENCES "purchase_orders"("id"),
    FOREIGN KEY ("received_by_employee_id") REFERENCES "employees"("id")
);

CREATE TABLE "products" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT,
    "description" TEXT,
    "brand_id" INTEGER,
    "category_id" INTEGER,
    "ncm_code" TEXT,
    "unit_of_measure" TEXT,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP,
    FOREIGN KEY ("brand_id") REFERENCES "brands"("id"),
    FOREIGN KEY ("category_id") REFERENCES "categories"("id")
);

CREATE TABLE "product_variants" (
    "id" INTEGER PRIMARY KEY,
    "product_id" INTEGER,
    "sku" TEXT,
    "barcode_ean" TEXT,
    "sale_price" NUMERIC,
    "cost_price" NUMERIC,
    "weight_kg" NUMERIC,
    "icms_rate" NUMERIC,
    "ipi_rate" NUMERIC,
    "is_active" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP,
    FOREIGN KEY ("product_id") REFERENCES "products"("id")
);

CREATE TABLE "purchase_order_items" (
    "id" INTEGER PRIMARY KEY,
    "purchase_order_id" INTEGER,
    "product_variant_id" INTEGER,
    "quantity_ordered" INTEGER,
    "unit_cost" NUMERIC,
    "line_total" NUMERIC,
    FOREIGN KEY ("purchase_order_id") REFERENCES "purchase_orders"("id"),
    FOREIGN KEY ("product_variant_id") REFERENCES "product_variants"("id")
);

CREATE TABLE "goods_receipt_items" (
    "id" INTEGER PRIMARY KEY,
    "goods_receipt_id" INTEGER,
    "purchase_order_item_id" INTEGER,
    "quantity_received" NUMERIC,
    FOREIGN KEY ("goods_receipt_id") REFERENCES "goods_receipts"("id"),
    FOREIGN KEY ("purchase_order_item_id") REFERENCES "purchase_order_items"("id")
);

CREATE TABLE "order_items" (
    "id" INTEGER PRIMARY KEY,
    "order_id" INTEGER,
    "product_variant_id" INTEGER,
    "quantity" INTEGER,
    "unit_price" NUMERIC,
    "icms_rate" NUMERIC,
    "ipi_rate" NUMERIC,
    "line_total" NUMERIC,
    FOREIGN KEY ("order_id") REFERENCES "orders"("id"),
    FOREIGN KEY ("product_variant_id") REFERENCES "product_variants"("id")
);

CREATE TABLE "payments" (
    "id" INTEGER PRIMARY KEY,
    "order_id" INTEGER,
    "method" TEXT,
    "installments" INTEGER,
    "amount" NUMERIC,
    "status" TEXT,
    "paid_at" TIMESTAMP,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP,
    FOREIGN KEY ("order_id") REFERENCES "orders"("id")
);

CREATE TABLE "product_suppliers" (
    "product_variant_id" INTEGER,
    "supplier_id" INTEGER,
    "supplier_sku" TEXT,
    "last_quoted_cost" NUMERIC,
    "lead_time_days" INTEGER,
    "is_preferred" BOOLEAN,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP,
    PRIMARY KEY ("product_variant_id", "supplier_id"),
    FOREIGN KEY ("product_variant_id") REFERENCES "product_variants"("id"),
    FOREIGN KEY ("supplier_id") REFERENCES "suppliers"("id")
);

CREATE TABLE "returns" (
    "id" INTEGER PRIMARY KEY,
    "return_number" TEXT,
    "order_id" INTEGER,
    "customer_id" INTEGER,
    "received_at_location_id" INTEGER,
    "status" TEXT,
    "reason" TEXT,
    "total_refund_amount" NUMERIC,
    "created_at" TIMESTAMP,
    "updated_at" TIMESTAMP,
    FOREIGN KEY ("order_id") REFERENCES "orders"("id"),
    FOREIGN KEY ("customer_id") REFERENCES "customers"("id"),
    FOREIGN KEY ("received_at_location_id") REFERENCES "locations"("id")
);

CREATE TABLE "return_items" (
    "id" INTEGER PRIMARY KEY,
    "return_id" INTEGER,
    "order_item_id" INTEGER,
    "quantity" NUMERIC,
    "action" TEXT,
    "exchange_variant_id" INTEGER,
    "unit_refund_amount" NUMERIC,
    FOREIGN KEY ("return_id") REFERENCES "returns"("id"),
    FOREIGN KEY ("order_item_id") REFERENCES "order_items"("id"),
    FOREIGN KEY ("exchange_variant_id") REFERENCES "product_variants"("id")
);

CREATE TABLE "stock_levels" (
    "product_variant_id" INTEGER,
    "location_id" INTEGER,
    "quantity_on_hand" NUMERIC,
    "reorder_point" TEXT,
    "updated_at" TIMESTAMP,
    PRIMARY KEY ("product_variant_id", "location_id"),
    FOREIGN KEY ("product_variant_id") REFERENCES "product_variants"("id"),
    FOREIGN KEY ("location_id") REFERENCES "locations"("id")
);

CREATE TABLE "stock_movements" (
    "id" INTEGER PRIMARY KEY,
    "product_variant_id" INTEGER,
    "location_id" INTEGER,
    "movement_type" TEXT,
    "quantity" NUMERIC,
    "reference_table" TEXT,
    "reference_id" TEXT,
    "employee_id" INTEGER,
    "notes" TEXT,
    "occurred_at" TIMESTAMP,
    "created_at" TIMESTAMP,
    FOREIGN KEY ("product_variant_id") REFERENCES "product_variants"("id"),
    FOREIGN KEY ("location_id") REFERENCES "locations"("id"),
    FOREIGN KEY ("employee_id") REFERENCES "employees"("id")
);

CREATE TABLE "variant_attribute_values" (
    "product_variant_id" INTEGER,
    "attribute_id" INTEGER,
    "value" TEXT,
    PRIMARY KEY ("product_variant_id", "attribute_id"),
    FOREIGN KEY ("product_variant_id") REFERENCES "product_variants"("id"),
    FOREIGN KEY ("attribute_id") REFERENCES "attributes"("id")
);

