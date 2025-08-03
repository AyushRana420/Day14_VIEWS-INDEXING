Create Database Day14
Use Day14

CREATE TABLE Students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(50),
    email VARCHAR(50),
    major VARCHAR(50),
    enrollment_year INT
);

-- Create Courses table
CREATE TABLE Courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(50),
    credit_hours INT,
    department VARCHAR(50)
);

-- Create StudentCourses table for enrollment
CREATE TABLE StudentCourses (
    enrollment_id INT PRIMARY KEY,
    student_id INT,
    course_id INT,
    semester VARCHAR(20),
    grade CHAR(2),
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id)
);

-- Insert sample data
INSERT INTO Students VALUES 
(1, 'John Doe', 'john@example.com', 'Computer Science', 2020),
(2, 'Jane Smith', 'jane@example.com', 'Mathematics', 2021),
(3, 'Mike Johnson', 'mike@example.com', 'Physics', 2020);

INSERT INTO Courses VALUES
(101, 'Database Systems', 3, 'CS'),
(102, 'Calculus II', 4, 'MATH'),
(103, 'Quantum Physics', 4, 'PHYSICS');

INSERT INTO StudentCourses VALUES
(1, 1, 101, 'Fall 2023', 'A'),
(2, 1, 102, 'Spring 2024', 'B'),
(3, 2, 102, 'Fall 2023', 'A'),
(4, 3, 103, 'Spring 2024', 'B+');

Select * from Students, Courses, StudentCourses;

--Simple View
CREATE VIEW CS_Students AS
SELECT student_id,student_name,email
FROM Students
WHERE major = 'Computer Science';

SELECT * FROM CS_Students;

--Complex View From Multiple Table with joins
CREATE VIEW dbo.StudentEnrollments AS
SELECT s.student_name,c.course_name,sc.semester,sc.grade
FROM dbo.Students s
INNER JOIN dbo.StudentCourses sc ON s.student_id = sc.student_id
INNER JOIN dbo.Courses c on sc.course_id = c.course_id

Select * from dbo.StudentEnrollments; 

--Join and Inner join thery are exactly same, So inner is used for clarity 
--  Query and modify View 
Select TOP 100 * FROM dbo.CS_Students;
Select top 3 * FROM dbo.StudentEnrollments;

SELECT * FROM dbo.StudentEnrollments Where grade='A';

-- Updating data through a view 
BEGIN TRansaction;
    UPDATE dbo.CS_Students
    SET email= 'John_doe_university.edu'
    Where student_id = 1;

SELECT * from CS_Students;

-- verifying the update operation 
SELECT  * FROM dbo.CS_Students Where student_id = 1;
ROLLBACK TRANSACTION -- Undoing the changes
-- IRCTC servers, Instead of doing every small chnages in in my main sysytem, we have views that works as dataset
-- where we can make local changes and later on when they are permanenet they are updated in the MAIN DB
-- Limitation with views :( V.IMP)

-- Attempting to update a complex view Using error handling 
BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE dbo.StudentEnrollments
        SET Grade = 'A+'
        WHERE student_name ='John Doe' AND course_name = 'Database Systems';
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERROR occured...!!' + ERROR_MESSAGE();
END CATCH;

-- Altering a view( MSSQL  uses CREATE or ALTER in newer version)
-- For older version, we need to DROP and CREATE 

IF EXISTS (SELECT * FROM sys.views WHERE name= 'CS_Students' AND schema_ID = SCHEMA_ID('dbo'))
    DROP VIEW dbo.CS_Students;
-- Simple view 
CREATE VIEW dbo.CS_Students_New AS
SELECT student_id,student_name,email,enrollment_year
FROM dbo.Students
Where major = 'Computer Science';

Select * FROM dbo.CS_Students_New;

-- View Metadata in MS SQL 
-- Get view defination 
 SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.CS_Students_New')) AS ViewDefinition;

 -- List all view in the database 

 SELECT name AS ViewName, create_Date, modify_date 
 FROM sys.views
 WHERE is_ms_shipped = 0
 ORDER BY name;

 --Indexing starts from here

 Select * FROM Students,Courses,StudentCourses;
 -- Indexing on above table for Faster lookups
 
 Create NONCLUSTERED INDEX IX_STUDENT_EMAIL on Students(email); -- student Email

 --composite non clustered index on major and enrollment year 
Create NONCLUSTERED INDEX IX_STUDENT_MAJOR ON Students(major,enrollment_year);

-- Crating a Unique Index on email to prevent duplicates
Create UNIQUE INDEX UQ_Students_Email ON Students(email)WHERE email is NOT NULL;

-- Create a non clustered Index on StudentCourses for common query patterns
Create NONCLUSTERED INDEX IX_StudentCourses_Grade ON StudentCourses(semester,grade);

-- Analysing Index usage 
--Checking existing indexes in my system
SELECT
        t.name as TableName,
        i.name as IndexName,
        i.type_desc as IndexType,
        i.is_unique as IsUnique
FROM sys.indexes i
INNER JOIN sys.tables t on i.object_id = t.object_id
WHERE i.name is NOT NULL;

--sample Queries based on indexing 
SELECT * FROM Students WHERE email = 'john@example.com';

--using composite index 
SELECT * FROM Students WHERE major = 'Computer Science' AND enrollment_year = 2020;

-- Listing  all the tables in the database 

SELECT * FROM sys.tables; 
SELECT * FROM sys.schemas;

-- Most views in MSSQL Server are read only by design? justify How ??

-- Only simple views meeting strcit criteria can be updated directly ? How ?

 SELECT * FROM CS_Students_NEW;--Simple updatable view(Meets all criteria)
 SELECT * FROM StudentEnrollments;--View with Join(Not directly updatable)
 SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.StudentEnrollments')) AS ViewDefinition;

 --View with Distinct
 CREATE VIEW UniqueMajors AS
 SELECT DISTINCT major FROM Students;
 SELECT * FROM UniqueMajors;

 --Below Operation is failing because
 --Distinct create a derived result set
 --SQL Server can't map updates back to the base table
 BEGIN TRY
    Print'Attempting to update DISTINCT view..'
    UPDATE UniqueMajors
    SET major = 'Computer Sciences'
    WHERE major = 'Computer Science'
 END TRY

 BEGIN CATCH
    PRINT'Update failed(as Expected)';
    PRINT 'ERROR: ' + ERROR_MESSAGE();
 END CATCH;

 --View with computated column(non updatable)
 CREATE VIEW StudentNameLengths AS
 SELECT student_id,student_name, LEN(student_name) AS name_length
 FROM Students;
 SELECT * FROM StudentNameLengths


 BEGIN TRY
    PRINT'Attempting to update computed column'
    UPDATE StudentNameLengths
    SET student_name = 'Jhon B'
    WHERE name_length = 8
 END TRY

 BEGIN CATCH
    PRINT'Update failed (as expected)';
    PRINT'Error' + ERROR_MESSAGE();
 END CATCH;