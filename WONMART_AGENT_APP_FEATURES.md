# 📱 WONMART Agent App — Feature Documentation
### Prepared for Client Review | Version 1.0.0 | March 2026

---

## 🔐 1. Authentication & Security

| Feature | Description |
|--------|-------------|
| **Agent Login** | Secure email & password login for registered agents |
| **Agent Registration** | New agent sign-up with name, email, region, and password |
| **Forgot Password** | Password reset via email link |
| **Biometric Authentication** | Fingerprint / Face ID lock screen on app launch (device-supported) |
| **Auto Logout** | Secure logout from the profile screen |
| **Firebase Auth Backend** | Industry-standard authentication powered by Firebase |

---

## 🏠 2. Home Dashboard

| Feature | Description |
|--------|-------------|
| **Today's Sales Summary Card** | Real-time card showing today's total sales amount and cash collected |
| **Outstanding Balance** | Live business insight showing total uncollected payment from all shops |
| **Monthly Sales** | Total sales value for the current month, updated in real-time |
| **Quick Actions** | One-tap shortcuts: Create Invoice, Add Shop, Record Payment |
| **Recent Shops** | List of the agent's recently added shops for quick access |
| **Top Product Sales** | Ranked list of best-selling products by quantity |
| **Agent Greeting** | Personalized greeting with agent's name and assigned region |
| **Real-time Data Streams** | Dashboard updates automatically without manual refresh |
| **Pull-to-Refresh** | Swipe down to manually refresh all dashboard data |
| **Daily Auto PDF Save** | At end of day (11 PM), inventory summary is automatically saved as PDF to device |

---

## 🏪 3. Shop Management

| Feature | Description |
|--------|-------------|
| **Add Shop** | Add new customer shops with Name, Address, Phone, WhatsApp, Email |
| **Edit Shop** | Update any shop details anytime |
| **Delete Shop** | Remove shops with confirmation dialog |
| **Shop Search** | Search shops by name in real-time |
| **GPS Location** | Option to tag shop with GPS location (shown with indicator badge) |
| **Unique Shop ID** | Each shop gets a system-generated unique ID |
| **Shop List View** | All shops listed with address, ID, and GPS status |
| **Real-time Sync** | Shop list stays in sync with Firebase in real-time |

---

## 🗺️ 4. Route Management

| Feature | Description |
|--------|-------------|
| **Add Route** | Create named delivery routes (e.g., "Galle to Matara") |
| **Edit Route** | Rename existing routes |
| **Delete Route** | Remove unused routes with confirmation |
| **Route List** | View all routes with creation date |

> Routes are managed within the **Shops** tab under the "Routes" sub-tab.

---

## 🧾 5. Sales Orders

| Feature | Description |
|--------|-------------|
| **Create Sales Order** | Multi-product invoice creation screen |
| **Shop Selection** | Dropdown to select the target shop for the order |
| **Product Selection** | Pick products from the agent's live store (only available stock shown) |
| **Stock Validation** | System prevents ordering more than available stock |
| **Flexible Pricing Modes** | Choose between "By Margin (%)" or "By Seller Price" for each item |
| **Multiple Products Per Order** | Add unlimited products in a single order |
| **Return Products** | Record returned items in the same order with return reasons |
| **Return Reasons** | Categorized reasons: Damaged, Expired, Overstock, Other |
| **Return-to-Stock Option** | Optionally add returned items back to agent store stock |
| **Order Summary Screen** | Full review of items, totals, and returns before confirming |
| **Order List** | All past orders listed with shop name, date, item count, and total |
| **Order Search** | Search sales records by shop name |
| **Order Details Dialog** | View full item-by-item breakdown of any order |
| **Delete Order** | Delete sales record; stock is automatically restored |
| **PDF Invoice Generation** | Generate and share/print a professional PDF invoice per order |
| **Real-time Order Sync** | Orders sync instantly with Firebase |

---

## 💳 6. Payments Collection

| Feature | Description |
|--------|-------------|
| **Record Payment** | Collect payment against a specific sales record |
| **Step-wise Payment Flow** | Guided steps: Select Shop → Select Record → Enter Payment |
| **Full Payment** | One-tap to mark full balance as paid |
| **Partial Payment** | Enter custom amount for partial settlements |
| **Remaining Balance Display** | Live calculation of remaining balance as the agent types |
| **Payment Status Tracking** | Records marked as Pending / Partial / Completed automatically |
| **View Record Details** | View all order items before collecting payment |
| **Payment Receipt PDF** | Generate and share a payment receipt instantly after recording |
| **Payments List** | View all payments with 3 tabs: Pending, Completed, All |
| **Filter by Shop** | Filter the payment list by a specific shop |
| **Invoice from Payments Screen** | Generate PDF invoice directly from the payments list |
| **Real-time Balance Updates** | Outstanding balance on home screen updates immediately |

