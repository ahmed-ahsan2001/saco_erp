"""One-time SACO site setup. Extend as custom features are added."""

import frappe


def run():
	"""Placeholder setup hook — add company defaults, roles, and custom fields here."""
	frappe.msgprint("SACO Management app is installed. Add setup steps in saco_setup.run as needed.")
