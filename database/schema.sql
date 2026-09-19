-- qmlProductManager V1.0 数据库结构。
-- 本脚本只创建数据库、表、约束和索引，不清空现有数据，也不写入演示数据。

CREATE DATABASE IF NOT EXISTS user_management
    DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE user_management;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    permission TINYINT NOT NULL DEFAULT 3,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_users_permission CHECK (permission IN (1, 2, 3))
);

CREATE TABLE IF NOT EXISTS ai_conversations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(100) NOT NULL DEFAULT '新对话',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_conversations_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ai_messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT NOT NULL,
    role ENUM('user', 'assistant', 'system') NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_messages_conversation FOREIGN KEY (conversation_id)
        REFERENCES ai_conversations(id) ON DELETE CASCADE
);

CREATE DATABASE IF NOT EXISTS warehouse
    DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE warehouse;

CREATE TABLE IF NOT EXISTS category (
    cat_id INT AUTO_INCREMENT PRIMARY KEY,
    cat_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS stock (
    stock_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cat_id INT NOT NULL,
    cname VARCHAR(100) NOT NULL,
    bid DECIMAL(10, 2) NOT NULL,
    m_date DATE NOT NULL,
    e_date DATE NOT NULL,
    price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    sum INT NOT NULL DEFAULT 0,
    up_sum INT NOT NULL DEFAULT 0,
    down_sum INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_stock_category FOREIGN KEY (cat_id)
        REFERENCES category(cat_id),
    CONSTRAINT chk_stock_bid CHECK (bid >= 0),
    CONSTRAINT chk_stock_price CHECK (price >= 0),
    CONSTRAINT chk_stock_sum CHECK (sum >= 0),
    CONSTRAINT chk_stock_limits CHECK (up_sum >= down_sum AND down_sum >= 0),
    CONSTRAINT chk_stock_dates CHECK (e_date >= m_date),
    CONSTRAINT uk_stock_batch UNIQUE (cat_id, cname, bid, m_date, e_date)
);

CREATE TABLE IF NOT EXISTS record (
    num BIGINT AUTO_INCREMENT PRIMARY KEY,
    cat_id INT NOT NULL,
    cname VARCHAR(100) NOT NULL,
    b_p DECIMAL(10, 2) NOT NULL,
    sum INT NOT NULL,
    e_i DECIMAL(12, 2) NOT NULL,
    t_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_record_category FOREIGN KEY (cat_id)
        REFERENCES category(cat_id),
    CONSTRAINT chk_record_price CHECK (b_p >= 0),
    CONSTRAINT chk_record_sum CHECK (sum > 0)
);

CREATE TABLE IF NOT EXISTS expense (
    num BIGINT AUTO_INCREMENT PRIMARY KEY,
    cat_id INT NOT NULL,
    cname VARCHAR(100) NOT NULL,
    b DECIMAL(10, 2) NOT NULL,
    sum INT NOT NULL,
    e DECIMAL(12, 2) NOT NULL,
    t_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_expense_category FOREIGN KEY (cat_id)
        REFERENCES category(cat_id),
    CONSTRAINT chk_expense_price CHECK (b >= 0),
    CONSTRAINT chk_expense_sum CHECK (sum > 0),
    CONSTRAINT chk_expense_amount CHECK (e >= 0)
);

CREATE TABLE IF NOT EXISTS income (
    num BIGINT AUTO_INCREMENT PRIMARY KEY,
    cat_id INT NOT NULL,
    cname VARCHAR(100) NOT NULL,
    p DECIMAL(10, 2) NOT NULL,
    sum INT NOT NULL,
    i DECIMAL(12, 2) NOT NULL,
    t_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_income_category FOREIGN KEY (cat_id)
        REFERENCES category(cat_id),
    CONSTRAINT chk_income_price CHECK (p >= 0),
    CONSTRAINT chk_income_sum CHECK (sum > 0),
    CONSTRAINT chk_income_amount CHECK (i >= 0)
);

CREATE INDEX idx_stock_category_name ON stock (cat_id, cname);
CREATE INDEX idx_record_filter ON record (cat_id, cname, t_time);
CREATE INDEX idx_expense_filter ON expense (cat_id, cname, t_time);
CREATE INDEX idx_income_filter ON income (cat_id, cname, t_time);

-- 新注册账号默认为顾客访客（permission=3）。如需调整角色，可执行：
-- UPDATE user_management.users SET permission = 1 WHERE username = '店主账号';
-- UPDATE user_management.users SET permission = 2 WHERE username = '店员账号';
