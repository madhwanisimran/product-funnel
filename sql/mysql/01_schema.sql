USE funnel_db;

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS users;

-- users
CREATE TABLE users (
	full_visitor_id               VARCHAR(20) NOT NULL,
    first_session_date			  DATE NOT NULL,
    cohort_month				  DATE NOT NULL,
    first_visit_number			  INT NOT NULL,
    is_true_new					  TINYINT(1) NOT NULL,
    first_channel				  VARCHAR(20) NULL,
    first_category                VARCHAR(10) NULL,
    first_country                 VARCHAR(60) NULL,
    has_inconsistent_visit_number TINYINT(1) NOT NULL,
    in_cohort_analysis			  TINYINT(1) NOT NULL,
    is_heavy_visitor			  TINYINT(1) NOT NULL,
    valid_orders				  INT NOT NULL,
    is_heavy_buyer				  TINYINT(1) NOT NULL,
    PRIMARY KEY (full_visitor_id)
) ENGINE=InnoDB DEFAULT CHARSET = utf8mb4;

-- sessions
CREATE TABLE sessions (
  session_key           VARCHAR(45)   NOT NULL,
  session_id            VARCHAR(40)   NOT NULL,
  full_visitor_id       VARCHAR(20)   NOT NULL,
  visit_id              BIGINT        NOT NULL,
  session_date          DATE          NOT NULL,
  visit_start_ts        DATETIME      NOT NULL,
  visit_number          INT           NOT NULL,
  channel_grouping      VARCHAR(20)   NOT NULL,
  device_category       VARCHAR(10)   NOT NULL,
  country               VARCHAR(60)   NOT NULL,
  pageviews             INT           NULL,
  total_hits            INT           NOT NULL,
  is_bounce             TINYINT(1)    NOT NULL,
  transactions          INT           NULL,
  session_revenue_usd   DECIMAL(14,6) NULL,
  is_split_visit        TINYINT(1)    NOT NULL,
  is_continuation_row   TINYINT(1)    NOT NULL,
  is_hit_cap_session    TINYINT(1)    NOT NULL,
  is_extreme_session    TINYINT(1)    NOT NULL,
  has_revenue_gap       TINYINT(1)    NOT NULL,
  is_valid_purchase_row TINYINT(1)    NOT NULL,
  PRIMARY KEY (session_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- events
CREATE TABLE events (
	event_id		VARCHAR(60)  NOT NULL,
    session_key 	VARCHAR(45)  NOT NULL,
    session_id		VARCHAR(40)	 NOT NULL,
    full_visitor_id VARCHAR(20)  NOT NULL,
    event_ts		DATETIME(3)  NOT NULL,
    hit_number		INT 		 NOT NULL,
    hit_type		VARCHAR(20)  NOT NULL,
    action_type		VARCHAR(2)   NOT NULL,
    event_name		VARCHAR(25)  NOT NULL,
    transaction_id  VARCHAR(30)  NULL,
    PRIMARY KEY (event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- orders
CREATE TABLE orders (
  transaction_id         VARCHAR(30)   NOT NULL,
  session_id             VARCHAR(40)   NOT NULL,
  session_key            VARCHAR(45)   NOT NULL,
  full_visitor_id        VARCHAR(20)   NOT NULL,
  order_date             DATE          NOT NULL,
  order_ts               DATETIME(3)   NOT NULL,
  hit_number             INT           NOT NULL,
  revenue_usd            DECIMAL(14,6) NULL,
  tax_usd                DECIMAL(14,6) NULL,
  shipping_usd           DECIMAL(14,6) NULL,
  currency               VARCHAR(3)    NOT NULL,
  is_valid_order         TINYINT(1)    NOT NULL,
  is_large_order_outlier TINYINT(1)    NOT NULL,
  PRIMARY KEY (transaction_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SHOW TABLES;
DESCRIBE orders;
DESCRIBE users;