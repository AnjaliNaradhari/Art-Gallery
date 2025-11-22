**🎨 Art Gallery Management System**

**📌 Project Overview**

The Art Gallery Management System is a DBMS-based web application designed to manage the operations of an art gallery, including:
- Artist registration & artwork management
- Artwork stock tracking
- Customer registration & login
- Artwork purchase system
- Orders management
- Exhibitions & artwork display
- Auction and bidding system with live status

The primary objective of this project is to demonstrate a well-structured database design with tables, relationships, triggers, views, and stored procedures.

**🗂️ Project Folder Structure**
```
Art-Gallery/
│
├── app.py                     # Main Flask backend application
├── database.sql               # Database schema + triggers + views + sample data
│
├── static/
│   └── static.css             # Stylesheet for UI
│
├── artist/
│   ├── login.html
│   ├── register.html
│   ├── home.html
│   ├── add_artist.html
│   ├── add_artwork.html
│   └── gallery.html
│
├── customer/
│   ├── login.html
│   ├── register.html
│   ├── home.html
│   ├── buy_artwork.html
│   ├── purchase_history.html
│   ├── view_exhibition.html
│   └── auction.html
│
└── select_role.html           # Main role-selection page
```
**Tech Stack**

Backend: Python (Flask)
Database: MySQL
Frontend: HTML, CSS (Bootstrap)
Tools: XAMPP / MySQL Workbench

**Features**

**👨‍🎨 Artist Module:**
- Artist registration & login
- Add artwork with type, status, stock, and description
- View all artwork in gallery

**🧑‍💼 Customer Module:**
- Customer registration & login
- Buy artwork (updates stock & order table)
- View purchase history
- Can participate in auction and bid amount
- View exhibitions & artworks displayed

**🚀 Commands to run the project**

1. Import the SQL Database: mysql -u root -p --port=3307 < artgallery.sql
2. Install Required Dependencies: pip install flask mysql-connector-python
3. Run the Application: python app.py
4. Open in Browser: visit -> http://localhost:5000

**Team Members**
- Nichanametla Keerthi - https://github.com/Keerthi-1906
- Naradhari Anjali - https://github.com/AnjaliNaradhari

