extends Control

@export var action_generator: NobodyWhoChat = null
@export var action_list: VBoxContainer = null

var can_generate: bool = true

# Called when the node enters the scene tree.
func _ready():
	# Create a Timer node dynamically
	var timer = Timer.new()
	timer.wait_time = 1.0  # 1 second interval
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)  # Connect the signal to the callback function
	add_child(timer)  # Add the Timer as a child of this node
	action_generator.action_generated.connect(_action_generated)

# Called every second when the Timer times out
func _on_timer_timeout():
	if not can_generate:
		return
	#action_generator.generate_action()
	can_generate = false
	print("Hello, World!")

func _action_generated(action: String):
	can_generate = true
	
	# Create a new Button
	var button = Button.new()
	button.text = action  # Set button text to the action value
	
	# Connect the button's pressed signal to a lambda that prints the text and frees the button
	button.pressed.connect(func():
		print(button.text)
		button.queue_free()
	)
	
	# Add the button to the action_list
	action_list.add_child(button)
