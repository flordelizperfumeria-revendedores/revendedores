extends RefCounted
## Personajes jugables: datos, personalidad de juego y frases.
## Para sumar un personaje: agregar una entrada acá y su dibujo en portrait.gd.

const LIST := ["rex", "cirilo", "yanina"]

const DATA := {
	"rex": {
		"name": "Don Rex",
		"title": "El T-Rex de Tafí",
		"style": "Agresivo",
		"bio": "Tiranosaurio de poncho y sombrero. Canta truco con cualquier cosa y golpea la mesa. Odia que le canten falta envido.",
		"color": Color(0.85, 0.35, 0.15),
		"personality": {"aggression": 0.9, "bluff": 0.35, "envido_bold": 0.75, "chaos": 0.1},
	},
	"cirilo": {
		"name": "Cirilo Amaicha",
		"title": "Gaucho de los cerros",
		"style": "Conservador",
		"bio": "Gaucho viejo y desconfiado. Juega callado, quiere solo con cartas buenas y acusa a todos los dinosaurios de malos perdedores.",
		"color": Color(0.2, 0.45, 0.75),
		"personality": {"aggression": 0.25, "bluff": 0.1, "envido_bold": 0.25, "chaos": 0.05},
	},
	"yanina": {
		"name": "Yanina \"La Brava\"",
		"title": "Reina de la peña",
		"style": "Impredecible",
		"bio": "Cantora de peña, sombrero con pluma y top de piel de dino. Miente sin pestañear, se ríe en tu cara y te canta retruco guiñando un ojo.",
		"color": Color(0.75, 0.2, 0.55),
		"personality": {"aggression": 0.6, "bluff": 0.65, "envido_bold": 0.6, "chaos": 0.45},
	},
}

