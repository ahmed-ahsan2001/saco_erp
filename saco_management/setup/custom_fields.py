import frappe
from frappe.custom.doctype.custom_field.custom_field import create_custom_fields

ITEM_FIELDS = [
	{
		"fieldname": "saco_brand",
		"fieldtype": "Link",
		"label": "Brand",
		"options": "Item Group",
		"insert_after": "item_group",
		"in_list_view": 1,
		"in_standard_filter": 1,
	},
	{
		"fieldname": "net_weight",
		"fieldtype": "Data",
		"label": "Net Weight",
		"insert_after": "saco_brand",
		"in_list_view": 1,
	},
	{
		"fieldname": "carton_packing",
		"fieldtype": "Data",
		"label": "Carton Packing",
		"insert_after": "net_weight",
	},
]


def ensure_custom_fields():
	create_custom_fields({"Item": ITEM_FIELDS})
