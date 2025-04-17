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
# Action/area will appear if regeneration amounts are met
var appear_min_regeneration: float = -INF # "Focus": { "appear": { "regeneration": { "min": 1.0 } } }
var appear_max_regeneration: float = INF # "Focus": { "appear": { "regeneration": { "max": 0.0 } } }
var appear_min_permanent_capacity: float = -INF
var appear_max_permanent_capacity: float = INF
var appear_min_temporary_capacity: float = -INF
var appear_max_temporary_capacity: float = INF

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
# Max regeneration: { "appear": { "regeneration": { "max": 1.0 } } }
func from_dict(data: Variant) -> void:
	if typeof(data) == TYPE_FLOAT or typeof(data) == TYPE_INT:
		required_amount = float(data)
		return

	if data.has("consume"):
		var consume_data = data["consume"]
		var amount = float(consume_data)
		var is_permanent = data.get("permanent", false)
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
		if appear_data.has("regeneration"):
			var regen_data = appear_data["regeneration"]
			appear_min_regeneration = regen_data.get("min", -INF)
			appear_max_regeneration = regen_data.get("max", INF)
		if appear_data.has("permanent_capacity"):
			var regen_data = appear_data["permanent_capacity"]
			appear_min_permanent_capacity = regen_data.get("min", -INF)
			appear_max_permanent_capacity = regen_data.get("max", INF)
		if appear_data.has("temporary_capacity"):
			var regen_data = appear_data["temporary_capacity"]
			appear_min_temporary_capacity = regen_data.get("min", -INF)
			appear_max_temporary_capacity = regen_data.get("max", INF)


# Returns true if only the "appear" requirements are fulfilled
func does_appear_requirements_pass(resource: ResourceData) -> bool:
	var total: float = resource.get_total()
	var regen: float = resource.regeneration
	var temporary_capacity: float = resource.temporary_capacity
	var permanent_capacity: float = resource.permanent_capacity
	# Debug info for total value check
	#print("🧪 Checking appear requirements for resource:", resource.name, "  [RAW] total=%.20f, min=%.20f, max=%.20f" % [total, appear_min_total, appear_max_total])

	# Check total value bounds (broken up)
	var fail_min: bool = total < appear_min_total
	var fail_max: bool = total > appear_max_total

	#print("  Check: total < min →", fail_min, "  Check: total > max →", fail_max)
	if fail_min or fail_max:
		return false

	# Check regeneration bounds
	if regen < appear_min_regeneration or regen > appear_max_regeneration:
		return false

	# Check temporary_capacity bounds
	if temporary_capacity < appear_min_temporary_capacity or temporary_capacity > appear_max_temporary_capacity:
		return false

	# Check permanent_capacity bounds
	if permanent_capacity < appear_min_permanent_capacity or permanent_capacity > appear_max_permanent_capacity:
		return false

	return true

# Returns true if any appear requirement is active
func has_appear_requirements() -> bool:
	return (
		appear_min_total > -INF or
		appear_max_total < INF or
		appear_min_temporary_capacity > -INF or
		appear_max_temporary_capacity < INF or
		appear_min_permanent_capacity > -INF or
		appear_max_permanent_capacity < INF or
		appear_min_regeneration > -INF or
		appear_max_regeneration < INF
	)


# Returns true if any requirement other then appear is active
func has_resource_requirements() -> bool:
	return required_amount > 0 or consume_temporary > 0 or consume_permanent > 0
