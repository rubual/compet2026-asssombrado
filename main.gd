extends Node2D

var dados = preload("res://levels.gd").new()

var level_atual = 0
var fantasma_atual = 0
var tempo_level = 0.0

var jogo_iniciado = false
var jogo_terminou = false
var mudando_level = false

# Guarda todos os inimigos que estão aparecendo
var inimigos_ativos = []


# Cenas dos tipos de inimigos
var cena_normal = preload("res://inimigos/InimigoNormal.tscn")
var cena_rapido = preload("res://inimigos/InimigoRapido.tscn")
var cena_lento = preload("res://inimigos/InimigoLento.tscn")
var cena_falso = preload("res://inimigos/InimigoFalso.tscn")


@onready var pos_esquerda = $PosEsquerda
@onready var pos_centro = $PosCentro
@onready var pos_direita = $PosDireita

@onready var inimigos = $Inimigos

@onready var game_over_tela = $Interface/GameOver
@onready var jumpscare = $Interface/GameOver/Jumpscare
@onready var relogio = $Interface/Relogio
@onready var vitoria_tela = $Interface/Vitoria
@onready var indicacao_level = $Interface/IndicacaoLevel


func _ready():
	# Esconde as telas no começo
	game_over_tela.visible = false
	jumpscare.visible = false
	vitoria_tela.visible = false
	indicacao_level.visible = false

	# Mostra o menu
	$Interface/Menu.visible = true


func _process(delta):
	# Se o jogo ainda não começou, não faz nada.
	if not jogo_iniciado:
		return

	# Se o jogo terminou, não faz nada.
	if jogo_terminou:
		return

	tempo_level += delta

	var eventos = dados.levels[level_atual]

	# Verifica se está na hora de aparecer o próximo inimigo
	if fantasma_atual < eventos.size():
		var evento = eventos[fantasma_atual]

		if tempo_level >= evento.tempo:
			aparecer_inimigo(evento)
			fantasma_atual += 1

	# Atualiza todos os inimigos que estão vivos
	atualizar_inimigos(delta)

	# Verifica se o jogador apontou a lanterna
	verificar_lanterna()

	if jogo_terminou:
		return

	# O nível só termina quando:
	# 1. Todos os inimigos programados já apareceram
	# 2. Não existe mais nenhum inimigo ativo
	if fantasma_atual >= eventos.size() and inimigos_ativos.size() == 0:
		if not mudando_level:
			proximo_level()


func aparecer_inimigo(evento):
	var tipo = evento.inimigo
	var posicao = evento.posicao

	var cena_inimigo = null

	# Escolhe qual cena deve ser criada
	if tipo == "normal":
		cena_inimigo = cena_normal

	elif tipo == "rapido":
		cena_inimigo = cena_rapido

	elif tipo == "lento":
		cena_inimigo = cena_lento

	elif tipo == "falso":
		cena_inimigo = cena_falso

	else:
		print("ERRO: inimigo desconhecido:", tipo)
		return


	# Cria uma NOVA cópia do inimigo
	var inimigo = cena_inimigo.instantiate()

	# Coloca o inimigo dentro do Node2D "Inimigos"
	inimigos.add_child(inimigo)


	# Define a posição dele
	if posicao == "esquerda":
		inimigo.position = pos_esquerda.position

	elif posicao == "centro":
		inimigo.position = pos_centro.position

	elif posicao == "direita":
		inimigo.position = pos_direita.position

	else:
		print("ERRO: posição desconhecida:", posicao)
		inimigo.queue_free()
		return


	# Define o tempo de reação
	var tempo_reacao = 3.0

	if tipo == "normal":
		tempo_reacao = 3.0

	elif tipo == "rapido":
		tempo_reacao = 1.5

	elif tipo == "lento":
		tempo_reacao = 5.0

	elif tipo == "falso":
		# O falso fica na tela por 5 segundos.
		tempo_reacao = 5.0


	# Guarda as informações desse inimigo específico
	inimigos_ativos.append({
		"tipo": tipo,
		"posicao": posicao,
		"node": inimigo,
		"tempo_restante": tempo_reacao
	})

	print("APARECEU:", tipo, "->", posicao)


