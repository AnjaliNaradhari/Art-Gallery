DROP DATABASE IF EXISTS artgallery;
CREATE DATABASE artgallery;
USE artgallery;

------------------------------------------------------------
-- REGISTER TABLE (ARTIST LOGIN)
------------------------------------------------------------
CREATE TABLE Register (
    REGISTER_ID INT PRIMARY KEY AUTO_INCREMENT,
    FullName VARCHAR(100) NOT NULL,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Password VARCHAR(50) NOT NULL
);

------------------------------------------------------------
-- CUSTOMER LOGIN TABLE
------------------------------------------------------------
CREATE TABLE Customer_Login (
    Customer_ID INT PRIMARY KEY AUTO_INCREMENT,
    FullName VARCHAR(100) NOT NULL,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Password VARCHAR(50) NOT NULL
);

------------------------------------------------------------
-- ARTIST TABLE
------------------------------------------------------------
CREATE TABLE Artist (
    Artist_id INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Style ENUM('Modern','Ancient','Fantasy','Realism','Abstract'),
    DOB DATE NOT NULL,
    Contact VARCHAR(15) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Reg_id INT,
    FOREIGN KEY (Reg_id) REFERENCES Register(REGISTER_ID)
);

------------------------------------------------------------
-- STOCK TABLE
------------------------------------------------------------
CREATE TABLE Artwork_Stocks (
    Stock_id INT PRIMARY KEY AUTO_INCREMENT,
    Stock_available INT,
    Location VARCHAR(100)
);

------------------------------------------------------------
-- ARTWORK TABLE
------------------------------------------------------------
CREATE TABLE Artworks (
    Artwork_id INT PRIMARY KEY AUTO_INCREMENT,
    Title VARCHAR(100),
    Year YEAR,
    Type ENUM('Painting','Sculpture','Digital','Photography'),
    Status ENUM('Available','Sold','On Display'),
    Description TEXT NOT NULL,
    Stock_id INT,
    Artist_id INT,
    FOREIGN KEY (Stock_id) REFERENCES Artwork_Stocks(Stock_id),
    FOREIGN KEY (Artist_id) REFERENCES Artist(Artist_id)
);

------------------------------------------------------------
-- EXHIBITION TABLE
------------------------------------------------------------
CREATE TABLE Exhibition (
    Exhibition_id INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Venue VARCHAR(100) NOT NULL,
    Description TEXT,
    Start_date DATE NOT NULL,
    Last_date DATE NOT NULL
);

------------------------------------------------------------
-- DISPLAYED_IN TABLE
------------------------------------------------------------
CREATE TABLE Displayed_In (
    Exhibition_id INT,
    Artwork_id INT,
    Display_status ENUM('On Display','Upcoming','Completed','Removed'),
    Venue VARCHAR(100) NOT NULL,
    Location VARCHAR(100) NOT NULL,
    PRIMARY KEY (Exhibition_id, Artwork_id),
    FOREIGN KEY (Exhibition_id) REFERENCES Exhibition(Exhibition_id),
    FOREIGN KEY (Artwork_id) REFERENCES Artworks(Artwork_id)
);

------------------------------------------------------------
-- EXHIBITION STAFF
------------------------------------------------------------
CREATE TABLE Exhibition_Staff (
    Staff_id INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Salary DECIMAL(10,2) NOT NULL,
    Age INT,
    Contact VARCHAR(15) NOT NULL,
    Exhibition_id INT,
    Artwork_id INT,
    FOREIGN KEY (Exhibition_id) REFERENCES Exhibition(Exhibition_id),
    FOREIGN KEY (Artwork_id) REFERENCES Artworks(Artwork_id)
);

------------------------------------------------------------
-- CUSTOMER TABLE
------------------------------------------------------------
CREATE TABLE Customer (
    Customer_id INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Contact VARCHAR(15) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Address VARCHAR(255),
    Membership ENUM('Regular','Premium','VIP')
);

