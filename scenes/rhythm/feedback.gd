extends TextureRect

var perfect_img = preload("res://assets/images/sprites/perfect.webp")
var good_img = preload("res://assets/images/sprites/good.webp")
var miss_img = preload("res://assets/images/sprites/miss.webp")

func mostrar_feedback(timing: String, success: bool):

	if success and timing == "Perfect":
		texture = perfect_img
	elif success and timing == "Good":
		texture = good_img
	else:
		texture = miss_img

	visible = true
	await get_tree().create_timer(0.5).timeout
	visible = false