func atualizar_inimigos(delta):
	# Começamos do final da lista porque podemos remover inimigos.
	for i in range(inimigos_ativos.size() - 1, -1, -1):

		var inimigo = inimigos_ativos[i]

		# Diminui o tempo restante
		inimigo.tempo_restante -= delta

		# O tempo acabou
		if inimigo.tempo_restante <= 0:

			# O falso simplesmente desaparece
			if inimigo.tipo == "falso":
				print("FALSO SUMIU")

				inimigo.node.queue_free()
				inimigos_ativos.remove_at(i)

				continue

			# Os outros inimigos causam Game Over
			print("NÃO MATOU A TEMPO:", inimigo.tipo)

			game_over()
			return


func verificar_lanterna():
	# Por enquanto continuamos usando A/S/D para testar.
	if Input.is_key_pressed(KEY_A):
		testar_lanterna("esquerda")

	if Input.is_key_pressed(KEY_S):
		testar_lanterna("centro")

	if Input.is_key_pressed(KEY_D):
		testar_lanterna("direita")


func testar_lanterna(direcao):

	# Procura um inimigo na direção apontada
	for i in range(inimigos_ativos.size() - 1, -1, -1):

		var inimigo = inimigos_ativos[i]

		# Não está na direção apontada
		if inimigo.posicao != direcao:
			continue


		# Se for falso, perde
		if inimigo.tipo == "falso":
			print("APONTOU PARA O FALSO!")

			game_over()
			return


		# Se for normal, rápido ou lento, mata
		print("MATOU:", inimigo.tipo)

		inimigo.node.queue_free()
		inimigos_ativos.remove_at(i)

		return


func proximo_level():
	mudando_level = true
	level_atual += 1

	# Acabaram todos os níveis
	if level_atual >= dados.levels.size():
		vitoria()
		return


	print("NIVEL:", level_atual + 1)

	# Remove qualquer inimigo que ainda esteja na cena
	for inimigo in inimigos_ativos:
		inimigo.node.queue_free()

	inimigos_ativos.clear()


	# Reinicia o nível
	tempo_level = 0.0
	fantasma_atual = 0

	indicacao_level.visible = true

	await get_tree().create_timer(2.0).timeout

	indicacao_level.visible = false
	mudando_level = false


func game_over():
	jogo_terminou = true

	# Remove todos os inimigos
	for inimigo in inimigos_ativos:
		inimigo.node.queue_free()

	inimigos_ativos.clear()

	# Mostra Game Over
	jumpscare.visible = true
	game_over_tela.visible = true


func vitoria():
	jogo_terminou = true

	# Remove todos os inimigos
	for inimigo in inimigos_ativos:
		inimigo.node.queue_free()

	inimigos_ativos.clear()

	# Mostra a tela de vitória
	vitoria_tela.visible = true


func iniciar_level():
	tempo_level = 0.0
	fantasma_atual = 0
	inimigos_ativos.clear()


func _on_botao_iniciar_pressed():
	jogo_iniciado = true
	jogo_terminou = false
	level_atual = 0

	$Interface/Menu.visible = false

	iniciar_level()


func _on_botao_tentar_novamente_pressed():
	jogo_iniciado = true
	jogo_terminou = false
	mudando_level = false

	level_atual = 0
	fantasma_atual = 0
	tempo_level = 0.0

	for inimigo in inimigos_ativos:
		inimigo.node.queue_free()

	inimigos_ativos.clear()

	game_over_tela.visible = false
	jumpscare.visible = false
	vitoria_tela.visible = false

	$Interface/Menu.visible = false

	iniciar_level()
