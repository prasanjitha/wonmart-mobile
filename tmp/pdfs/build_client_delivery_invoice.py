from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether,
)

OUTPUT = "output/pdf/wonmart-client-completion-payment-request.pdf"

ORANGE = colors.HexColor("#FF7A1A")
DARK = colors.HexColor("#101827")
NAVY = colors.HexColor("#182438")
SLATE = colors.HexColor("#526174")
LIGHT = colors.HexColor("#F4F7FB")
BORDER = colors.HexColor("#D9E1EA")
GREEN = colors.HexColor("#078B67")


def money(amount):
    return f"Rs. {amount:,.2f}"


def footer(canvas, doc):
    canvas.saveState()
    width, _ = A4
    canvas.setStrokeColor(BORDER)
    canvas.line(18 * mm, 13 * mm, width - 18 * mm, 13 * mm)
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(SLATE)
    canvas.drawString(18 * mm, 8.5 * mm, "Wonmart platform enhancement - client delivery document")
    canvas.drawRightString(width - 18 * mm, 8.5 * mm, f"Page {doc.page}")
    canvas.restoreState()


styles = getSampleStyleSheet()
styles.add(ParagraphStyle(
    name="TitleCustom", parent=styles["Title"], fontName="Helvetica-Bold",
    fontSize=24, leading=29, textColor=DARK, spaceAfter=5,
))
styles.add(ParagraphStyle(
    name="Subtitle", parent=styles["Normal"], fontName="Helvetica", fontSize=10,
    leading=15, textColor=SLATE,
))
styles.add(ParagraphStyle(
    name="Section", parent=styles["Heading2"], fontName="Helvetica-Bold",
    fontSize=14, leading=18, textColor=DARK, spaceBefore=13, spaceAfter=7,
))
styles.add(ParagraphStyle(
    name="BodyCustom", parent=styles["BodyText"], fontName="Helvetica", fontSize=9.3,
    leading=14, textColor=DARK,
))
styles.add(ParagraphStyle(
    name="Small", parent=styles["BodyText"], fontName="Helvetica", fontSize=8.3,
    leading=11, textColor=SLATE,
))
styles.add(ParagraphStyle(
    name="TableHeader", parent=styles["BodyText"], fontName="Helvetica-Bold",
    fontSize=7.8, leading=9.2, textColor=colors.white,
))
styles.add(ParagraphStyle(
    name="TableBody", parent=styles["BodyText"], fontName="Helvetica", fontSize=7.55,
    leading=9.7, textColor=DARK,
))
styles.add(ParagraphStyle(
    name="Status", parent=styles["BodyText"], fontName="Helvetica-Bold", fontSize=7.35,
    leading=9, textColor=GREEN, alignment=TA_CENTER,
))
styles.add(ParagraphStyle(
    name="AmountLabel", parent=styles["BodyText"], fontName="Helvetica-Bold", fontSize=9,
    leading=12, textColor=SLATE,
))
styles.add(ParagraphStyle(
    name="Amount", parent=styles["BodyText"], fontName="Helvetica-Bold", fontSize=22,
    leading=26, textColor=ORANGE, alignment=TA_RIGHT,
))


def p(text, style="BodyCustom"):
    return Paragraph(text, styles[style])


def info_row(label, value):
    return [p(label, "Small"), p(value, "BodyCustom")]


