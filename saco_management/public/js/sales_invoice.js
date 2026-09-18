frappe.ui.form.on("Sales Invoice", {
	onload(frm) {
		if (frm.is_new() && !frm.doc.update_stock) {
			frm.set_value("update_stock", 0);
		}
	},

	refresh(frm) {
		if (frm.doc.docstatus !== 1 || frm.doc.per_delivered >= 100) {
			return;
		}
		frm.add_custom_button(
			__("Delivery Note"),
			() => {
				frappe.model.open_mapped_doc({
					method: "erpnext.accounts.doctype.sales_invoice.sales_invoice.make_delivery_note",
					frm,
				});
			},
			__("Create"),
		);
	},
});

frappe.ui.form.on("Sales Invoice Item", {
	item_code(frm, cdt, cdn) {
		const row = locals[cdt][cdn];
		if (!row.item_code) {
			return;
		}
		frappe.db.get_value("Item", row.item_code, "item_name").then(({ message }) => {
			if (message?.item_name) {
				frappe.model.set_value(cdt, cdn, "description", message.item_name);
			}
		});
	},
});
