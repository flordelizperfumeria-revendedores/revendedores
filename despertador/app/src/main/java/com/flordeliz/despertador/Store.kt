package com.flordeliz.despertador

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

enum class Sonido(val etiqueta: String) {
    TAIKO("Taiko"),
    EPICO("Épico"),
    AMANECER("Amanecer"),
    PROPIA("Mi música"),
    AZAR("Al azar"),
}

/** days usa las constantes de Calendar (SUNDAY = 1 … SATURDAY = 7). Vacío = una sola vez. */
data class Alarma(
    val id: Int,
    val hora: Int,
    val minuto: Int,
    val dias: Set<Int>,
    val activa: Boolean,
    val sonido: Sonido,
) {
    fun toJson() = JSONObject().apply {
        put("id", id); put("hora", hora); put("minuto", minuto)
        put("dias", JSONArray(dias.sorted())); put("activa", activa); put("sonido", sonido.name)
    }

    companion object {
        fun fromJson(o: JSONObject): Alarma {
            val d = o.optJSONArray("dias") ?: JSONArray()
            return Alarma(
                id = o.getInt("id"),
                hora = o.getInt("hora"),
                minuto = o.getInt("minuto"),
                dias = (0 until d.length()).map { d.getInt(it) }.toSet(),
                activa = o.optBoolean("activa", true),
                sonido = runCatching { Sonido.valueOf(o.optString("sonido")) }.getOrDefault(Sonido.TAIKO),
            )
        }
    }
}

data class Intencion(val fecha: String, val texto: String)

class Store(context: Context) {
    private val p: SharedPreferences =
        context.applicationContext.getSharedPreferences("kiai", Context.MODE_PRIVATE)

    // ---------------------------------------------------------------- alarmas
    fun alarmas(): List<Alarma> {
        val arr = JSONArray(p.getString("alarmas", "[]"))
        return (0 until arr.length()).map { Alarma.fromJson(arr.getJSONObject(it)) }
            .sortedWith(compareBy({ it.hora }, { it.minuto }))
    }

    fun guardarAlarmas(lista: List<Alarma>) {
        p.edit().putString("alarmas", JSONArray(lista.map { it.toJson() }).toString()).apply()
    }

    fun alarma(id: Int) = alarmas().firstOrNull { it.id == id }

    fun upsert(a: Alarma) = guardarAlarmas(alarmas().filter { it.id != a.id } + a)

    fun borrar(id: Int) = guardarAlarmas(alarmas().filter { it.id != id })

    fun nuevoId(): Int {
        val n = p.getInt("sigId", 1)
        p.edit().putInt("sigId", n + 1).apply()
        return n
    }

    // ---------------------------------------------------------------- semana
    fun actividades(diaSemana: Int): Set<Actividad> {
        val guardado = p.getString("semana_$diaSemana", null)
            ?: return semanaPorDefecto(diaSemana)
        if (guardado.isEmpty()) return emptySet()
        return guardado.split(",").mapNotNull { runCatching { Actividad.valueOf(it) }.getOrNull() }.toSet()
    }

    fun guardarActividades(diaSemana: Int, acts: Set<Actividad>) {
        p.edit().putString("semana_$diaSemana", acts.joinToString(",") { it.name }).apply()
    }

    private fun semanaPorDefecto(d: Int): Set<Actividad> = when (d) {
        Calendar.MONDAY, Calendar.WEDNESDAY, Calendar.FRIDAY ->
            setOf(Actividad.ABOGACIA, Actividad.GYM, Actividad.NEGOCIO)
        Calendar.TUESDAY, Calendar.THURSDAY ->
            setOf(Actividad.ABOGACIA, Actividad.KARATE, Actividad.PERFUMERIA)
        Calendar.SATURDAY -> setOf(Actividad.NEGOCIO, Actividad.PERFUMERIA)
        else -> setOf(Actividad.DESCANSO)
    }

    // ---------------------------------------------------------------- ajustes
    var voz: Boolean
        get() = p.getBoolean("voz", true)
        set(v) = p.edit().putBoolean("voz", v).apply()

    var vibrar: Boolean
        get() = p.getBoolean("vibrar", true)
        set(v) = p.edit().putBoolean("vibrar", v).apply()

    var musicaPropia: String?
        get() = p.getString("musicaPropia", null)
        set(v) = p.edit().putString("musicaPropia", v).apply()

    var musicaPropiaNombre: String?
        get() = p.getString("musicaPropiaNombre", null)
        set(v) = p.edit().putString("musicaPropiaNombre", v).apply()

    // ---------------------------------------------------------------- mensajes
    fun recientes(): List<String> =
        p.getString("recientes", "")!!.split(",").filter { it.isNotBlank() }

    fun marcarMostrado(id: String) {
        val l = (listOf(id) + recientes().filter { it != id }).take(40)
        p.edit().putString("recientes", l.joinToString(",")).apply()
    }

    fun favoritos(): List<String> =
        p.getString("favoritos", "")!!.split(",").filter { it.isNotBlank() }

    fun esFavorito(id: String) = id in favoritos()

    fun alternarFavorito(id: String): Boolean {
        val f = favoritos()
        val nueva = if (id in f) f - id else listOf(id) + f
        p.edit().putString("favoritos", nueva.joinToString(",")).apply()
        return id in nueva
    }

    // ---------------------------------------------------------------- racha
    val racha: Int get() = p.getInt("racha", 0)
    val mejorRacha: Int get() = p.getInt("mejorRacha", 0)

    /** a tiempo = apagó la alarma antes del mensaje duro de los 5 minutos. */
    fun registrarDespertar(aTiempo: Boolean) {
        val hoy = fecha(0)
        val ultimo = p.getString("ultimoDespertar", null)
        if (ultimo == hoy) {
            // Segunda alarma del mismo día: sólo puede cortar la racha, no sumarla.
            if (!aTiempo) p.edit().putInt("racha", 0).apply()
            return
        }
        val nueva = when {
            !aTiempo -> 0
            ultimo == fecha(-1) -> racha + 1
            else -> 1
        }
        p.edit()
            .putString("ultimoDespertar", hoy)
            .putInt("racha", nueva)
            .putInt("mejorRacha", maxOf(mejorRacha, nueva))
            .apply()
    }

    // ---------------------------------------------------------------- intenciones
    fun intenciones(): List<Intencion> {
        val arr = JSONArray(p.getString("intenciones", "[]"))
        return (0 until arr.length()).map {
            val o = arr.getJSONObject(it)
            Intencion(o.getString("fecha"), o.getString("texto"))
        }
    }

    fun agregarIntencion(texto: String) {
        val l = listOf(Intencion(fecha(0), texto)) + intenciones()
        val arr = JSONArray(l.take(60).map { JSONObject().put("fecha", it.fecha).put("texto", it.texto) })
        p.edit().putString("intenciones", arr.toString()).apply()
    }

    companion object {
        fun fecha(desplazamientoDias: Int): String {
            val c = Calendar.getInstance()
            c.add(Calendar.DAY_OF_YEAR, desplazamientoDias)
            return "%04d-%02d-%02d".format(c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH))
        }
    }
}
