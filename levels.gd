extends Node


# Cada nível é uma lista de inimigos.
# "tempo" = quando o inimigo aparece
# "posicao" = onde ele aparece
# "inimigo" = qual tipo de inimigo é

var levels = [
	# =========================
	# NOITE 1
	# =========================
	[
		{
			"tempo": 2.0,
			"posicao": "esquerda",
			"inimigo": "normal"
		},
		{
			"tempo": 4.0,
			"posicao": "direita",
			"inimigo": "rapido"
		},
		{
			"tempo": 7.0,
			"posicao": "centro",
			"inimigo": "lento"
		},
		{
			"tempo": 8.0,
			"posicao": "esquerda",
			"inimigo": "falso"
		}
	],

	# =========================
	# NOITE 2
	# =========================
	[
		{
			"tempo": 2.0,
			"posicao": "direita",
			"inimigo": "normal"
		},
		{
			"tempo": 4.0,
			"posicao": "esquerda",
			"inimigo": "rapido"
		},
		{
			"tempo": 6.0,
			"posicao": "centro",
			"inimigo": "lento"
		},
		{
			"tempo": 8.0,
			"posicao": "direita",
			"inimigo": "falso"
		}
	],

	# =========================
	# NOITE 3
	# =========================
	[
		{
			"tempo": 2.0,
			"posicao": "centro",
			"inimigo": "normal"
		},
		{
			"tempo": 3.8,
			"posicao": "esquerda",
			"inimigo": "rapido"
		},
		{
			"tempo": 5.8,
			"posicao": "direita",
			"inimigo": "normal"
		},
		{
			"tempo": 7.8,
			"posicao": "centro",
			"inimigo": "lento"
		},
		{
			"tempo": 8.5,
			"posicao": "esquerda",
			"inimigo": "falso"
		}
	],

	# =========================
	# NOITE 4
	# =========================
	[
		{
			"tempo": 1.8,
			"posicao": "direita",
			"inimigo": "normal"
		},
		{
			"tempo": 3.5,
			"posicao": "centro",
			"inimigo": "rapido"
		},
		{
			"tempo": 5.5,
			"posicao": "esquerda",
			"inimigo": "normal"
		},
		{
			"tempo": 7.5,
			"posicao": "direita",
			"inimigo": "lento"
		},
		{
			"tempo": 9.5,
			"posicao": "centro",
			"inimigo": "falso"
		},
		{
			"tempo": 11.5,
			"posicao": "esquerda",
			"inimigo": "normal"
		}
	]
]
