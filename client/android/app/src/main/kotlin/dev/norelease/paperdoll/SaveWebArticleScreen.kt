package dev.norelease.paperdoll

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

/**
 * Process-lifetime scope. Work started here survives dismissal of the activity, so the
 * user can close the dialog mid-request without losing the save. It does NOT survive
 * process death — if the OS reclaims the (now empty) app process before the request
 * completes, the save is lost. That window is accepted here in lieu of WorkManager.
 */
object SaveScope {
    val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
}

sealed interface SaveState {
    data object Loading : SaveState

    data object Success : SaveState

    data class Error(val kind: SaveErrorKind) : SaveState
}

/**
 * Categories of save failure. Kept coarse on purpose: the UI shows a fixed, user-facing
 * message per category and never surfaces the underlying exception, which may leak internal
 * details (server error bodies, stack info, etc.).
 */
enum class SaveErrorKind {
    /** The request never reached the server (no connectivity, timeout, etc.). */
    Network,

    /** The server responded with an error, or anything else went wrong. */
    Unexpected,
}

private fun SaveErrorKind.message(): String =
    when (this) {
        SaveErrorKind.Network ->
            "Couldn't reach the server. Check your connection and try again."
        SaveErrorKind.Unexpected ->
            "Couldn't add to your reading list. Please try again."
    }

@Composable
fun SaveWebArticleScreen(url: String, title: String?, onClose: () -> Unit) {
    var state by remember { mutableStateOf<SaveState>(SaveState.Loading) }
    // Only observes the request; the request itself runs in SaveScope so it outlives this
    // composition. When the dialog closes, only this observer is cancelled, not the POST.
    val observerScope = rememberCoroutineScope()

    LaunchedEffect(url) {
        val deferred = SaveScope.scope.async { runCatching { postToReadingList(url, title) } }
        observerScope.launch {
            state =
                deferred.await().fold(
                    onSuccess = { SaveState.Success },
                    onFailure = {
                        val kind =
                            if (it is IOException) SaveErrorKind.Network
                            else SaveErrorKind.Unexpected
                        SaveState.Error(kind)
                    },
                )
        }
    }

    Column(
        modifier = Modifier.fillMaxWidth().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        when (val s = state) {
            is SaveState.Loading -> {
                CircularProgressIndicator()
                Spacer(Modifier.height(16.dp))
                Text("Adding to Reading List…")
                Spacer(Modifier.height(16.dp))
                // The user can close at any time; the request keeps running in SaveScope.
                TextButton(onClick = onClose) { Text("Close") }
            }
            is SaveState.Success -> {
                Text("Added to Reading List")
                if (!title.isNullOrBlank()) {
                    Spacer(Modifier.height(8.dp))
                    Text(
                        title,
                        style = MaterialTheme.typography.bodyMedium,
                        textAlign = TextAlign.Center,
                        maxLines = 3,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                Spacer(Modifier.height(16.dp))
                Button(onClick = onClose) { Text("Close") }
            }
            is SaveState.Error -> {
                Text(s.kind.message(), textAlign = TextAlign.Center)
                Spacer(Modifier.height(16.dp))
                Button(onClick = onClose) { Text("Close") }
            }
        }
    }
}

/** Maximum length of the placeholder title sent to the server (URL is left as-is). */
private const val MAX_TITLE_LENGTH = 140

/**
 * Caps [title] at [MAX_TITLE_LENGTH] characters, truncating and appending "..." (so the
 * result never exceeds the limit) when it is longer.
 */
private fun truncateTitle(title: String): String =
    if (title.length > MAX_TITLE_LENGTH) {
        title.take(MAX_TITLE_LENGTH - 3) + "..."
    } else {
        title
    }

/**
 * POSTs `{"url": url}` (plus an optional `title` placeholder, when a non-blank one was
 * shared) to the reading-list endpoint. The title is capped at [MAX_TITLE_LENGTH]
 * characters. The API responds 201 with an empty `{}` body, so there is nothing to parse —
 * success is the status code alone. There is no auth header (the API has none). Throws on a
 * non-2xx response or any I/O failure.
 */
fun postToReadingList(url: String, title: String?) {
    val endpoint = URL(BuildConfig.API_BASE_URL.trimEnd('/') + "/reading-list")
    val connection = endpoint.openConnection() as HttpURLConnection
    try {
        connection.requestMethod = "POST"
        connection.setRequestProperty("Content-Type", "application/json")
        connection.setRequestProperty("Accept", "application/json")
        connection.connectTimeout = 15_000
        connection.readTimeout = 15_000
        connection.doOutput = true

        val json = JSONObject().put("url", url)
        if (!title.isNullOrBlank()) {
            json.put("title", truncateTitle(title))
        }
        val body = json.toString()
        connection.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }

        val code = connection.responseCode
        if (code !in 200..299) {
            val error = connection.errorStream?.bufferedReader()?.use { it.readText() }
            throw RuntimeException("HTTP $code" + if (!error.isNullOrBlank()) ": $error" else "")
        }
    } finally {
        connection.disconnect()
    }
}
