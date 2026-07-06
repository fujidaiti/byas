package dev.norelease.paperdoll

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Patterns
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.platform.LocalContext

/**
 * Dialog-style activity launched from the browser's share sheet. It extracts the shared
 * URL, POSTs it to the reading list, and shows the result.
 */
class SaveWebClipActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val sendIntent = intent?.takeIf { it.action == Intent.ACTION_SEND }
        val sharedText = sendIntent?.getStringExtra(Intent.EXTRA_TEXT)
        val url = sharedText?.let { extractUrl(it) }
        if (url == null) {
            finish()
            return
        }
        // Browsers (e.g. Chrome) put the page title in EXTRA_SUBJECT. Use it as a
        // placeholder title so the item has a meaningful label before the server's
        // async fetch fills in the real one. May be null; blanks are dropped downstream.
        val title = sendIntent.getStringExtra(Intent.EXTRA_SUBJECT)

        setContent {
            val context = LocalContext.current
            val dark = isSystemInDarkTheme()
            // Material You dynamic color (wallpaper-derived) is only available on Android 12
            // (API 31) and up; fall back to the Material 3 baseline scheme below that.
            val colorScheme =
                when {
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
                        if (dark) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
                    dark -> darkColorScheme()
                    else -> lightColorScheme()
                }
            MaterialTheme(colorScheme = colorScheme) {
                Surface {
                    SaveWebClipScreen(url = url, title = title, onClose = { finish() })
                }
            }
        }
    }

    /**
     * Apps may share "Page Title https://example.com/x", so [Patterns.WEB_URL]
     * `.matches()` (which requires the whole string to be a URL) is not enough. Return the
     * first http(s) URL found in the text; the scheme check avoids matching a bare
     * "example.com" that happens to appear in the title.
     */
    private fun extractUrl(text: String): String? {
        val trimmed = text.trim()
        if (Patterns.WEB_URL.matcher(trimmed).matches() &&
            (trimmed.startsWith("http://") || trimmed.startsWith("https://"))
        ) {
            return trimmed
        }
        val matcher = Patterns.WEB_URL.matcher(trimmed)
        while (matcher.find()) {
            val candidate = trimmed.substring(matcher.start(), matcher.end())
            if (candidate.startsWith("http://") || candidate.startsWith("https://")) {
                return candidate
            }
        }
        return null
    }
}
