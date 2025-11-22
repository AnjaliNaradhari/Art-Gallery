from flask import Flask, render_template, request, redirect, url_for, flash, session
import mysql.connector
from datetime import timedelta

app = Flask(__name__)
app.secret_key = "artgallery_secret_key"
app.permanent_session_lifetime = timedelta(minutes=20)

# -----------------------------
# DATABASE CONNECTION
# -----------------------------
try:
    db = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="artgallery"
    )
    cursor = db.cursor(dictionary=True)
    print("✅ Database connected successfully!")
except mysql.connector.Error as err:
    print("❌ Database connection failed:", err)


# -----------------------------
# ROLE SELECTION PAGE
# -----------------------------
@app.route('/')
def index():
    return render_template('select_role.html')


# -----------------------------
# ARTIST LOGIN / REGISTER / HOME
# -----------------------------
@app.route('/artist_login', methods=['GET', 'POST'])
def artist_login():
    if request.method == 'POST':
        uname = request.form['username']
        pwd = request.form['password']
        cursor.execute("SELECT * FROM Register WHERE Username=%s AND Password=%s", (uname, pwd))
        artist = cursor.fetchone()
        if artist:
            session['artist'] = artist['Username']
            session['artist_id'] = artist['REGISTER_ID']
            flash(f"Welcome, {artist['FullName']}!", "success")
            return redirect(url_for('artist_home'))
        else:
            flash("❌ Invalid artist credentials!", "danger")
    return render_template('artist/login.html')


@app.route('/artist_register', methods=['GET', 'POST'])
def artist_register():
    if request.method == 'POST':
        fullname = request.form['fullname']
        uname = request.form['username']
        pwd = request.form['password']

        cursor.execute("SELECT * FROM Register WHERE Username=%s", (uname,))
        existing = cursor.fetchone()
        if existing:
            flash("⚠️ Username already exists.", "warning")
            return redirect(url_for('artist_register'))

        cursor.execute("INSERT INTO Register (FullName, Username, Password) VALUES (%s, %s, %s)",
                       (fullname, uname, pwd))
        db.commit()
        flash("✅ Artist registration successful!", "success")
        return redirect(url_for('artist_login'))
    return render_template('artist/register.html')


@app.route('/artist_home')
def artist_home():
    if 'artist' not in session:
        flash("Please log in first!", "warning")
        return redirect(url_for('artist_login'))
    return render_template('artist/home.html', user=session['artist'])


# ✅ FIX FOR “home” build error
@app.route('/home')
def home():
    return redirect(url_for('artist_home'))


# -----------------------------
# ARTIST: VIEW GALLERY
# -----------------------------
@app.route('/gallery')
def gallery():
    if 'artist' not in session:
        flash("Please log in first!", "warning")
        return redirect(url_for('artist_login'))

    cursor.execute("""
        SELECT a.Artwork_id, a.Title, a.Type, a.Status, ar.Name AS Artist
        FROM Artworks a
        JOIN Artist ar ON a.Artist_id = ar.Artist_id;
    """)
    artworks = cursor.fetchall()

    return render_template('artist/gallery.html', artworks=artworks, user=session['artist'])


# -----------------------------
# ARTIST: ADD ARTWORK
# -----------------------------
@app.route('/add_artwork', methods=['GET', 'POST'])
def add_artwork():
    if 'artist' not in session:
        flash("Please log in first!", "warning")
        return redirect(url_for('artist_login'))

    if request.method == 'POST':
        title = request.form['title']
        art_type = request.form['type']
        year = request.form['year']
        description = request.form['description']
        artist_id = request.form['artist_id']
        stock_id = request.form['stock_id']

        cursor.execute("""
            INSERT INTO Artworks (Title, Type, Year, Description, Artist_id, Stock_id, Status)
            VALUES (%s, %s, %s, %s, %s, %s, 'Available')
        """, (title, art_type, year, description, artist_id, stock_id))
        db.commit()

        flash("✅ Artwork added successfully!", "success")
        return redirect(url_for('gallery'))

    cursor.execute("SELECT * FROM Artist")
    artists = cursor.fetchall()
    cursor.execute("SELECT * FROM Artwork_Stocks")
    stocks = cursor.fetchall()
    return render_template('artist/add_artwork.html', artists=artists, stocks=stocks)


