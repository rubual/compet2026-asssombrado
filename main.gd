extends Node2D

var dados = preload("res://levels.gd").new()

var level_atual = 0
var fantasma_atual = 0
var tempo_level = 0.0

var jogo_iniciado = false
var jogo_terminou = false
var mudando_level = false
var lanterna_pressionada = false # Para evitar spam do is_key_pressed
var pode_reiniciar = false # Trava de segurança para não pular menus acidentalmente

# Efeitos Visuais e Sonoros
var shake_intensity = 0.0
@onready var bg = $TextureRect
var flash_luz = ColorRect.new()
var som_lanterna = AudioStreamPlayer.new()
var som_jumpscare = AudioStreamPlayer.new()
var som_inimigo_derrotado = AudioStreamPlayer.new()

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
	# Oculta o cursor do mouse, já que o foco é o hardware/lanterna (Kiosk mode)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	# Esconde as telas no começo
	game_over_tela.visible = false
	jumpscare.visible = false
	vitoria_tela.visible = false
	indicacao_level.visible = false
	
	# Configura o Flash de Luz da Lanterna
	flash_luz.color = Color(1, 1, 0.8, 0.0) # Amarelo transparente
	flash_luz.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_luz.mouse_filter = Control.MOUSE_FILTER_IGNORE # <--- DEIXA O CLIQUE PASSAR
	$Interface.add_child(flash_luz)
	
	# Adiciona os tocadores de som à cena
	add_child(som_lanterna)
	add_child(som_jumpscare)
	add_child(som_inimigo_derrotado)
	# TODO: Depois você pode arrastar arquivos de áudio para cá:
	# som_lanterna.stream = preload("res://caminho_do_som.mp3")

	# Mostra o menu
	$Interface/Menu.visible = true


func _process(delta):
	# === NOVA LÓGICA DE INPUT GLOBAL ===
	var acionou = false
	var direcao = ""

	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		direcao = "esquerda"
		acionou = true
	elif Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		direcao = "centro"
		acionou = true
	elif Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		direcao = "direita"
		acionou = true

	var disparou_agora = false
	if acionou and not lanterna_pressionada:
		lanterna_pressionada = true
		disparou_agora = true
	elif not acionou:
		lanterna_pressionada = false
	# ====================================

	# Se o jogo ainda não começou, qualquer luz inicia o jogo!
	if not jogo_iniciado:
		if disparou_agora:
			_on_botao_iniciar_pressed()
		return

	# Se o jogo terminou, qualquer luz reinicia o jogo (respeitando a trava de tempo)
	if jogo_terminou:
		if disparou_agora and pode_reiniciar:
			_on_botao_tentar_novamente_pressed()
		return

	# Daqui pra baixo é o jogo rodando normalmente...
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

	# Efeito de Flash desaparecendo gradualmente
	if flash_luz.color.a > 0:
		flash_luz.color.a -= delta * 3.0

	# Efeito de Screen Shake (tensão aumentando)
	if shake_intensity > 0:
		bg.position = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		shake_intensity = lerpf(shake_intensity, 0.0, 5 * delta)
	else:
		bg.position = Vector2(-2, 2) # Posição original do bg

	# Se o jogador apontou a lanterna durante o gameplay
	if disparou_agora:
		testar_lanterna(direcao)

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
		
		# Aumenta a tensão (shake) se o inimigo for verdadeiro e estiver prestes a atacar
		if inimigo.tipo != "falso" and inimigo.tempo_restante < 1.0:
			shake_intensity = (1.0 - inimigo.tempo_restante) * 15.0

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
	# FUNÇÃO DESATIVADA: A lógica de checar o botão foi movida para o topo do _process()
	# Isso permite usar a lanterna não só para atirar, mas também para clicar nos menus!
	pass


func testar_lanterna(direcao):
	# Efeitos visuais e sonoros da lanterna acendendo
	flash_luz.color.a = 0.4
	som_lanterna.play()

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
		
		# Feedback de acerto
		som_inimigo_derrotado.play()
		flash_luz.color = Color(0.8, 1.0, 0.8, 0.6) # Pisca verde rápido

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
	som_jumpscare.play()
	shake_intensity = 0.0
	bg.position = Vector2(-2, 2)
	pode_reiniciar = false # Trava para não pular o Jumpscare sem querer

	# Remove todos os inimigos
	for inimigo in inimigos_ativos:
		inimigo.node.queue_free()

	inimigos_ativos.clear()

	# Mostra Game Over
	jumpscare.visible = true
	game_over_tela.visible = true

	# Aguarda 1.5s antes de permitir que a lanterna reinicie o jogo
	await get_tree().create_timer(1.5).timeout
	pode_reiniciar = true


func vitoria():
	jogo_terminou = true
	pode_reiniciar = false

	# Remove todos os inimigos
	for inimigo in inimigos_ativos:
		inimigo.node.queue_free()

	inimigos_ativos.clear()

	# Mostra a tela de vitória
	vitoria_tela.visible = true
	
	# Aguarda 1.0s antes de permitir que a lanterna reinicie o jogo
	await get_tree().create_timer(1.0).timeout
	pode_reiniciar = true


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
