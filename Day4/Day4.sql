-- 1. Tạo cơ sở dữ liệu
CREATE DATABASE IF NOT EXISTS OnlineLearning;
USE OnlineLearning;

-- 2. Xóa cơ sở dữ liệu nếu không còn dùng nữa
DROP DATABASE IF EXISTS OnlineLearning;

-- 3. Tạo bảng Students
CREATE TABLE IF NOT EXISTS Students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    join_date DATE
);


-- 4. Tạo bảng Courses
CREATE TABLE IF NOT EXISTS Courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    price INT CHECK (price >= 0)
);

-- 5. Tạo bảng Enrollments
CREATE TABLE IF NOT EXISTS Enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    course_id INT,
    enroll_date DATE DEFAULT (CURDATE()),
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id)
);

-- Thêm dữ liệu vào bảng Students
INSERT INTO Students (full_name, email, join_date) VALUES
('Nguyen Van A', 'a@student.com', '2025-06-01'),
('Tran Thi B', 'b@student.com', '2025-06-03'),
('Le Van C', 'c@student.com', '2025-06-05');

-- Thêm dữ liệu vào bảng Courses
INSERT INTO Courses (title, description, price) VALUES
('Web Development', 'Learn to build websites using HTML, CSS, and JavaScript', 100),
('Data Structures', 'Introduction to algorithms and data structures', 120),
('Database Basics', 'Learn relational databases and SQL', 90);

-- Thêm dữ liệu vào bảng Enrollments
INSERT INTO Enrollments (student_id, course_id) VALUES
(1, 1),
(1, 3),
(2, 2),
(3, 1),
(3, 2);

-- 6. Thêm cột status vào bảng Enrollments
ALTER TABLE Enrollments
ADD COLUMN status VARCHAR(20) DEFAULT 'active';

-- 7. Xóa bảng Enrollments nếu không còn cần nữa
DROP TABLE IF EXISTS Enrollments;

-- 8. Tạo VIEW hiển thị danh sách sinh viên và tên khóa học họ đã đăng ký
CREATE OR REPLACE VIEW StudentCourseView AS
SELECT s.student_id, s.full_name, s.email, c.course_id, c.title AS course_title
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
JOIN Courses c ON e.course_id = c.course_id;

-- 9. Tạo chỉ mục trên cột title của bảng Courses
CREATE INDEX idx_courses_title ON Courses(title);
