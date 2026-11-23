USE funnel_db;

-- sessions
ALTER TABLE sessions
	ADD INDEX idx_sessions_visitor_visit (full_visitor_id,visit_number),
    ADD INDEX idx_sessions_date			 (session_date),
    ADD INDEX idx_sessions_channel  	 (channel_grouping),
    ADD INDEX idx_sessions_session_id	 (session_id);
    
-- events
ALTER TABLE events
	ADD INDEX idx_events_session_event   (session_key, event_name),
    ADD INDEX idx_events_name			 (event_name);
    
-- orders
ALTER TABLE orders
	ADD INDEX idx_orders_visitor  (full_visitor_id),
    ADD INDEX idx_orders_date 	  (order_date);
    
-- users
ALTER TABLE users
	ADD INDEX idx_users_cohort (cohort_month, first_channel);
    
-- foreign keys
ALTER TABLE sessions ADD CONSTRAINT fk_sessions_user
  FOREIGN KEY (full_visitor_id) REFERENCES users (full_visitor_id);
  
ALTER TABLE events ADD CONSTRAINT fk_events_session
  FOREIGN KEY (session_key) REFERENCES sessions (session_key);
  
ALTER TABLE orders ADD CONSTRAINT fk_orders_session
  FOREIGN KEY (session_key) REFERENCES sessions (session_key);
    
SELECT TABLE_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'funnel_db' AND REFERENCED_TABLE_NAME IS NOT NULL;

SHOW INDEX FROM events;
