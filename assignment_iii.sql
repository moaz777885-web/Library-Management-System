-- =====================================================================
-- ASSIGNMENT III: SQL TABLE MANIPULATION
-- Student     : Moaz Mohammed Yacoub
-- Student ID  : 202510648
-- Institution : Kigali Independent University (ULK)
-- DBMS        : MySQL 8.0+
-- Project     : Library Management System
-- Database    : moaz_202510648_library_system
--
-- EXECUTION STAGES (see README / guide):
--   Stage A: Sections 1-7  (create, insert, SELECT, JOIN, UPDATE)
--   >>> PAUSE: generate erd.png from MySQL Workbench <<<
--   Stage B: Sections 8-10 (ALTER TABLE, extra INSERT, final check)
-- The whole file can also be run top-to-bottom on a fresh server.
-- =====================================================================


-- =====================================================================
-- SECTION 1: DATABASE CREATION
-- =====================================================================
-- Objective: Create a fresh database that follows yourname_studentid_projectname.
-- DROP makes the script re-runnable from the beginning (it deletes the
-- old copy of THIS database only).
DROP DATABASE IF EXISTS moaz_202510648_library_system;

CREATE DATABASE moaz_202510648_library_system
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE moaz_202510648_library_system;


-- =====================================================================
-- SECTION 2: TABLE CREATION AND CONSTRAINTS
-- Parent tables first (students, books), child table last (borrowings).
-- =====================================================================

-- Parent table 1: students (one student can have many borrowings)
CREATE TABLE students (
    student_id        INT          NOT NULL AUTO_INCREMENT,
    full_name         VARCHAR(100) NOT NULL,
    email             VARCHAR(100) NOT NULL,
    phone             VARCHAR(15),
    faculty           VARCHAR(80)  NOT NULL,
    registration_date DATE         NOT NULL,
    membership_status VARCHAR(10)  NOT NULL DEFAULT 'Active',
    CONSTRAINT pk_students PRIMARY KEY (student_id),
    CONSTRAINT uq_students_email UNIQUE (email),
    CONSTRAINT chk_students_status CHECK (membership_status IN ('Active', 'Suspended'))
) ENGINE = InnoDB;

-- Parent table 2: books (one book can appear in many borrowings)
CREATE TABLE books (
    book_id          INT          NOT NULL AUTO_INCREMENT,
    isbn             VARCHAR(20)  NOT NULL,
    title            VARCHAR(150) NOT NULL,
    author           VARCHAR(100) NOT NULL,
    category         VARCHAR(50)  NOT NULL,
    publication_year SMALLINT     NOT NULL,
    copies_total     SMALLINT     NOT NULL DEFAULT 1,
    CONSTRAINT pk_books PRIMARY KEY (book_id),
    CONSTRAINT uq_books_isbn UNIQUE (isbn),
    CONSTRAINT chk_books_year CHECK (publication_year BETWEEN 1000 AND 2100)
) ENGINE = InnoDB;

