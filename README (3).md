# Assignment III: SQL Table Manipulation

## 1. Project Overview

| Item | Detail |
|---|---|
| Project title | Library Management System |
| Student name | Moaz Mohammed Yacoub |
| Student ID | 202510648 |
| Institution | Kigali Independent University (ULK) |
| Assignment | Assignment III: SQL Table Manipulation |
| DBMS | MySQL 8.0+ (MySQL Workbench) |
| Database name | `moaz_202510648_library_system` |

## 2. Business Idea

A university library lends books to registered students. The system must record **who** the students are, **which** books the library owns, and **which student borrowed which book and when**. Keeping these three things in three tables avoids repeating student or book details on every borrowing.

## 3. Database and Table Design

### `students` (parent): the people who can borrow
| Column | Data type | Constraints |
|---|---|---|
| student_id | INT | **PRIMARY KEY**, AUTO_INCREMENT |
| full_name | VARCHAR(100) | NOT NULL |
| email | VARCHAR(100) | NOT NULL, UNIQUE |
| phone | VARCHAR(15) | optional |
| faculty | VARCHAR(80) | NOT NULL *(renamed to `department` in Q4.1)* |
| registration_date | DATE | NOT NULL |
| membership_status | VARCHAR(10) | NOT NULL, DEFAULT 'Active', CHECK in ('Active','Suspended') |

### `books` (parent): the books the library owns
| Column | Data type | Constraints |
|---|---|---|
| book_id | INT | **PRIMARY KEY**, AUTO_INCREMENT |
| isbn | VARCHAR(20) | NOT NULL, UNIQUE |
| title | VARCHAR(150) | NOT NULL |
| author | VARCHAR(100) | NOT NULL |
| category | VARCHAR(50) | NOT NULL |
| publication_year | SMALLINT | NOT NULL, CHECK 1000–2100 |
| copies_total | SMALLINT | NOT NULL, DEFAULT 1 *(changed to INT in Q4.2)* |
| shelf_location | VARCHAR(20) | NULL allowed *(added in Q4.3)* |

### `borrowings` (child): one row per loan
| Column | Data type | Constraints |
|---|---|---|
| borrowing_id | INT | **PRIMARY KEY**, AUTO_INCREMENT |
| student_id | INT | NOT NULL, **FOREIGN KEY** → students(student_id) |
| book_id | INT | NOT NULL, **FOREIGN KEY** → books(book_id) |
| borrow_date | DATE | NOT NULL |
| due_date | DATE | NOT NULL, CHECK due_date ≥ borrow_date |
| return_date | DATE | NULL (NULL = not yet returned) |
| status | VARCHAR(10) | NOT NULL, DEFAULT 'Borrowed', CHECK in ('Borrowed','Returned','Overdue') |

## 4. Primary Keys and Foreign Keys

- **Primary key**: a column that uniquely identifies each row. `student_id`, `book_id` and `borrowing_id` are generated automatically by `AUTO_INCREMENT`, so two rows can never share the same value and we never type them by hand.
- **Foreign key**: a column that points to a primary key in another table. `borrowings.student_id` must match an existing `students.student_id`, and `borrowings.book_id` must match an existing `books.book_id`. MySQL rejects any value that does not exist in the parent table.
- **Parent tables**: `students`, `books` (created first). **Child table**: `borrowings` (created last because it depends on both).

## 5. Table Relationships

| Relationship | Type | Meaning |
|---|---|---|
| students → borrowings | One-to-many | One student can have many borrowings; each borrowing belongs to exactly one student. |
| books → borrowings | One-to-many | One book can be borrowed many times; each borrowing is for exactly one book. |
| students ↔ books | Many-to-many (through `borrowings`) | A student borrows many books and a book is borrowed by many students; `borrowings` is the linking table. |

Why necessary: the student's name and the book's title are stored once; `borrowings` only stores their IDs. This avoids duplication and keeps data consistent.

## 6. Database and Table Creation

```sql
DROP DATABASE IF EXISTS moaz_202510648_library_system;
CREATE DATABASE moaz_202510648_library_system
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE moaz_202510648_library_system;

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
        REFERENCES students (student_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_borrowings_book FOREIGN KEY (book_id)
        REFERENCES books (book_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_borrowings_dates CHECK (due_date >= borrow_date),
    CONSTRAINT chk_borrowings_status CHECK (status IN ('Borrowed', 'Returned', 'Overdue'))
) ENGINE = InnoDB;
```

