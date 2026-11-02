package com.flordeliz.despertador

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import java.util.Calendar

object Programador {

    const val EXTRA_ID = "alarmaId"

    /** Próximo disparo en milisegundos, o null si la alarma está apagada. */
    fun proximo(a: Alarma, desde: Calendar = Calendar.getInstance()): Long? {
        if (!a.activa) return null
        val c = desde.clone() as Calendar
        c.set(Calendar.HOUR_OF_DAY, a.hora)
        c.set(Calendar.MINUTE, a.minuto)
        c.set(Calendar.SECOND, 0)
        c.set(Calendar.MILLISECOND, 0)
        if (!c.after(desde)) c.add(Calendar.DAY_OF_YEAR, 1)
        if (a.dias.isNotEmpty()) {
            var n = 0
            while (c.get(Calendar.DAY_OF_WEEK) !in a.dias && n < 8) {
                c.add(Calendar.DAY_OF_YEAR, 1); n++
            }
        }
        return c.timeInMillis
    }

    private fun pendiente(ctx: Context, id: Int): PendingIntent {
        val i = Intent(ctx, AlarmReceiver::class.java).putExtra(EXTRA_ID, id)
        return PendingIntent.getBroadcast(
            ctx, id, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun puedeExactas(ctx: Context): Boolean {
        val am = ctx.getSystemService(AlarmManager::class.java)
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
    }

    fun programar(ctx: Context, a: Alarma) {
        val am = ctx.getSystemService(AlarmManager::class.java)
        val pi = pendiente(ctx, a.id)
        am.cancel(pi)
        val cuando = proximo(a) ?: return
        val abrir = PendingIntent.getActivity(
            ctx, 0, Intent(ctx, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        try {
            if (puedeExactas(ctx)) {
                am.setAlarmClock(AlarmManager.AlarmClockInfo(cuando, abrir), pi)
            } else {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cuando, pi)
            }
        } catch (e: SecurityException) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cuando, pi)
        }
    }

    fun cancelar(ctx: Context, id: Int) {
        ctx.getSystemService(AlarmManager::class.java).cancel(pendiente(ctx, id))
    }

    fun reprogramarTodas(ctx: Context) {
        Store(ctx).alarmas().forEach { programar(ctx, it) }
    }

    /** La alarma más cercana entre todas, para mostrar "suena en…". */
    fun siguiente(ctx: Context): Long? =
        Store(ctx).alarmas().mapNotNull { proximo(it) }.minOrNull()
}

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val id = intent.getIntExtra(Programador.EXTRA_ID, -1)
        val pm = ctx.getSystemService(PowerManager::class.java)
        pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "kiai:receptor").acquire(10_000)

        val store = Store(ctx)
        store.alarma(id)?.let { a ->
            // Alarma de una sola vez: se apaga. Repetitiva: se programa la próxima.
            if (a.dias.isEmpty()) store.upsert(a.copy(activa = false))
            else Programador.programar(ctx, a)
        }
        AlarmService.iniciar(ctx, id)
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        Programador.reprogramarTodas(ctx)
    }
}