-- Child table: borrowings (each row links ONE student to ONE book)
CREATE TABLE borrowings (
    borrowing_id INT         NOT NULL AUTO_INCREMENT,
    student_id   INT         NOT NULL,
    book_id      INT         NOT NULL,
    borrow_date  DATE        NOT NULL,
    due_date     DATE        NOT NULL,
    return_date  DATE        NULL,
    status       VARCHAR(10) NOT NULL DEFAULT 'Borrowed',
    CONSTRAINT pk_borrowings PRIMARY KEY (borrowing_id),
    CONSTRAINT fk_borrowings_student FOREIGN KEY (student_id)
        REFERENCES students (student_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_borrowings_book FOREIGN KEY (book_id)
        REFERENCES books (book_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_borrowings_dates CHECK (due_date >= borrow_date),
    CONSTRAINT chk_borrowings_status CHECK (status IN ('Borrowed', 'Returned', 'Overdue'))
) ENGINE = InnoDB;

-- Verify the structure
SHOW TABLES;
DESCRIBE students;
DESCRIBE books;
DESCRIBE borrowings;


-- =====================================================================
-- SECTION 3: INITIAL DATA INSERTION
-- Rule: primary keys (student_id, book_id, borrowing_id) are NOT listed;
-- MySQL generates them with AUTO_INCREMENT.
-- Order: parents (students, books) first, then child (borrowings).
-- =====================================================================

-- 3.1 Students (6 records)
INSERT INTO students (full_name, email, phone, faculty, registration_date, membership_status)
VALUES
    ('Alice Uwase',           'alice.uwase@example.com',          '0788100001', 'Information Technology', '2025-09-15', 'Active'),
    ('Eric Habimana',         'eric.habimana@example.com',        '0788100002', 'Business Administration', '2025-09-16', 'Active'),
    ('Grace Mukamana',        'grace.mukamana@example.com',       '0788100003', 'Law',                     '2025-10-01', 'Active'),
    ('Jean Claude Niyonzima', 'jc.niyonzima@example.com',         '0788100004', 'Education',               '2025-10-05', 'Active'),
    ('Diane Ingabire',        'diane.ingabire@example.com',       '0788100005', 'Information Technology',  '2025-10-12', 'Active'),
    ('Patrick Nshimiyimana',  'patrick.nshimiyimana@example.com', '0788100006', 'Business Administration', '2026-01-20', 'Active');

-- 3.2 Books (6 records)
INSERT INTO books (isbn, title, author, category, publication_year, copies_total)
VALUES
    ('9780132350884', 'Clean Code',                'Robert C. Martin',    'Programming',      2008, 3),
    ('9780134685991', 'Effective Java',            'Joshua Bloch',        'Programming',      2018, 2),
    ('9780078022159', 'Database System Concepts',  'Abraham Silberschatz','Databases',        2019, 4),
    ('9780262046305', 'Introduction to Algorithms','Thomas H. Cormen',    'Computer Science', 2022, 3),
    ('9780134492513', 'Principles of Marketing',   'Philip Kotler',       'Business',         2017, 2),
    ('9780385474542', 'Things Fall Apart',         'Chinua Achebe',       'Literature',       1958, 5);

-- 3.3 Borrowings (7 records)
-- Foreign keys are found with sub-queries on UNIQUE columns (email, isbn),
-- so we never type generated ID numbers by hand.
INSERT INTO borrowings (student_id, book_id, borrow_date, due_date, return_date, status)
VALUES
    ((SELECT student_id FROM students WHERE email = 'alice.uwase@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780132350884'),
     '2026-09-01', '2026-09-15', '2026-09-12', 'Returned'),
    ((SELECT student_id FROM students WHERE email = 'alice.uwase@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780078022159'),
     '2026-10-01', '2026-10-15', NULL, 'Borrowed'),
    ((SELECT student_id FROM students WHERE email = 'eric.habimana@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780134492513'),
     '2026-09-10', '2026-09-24', '2026-09-30', 'Returned'),
    ((SELECT student_id FROM students WHERE email = 'grace.mukamana@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780385474542'),
     '2026-10-05', '2026-10-19', NULL, 'Borrowed'),
    ((SELECT student_id FROM students WHERE email = 'jc.niyonzima@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780134685991'),
     '2026-10-10', '2026-10-24', NULL, 'Borrowed'),
    ((SELECT student_id FROM students WHERE email = 'diane.ingabire@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780262046305'),
     '2026-10-12', '2026-10-26', NULL, 'Borrowed'),
    ((SELECT student_id FROM students WHERE email = 'diane.ingabire@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780132350884'),
     '2026-09-20', '2026-10-04', '2026-10-02', 'Returned');


-- =====================================================================
-- SECTION 4: VERIFICATION OF INITIAL DATA
-- Expected: students = 6, books = 6, borrowings = 7
-- =====================================================================
SELECT 'students'   AS table_name, COUNT(*) AS total_records FROM students
UNION ALL
SELECT 'books',      COUNT(*) FROM books
UNION ALL
SELECT 'borrowings', COUNT(*) FROM borrowings;

-- Confirm AUTO_INCREMENT keys and foreign keys work together
SELECT * FROM students;
SELECT * FROM books;
SELECT * FROM borrowings;

-- Optional constraint test (run ONE line at a time; each SHOULD FAIL):
-- INSERT INTO borrowings (student_id, book_id, borrow_date, due_date)
--   VALUES (999, 1, '2026-10-01', '2026-10-15');   -- Error 1452: no student 999
-- INSERT INTO students (full_name, email, faculty, registration_date)
--   VALUES ('Duplicate', 'alice.uwase@example.com', 'Law', '2026-10-01'); -- Error 1062: duplicate email


-- =====================================================================
-- SECTION 5: SELECT TASKS (CATEGORY 1)
-- =====================================================================

-- Q1.1: Basic Data Retrieval
-- Objective: Show the name, email and faculty of every registered student.
SELECT full_name, email, faculty
FROM students;

-- Q1.2: Conditional Data Retrieval
-- Objective: List books published in 2018 or later (recent books).
SELECT title, author, publication_year
FROM books
WHERE publication_year >= 2018;

-- Q1.3: Sorted Data Retrieval
-- Objective: List all books from newest to oldest.
SELECT title, author, publication_year
FROM books
ORDER BY publication_year DESC;


-- =====================================================================
-- SECTION 6: JOIN TASKS (CATEGORY 2)
-- =====================================================================

-- Q2.1: INNER JOIN
-- Objective: Show each borrowing together with the name of the student who made it.
SELECT s.full_name, b.borrowing_id, b.borrow_date, b.due_date, b.status
FROM students AS s
INNER JOIN borrowings AS b ON s.student_id = b.student_id
ORDER BY b.borrowing_id;

-- Q2.2: LEFT JOIN
-- Objective: List ALL students, with their borrowings if they have any.
-- Patrick Nshimiyimana has no borrowings, so his borrowing columns show NULL.
SELECT s.student_id, s.full_name, b.borrowing_id, b.status
FROM students AS s
LEFT JOIN borrowings AS b ON s.student_id = b.student_id
ORDER BY s.student_id, b.borrowing_id;

-- Q2.3: Multi-Table JOIN (students + borrowings + books)
-- Objective: Library report: who borrowed which book, when, and return status.
SELECT s.full_name,
       bk.title,
       br.borrow_date,
       br.due_date,
       br.return_date,
       CASE WHEN br.return_date IS NULL THEN 'Not yet returned'
            ELSE 'Returned' END AS return_status
FROM borrowings AS br
INNER JOIN students AS s  ON br.student_id = s.student_id
INNER JOIN books    AS bk ON br.book_id    = bk.book_id
ORDER BY br.borrowing_id;


-- =====================================================================
-- SECTION 7: UPDATE TASKS AND VERIFICATION (CATEGORY 3)
-- MySQL Workbench "Safe Updates" blocks UPDATEs whose WHERE does not use
-- a key column (Error 1175). We switch it off for this section only,
-- and every UPDATE below still has a precise WHERE condition.
-- =====================================================================
SET SQL_SAFE_UPDATES = 0;

-- Q3.1: Update One Record
-- Objective: Change Grace Mukamana's phone number.
-- Step 1: identify the record (BEFORE)
SELECT student_id, full_name, email, phone
FROM students
WHERE email = 'grace.mukamana@example.com';
-- Step 2: update
UPDATE students
SET phone = '0788200003'
WHERE email = 'grace.mukamana@example.com';
-- Step 3: verify (AFTER)
SELECT student_id, full_name, email, phone
FROM students
WHERE email = 'grace.mukamana@example.com';

-- Q3.2: Update Multiple Records
-- Objective: Standardise the category name: 'Programming' -> 'Computer Science'.
-- Step 1: identify the records (BEFORE)
SELECT book_id, title, category
FROM books
WHERE category = 'Programming';
-- Step 2: update
UPDATE books
SET category = 'Computer Science'
WHERE category = 'Programming';
-- Step 3: verify (AFTER)
SELECT book_id, title, category
FROM books
WHERE category = 'Computer Science'
ORDER BY book_id;

-- Q3.3: Conditional Update (business rule)
-- Rule: a book that is still 'Borrowed', has no return date, and whose due
-- date is before 2026-10-20 is marked 'Overdue'.
-- (A fixed review date is used so the result is the same every time.)
-- Step 1: identify the records (BEFORE)
SELECT borrowing_id, student_id, book_id, due_date, return_date, status
FROM borrowings
WHERE status = 'Borrowed'
  AND return_date IS NULL
  AND due_date < '2026-10-20';
-- Step 2: update
UPDATE borrowings
SET status = 'Overdue'
WHERE status = 'Borrowed'
  AND return_date IS NULL
  AND due_date < '2026-10-20';
-- Step 3: verify (AFTER)
SELECT borrowing_id, due_date, return_date, status
FROM borrowings
ORDER BY borrowing_id;

SET SQL_SAFE_UPDATES = 1;


-- =====================================================================
-- >>> PAUSE POINT: Generate the ERD NOW (before any ALTER TABLE) <<<
-- MySQL Workbench: Database > Reverse Engineer... > choose
-- moaz_202510648_library_system > finish > File > Export > Export as PNG
-- Save as erd.png. Then continue with Section 8.
-- =====================================================================


-- =====================================================================
-- SECTION 8: ALTER TABLE TASKS AND VERIFICATION (CATEGORY 4)
-- Order matters: 4.1 renames students.faculty -> department, so every
-- later statement uses 'department'.
-- =====================================================================

-- Q4.1: Rename a Column
-- Objective: Rename students.faculty to students.department.
ALTER TABLE students
    RENAME COLUMN faculty TO department;
-- Verify the new name and that the data is still there
DESCRIBE students;
SELECT full_name, department FROM students;

-- Q4.2: Change a Column's Data Type
-- Objective: Widen books.copies_total from SMALLINT to INT (safe: every
-- SMALLINT value fits in INT, so no data is lost).
ALTER TABLE books
    MODIFY COLUMN copies_total INT NOT NULL DEFAULT 1;
-- Verify the new type and that values are unchanged
SELECT COLUMN_NAME, DATA_TYPE, COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'moaz_202510648_library_system'
  AND TABLE_NAME = 'books'
  AND COLUMN_NAME = 'copies_total';
SELECT book_id, title, copies_total FROM books ORDER BY book_id;

-- Q4.3: Add a Column
-- Objective: Add books.shelf_location so librarians know where a book is kept.
-- It allows NULL because existing books have no location recorded yet.
ALTER TABLE books
    ADD COLUMN shelf_location VARCHAR(20) NULL AFTER category;
-- Verify the new structure
DESCRIBE books;
SELECT book_id, title, shelf_location FROM books ORDER BY book_id;


-- =====================================================================
-- SECTION 9: ADDITIONAL INSERT TASKS AND VERIFICATION (CATEGORY 5)
-- These use the FINAL schema (students.department, books.shelf_location).
-- =====================================================================

-- Q5.1: Insert a Single Record
-- Objective: Register one new student.
INSERT INTO students (full_name, email, phone, department, registration_date)
VALUES ('Claudine Uwimana', 'claudine.uwimana@example.com', '0788100007', 'Law', '2026-10-22');
-- Verify (membership_status should have received its DEFAULT 'Active')
SELECT student_id, full_name, email, department, membership_status
FROM students
WHERE email = 'claudine.uwimana@example.com';

-- Q5.2: Insert Multiple Records
-- Objective: Add three new books with ONE multi-row INSERT.
INSERT INTO books (isbn, title, author, category, shelf_location, publication_year, copies_total)
VALUES
    ('9781119800361', 'Operating System Concepts', 'Abraham Silberschatz', 'Computer Science', 'CS-02',  2021, 3),
    ('9780596517748', 'JavaScript: The Good Parts', 'Douglas Crockford',   'Computer Science', 'CS-03',  2008, 2),
    ('9780307887894', 'The Lean Startup',           'Eric Ries',           'Business',         'BUS-01', 2011, 2);
-- Verify
SELECT book_id, isbn, title, category, shelf_location
FROM books
WHERE isbn IN ('9781119800361', '9780596517748', '9780307887894')
ORDER BY book_id;

-- Q5.3: Insert a Related Record
-- Objective: Claudine (new student) borrows Operating System Concepts.
-- The foreign keys are looked up from EXISTING parent rows.
INSERT INTO borrowings (student_id, book_id, borrow_date, due_date, return_date, status)
VALUES (
    (SELECT student_id FROM students WHERE email = 'claudine.uwimana@example.com'),
    (SELECT book_id FROM books WHERE isbn = '9781119800361'),
    '2026-10-23', '2026-11-06', NULL, 'Borrowed'
);
-- Verify the new row and its parents with a JOIN
SELECT br.borrowing_id, s.full_name, bk.title, br.borrow_date, br.due_date, br.status
FROM borrowings AS br
INNER JOIN students AS s  ON br.student_id = s.student_id
INNER JOIN books    AS bk ON br.book_id    = bk.book_id
WHERE s.email = 'claudine.uwimana@example.com';


-- =====================================================================
-- SECTION 10: FINAL CHECK
-- Expected: students = 7, books = 9, borrowings = 8
-- =====================================================================
SELECT 'students'   AS table_name, COUNT(*) AS total_records FROM students
UNION ALL
SELECT 'books',      COUNT(*) FROM books
UNION ALL
SELECT 'borrowings', COUNT(*) FROM borrowings;
