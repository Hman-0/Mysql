--Tạo bảng trong phpmyadmin 
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(100),
    email VARCHAR(100)
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount INT,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100),
    price INT
);


-- Thêm dữ liệu vào bảng

-- Customers
INSERT INTO Customers (customer_id, name, city, email) VALUES
(1, 'Nguyen An', 'Hanoi', 'an.nguyen@email.com'),
(2, 'Tran Binh', 'Ho Chi Minh', NULL),
(3, 'Le Cuong', 'Da Nang', 'cuong.le@email.com'),
(4, 'Hoang Duong', 'Hanoi', 'duong.hoang@email.com');

-- Orders
INSERT INTO Orders (order_id, customer_id, order_date, total_amount) VALUES
(101, 1, '2023-01-15', 500000),
(102, 3, '2023-02-10', 800000),
(103, 2, '2023-03-05', 300000),
(104, 1, '2023-04-01', 450000);

-- Products
INSERT INTO Products (product_id, name, price) VALUES
(1, 'Laptop Dell', 15000000),
(2, 'Mouse Logitech', 300000),
(3, 'Keyboard Razer', 1200000),
(4, 'Laptop HP', 14000000);





-- 1. Danh sách khách hàng đến từ Hà Nội
SELECT * FROM Customers WHERE city = 'Hanoi';

-- 2. Đơn hàng có giá trị trên 400.000 đồng và đặt sau ngày 31/01/2023
SELECT * FROM Orders WHERE total_amount > 400000 AND order_date > '2023-01-31';

-- 3. Khách hàng chưa có địa chỉ email
SELECT * FROM Customers WHERE email IS NULL;

-- 4. Xem toàn bộ đơn hàng, sắp xếp theo tổng tiền từ cao xuống thấp
SELECT * FROM Orders ORDER BY total_amount DESC;

-- 5. Thêm khách hàng mới "Pham Thanh" (email để trống)
INSERT INTO Customers (customer_id, name, city, email) VALUES (5, 'Pham Thanh', 'Can Tho', NULL);

-- 6. Cập nhật email khách hàng có mã 2
UPDATE Customers SET email = 'binh.tran@email.com' WHERE customer_id = 2;

-- 7. Xóa đơn hàng có mã là 103
DELETE FROM Orders WHERE order_id = 103;

-- 8. Lấy danh sách 2 khách hàng đầu tiên
SELECT * FROM Customers LIMIT 2;

-- 9. Đơn hàng có giá trị lớn nhất và nhỏ nhất
SELECT MAX(total_amount) AS max_order, MIN(total_amount) AS min_order FROM Orders;

-- 10. Tổng số lượng đơn hàng, tổng số tiền đã bán ra và trung bình giá trị một đơn hàng
SELECT COUNT(*) AS total_orders, SUM(total_amount) AS total_sales, AVG(total_amount) AS avg_order_value FROM Orders;

-- 11. Sản phẩm có tên bắt đầu bằng "Laptop"
SELECT * FROM Products WHERE name LIKE 'Laptop%';

-- 12. Mô tả ngắn gọn về RDBMS và vai trò các mối quan hệ
-- RDBMS (Relational Database Management System) là hệ quản trị cơ sở dữ liệu quan hệ, cho phép lưu trữ, quản lý dữ liệu theo các bảng có liên kết với nhau qua các khóa. Các mối quan hệ giữa các bảng (ví dụ: Customers và Orders liên kết qua customer_id) giúp đảm bảo tính toàn vẹn dữ liệu, giảm trùng lặp và hỗ trợ truy vấn dữ liệu hiệu quả.
