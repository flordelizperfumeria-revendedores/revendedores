package com.flordeliz.despertador

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Calendar
import java.util.Locale

/**
 * Hace sonar la alarma: música con crescendo, vibración, mensaje duro a los 5 minutos
 * y lectura en voz del mensaje del día cuando se apaga.
 */
class AlarmService : Service() {

    /** Estado compartido con AlarmActivity (mismo proceso). */
    object Estado {
        var sonando = false
        var mensajeId: String = ""
        var duroId: String? = null
        var aTiempo = true
        var prueba = false
        var inicio = 0L
        var oyente: (() -> Unit)? = null
    }

    private val handler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var tts: TextToSpeech? = null
    private var ttsListo = false
    private var wake: PowerManager.WakeLock? = null
    private var volumen = 0.12f
    private val durosUsados = mutableSetOf<String>()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACCION_APAGAR -> apagar(intent.getStringExtra(EXTRA_LEER))
            else -> sonar(intent?.getIntExtra(Programador.EXTRA_ID, -1) ?: -1)
        }
        return START_NOT_STICKY
    }

    // ------------------------------------------------------------------ sonar
    private fun sonar(alarmaId: Int) {
        ponerEnPrimerPlano()
        if (Estado.sonando) return

        val store = Store(this)
        val dia = Calendar.getInstance().get(Calendar.DAY_OF_WEEK)
        val msg = Mensajes.delDia(store.actividades(dia), store.recientes())
        store.marcarMostrado(msg.id)
        Estado.sonando = true
        Estado.mensajeId = msg.id
        Estado.duroId = null
        Estado.aTiempo = true
        Estado.prueba = alarmaId == ID_PRUEBA
        Estado.inicio = System.currentTimeMillis()

        wake = getSystemService(PowerManager::class.java)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "kiai:sonando")
            .apply { acquire(MAX_SONANDO + 60_000) }

        prepararVoz()
        val sonido = store.alarma(alarmaId)?.sonido
            ?: store.alarmas().firstOrNull { it.activa }?.sonido
            ?: Sonido.TAIKO
        reproducir(sonido, store)
        subirVolumen()
        if (store.vibrar) handler.postDelayed({ vibrar(suave = true) }, 20_000)
        handler.postDelayed(::modoDuro, ESPERA_DURO)
        handler.postDelayed({ apagar(null) }, MAX_SONANDO)

        abrirPantalla()
    }

    private fun reproducir(elegido: Sonido, store: Store) {
        val atributos = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        val sonido = if (elegido == Sonido.AZAR)
            listOf(Sonido.TAIKO, Sonido.EPICO, Sonido.AMANECER).random() else elegido
        val mp = MediaPlayer()
        try {
            mp.setAudioAttributes(atributos)
            val propia = store.musicaPropia
            if (sonido == Sonido.PROPIA && propia != null) {
                mp.setDataSource(this, Uri.parse(propia))
            } else {
                val raw = when (sonido) {
                    Sonido.EPICO -> R.raw.epico
                    Sonido.AMANECER -> R.raw.amanecer
                    else -> R.raw.taiko
                }
                val afd = resources.openRawResourceFd(raw)
                mp.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
            }
            mp.isLooping = true
            mp.setVolume(volumen, volumen)
            mp.prepare()
            mp.start()
            player = mp
        } catch (e: Exception) {
            // Si falla la música propia (archivo borrado, sin permiso), suena el taiko.
            mp.release()
            if (sonido != Sonido.TAIKO) reproducir(Sonido.TAIKO, store)
        }
    }

    /** Crescendo: de muy bajo a volumen completo en ~45 segundos. */
    private fun subirVolumen() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                if (!Estado.sonando) return
                if (volumen < 1f) {
                    volumen = minOf(1f, volumen + 0.01f)
                    player?.setVolume(volumen, volumen)
                    handler.postDelayed(this, 450)
                }
            }
        }, 450)
    }

    private fun vibrador(): Vibrator =
        if (Build.VERSION.SDK_INT >= 31) getSystemService(VibratorManager::class.java).defaultVibrator
        else getSystemService(Vibrator::class.java)

    private fun vibrar(suave: Boolean) {
        val v = vibrador()
        val patron = if (suave) longArrayOf(0, 400, 1600) else longArrayOf(0, 700, 300, 700, 900)
        val attrs = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build()
        @Suppress("DEPRECATION")
        v.vibrate(VibrationEffect.createWaveform(patron, 0), attrs)
    }

    private fun pararVibracion() {
        vibrador().cancel()
    }

    // ------------------------------------------------------------------ 5 minutos
    private fun modoDuro() {
        if (!Estado.sonando) return
        val m = Mensajes.duro(durosUsados)
        durosUsados += m.id
        Estado.duroId = m.id
        Estado.aTiempo = false
        Estado.oyente?.invoke()
        volumen = 1f
        if (Store(this).vibrar) vibrar(suave = false)
        player?.setVolume(0.15f, 0.15f)
        hablar(m.texto, "duro") {
            if (Estado.sonando) player?.setVolume(1f, 1f)
        }
        handler.postDelayed(::modoDuro, REPETIR_DURO)
    }

    // ------------------------------------------------------------------ voz
    private fun prepararVoz() {
        tts = TextToSpeech(this) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val t = tts ?: return@TextToSpeech
                val idiomas = listOf(Locale("es", "AR"), Locale("es", "US"), Locale("es", "ES"), Locale("es"))
                for (loc in idiomas) {
                    if (t.isLanguageAvailable(loc) >= TextToSpeech.LANG_AVAILABLE) { t.language = loc; break }
                }
                t.setSpeechRate(0.92f)
                t.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                ttsListo = true
            }
        }
    }

    private fun hablar(texto: String, id: String, alTerminar: () -> Unit) {
        val t = tts
        if (t == null || !ttsListo) { alTerminar(); return }
        t.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {}
            override fun onDone(utteranceId: String?) { handler.post { alTerminar() } }
            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String?) { handler.post { alTerminar() } }
        })
        t.speak(texto, TextToSpeech.QUEUE_FLUSH, Bundle(), id)
    }

    // ------------------------------------------------------------------ apagar
    private fun apagar(leer: String?) {
        Estado.sonando = false
        Estado.oyente = null
        handler.removeCallbacksAndMessages(null)
        player?.run { runCatching { stop() }; release() }
        player = null
        pararVibracion()
        if (!leer.isNullOrBlank() && Store(this).voz && ttsListo) {
            // Pequeña pausa para que el silencio marque el cambio, y después la voz.
            handler.postDelayed({ hablar(leer, "dia") { terminar() } }, 600)
            handler.postDelayed({ terminar() }, 90_000)
        } else {
            terminar()
        }
    }

    private fun terminar() {
        handler.removeCallbacksAndMessages(null)
        tts?.run { stop(); shutdown() }
        tts = null
        wake?.let { if (it.isHeld) it.release() }
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        Estado.sonando = false
        handler.removeCallbacksAndMessages(null)
        player?.release()
        tts?.shutdown()
        wake?.let { if (it.isHeld) it.release() }
        super.onDestroy()
    }

    // ------------------------------------------------------------------ notificación
    private fun ponerEnPrimerPlano() {
        val nm = getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CANAL) == null) {
            val ch = NotificationChannel(CANAL, "Alarma", NotificationManager.IMPORTANCE_HIGH).apply {
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                description = "Pantalla de la alarma sonando"
            }
            nm.createNotificationChannel(ch)
        }
        val pantalla = PendingIntent.getActivity(
            this, 1,
            Intent(this, AlarmActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val n = Notification.Builder(this, CANAL)
            .setSmallIcon(R.drawable.ic_frente)
            .setContentTitle("Kiai · Es hora")
            .setContentText("Tocá para leer tu mensaje y apagar la alarma")
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .setContentIntent(pantalla)
            .setFullScreenIntent(pantalla, true)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIF_ID, n)
        }
    }

    private fun abrirPantalla() {
        try {
            startActivity(
                Intent(this, AlarmActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        } catch (_: Exception) {
            // Si el sistema no deja abrirla desde segundo plano, la abre la notificación.
        }
    }

    companion object {
        private const val CANAL = "kiai_alarma"
        private const val NOTIF_ID = 7
        const val ACCION_APAGAR = "apagar"
        const val EXTRA_LEER = "leer"
        const val ESPERA_DURO = 5 * 60_000L
        const val REPETIR_DURO = 150_000L
        const val MAX_SONANDO = 30 * 60_000L
        const val ID_PRUEBA = -7

        fun iniciar(ctx: Context, alarmaId: Int) {
            val i = Intent(ctx, AlarmService::class.java).putExtra(Programador.EXTRA_ID, alarmaId)
            ctx.startForegroundService(i)
        }

        fun apagar(ctx: Context, textoALeer: String?) {
            val i = Intent(ctx, AlarmService::class.java)
                .setAction(ACCION_APAGAR)
                .putExtra(EXTRA_LEER, textoALeer)
            ctx.startService(i)
        }
    }
}
