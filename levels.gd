extends Node


# Cada nível é uma lista de inimigos.
# "tempo" = quando o inimigo aparece
# "posicao" = onde ele aparece
# "inimigo" = qual tipo de inimigo é

var levels = [
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
			"tempo": 9.0,
			"posicao": "esquerda",
			"inimigo": "falso"
		}
	],


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
	]
]
