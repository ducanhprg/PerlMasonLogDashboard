-- Simple Log Dashboard Database Schema
-- Optimized for Perl + Mason + PostgreSQL demo

-- Create the database if it doesn't exist
-- CREATE DATABASE log_dashboard;

-- \c log_dashboard;

-- Simple log entries table that matches the application
CREATE TABLE IF NOT EXISTS log_entries (
    id BIGSERIAL PRIMARY KEY,
    log_type VARCHAR(20) NOT NULL,           -- 'access' or 'error'
    ip_address INET,
    timestamp TIMESTAMP WITH TIME ZONE,
    method VARCHAR(10),                      -- HTTP method
    path VARCHAR(1024),
    status_code INTEGER,
    response_size INTEGER,
    user_agent TEXT,
    response_time NUMERIC(10,3),             -- in milliseconds
    level VARCHAR(20),                       -- for error logs
    message TEXT,                            -- for error logs
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_log_entries_timestamp ON log_entries(timestamp);
CREATE INDEX IF NOT EXISTS idx_log_entries_log_type ON log_entries(log_type);
CREATE INDEX IF NOT EXISTS idx_log_entries_status_code ON log_entries(status_code);
CREATE INDEX IF NOT EXISTS idx_log_entries_ip_address ON log_entries(ip_address);
CREATE INDEX IF NOT EXISTS idx_log_entries_path ON log_entries(path);

-- Insert some sample data if table is empty
INSERT INTO log_entries (log_type, ip_address, timestamp, method, path, status_code, response_size, user_agent, response_time)
SELECT 'access', '192.168.1.100', NOW() - INTERVAL '1 hour', 'GET', '/', 200, 1234, 'Mozilla/5.0', 150.5
WHERE NOT EXISTS (SELECT 1 FROM log_entries LIMIT 1); 