------------------------------------------------------------
-- ORDERS
------------------------------------------------------------
CREATE TABLE Orders (
    Order_id INT PRIMARY KEY AUTO_INCREMENT,
    Price DECIMAL(10,2),
    Quantity INT,
    Order_status ENUM('Pending','Completed','Cancelled'),
    Date DATE,
    Customer_id INT,
    Artwork_id INT,
    FOREIGN KEY (Customer_id) REFERENCES Customer(Customer_id),
    FOREIGN KEY (Artwork_id) REFERENCES Artworks(Artwork_id)
);

------------------------------------------------------------
-- PAYMENT TABLE
------------------------------------------------------------
CREATE TABLE Payment (
    Payment_id INT PRIMARY KEY AUTO_INCREMENT,
    Total_amount DECIMAL(10,2),
    Mode ENUM('Cash','Credit Card','Debit Card','UPI','Net Banking','PayPal'),
    Date DATE,
    Customer_id INT,
    FOREIGN KEY (Customer_id) REFERENCES Customer(Customer_id)
);

------------------------------------------------------------
-- AUCTION TABLE
------------------------------------------------------------
CREATE TABLE Auction (
    Auction_id INT PRIMARY KEY AUTO_INCREMENT,
    Date_of_auction DATE NOT NULL,
    Status ENUM('Scheduled','Ongoing','Completed','Cancelled'),
    Start_price DECIMAL(10,2),
    Highest_bid DECIMAL(10,2),
    Customer_id INT,
    Artwork_id INT,
    Start_time DATETIME DEFAULT NOW(),
    Duration_hours INT DEFAULT 2,
    FOREIGN KEY (Customer_id) REFERENCES Customer(Customer_id),
    FOREIGN KEY (Artwork_id) REFERENCES Artworks(Artwork_id)
);



------------------------------------------------------------
-- BIDS TABLE
------------------------------------------------------------
CREATE TABLE Bids (
    Bid_id INT PRIMARY KEY AUTO_INCREMENT,
    Auction_id INT,
    Customer_id INT,
    Bid_amount DECIMAL(10,2),
    Bid_time DATETIME,
    FOREIGN KEY (Auction_id) REFERENCES Auction(Auction_id),
    FOREIGN KEY (Customer_id) REFERENCES Customer(Customer_id)
);

------------------------------------------------------------
-- ARTWORK LOG TABLE
------------------------------------------------------------
CREATE TABLE Artwork_Log (
    Log_id INT PRIMARY KEY AUTO_INCREMENT,
    Artwork_id INT,
    Title VARCHAR(100),
    Log_message VARCHAR(255),
    Log_time DATETIME
);

------------------------------------------------------------
-- TRIGGERS
------------------------------------------------------------
DELIMITER //
CREATE TRIGGER AfterArtworkInsert
AFTER INSERT ON Artworks
FOR EACH ROW
BEGIN
    INSERT INTO Artwork_Log(Artwork_id, Title, Log_message, Log_time)
    VALUES (NEW.Artwork_id, NEW.Title, CONCAT('New artwork added: ', NEW.Title), NOW());
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER UpdateArtworkStatus
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    IF NEW.Order_status = 'Completed' THEN
        UPDATE Artworks
        SET Status = 'Sold'
        WHERE Artwork_id = NEW.Artwork_id;
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER BidLog_AfterInsert
AFTER INSERT ON Bids
FOR EACH ROW
BEGIN
    UPDATE Auction
    SET Highest_bid = GREATEST(IFNULL(Highest_bid, 0), NEW.Bid_amount)
    WHERE Auction_id = NEW.Auction_id;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER ReduceStock_AfterOrder
AFTER UPDATE ON Orders
FOR EACH ROW
BEGIN
    IF NEW.Order_status = 'Completed' THEN
        UPDATE Artwork_Stocks
        SET Stock_available = Stock_available - NEW.Quantity
        WHERE Stock_id = (SELECT Stock_id FROM Artworks WHERE Artwork_id = NEW.Artwork_id);
    END IF;
END //
DELIMITER ;

