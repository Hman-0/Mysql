-- Tạo bảng Rooms
CREATE TABLE Rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    room_number VARCHAR(10) UNIQUE NOT NULL,
    type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Available', 'Occupied', 'Maintenance')),
    price INT NOT NULL CHECK (price >= 0)
);

-- Tạo bảng Guests
CREATE TABLE Guests (
    guest_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL
);

-- Tạo bảng Bookings
CREATE TABLE Bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    guest_id INT NOT NULL,
    room_id INT NOT NULL,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Pending', 'Confirmed', 'Cancelled')),
    FOREIGN KEY (guest_id) REFERENCES Guests(guest_id),
    FOREIGN KEY (room_id) REFERENCES Rooms(room_id)
);

-- Tạo bảng Invoices (Bonus)
CREATE TABLE Invoices (
    invoice_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    total_amount INT NOT NULL,
    generated_date DATE NOT NULL,
    FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id)
);

-- DỮ LIỆU MẪU

-- Rooms
INSERT INTO Rooms (room_number, type, status, price) VALUES
('101', 'Standard', 'Available', 500000),
('102', 'VIP', 'Available', 1200000),
('201', 'Suite', 'Available', 2000000),
('202', 'Standard', 'Maintenance', 550000),
('301', 'VIP', 'Available', 1300000);

-- Guests
INSERT INTO Guests (full_name, phone) VALUES
('Nguyen Van A', '0901234567'),
('Tran Thi B', '0912345678'),
('Le Van C', '0923456789');

-- Bookings
-- Đặt phòng cho khách 1, phòng 101, đã xác nhận
INSERT INTO Bookings (guest_id, room_id, check_in, check_out, status) VALUES
(1, 1, '2024-07-01', '2024-07-05', 'Confirmed'),
(2, 2, '2024-07-03', '2024-07-06', 'Pending'),
(3, 3, '2024-07-10', '2024-07-15', 'Cancelled');

-- Invoices (nếu muốn có mẫu)
INSERT INTO Invoices (booking_id, total_amount, generated_date) VALUES
(1, 2000000, '2024-07-05');


-- Stored Procedure: MakeBooking
DELIMITER $$
CREATE PROCEDURE MakeBooking(
    IN p_guest_id INT,
    IN p_room_id INT,
    IN p_check_in DATE,
    IN p_check_out DATE
)
BEGIN
    -- Kiểm tra phòng có Available không
    IF NOT EXISTS (
        SELECT 1 FROM Rooms WHERE room_id = p_room_id AND status = 'Available'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is not available!';
    END IF;

    -- Kiểm tra trùng lịch đặt phòng
    IF EXISTS (
        SELECT 1 FROM Bookings
        WHERE room_id = p_room_id
          AND status = 'Confirmed'
          AND (
                (p_check_in < check_out AND p_check_out > check_in)
              )
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is already booked for the selected dates!';
    END IF;

    -- Nếu hợp lệ, tạo booking và cập nhật phòng
    INSERT INTO Bookings (guest_id, room_id, check_in, check_out, status)
    VALUES (p_guest_id, p_room_id, p_check_in, p_check_out, 'Confirmed');

    UPDATE Rooms SET status = 'Occupied' WHERE room_id = p_room_id;
END$$
DELIMITER ;

-- Trigger: after_booking_cancel
DELIMITER $$
CREATE TRIGGER after_booking_cancel
AFTER UPDATE ON Bookings
FOR EACH ROW
BEGIN
    -- Chỉ xử lý khi status chuyển thành Cancelled
    IF NEW.status = 'Cancelled' AND OLD.status <> 'Cancelled' THEN
        -- Kiểm tra còn booking nào khác cho phòng này trong tương lai không
        IF NOT EXISTS (
            SELECT 1 FROM Bookings
            WHERE room_id = NEW.room_id
              AND status = 'Confirmed'
              AND check_in > CURDATE()
        ) THEN
            UPDATE Rooms SET status = 'Available' WHERE room_id = NEW.room_id;
        END IF;
    END IF;
END$$
DELIMITER ;

-- Stored Procedure: GenerateInvoice (Bonus)
DELIMITER $$
CREATE PROCEDURE GenerateInvoice(
    IN p_booking_id INT
)
BEGIN
    DECLARE v_check_in DATE;
    DECLARE v_check_out DATE;
    DECLARE v_room_id INT;
    DECLARE v_price INT;
    DECLARE v_nights INT;
    DECLARE v_total INT;

    -- Lấy thông tin booking
    SELECT check_in, check_out, room_id INTO v_check_in, v_check_out, v_room_id
    FROM Bookings WHERE booking_id = p_booking_id;

    -- Lấy giá phòng
    SELECT price INTO v_price FROM Rooms WHERE room_id = v_room_id;

    -- Tính số đêm
    SET v_nights = DATEDIFF(v_check_out, v_check_in);

    -- Tính tổng tiền
    SET v_total = v_nights * v_price;

    -- Lưu vào bảng Invoices
    INSERT INTO Invoices (booking_id, total_amount, generated_date)
    VALUES (p_booking_id, v_total, CURDATE());
END$$
DELIMITER ;

-- DEMO: Thực thi các procedure và trigger

-- 1. Đặt phòng mới (MakeBooking)
-- Đặt cho khách 2, phòng 5, từ 2024-07-25 đến 2024-07-28
CALL MakeBooking(2, 5, '2024-07-25', '2024-07-28');

-- 2. Hủy booking (giả sử booking_id = 2)
UPDATE Bookings SET status = 'Cancelled' WHERE booking_id = 2;

-- 3. Tạo hóa đơn cho booking_id = 2
CALL GenerateInvoice(1);

-- 4. Kiểm tra dữ liệu các bảng
SELECT * FROM Rooms;
SELECT * FROM Bookings;
SELECT * FROM Invoices;

