extends Control

# TODO - Detect size

func _init():
	# TODO - Adjust per image! Hardcoded doesn't feel right
	var view_y = (Lt2Constants.RESOLUTION_TARGET.y / 2) - 620
	
	scale.x = float(Lt2Constants.RESOLUTION_TARGET.x) / 768
	scale.y = float(Lt2Constants.RESOLUTION_TARGET.y / 2) / 620
	scale.x = max(scale.x, scale.y)
	
	# If we have maximised the y-axis, don't offset Y
	if scale.x == scale.y:
		view_y = 0
	
	scale.y = scale.x
	position.x = (-768 / 2) * scale.x
	position.y = (view_y / 2) * scale.y
