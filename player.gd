extends Node2D

var direcao = "centro"

func _process(_delta):
	var nova_direcao = direcao

	if Input.is_key_pressed(KEY_A):
		nova_direcao = "esquerda"

	if Input.is_key_pressed(KEY_S):
		nova_direcao = "centro"

	if Input.is_key_pressed(KEY_D):
		nova_direcao = "direita"

	if nova_direcao != direcao:
		direcao = nova_direcao
		print(direcao)
