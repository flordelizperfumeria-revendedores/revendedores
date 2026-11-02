package com.flordeliz.despertador

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView

/** Paleta y piezas visuales: estética dojo minimalista. */
object Ui {
    val FONDO = Color.parseColor("#0D0D0D")
    val SUPERFICIE = Color.parseColor("#161616")
    val LINEA = Color.parseColor("#2A2A2A")
    val PAPEL = Color.parseColor("#EDE6DA")
    val TENUE = Color.parseColor("#8C857A")
    val HANKO = Color.parseColor("#C8102E")
    val HANKO_OSCURO = Color.parseColor("#3A0A12")

    val SERIF: Typeface = Typeface.create(Typeface.SERIF, Typeface.NORMAL)
    val SERIF_ITALICA: Typeface = Typeface.create(Typeface.SERIF, Typeface.ITALIC)
    val LIVIANA: Typeface = Typeface.create("sans-serif-thin", Typeface.NORMAL)
    val MEDIA: Typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
    val NORMAL: Typeface = Typeface.create("sans-serif", Typeface.NORMAL)
}

fun Context.dp(v: Number): Int =
    TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()

fun Context.texto(
    t: CharSequence,
    tam: Float = 16f,
    color: Int = Ui.PAPEL,
    fuente: Typeface = Ui.NORMAL,
    espaciado: Float = 0f,
): TextView = TextView(this).apply {
    text = t
    textSize = tam
    setTextColor(color)
    typeface = fuente
    letterSpacing = espaciado
}

/** Rótulo chico en mayúsculas espaciadas, como los encabezados de un dojo. */
fun Context.rotulo(t: String, color: Int = Ui.TENUE) =
    texto(t.uppercase(), 11f, color, Ui.MEDIA, 0.22f)

fun fondoRedondeado(color: Int, radio: Float, borde: Int? = null, anchoBorde: Int = 0) =
    GradientDrawable().apply {
        setColor(color)
        cornerRadius = radio
        if (borde != null) setStroke(anchoBorde, borde)
    }

fun View.conToque(color: Int = Color.parseColor("#33EDE6DA")) {
    val actual = background
    background = RippleDrawable(ColorStateList.valueOf(color), actual, actual ?: fondoRedondeado(Color.WHITE, 0f))
    isClickable = true
    isFocusable = true
}

fun Context.tarjeta(): LinearLayout = LinearLayout(this).apply {
    orientation = LinearLayout.VERTICAL
    background = fondoRedondeado(Ui.SUPERFICIE, dp(14).toFloat(), Ui.LINEA, dp(1))
    setPadding(dp(18), dp(16), dp(18), dp(16))
}

fun Context.boton(t: String, principal: Boolean = true, alTocar: () -> Unit): TextView =
    texto(t.uppercase(), 13f, Ui.PAPEL, Ui.MEDIA, 0.16f).apply {
        gravity = Gravity.CENTER
        setPadding(dp(20), dp(15), dp(20), dp(15))
        background = if (principal) fondoRedondeado(Ui.HANKO, dp(10).toFloat())
        else fondoRedondeado(Color.TRANSPARENT, dp(10).toFloat(), Ui.LINEA, dp(1))
        conToque()
        setOnClickListener { alTocar() }
    }

/** Chip seleccionable (días, actividades). */
fun Context.chip(t: String, activo: Boolean, alTocar: () -> Unit): TextView =
    texto(t, 13f, if (activo) Ui.PAPEL else Ui.TENUE, if (activo) Ui.MEDIA else Ui.NORMAL).apply {
        gravity = Gravity.CENTER
        setPadding(dp(12), dp(8), dp(12), dp(8))
        background = if (activo) fondoRedondeado(Ui.HANKO_OSCURO, dp(20).toFloat(), Ui.HANKO, dp(1))
        else fondoRedondeado(Color.TRANSPARENT, dp(20).toFloat(), Ui.LINEA, dp(1))
        conToque()
        setOnClickListener { alTocar() }
    }

/** Sello rojo circular (hanko) con un kanji. */
fun Context.sello(kanji: String, tam: Int = 64): TextView =
    texto(kanji, tam * 0.42f, Ui.PAPEL, Ui.SERIF).apply {
        gravity = Gravity.CENTER
        background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Ui.HANKO)
        }
        layoutParams = LinearLayout.LayoutParams(dp(tam), dp(tam))
    }

fun lp(
    ancho: Int = ViewGroup.LayoutParams.MATCH_PARENT,
    alto: Int = ViewGroup.LayoutParams.WRAP_CONTENT,
    peso: Float = 0f,
) = LinearLayout.LayoutParams(ancho, alto, peso)

fun LinearLayout.LayoutParams.margen(arriba: Int = 0, abajo: Int = 0, izq: Int = 0, der: Int = 0) =
    apply { setMargins(izq, arriba, der, abajo) }

/** Fila con chips que pasan de línea si no entran (simple, sin librerías). */
class FilaFluida(ctx: Context) : ViewGroup(ctx) {
    private val sep = ctx.dp(8)

    override fun onMeasure(wSpec: Int, hSpec: Int) {
        val ancho = MeasureSpec.getSize(wSpec)
        var x = 0; var y = 0; var altoFila = 0
        for (i in 0 until childCount) {
            val c = getChildAt(i)
            c.measure(MeasureSpec.makeMeasureSpec(ancho, MeasureSpec.AT_MOST), MeasureSpec.UNSPECIFIED)
            if (x + c.measuredWidth > ancho && x > 0) { x = 0; y += altoFila + sep; altoFila = 0 }
            x += c.measuredWidth + sep
            altoFila = maxOf(altoFila, c.measuredHeight)
        }
        setMeasuredDimension(ancho, y + altoFila)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        val ancho = r - l
        var x = 0; var y = 0; var altoFila = 0
        for (i in 0 until childCount) {
            val c = getChildAt(i)
            if (x + c.measuredWidth > ancho && x > 0) { x = 0; y += altoFila + sep; altoFila = 0 }
            c.layout(x, y, x + c.measuredWidth, y + c.measuredHeight)
            x += c.measuredWidth + sep
            altoFila = maxOf(altoFila, c.measuredHeight)
        }
    }
}
