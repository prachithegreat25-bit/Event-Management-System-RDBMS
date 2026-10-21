CREATE DATABASE IF NOT EXISTS EventManagement;
USE EventManagement;
-- Drop tables in reverse foreign-key order to avoid dependency errors
DROP TABLE IF EXISTS Feedback;
DROP TABLE IF EXISTS Sponsorship;
DROP TABLE IF EXISTS Registration;
DROP TABLE IF EXISTS Event;
DROP TABLE IF EXISTS Participant;
DROP TABLE IF EXISTS Venue;
DROP TABLE IF EXISTS Organizer;
CREATE TABLE Venue (
    Venue_ID INT PRIMARY KEY,
    Venue_Name VARCHAR(100) NOT NULL,
    Location VARCHAR(150) NOT NULL,
    Capacity INT CHECK (Capacity > 0)
);
CREATE TABLE Organizer (
    Organizer_ID INT PRIMARY KEY,
    Org_Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(15)
);
CREATE TABLE Event (
    Event_ID INT PRIMARY KEY,
    Event_Name VARCHAR(150) NOT NULL,
    Event_Date DATE NOT NULL,
    Category VARCHAR(50),
    Venue_ID INT,
    Organizer_ID INT,
    FOREIGN KEY (Venue_ID) REFERENCES Venue(Venue_ID),
    FOREIGN KEY (Organizer_ID) REFERENCES Organizer(Organizer_ID)
);
CREATE TABLE Participant (
    Participant_ID INT PRIMARY KEY,
    Part_Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(15)
);
CREATE TABLE Registration (
    Registration_ID INT PRIMARY KEY,
    Event_ID INT,
    Participant_ID INT,
    Reg_Date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID) ON DELETE CASCADE,
    FOREIGN KEY (Participant_ID) REFERENCES Participant(Participant_ID) ON DELETE CASCADE
);
CREATE TABLE Sponsorship (
    Sponsor_ID INT PRIMARY KEY,
    Event_ID INT,
    Sponsor_Name VARCHAR(100) NOT NULL,
    Contribution_Amount DECIMAL(10, 2) CHECK (Contribution_Amount >= 0),
    FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID) ON DELETE CASCADE
);
CREATE TABLE Feedback (
    Feedback_ID INT PRIMARY KEY,
    Event_ID INT,
    Participant_ID INT,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Comments VARCHAR(255),
    FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID) ON DELETE CASCADE,
    FOREIGN KEY (Participant_ID) REFERENCES Participant(Participant_ID) ON DELETE CASCADE
);
INSERT INTO Venue VALUES (1, 'Auditorium A', 'Main Campus', 500);
INSERT INTO Venue VALUES (2, 'Tech Lab 3', 'CS Block', 120);
INSERT INTO Venue VALUES (3, 'Open Air Theatre', 'Student Activity Center', 1000);
INSERT INTO Organizer VALUES (1, 'Dr. Sharma', 'sharma@univ.edu', '9876543210');
INSERT INTO Organizer VALUES (2, 'Tech Club MUJ', 'techclub@muj.edu', '9123456789');
INSERT INTO Event VALUES (101, 'AI Symposium 2026', '2026-09-15', 'Technical', 1, 1);
INSERT INTO Event VALUES (102, 'CodeSprint Hackathon', '2026-09-25', 'Coding', 2, 2);
INSERT INTO Event VALUES (103, 'Cultural Night', '2026-10-05', 'Cultural', 3, 2);
INSERT INTO Participant VALUES (1, 'Aarav Mehta', 'aarav@gmail.com', '9988776655');
INSERT INTO Participant VALUES (2, 'Prachi Agarwal', 'prachi@gmail.com', '9811223344');
INSERT INTO Participant VALUES (3, 'Rohan Verma', 'rohan@gmail.com', '9722334455');
INSERT INTO Registration VALUES (1, 101, 1, '2026-09-01');
INSERT INTO Registration VALUES (2, 101, 2, '2026-09-02');
INSERT INTO Registration VALUES (3, 102, 2, '2026-09-10');
INSERT INTO Registration VALUES (4, 102, 3, '2026-09-12');
INSERT INTO Sponsorship VALUES (1, 101, 'TechCorp Inc.', 75000.00);
INSERT INTO Feedback VALUES (1, 101, 1, 5, 'Outstanding technical depth and organization!');
SELECT e.Event_Name, e.Event_Date, v.Venue_Name, v.Location
FROM Event e JOIN Venue v ON e.Venue_ID = v.Venue_ID;
SELECT e.Event_ID, e.Event_Name, COUNT(r.Participant_ID) AS Total_Participants
FROM Event e LEFT JOIN Registration r ON e.Event_ID = r.Event_ID
GROUP BY e.Event_ID, e.Event_Name;
SELECT e.Event_ID, e.Event_Name, p.Part_Name, r.Reg_Date
FROM Event e
JOIN Registration r ON e.Event_ID = r.Event_ID
JOIN Participant p ON r.Participant_ID = p.Participant_ID;
SELECT e.Event_ID, e.Event_Name, COUNT(r.Participant_ID) AS Total_Participants
FROM Event e JOIN Registration r ON e.Event_ID = r.Event_ID
GROUP BY e.Event_ID, e.Event_Name
HAVING COUNT(r.Participant_ID) > 100;
SELECT e.Event_ID, e.Event_Name, COUNT(r.Participant_ID) AS Total_Participants
FROM Event e JOIN Registration r ON e.Event_ID = r.Event_ID
WHERE r.Reg_Date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY e.Event_ID, e.Event_Name
ORDER BY Total_Participants DESC
LIMIT 3;
DELIMITER //

CREATE TRIGGER trg_enforce_capacity
BEFORE INSERT ON Registration
FOR EACH ROW
BEGIN
    DECLARE v_capacity INT;
    DECLARE v_current INT;

    SELECT v.Capacity INTO v_capacity
    FROM Event e JOIN Venue v ON e.Venue_ID = v.Venue_ID
    WHERE e.Event_ID = NEW.Event_ID;

    SELECT COUNT(*) INTO v_current
    FROM Registration WHERE Event_ID = NEW.Event_ID;

    IF v_current >= v_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Capacity limit reached for this venue.';
    END IF;
END //

DELIMITER ;
