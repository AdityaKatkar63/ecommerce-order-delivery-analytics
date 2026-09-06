-----------Create Database-----------

create database ecommerce_order_delivery_db1


------------Create All Dimension Tables----------------

-- 1.dim_region

create table dim_region(
      region_id SERIAL primary Key,
      country_name varchar(100) NOT NULL,
      state_name varchar(100) NOT NULL,
	  city_name varchar(100) NOT NULL,
	  region_zone varchar(50) NOT NULL,
	  pincode CHAR(6) NOT NULL
                CHECK (pincode ~ '^[0-9]{6}$')
	);



-- 2.dim_category

CREATE TABLE dim_category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL,
    parent_category VARCHAR(100)
);

--3.dim_product 

CREATE TABLE dim_product (
    product_id SERIAL PRIMARY KEY,
    sku_code VARCHAR(30) UNIQUE NOT NULL,
    product_name VARCHAR(150) NOT NULL,
    category_id INT NOT NULL,
    brand_name VARCHAR(100),
    list_price DECIMAL(10,2) NOT NULL,
    cost_price DECIMAL(10,2) NOT NULL,
    product_status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_product_category
	FOREIGN KEY (category_id)
        REFERENCES dim_category(category_id)
);

--4.dim_warehouse

CREATE TABLE dim_warehouse(
    warehouse_id SERIAL PRIMARY KEY,
	warehouse_code VARCHAR(20) UNIQUE NOT NULL,
	warehouse_name VARCHAR(70) NOT NULL,
	region_id INT NOT NULL,
	warehouse_type varchar(50) NOT NULL,
	storage_capacity_units INT NOT NULL,
    active_flag BOOLEAN DEFAULT TRUE,

    CONSTRAINT fk_warehouse_region
        FOREIGN KEY (region_id)
        REFERENCES dim_region(region_id)
);


--5.dim_customer
	
CREATE TABLE dim_customer (
    customer_id SERIAL PRIMARY KEY,
    customer_code VARCHAR(20) UNIQUE NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    gender VARCHAR(10),
    age_group VARCHAR(20),
    region_id INT NOT NULL,
    registration_date DATE,
    customer_segment VARCHAR(50),
    active_flag BOOLEAN DEFAULT TRUE,

    CONSTRAINT fk_customer_region
        FOREIGN KEY (region_id)
        REFERENCES dim_region(region_id)
);



--6.dim_seller

CREATE TABLE dim_seller (
    seller_id SERIAL PRIMARY KEY,
    seller_code VARCHAR(20) UNIQUE NOT NULL,
    seller_name VARCHAR(100) NOT NULL,
    seller_type VARCHAR(50) NOT NULL,
    region_id INT NOT NULL,
    onboarding_date DATE,
    seller_status VARCHAR(20) NOT NULL,

    CONSTRAINT fk_seller_region
        FOREIGN KEY (region_id)
        REFERENCES dim_region(region_id)
);


-- 7.dim_delivery_partner


CREATE TABLE dim_delivery_partner (
    delivery_partner_id SERIAL PRIMARY KEY,
    partner_code VARCHAR(20) UNIQUE NOT NULL,
    partner_name VARCHAR(100) NOT NULL,
    service_type VARCHAR(50) NOT NULL,
    coverage_zone VARCHAR(100) NOT NULL,
    active_flag BOOLEAN DEFAULT TRUE
);



-- 8.dim_calendar


CREATE TABLE dim_calendar (
    calendar_date DATE PRIMARY KEY,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month_no INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    week_no INT NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL
);


-------- View Tables Command (Change Table Name According Which table Want to See)-------

select * from dim_region


-------------------Create All Facts Tables------------------

-- 1.fact_orders


CREATE TABLE fact_orders (
    order_id SERIAL PRIMARY KEY,
    order_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_status VARCHAR(30) NOT NULL,
    order_channel VARCHAR(30) NOT NULL,
    total_order_amount DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0
                          CHECK (discount_amount >= 0),
    final_order_amount DECIMAL(10,2) NOT NULL,
    coupon_used_flag BOOLEAN DEFAULT FALSE,
    expected_delivery_date DATE NOT NULL,

    CONSTRAINT fk_order_customer
        FOREIGN KEY (customer_id)
        REFERENCES dim_customer(customer_id),

    CONSTRAINT fk_order_date
        FOREIGN KEY (order_date)
        REFERENCES dim_calendar(calendar_date),

    CONSTRAINT fk_expected_delivery_date
        FOREIGN KEY (expected_delivery_date)
        REFERENCES dim_calendar(calendar_date)
);
	

-- 2.fact_order_items



CREATE TABLE fact_order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    seller_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    item_discount DECIMAL(10,2) DEFAULT 0,
    item_total_amount DECIMAL(10,2) NOT NULL,

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES fact_orders(order_id),

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES dim_product(product_id),

    CONSTRAINT fk_order_items_seller
        FOREIGN KEY (seller_id)
        REFERENCES dim_seller(seller_id),

    CONSTRAINT fk_order_items_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES dim_warehouse(warehouse_id)
);


