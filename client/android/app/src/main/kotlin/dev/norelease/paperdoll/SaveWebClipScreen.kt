package dev.norelease.paperdoll

import android.content.Context
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

/**
 * Process-lifetime scope. Work started here survives dismissal of the activity, so the
 * user can close the dialog mid-request without losing the save.
 */
object SaveScope {
    val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
}

sealed interface SaveState {
    data object Loading : SaveState

    data object Success : SaveState

    data class Error(val kind: SaveErrorKind) : SaveState
}

enum class SaveErrorKind {
    /** The request never reached the server (no connectivity, timeout, etc.). */
    Network,

    /** No auth token is stored locally, so the request was never sent. */
    Unauthenticated,

    /** The server responded with an error, or anything else went wrong. */
    Unexpected,
}

private fun SaveErrorKind.message(): String =
    when (this) {
        SaveErrorKind.Network ->
            "Couldn't reach the server. Check your connection and try again."

        SaveErrorKind.Unauthenticated ->
            "Log in to Paperdoll first, then try sharing again."

        SaveErrorKind.Unexpected ->
            "Couldn't add to your reading list. Please try again."
    }

/** Thrown by [postToReadingList] when no auth token is stored locally. */
class UnauthenticatedException : Exception()

private fun SaveState.statusHeadline(): String =
    when (this) {
        SaveState.Loading -> "Adding to Reading List…"
        SaveState.Success -> "Added to Reading List"
        is SaveState.Error -> "Couldn't Save"
    }

private val DIALOG_HEIGHT = 280.dp

@Composable
fun SaveWebClipScreen(url: String, title: String?, onClose: () -> Unit) {
    var state by remember { mutableStateOf<SaveState>(SaveState.Loading) }
    // Only observes the request; the request itself runs in SaveScope so it outlives this
    // composition. When the dialog closes, only this observer is cancelled, not the POST.
    val observerScope = rememberCoroutineScope()
    // Application context, not the activity: the request runs in the process-lifetime
    // SaveScope and may still be in flight after this activity is destroyed.
    val appContext = LocalContext.current.applicationContext

    LaunchedEffect(url) {
        val deferred =
            SaveScope.scope.async { runCatching { postToReadingList(appContext, url, title) } }
        observerScope.launch {
            state =
                deferred.await().fold(
                    onSuccess = { SaveState.Success },
                    onFailure = {
                        val kind =
                            when (it) {
                                is UnauthenticatedException -> SaveErrorKind.Unauthenticated
                                is IOException -> SaveErrorKind.Network
                                else -> SaveErrorKind.Unexpected
                            }
                        SaveState.Error(kind)
                    },
                )
        }
    }

    // Fall back to the raw URL when the browser didn't share a page title.
    val trimmedTitle = title?.takeIf { it.isNotBlank() }
    val label = trimmedTitle ?: url
    // When a title is shown, surface the URL's domain beneath it. When it isn't, the URL is
    // already the label, so there's nothing extra to show.
    val domain = if (trimmedTitle != null) domainOf(url) else null

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(DIALOG_HEIGHT)
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            state.statusHeadline(),
            modifier = Modifier.fillMaxWidth(),
            style = MaterialTheme.typography.titleLarge,
        )
        Spacer(Modifier.height(24.dp))

        when (val s = state) {
            is SaveState.Loading -> {
                CircularProgressIndicator()
                Spacer(Modifier.height(16.dp))
                PageTitle(label)
            }

            is SaveState.Success -> {
                PageTitle(label)
            }

            is SaveState.Error -> {
                Text(s.kind.message(), textAlign = TextAlign.Left)
            }
        }
        if (domain != null && state !is SaveState.Error) {
            Spacer(Modifier.height(8.dp))
            Text(
                domain,
                modifier = Modifier.fillMaxWidth(),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Left,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Spacer(Modifier.weight(1f))
        Button(onClick = onClose, modifier = Modifier.align(Alignment.End)) { Text("Close") }
    }
}

/** Best-effort host of [url] (e.g. "example.com"), or null if it can't be parsed. */
private fun domainOf(url: String): String? =
    runCatching { URL(url).host }.getOrNull()?.removePrefix("www.")?.takeIf { it.isNotBlank() }

/** The saved page's title (or its URL when no title was shared), in a prominent style. */
@Composable
private fun PageTitle(text: String) {
    Text(
        text,
        modifier = Modifier.fillMaxWidth(),
        style = MaterialTheme.typography.bodyLarge,
        textAlign = TextAlign.Left,
        maxLines = 4,
        overflow = TextOverflow.Ellipsis,
    )
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

/** Storage key shared with Dart's `authTokenStorageKey` (auth_repository_impl.dart). */
private const val AUTH_TOKEN_KEY = "auth_token"

suspend fun postToReadingList(context: Context, url: String, title: String?) {
    val token = TokenStore.read(context, AUTH_TOKEN_KEY) ?: throw UnauthenticatedException()

    withContext(Dispatchers.IO) {
        val endpoint = URL(BuildConfig.API_BASE_URL + "/reading-list")
        val connection = endpoint.openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept", "application/json")
            connection.setRequestProperty("Authorization", "Bearer $token")
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
                throw RuntimeException(
                    "HTTP $code" + if (!error.isNullOrBlank()) ": $error" else "",
                )
            }
        } finally {
            connection.disconnect()
        }
    }
}