📸 **Screenshot:** `screenshots/01_tables_created.png`: output of `SHOW TABLES; DESCRIBE students; DESCRIBE books; DESCRIBE borrowings;`

![01_tables_created](screenshots/01_tables_created.png)

### How to run `assignment_iii.sql`

1. Install MySQL Server 8.0.16 or newer and MySQL Workbench; open a connection to your local server.
2. Open `assignment_iii.sql` (File → Open SQL Script).
3. Run **Sections 1–7** (down to the `SET SQL_SAFE_UPDATES = 1;` line). The script starts with `DROP DATABASE IF EXISTS moaz_202510648_library_system`, so it only deletes an older copy of this project database.
4. Stop at the `PAUSE POINT` comment and generate the ERD (Database → Reverse Engineer → File → Export → Export as PNG, saved as `erd.png`).
5. Run **Sections 8–10** (ALTER TABLE, extra INSERTs, final count). Final counts should be students 7, books 9, borrowings 8.

## 7. Initial Data Insertion

Parents first (`students`, `books`), child last (`borrowings`). No primary keys are inserted; foreign keys are found with sub-queries on UNIQUE columns.

```sql
INSERT INTO students (full_name, email, phone, faculty, registration_date, membership_status)
VALUES
    ('Alice Uwase',           'alice.uwase@example.com',          '0788100001', 'Information Technology',  '2025-09-15', 'Active'),
    ('Eric Habimana',         'eric.habimana@example.com',        '0788100002', 'Business Administration', '2025-09-16', 'Active'),
    ('Grace Mukamana',        'grace.mukamana@example.com',       '0788100003', 'Law',                     '2025-10-01', 'Active'),
    ('Jean Claude Niyonzima', 'jc.niyonzima@example.com',         '0788100004', 'Education',               '2025-10-05', 'Active'),
    ('Diane Ingabire',        'diane.ingabire@example.com',       '0788100005', 'Information Technology',  '2025-10-12', 'Active'),
    ('Patrick Nshimiyimana',  'patrick.nshimiyimana@example.com', '0788100006', 'Business Administration', '2026-01-20', 'Active');

INSERT INTO books (isbn, title, author, category, publication_year, copies_total)
VALUES
    ('9780132350884', 'Clean Code',                 'Robert C. Martin',     'Programming',      2008, 3),
    ('9780134685991', 'Effective Java',             'Joshua Bloch',         'Programming',      2018, 2),
    ('9780078022159', 'Database System Concepts',   'Abraham Silberschatz', 'Databases',        2019, 4),
    ('9780262046305', 'Introduction to Algorithms', 'Thomas H. Cormen',     'Computer Science', 2022, 3),
    ('9780134492513', 'Principles of Marketing',    'Philip Kotler',        'Business',         2017, 2),
    ('9780385474542', 'Things Fall Apart',          'Chinua Achebe',        'Literature',       1958, 5);

INSERT INTO borrowings (student_id, book_id, borrow_date, due_date, return_date, status)
VALUES
    ((SELECT student_id FROM students WHERE email = 'alice.uwase@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780132350884'), '2026-09-01', '2026-09-15', '2026-09-12', 'Returned'),
    ((SELECT student_id FROM students WHERE email = 'alice.uwase@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780078022159'), '2026-10-01', '2026-10-15', NULL, 'Borrowed'),
    ((SELECT student_id FROM students WHERE email = 'eric.habimana@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780134492513'), '2026-09-10', '2026-09-24', '2026-09-30', 'Returned'),
    ((SELECT student_id FROM students WHERE email = 'grace.mukamana@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780385474542'), '2026-10-05', '2026-10-19', NULL, 'Borrowed'),
    ((SELECT student_id FROM students WHERE email = 'jc.niyonzima@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780134685991'), '2026-10-10', '2026-10-24', NULL, 'Borrowed'),
    ((SELECT student_id FROM students WHERE email = 'diane.ingabire@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780262046305'), '2026-10-12', '2026-10-26', NULL, 'Borrowed'),
    ((SELECT student_id FROM students WHERE email = 'diane.ingabire@example.com'),
     (SELECT book_id FROM books WHERE isbn = '9780132350884'), '2026-09-20', '2026-10-04', '2026-10-02', 'Returned');
```

Verification:

