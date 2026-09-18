"""SACO site setup — brands, items, selling defaults."""

from __future__ import annotations

import frappe

from saco_management.setup.custom_fields import ensure_custom_fields
from saco_management.setup.import_items import run as import_items


def run(company: str | None = None, import_data: bool = True):
	"""Run after ERPNext setup wizard.

	  bench --site SITE execute saco_management.setup.saco_setup.run
	"""
	frappe.only_for("System Manager")
	company = company or frappe.defaults.get_global_default("company")
	if not company:
		frappe.throw("Complete the ERPNext Setup Wizard and set a default Company first.")

	ensure_custom_fields()
	frappe.clear_cache(doctype="Item")
	configure_selling_defaults(company)

	result = None
	if import_data:
		result = import_items(company=company)

	frappe.db.commit()
	message = "SACO setup complete."
	if result:
		message += (
			f" Imported {result['total']} items "
			f"({result['created']} new, {result['updated']} updated). "
			f"Use price list 'SACO Selling' on Sales Invoices."
		)
	print(message)
	if result:
		print(result)
	return result


def configure_selling_defaults(company: str) -> None:
	"""Invoice first, then delivery note; search items by code."""
	selling = frappe.get_single("Selling Settings")
	selling.customer_group = selling.customer_group or "All Customer Groups"
	selling.territory = selling.territory or "All Territories"
	selling.sales_update_frequency = "Each Transaction"
	selling.save(ignore_permissions=True)

	accounts = frappe.get_single("Accounts Settings")
	if hasattr(accounts, "unlink_payment_on_cancellation_of_invoice"):
		accounts.unlink_payment_on_cancellation_of_invoice = 1
	accounts.save(ignore_permissions=True)
