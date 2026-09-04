-- 重置 user_management 与 warehouse 的演示数据。
CREATE DATABASE IF NOT EXISTS user_management
    DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE user_management;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    permission TINYINT NOT NULL DEFAULT 3,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ai_conversations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(100) NOT NULL DEFAULT '新对话',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_conversations_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ai_messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT NOT NULL,
    role ENUM('user', 'assistant', 'system') NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_messages_conversation FOREIGN KEY (conversation_id) REFERENCES ai_conversations(id) ON DELETE CASCADE
);

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM ai_messages;
DELETE FROM ai_conversations;
DELETE FROM users;
ALTER TABLE ai_messages AUTO_INCREMENT = 1;
ALTER TABLE ai_conversations AUTO_INCREMENT = 1;
ALTER TABLE users AUTO_INCREMENT = 1;
SET FOREIGN_KEY_CHECKS = 1;
INSERT INTO users (username, password_hash, email, permission)
VALUES ('admin', SHA2('1', 256), 'admin@warehouse.local', 1);

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
    CONSTRAINT fk_stock_category FOREIGN KEY (cat_id) REFERENCES category(cat_id),
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
    CONSTRAINT fk_record_category FOREIGN KEY (cat_id) REFERENCES category(cat_id)
);

CREATE TABLE IF NOT EXISTS expense (
    num BIGINT AUTO_INCREMENT PRIMARY KEY,
    cat_id INT NOT NULL,
    cname VARCHAR(100) NOT NULL,
    b DECIMAL(10, 2) NOT NULL,
    sum INT NOT NULL,
    e DECIMAL(12, 2) NOT NULL,
    t_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_expense_category FOREIGN KEY (cat_id) REFERENCES category(cat_id)
);

CREATE TABLE IF NOT EXISTS income (
    num BIGINT AUTO_INCREMENT PRIMARY KEY,
    cat_id INT NOT NULL,
    cname VARCHAR(100) NOT NULL,
    p DECIMAL(10, 2) NOT NULL,
    sum INT NOT NULL,
    i DECIMAL(12, 2) NOT NULL,
    t_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_income_category FOREIGN KEY (cat_id) REFERENCES category(cat_id)
);

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM income;
DELETE FROM expense;
DELETE FROM record;
DELETE FROM stock;
DELETE FROM category;
ALTER TABLE income AUTO_INCREMENT = 1;
ALTER TABLE expense AUTO_INCREMENT = 1;
ALTER TABLE record AUTO_INCREMENT = 1;
ALTER TABLE stock AUTO_INCREMENT = 1;
ALTER TABLE category AUTO_INCREMENT = 1;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO category (cat_id, cat_name) VALUES
    (1, '食品类'),
    (2, '饮料类'),
    (3, '日用品类'),
    (4, '数码产品类'),
    (5, '文具类');

INSERT INTO stock (cat_id, cname, bid, m_date, e_date, price, sum, up_sum, down_sum) VALUES
    (1, '奥利奥饼干', 5.50, '2026-07-20', '2027-01-16', 8.50, 72, 120, 18),
    (1, '康师傅红烧牛肉面', 3.20, '2026-07-18', '2027-01-14', 4.50, 126, 200, 30),
    (2, '可口可乐', 2.50, '2026-07-12', '2027-05-08', 3.50, 168, 300, 40),
    (2, '农夫山泉', 1.20, '2026-07-08', '2027-05-04', 2.00, 235, 400, 60),
    (3, '蓝月亮洗衣液', 15.00, '2026-05-10', '2029-05-09', 25.00, 36, 60, 8),
    (3, '心相印抽纸', 8.00, '2026-06-01', '2027-06-01', 12.50, 94, 180, 24),
    (4, '苹果数据线', 35.00, '2026-05-20', '2028-05-19', 59.00, 46, 100, 12),
    (4, '罗技鼠标', 60.00, '2026-05-08', '2028-05-07', 99.00, 28, 60, 6),
    (5, '晨光中性笔', 1.50, '2026-06-15', '2029-06-14', 3.00, 480, 800, 120),
    (5, '得力订书机', 12.00, '2026-04-10', '2029-04-09', 20.00, 54, 120, 12);

-- 入库记录：用于成本、库存和收支页面测试。
INSERT INTO expense (cat_id, cname, b, sum, e, t_time) VALUES
    (4, '苹果数据线', 35.00, 54, 1890.00, '2026-08-02 09:20:00'),
    (4, '罗技鼠标', 60.00, 55, 3300.00, '2026-08-05 10:30:00'),
    (1, '奥利奥饼干', 5.50, 40, 220.00, '2026-08-03 14:10:00'),
    (2, '可口可乐', 2.50, 80, 200.00, '2026-08-08 11:05:00'),
    (3, '蓝月亮洗衣液', 15.00, 12, 180.00, '2026-08-11 15:40:00'),
    (5, '晨光中性笔', 1.50, 150, 225.00, '2026-08-15 09:15:00');

-- 出库销售额。
INSERT INTO income (cat_id, cname, p, sum, i, t_time) VALUES
    (4, '苹果数据线', 59.00, 8, 472.00, '2026-08-10 13:20:00'),
    (4, '罗技鼠标', 99.00, 15, 1485.00, '2026-08-12 16:00:00'),
    (4, '罗技鼠标', 99.00, 12, 1188.00, '2026-08-26 10:45:00'),
    (1, '奥利奥饼干', 8.50, 24, 204.00, '2026-08-17 17:30:00'),
    (2, '可口可乐', 3.50, 40, 140.00, '2026-08-19 12:00:00'),
    (3, '蓝月亮洗衣液', 25.00, 6, 150.00, '2026-08-22 18:10:00'),
    (5, '晨光中性笔', 3.00, 90, 270.00, '2026-08-28 14:25:00');

-- 总交易记录与收入、支出表保持一一对应。
INSERT INTO record (cat_id, cname, b_p, sum, e_i, t_time) VALUES
    (4, '苹果数据线', 35.00, 54, -1890.00, '2026-08-02 09:20:00'),
    (4, '罗技鼠标', 60.00, 55, -3300.00, '2026-08-05 10:30:00'),
    (1, '奥利奥饼干', 5.50, 40, -220.00, '2026-08-03 14:10:00'),
    (2, '可口可乐', 2.50, 80, -200.00, '2026-08-08 11:05:00'),
    (3, '蓝月亮洗衣液', 15.00, 12, -180.00, '2026-08-11 15:40:00'),
    (5, '晨光中性笔', 1.50, 150, -225.00, '2026-08-15 09:15:00'),
    (4, '苹果数据线', 59.00, 8, 472.00, '2026-08-10 13:20:00'),
    (4, '罗技鼠标', 99.00, 15, 1485.00, '2026-08-12 16:00:00'),
    (4, '罗技鼠标', 99.00, 12, 1188.00, '2026-08-26 10:45:00'),
    (1, '奥利奥饼干', 8.50, 24, 204.00, '2026-08-17 17:30:00'),
    (2, '可口可乐', 3.50, 40, 140.00, '2026-08-19 12:00:00'),
    (3, '蓝月亮洗衣液', 25.00, 6, 150.00, '2026-08-22 18:10:00'),
    (5, '晨光中性笔', 3.00, 90, 270.00, '2026-08-28 14:25:00');