-- 3.fact_payments

CREATE TABLE fact_payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    payment_date DATE NOT NULL,
    payment_mode VARCHAR(30) NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR(30) NOT NULL,
    transaction_id VARCHAR(50) UNIQUE NOT NULL,

    CONSTRAINT fk_payment_order
        FOREIGN KEY (order_id)
        REFERENCES fact_orders(order_id),

    CONSTRAINT fk_payment_date
        FOREIGN KEY (payment_date)
        REFERENCES dim_calendar(calendar_date)
);


-- 4.fact_shipments

	
CREATE TABLE fact_shipments (
    shipment_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    delivery_partner_id INT NOT NULL,
    shipment_date DATE NOT NULL,
    estimated_delivery_date DATE NOT NULL,
    actual_delivery_date DATE,
    shipment_status VARCHAR(30) NOT NULL,
    shipping_cost DECIMAL(10,2) NOT NULL,

    CONSTRAINT fk_shipment_order
        FOREIGN KEY (order_id)
        REFERENCES fact_orders(order_id),

    CONSTRAINT fk_shipment_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES dim_warehouse(warehouse_id),

    CONSTRAINT fk_shipment_partner
        FOREIGN KEY (delivery_partner_id)
        REFERENCES dim_delivery_partner(delivery_partner_id),

    CONSTRAINT fk_shipment_date
        FOREIGN KEY (shipment_date)
        REFERENCES dim_calendar(calendar_date),

    CONSTRAINT fk_estimated_delivery_date
        FOREIGN KEY (estimated_delivery_date)
        REFERENCES dim_calendar(calendar_date),

    CONSTRAINT fk_actual_delivery_date
        FOREIGN KEY (actual_delivery_date)
        REFERENCES dim_calendar(calendar_date)
);



-- 5.fact_returns


CREATE TABLE fact_returns (
    return_id SERIAL PRIMARY KEY,
    order_item_id INT NOT NULL,
    return_date DATE NOT NULL,
    return_reason VARCHAR(100) NOT NULL,
    quantity_returned INT NOT NULL,
    refund_amount DECIMAL(10,2) NOT NULL,
    return_status VARCHAR(30) NOT NULL,

    CONSTRAINT fk_return_order_item
        FOREIGN KEY (order_item_id)
        REFERENCES fact_order_items(order_item_id),

    CONSTRAINT fk_return_date
        FOREIGN KEY (return_date)
        REFERENCES dim_calendar(calendar_date)
);




-- 6.fact_inventory_snapshot


CREATE TABLE fact_inventory_snapshot (
    inventory_snapshot_id SERIAL PRIMARY KEY,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    snapshot_date DATE NOT NULL,
    opening_stock INT NOT NULL,
    stock_received INT NOT NULL,
    stock_sold INT NOT NULL,
    closing_stock INT NOT NULL,
    stockout_flag BOOLEAN DEFAULT FALSE,

    CONSTRAINT fk_inventory_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES dim_warehouse(warehouse_id),

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES dim_product(product_id),

    CONSTRAINT fk_inventory_snapshot_date
        FOREIGN KEY (snapshot_date)
        REFERENCES dim_calendar(calendar_date)
);



-- 7.fact_seller_performance


CREATE TABLE fact_seller_performance (
    seller_performance_id SERIAL PRIMARY KEY,
    seller_id INT NOT NULL,
    calendar_date DATE NOT NULL,
    orders_count INT NOT NULL,
    units_sold INT NOT NULL,
    gross_sales_amount DECIMAL(10,2) NOT NULL,
    returns_count INT NOT NULL,
    net_sales_amount DECIMAL(10,2) NOT NULL,
    rating_average DECIMAL(3,2),

    CONSTRAINT fk_seller_performance_seller
        FOREIGN KEY (seller_id)
        REFERENCES dim_seller(seller_id),

    CONSTRAINT fk_seller_performance_date
        FOREIGN KEY (calendar_date)
        REFERENCES dim_calendar(calendar_date)
);



-- 8.fact_customer_reviews


CREATE TABLE fact_customer_reviews (
    review_id SERIAL PRIMARY KEY,
    order_item_id INT NOT NULL,
    customer_id INT NOT NULL,
    review_date DATE NOT NULL,
    rating DECIMAL(2,1) NOT NULL
    CHECK (rating BETWEEN 1.0 AND 5.0),
    review_comment TEXT,
    verified_purchase_flag BOOLEAN DEFAULT FALSE,

    CONSTRAINT fk_review_order_item
        FOREIGN KEY (order_item_id)
        REFERENCES fact_order_items(order_item_id),

    CONSTRAINT fk_review_customer
        FOREIGN KEY (customer_id)
        REFERENCES dim_customer(customer_id),

    CONSTRAINT fk_review_date
        FOREIGN KEY (review_date)
        REFERENCES dim_calendar(calendar_date)
);



























