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
var cortina_preta = ColorRect.new() # Camada global de Fade
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

# Referências aos Textos e Botões para animação
@onready var texto_game_over = $Interface/GameOver/Jumpscare/Texto
@onready var texto_vitoria = $Interface/Vitoria/TextoVitoria
@onready var texto_level = $Interface/IndicacaoLevel/TextoLevel
@onready var botao_iniciar = $Interface/Menu/BotaoIniciar
@onready var botao_tentar = $Interface/GameOver/BotaoTentarNovamente

# Nova Logo do Jogo
var logo_jogo = TextureRect.new()


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
	
	# Cortina de Fade global
	cortina_preta.color = Color(0, 0, 0, 1.0) # Começa tudo preto
	cortina_preta.set_anchors_preset(Control.PRESET_FULL_RECT)
	cortina_preta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cortina_preta.z_index = 100
	$Interface.add_child(cortina_preta)
	
	# Animação de entrada suave ao abrir o jogo
	var tween_abertura = create_tween()
	tween_abertura.tween_property(cortina_preta, "color:a", 0.0, 2.5) # Prolongado para 2.5s
	tween_abertura.tween_callback(func(): botao_iniciar.visible = true) # Revela o texto após a logo aparecer
	
	# Adiciona os tocadores de som à cena
	add_child(som_lanterna)
	add_child(som_jumpscare)
	add_child(som_inimigo_derrotado)
	# TODO: Depois você pode arrastar arquivos de áudio para cá:
	# som_lanterna.stream = preload("res://caminho_do_som.mp3")

	# Esconde o relógio estático que estava sobrando
	relogio.visible = false

	# Aplica o novo visual de Arcade e Terror nos textos
	_configurar_textos()

	# Mostra o menu
	$Interface/Menu.visible = true


