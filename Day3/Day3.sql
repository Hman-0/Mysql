-- 1. Tìm các ứng viên đã từng ứng tuyển vào ít nhất một công việc thuộc phòng ban "IT".
-- Sử dụng EXISTS
SELECT *
FROM Candidates c
WHERE EXISTS (
    -- Bước 1: Lọc các hồ sơ ứng tuyển của ứng viên này
    SELECT 1
    FROM Applications a
    JOIN Jobs j ON a.job_id = j.job_id
    WHERE a.candidate_id = c.candidate_id
      AND j.department = 'IT' -- Bước 2: Chỉ lấy các công việc thuộc phòng ban IT
);

-- 2. Liệt kê các công việc mà mức lương tối đa lớn hơn mức lương mong đợi của bất kỳ ứng viên nào.
-- Sử dụng ANY
SELECT *
FROM Jobs
WHERE max_salary > ANY (
    -- Bước 1: Lấy mức lương mong đợi của tất cả ứng viên
    SELECT expected_salary FROM Candidates
);

-- 3. Liệt kê các công việc mà mức lương tối thiểu lớn hơn mức lương mong đợi của tất cả ứng viên.
-- Sử dụng ALL
SELECT *
FROM Jobs
WHERE min_salary > ALL (
    -- Bước 1: Lấy mức lương mong đợi của tất cả ứng viên
    SELECT expected_salary FROM Candidates
);

-- 4. Chèn vào bảng ShortlistedCandidates những ứng viên có trạng thái ứng tuyển là 'Accepted'.
-- Sử dụng INSERT SELECT
INSERT INTO ShortlistedCandidates (candidate_id, job_id, selection_date)
SELECT a.candidate_id, a.job_id, CURRENT_DATE
FROM Applications a
WHERE a.status = 'Accepted';

-- 5. Hiển thị danh sách ứng viên, kèm theo đánh giá mức kinh nghiệm.
-- Sử dụng CASE
SELECT
    candidate_id,
    full_name,
    years_exp,
    -- Bước 1: Đánh giá mức kinh nghiệm dựa vào số năm
    CASE
        WHEN years_exp < 1 THEN 'Fresher'
        WHEN years_exp BETWEEN 1 AND 3 THEN 'Junior'
        WHEN years_exp BETWEEN 4 AND 6 THEN 'Mid-level'
        ELSE 'Senior'
    END AS experience_level
FROM Candidates;

-- 6. Liệt kê tất cả các ứng viên, nếu phone bị NULL thì thay bằng 'Chưa cung cấp'.
-- Sử dụng COALESCE (hoặc IFNULL nếu dùng MySQL)
SELECT
    candidate_id,
    full_name,
    email,
    COALESCE(phone, 'Chưa cung cấp') AS phone,
    years_exp,
    expected_salary
FROM Candidates;

-- 7. Tìm các công việc có mức lương tối đa không bằng mức lương tối thiểu và mức lương tối đa lớn hơn hoặc bằng 1000.
-- Sử dụng các Operators như !=, >=, AND, OR
SELECT *
FROM Jobs
WHERE max_salary != min_salary
  AND max_salary >= 1000;