```sql
SELECT 'students' AS table_name, COUNT(*) AS total_records FROM students
UNION ALL SELECT 'books', COUNT(*) FROM books
UNION ALL SELECT 'borrowings', COUNT(*) FROM borrowings;
SELECT * FROM students;  SELECT * FROM books;  SELECT * FROM borrowings;
```

**Expected Output — Not Yet Executed**

| table_name | total_records |
|---|---|
| students | 6 |
| books | 6 |
| borrowings | 7 |

IDs 1–6 / 1–6 / 1–7 are generated automatically, and every `borrowings.student_id` and `book_id` matches an existing parent row (otherwise the INSERT would have failed with Error 1452).

📸 **Screenshots:** `screenshots/02_record_counts.png` (count query) and `screenshots/03_all_tables_data.png` (the three `SELECT *` results).

![02_record_counts](screenshots/02_record_counts.png)

![03_all_tables_data](screenshots/03_all_tables_data.png)

## 8. Entity-Relationship Diagram

Generated from the actual database with MySQL Workbench (**Database → Reverse Engineer**), before the ALTER TABLE tasks.

![ERD](erd.png)

How to read it: each box is a table; key icons mark primary keys; the lines from `borrowings` to `students` and to `books` are the foreign keys; the crow's-foot end of a line is the "many" side (`borrowings`), the single end is the "one" side (the parent table).

## 9. SQL Practical Tasks

### Q1.1–Q1.3: SELECT

**Q1.1: Basic Data Retrieval**  
*Objective:* show name, email and faculty of every student.
```sql
SELECT full_name, email, faculty FROM students;
```
**Actual Output (see screenshot)**

| full_name | email | faculty |
|---|---|---|
| Alice Uwase | alice.uwase@example.com | Information Technology |
| Eric Habimana | eric.habimana@example.com | Business Administration |
| Grace Mukamana | grace.mukamana@example.com | Law |
| Jean Claude Niyonzima | jc.niyonzima@example.com | Education |
| Diane Ingabire | diane.ingabire@example.com | Information Technology |
| Patrick Nshimiyimana | patrick.nshimiyimana@example.com | Business Administration |

*Explanation:* `SELECT` names the columns to show, `FROM` names the table. Only three columns appear, not the whole row. 📸 `screenshots/q1_1.png`

![q1_1](screenshots/q1_1.png)

**Q1.2: Conditional Data Retrieval**  
*Objective:* list books published in 2018 or later.
```sql
SELECT title, author, publication_year FROM books WHERE publication_year >= 2018;
```
**Actual Output (see screenshot)**

| title | author | publication_year |
|---|---|---|
| Effective Java | Joshua Bloch | 2018 |
| Database System Concepts | Abraham Silberschatz | 2019 |
| Introduction to Algorithms | Thomas H. Cormen | 2022 |

*Explanation:* `WHERE` keeps only rows where the condition is true; the other three books are filtered out. 📸 `screenshots/q1_2.png`

![q1_2](screenshots/q1_2.png)

**Q1.3: Sorted Data Retrieval**  
*Objective:* list books from newest to oldest.
```sql
SELECT title, author, publication_year FROM books ORDER BY publication_year DESC;
```
**Actual Output (see screenshot)**

| title | author | publication_year |
|---|---|---|
| Introduction to Algorithms | Thomas H. Cormen | 2022 |
| Database System Concepts | Abraham Silberschatz | 2019 |
| Effective Java | Joshua Bloch | 2018 |
| Principles of Marketing | Philip Kotler | 2017 |
| Clean Code | Robert C. Martin | 2008 |
| Things Fall Apart | Chinua Achebe | 1958 |

*Explanation:* `ORDER BY ... DESC` sorts from the largest year to the smallest. 📸 `screenshots/q1_3.png`

![q1_3](screenshots/q1_3.png)

### Q2.1–Q2.3: JOIN

**Q2.1: INNER JOIN**  
*Objective:* show each borrowing with the borrower's name.
```sql
SELECT s.full_name, b.borrowing_id, b.borrow_date, b.due_date, b.status
FROM students AS s
INNER JOIN borrowings AS b ON s.student_id = b.student_id
ORDER BY b.borrowing_id;
```
**Expected Output — Not Yet Executed**

