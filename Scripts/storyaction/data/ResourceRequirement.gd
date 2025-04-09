# ResourceRequirement.gd
class_name ResourceRequirement
extends RefCounted

# === AMOUNT REQUIREMENTS ===
# These require the resource to have at least this amount in each group
var required_amount_visible: float = 0.0
var required_amount_hidden: float = 0.0
var required_amount_permanent: float = 0.0

# === APPEAR REQUIREMENTS ===
# These define min/max range checks for a resource group
var appear_min_visible: float = -INF
var appear_max_visible: float = INF

var appear_min_hidden: float = -INF
var appear_max_hidden: float = INF

var appear_min_permanent: float = -INF
var appear_max_permanent: float = INF

# === CONSUME REQUIREMENTS ===
# These values will be subtracted from the corresponding resource group
var consume_visible: float = 0.0
var consume_hidden: float = 0.0
var consume_permanent: float = 0.0

# === SUM CHECK ===
# This value is compared against the total of all groups
var required_total_sum: float = 0.0


# === VALIDATION ===

# Checks if a given resource fulfills all requirements
func can_fulfill(resource: ResourceData) -> bool:
	# Check per-group amounts
	if resource.get_visible() < required_amount_visible:
		return false
	if resource.get_hidden() < required_amount_hidden:
		return false
	if resource.get_permanent() < required_amount_permanent:
		return false

	# Check appear min/max bounds
	if resource.get_visible() < appear_min_visible or resource.get_visible() > appear_max_visible:
		return false
	if resource.get_hidden() < appear_min_hidden or resource.get_hidden() > appear_max_hidden:
		return false
	if resource.get_permanent() < appear_min_permanent or resource.get_permanent() > appear_max_permanent:
		return false

	# Check consume (sufficient to consume)
	if resource.get_visible() < consume_visible:
		return false
	if resource.get_hidden() < consume_hidden:
		return false
	if resource.get_permanent() < consume_permanent:
		return false

	# Check total sum (optional)
	if required_total_sum > 0.0 and resource.get_total() < required_total_sum:
		return false

	return true

# Subtracts the defined consume values from the resource
func consume_from(resource: ResourceData) -> void:
	resource.remove_visible(consume_visible)
	resource.remove_hidden(consume_hidden)
	resource.remove_permanent(consume_permanent)

# Parses a structured dictionary into this requirement instance.
# Example:
# {
#   "consume": { "visible": 10 },
#   "amount": { "hidden": 5 },
#   "appear": { "permanent": { "min": 2 } },
#   "sum": 25
# }
func from_dict(data: Dictionary) -> void:
	if data.has("consume"):
		var consume = data["consume"]
		consume_visible = consume.get("visible", 0.0)
		consume_hidden = consume.get("hidden", 0.0)
		consume_permanent = consume.get("permanent", 0.0)

	if data.has("amount"):
		var amount = data["amount"]
		required_amount_visible = amount.get("visible", 0.0)
		required_amount_hidden = amount.get("hidden", 0.0)
		required_amount_permanent = amount.get("permanent", 0.0)

	if data.has("appear"):
		var appear = data["appear"]
		if appear.has("visible"):
			var myrange = appear["visible"]
			appear_min_visible = myrange.get("min", -INF)
			appear_max_visible = myrange.get("max", INF)
		if appear.has("hidden"):
			var myrange = appear["hidden"]
			appear_min_hidden = myrange.get("min", -INF)
			appear_max_hidden = myrange.get("max", INF)
		if appear.has("permanent"):
			var myrange = appear["permanent"]
			appear_min_permanent = myrange.get("min", -INF)
			appear_max_permanent = myrange.get("max", INF)

	if data.has("sum"):
		required_total_sum = data["sum"]

# Returns true if only the "appear" requirements are fulfilled
func does_appear_requirements_pass(resource: ResourceData) -> bool:
	# Visible bounds check
	var visible := resource.get_visible()
	if visible < appear_min_visible or visible > appear_max_visible:
		return false

	# Hidden bounds check
	var hidden := resource.get_hidden()
	if hidden < appear_min_hidden or hidden > appear_max_hidden:
		return false

	# Permanent bounds check
	var permanent := resource.get_permanent()
	if permanent < appear_min_permanent or permanent > appear_max_permanent:
		return false

	return true

# Returns true if any appear requirement is active
func has_appear_requirements() -> bool:
	return (
		appear_min_visible > -INF or appear_max_visible < INF or
		appear_min_hidden > -INF or appear_max_hidden < INF or
		appear_min_permanent > -INF or appear_max_permanent < INF
	)