------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------
DELIMITER //
CREATE FUNCTION GetDiscountedPrice(price DECIMAL(10,2), membership ENUM('Regular','Premium','VIP'))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE discount DECIMAL(4,2);
    IF membership = 'Premium' THEN SET discount = 0.10;
    ELSEIF membership = 'VIP' THEN SET discount = 0.20;
    ELSE SET discount = 0.00;
    END IF;
    RETURN price - (price * discount);
END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION CalcTotal(price DECIMAL(10,2), qty INT, discount DECIMAL(5,2))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN (price * qty) - ((price * qty) * (discount/100));
END //
DELIMITER ;

------------------------------------------------------------
-- STORED PROCEDURES
------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE AddCustomer(
    IN cname VARCHAR(100),
    IN ccontact VARCHAR(15),
    IN cemail VARCHAR(100),
    IN caddress VARCHAR(255),
    IN cmembership ENUM('Regular','Premium','VIP')
)
BEGIN
    INSERT INTO Customer(Name, Contact, Email, Address, Membership)
    VALUES (cname, ccontact, cemail, caddress, cmembership);
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE GetArtworksByArtist(IN artistName VARCHAR(100))
BEGIN
    SELECT A.Artwork_id, A.Title, A.Type, A.Status
    FROM Artworks A
    JOIN Artist R ON A.Artist_id = R.Artist_id
    WHERE R.Name = artistName;
END //
DELIMITER ;

------------------------------------------------------------
-- VIEWS
------------------------------------------------------------
CREATE VIEW ArtworkDetails AS
SELECT a.Artwork_id, a.Title, a.Type, a.Status,
       ar.Name AS Artist_Name, ar.Style AS Artist_Style,
       s.Location AS Stock_Location, s.Stock_available
FROM Artworks a
JOIN Artist ar ON a.Artist_id = ar.Artist_id
JOIN Artwork_Stocks s ON a.Stock_id = s.Stock_id;

CREATE VIEW ExhibitionOverview AS
SELECT e.Name AS Exhibition, e.Venue, a.Title AS Artwork,
       di.Display_status, di.Location
FROM Exhibition e
JOIN Displayed_In di ON e.Exhibition_id = di.Exhibition_id
JOIN Artworks a ON di.Artwork_id = a.Artwork_id;

CREATE VIEW CustomerPurchaseHistory AS
SELECT c.Name AS Customer, a.Title AS Artwork,
       o.Order_status, o.Date AS Order_Date
FROM Orders o
JOIN Customer c ON o.Customer_id = c.Customer_id
JOIN Artworks a ON o.Artwork_id = a.Artwork_id;

------------------------------------------------------------
--  DATA (Matching Flask App)
------------------------------------------------------------
INSERT INTO Register (FullName, Username, Password)
VALUES
('John', 'johnA', '123'),
('Emily Rose', 'emilyR', '123'),
('David Lee', 'davidL', '123');

INSERT INTO Customer_Login (FullName, Username, Password)
VALUES
('Alice Brown', 'aliceB', '123'),
('Michael Ford', 'mikeF', '123'),
('Sophia Lane', 'sophiaL', '123');

INSERT INTO Artwork_Stocks (Stock_available, Location)
VALUES
(10, 'Main Storage'),
(5, 'Gallery Hall A'),
(15, 'Gallery Basement Storage'),
(8, 'VIP Exhibition Room'),
(12, 'Outdoor Sculpture Section'),
(20, 'Digital Art Server Storage'),
(6,  'Photography Dark Room');

INSERT INTO Artist (Name, Style, DOB, Contact, Email, Reg_id)
VALUES
('John Artist', 'Modern', '1980-04-05', '9998887776', 'john@example.com', 1),
('Emily Rose', 'Realism', '1985-11-15', '9876543210', 'emily@example.com', 2),
('David Lee', 'Fantasy', '1990-09-21', '9090909090', 'david@example.com', 3),
('Sarah Winters', 'Modern', '1988-02-14', '9123456780', 'sarah@example.com', 1),
('Leonardo Park', 'Abstract', '1992-08-12', '9234567810', 'leo@example.com', 2),
('Marina Cole', 'Realism', '1979-01-30', '9345678201', 'marina@example.com', 3);