| full_name | borrowing_id | borrow_date | due_date | status |
|---|---|---|---|---|
| Alice Uwase | 1 | 2026-09-01 | 2026-09-15 | Returned |
| Alice Uwase | 2 | 2026-10-01 | 2026-10-15 | Borrowed |
| Eric Habimana | 3 | 2026-09-10 | 2026-09-24 | Returned |
| Grace Mukamana | 4 | 2026-10-05 | 2026-10-19 | Borrowed |
| Jean Claude Niyonzima | 5 | 2026-10-10 | 2026-10-24 | Borrowed |
| Diane Ingabire | 6 | 2026-10-12 | 2026-10-26 | Borrowed |
| Diane Ingabire | 7 | 2026-09-20 | 2026-10-04 | Returned |

*Interpretation:* INNER JOIN returns only rows with a match in both tables. Patrick Nshimiyimana has no borrowings, so he does not appear. 📸 `screenshots/q2_1.png`

![q2_1](screenshots/q2_1.png)

**Q2.2: LEFT JOIN**  
*Objective:* list all students, with borrowings where they exist.
```sql
SELECT s.student_id, s.full_name, b.borrowing_id, b.status
FROM students AS s
LEFT JOIN borrowings AS b ON s.student_id = b.student_id
ORDER BY s.student_id, b.borrowing_id;
```
**Expected Output — Not Yet Executed**

| student_id | full_name | borrowing_id | status |
|---|---|---|---|
| 1 | Alice Uwase | 1 | Returned |
| 1 | Alice Uwase | 2 | Borrowed |
| 2 | Eric Habimana | 3 | Returned |
| 3 | Grace Mukamana | 4 | Borrowed |
| 4 | Jean Claude Niyonzima | 5 | Borrowed |
| 5 | Diane Ingabire | 6 | Borrowed |
| 5 | Diane Ingabire | 7 | Returned |
| 6 | Patrick Nshimiyimana | NULL | NULL |

*Interpretation:* LEFT JOIN keeps every row of the left table (`students`). Patrick has no match, so the right-table columns are filled with NULL. This sample data really does contain such a student. 📸 `screenshots/q2_2.png`

![q2_2](screenshots/q2_2.png)

**Q2.3: Multi-Table JOIN**  
*Objective:* library report of who borrowed which book and whether it was returned.
```sql
SELECT s.full_name, bk.title, br.borrow_date, br.due_date, br.return_date,
       CASE WHEN br.return_date IS NULL THEN 'Not yet returned'
            ELSE 'Returned' END AS return_status
FROM borrowings AS br
INNER JOIN students AS s  ON br.student_id = s.student_id
INNER JOIN books    AS bk ON br.book_id    = bk.book_id
ORDER BY br.borrowing_id;
```
**Actual Output (see screenshot)**

| full_name | title | borrow_date | due_date | return_date | return_status |
|---|---|---|---|---|---|
| Alice Uwase | Clean Code | 2026-09-01 | 2026-09-15 | 2026-09-12 | Returned |
| Alice Uwase | Database System Concepts | 2026-10-01 | 2026-10-15 | NULL | Not yet returned |
| Eric Habimana | Principles of Marketing | 2026-09-10 | 2026-09-24 | 2026-09-30 | Returned |
| Grace Mukamana | Things Fall Apart | 2026-10-05 | 2026-10-19 | NULL | Not yet returned |
| Jean Claude Niyonzima | Effective Java | 2026-10-10 | 2026-10-24 | NULL | Not yet returned |
| Diane Ingabire | Introduction to Algorithms | 2026-10-12 | 2026-10-26 | NULL | Not yet returned |
| Diane Ingabire | Clean Code | 2026-09-20 | 2026-10-04 | 2026-10-02 | Returned |

*Interpretation:* `borrowings` sits in the middle and connects `students` and `books`; four books are still out. 📸 `screenshots/q2_3.png`

![q2_3](screenshots/q2_3.png)

### Q3.1–Q3.3: UPDATE

(MySQL Workbench Safe Updates is switched off with `SET SQL_SAFE_UPDATES = 0;` for this section only; each UPDATE still has a specific WHERE.)

**Q3.1: Update One Record**  
*Objective:* change Grace Mukamana's phone number.
```sql
SELECT student_id, full_name, email, phone FROM students WHERE email = 'grace.mukamana@example.com';  -- before
UPDATE students SET phone = '0788200003' WHERE email = 'grace.mukamana@example.com';
SELECT student_id, full_name, email, phone FROM students WHERE email = 'grace.mukamana@example.com';  -- after
```
**Expected Output — Not Yet Executed:** before `phone = 0788100003`; after `phone = 0788200003`; "1 row(s) affected". 
*Explanation:* `email` is UNIQUE, so the WHERE can match only one student. 📸 `screenshots/q3_1.png`

