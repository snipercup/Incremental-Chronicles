class_name TimedAction
extends StoryAction

var time_limit: float = 5.0
var timer: Timer = null

func _init(data: Dictionary = {}) -> void:
	super(data)
	time_limit = data.get("time_limit", 5.0)
	timer = Timer.new()
	timer.wait_time = time_limit
	timer.timeout.connect(_on_timeout)
	#add_child(timer)

func perform_action() -> void:
	print("Starting timed action: %s" % story_text)
	timer.start()

func _on_timeout() -> void:
	print("Failed to complete action in time: %s" % story_text)

func get_icon() -> String:
	return "⏳"