## Frases por situación. Clave especial "vs_<id>_<situación>" para cruces entre personajes.
const LINES := {
	"rex": {
		"truco": ["¡TRUCO, carajo!", "¡Truco! ¡Y no me mires con esos ojitos de mamífero!", "¡TRUCOOO! ¡GRRAAAH!"],
		"retruco": ["¡Quiero RETRUCO! ¡Los brazos cortos, pero las cartas largas!", "¡Retruco! ¡Te como crudo!"],
		"vale_cuatro": ["¡QUIERO VALE CUATRO! *¡PUM, PUM!*", "¡VALE CUATRO! ¡Se me rompe la mesa pero no el orgullo!"],
		"envido": ["Envido. Y no me mires los dientes.", "¡Envido! Tengo tantos como colmillos."],
		"real_envido": ["¡REAL ENVIDO! ¡Rugido real!", "Real envido, chiquito."],
		"falta_envido": ["¡FALTA ENVIDO! ¡A la extinción!", "Falta envido. Me voy con todo, como el meteorito."],
		"flor": ["¡FLOR! Como las del Jurásico, enormes."],
		"contraflor": ["¡Contraflor! ¡Mi jardín es más grande!"],
		"quiero": ["¡QUIERO! ¡Traé la sal!", "Quiero, y te muerdo.", "¡Obvio que quiero!"],
		"no_quiero": ["No quiero... ¡pero que conste que estoy furioso!", "Grrr... no quiero.", "Paso. Me duele la cola."],
		"achico": ["Con flor me achico... grrr."],
		"mazo": ["¡Me voy al mazo antes de comerme la mesa!"],
		"falta_received": ["¡¿FALTA ENVIDO A MÍ?! ¡GRRRAAAAAH! ¡RESPETÁ AL REY LAGARTO!", "¡¿Falta envido?! ¡Me hierve la sangre fría!"],
		"win_baza": ["¡Ñam!", "¡Esa es mía!", "¡Comida!"],
		"win_hand": ["¡JA! ¡Mordiste el polvo!", "¡Rey de los Valles!", "¡Otra para el T-Rex! *golpe de cola*"],
		"lose_hand": ["¡Esto es un fraude jurásico!", "¡Grrr! ¡Las cartas están marcadas!", "Me distraje con un pterodáctilo."],
		"win_match": ["¡ROOOAAAR! ¡Soy el depredador del truco!", "¡Al asado con vos!"],
		"lose_match": ["¡Exijo revancha! ¡Y una mesa más alta!", "¡Esto no termina acá, mamífero!"],
		"taunt": ["¿Ese es tu mejor juego? Hasta un huevo juega mejor.", "Tenés menos cartas que un velociraptor vegano."],
		"envido_win": ["¡Son mejores las mías!", "¡Tantos de tiranosaurio!"],
		"envido_lose": ["Son buenas... grrr.", "¡Me robaron los tantos!"],
	},
	"cirilo": {
		"truco": ["Truco, compadre.", "Le canto truco, si me permite.", "Truco, y que lo escuche la Pachamama."],
		"retruco": ["Quiero retruco, mi amigo.", "Retruco. Este viejo no es zonzo."],
		"vale_cuatro": ["¡Quiero vale cuatro, y que me lleve el viento zonda!", "Vale cuatro. A lo gaucho."],
		"envido": ["Envido.", "Envido, pa' calentar el mate."],
		"real_envido": ["Real envido, cumpa.", "Real envido. Tengo los tantos curados."],
		"falta_envido": ["Falta envido. Despacito, como el algarrobo.", "Falta envido, y que Dios reparta suerte."],
		"flor": ["Flor, como en los cerros en primavera."],
		"contraflor": ["Contraflor. No me apure."],
		"quiero": ["Quiero.", "Quiero, nomás.", "Bueno, quiero."],
		"no_quiero": ["No quiero. El que se apura se cae del caballo.", "No quiero, guárdese la lengua.", "Paso, compadre."],
		"achico": ["Con flor me achico, pero no me arrugo."],
		"mazo": ["Me voy al mazo. Mañana será otro día."],
		"falta_received": ["¡Ah, mire usté! Falta envido le canta al viejo..."],
		"win_baza": ["Bien.", "Esa la gané yo.", "Despacito..."],
		"win_hand": ["Paciencia y truco, mi amigo.", "Así se juega en Amaicha.", "¡Aijuna! Para el viejo."],
		"lose_hand": ["Mala suerte, nomás.", "Uh... me tocaron cartas de quincho.", "Esta se la regalo."],
		"win_match": ["¡Aijuna! Se terminó el baile. Sírvase un vino.", "Le gané con el poncho puesto."],
		"lose_match": ["Bien jugado, compadre. Pero el mate lo paga usté.", "Me ganó... será la edad."],
		"taunt": ["Juega como turista en Tafí.", "¿Usté aprendió a jugar ayer?"],
		"envido_win": ["Son buenas las mías.", "Tengo más tantos que años."],
		"envido_lose": ["Son buenas.", "Buenas son, nomás."],
		"vs_rex_win_hand": ["¡Ja! ¡Dinosaurio mal perdedor, mírelo cómo patalea!", "Vaya a llorarle a un volcán, lagartija."],
		"vs_rex_win_match": ["¡Le gané al T-Rex! ¡Mañana le cobro entrada a los turistas!"],
		"vs_yanina_lose_hand": ["Señorita, usted me distrae con ese sombrero..."],
	},
	"yanina": {
		"truco": ["Truco, bombón. ¿Te animás?", "Truco... y mirame a los ojos.", "¡Truco! Ay, se te puso colorada la cara."],
		"retruco": ["Quiero retruco, papito.", "Retruco, y guiño de ojo incluido."],
		"vale_cuatro": ["¡Quiero VALE CUATRO! Agarrate el sombrero.", "Vale cuatro, corazón. Esto se pone picante."],
		"envido": ["Envido, ¿o te da miedito?", "Envido... adiviná qué tengo."],
		"real_envido": ["Real envido, mi rey.", "Real envido. Yo no miento... casi nunca."],
		"falta_envido": ["¡Falta envido! A todo o nada, como en la peña.", "Falta envido, y que se termine la noche."],
		"flor": ["¡FLOR! Y no es la del sombrero."],
		"contraflor": ["¡Contraflor! Mi jardín es más lindo."],
		"quiero": ["Quiero, obvio.", "¡Quiero! Te lo voy a hacer doler.", "Mmm... quiero."],
		"no_quiero": ["No quiero. Por esta vez te perdono.", "Nah, guardalo para otra.", "No quiero, pero no te agrandes."],
		"achico": ["Con flor me achico... por ahora."],
		"mazo": ["Me voy al mazo, pero vuelvo más linda."],
		"falta_received": ["¿Falta envido a mí? Qué atrevido... me encanta."],
		"win_baza": ["Mía, bebé.", "¡Uy, qué pena para vos!", "Jijiji."],
		"win_hand": ["¡Llorá tranquilo, nadie te mira!", "¡Ay, perdiste otra vez, pobrecito!", "¿Necesitás un pañuelito?"],
		"lose_hand": ["Te la dejé ganar, no te creas.", "Uff, suerte de principiante.", "Bueno, disfrutala que dura poco."],
		"win_match": ["¡Ganó la reina de la peña! Besito y chau.", "¡Te dejé seco como el valle en agosto!"],
		"lose_match": ["Ganaste... pero yo salgo mejor en la foto.", "Bien jugado. Me debés una zamba."],
		"taunt": ["¿Pensando? Qué tierno.", "Dale que se me enfría el vino."],
		"envido_win": ["Son mejores las mías, amor.", "Tengo más tantos que pretendientes."],
		"envido_lose": ["Son buenas... qué bronca.", "Buenas. No me mires así."],
		"vs_rex_win_hand": ["¿Qué pasa, Rex? ¿Se te achicaron los bracitos?"],
		"vs_cirilo_win_hand": ["Ay, Cirilo, andá a tomar la sopa."],
	},
}


static func get_data(id: String) -> Dictionary:
	return DATA.get(id, DATA["rex"])


static func line(id: String, key: String, other_id: String = "", rng: RandomNumberGenerator = null) -> String:
	var lines: Dictionary = LINES.get(id, {})
	var options: Array = []
	var special := "vs_%s_%s" % [other_id, key]
	if lines.has(special):
		options = lines[special]
		# A veces usa la frase general igual, para variar.
		if lines.has(key) and randf() < 0.35:
			options = lines[key]
	elif lines.has(key):
		options = lines[key]
	if options.is_empty():
		return ""
	if rng:
		return options[rng.randi_range(0, options.size() - 1)]
	return options[randi() % options.size()]