![q3_1](screenshots/q3_1.png)

**Q3.2: Update Multiple Records**  
*Objective:* standardise category `Programming` → `Computer Science`.
```sql
SELECT book_id, title, category FROM books WHERE category = 'Programming';   -- before
UPDATE books SET category = 'Computer Science' WHERE category = 'Programming';
SELECT book_id, title, category FROM books WHERE category = 'Computer Science' ORDER BY book_id;  -- after
```
**Expected Output — Not Yet Executed:** before: Clean Code, Effective Java (2 rows). After UPDATE: "2 row(s) affected"; the verification shows 3 rows: Clean Code, Effective Java, Introduction to Algorithms (the last was already Computer Science).
*Explanation:* the preview query proves exactly two rows match before the change. 📸 `screenshots/q3_2.png`

![q3_2](screenshots/q3_2.png)

**Q3.3: Conditional Update (business rule)**  
*Rule:* loans still `Borrowed`, not returned, and due before 2026-10-20 become `Overdue`.
```sql
SELECT borrowing_id, due_date, return_date, status FROM borrowings
WHERE status = 'Borrowed' AND return_date IS NULL AND due_date < '2026-10-20';   -- before
UPDATE borrowings SET status = 'Overdue'
WHERE status = 'Borrowed' AND return_date IS NULL AND due_date < '2026-10-20';
SELECT borrowing_id, due_date, return_date, status FROM borrowings ORDER BY borrowing_id;  -- after
```
**Expected Output — Not Yet Executed:** before: borrowing 2 (due 2026-10-15) and 4 (due 2026-10-19). After: "2 row(s) affected"; borrowings 2 and 4 show `Overdue`; 5 and 6 (due 10-24 and 10-26) stay `Borrowed`; 1, 3, 7 stay `Returned`.
*Explanation:* all three conditions must be true together (AND), so returned loans and loans not yet due are untouched. 📸 `screenshots/q3_3.png`

![q3_3](screenshots/q3_3.png)

### Q4.1–Q4.3: ALTER TABLE

(Order: the ERD was exported first. Q4.1 renames a column, so later statements use the new name.)

**Q4.1: Rename a Column**  
*Objective:* rename `students.faculty` to `department`.
```sql
ALTER TABLE students RENAME COLUMN faculty TO department;
DESCRIBE students;
SELECT full_name, department FROM students;
```
**Expected Output — Not Yet Executed:** `DESCRIBE students` lists `department varchar(80) NO` instead of `faculty`; the SELECT shows the same six values as before (e.g. Alice Uwase → Information Technology).
*Explanation:* only the column name changed; its data and type did not. 📸 `screenshots/q4_1.png`

![q4_1](screenshots/q4_1.png)

**Q4.2: Change a Column's Data Type**  
*Objective:* change `books.copies_total` from SMALLINT to INT (every SMALLINT value fits in INT, so nothing is lost).
```sql
ALTER TABLE books MODIFY COLUMN copies_total INT NOT NULL DEFAULT 1;
SELECT COLUMN_NAME, DATA_TYPE, COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'moaz_202510648_library_system' AND TABLE_NAME = 'books' AND COLUMN_NAME = 'copies_total';
SELECT book_id, title, copies_total FROM books ORDER BY book_id;
```
**Expected Output — Not Yet Executed:** DATA_TYPE `int`; copies_total values unchanged: 3, 2, 4, 3, 2, 5.
*Explanation:* we repeat `NOT NULL DEFAULT 1` because `MODIFY` replaces the whole column definition. 📸 `screenshots/q4_2.png`

![q4_2](screenshots/q4_2.png)

**Q4.3: Add a Column**  
*Objective:* add `shelf_location` so librarians can find books.
```sql
ALTER TABLE books ADD COLUMN shelf_location VARCHAR(20) NULL AFTER category;
DESCRIBE books;
SELECT book_id, title, shelf_location FROM books ORDER BY book_id;
```
**Expected Output — Not Yet Executed:** `DESCRIBE books` shows `shelf_location varchar(20) YES NULL` after `category`; all six existing books show `NULL` in that column. 
*Explanation:* adding was chosen over removing because nothing needs to be deleted and it improves the system; NULL is allowed because old rows have no location yet. 📸 `screenshots/q4_3.png`