---

## 📦 7. Store / Inventory Management

### 7.1 My Store
| Feature | Description |
|--------|-------------|
| **Agent Store View** | View all products currently in the agent's stock |
| **Live Stock Quantities** | Real-time quantity display for each product |
| **Product Search** | Search products by name within the store |
| **Stock by Unit** | Each product shows its unit (e.g., bottles, boxes, kg) |

### 7.2 Store History
| Feature | Description |
|--------|-------------|
| **Issuance History** | Full log of stock issuances made to the agent from the warehouse |
| **History Detail Cards** | Each entry shows product, quantity, date, and action type |

### 7.3 Issuing Overview (Stock Payments Summary)
| Feature | Description |
|--------|-------------|
| **Date Range Filtering** | Select any custom date range to view issuances |
| **All Products Summary** | Aggregated table: Product Name, Warehouse Stock, Qty Issued, Expected Rs |
| **Grand Total** | Total expected revenue from all issued stock in the selected range |
| **By Product View** | Drill down into a specific product across all shops |
| **Per-Shop Breakdown** | See which shop received what quantity, at what margin, with payment status |
| **Payment Status Per Shop** | Shows Completed / Partial / Pending / No Record for each shop |

### 7.4 Return Overview
| Feature | Description |
|--------|-------------|
| **Return Product Tracking** | View all products that were returned by shops |
| **Return Summary** | Grouped return data with quantities and reasons |

---

## 📄 8. PDF Generation

| Feature | Description |
|--------|-------------|
| **Professional Sales Invoice** | Full-page PDF invoice with company logo, agent name, shop details, itemized list, totals, return amounts, and payment status |
| **Payment Receipt PDF** | Compact receipt after payment recording with paid amount and balance |
| **Daily Inventory Summary PDF** | Auto-saved end-of-day PDF with current stock snapshot |
| **Share / Print / Download** | All PDFs can be shared via WhatsApp, email, or printed directly |

---

## 📊 9. Data Export (CSV)

| Feature | Description |
|--------|-------------|
| **Sales Records Export** | Export all sales within a selected date range as a CSV file |
| **Return Records Export** | Export return transactions within a date range as CSV |
| **Store Inventory Export** | Export current stock snapshot as CSV |
| **Shop List Export** | Export all registered shops as CSV |

> All exports are accessible from the **Agent Profile** screen.

---

## 👤 10. Agent Profile

| Feature | Description |
|--------|-------------|
| **Profile View** | Shows agent name and unique agent ID |
| **Data Export** | Access all 4 export types from one screen |
| **App Info** | Displays app name and version |
| **Logout** | Securely sign out of the app |

---

## ⚙️ 11. Technical Features

| Feature | Description |
|--------|-------------|
| **Firebase Realtime Sync** | All data (shops, orders, payments, stock) syncs live via Firestore |
| **Offline Support** | Core operations (add shops, sales, routes) work offline and sync when reconnected |
| **Dark Mode UI** | Premium dark theme throughout the app |
| **Glassmorphism Design** | Modern glass-card UI aesthetic |
| **Premium Animations** | Smooth transitions, loading states, and micro-interactions |
| **Toast Notifications** | Non-intrusive success/error feedback messages |
| **Confirmation Dialogs** | All destructive actions (delete) require explicit confirmation |
| **Platform** | Android & iOS (Flutter cross-platform) |
| **Backend** | Firebase (Auth, Firestore, Cloud Storage) |

---

## 📋 Summary — Feature Count

| Module | Features |
|--------|---------|
| Authentication & Security | 6 |
| Home Dashboard | 10 |
| Shop Management | 8 |
| Route Management | 4 |
| Sales Orders | 16 |
| Payments Collection | 11 |
| Store / Inventory | 16 |
| PDF Generation | 4 |
| Data Export (CSV) | 4 |
| Agent Profile | 4 |
| Technical / Architecture | 10 |
| **TOTAL** | **93 Features** |

---

*This document was prepared to provide a complete overview of the Wonmart Agent App as developed and delivered. All listed features have been implemented and are functional within the application.*

---
**Prepared by:** Development Team  
**Date:** March 2026  
**App Version:** 1.0.0  
**Technology:** Flutter (Dart) + Firebase
