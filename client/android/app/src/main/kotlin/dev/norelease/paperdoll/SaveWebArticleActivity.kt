package dev.norelease.paperdoll

import android.content.Intent
import android.os.Bundle
import android.util.Patterns
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface

/**
 * Dialog-style activity launched from the browser's share sheet. It extracts the shared
 * URL, POSTs it to the reading list, and shows the result. It intentionally extends
 * [ComponentActivity] rather than FlutterActivity so it never boots the Flutter engine.
 */
class SaveWebArticleActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val sendIntent = intent?.takeIf { it.action == Intent.ACTION_SEND }
        val sharedText = sendIntent?.getStringExtra(Intent.EXTRA_TEXT)

        // The manifest can only filter by MIME type (text/plain), which also matches
        // non-URL text shares, so validate the actual content here at runtime.
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
            MaterialTheme {
                Surface {
                    SaveWebArticleScreen(url = url, title = title, onClose = { finish() })
                }
            }
        }
    }

    /**
     * Browsers often share "Page Title https://example.com/x", so [Patterns.WEB_URL]
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
