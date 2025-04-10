class_name LoopAction
extends StoryAction

var ui_scene: PackedScene = preload("res://Scenes/action/story_action_loop_ui.tscn")
var cooldown: float = 1.0
# Add this line to declare the new property with a default value
var max_loops: int = -1

# --- Loop state tracking ---
var elapsed_time: float = 0.0
var is_looping: bool = false
var current_loops: int = 0

func _init(data: Dictionary, myarea: StoryArea = null) -> void:
	super(data, myarea)
	cooldown = data.get("cooldown", 1.0)
	max_loops = data.get("max_loops", -1)  # Retrieve from data or use default

func perform_action() -> void:
	print("Performed loop action: %s" % [story_text])

func get_cooldown() -> float:
	return cooldown

func get_max_loops() -> float:
	return max_loops

func get_icon() -> String:
	return "🔁"

# Returns the type as specified in the json
func get_type() -> String:
	return "loop"

# Called from UI every frame
func process_loop(delta: float, active_action: StoryAction, resource_manager: Node) -> bool:
	if not is_looping:
		return false

	elapsed_time += delta
	var cooldown_duration := get_cooldown()

	# Loop complete
	if elapsed_time >= cooldown_duration:
		elapsed_time = 0.0

		# Stop if at capacity
		if resource_manager.are_all_at_capacity(get_rewards().keys()):
			is_looping = false
			return false

		# Reward and update signals
		SignalBroker.action_rewarded.emit(self)

		current_loops += 1

		if get_max_loops() > -1 and current_loops >= get_max_loops():
			is_looping = false
			SignalBroker.action_removed.emit(self)
			return false

		# Stop looping if user changed active action
		if active_action != self:
			is_looping = false
			return false

		# Otherwise continue looping
		is_looping = true

	return true  # Loop in progress

# Called by UI when user clicks the loop button
func start_loop() -> void:
	elapsed_time = 0.0
	is_looping = true
	#current_loops = 0

# Called to manually cancel the loop (e.g., another action selected)
func cancel_loop() -> void:
	elapsed_time = 0.0
	is_looping = false

# Returns cooldown progress as a percentage (0–100)
func get_progress_percent() -> float:
	if cooldown <= 0.0:
		return 0.0
	return clamp((elapsed_time / cooldown) * 100.0, 0.0, 100.0)
