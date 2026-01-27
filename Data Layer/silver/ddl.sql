-- ============================================================================
-- SILVER LAYER: TABLE BOOKING
-- Silver Layer - Cleaned and validated Uber ride data
-- ============================================================================

-- Create silver schema (if it doesn't exist)
CREATE SCHEMA IF NOT EXISTS silver;

-- Schema comment
COMMENT ON SCHEMA silver IS 'Silver Layer - Cleaned and validated data';

-- ============================================================================
-- TABLE: BOOKING
-- ============================================================================
DROP TABLE IF EXISTS silver.booking CASCADE;

CREATE TABLE silver.booking (
    id VARCHAR(50) PRIMARY KEY,
    date DATE,
    time TIME,
    status VARCHAR(50),
    customer_id VARCHAR(50),
    vehicle VARCHAR(50),
    pickup_location VARCHAR(100),
    drop_location VARCHAR(100),
    pickup_zone VARCHAR(50),
    pickup_region VARCHAR(50),
    drop_zone VARCHAR(50),
    drop_region VARCHAR(50),
    vehicle_time_to_arrival DECIMAL(10,2),
    customer_time_to_arrival DECIMAL(10,2),
    cancelled_by_customer BOOLEAN,
    reason_cancelled_by_customer TEXT,
    cancelled_by_driver BOOLEAN,
    reason_cancelled_by_driver TEXT,
    incomplete BOOLEAN,
    reason_incomplete TEXT,
    value DECIMAL(10,2),
    distance DECIMAL(10,2),
    distance_category VARCHAR(20),
    value_per_km DECIMAL(10,2),
    driver_rating DECIMAL(3,2),
    customer_rating DECIMAL(3,2),
    payment_method VARCHAR(50),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================
CREATE INDEX idx_booking_date ON silver.booking(date);
CREATE INDEX idx_booking_status ON silver.booking(status);
CREATE INDEX idx_booking_customer_id ON silver.booking(customer_id);
CREATE INDEX idx_booking_vehicle ON silver.booking(vehicle);
CREATE INDEX idx_booking_pickup_zone ON silver.booking(pickup_zone);
CREATE INDEX idx_booking_drop_zone ON silver.booking(drop_zone);
CREATE INDEX idx_booking_distance_category ON silver.booking(distance_category);
CREATE INDEX idx_booking_payment_method ON silver.booking(payment_method);
CREATE INDEX idx_booking_cancelled_customer ON silver.booking(cancelled_by_customer) WHERE cancelled_by_customer = TRUE;
CREATE INDEX idx_booking_cancelled_driver ON silver.booking(cancelled_by_driver) WHERE cancelled_by_driver = TRUE;

-- ============================================================================
-- COLUMN COMMENTS
-- ============================================================================
COMMENT ON TABLE silver.booking IS 'Uber ride bookings with cleaned and enriched data';
COMMENT ON COLUMN silver.booking.id IS 'Unique booking ID';
COMMENT ON COLUMN silver.booking.date IS 'Booking date';
COMMENT ON COLUMN silver.booking.time IS 'Booking time';
COMMENT ON COLUMN silver.booking.status IS 'Booking status (completed, cancelled, etc.)';
COMMENT ON COLUMN silver.booking.customer_id IS 'Customer identifier';
COMMENT ON COLUMN silver.booking.vehicle IS 'Vehicle type (UberX, Uber Black, etc.)';
COMMENT ON COLUMN silver.booking.pickup_location IS 'Pickup address';
COMMENT ON COLUMN silver.booking.drop_location IS 'Drop-off address';
COMMENT ON COLUMN silver.booking.pickup_zone IS 'Pickup zone/neighborhood';
COMMENT ON COLUMN silver.booking.pickup_region IS 'Pickup region/city area';
COMMENT ON COLUMN silver.booking.drop_zone IS 'Drop-off zone/neighborhood';
COMMENT ON COLUMN silver.booking.drop_region IS 'Drop-off region/city area';
COMMENT ON COLUMN silver.booking.vehicle_time_to_arrival IS 'Vehicle time to arrival (minutes)';
COMMENT ON COLUMN silver.booking.customer_time_to_arrival IS 'Customer time to arrival (minutes)';
COMMENT ON COLUMN silver.booking.cancelled_by_customer IS 'Booking cancelled by customer';
COMMENT ON COLUMN silver.booking.reason_cancelled_by_customer IS 'Reason for customer cancellation';
COMMENT ON COLUMN silver.booking.cancelled_by_driver IS 'Booking cancelled by driver';
COMMENT ON COLUMN silver.booking.reason_cancelled_by_driver IS 'Reason for driver cancellation';
COMMENT ON COLUMN silver.booking.incomplete IS 'Incomplete ride';
COMMENT ON COLUMN silver.booking.reason_incomplete IS 'Reason for incomplete ride';
COMMENT ON COLUMN silver.booking.value IS 'Ride value (currency)';
COMMENT ON COLUMN silver.booking.distance IS 'Ride distance (kilometers)';
COMMENT ON COLUMN silver.booking.distance_category IS 'Distance category (short, medium, long)';
COMMENT ON COLUMN silver.booking.value_per_km IS 'Value per kilometer';
COMMENT ON COLUMN silver.booking.driver_rating IS 'Driver rating (1-5)';
COMMENT ON COLUMN silver.booking.customer_rating IS 'Customer rating (1-5)';
COMMENT ON COLUMN silver.booking.payment_method IS 'Payment method (credit card, cash, etc.)';

-- ============================================================================
-- AUXILIARY VIEWS (OPTIONAL)
-- ============================================================================

-- View: High-value rides
CREATE OR REPLACE VIEW silver.vw_high_value_rides AS
SELECT 
    id,
    customer_id,
    vehicle,
    pickup_zone,
    drop_zone,
    distance,
    value,
    value_per_km,
    driver_rating
FROM silver.booking
WHERE status = 'completed'
ORDER BY value DESC;

-- View: Frequently cancelled zones
CREATE OR REPLACE VIEW silver.vw_cancellation_analysis AS
SELECT 
    pickup_zone,
    pickup_region,
    COUNT(*) as total_bookings,
    SUM(CASE WHEN cancelled_by_customer THEN 1 ELSE 0 END) as customer_cancellations,
    SUM(CASE WHEN cancelled_by_driver THEN 1 ELSE 0 END) as driver_cancellations,
    ROUND(AVG(vehicle_time_to_arrival), 2) as avg_vehicle_eta
FROM silver.booking
GROUP BY pickup_zone, pickup_region
ORDER BY (customer_cancellations + driver_cancellations) DESC;

-- View: Vehicle performance summary
CREATE OR REPLACE VIEW silver.vw_vehicle_performance AS
SELECT 
    vehicle,
    COUNT(*) as total_rides,
    ROUND(AVG(distance), 2) as avg_distance,
    ROUND(AVG(value), 2) as avg_value,
    ROUND(AVG(driver_rating), 2) as avg_driver_rating,
    ROUND(AVG(customer_rating), 2) as avg_customer_rating,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_rides
FROM silver.booking
GROUP BY vehicle
ORDER BY total_rides DESC;

-- View: Daily ride metrics
CREATE OR REPLACE VIEW silver.vw_daily_metrics AS
SELECT 
    date,
    COUNT(*) as total_bookings,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_rides,
    SUM(CASE WHEN cancelled_by_customer THEN 1 ELSE 0 END) as customer_cancellations,
    SUM(CASE WHEN cancelled_by_driver THEN 1 ELSE 0 END) as driver_cancellations,
    ROUND(AVG(value), 2) as avg_ride_value,
    ROUND(AVG(distance), 2) as avg_ride_distance,
    SUM(value) as total_revenue
FROM silver.booking
GROUP BY date
ORDER BY date DESC;

-- ============================================================================
-- END OF DDL
-- ============================================================================