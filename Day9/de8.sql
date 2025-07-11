-- ✅ Tạo bảng mẫu theo đề bài
CREATE TABLE Users (
  user_id INT PRIMARY KEY,
  username VARCHAR(50),
  created_at DATETIME
);

CREATE TABLE Posts (
  post_id INT PRIMARY KEY,
  user_id INT,
  content TEXT,
  created_at DATETIME,
  likes INT,
  hashtags VARCHAR(255),
  FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Follows (
  follower_id INT,
  followee_id INT,
  PRIMARY KEY (follower_id, followee_id)
);

-- Do PostViews cần phân vùng => không dùng FOREIGN KEY
CREATE TABLE PostViews (
  view_id BIGINT PRIMARY KEY,
  post_id INT,
  viewer_id INT,
  view_time DATETIME
);

-- ✅ Dữ liệu mẫu
INSERT INTO Users (user_id, username, created_at) VALUES
(1, 'alice', '2025-01-01 10:00:00'),
(2, 'bob', '2025-02-01 11:00:00'),
(3, 'carol', '2025-03-01 12:00:00');

INSERT INTO Posts (post_id, user_id, content, created_at, likes, hashtags) VALUES
(1, 1, 'Hello world! #intro', '2025-07-11 08:00:00', 5, 'intro'),
(2, 2, 'Workout tips #fitness', '2025-07-11 09:00:00', 15, 'fitness'),
(3, 3, 'Travel blog #travel', '2025-07-10 14:00:00', 10, 'travel');

INSERT INTO Follows (follower_id, followee_id) VALUES
(1, 2), (2, 3), (3, 1);

INSERT INTO PostViews (view_id, post_id, viewer_id, view_time) VALUES
(1, 1, 2, '2025-07-11 10:00:00'),
(2, 2, 1, '2025-07-11 11:00:00'),
(3, 3, 1, '2025-07-10 15:30:00');

-- ✅ Tạo bảng UserLikes
    CREATE TABLE UserLikes (
    user_id INT,
    post_id INT,
    liked_at DATETIME,
    PRIMARY KEY (user_id, post_id)
    );



-- ✅ 1. Truy vấn top 10 bài viết được thích hôm nay
SELECT post_id, user_id, content, likes
FROM Posts
WHERE DATE(created_at) = CURRENT_DATE()
ORDER BY likes DESC
LIMIT 10;

-- Optional: MEMORY table để cache
-- TEXT không được hỗ trợ trong MEMORY, cần chuyển sang VARCHAR
CREATE TABLE TopPostsToday (
  post_id INT PRIMARY KEY,
  user_id INT,
  content VARCHAR(1000),
  likes INT
) ENGINE=MEMORY;

INSERT INTO TopPostsToday
SELECT post_id, user_id, LEFT(content, 1000), likes
FROM Posts
WHERE DATE(created_at) = CURRENT_DATE()
ORDER BY likes DESC
LIMIT 10;

-- ✅ 2. EXPLAIN ANALYZE với LIKE
EXPLAIN ANALYZE
SELECT *
FROM Posts
WHERE hashtags LIKE '%fitness%'
ORDER BY created_at DESC
LIMIT 20;

-- Cải tiến với FULLTEXT
ALTER TABLE Posts ADD FULLTEXT idx_tags (hashtags);
SELECT *
FROM Posts
WHERE MATCH(hashtags) AGAINST('fitness' IN NATURAL LANGUAGE MODE)
ORDER BY created_at DESC
LIMIT 20;

-- ✅ 3. Phân vùng PostViews theo tháng

-- Ví dụ tạo bảng mới không có FK:
CREATE TABLE PostViews_Stat (
  view_id INT,
  post_id INT,
  viewer_id INT,
  view_time TIMESTAMP,
  view_yyyymm INT,
  PRIMARY KEY (view_yyyymm, view_id)
)
PARTITION BY RANGE (view_yyyymm) (
  PARTITION p202501 VALUES LESS THAN (202502),
  PARTITION p202502 VALUES LESS THAN (202503),
  PARTITION p202503 VALUES LESS THAN (202504),
  PARTITION pMAX VALUES LESS THAN MAXVALUE
);

-- Truy vấn số lượt xem mỗi tháng gần đây
SELECT
  DATE_FORMAT(view_time, '%Y-%m') AS ym,
  COUNT(*) AS views
FROM PostViews
WHERE view_time >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY ym
ORDER BY ym DESC;

-- ✅ 4. Chuẩn hóa bảng hashtag
CREATE TABLE Hashtags (
  hashtag_id INT AUTO_INCREMENT PRIMARY KEY,
  tag VARCHAR(100) UNIQUE
);

CREATE TABLE PostHashtags (
  post_id INT,
  hashtag_id INT,
  PRIMARY KEY (post_id, hashtag_id),
  FOREIGN KEY (hashtag_id) REFERENCES Hashtags(hashtag_id)
);

-- Phi chuẩn hóa bảng dashboard
CREATE TABLE PopularPostsDaily (
  dt DATE,
  post_id INT,
  likes INT,
  views INT,
  PRIMARY KEY (dt, post_id)
);

-- ✅ 5. Tối ưu kiểu dữ liệu
-- Đổi view_id BIGINT -> INT UNSIGNED nếu < 2 tỷ
-- hashtags VARCHAR(255) -> VARCHAR(100)
-- created_at DATETIME -> TIMESTAMP nếu không cần xa hơn năm 1970

-- ✅ 6. Window function: top 3 bài viết mỗi ngày
WITH DailyViews AS (
  SELECT
    post_id,
    DATE(view_time) AS view_date,
    COUNT(*) AS cnt_views
  FROM PostViews
  GROUP BY post_id, view_date
)
SELECT post_id, view_date, cnt_views, rnk FROM (
  SELECT post_id, view_date, cnt_views,
         RANK() OVER (PARTITION BY view_date ORDER BY cnt_views DESC) AS rnk
  FROM DailyViews
) t
WHERE rnk <= 3;
-- ✅ 7. Stored Procedure cập nhật lượt thích bài viết
DELIMITER $$
CREATE PROCEDURE sp_like_post(IN p_user_id INT, IN p_post_id INT)
BEGIN
  START TRANSACTION;

  -- Kiểm tra nếu user chưa like post
  IF NOT EXISTS (
    SELECT 1 FROM UserLikes
    WHERE user_id = p_user_id AND post_id = p_post_id
  ) THEN
    -- Thêm vào bảng UserLikes
    INSERT INTO UserLikes(user_id, post_id, liked_at)
    VALUES (p_user_id, p_post_id, NOW());

    -- Cập nhật lượt like trong bảng Posts
    UPDATE Posts
    SET likes = likes + 1
    WHERE post_id = p_post_id;
  END IF;

  COMMIT;
END$$
DELIMITER ;

SELECT * FROM UserLikes;
SELECT post_id, likes FROM Posts WHERE post_id = 2;

-- Ví dụ: Người dùng ID 1 like bài viết ID 2
CALL sp_like_post(1, 2);

-- ✅ 8. Bật slow query log và phân tích
-- Chạy 1 lần trong MySQL CLI:
SET GLOBAL slow_query_log = 1;
SET GLOBAL long_query_time = 1; -- log nếu > 1 giây
SHOW VARIABLES LIKE 'slow_query_log_file';

-- Truy vấn chậm ví dụ
SELECT * FROM Posts
WHERE user_id = 1234 AND content LIKE '%hike%'
ORDER BY created_at DESC;

-- Cải tiến: FULLTEXT
ALTER TABLE Posts ADD FULLTEXT(content);
SELECT * FROM Posts
WHERE user_id = 1234 AND MATCH(content) AGAINST('hike')
ORDER BY created_at DESC
LIMIT 20;

-- ✅ 9. OPTIMIZER_TRACE
-- Bật theo dõi truy vấn tối ưu hóa cho session hiện tại
SET SESSION optimizer_trace = 'enabled=on';
SET SESSION optimizer_trace_max_mem_size = 1000000;

-- Truy vấn cần theo dõi hiệu suất
SELECT p.post_id, u.username, COUNT(v.view_id) AS views
FROM Posts p
JOIN Users u ON p.user_id = u.user_id
LEFT JOIN PostViews v ON v.post_id = p.post_id
WHERE p.created_at >= CURDATE() - INTERVAL 7 DAY
GROUP BY p.post_id
ORDER BY views DESC
LIMIT 25;

-- Xem kết quả phân tích truy vấn (dưới dạng JSON)
SELECT TRACE 
FROM INFORMATION_SCHEMA.OPTIMIZER_TRACE;

