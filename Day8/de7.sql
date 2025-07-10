
-- 1. TẠO BẢNG CHO HỆ THỐNG E-COMMERCE


CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category_id INT,
    price DECIMAL(12,2),
    stock_quantity INT,
    created_at DATETIME,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    order_date DATETIME,
    status VARCHAR(20)
);

CREATE TABLE OrderItems (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(12,2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);


-- 2. THÊM DỮ LIỆU MẪU


INSERT INTO Categories (name) VALUES
('Electronics'),
('Books'),
('Clothing');

INSERT INTO Products (name, category_id, price, stock_quantity, created_at) VALUES
('Smartphone', 1, 12000000, 50, '2024-06-01 10:00:00'),
('Laptop', 1, 25000000, 30, '2024-06-02 11:00:00'),
('Headphones', 1, 1500000, 100, '2024-06-03 12:00:00'),
('Novel', 2, 200000, 200, '2024-06-04 13:00:00'),
('T-shirt', 3, 300000, 150, '2024-06-05 14:00:00'),
('Tablet', 1, 8000000, 20, '2024-06-06 15:00:00'),
('E-reader', 1, 2500000, 0, '2024-06-07 16:00:00');

INSERT INTO Orders (user_id, order_date, status) VALUES
(1, '2024-06-10 09:00:00', 'Shipped'),
(2, '2024-06-11 10:00:00', 'Pending'),
(3, '2024-06-12 11:00:00', 'Shipped'),
(4, '2024-06-13 12:00:00', 'Cancelled'),
(1, '2024-06-14 13:00:00', 'Shipped');

INSERT INTO OrderItems (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 2, 12000000),
(1, 3, 1, 1500000),
(2, 2, 1, 25000000),
(3, 1, 1, 12000000),
(3, 4, 3, 200000),
(4, 5, 2, 300000),
(5, 6, 1, 8000000),
(5, 1, 1, 12000000);

-- Thêm dữ liệu mẫu mới cho đơn hàng trong 30 ngày gần nhất
INSERT INTO Orders (user_id, order_date, status) VALUES
(2, NOW() - INTERVAL 5 DAY, 'Shipped'),
(3, NOW() - INTERVAL 10 DAY, 'Shipped');

-- Giả sử order_id tự tăng tiếp theo là 6 và 7 (nếu không, hãy kiểm tra lại giá trị thực tế)
INSERT INTO OrderItems (order_id, product_id, quantity, unit_price) VALUES
(6, 1, 3, 12000000),
(7, 2, 2, 25000000),
(6, 3, 1, 1500000),
(7, 4, 4, 200000);


-- 3. TẠO CHỈ MỤC TỐI ƯU HÓA


-- Chỉ mục cho Orders hỗ trợ lọc và sắp xếp
CREATE INDEX idx_orders_status_orderdate ON Orders(status, order_date DESC);
-- Composite index hỗ trợ JOIN hiệu quả giữa Orders và OrderItems
CREATE INDEX idx_orderitems_orderid_productid ON OrderItems(order_id, product_id);
-- Covering index cho Products
CREATE INDEX idx_products_covering ON Products(category_id, price, product_id, name);


-- 4. Truy vấn JOIN chỉ lấy cột cần thiết
SELECT Orders.order_id, Orders.order_date, Orders.status, OrderItems.product_id, OrderItems.quantity
FROM Orders
JOIN OrderItems ON Orders.order_id = OrderItems.order_id
WHERE Orders.status = 'Shipped'
ORDER BY Orders.order_date DESC;

-- 5. So sánh JOIN vs Subquery
-- JOIN (nên dùng)
SELECT Products.product_id, Products.name, Categories.name AS category_name
FROM Products
JOIN Categories ON Products.category_id = Categories.category_id;
-- Subquery (kém hiệu quả)
SELECT product_id, name,
  (SELECT name FROM Categories WHERE Categories.category_id = Products.category_id) AS category_name
FROM Products;

-- 6. Lấy 10 sản phẩm mới nhất trong danh mục 'Electronics', còn hàng
SELECT p.product_id, p.name, p.price, p.stock_quantity, p.created_at
FROM Products p
JOIN Categories c ON p.category_id = c.category_id
WHERE c.name = 'Electronics'
  AND p.stock_quantity > 0
ORDER BY p.created_at DESC
LIMIT 10;

-- 7. Truy vấn sử dụng Covering Index
SELECT product_id, name, price 
FROM Products 
WHERE category_id = 3 
ORDER BY price ASC 
LIMIT 20;

-- 8. Tính doanh thu theo tháng
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, SUM(oi.quantity * oi.unit_price) AS revenue
    FROM Orders o
    JOIN OrderItems oi ON o.order_id = oi.order_id
    WHERE o.order_date >= '2024-01-01' AND o.order_date < '2025-01-01'
    AND o.status = 'Shipped'
    GROUP BY month
    ORDER BY month;

-- 9. Tách truy vấn lớn thành nhiều bước nhỏ
-- Bước 1: Lọc đơn hàng có sản phẩm đắt tiền (>1M)
SELECT DISTINCT o.order_id
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
WHERE oi.unit_price > 1000000;
-- Bước 2: Tính tổng số lượng bán ra của các đơn hàng này
SELECT SUM(oi.quantity) AS total_quantity
FROM OrderItems oi
WHERE oi.order_id IN (
  SELECT DISTINCT o.order_id
  FROM Orders o
  JOIN OrderItems oi2 ON o.order_id = oi2.order_id
  WHERE oi2.unit_price > 1000000
);

-- 10. Top 5 sản phẩm bán chạy nhất trong 30 ngày gần nhất
SELECT p.product_id, p.name, SUM(oi.quantity) AS total_sold
FROM OrderItems oi
JOIN Orders o ON oi.order_id = o.order_id
JOIN Products p ON oi.product_id = p.product_id
WHERE o.order_date >= NOW() - INTERVAL 30 DAY
  AND o.status = 'Shipped'
GROUP BY p.product_id, p.name
ORDER BY total_sold DESC
LIMIT 5;



