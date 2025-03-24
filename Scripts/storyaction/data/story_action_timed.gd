class_name TimedAction
extends StoryAction

var time_limit: float = 5.0
var timer: Timer = null

func _init(data: Dictionary = {}, myarea: StoryArea = null) -> void:
	super(data, myarea)
	time_limit = data.get("time_limit", 5.0)
	timer = Timer.new()
	timer.wait_time = time_limit
	timer.timeout.connect(_on_timeout)

func perform_action() -> void:
	print("Starting timed action: %s" % story_text)
	timer.start()

func _on_timeout() -> void:
	print("Failed to complete action in time: %s" % story_text)

func get_icon() -> String:
	return "⏳"