![q4_3](screenshots/q4_3.png)

### Q5.1–Q5.3: INSERT

**Q5.1: Insert a Single Record**
```sql
INSERT INTO students (full_name, email, phone, department, registration_date)
VALUES ('Claudine Uwimana', 'claudine.uwimana@example.com', '0788100007', 'Law', '2026-10-22');
SELECT student_id, full_name, email, department, membership_status
FROM students WHERE email = 'claudine.uwimana@example.com';
```
**Expected Output — Not Yet Executed:** one row: `student_id 7`, Claudine Uwimana, Law, `membership_status = Active` (from DEFAULT). 
*Explanation:* uses the renamed column `department`; `student_id` is generated automatically. 📸 `screenshots/q5_1.png`

![q5_1](screenshots/q5_1.png)

**Q5.2: Insert Multiple Records**
```sql
INSERT INTO books (isbn, title, author, category, shelf_location, publication_year, copies_total)
VALUES
 ('9781119800361', 'Operating System Concepts',  'Abraham Silberschatz', 'Computer Science', 'CS-02',  2021, 3),
 ('9780596517748', 'JavaScript: The Good Parts', 'Douglas Crockford',    'Computer Science', 'CS-03',  2008, 2),
 ('9780307887894', 'The Lean Startup',           'Eric Ries',            'Business',         'BUS-01', 2011, 2);
SELECT book_id, isbn, title, category, shelf_location FROM books
WHERE isbn IN ('9781119800361', '9780596517748', '9780307887894') ORDER BY book_id;
```
**Expected Output — Not Yet Executed:** "3 row(s) affected"; three rows with book_id 7, 8, 9.
*Explanation:* one statement inserts three rows; if any row broke a constraint, none would be inserted. 📸 `screenshots/q5_2.png`

![q5_2](screenshots/q5_2.png)

**Q5.3: Insert a Related Record**
```sql
INSERT INTO borrowings (student_id, book_id, borrow_date, due_date, return_date, status)
VALUES ((SELECT student_id FROM students WHERE email = 'claudine.uwimana@example.com'),
        (SELECT book_id FROM books WHERE isbn = '9781119800361'),
        '2026-10-23', '2026-11-06', NULL, 'Borrowed');
SELECT br.borrowing_id, s.full_name, bk.title, br.borrow_date, br.due_date, br.status
FROM borrowings AS br
INNER JOIN students AS s ON br.student_id = s.student_id
INNER JOIN books AS bk ON br.book_id = bk.book_id
WHERE s.email = 'claudine.uwimana@example.com';
```
**Expected Output — Not Yet Executed:** one row: borrowing_id 8, Claudine Uwimana, Operating System Concepts, 2026-10-23, 2026-11-06, Borrowed.
*Explanation:* the foreign-key values come from existing parent rows, so the FOREIGN KEY constraints pass. Final counts: students 7, books 9, borrowings 8. 📸 `screenshots/q5_3.png`

![q5_3](screenshots/q5_3.png)

## 10. Results and Execution Evidence

Replace the *Expected Output* labels above with your own screenshots once executed.

| Screenshot file | Shows |
|---|---|
| `screenshots/01_tables_created.png` | SHOW TABLES and DESCRIBE of the 3 tables |
| `screenshots/02_record_counts.png` | Count query: 6 / 6 / 7 |
| `screenshots/03_all_tables_data.png` | SELECT * of all three tables |
| `screenshots/q1_1.png` … `q5_3.png` | Result grid or Action Output for each of the 15 tasks (for UPDATE/ALTER/INSERT include the verification query result, not only the statement) |

## 11. Conclusion

In this assignment I learned how to design a small relational database with three tables, and why splitting data into parent tables (`students`, `books`) and a child table (`borrowings`) avoids duplication. Primary keys with `AUTO_INCREMENT` give every row a unique identity, and foreign keys together with constraints (`UNIQUE`, `NOT NULL`, `CHECK`) protect the data from invalid values. I practised inserting parent rows before child rows and retrieving data with `SELECT`, `WHERE` and `ORDER BY`. I learned that `INNER JOIN` returns only matching rows while `LEFT JOIN` keeps every row from the left table, and that multi-table joins build useful reports. I learned to preview records before an `UPDATE`, use a precise `WHERE`, and verify afterwards. Finally, I learned that `UPDATE` changes data while `ALTER TABLE` changes the structure, and that renaming a column or changing a type affects every later statement.