# -----------------------------
# ARTIST: ADD ARTIST DETAILS
# -----------------------------
@app.route('/add_artist', methods=['GET', 'POST'])
def add_artist():
    if 'artist' not in session:
        flash("Please log in first!", "warning")
        return redirect(url_for('artist_login'))

    if request.method == 'POST':
        name = request.form['name']
        style = request.form['style']
        dob = request.form['dob']
        contact = request.form['contact']
        email = request.form['email']

        cursor.execute("""
            INSERT INTO Artist (Name, Style, DOB, Contact, Email)
            VALUES (%s, %s, %s, %s, %s)
        """, (name, style, dob, contact, email))
        db.commit()

        flash("✅ Artist added successfully!", "success")
        return redirect(url_for('artist_home'))
    return render_template('artist/add_artist.html')


# -----------------------------
# CUSTOMER LOGIN / REGISTER / HOME
# -----------------------------
@app.route('/customer_login', methods=['GET', 'POST'])
def customer_login():
    if request.method == 'POST':
        uname = request.form['username']
        pwd = request.form['password']
        cursor.execute("SELECT * FROM Customer_Login WHERE Username=%s AND Password=%s", (uname, pwd))
        customer = cursor.fetchone()
        if customer:
            session['customer'] = customer['Username']
            session['customer_id'] = customer['Customer_ID']
            flash(f"Welcome, {customer['FullName']}!", "success")
            return redirect(url_for('customer_home'))
        else:
            flash("❌ Invalid customer credentials!", "danger")
    return render_template('customer/login.html')


@app.route('/customer_register', methods=['GET', 'POST'])
def customer_register():
    if request.method == 'POST':
        fullname = request.form['fullname']
        uname = request.form['username']
        pwd = request.form['password']

        cursor.execute("SELECT * FROM Customer_Login WHERE Username=%s", (uname,))
        existing = cursor.fetchone()
        if existing:
            flash("⚠️ Username already exists.", "warning")
            return redirect(url_for('customer_register'))

        cursor.execute("INSERT INTO Customer_Login (FullName, Username, Password) VALUES (%s, %s, %s)",
                       (fullname, uname, pwd))
        db.commit()
        flash("✅ Customer registration successful!", "success")
        return redirect(url_for('customer_login'))
    return render_template('customer/register.html')


# -----------------------------
# CUSTOMER HOME (with dashboard data)
# -----------------------------
@app.route('/customer_home')
def customer_home():
    if 'customer' not in session:
        flash("Please log in first!", "warning")
        return redirect(url_for('customer_login'))

    # Featured Artworks
    cursor.execute("""
        SELECT a.Title, a.Type, a.Status, ar.Name AS Artist
        FROM Artworks a
        JOIN Artist ar ON a.Artist_id = ar.Artist_id
        WHERE a.Status = 'Available'
        LIMIT 4;
    """)
    artworks = cursor.fetchall()

    # Upcoming Exhibitions
    cursor.execute("""
        SELECT Name, Venue, Start_date, Last_date
        FROM Exhibition
        WHERE Start_date >= CURDATE()
        ORDER BY Start_date ASC
        LIMIT 5;
    """)
    exhibitions = cursor.fetchall()

    # Ongoing Auctions
    cursor.execute("""
        SELECT a.Title AS Artwork, ar.Name AS Artist, auc.Start_price, auc.Highest_bid, auc.Status
        FROM Auction auc
        JOIN Artworks a ON auc.Artwork_id = a.Artwork_id
        JOIN Artist ar ON a.Artist_id = ar.Artist_id
        WHERE auc.Status = 'Ongoing'
        LIMIT 5;
    """)
    auctions = cursor.fetchall()

    return render_template('customer/home.html',
                           user=session['customer'],
                           artworks=artworks,
                           exhibitions=exhibitions,
                           auctions=auctions)


# -----------------------------
# CUSTOMER: VIEW EXHIBITION
# -----------------------------
@app.route('/view_exhibition')
def view_exhibition():
    if 'customer' not in session:
        flash("Please log in first!", "warning")
        return redirect(url_for('customer_login'))

    query = """
    SELECT e.Name AS Exhibition, e.Venue, e.Start_date, e.Last_date,
           a.Title AS Artwork, ar.Name AS Artist, di.Display_status
    FROM Exhibition e
    JOIN Displayed_In di ON e.Exhibition_id = di.Exhibition_id
    JOIN Artworks a ON di.Artwork_id = a.Artwork_id
    JOIN Artist ar ON a.Artist_id = ar.Artist_id
    ORDER BY e.Start_date DESC;
    """
    cursor.execute(query)
    exhibitions = cursor.fetchall()
    return render_template('customer/view_exhibition.html', exhibitions=exhibitions, user=session['customer'])


