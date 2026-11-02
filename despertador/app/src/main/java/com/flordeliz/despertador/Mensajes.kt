package com.flordeliz.despertador

/** Actividades que se pueden asignar a cada día de la semana. */
enum class Actividad(val etiqueta: String) {
    GYM("Gym"),
    KARATE("Karate"),
    ABOGACIA("Abogacía"),
    PERFUMERIA("Perfumería"),
    NEGOCIO("Flor de Liz"),
    DESCANSO("Descanso"),
}

/**
 * Categoría de un mensaje. FILOSOFIA sirve para cualquier día;
 * DURO es el que suena si no apagás la alarma en 5 minutos.
 */
enum class Cat { FILOSOFIA, GYM, KARATE, ABOGACIA, PERFUMERIA, NEGOCIO, DESCANSO, DURO }

data class Mensaje(val id: String, val cat: Cat, val texto: String, val fuente: String = "")

object Mensajes {

    val todos: List<Mensaje> = listOf(
        // ------------------------------------------------------------ FILOSOFÍA
        Mensaje("f01", Cat.FILOSOFIA,
            "Marco Aurelio era emperador de Roma y aun así tenía que escribirse a sí mismo, al amanecer, que se levantaba para hacer el trabajo de un hombre. Nadie tiene ganas a esta hora. Se levanta igual.",
            "Marco Aurelio · Meditaciones, libro V"),
        Mensaje("f02", Cat.FILOSOFIA,
            "No recibimos una vida corta: la hacemos corta malgastándola. Hoy no tenés que hacer nada épico. Tenés que no regalar las horas.",
            "Séneca · Sobre la brevedad de la vida"),
        Mensaje("f03", Cat.FILOSOFIA,
            "Imaginá que este día exacto se va a repetir infinitas veces, igual, para siempre. ¿Lo vivirías así como lo tenés planeado? Si la respuesta es no, cambiá una sola cosa antes del mediodía.",
            "Nietzsche · el eterno retorno"),
        Mensaje("f04", Cat.FILOSOFIA,
            "Camus imaginó a Sísifo feliz empujando la misma piedra. No porque la piedra cambiara, sino porque la piedra era suya. Tu expediente, tu kata, tu serie: son tu piedra. Empujala con orgullo.",
            "Albert Camus · El mito de Sísifo"),
        Mensaje("f05", Cat.FILOSOFIA,
            "Hoy es la victoria sobre el que fuiste ayer. No compitas con nadie más hasta haberle ganado a ese.",
            "Miyamoto Musashi · El libro de los cinco anillos"),
        Mensaje("f06", Cat.FILOSOFIA,
            "Nadie se baña dos veces en el mismo río. Hoy no sos el que se acostó anoche: dormiste, reparaste músculo, consolidaste lo que estudiaste. Usá a esta versión nueva.",
            "Heráclito"),
        Mensaje("f07", Cat.FILOSOFIA,
            "Las mañanas que te quedan son un número finito. No es una frase motivadora: es aritmética. Esta ya la estás gastando. Decidí en qué.",
            "Memento mori"),
        Mensaje("f08", Cat.FILOSOFIA,
            "Epicteto, que nació esclavo, separaba lo que depende de vos de lo que no. El juez, el cliente, el tránsito: no dependen de vos. La preparación, la puntualidad y el esfuerzo: completamente tuyos. Hoy jugá sólo esa cancha.",
            "Epicteto · Enquiridión"),
        Mensaje("f09", Cat.FILOSOFIA,
            "En la mente del principiante hay muchas posibilidades; en la del experto, pocas. Encará el día como si fuera tu primera clase: mirando todo.",
            "Shunryu Suzuki · Mente zen, mente de principiante"),
        Mensaje("f10", Cat.FILOSOFIA,
            "La vida se entiende hacia atrás, pero se vive hacia adelante. No vas a saber hoy para qué sirve el esfuerzo de hoy. Lo vas a saber dentro de años. Avanzá igual.",
            "Søren Kierkegaard · Diarios"),
        Mensaje("f11", Cat.FILOSOFIA,
            "Uno se vuelve valiente haciendo actos valientes, y justo haciendo actos justos. La disciplina no se siente primero y se practica después. Es al revés.",
            "Aristóteles · Ética a Nicómaco, libro II"),
        Mensaje("f12", Cat.FILOSOFIA,
            "Nadie se acuerda de las mañanas que durmió de más. Te vas a acordar de las que te levantaste a pelearla. Hacé que hoy sea de las que se recuerdan."),
        Mensaje("f13", Cat.FILOSOFIA,
            "Quien tiene un porqué puede soportar casi cualquier cómo. Antes de pisar el piso, decí en voz alta tu porqué de hoy. Si no lo tenés, ese es el primer trabajo del día.",
            "Nietzsche, citado por Viktor Frankl"),
        Mensaje("f14", Cat.FILOSOFIA,
            "Thoreau se fue al bosque para vivir a propósito, para no descubrir al morir que no había vivido. Vos no necesitás un bosque. Necesitás que cada bloque de hoy tenga dueño, y que ese dueño seas vos.",
            "Henry David Thoreau · Walden"),
        Mensaje("f15", Cat.FILOSOFIA,
            "Zanshin: la mente que sigue alerta después del golpe. El peligro de hoy no es arrancar mal, es aflojar después del primer logro. Mantené la guardia hasta la noche.",
            "Concepto de las artes marciales japonesas"),
        Mensaje("f16", Cat.FILOSOFIA,
            "Tenés tres vidas en una: el estrado, el dojo y el perfume. La mayoría no se anima a tener ni una sola con intensidad. Eso no es cansancio, es privilegio. Arriba."),
        Mensaje("f17", Cat.FILOSOFIA,
            "Todo lo que te parece urgente dentro de cien años no le va a importar a nadie. Justamente por eso, hacé hoy lo que vos querés que haya existido.",
            "Marco Aurelio, idea recurrente"),
        Mensaje("f18", Cat.FILOSOFIA,
            "El hombre está condenado a ser libre: no elegir también es elegir. Quedarte en la cama es una decisión. Tomá otra.",
            "Jean-Paul Sartre · El existencialismo es un humanismo"),
        Mensaje("f19", Cat.FILOSOFIA,
            "Ichigo ichie: un encuentro, una sola vez. Este día, con esta luz y este cuerpo, no se repite. Tratalo como a un invitado que no va a volver.",
            "Expresión de la ceremonia del té japonesa"),
        Mensaje("f20", Cat.FILOSOFIA,
            "El cansancio de la mañana es el cuerpo cobrando la deuda de ayer. Se paga moviéndose, no durmiendo cinco minutos más."),
        Mensaje("f21", Cat.FILOSOFIA,
            "Lo que me impide actuar se convierte en el camino. El obstáculo no está frente a tu día: es tu día. Empezá por ahí.",
            "Marco Aurelio · Meditaciones, libro V"),
        Mensaje("f22", Cat.FILOSOFIA,
            "Vivir es lo más raro del mundo; la mayoría de la gente simplemente existe. Hoy elegí la versión rara.",
            "Oscar Wilde · El alma del hombre bajo el socialismo"),

        // ------------------------------------------------------------ GYM
        Mensaje("g01", Cat.GYM,
            "Hoy hay hierro. El músculo no crece en el gimnasio: crece cuando el cuerpo entiende que vas a volver. Volvé."),
        Mensaje("g02", Cat.GYM,
            "La barra pesa lo mismo con ganas que sin ganas. La diferencia es que sin ganas la levantan pocos. Sé de los pocos."),
        Mensaje("g03", Cat.GYM,
            "Cada serie que terminás cuando ya querías dejar es un voto por la persona que querés ser. Hoy votá varias veces."),
        Mensaje("g04", Cat.GYM,
            "Tu cuerpo es la herramienta que usás en todas tus otras vidas: en el tribunal, en el dojo, en el showroom. Hoy le hacés el service."),
        Mensaje("g05", Cat.GYM,
            "Sobrecarga progresiva: un kilo más, una repetición más, un segundo más de control. No hace falta un día heroico. Hace falta un día un poco mejor que el anterior."),
        Mensaje("g06", Cat.GYM,
            "Nadie te aplaude en la última repetición. Por eso es la única que cuenta de verdad."),
        Mensaje("g07", Cat.GYM,
            "Entrá al gimnasio sabiendo qué vas a hacer. El plan se escribe en el desayuno, no frente al rack."),
        Mensaje("g08", Cat.GYM,
            "La fuerza que construís hoy es la que te sostiene la guardia el jueves en el dojo. Nada de lo que entrenás se pierde."),

        // ------------------------------------------------------------ KARATE
        Mensaje("k01", Cat.KARATE,
            "Hoy hay dojo. El karate empieza y termina con el saludo. Empezá el día igual: con respeto y en guardia.",
            "Gichin Funakoshi · Niju kun"),
        Mensaje("k02", Cat.KARATE,
            "El karate es como el agua caliente: si dejás de darle fuego, se enfría. Dos horas hoy mantienen el agua hirviendo.",
            "Gichin Funakoshi · Niju kun"),
        Mensaje("k03", Cat.KARATE,
            "Mil días de práctica para forjar, diez mil para pulir. Hoy es uno de esos días. No tiene que ser brillante; tiene que estar.",
            "Miyamoto Musashi"),
        Mensaje("k04", Cat.KARATE,
            "Kime: toda la energía en un punto y en un instante. Elegí el punto de hoy y poné ahí todo lo que tenés."),
        Mensaje("k05", Cat.KARATE,
            "El cinturón no se gana el día del examen. Se gana en días como este, a la hora en que nadie mira."),
        Mensaje("k06", Cat.KARATE,
            "En el kumite no hay tiempo de preguntarte si tenés ganas. Se entrena para que el cuerpo responda antes que las excusas. Empezá ahora."),
        Mensaje("k07", Cat.KARATE,
            "Mushin: mente sin mente. Dejá de negociar con vos mismo y simplemente movete. La técnica piensa por vos."),
        Mensaje("k08", Cat.KARATE,
            "El objetivo final del karate no está en la victoria ni en la derrota, sino en perfeccionar el carácter de quien lo practica. Hoy entrenás eso también.",
            "Gichin Funakoshi"),

        // ------------------------------------------------------------ ABOGACÍA
        Mensaje("a01", Cat.ABOGACIA,
            "Un plazo no tiene estado de ánimo: vence o no vence. Revisá el PJN antes de que el día te revise a vos."),
        Mensaje("a02", Cat.ABOGACIA,
            "Detrás de cada causa hay alguien que puso su problema en tu criterio. Esa confianza se honra temprano, no a las once de la noche."),
        Mensaje("a03", Cat.ABOGACIA,
            "El buen escrito se gana leyendo el expediente, no redactando. Hoy leé como si el juez fuera a buscar justo el error que vos no viste."),
        Mensaje("a04", Cat.ABOGACIA,
            "En aduana el detalle es todo: una posición arancelaria, una fecha de oficialización, una firma. La precisión es tu ventaja. Afilala hoy."),
        Mensaje("a05", Cat.ABOGACIA,
            "Estudiá. El derecho se transforma constantemente. Si no seguís sus pasos, vas a ser cada día un poco menos abogado.",
            "Eduardo J. Couture · Los mandamientos del abogado"),
        Mensaje("a06", Cat.ABOGACIA,
            "Tu deber es luchar por el derecho; pero el día que encuentres en conflicto el derecho con la justicia, luchá por la justicia.",
            "Eduardo J. Couture · Los mandamientos del abogado"),
        Mensaje("a07", Cat.ABOGACIA,
            "Lo urgente de hoy es lo importante que ayer no se hizo. Hacé hoy lo importante y mañana va a haber menos incendios."),
        Mensaje("a08", Cat.ABOGACIA,
            "El cliente no recuerda cuántas horas trabajaste. Recuerda si llegaste antes que el problema. Llegá antes."),

        // ------------------------------------------------------------ PERFUMERÍA (estudio)
        Mensaje("p01", Cat.PERFUMERIA,
            "Hoy estudiás perfumería. La nariz se entrena como un músculo: oler, nombrar, recordar. Diez minutos con materias primas valen más que una hora de teoría."),
        Mensaje("p02", Cat.PERFUMERIA,
            "Un perfume tiene salida, corazón y fondo. Tu día también. La salida es esta primera hora: que deje buena impresión."),
        Mensaje("p03", Cat.PERFUMERIA,
            "Roudnitska sostenía que el perfume es un arte y no un producto de laboratorio. Estudiá la química hoy para poder hacer arte mañana.",
            "Edmond Roudnitska"),
        Mensaje("p04", Cat.PERFUMERIA,
            "El oud nace en el árbol de agar como respuesta a una herida, y tarda años. Lo más valioso suele formarse en lo que costó."),
        Mensaje("p05", Cat.PERFUMERIA,
            "Cada acorde que memorizás es una palabra más en un idioma que muy pocos hablan. Hoy sumá vocabulario."),
        Mensaje("p06", Cat.PERFUMERIA,
            "La nariz se satura rápido; por eso los perfumistas huelen poco y con atención. Aplicalo al día: menos cosas, más presencia."),
        Mensaje("p07", Cat.PERFUMERIA,
            "Un perfumista puede pasar cientos de pruebas hasta dar con una fórmula. La versión cien no existe sin las noventa y nueve anteriores. Hoy hacé la tuya."),

        // ------------------------------------------------------------ FLOR DE LIZ
        Mensaje("n01", Cat.NEGOCIO,
            "Flor de Liz no se vende sola. Hoy hay alguien que todavía no sabe que su perfume favorito lo vendés vos. Salí a encontrarlo."),
        Mensaje("n02", Cat.NEGOCIO,
            "Un video publicado imperfecto le gana siempre al video perfecto que sigue en borradores. Hoy publicá."),
        Mensaje("n03", Cat.NEGOCIO,
            "Vender un perfume es vender un recuerdo que todavía no pasó. Hoy contá una historia, no una ficha técnica."),
        Mensaje("n04", Cat.NEGOCIO,
            "Un cliente que vuelve vale más que tres nuevos. Hoy respondé ese mensaje que dejaste para después."),
        Mensaje("n05", Cat.NEGOCIO,
            "El algoritmo premia la constancia antes que el talento. La cuenta que publica todos los días le termina ganando a la que publica genial una vez por mes."),
        Mensaje("n06", Cat.NEGOCIO,
            "Tu showroom es un escenario. Que el que entre se lleve una experiencia, aunque hoy no compre. Mañana vuelve."),
        Mensaje("n07", Cat.NEGOCIO,
            "No vendés frascos: vendés cómo se siente alguien cuando entra a un lugar oliendo así. Hoy vendé eso."),

        // ------------------------------------------------------------ DESCANSO
        Mensaje("d01", Cat.DESCANSO,
            "Hoy no hay agenda pesada. Descansar también es entrenar: el músculo y la cabeza se arman en la pausa. Pero descanso no es desperdicio: elegí a propósito qué vas a disfrutar."),
        Mensaje("d02", Cat.DESCANSO,
            "Al espíritu hay que darle descanso, como al campo fértil que no se fuerza a producir sin pausa. Hoy dejá reposar la tierra.",
            "Séneca · Sobre la tranquilidad del alma"),
        Mensaje("d03", Cat.DESCANSO,
            "Un día liviano es para lo que la semana no deja: llamar a alguien que querés, leer algo largo, caminar sin auriculares."),
        Mensaje("d04", Cat.DESCANSO,
            "El arco que nunca se afloja termina rompiéndose. Hoy aflojá la cuerda, pero con intención."),

        // ------------------------------------------------------------ DURO (5 minutos sin apagar)
        Mensaje("x01", Cat.DURO,
            "Pasaron cinco minutos. Esto ya no es cansancio, es negociación. Y la estás perdiendo. Arriba. Ahora."),
        Mensaje("x02", Cat.DURO,
            "El que se queda en la cama no tiene causas que ganar, ni cinturón que defender, ni una marca que crecer. Ese no sos vos. Levantate."),
        Mensaje("x03", Cat.DURO,
            "Cinco minutos regalados. ¿A quién? A nadie. Ni siquiera descansaste. Pies al piso."),
        Mensaje("x04", Cat.DURO,
            "Si tu sensei te viera así, ya estarías haciendo flexiones. Resolvé el juego y salí de la cama."),
        Mensaje("x05", Cat.DURO,
            "Los plazos no esperan. Los clientes no esperan. El día ya arrancó sin vos. Alcanzalo."),
        Mensaje("x06", Cat.DURO,
            "Anoche te prometiste levantarte a esta hora. Cumplile a quien eras anoche. Arriba."),
        Mensaje("x07", Cat.DURO,
            "Nada de lo que querés está en esa cama. Nada. Movete."),
        Mensaje("x08", Cat.DURO,
            "Ya sabés cómo termina esto: te levantás igual, pero tarde y con culpa. Elegí la otra versión. Ahora."),
        Mensaje("x09", Cat.DURO,
            "Kiai. Un grito, un movimiento, y estás de pie. No lo pienses más."),
    )

