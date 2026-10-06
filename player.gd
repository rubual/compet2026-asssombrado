extends Node2D

var direcao = "centro"

func _process(_delta):
	var nova_direcao = direcao

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("ui_left") or Input.is_joy_button_pressed(0, JOY_BUTTON_A):
		nova_direcao = "esquerda"

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("ui_up") or Input.is_joy_button_pressed(0, JOY_BUTTON_B):
		nova_direcao = "centro"

	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("ui_right") or Input.is_joy_button_pressed(0, JOY_BUTTON_X):
		nova_direcao = "direita"

	if nova_direcao != direcao:
		direcao = nova_direcao
		print(direcao)
