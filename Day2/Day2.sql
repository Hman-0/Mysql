-- 1. Tạo bảng và dữ liệu mẫu

CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    city VARCHAR(50),
    referrer_id INT,
    created_at DATE
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price INT,
    is_active TINYINT
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date DATE,
    status VARCHAR(20)
);

CREATE TABLE OrderItems (
    order_id INT,
    product_id INT,
    quantity INT
);

INSERT INTO Users VALUES
(1, 'Nguyen Van A', 'Hanoi', NULL, '2023-01-01'),
(2, 'Tran Thi B', 'HCM', 1, '2023-01-10'),
(3, 'Le Van C', 'Hanoi', 1, '2023-01-12'),
(4, 'Do Thi D', 'Da Nang', 2, '2023-02-05'),
(5, 'Hoang E', 'Can Tho', NULL, '2023-02-10');


INSERT INTO Products VALUES
(1, 'iPhone 13', 'Electronics', 20000000, 1),
(2, 'MacBook Air', 'Electronics', 28000000, 1),
(3, 'Coffee Beans', 'Grocery', 250000, 1),
(4, 'Book: SQL Basics', 'Books', 150000, 1),
(5, 'Xbox Controller', 'Gaming', 1200000, 0);


INSERT INTO Orders VALUES
(1001, 1, '2023-02-01', 'completed'),
(1002, 2, '2023-02-10', 'cancelled'),
(1003, 3, '2023-02-12', 'completed'),
(1004, 4, '2023-02-15', 'completed'),
(1005, 1, '2023-03-01', 'pending');


INSERT INTO OrderItems VALUES
(1001, 1, 1),
(1001, 3, 3),
(1003, 2, 1),
(1003, 4, 2),
(1004, 3, 5),
(1005, 2, 1);

-- 2. Các truy vấn 

-- 1. Tổng doanh thu từ các đơn hàng completed, nhóm theo danh mục sản phẩm
SELECT
    p.category,
    SUM(oi.quantity * p.price) AS total_revenue
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY p.category;

-- 2. Danh sách người dùng kèm tên người giới thiệu (self join)
SELECT
    u.user_id,
    u.full_name,
    ref.full_name AS referrer_name
FROM Users u
LEFT JOIN Users ref ON u.referrer_id = ref.user_id;

-- 3. Sản phẩm đã từng được đặt mua nhưng hiện tại không còn active
SELECT DISTINCT
    p.product_id,
    p.product_name
FROM OrderItems oi
JOIN Products p ON oi.product_id = p.product_id
WHERE p.is_active = 0;

-- 4. Người dùng chưa từng đặt bất kỳ đơn hàng nào
SELECT
    u.user_id,
    u.full_name
FROM Users u
LEFT JOIN Orders o ON u.user_id = o.user_id
WHERE o.order_id IS NULL;

-- 5. Đơn hàng đầu tiên của từng người dùng
SELECT
    o.user_id,
    MIN(o.order_id) AS first_order_id
FROM Orders o
GROUP BY o.user_id;

-- 6. Tổng chi tiêu của mỗi người dùng (chỉ tính đơn hàng completed)
SELECT
    o.user_id,
    SUM(oi.quantity * p.price) AS total_spent
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY o.user_id;

-- 7. Lọc người dùng tiêu nhiều (> 25 triệu)
SELECT
    user_id,
    total_spent
FROM (
    SELECT
        o.user_id,
        SUM(oi.quantity * p.price) AS total_spent
    FROM Orders o
    JOIN OrderItems oi ON o.order_id = oi.order_id
    JOIN Products p ON oi.product_id = p.product_id
    WHERE o.status = 'completed'
    GROUP BY o.user_id
) t
WHERE total_spent > 25000000;

-- 8. Tổng số đơn hàng và tổng doanh thu của từng thành phố
SELECT
    u.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(CASE WHEN o.status = 'completed' THEN oi.quantity * p.price ELSE 0 END) AS total_revenue
FROM Users u
LEFT JOIN Orders o ON u.user_id = o.user_id
LEFT JOIN OrderItems oi ON o.order_id = oi.order_id
LEFT JOIN Products p ON oi.product_id = p.product_id
GROUP BY u.city;

-- 9. Người dùng có ít nhất 2 đơn hàng completed
SELECT
    o.user_id,
    COUNT(*) AS completed_orders
FROM Orders o
WHERE o.status = 'completed'
GROUP BY o.user_id
HAVING COUNT(*) >= 2;

-- 10. Đơn hàng có sản phẩm thuộc nhiều hơn 1 danh mục
SELECT
    oi.order_id
FROM OrderItems oi
JOIN Products p ON oi.product_id = p.product_id
GROUP BY oi.order_id
HAVING COUNT(DISTINCT p.category) > 1;

-- 11. UNION: người dùng đã từng đặt hàng và người dùng được giới thiệu
SELECT
    u.user_id,
    u.full_name,
    'placed_order' AS source
FROM Users u
JOIN Orders o ON u.user_id = o.user_id

UNION

SELECT
    u.user_id,
    u.full_name,
    'referred' AS source
FROM Users u
WHERE u.referrer_id IS NOT NULL;