    private val porId = todos.associateBy { it.id }

    fun porId(id: String): Mensaje? = porId[id]

    fun categoriaDe(a: Actividad): Cat = when (a) {
        Actividad.GYM -> Cat.GYM
        Actividad.KARATE -> Cat.KARATE
        Actividad.ABOGACIA -> Cat.ABOGACIA
        Actividad.PERFUMERIA -> Cat.PERFUMERIA
        Actividad.NEGOCIO -> Cat.NEGOCIO
        Actividad.DESCANSO -> Cat.DESCANSO
    }

    /**
     * Elige el mensaje del día: mitad de las veces sobre lo que te toca hoy,
     * mitad filosofía. Evita repetir los últimos mensajes mostrados.
     */
    fun delDia(actividades: Set<Actividad>, recientes: List<String>): Mensaje {
        val cats = actividades.map { categoriaDe(it) }.toSet()
        val usarDia = cats.isNotEmpty() && Math.random() < 0.55
        val base = if (usarDia) todos.filter { it.cat in cats } else todos.filter { it.cat == Cat.FILOSOFIA }
        val frescos = base.filter { it.id !in recientes }
        return (frescos.ifEmpty { base }).random()
    }

    fun duro(yaUsados: Set<String>): Mensaje {
        val duros = todos.filter { it.cat == Cat.DURO }
        return duros.filter { it.id !in yaUsados }.ifEmpty { duros }.random()
    }
}
