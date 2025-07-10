

-- 1. TẠO BẢNG


-- DỮ LIỆU MẪU

-- Accounts
INSERT INTO Accounts (account_id, full_name, balance, status) VALUES
    (1, 'Nguyen Van A', 10000.00, 'Active'),
    (2, 'Tran Thi B', 5000.00, 'Active'),
    (3, 'Le Van C', 2000.00, 'Frozen'),
    (4, 'Pham Thi D', 0.00, 'Closed');

-- Transactions
INSERT INTO Transactions (from_account, to_account, amount, txn_date, status) VALUES
    (1, 2, 1000.00, '2024-06-01 09:00:00', 'Success'),
    (2, 1, 500.00, '2024-06-01 10:00:00', 'Success'),
    (1, 3, 200.00, '2024-06-02 08:30:00', 'Failed'),
    (2, 4, 100.00, '2024-06-02 11:00:00', 'Success');

-- TxnAuditLogs
INSERT INTO TxnAuditLogs (txn_detail, log_time) VALUES
    ('Transfer success: 1 -> 2, Amount: 1000.00', '2024-06-01 09:00:01'),
    ('Transfer success: 2 -> 1, Amount: 500.00', '2024-06-01 10:00:01'),
    ('Transfer failed: 1 -> 3, Amount: 200.00', '2024-06-02 08:30:01'),
    ('Transfer success: 2 -> 4, Amount: 100.00', '2024-06-02 11:00:01');

-- Referrals
INSERT INTO Referrals (referrer_id, referee_id) VALUES
    (1, 2),
    (1, 3),
    (2, 4),
    (3, 5),
    (5, 6);

-- Bảng Accounts (InnoDB)
CREATE TABLE IF NOT EXISTS Accounts (
    account_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    balance DECIMAL(15, 2),
    status VARCHAR(20)
) ENGINE = InnoDB;

-- Bảng Transactions (InnoDB)
CREATE TABLE IF NOT EXISTS Transactions (
    txn_id INT AUTO_INCREMENT PRIMARY KEY,
    from_account INT,
    to_account INT,
    amount DECIMAL(15, 2),
    txn_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20),
    FOREIGN KEY (from_account) REFERENCES Accounts(account_id),
    FOREIGN KEY (to_account) REFERENCES Accounts(account_id)
) ENGINE = InnoDB;

-- Bảng TxnAuditLogs (MyISAM)
CREATE TABLE IF NOT EXISTS TxnAuditLogs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    txn_detail TEXT,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE = MyISAM;

-- Bảng Referrals (cho CTE đệ quy)
CREATE TABLE IF NOT EXISTS Referrals (
    referrer_id INT,
    referee_id INT
);

-- 2. STORED PROCEDURE CHUYỂN TIỀN

DELIMITER $$

DROP PROCEDURE IF EXISTS TransferMoney $$

CREATE PROCEDURE TransferMoney (
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(15,2)
)
BEGIN
    DECLARE v_from_balance DECIMAL(15,2);
    DECLARE v_status_from VARCHAR(20);
    DECLARE v_status_to VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        INSERT INTO TxnAuditLogs (txn_detail)
        VALUES (CONCAT('Transfer failed: ', p_from_account, ' -> ', p_to_account, ', Amount: ', p_amount));
    END;

    START TRANSACTION;

    -- Lock theo thứ tự để chống deadlock
    SELECT balance, status INTO v_from_balance, v_status_from
    FROM Accounts
    WHERE account_id = p_from_account
    FOR UPDATE;

    SELECT status INTO v_status_to
    FROM Accounts
    WHERE account_id = p_to_account
    FOR UPDATE;

    IF v_status_from != 'Active' OR v_status_to != 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'One or both accounts are not active';
    END IF;

    IF v_from_balance < p_amount THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;

    UPDATE Accounts SET balance = balance - p_amount WHERE account_id = p_from_account;
    UPDATE Accounts SET balance = balance + p_amount WHERE account_id = p_to_account;

    INSERT INTO Transactions (from_account, to_account, amount, txn_date, status)
    VALUES (p_from_account, p_to_account, p_amount, NOW(), 'Success');

    INSERT INTO TxnAuditLogs (txn_detail)
    VALUES (CONCAT('Transfer success: ', p_from_account, ' -> ', p_to_account, ', Amount: ', p_amount));

    COMMIT;
END$$

DELIMITER ;


-- 3. MVCC – Multi-Version Concurrency Control


-- 🔹 Session 1: Đọc số dư trong Transaction
START TRANSACTION;

SELECT 
    account_id, 
    full_name, 
    balance 
FROM Accounts 
WHERE account_id = 1;

-- Không COMMIT, giữ nguyên transaction để quan sát hiệu ứng snapshot

-- 🔹 Session 2 (mở ở tab khác hoặc cửa sổ khác):
-- Chuyển tiền từ account_id = 1 sang 2
CALL TransferMoney(1, 2, 100.00);

-- 🔹 Quay lại Session 1:
-- Kiểm tra lại số dư vẫn là bản cũ (ảnh chụp ban đầu)
SELECT 
    account_id, 
    balance 
FROM Accounts 
WHERE account_id = 1;

-- Kết thúc Transaction
COMMIT;


-- 4. COMMON TABLE EXPRESSIONS

-- a. CTE đệ quy: lấy tất cả cấp dưới nhiều tầng
    WITH RECURSIVE Downlines AS (
        SELECT referee_id, referrer_id, 1 AS level
        FROM Referrals
        WHERE referrer_id = 1 -- Khách gốc

        UNION ALL

        SELECT r.referee_id, r.referrer_id, d.level + 1
        FROM Referrals r
        JOIN Downlines d ON r.referrer_id = d.referee_id
    )
    SELECT * FROM Downlines;

-- b. CTE phân tích giao dịch
WITH AvgAmount AS (
    SELECT AVG(amount) AS avg_amt FROM Transactions
),
LabeledTransactions AS (
    SELECT 
        txn_id,
        from_account,
        to_account,
        amount,
        txn_date,
        status,
        CASE 
            WHEN amount > (SELECT avg_amt FROM AvgAmount) THEN 'High'
            WHEN amount = (SELECT avg_amt FROM AvgAmount) THEN 'Normal'
            ELSE 'Low'
        END AS amount_label
    FROM Transactions
)
SELECT * FROM LabeledTransactions;

