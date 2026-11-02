package com.flordeliz.despertador

import android.app.Activity
import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Pantalla que aparece cuando suena la alarma.
 * Mensaje del día → (pausa para leerlo) → minijuego → intención del día.
 */
class AlarmActivity : Activity() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var store: Store
    private lateinit var mensaje: Mensaje
    private lateinit var hora: TextView
    private lateinit var zonaJuego: LinearLayout
    private lateinit var bannerDuro: TextView
    private var resuelto = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setShowWhenLocked(true)
        setTurnScreenOn(true)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        if (!AlarmService.Estado.sonando) { finish(); return }

        store = Store(this)
        mensaje = Mensajes.porId(AlarmService.Estado.mensajeId)
            ?: Mensajes.delDia(actividadesDeHoy(), store.recientes())

        setContentView(construir())
        actualizarHora()
        AlarmService.Estado.duroId?.let { mostrarDuro(it) }
        AlarmService.Estado.oyente = {
            runOnUiThread { AlarmService.Estado.duroId?.let { mostrarDuro(it) } }
        }
        cuentaRegresiva(7)
    }

    private fun actividadesDeHoy() =
        store.actividades(Calendar.getInstance().get(Calendar.DAY_OF_WEEK))

    // ------------------------------------------------------------------ vista
    private fun construir(): View {
        val col = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(36), dp(24), dp(32))
        }

        val cabecera = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        cabecera.addView(sello("起", 48))
        val fechaCol = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(14), 0, 0, 0)
        }
        val fecha = SimpleDateFormat("EEEE d 'de' MMMM", Locale("es", "AR")).format(Date())
        fechaCol.addView(rotulo(fecha, Ui.PAPEL))
        val acts = actividadesDeHoy().joinToString("  ·  ") { it.etiqueta }
        fechaCol.addView(rotulo(acts.ifEmpty { "Día libre" }).apply { setPadding(0, dp(4), 0, 0) })
        cabecera.addView(fechaCol)
        col.addView(cabecera)

        hora = texto("", 84f, Ui.PAPEL, Ui.LIVIANA, -0.02f).apply { setPadding(0, dp(18), 0, dp(6)) }
        col.addView(hora)

        bannerDuro = texto("", 19f, Ui.PAPEL, Ui.MEDIA).apply {
            background = fondoRedondeado(Ui.HANKO, dp(12).toFloat())
            setPadding(dp(18), dp(16), dp(18), dp(16))
            visibility = View.GONE
            setLineSpacing(0f, 1.25f)
        }
        col.addView(bannerDuro, lp().margen(abajo = dp(16)))

        val card = tarjeta()
        card.addView(rotulo("Para hoy", Ui.HANKO))
        card.addView(texto(mensaje.texto, 22f, Ui.PAPEL, Ui.SERIF).apply {
            setLineSpacing(0f, 1.32f)
            setPadding(0, dp(12), 0, dp(12))
        })
        if (mensaje.fuente.isNotBlank()) {
            card.addView(texto("— " + mensaje.fuente, 14f, Ui.TENUE, Ui.SERIF_ITALICA))
        }
        val fav = texto("", 14f, Ui.TENUE, Ui.MEDIA).apply { setPadding(0, dp(14), 0, 0) }
        fun pintarFav() {
            val es = store.esFavorito(mensaje.id)
            fav.text = if (es) "♥  Guardado en favoritos" else "♡  Guardar en favoritos"
            fav.setTextColor(if (es) Ui.HANKO else Ui.TENUE)
        }
        pintarFav()
        fav.setOnClickListener { store.alternarFavorito(mensaje.id); pintarFav() }
        card.addView(fav)
        col.addView(card)

        zonaJuego = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(22), 0, 0)
        }
        col.addView(zonaJuego)

        return ScrollView(this).apply {
            setBackgroundColor(Ui.FONDO)
            isFillViewport = true
            addView(col)
        }
    }

    private fun actualizarHora() {
        val c = Calendar.getInstance()
        hora.text = "%02d:%02d".format(c.get(Calendar.HOUR_OF_DAY), c.get(Calendar.MINUTE))
        handler.postDelayed(::actualizarHora, 15_000)
    }

    private fun mostrarDuro(id: String) {
        val m = Mensajes.porId(id) ?: return
        bannerDuro.text = m.texto
        bannerDuro.visibility = View.VISIBLE
    }

    // ------------------------------------------------------------------ juego
    /** Unos segundos para leer el mensaje antes de poder apagar. */
    private fun cuentaRegresiva(seg: Int) {
        zonaJuego.removeAllViews()
        if (seg <= 0) { iniciarJuego(); return }
        zonaJuego.addView(rotulo("Leé el mensaje · el juego aparece en $seg").apply {
            gravity = Gravity.CENTER
        }, lp())
        handler.postDelayed({ cuentaRegresiva(seg - 1) }, 1000)
    }

    private fun iniciarJuego() {
        zonaJuego.removeAllViews()
        when ((0..2).random()) {
            0 -> juegoOrden()
            1 -> juegoSuma()
            else -> juegoPalabra()
        }
    }

    private fun titulo(t: String) {
        zonaJuego.addView(rotulo("Para apagar", Ui.HANKO))
        zonaJuego.addView(texto(t, 18f, Ui.PAPEL, Ui.MEDIA).apply { setPadding(0, dp(6), 0, dp(14)) })
    }

    private fun grilla(columnas: Int): GridLayout = GridLayout(this).apply {
        columnCount = columnas
        zonaJuego.addView(this, lp())
    }

    private fun celda(g: GridLayout, t: String, alTocar: (TextView) -> Unit): TextView {
        val v = texto(t, 24f, Ui.PAPEL, Ui.MEDIA).apply {
            gravity = Gravity.CENTER
            background = fondoRedondeado(Ui.SUPERFICIE, dp(12).toFloat(), Ui.LINEA, dp(1))
            conToque()
            minHeight = dp(64)
        }
        v.setOnClickListener { alTocar(v) }
        g.addView(v, GridLayout.LayoutParams(
            GridLayout.spec(GridLayout.UNDEFINED), GridLayout.spec(GridLayout.UNDEFINED, 1f)
        ).apply { width = 0; setMargins(dp(5), dp(5), dp(5), dp(5)) })
        return v
    }

    private fun error(msg: String, reintentar: () -> Unit) {
        zonaJuego.removeAllViews()
        zonaJuego.addView(rotulo(msg, Ui.HANKO).apply { gravity = Gravity.CENTER }, lp())
        handler.postDelayed({ reintentar() }, 900)
    }

    /** Tocar los números del 1 al 6 en orden. */
    private fun juegoOrden() {
        titulo("Tocá los números del 1 al 6, en orden")
        val g = grilla(3)
        var siguiente = 1
        (1..6).shuffled().forEach { n ->
            celda(g, n.toString()) { v ->
                if (n == siguiente) {
                    v.alpha = 0.2f; v.isEnabled = false
                    siguiente++
                    if (siguiente > 6) exito()
                } else error("Ese no. De nuevo.") { zonaJuego.removeAllViews(); juegoOrden() }
            }
        }
    }

    /** Una cuenta simple. */
    private fun juegoSuma() {
        val a = (12..48).random(); val b = (3..9).random()
        val r = a + b
        titulo("¿Cuánto es $a + $b?")
        val g = grilla(2)
        (setOf(r, r + 1, r - 1, r + 10).shuffled()).forEach { op ->
            celda(g, op.toString()) {
                if (op == r) exito() else error("No. Despertá la cabeza.") { zonaJuego.removeAllViews(); juegoSuma() }
            }
        }
    }

    /** Elegir qué palabra aparece en el mensaje: obliga a leerlo. */
    private fun juegoPalabra() {
        val limpio = mensaje.texto.lowercase(Locale("es")).replace(Regex("[^\\p{L} ]"), " ")
        val palabras = limpio.split(" ").filter { it.length >= 6 }.distinct()
        if (palabras.isEmpty()) { juegoSuma(); return }
        val correcta = palabras.random()
        val distractores = listOf(
            "montaña", "ventana", "silencio", "bandera", "espejo", "tormenta", "jardín", "océano",
            "martillo", "guitarra", "desierto", "relámpago", "linterna", "volcán", "bosque", "estrella",
        ).filter { it !in limpio }.shuffled().take(3)
        titulo("¿Cuál de estas palabras está en tu mensaje?")
        val g = grilla(2)
        (distractores + correcta).shuffled().forEach { w ->
            celda(g, w) {
                if (w == correcta) exito()
                else error("No estaba. Leelo otra vez.") { zonaJuego.removeAllViews(); juegoPalabra() }
            }.apply { textSize = 18f }
        }
    }

    // ------------------------------------------------------------------ después
    private fun exito() {
        if (resuelto) return
        resuelto = true
        if (!AlarmService.Estado.prueba) store.registrarDespertar(AlarmService.Estado.aTiempo)
        val leer = if (mensaje.fuente.isNotBlank()) mensaje.texto + ". " + mensaje.fuente else mensaje.texto
        AlarmService.apagar(this, leer)
        bannerDuro.visibility = View.GONE
        mostrarIntencion()
    }

    private fun mostrarIntencion() {
        zonaJuego.removeAllViews()
        val racha = store.racha
        zonaJuego.addView(rotulo(
            if (racha > 0) "Racha · $racha ${if (racha == 1) "día" else "días"} seguidos" else "Racha reiniciada · hoy empieza otra",
            Ui.HANKO,
        ))
        zonaJuego.addView(texto("¿Qué vas a conquistar hoy?", 22f, Ui.PAPEL, Ui.SERIF).apply {
            setPadding(0, dp(8), 0, dp(12))
        })
        val campo = EditText(this).apply {
            hint = "Una sola cosa. Concreta."
            setHintTextColor(Ui.TENUE)
            setTextColor(Ui.PAPEL)
            textSize = 17f
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
            background = fondoRedondeado(Ui.SUPERFICIE, dp(12).toFloat(), Ui.LINEA, dp(1))
            setPadding(dp(16), dp(14), dp(16), dp(14))
        }
        zonaJuego.addView(campo, lp())
        val botones = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, dp(14), 0, 0)
        }
        botones.addView(boton("Ahora no", principal = false) { cerrar() }, lp(0, peso = 1f).margen(der = dp(6)))
        botones.addView(boton("A darle") {
            val t = campo.text.toString().trim()
            if (t.isNotEmpty()) store.agregarIntencion(t)
            cerrar()
        }, lp(0, peso = 1.4f).margen(izq = dp(6)))
        zonaJuego.addView(botones, lp())
    }

    private fun cerrar() {
        currentFocus?.let {
            getSystemService(InputMethodManager::class.java).hideSoftInputFromWindow(it.windowToken, 0)
        }
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Mientras suena no se puede salir con "atrás": hay que resolver el juego.
        if (resuelto) super.onBackPressed()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        if (AlarmService.Estado.oyente != null && !resuelto) AlarmService.Estado.oyente = null
        super.onDestroy()
    }

    companion object {
        fun abrir(ctx: Context) {
            ctx.startActivity(
                android.content.Intent(ctx, AlarmActivity::class.java)
                    .addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        }
    }
}