INSERT INTO Artworks (Title, Year, Type, Status, Description, Stock_id, Artist_id)
VALUES
('Blue Horizon', 2020, 'Painting', 'Available', 'Landscape art', 1, 1),
('Golden Dreams', 2019, 'Sculpture', 'Available', 'Golden sculpture', 1, 2),
('Digital Mirage', 2023, 'Digital', 'Available', 'Modern digital art', 2, 3),
('Silent Forest', 2021, 'Photography', 'On Display', 'Dark forest photo', 2, 1),
('Shadows of Time', 2022, 'Painting', 'Available', 'Vintage-themed painting', 2, 4),
('Light of Destiny', 2024, 'Digital', 'Available', 'Futuristic digital creation', 1, 5),
('Moonlit Sculpture', 2018, 'Sculpture', 'On Display', 'Hand-carved marble figurine', 1, 6),
('Mystic River', 2023, 'Painting', 'Available', 'Nature-inspired art', 2, 4),
('Broken Reflections', 2023, 'Photography', 'Available', 'Glass reflection photography', 2, 5);

INSERT INTO Exhibition (Name, Venue, Description, Start_date, Last_date)
VALUES
('Spring Expo', 'City Art Hall', 'Spring collection', '2025-03-01', '2025-03-15'),
('Digital Wonders', 'Tech Gallery', 'Digital artworks', '2025-04-10', '2025-04-30'),
('Summer Showcase', 'National Art Hall', 'Mixed media artworks', '2025-06-10', '2025-06-25'),
('Heritage & Beyond', 'Royal Art Museum', 'Classic Indian artworks', '2025-07-05', '2025-07-30');

INSERT INTO Displayed_In (Exhibition_id, Artwork_id, Display_status, Venue, Location)
VALUES
(1, 4, 'On Display', 'City Art Hall', 'Room 2'),
(2, 3, 'Upcoming', 'Tech Gallery', 'Digital Wing'),
(3, 7, 'On Display', 'National Art Hall', 'Main Gallery'),
(4, 8, 'Upcoming', 'Royal Art Museum', 'Heritage Wing');

INSERT INTO Customer (Name, Contact, Email, Address, Membership)
VALUES
('Alice Brown', '9876500000', 'alice@example.com', 'Bangalore', 'Regular'),
('Michael Ford', '9876511111', 'mike@example.com', 'Delhi', 'Premium'),
('Rahul Menon', '9876000011', 'rahul@example.com', 'Kochi', 'Premium'),
('Priya Sharma', '8765000033', 'priya@example.com', 'Mumbai', 'VIP'),
('Daniel Costa', '9988776655', 'daniel@example.com', 'Goa', 'Regular');

INSERT INTO Orders (Price, Quantity, Order_status, Date, Customer_id, Artwork_id)
VALUES
(15000, 1, 'Completed', '2025-02-01', 1, 1),
(22000, 1, 'Completed', '2025-02-10', 3, 5),
(18000, 1, 'Pending', '2025-02-15', 4, 6),
(12000, 1, 'Completed', '2025-02-18', 5, 7);

INSERT INTO Auction
(Date_of_auction, Status, Start_price, Highest_bid, Customer_id, Artwork_id, Start_time, Duration_hours)
VALUES
('2025-05-01', 'Scheduled', 5000, NULL, NULL, 2, NOW(), 2),
('2025-06-01', 'Ongoing', 7000, 7200, 1, 3, NOW(), 2),
('2025-08-05', 'Scheduled', 9000, NULL, NULL, 4, NOW(), 3),
('2025-09-01', 'Ongoing', 15000, 15200, 3, 6, NOW(), 2),
('2025-09-10', 'Completed', 5000, 6500, 4, 7, NOW() - INTERVAL 3 HOUR, 2);