def build():
    doc = SimpleDocTemplate(
        OUTPUT,
        pagesize=A4,
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=16 * mm,
        bottomMargin=21 * mm,
        title="Wonmart Platform Enhancement - Completion and Payment Request",
        author="Wonmart Development Team",
    )
    story = []

    brand = Table([[p("WONMART", "TitleCustom"), p("CLIENT DELIVERY DOCUMENT", "Small")]], colWidths=[110 * mm, 64 * mm])
    brand.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("ALIGN", (1, 0), (1, 0), "RIGHT"),
        ("LINEBELOW", (0, 0), (-1, -1), 2, ORANGE),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    story.append(brand)
    story.append(Spacer(1, 9 * mm))
    story.append(p("Platform Enhancement Completion and Payment Request", "TitleCustom"))
    story.append(p("A completion summary for the recently delivered Wonmart web admin, reporting, inventory, and mobile sales-order enhancements.", "Subtitle"))
    story.append(Spacer(1, 7 * mm))

    details = Table([
        info_row("Document date", "17 September 2026"),
        info_row("Client", "Wonmart Client"),
        info_row("Project", "Wonmart platform enhancement delivery"),
        info_row("Delivery status", "Completed and ready for client review"),
    ], colWidths=[42 * mm, 132 * mm])
    details.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (0, -1), LIGHT),
        ("BOX", (0, 0), (-1, -1), 0.5, BORDER),
        ("INNERGRID", (0, 0), (-1, -1), 0.35, BORDER),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    story.append(details)

    story.append(p("Completed Deliverables", "Section"))
    story.append(p("The scope below has been implemented across the web administration portal and the agent mobile workflow. These items are designed to improve visibility, operations, invoice access, reporting, and inventory control.", "BodyCustom"))
    story.append(Spacer(1, 4 * mm))

    rows = [[p("#", "TableHeader"), p("Completed area", "TableHeader"), p("Delivered functionality", "TableHeader"), p("Status", "TableHeader")]]
    deliverables = [
        ("01", "Agent admin dashboard", "Delivered a dedicated agent administration dashboard with clear overview cards and direct navigation to the selected agent's operational areas. The dashboard gives administrators a single starting point to review sales activity, inventory value, pending balances, shops, routes, payments, and reporting without moving between unrelated screens."),
        ("02", "Admin agent management", "Expanded the agent management workspace so administrators can open an individual agent profile and manage the associated sales, reports, inventory, shops, routes, payment records, and profile details. The updated structure reduces manual cross-checking and keeps agent-specific operational data together in one managed view."),
        ("03", "Agent-wise invoice access", "Added a dedicated Invoice column to agent sales records with View and Download actions for every saved shop sale. The View action presents order items, return items, sample products, paid amount, balance, and totals; the Download action produces the saved invoice as a PDF for customer or accounting use."),
        ("04", "Sales report suite", "Implemented reporting views for invoice-wise, agent-wise, date-wise, product-wise, and supplier-wise analysis. These reports support operational monitoring and commercial review with date filters, searchable report tables, calculated values, and export options so users can review performance at the required level of detail."),
        ("05", "Stock report suite", "Delivered Full Stock and Low Stock reports that show product availability, cost and sale value, estimated profit, supplier information, and stock status. The reports include filters, CSV/PDF export support, product-name ordering, and exclusion of products that have been hidden from active inventory views."),
        ("06", "Agent report suite", "Delivered Agent Sales, Agent Stock, and Agent Low Stock reports for reviewing distributor-level performance and inventory risk. The Agent Sales report includes a date-range selector, invoice actions, totals, returns, agent-price cost, profit, and cash received; the stock reports provide the relevant agent inventory and low-stock data."),
        ("07", "Inventory table improvements", "Improved inventory tables with ascending product-name ordering, clearer product and value columns, status controls, and a View Hidden workflow. Product visibility can now be changed per record, saved against the relevant store entry, reviewed in a separate hidden-products popup, and restored when the product should become active again."),
        ("08", "Sample product sales workflow", "Added an optional Add Sample Product section to the agent mobile Create Sales Order screen. Users can select any product available in the agent store, enter the quantity, add one or more sample items to the order, and review the selected samples before confirming the sale; confirmed sample quantities are included in the applicable agent-store stock deduction."),
        ("09", "Invoice and return enhancements", "Enhanced both thermal and A4 invoice generation to show return and sample information whenever those records exist. Return items are presented with product name, quantity, price, amount, and return total; sample products are presented in their own section with item names and quantities, positioned appropriately for each invoice format."),
        ("10", "Sales performance summaries", "Added sales, total cost, total profit, cash received, and returns summary cards to the agent sales and report experiences. Total cost is calculated from each sold item's quantity multiplied by its matching agent-store shop price, using efficient product-price lookup so the result reflects the assigned agent price instead of the retail selling price."),
        ("11", "Merged product stock reports", "Added separate Merge Products stock reports for both main warehouse inventory and each agent's agent_store inventory. Records with the same main-warehouse barcode or the same agent Product ID are combined into one product family; batch/date suffixes are removed from the displayed name, quantities and stock values are summed, and weighted unit prices are used when historical batches have different prices. The merged tables, summary cards, CSV exports, and PDF exports all use the same combined data."),
    ]
    for number, area, description in deliverables:
        rows.append([p(number, "TableBody"), p(area, "TableBody"), p(description, "TableBody"), p("COMPLETED", "Status")])
    delivered = Table(rows, colWidths=[11 * mm, 38 * mm, 101 * mm, 24 * mm], repeatRows=1)
    delivered.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), DARK),
        ("GRID", (0, 0), (-1, -1), 0.35, BORDER),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 3.5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3.5),
        ("BACKGROUND", (0, 1), (-1, -1), colors.white),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, LIGHT]),
        ("ALIGN", (0, 1), (0, -1), "CENTER"),
    ]))
    story.append(delivered)
    story.append(Spacer(1, 6 * mm))

    story.append(p("Delivery Notes", "Section"))
    notes = [
        "All completed items are integrated with the existing Wonmart data structure, including agent_store, sales payment, sales record, and invoice information.",
        "Report and invoice features include the relevant products, returns, samples, totals, and status information where the source data is available.",
        "Inventory status changes are saved against the individual agent-store product record, allowing hidden products to be restored without deleting stock data.",
        "The delivered web interfaces include responsive tables, searchable lists, date-range filters, export options, and usable empty/loading states.",
    ]
    for note in notes:
        story.append(p(f"<b>•</b> {note}", "BodyCustom"))
        story.append(Spacer(1, 1.7 * mm))

    story.append(Spacer(1, 4 * mm))
    story.append(p("Key Operational Outcomes", "Section"))
    outcomes = Table([
        [p("Operational visibility", "AmountLabel"), p("Administrators can review agent activity, stock, reports, shops, payments, and invoices from connected management views.", "BodyCustom")],
        [p("Invoice completeness", "AmountLabel"), p("Invoice views and downloads include order items, return items, sample products, and calculated totals when those records are available.", "BodyCustom")],
        [p("Inventory control", "AmountLabel"), p("Product visibility can be managed without deleting stock records, helping teams keep active views focused while retaining restore access.", "BodyCustom")],
    ], colWidths=[48 * mm, 126 * mm])
    outcomes.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (0, -1), LIGHT),
        ("BOX", (0, 0), (-1, -1), 0.5, BORDER),
        ("INNERGRID", (0, 0), (-1, -1), 0.35, BORDER),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
    ]))
    story.append(outcomes)
    story.append(Spacer(1, 7 * mm))
    completion = Table([[p("COMPLETION DECLARATION", "AmountLabel"), p("The listed enhancements have been completed and prepared for client review, acceptance, and payment processing.", "BodyCustom")]], colWidths=[48 * mm, 126 * mm])
    completion.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#EDF9F5")),
        ("BOX", (0, 0), (-1, -1), 0.7, GREEN),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 9),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 9),
    ]))
    story.append(completion)

    story.append(p("Commercial Summary", "TitleCustom"))
    story.append(p("Commercial completion summary for the completed Wonmart platform enhancement scope.", "Subtitle"))
    story.append(Spacer(1, 7 * mm))

    amount_card = Table([
        [p("PROJECT DELIVERY VALUE", "AmountLabel"), p(money(30000), "Amount")],
        [p("Completed scope", "Small"), p("Wonmart web admin, reporting, inventory, invoicing, and agent mobile sales enhancements", "Small")],
    ], colWidths=[70 * mm, 104 * mm])
    amount_card.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#FFF3E8")),
        ("BOX", (0, 0), (-1, -1), 1, ORANGE),
        ("INNERGRID", (0, 1), (-1, -1), 0.35, BORDER),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("ALIGN", (1, 0), (1, 0), "RIGHT"),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ("TOPPADDING", (0, 0), (-1, -1), 10),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
    ]))
    story.append(amount_card)
    story.append(Spacer(1, 8 * mm))
    story.append(p("Commercial Scope", "Section"))
    story.append(p("The stated project delivery value covers the completed web administration, reporting, inventory, invoice, and agent mobile sales-order enhancements described in this document.", "BodyCustom"))

    doc.build(story, onFirstPage=footer, onLaterPages=footer)


if __name__ == "__main__":
    build()