func _configurar_textos():
	# Expande o Menu para cobrir a tela inteira, para que as âncoras dos filhos funcionem
	$Interface/Menu.set_anchors_preset(Control.PRESET_FULL_RECT)

	# ==== CONFIGURAÇÃO DA LOGO ====
	logo_jogo.texture = preload("res://assets/AsSsombradoLogo.png")
	logo_jogo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_jogo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_jogo.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	logo_jogo.offset_left = 0
	logo_jogo.offset_right = 0
	logo_jogo.offset_top = 50
	logo_jogo.offset_bottom = 400
	$Interface/Menu.add_child(logo_jogo)
	
	# Animação macabra da logo (Flutuação e Mudança de Brilho)
	var tween_logo = create_tween().set_loops()
	# Ela desce suavemente e escurece um pouco
	tween_logo.tween_property(logo_jogo, "position:y", 65.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_logo.parallel().tween_property(logo_jogo, "modulate", Color(0.6, 0.6, 0.6, 1.0), 3.0).set_trans(Tween.TRANS_SINE)
	# Ela sobe suavemente e recupera o brilho
	tween_logo.tween_property(logo_jogo, "position:y", 35.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_logo.parallel().tween_property(logo_jogo, "modulate", Color(1.0, 1.0, 1.0, 1.0), 3.0).set_trans(Tween.TRANS_SINE)
	# ==============================

	# ==== FONTES DO SISTEMA ====
	var fonte_arcade = SystemFont.new()
	fonte_arcade.font_names = PackedStringArray(["Consolas", "Courier New", "Impact"])
	
	var fonte_macabra = SystemFont.new()
	fonte_macabra.font_names = PackedStringArray(["Chiller", "Impact", "Georgia"])

	# Estilização Profissional dos Botões
	botao_iniciar.flat = true
	botao_iniciar.text = "APONTE A LANTERNA PARA INICIAR"
	botao_iniciar.alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao_iniciar.add_theme_font_override("font", fonte_arcade)
	botao_iniciar.add_theme_font_size_override("font_size", 38)
	botao_iniciar.add_theme_color_override("font_color", Color(0.3, 0.9, 0.8)) # Ciano Sombrio
	botao_iniciar.add_theme_constant_override("outline_size", 8)
	botao_iniciar.add_theme_color_override("font_outline_color", Color.BLACK)
	botao_iniciar.visible = false # Oculto até a logo carregar
	
	botao_tentar.flat = true
	botao_tentar.text = "APONTE A LANTERNA PARA TENTAR DE NOVO"
	botao_tentar.alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao_tentar.add_theme_font_override("font", fonte_arcade)
	botao_tentar.add_theme_font_size_override("font_size", 28)
	botao_tentar.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2)) # Dourado Alaranjado
	botao_tentar.add_theme_constant_override("outline_size", 6)
	botao_tentar.add_theme_color_override("font_outline_color", Color.BLACK)
	# Prende no topo da tela
	botao_tentar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	botao_tentar.offset_top = 50
	botao_tentar.offset_bottom = 110

	# Animação de Piscar (Blinking) Infinita para os textos de continuar
	var tween_botoes = create_tween().set_loops()
	tween_botoes.tween_property(botao_iniciar, "modulate:a", 0.2, 0.6)
	tween_botoes.parallel().tween_property(botao_tentar, "modulate:a", 0.2, 0.6)
	tween_botoes.tween_property(botao_iniciar, "modulate:a", 1.0, 0.6)
	tween_botoes.parallel().tween_property(botao_tentar, "modulate:a", 1.0, 0.6)
	
	# Estilo do Game Over (Tensão) e Centralização
	texto_game_over.text = "VOCÊ FOI PEGO..."
	texto_game_over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_game_over.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto_game_over.set_anchors_preset(Control.PRESET_HCENTER_WIDE)
	texto_game_over.offset_left = 0
	texto_game_over.offset_right = 0
	texto_game_over.offset_top = 100
	texto_game_over.offset_bottom = 300
	
	if texto_game_over.label_settings:
		texto_game_over.label_settings.font = fonte_macabra
		texto_game_over.label_settings.font_color = Color(0.7, 0.0, 0.0) # Sangue escuro
		texto_game_over.label_settings.shadow_color = Color(0, 0, 0, 1.0)
		texto_game_over.label_settings.shadow_size = 15
		texto_game_over.label_settings.outline_size = 8
		texto_game_over.label_settings.outline_color = Color.BLACK
		
	# Estilo da Vitória e Animação de Respiração (Pulsar)
	texto_vitoria.text = "SOBREVIVEU À NOITE!"
	if texto_vitoria.label_settings:
		texto_vitoria.label_settings.font_color = Color(1, 0.8, 0) # Dourado
		texto_vitoria.label_settings.shadow_color = Color(0, 0, 0, 0.7)
		texto_vitoria.label_settings.shadow_size = 5
		
	# Para pulsar a partir do centro, garantimos que o texto esteja centralizado na tela
	texto_vitoria.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_vitoria.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto_vitoria.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto_vitoria.pivot_offset = Vector2(1152/2, 648/2) # Centro aproximado da tela
	
	var tween_vitoria = create_tween().set_loops()
	tween_vitoria.tween_property(texto_vitoria, "scale", Vector2(1.05, 1.05), 1.0).set_trans(Tween.TRANS_SINE)
	tween_vitoria.tween_property(texto_vitoria, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)


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

	# INTERROMPE COMPLETAMENTE O FLUXO DO JOGO DURANTE QUALQUER TRANSIÇÃO
	if mudando_level:
		return

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


	# ==== Animações do Fantasma ====
	# Surgimento (Fade In)
	inimigo.modulate.a = 0.0
	var tween_spawn = create_tween()
	tween_spawn.tween_property(inimigo, "modulate:a", 1.0, 0.6)
	
	# Flutuação (Hover) contínua
	var tween_float = create_tween().set_loops()
	var base_y = inimigo.position.y
	tween_float.tween_property(inimigo, "position:y", base_y - 15.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_float.tween_property(inimigo, "position:y", base_y, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# ===============================


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
	
	# Texto de introdução da Fase e Transição Suave (Fade In/Out)
	texto_level.text = "NOITE " + str(level_atual + 1)
	texto_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto_level.set_anchors_preset(Control.PRESET_FULL_RECT)

	indicacao_level.visible = true
	indicacao_level.modulate.a = 0.0
	
	var tween_entrada = create_tween()
	tween_entrada.tween_property(indicacao_level, "modulate:a", 1.0, 0.5)

	await get_tree().create_timer(2.0).timeout
	
	var tween_saida = create_tween()
	tween_saida.tween_property(indicacao_level, "modulate:a", 0.0, 0.5)
	await tween_saida.finished

	indicacao_level.visible = false
	mudando_level = false


func game_over():
	mudando_level = false
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
	mudando_level = false
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
	mudando_level = true
	
	var tween = create_tween()
	tween.tween_property(cortina_preta, "color:a", 1.0, 0.5)
	await tween.finished

	jogo_iniciado = true
	jogo_terminou = false
	level_atual = -1 # Começa no -1 porque o proximo_level vai somar +1
	
	$Interface/Menu.visible = false

	# A própria função proximo_level já tem sua tela preta de "NOITE X"
	# Então nós apenas ocultamos a cortina global instantaneamente para ela assumir
	cortina_preta.color.a = 0.0
	proximo_level()


func _on_botao_tentar_novamente_pressed():
	mudando_level = true
	
	var tween = create_tween()
	tween.tween_property(cortina_preta, "color:a", 1.0, 0.8)
	await tween.finished

	# Retorna para o Menu Inicial de forma limpa
	jogo_iniciado = false
	jogo_terminou = false
	pode_reiniciar = false

	level_atual = 0
	fantasma_atual = 0
	tempo_level = 0.0

	for inimigo in inimigos_ativos:
		inimigo.node.queue_free()

	inimigos_ativos.clear()

	game_over_tela.visible = false
	jumpscare.visible = false
	vitoria_tela.visible = false

	$Interface/Menu.visible = true
	
	var tween_out = create_tween()
	tween_out.tween_property(cortina_preta, "color:a", 0.0, 0.8)
	await tween_out.finished
	
	mudando_level = false