# -----------------------------
# CUSTOMER: BUY ARTWORK (Store-style)
# -----------------------------
@app.route('/buy_artwork', methods=['GET', 'POST'])
def buy_artwork():
    if 'customer' not in session:
        flash("Please log in first!", "warning")
        return redirect(url_for('customer_login'))

    cursor.execute("""
        SELECT a.Artwork_id, a.Title, a.Type, a.Status, ar.Name AS Artist, a.Description, s.Stock_available
        FROM Artworks a
        JOIN Artist ar ON a.Artist_id = ar.Artist_id
        JOIN Artwork_Stocks s ON a.Stock_id = s.Stock_id
        WHERE a.Status = 'Available';
    """)
    artworks = cursor.fetchall()

    if request.method == 'POST':
        artwork_id = request.form['artwork_id']
        customer_id = session['customer_id']

        cursor.execute("""
            INSERT INTO Orders (Customer_id, Artwork_id, Quantity, Order_status, Date)
            VALUES (%s, %s, 1, 'Completed', NOW());
        """, (customer_id, artwork_id))
        db.commit()

        cursor.execute("UPDATE Artworks SET Status='Sold' WHERE Artwork_id=%s", (artwork_id,))
        db.commit()

        flash("✅ Purchase successful! The artwork is now yours.", "success")
        return redirect(url_for('purchase_history'))

    return render_template('customer/buy_artwork.html', artworks=artworks, user=session['customer'])


# -----------------------------
# CUSTOMER: AUCTION / BID
# -----------------------------
@app.route('/auction', methods=['GET', 'POST'])
def auction():
    if 'customer' not in session:
        flash("Please log in first!", "warning")
        return redirect(url_for('customer_login'))

    if request.method == 'POST':
        auction_id = request.form['auction_id']
        bid_amount = float(request.form['bid_amount'])
        customer_id = session['customer_id']

        cursor.execute("""
            INSERT INTO Bids (Auction_id, Customer_id, Bid_amount, Bid_time)
            VALUES (%s, %s, %s, NOW())
        """, (auction_id, customer_id, bid_amount))
        db.commit()

        cursor.execute("""
            UPDATE Auction
            SET Highest_bid = GREATEST(IFNULL(Highest_bid, 0), %s)
            WHERE Auction_id = %s
        """, (bid_amount, auction_id))
        db.commit()

        flash("✅ Bid placed successfully!", "success")
        return redirect(url_for('auction'))

    cursor.execute("""
        SELECT auc.Auction_id, a.Title AS Artwork, a.Type, ar.Name AS Artist,
               auc.Status, auc.Start_price, auc.Highest_bid
        FROM Auction auc
        JOIN Artworks a ON auc.Artwork_id = a.Artwork_id
        JOIN Artist ar ON a.Artist_id = ar.Artist_id
        WHERE auc.Status IN ('Ongoing', 'Scheduled')
    """)
    auctions = cursor.fetchall()

    return render_template('customer/auction.html', auctions=auctions, user=session['customer'])


# -----------------------------
# CUSTOMER: PURCHASE HISTORY
# -----------------------------
@app.route('/purchase_history')
def purchase_history():
    if 'customer' not in session:
        flash("Please log in first!", "warning")
        return redirect(url_for('customer_login'))

    cursor.execute("""
        SELECT o.Order_id, a.Title, a.Type, o.Date, o.Order_status
        FROM Orders o
        JOIN Artworks a ON o.Artwork_id = a.Artwork_id
        WHERE o.Customer_id = %s
        ORDER BY o.Date DESC;
    """, (session['customer_id'],))
    purchases = cursor.fetchall()

    return render_template('customer/purchase_history.html', purchases=purchases, user=session['customer'])


# -----------------------------
# LOGOUT
# -----------------------------
@app.route('/logout')
def logout():
    session.clear()
    flash("You have been logged out.", "info")
    return redirect(url_for('index'))


# -----------------------------
# MAIN ENTRY POINT
# -----------------------------
if __name__ == "__main__":
    app.run(debug=True)
