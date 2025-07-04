-- 1. Tạo bảng Candidates
CREATE TABLE Candidates (
    candidate_id INT PRIMARY KEY,
    full_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    years_exp INT,
    expected_salary INT
);

-- Thêm dữ liệu mẫu cho Candidates
INSERT INTO Candidates (candidate_id, full_name, email, phone, years_exp, expected_salary)
VALUES
(1, 'Nguyen Van A', 'a@example.com', '0909123456', 3, 1000),
(2, 'Tran Thi B', 'b@example.com', '0912345678', 5, 1500),
(3, 'Le Van C', 'c@example.com', '0987654321', 2, 900);

-- 2. Tạo bảng Jobs
CREATE TABLE Jobs (
    job_id INT PRIMARY KEY,
    title VARCHAR(255),
    department VARCHAR(255),
    min_salary INT,
    max_salary INT
);

-- Thêm dữ liệu mẫu cho Jobs
INSERT INTO Jobs (job_id, title, department, min_salary, max_salary)
VALUES
(101, 'Backend Developer', 'IT', 800, 1200),
(102, 'Frontend Developer', 'IT', 900, 1300),
(103, 'HR Executive', 'HR', 700, 1000);

-- 3. Tạo bảng Applications
CREATE TABLE Applications (
    app_id INT PRIMARY KEY,
    candidate_id INT,
    job_id INT,
    apply_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (candidate_id) REFERENCES Candidates(candidate_id),
    FOREIGN KEY (job_id) REFERENCES Jobs(job_id)
);

-- Thêm dữ liệu mẫu cho Applications
INSERT INTO Applications (app_id, candidate_id, job_id, apply_date, status)
VALUES
(1001, 1, 101, '2025-06-01', 'Pending'),
(1002, 2, 102, '2025-06-03', 'Accepted'),
(1003, 3, 103, '2025-06-05', 'Rejected');

-- 4. Tạo bảng ShortlistedCandidates
CREATE TABLE ShortlistedCandidates (
    candidate_id INT,
    job_id INT,
    selection_date DATE,
    PRIMARY KEY (candidate_id, job_id),
    FOREIGN KEY (candidate_id) REFERENCES Candidates(candidate_id),
    FOREIGN KEY (job_id) REFERENCES Jobs(job_id)
);


