extends NobodyWhoChat

signal action_generated(action: String)

func _ready():
	start_worker()


func generate_action() -> void:
	start_worker()
	var mysampler: NobodyWhoSampler = sampler
	mysampler.seed = randi()  # Set seed to a random integer
	# say something
	say("What is the next action I can do in this village? Return exactly one action.")

	# wait for the response
	var response = await response_finished
	print("Got response: " + response)
	action_generated.emit(response)
