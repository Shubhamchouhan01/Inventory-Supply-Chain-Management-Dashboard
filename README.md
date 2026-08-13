 Inventory & Supply Chain Management Dashboard

A Python-driven UI for advanced SQL database operations — built so non-technical users (managers, team leads, operations staff) can interact with a full-featured MySQL inventory system through a clean web dashboard, with zero SQL knowledge required.

 Overview

Most business databases are powerful but locked behind SQL. This project bridges that gap: a MySQL backend with real-world schema design, views, and stored procedures, wired up to a Streamlit frontend where every action — viewing stock, placing reorders, receiving shipments — happens with a click instead of a query.

🎯 Key Features
📊 Live dashboard metrics — total suppliers, products, categories, sales value, and restock value at a glance
🚨 Low-stock alerts — automatically flags products below their reorder level
➕ Add new products — through a simple form, with automatic shipment + stock entry logging
📜 Product history tracking — full inventory movement history (shipments + stock changes) per product
🔁 Reorder workflow — place reorders and mark them as received, with stock and shipment records updated automatically
🗂️ Supplier & category browsing — clean, filterable tables for reference data
🏗️ Architecture

The project is built in two layers:

🗄️ 1. Database Layer (MySQL)
Tables — products, suppliers, shipments, stock_entries, reorders
Views — product_inventory_history, a unified feed combining shipments and stock entries for full traceability per product
Stored Procedures:
AddNewProductManualID — inserts a new product and automatically logs the initial shipment and stock entry in one transaction
MarkReorderAsReceived — updates reorder status, restocks the product, and logs the shipment + stock entry, all wrapped in a transaction for consistency
Business logic queries — low-stock detection, sales/restock value rollups over rolling time windows, and reorder gap analysis (products below reorder level with no pending reorder)
🖥️ 2. Application Layer (Python + Streamlit)
db_functions.py — all database access logic, cleanly separated from the UI (connection handling, queries, and stored procedure calls)
app.py — the Streamlit frontend, split into two views:
Basic Information — dashboard metrics and reference tables
Operational Tasks — Add New Product, Product History, Place Reorder, Receive Reorder
🛠️ Tech Stack
Layer	Technology
Frontend	Streamlit
Backend logic	Python (mysql-connector-python)
Database	MySQL (Views, Stored Procedures, Transactions)
Data handling	Pandas
🚀 What Makes This Advanced
Combines a real multi-layer architecture (DB logic layer → Python data layer → UI layer) instead of flattening everything into the frontend
Uses genuine database engineering: views for reporting, stored procedures for atomic multi-table business transactions, and transactions for data integrity
Mirrors real operational workflows found in inventory, sales, and supply chain systems
Designed for non-technical end users — every backend capability is exposed as a button, form, or dropdown
⚙️ Getting Started
Prerequisites
Python 3.9+
MySQL Server
pip
Setup
Clone the repository
bash
   git clone <your-repo-url>
   cd inventory-dashboard
Install dependencies
bash
   pip install streamlit pandas mysql-connector-python
Set up the database
Create a MySQL database
Run inventory_project.sql to create the tables, view, and stored procedures
Configure your database credentials
Update the connection details in db_functions.py (connect_to_db())
⚠️ For production or public repos, move credentials to environment variables instead of hardcoding them
Run the app
bash
   streamlit run app.py
📂 Project Structure
├── app.py                     # Streamlit frontend
├── db_functions.py            # Database access layer
├── inventory_project.sql      # Schema, views, stored procedures
└── README.md
🔮 Possible Next Steps
Add authentication/role-based access for different user types
Add data visualizations (stock trends, top-moving products)
Move credentials to a .env file with python-dotenv
Add automated tests for stored procedures and query functions
📄 License

This project is open for learning and personal use. Feel free to fork and adapt it.
