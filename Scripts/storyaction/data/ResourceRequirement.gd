# ResourceRequirement.gd
class_name ResourceRequirement
extends RefCounted

# === AMOUNT REQUIREMENTS ===
# Replace visible/hidden with a single temporary value
var required_amount: float = 0.0

# === APPEAR REQUIREMENTS ===
# No longer group-specific — just one total-based check
var appear_min_total: float = -INF
var appear_max_total: float = INF

# === CONSUME REQUIREMENTS ===
# Use separate flags for temp vs perm consumption
var consume_temporary: float = 0.0
var consume_permanent: float = 0.0


# === VALIDATION ===

# Checks if a given resource fulfills all requirements
func can_fulfill(resource: ResourceData) -> bool:
	var total := resource.get_total()
	if total < required_amount:
		return false

	# Appear requirement — uses total only
	if total < appear_min_total or total > appear_max_total:
		return false

	# Check if enough to consume
	if resource.get_temporary() < consume_temporary:
		return false
	if resource.get_permanent() < consume_permanent:
		return false

	return true


# Subtracts the defined consume values from the resource
func consume_from(resource: ResourceData) -> void:
	resource.remove_temporary(consume_temporary)
	resource.remove_permanent(consume_permanent)


# Parses a structured dictionary into this requirement instance.
# Example:
# Consume temporary: { "consume": 1.0 }
# Consume permanent: { "consume": 1.0, "permanent": true }
# Appear requirement, no consumption: { "appear": { "min": 1.0, "max": 2.0 } }
# Just a number: 20.0. Player needs at least 20, but nothing is consumed
func from_dict(data: Variant) -> void:
	if typeof(data) == TYPE_FLOAT or typeof(data) == TYPE_INT:
		required_amount = float(data)
		return

	if data.has("consume"):
		var consume_data = data["consume"]
		var amount = float(consume_data)
		var is_permanent = consume_data.get("permanent", false)
		if is_permanent:
			consume_permanent = amount
		else:
			consume_temporary = amount

	if data.has("amount"):
		required_amount = data["amount"] # Support for just "amount", alternative for a single number

	if data.has("appear"):
		var appear_data = data["appear"]
		appear_min_total = appear_data.get("min", -INF)
		appear_max_total = appear_data.get("max", INF)


# Returns true if only the "appear" requirements are fulfilled
func does_appear_requirements_pass(resource: ResourceData) -> bool:
	var total := resource.get_total()
	return total >= appear_min_total and total <= appear_max_total


# Returns true if any appear requirement is active
func has_appear_requirements() -> bool:
	return appear_min_total > -INF or appear_max_total < INF
