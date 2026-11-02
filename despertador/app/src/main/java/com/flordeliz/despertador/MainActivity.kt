package com.flordeliz.despertador

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.app.TimePickerDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.ColorStateList
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.OpenableColumns
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Switch
import android.widget.TextView
import android.widget.Toast
import java.util.Calendar

class MainActivity : Activity() {

    private enum class Pestania(val etiqueta: String) { ALARMAS("Alarmas"), SEMANA("Semana"), DIARIO("Diario"), AJUSTES("Ajustes") }

    private lateinit var store: Store
    private lateinit var contenido: LinearLayout
    private lateinit var scroll: ScrollView
    private lateinit var barra: LinearLayout
    private var actual = Pestania.ALARMAS

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        store = Store(this)

        val raiz = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Ui.FONDO)
        }
        contenido = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(22), dp(28), dp(22), dp(28))
        }
        scroll = ScrollView(this).apply { addView(contenido) }
        raiz.addView(scroll, lp(alto = 0, peso = 1f))
        barra = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setBackgroundColor(Ui.SUPERFICIE)
            setPadding(dp(8), dp(4), dp(8), dp(4))
        }
        raiz.addView(View(this).apply { setBackgroundColor(Ui.LINEA) }, lp(alto = dp(1)))
        raiz.addView(barra, lp())
        setContentView(raiz)

        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
        }
        Programador.reprogramarTodas(this)
    }

    override fun onResume() {
        super.onResume()
        mostrar(actual)
    }

    private fun mostrar(p: Pestania) {
        actual = p
        barra.removeAllViews()
        Pestania.values().forEach { t ->
            val sel = t == p
            val v = texto(t.etiqueta.uppercase(), 11f, if (sel) Ui.PAPEL else Ui.TENUE, Ui.MEDIA, 0.18f).apply {
                gravity = Gravity.CENTER
                setPadding(0, dp(16), 0, dp(16))
                setOnClickListener { mostrar(t) }
            }
            val celda = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER_HORIZONTAL
                addView(v, lp())
                addView(View(this@MainActivity).apply {
                    setBackgroundColor(if (sel) Ui.HANKO else 0)
                }, lp(dp(22), dp(2)).margen(abajo = dp(6)))
            }
            barra.addView(celda, lp(0, peso = 1f))
        }
        contenido.removeAllViews()
        when (p) {
            Pestania.ALARMAS -> pantallaAlarmas()
            Pestania.SEMANA -> pantallaSemana()
            Pestania.DIARIO -> pantallaDiario()
            Pestania.AJUSTES -> pantallaAjustes()
        }
        scroll.scrollTo(0, 0)
    }

    private fun encabezado(titulo: String, sub: String) {
        val fila = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        fila.addView(sello("気", 40))
        val col = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(14), 0, 0, 0)
        }
        col.addView(texto(titulo, 28f, Ui.PAPEL, Ui.SERIF))
        col.addView(rotulo(sub))
        fila.addView(col)
        contenido.addView(fila, lp().margen(abajo = dp(24)))
    }

    private fun seccion(t: String) =
        contenido.addView(rotulo(t), lp().margen(arriba = dp(26), abajo = dp(10)))

    // ================================================================== ALARMAS
    private fun pantallaAlarmas() {
        encabezado("Kiai", textoSiguiente())

        // Racha
        val r = tarjeta().apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        r.addView(texto(store.racha.toString(), 46f, Ui.HANKO, Ui.LIVIANA), lp(LinearLayout.LayoutParams.WRAP_CONTENT))
        val rc = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(16), 0, 0, 0) }
        rc.addView(texto(if (store.racha == 1) "día seguido de pie a tiempo" else "días seguidos de pie a tiempo", 15f, Ui.PAPEL, Ui.SERIF))
        rc.addView(rotulo("Mejor racha · ${store.mejorRacha}").apply { setPadding(0, dp(4), 0, 0) })
        r.addView(rc)
        contenido.addView(r, lp())

        seccion("Tus alarmas")
        val alarmas = store.alarmas()
        if (alarmas.isEmpty()) {
            contenido.addView(texto("Todavía no hay alarmas. Creá la primera: el día se gana desde la noche anterior.", 16f, Ui.TENUE, Ui.SERIF_ITALICA).apply {
                setLineSpacing(0f, 1.3f)
            }, lp().margen(abajo = dp(14)))
        }
        alarmas.forEach { contenido.addView(tarjetaAlarma(it), lp().margen(abajo = dp(12))) }

        contenido.addView(boton("+  Nueva alarma") {
            elegirHora(6, 30) { h, m ->
                val a = Alarma(store.nuevoId(), h, m,
                    setOf(Calendar.MONDAY, Calendar.TUESDAY, Calendar.WEDNESDAY, Calendar.THURSDAY, Calendar.FRIDAY),
                    true, Sonido.TAIKO)
                guardar(a)
            }
        }, lp().margen(arriba = dp(6)))
    }

    private fun textoSiguiente(): String {
        val s = Programador.siguiente(this) ?: return "Sin alarmas activas"
        val min = ((s - System.currentTimeMillis()) / 60_000).coerceAtLeast(0)
        val h = min / 60; val m = min % 60
        return if (h > 0) "Suena en $h h $m min" else "Suena en $m min"
    }

    private fun guardar(a: Alarma) {
        store.upsert(a)
        Programador.programar(this, a)
        if (a.activa) Toast.makeText(this, textoSiguiente(), Toast.LENGTH_SHORT).show()
        mostrar(Pestania.ALARMAS)
    }

    private fun elegirHora(h: Int, m: Int, listo: (Int, Int) -> Unit) {
        TimePickerDialog(this, android.R.style.Theme_Material_Dialog_Alert,
            { _, hh, mm -> listo(hh, mm) }, h, m, true).show()
    }

    private fun tarjetaAlarma(a: Alarma): View {
        val t = tarjeta()
        val fila = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        val hora = texto("%02d:%02d".format(a.hora, a.minuto), 46f, if (a.activa) Ui.PAPEL else Ui.TENUE, Ui.LIVIANA).apply {
            setOnClickListener { elegirHora(a.hora, a.minuto) { h, m -> guardar(a.copy(hora = h, minuto = m, activa = true)) } }
        }
        fila.addView(hora, lp(0, peso = 1f))
        fila.addView(interruptor(a.activa) { guardar(a.copy(activa = it)) })
        t.addView(fila)

        val dias = listOf(
            Calendar.MONDAY to "L", Calendar.TUESDAY to "M", Calendar.WEDNESDAY to "X", Calendar.THURSDAY to "J",
            Calendar.FRIDAY to "V", Calendar.SATURDAY to "S", Calendar.SUNDAY to "D",
        )
        val filaDias = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(0, dp(8), 0, 0) }
        dias.forEach { (d, letra) ->
            val on = d in a.dias
            filaDias.addView(chip(letra, on) {
                guardar(a.copy(dias = if (on) a.dias - d else a.dias + d))
            }.apply { setPadding(0, dp(8), 0, dp(8)) }, lp(0, peso = 1f).margen(der = dp(4)))
        }
        t.addView(filaDias)
        t.addView(rotulo(if (a.dias.isEmpty()) "Una sola vez" else "Repite").apply { setPadding(0, dp(8), 0, 0) })

        t.addView(rotulo("Sonido").apply { setPadding(0, dp(16), 0, dp(8)) })
        val sonidos = FilaFluida(this)
        Sonido.values().forEach { s ->
            sonidos.addView(chip(s.etiqueta, s == a.sonido) {
                if (s == Sonido.PROPIA && store.musicaPropia == null) {
                    Toast.makeText(this, "Primero elegí tu canción en Ajustes", Toast.LENGTH_LONG).show()
                } else guardar(a.copy(sonido = s))
            })
        }
        t.addView(sonidos)

        t.addView(texto("Eliminar", 13f, Ui.TENUE, Ui.MEDIA).apply {
            setPadding(0, dp(16), 0, 0)
            setOnClickListener {
                Programador.cancelar(this@MainActivity, a.id)
                store.borrar(a.id)
                mostrar(Pestania.ALARMAS)
            }
        })
        return t
    }

    private fun interruptor(on: Boolean, cambio: (Boolean) -> Unit) = Switch(this).apply {
        isChecked = on
        thumbTintList = ColorStateList(
            arrayOf(intArrayOf(android.R.attr.state_checked), intArrayOf()),
            intArrayOf(Ui.HANKO, Ui.TENUE),
        )
        trackTintList = ColorStateList(
            arrayOf(intArrayOf(android.R.attr.state_checked), intArrayOf()),
            intArrayOf(Ui.HANKO_OSCURO, Ui.LINEA),
        )
        setOnCheckedChangeListener { _, c -> cambio(c) }
    }

    // ================================================================== SEMANA
    private fun pantallaSemana() {
        encabezado("Tu semana", "El mensaje de cada mañana habla de lo que te toca")
        val dias = listOf(
            Calendar.MONDAY to "Lunes", Calendar.TUESDAY to "Martes", Calendar.WEDNESDAY to "Miércoles",
            Calendar.THURSDAY to "Jueves", Calendar.FRIDAY to "Viernes", Calendar.SATURDAY to "Sábado",
            Calendar.SUNDAY to "Domingo",
        )
        val hoy = Calendar.getInstance().get(Calendar.DAY_OF_WEEK)
        dias.forEach { (d, nombre) ->
            val t = tarjeta()
            t.addView(texto(nombre, 19f, if (d == hoy) Ui.HANKO else Ui.PAPEL, Ui.SERIF).apply { setPadding(0, 0, 0, dp(10)) })
            val acts = store.actividades(d)
            val fila = FilaFluida(this)
            Actividad.values().forEach { act ->
                val on = act in acts
                fila.addView(chip(act.etiqueta, on) {
                    store.guardarActividades(d, if (on) acts - act else acts + act)
                    val y = scroll.scrollY
                    mostrar(Pestania.SEMANA)
                    scroll.post { scroll.scrollTo(0, y) }
                })
            }
            t.addView(fila)
            contenido.addView(t, lp().margen(abajo = dp(10)))
        }
    }

    // ================================================================== DIARIO
    private fun pantallaDiario() {
        encabezado("Diario", "Lo que te pegó y lo que te propusiste")

        seccion("Favoritos")
        val favs = store.favoritos().mapNotNull { Mensajes.porId(it) }
        if (favs.isEmpty()) {
            contenido.addView(texto("Cuando un mensaje te pegue, tocá ♡ en la pantalla de la alarma y queda acá.", 15f, Ui.TENUE, Ui.SERIF_ITALICA))
        }
        favs.forEach { m ->
            val t = tarjeta()
            t.addView(texto(m.texto, 18f, Ui.PAPEL, Ui.SERIF).apply { setLineSpacing(0f, 1.3f) })
            if (m.fuente.isNotBlank()) t.addView(texto("— " + m.fuente, 13f, Ui.TENUE, Ui.SERIF_ITALICA).apply { setPadding(0, dp(8), 0, 0) })
            t.addView(texto("♥  Quitar", 13f, Ui.HANKO, Ui.MEDIA).apply {
                setPadding(0, dp(12), 0, 0)
                setOnClickListener { store.alternarFavorito(m.id); mostrar(Pestania.DIARIO) }
            })
            contenido.addView(t, lp().margen(abajo = dp(10)))
        }

        seccion("Intenciones")
        val ints = store.intenciones()
        if (ints.isEmpty()) {
            contenido.addView(texto("Cada mañana, después de apagar la alarma, escribís qué vas a conquistar ese día. Se guarda acá.", 15f, Ui.TENUE, Ui.SERIF_ITALICA))
        }
        ints.forEach { i ->
            val fila = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(0, dp(10), 0, dp(10)) }
            fila.addView(rotulo(i.fecha))
            fila.addView(texto(i.texto, 17f, Ui.PAPEL, Ui.SERIF).apply { setPadding(0, dp(4), 0, 0) })
            contenido.addView(fila)
            contenido.addView(View(this).apply { setBackgroundColor(Ui.LINEA) }, lp(alto = dp(1)))
        }
    }

    // ================================================================== AJUSTES
    private fun pantallaAjustes() {
        encabezado("Ajustes", "Sonido, voz y permisos")

        val t = tarjeta()
        t.addView(filaInterruptor("Leer el mensaje en voz alta", "Cuando apagás la alarma, una voz te lo lee", store.voz) { store.voz = it })
        t.addView(View(this).apply { setBackgroundColor(Ui.LINEA) }, lp(alto = dp(1)).margen(arriba = dp(12), abajo = dp(12)))
        t.addView(filaInterruptor("Vibrar", "Suave a los 20 segundos, fuerte a los 5 minutos", store.vibrar) { store.vibrar = it })
        contenido.addView(t, lp())

        seccion("Mi música")
        val m = tarjeta()
        m.addView(texto(store.musicaPropiaNombre ?: "Ninguna canción elegida", 16f, Ui.PAPEL, Ui.SERIF))
        m.addView(rotulo("Se usa en las alarmas con sonido \"Mi música\"").apply { setPadding(0, dp(4), 0, dp(12)) })
        m.addView(boton("Elegir canción", principal = false) {
            val i = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "audio/*"
            }
            startActivityForResult(i, PEDIR_MUSICA)
        })
        contenido.addView(m, lp())

        seccion("Probar")
        contenido.addView(boton("Probar la alarma ahora") {
            AlarmService.iniciar(this, AlarmService.ID_PRUEBA)
        }, lp())
        contenido.addView(rotulo("La prueba no cuenta para la racha").apply { setPadding(0, dp(8), 0, 0) })

        seccion("Permisos para que suene siempre")
        val p = tarjeta()
        val nm = getSystemService(NotificationManager::class.java)
        val pm = getSystemService(PowerManager::class.java)

        filaPermiso(p, "Notificaciones",
            Build.VERSION.SDK_INT < 33 || checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        ) {
            if (Build.VERSION.SDK_INT >= 33) requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
        }
        filaPermiso(p, "Pantalla completa sobre el bloqueo",
            Build.VERSION.SDK_INT < 34 || nm.canUseFullScreenIntent()
        ) {
            if (Build.VERSION.SDK_INT >= 34) abrirAjuste(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
        }
        filaPermiso(p, "Alarmas exactas", Programador.puedeExactas(this)) {
            if (Build.VERSION.SDK_INT >= 31) abrirAjuste(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
        }
        filaPermiso(p, "Batería sin restricciones", pm.isIgnoringBatteryOptimizations(packageName)) {
            abrirAjuste(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
        }
        contenido.addView(p, lp())

        val version = runCatching { packageManager.getPackageInfo(packageName, 0).versionName }.getOrNull() ?: ""
        contenido.addView(rotulo("Kiai · v$version · hecho para Flor de Liz").apply {
            gravity = Gravity.CENTER
            setPadding(0, dp(32), 0, 0)
        }, lp())
    }

    private fun filaInterruptor(titulo: String, sub: String, on: Boolean, cambio: (Boolean) -> Unit): View {
        val fila = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        val col = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        col.addView(texto(titulo, 16f, Ui.PAPEL, Ui.NORMAL))
        col.addView(texto(sub, 13f, Ui.TENUE, Ui.NORMAL).apply { setPadding(0, dp(2), dp(8), 0) })
        fila.addView(col, lp(0, peso = 1f))
        fila.addView(interruptor(on, cambio))
        return fila
    }

    private fun filaPermiso(destino: LinearLayout, nombre: String, ok: Boolean, arreglar: () -> Unit) {
        val fila = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dp(10), 0, dp(10))
        }
        fila.addView(texto(nombre, 15f, Ui.PAPEL), lp(0, peso = 1f))
        val estado: TextView = if (ok) texto("✓ Listo", 13f, Ui.TENUE, Ui.MEDIA)
        else texto("ACTIVAR", 12f, Ui.HANKO, Ui.MEDIA, 0.16f).apply { setOnClickListener { arreglar() } }
        fila.addView(estado)
        destino.addView(fila)
    }

    private fun abrirAjuste(accion: String) {
        try {
            startActivity(Intent(accion, Uri.parse("package:$packageName")))
        } catch (_: Exception) {
            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PEDIR_MUSICA || resultCode != RESULT_OK) return
        val uri = data?.data ?: return
        runCatching {
            contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        var nombre = "Canción elegida"
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
            if (c.moveToFirst()) nombre = c.getString(0) ?: nombre
        }
        store.musicaPropia = uri.toString()
        store.musicaPropiaNombre = nombre
        Toast.makeText(this, "Listo. Elegí \"Mi música\" en la alarma.", Toast.LENGTH_LONG).show()
    }

    companion object {
        private const val PEDIR_MUSICA = 42
    }
}
