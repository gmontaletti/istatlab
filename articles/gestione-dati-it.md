# Gestione efficiente dei dati ISTAT

``` r
library(istatlab)
library(data.table)
```

## 1. Perché minimizzare le chiamate API

L’API SDMX di ISTAT ha limiti di velocità e timeout di connessione (il
valore predefinito del pacchetto è 240 secondi). Il download di dataset
di grandi dimensioni richiede tempo e può comportare errori di rete. La
memorizzazione nella cache dei dati garantisce riproducibilità: i
risultati rimangono coerenti anche se ISTAT aggiorna i dataset. Il
pacchetto istatlab è progettato per minimizzare le chiamate API
ridondanti attraverso un sistema di cache a più livelli.

Le chiamate API ripetute causano:

- Timeout di connessione su dataset voluminosi
- Sovraccarico dei server ISTAT
- Tempi di attesa prolungati per l’utente
- Risultati potenzialmente incoerenti tra esecuzioni successive

Il sistema di cache riduce questi problemi mantenendo metadati e dati
scaricati in locale.

## 2. Limiti e blocchi dell’API ISTAT

L’API SDMX di ISTAT applica limiti di velocità per proteggere
l’infrastruttura del server. Il superamento di questi limiti può
comportare blocchi temporanei degli indirizzi IP. Il pacchetto istatlab
implementa contromisure automatiche per rispettare questi limiti e
gestire gli errori di rete.

### 2.1 Comportamento del rate limiting

ISTAT impone un limite di circa 5 richieste al minuto. Quando questo
limite viene superato, il server risponde con HTTP 429 (Too Many
Requests). Dopo violazioni ripetute, il server può bloccare
temporaneamente l’indirizzo IP per 24-48 ore.

Il server può anche restituire HTTP 503 (Service Unavailable) quando è
sovraccarico o durante manutenzioni.

### 2.2 Sistema di throttling

La funzione
[`throttle()`](https://gmontaletti.github.io/istatlab/reference/throttle.md)
in `R/http_transport.R` applica un ritardo minimo di 13 secondi tra le
richieste consecutive. Questo corrisponde a circa 4.6 richieste al
minuto, valore inferiore al limite di circa 5 richieste al minuto
imposto da ISTAT.

Il throttling utilizza un ambiente a livello di pacchetto
(`.istat_rate_limiter`) per tracciare il timestamp dell’ultima
richiesta. Ad ogni ritardo viene aggiunto un jitter casuale (+/- 10%)
per evitare pattern di richieste sincronizzate.

``` r
# 1. Visualizzare la configurazione del rate limiting -----
config <- get_istat_config()
print(config$rate_limit)

# 2. Il ritardo è applicato automaticamente tra chiamate -----
# Non è necessaria alcuna azione da parte dell'utente
data1 <- download_istat_data("150_908", start_time = "2023")
data2 <- download_istat_data("534_50", start_time = "2023")
# Il sistema attende automaticamente 13 secondi (+/- jitter) tra le due chiamate
```

### 2.3 Retry con backoff esponenziale

La funzione
[`http_get_with_retry()`](https://gmontaletti.github.io/istatlab/reference/http_get_with_retry.md)
gestisce automaticamente i codici HTTP 429 e 503 con tentativi di retry.
Vengono effettuati fino a 3 tentativi con backoff esponenziale:

- Primo retry: 60 secondi di attesa
- Secondo retry: 120 secondi di attesa
- Terzo retry: 240 secondi di attesa

Il backoff massimo è limitato a 300 secondi. Se il server fornisce
l’header `Retry-After`, il sistema lo rispetta. Ad ogni backoff viene
aggiunto jitter casuale per evitare sincronizzazione.

``` r
# 1. I retry sono gestiti automaticamente dal sistema -----
# L'utente non deve implementare logica di retry manuale
data <- download_istat_data("150_908", start_time = "2020")
# In caso di 429 o 503, il sistema ritenta fino a 3 volte

# 2. Parametri di configurazione del backoff -----
config <- get_istat_config()$rate_limit
print(paste("Max retries:", config$max_retries))
print(paste("Initial backoff:", config$initial_backoff, "secondi"))
print(paste("Backoff multiplier:", config$backoff_multiplier))
print(paste("Max backoff:", config$max_backoff, "secondi"))
```

### 2.4 Rilevamento del ban

La funzione
[`detect_ban()`](https://gmontaletti.github.io/istatlab/reference/detect_ban.md)
monitora le risposte HTTP 429 consecutive. Dopo 3 risposte 429
consecutive (threshold configurabile), il sistema emette un warning che
indica un probabile ban dell’indirizzo IP e interrompe i tentativi di
retry.

Dopo un periodo di attesa di 24-48 ore, è possibile resettare lo stato
del rate limiter con
[`reset_rate_limiter()`](https://gmontaletti.github.io/istatlab/reference/reset_rate_limiter.md):

``` r
# 1. Il rilevamento del ban è automatico -----
# Il sistema emette un warning dopo 3 risposte 429 consecutive
# Warning: "Your IP may be temporarily banned by ISTAT. Wait 24-48 hours."

# 2. Reset del rate limiter dopo il periodo di ban -----
reset_rate_limiter()
# Resetta il contatore di 429 consecutivi e il timestamp dell'ultima richiesta

# 3. Configurazione della soglia di rilevamento -----
config <- get_istat_config()$rate_limit
print(paste("Ban detection threshold:", config$ban_detection_threshold))
```

### 2.5 Esecuzione sequenziale nei download multipli

La funzione
[`download_multiple_datasets()`](https://gmontaletti.github.io/istatlab/reference/download_multiple_datasets.md)
forza l’esecuzione sequenziale dei download per garantire che il rate
limiting sia rispettato. Il parametro `n_cores` è mantenuto per
compatibilità con versioni precedenti, ma viene ignorato.

``` r
# 1. Download di dataset multipli con rate limiting -----
dataset_ids <- c("150_908", "534_50", "534_51")
data_list <- download_multiple_datasets(dataset_ids, start_time = "2020")
# I download avvengono in sequenza con throttling applicato

# 2. Il parametro n_cores è ignorato -----
# Mantenuto per retrocompatibilità, ma l'esecuzione è sempre sequenziale
data_list <- download_multiple_datasets(dataset_ids, n_cores = 4)
# n_cores viene ignorato: esecuzione sequenziale con rate limiting
```

### 2.6 Fallback del trasporto HTTP

La funzione
[`http_get()`](https://gmontaletti.github.io/istatlab/reference/http_get.md)
tenta prima di utilizzare
[`httr::GET()`](https://httr.r-lib.org/reference/GET.html). Se fallisce,
il sistema utilizza automaticamente curl di sistema come fallback.
Questo fornisce resilienza contro problemi specifici delle librerie
HTTP.

``` r
# 1. Il fallback è completamente trasparente -----
# L'utente non deve gestire manualmente il metodo HTTP
data <- download_istat_data("150_908", start_time = "2023")
# Il sistema seleziona automaticamente il metodo HTTP appropriato

# 2. Il risultato include il metodo utilizzato -----
# Disponibile nei log interni per debugging
# Method: "httr" o "curl"
```

### 2.7 Classificazione degli errori

Il sistema classifica gli errori API con exit code standardizzati
(definiti in `R/error_handling.R`):

- **Exit code 0**: Operazione riuscita
- **Exit code 1**: Errore generico (connettività, HTTP, parsing)
- **Exit code 2**: Timeout di connessione
- **Exit code 3**: Rate limiting (HTTP 429)

La funzione
[`classify_api_error()`](https://gmontaletti.github.io/istatlab/reference/classify_api_error.md)
categorizza gli errori per una gestione coerente:

``` r
# 1. Gli exit code sono gestiti internamente -----
# L'utente riceve messaggi di errore descrittivi
# Gli exit code sono disponibili negli oggetti istat_result

# 2. Verifica manuale dello stato (avanzato) -----
# La maggior parte degli utenti non necessita di questo livello di dettaglio
result <- tryCatch(
  download_istat_data("INVALID_ID"),
  error = function(e) NULL
)
# Il sistema classifica automaticamente il tipo di errore
```

## 3. Il sistema di cache dei metadati

La funzione
[`download_metadata()`](https://gmontaletti.github.io/istatlab/reference/download_metadata.md)
scarica il catalogo completo dei dataset ISTAT e lo memorizza in
`meta/flussi_istat.rds` con un TTL (time-to-live) di 14 giorni. Alla
prima chiamata, i dati vengono scaricati dall’API. Le chiamate
successive leggono dalla cache locale fino alla scadenza.

``` r
# 1. Primo download: interroga l'API ISTAT -----
metadata <- download_metadata()
# Scarica il catalogo e lo salva in meta/flussi_istat.rds

# 2. Chiamate successive: legge dalla cache -----
metadata <- download_metadata()
# Restituisce i dati dalla cache senza chiamare l'API
```

Struttura della directory cache:

    meta/
      flussi_istat.rds          # Catalogo dei dataset
      codelists.rds             # Codelist memorizzate nella cache
      dataset_codelist_map.rds  # Mapping dataset-codelist
      data_download_log.rds     # Registro timestamp download
      codelist_metadata.rds     # Metadati TTL codelist

Per visualizzare la configurazione della cache:

``` r
# 1. Configurazione generale -----
config <- get_istat_config()
print(config$cache)

# 2. Durata predefinita della cache -----
cache_days <- config$defaults$cache_days
print(paste("Cache TTL:", cache_days, "giorni"))
```

## 4. Il sistema TTL sfalsato per le codelist

Le codelist (classificazioni come ITTER107 per i territori o ATECO per
le attività economiche) sono memorizzate separatamente. Se tutte le
codelist scadessero simultaneamente, si verificherebbe un sovraccarico
dell’API. Il pacchetto utilizza un sistema di TTL sfalsato: ogni
codelist ha una durata calcolata come
`base_ttl + hash(codelist_id) % jitter_days`.

``` r
# 1. Calcolare il TTL di una codelist specifica -----
ttl_days <- compute_codelist_ttl("CL_ITTER107")
print(paste("TTL per CL_ITTER107:", ttl_days, "giorni"))

# 2. Verificare quali codelist sono scadute per un dataset -----
expired_info <- check_codelist_expiration("150_908")
print(expired_info$expired_codelists)

# 3. Aggiornare solo le codelist scadute -----
refresh_expired_codelists("150_908")
```

Configurazione del sistema TTL:

``` r
# 1. Visualizzare i parametri TTL -----
config <- get_istat_config()
base_ttl <- config$cache$codelist_base_ttl_days  # 14 giorni
jitter <- config$cache$codelist_jitter_days      # 14 giorni
print(paste("Base TTL:", base_ttl, "| Jitter:", jitter))

# 2. Funzioni di gestione metadati (basso livello) -----
metadata <- load_codelist_metadata()
# save_codelist_metadata(metadata)  # Salvataggio manuale
```

Questo approccio distribuisce i refresh delle codelist nel tempo,
evitando picchi di carico sull’API.

## 5. Verificare gli aggiornamenti prima del download

Prima di scaricare un dataset, è possibile verificare se ISTAT ha
pubblicato aggiornamenti dall’ultimo download. La funzione
[`get_dataset_last_update()`](https://gmontaletti.github.io/istatlab/reference/get_dataset_last_update.md)
restituisce il timestamp `LAST_UPDATE` fornito dall’API. Il parametro
`check_update = TRUE` confronta questo timestamp con il registro dei
download locali.

``` r
# 1. Verificare manualmente il timestamp di aggiornamento -----
last_update <- get_dataset_last_update("150_908")
print(last_update)

# 2. Download con verifica automatica -----
data <- download_istat_data("150_908", start_time = "2023", check_update = TRUE)
# Se i dati non sono cambiati, restituisce NULL con messaggio informativo
```

Workflow completo:

``` r
# 1. Prima esecuzione: scarica e registra il timestamp -----
data_iniziale <- download_istat_data("150_908",
                                      start_time = "2023",
                                      check_update = TRUE)
print(dim(data_iniziale))

# 2. Esecuzione successiva: verifica prima di scaricare -----
data_aggiornata <- download_istat_data("150_908",
                                        start_time = "2023",
                                        check_update = TRUE)
# Se LAST_UPDATE non è cambiato, restituisce NULL
if (is.null(data_aggiornata)) {
  print("Nessun aggiornamento disponibile, utilizzo dati esistenti")
  data_aggiornata <- data_iniziale
}
```

Questo meccanismo riduce drasticamente le chiamate API non necessarie.

## 6. Download incrementale per periodo temporale

Il parametro `incremental` consente di scaricare solo i dati da una data
specifica in poi. Accetta oggetti Date o stringhe di carattere nei
formati “YYYY”, “YYYY-MM”, “YYYY-MM-DD”. Questo è utile per
aggiornamenti periodici che necessitano solo dei dati più recenti.

``` r
# 1. Download incrementale con anno -----
data_2024 <- download_istat_data("150_908", incremental = "2024")
# Scarica solo i dati dal 2024 in poi

# 2. Download incrementale con data specifica -----
data_recenti <- download_istat_data("150_908",
                                     incremental = as.Date("2024-06-01"))
# Scarica dati da giugno 2024 in poi

# 3. Differenza tra incremental e start_time -----
# incremental ha precedenza su start_time
data <- download_istat_data("150_908",
                             start_time = "2020",
                             incremental = "2024")
# Scarica solo dal 2024, start_time viene ignorato
```

Caso d’uso tipico per job di aggiornamento regolare:

``` r
# 1. Script di aggiornamento mensile -----
anno_corrente <- format(Sys.Date(), "%Y")
data_nuovi <- download_istat_data("150_908", incremental = anno_corrente)

# 2. Combinazione con check_update -----
data_nuovi <- download_istat_data("150_908",
                                   incremental = anno_corrente,
                                   check_update = TRUE)
# Scarica solo se ci sono aggiornamenti dal periodo specificato
```

## 7. Integrazione con dati esistenti

Il parametro `existing_data` consente di integrare nuovi download con
dati già scaricati, gestendo automaticamente la deduplicazione dei
periodi sovrapposti. Questo è utile quando si costruiscono serie
storiche incrementali.

``` r
# 1. Download iniziale di dati storici -----
data_2023 <- download_istat_data("150_908",
                                  start_time = "2023",
                                  end_time = "2023")
print(dim(data_2023))

# 2. Download aggiuntivo con integrazione -----
data_completo <- download_istat_data("150_908",
                                      start_time = "2024",
                                      existing_data = data_2023)
# data_completo contiene 2023 + 2024 senza duplicati
print(dim(data_completo))

# 3. Verifica della deduplicazione -----
# La deduplicazione avviene sulle colonne chiave dimensionali
# Mantiene le righe più recenti in caso di sovrapposizione
```

Workflow per aggiornamenti periodici:

``` r
# 1. Caricamento dati esistenti -----
# data_storico <- readRDS("data/serie_150_908.rds")

# 2. Download incrementale e integrazione -----
data_aggiornato <- download_istat_data("150_908",
                                        incremental = "2025",
                                        existing_data = data_storico,
                                        check_update = TRUE)

# 3. Salvataggio dati completi -----
# saveRDS(data_aggiornato, "data/serie_150_908.rds")
```

La logica di deduplicazione mantiene le righe più recenti quando rileva
duplicati sulle colonne chiave dimensionali.

## 8. Download in batch efficiente

Per scaricare più dataset simultaneamente,
[`download_multiple_datasets()`](https://gmontaletti.github.io/istatlab/reference/download_multiple_datasets.md)
utilizza l’esecuzione parallela con
[`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html). I
core disponibili sono configurabili.

``` r
# 1. Download batch di dataset correlati -----
dataset_ids <- c("534_50", "534_51", "534_52")
data_list <- download_multiple_datasets(dataset_ids,
                                         start_time = "2020")
# Restituisce una lista nominata: data_list[["534_50"]], etc.

# 2. Accesso ai dati scaricati -----
print(names(data_list))
data_534_50 <- data_list[["534_50"]]

# 3. Download solo di dataset aggiornati -----
timestamp_riferimento <- as.POSIXct("2025-12-10 14:30:00", tz = "UTC")
updated_list <- download_multiple_datasets(dataset_ids,
                                            updated_after = timestamp_riferimento)
# Scarica solo i dataset modificati dopo il timestamp
```

Gestione degli errori:

``` r
# 1. Download batch con gestione errori -----
dataset_ids <- c("150_908", "INVALID_ID", "534_50")
data_list <- download_multiple_datasets(dataset_ids)

# 2. Verifica dei risultati -----
for (id in dataset_ids) {
  if (is.null(data_list[[id]])) {
    print(paste("Errore nel download di", id))
  } else {
    print(paste("Scaricato", id, ":", nrow(data_list[[id]]), "righe"))
  }
}
# I dataset con errori restituiscono NULL, gli altri continuano
```

Il parallelismo accelera significativamente il download di più dataset
indipendenti.

## 9. Frequenze e download mirato

I dataset ISTAT possono contenere dati con frequenze diverse (annuale,
trimestrale, mensile). La funzione
[`get_available_frequencies()`](https://gmontaletti.github.io/istatlab/reference/get_available_frequencies.md)
identifica le frequenze presenti. La funzione
[`download_istat_data_by_freq()`](https://gmontaletti.github.io/istatlab/reference/download_istat_data_by_freq.md)
può scaricare automaticamente tutte le frequenze separatamente o
filtrare per una frequenza specifica.

``` r
# 1. Identificare le frequenze disponibili -----
freq_disponibili <- get_available_frequencies("151_914")
print(freq_disponibili)  # es. c("A", "Q", "M")

# 2. Download automatico con split per frequenza -----
data_list <- download_istat_data_by_freq("151_914", start_time = "2020")
# Restituisce lista nominata: data_list$Q, data_list$A, data_list$M

# 3. Accesso ai dati per frequenza -----
data_trimestrale <- data_list$Q
data_annuale <- data_list$A
print(dim(data_trimestrale))

# 4. Download solo frequenza specifica -----
data_solo_Q <- download_istat_data_by_freq("151_914",
                                            start_time = "2020",
                                            freq = "Q")
# Restituisce solo i dati trimestrali
```

Considerazioni sull’efficienza:

``` r
# 1. Quando usare freq parameter -----
# Se serve solo una frequenza, specificare freq riduce i dati scaricati
data_mensile <- download_istat_data_by_freq("151_914", freq = "M")

# 2. Quando usare split automatico -----
# Se servono tutte le frequenze per analisi comparative
data_tutte <- download_istat_data_by_freq("151_914")

# 3. Alternativa con download_istat_data() -----
# Per dataset con frequenza omogenea, usare download_istat_data()
data_standard <- download_istat_data("150_908")
# Più efficiente se non serve separazione per frequenza
```

## 10. Gestione della directory cache

La directory cache predefinita è `meta/` nella directory di lavoro
corrente. È possibile specificare directory alternative con il parametro
`cache_dir`.

``` r
# 1. Directory cache predefinita -----
config <- get_istat_config()
default_cache <- config$cache$metadata_file
print(dirname(default_cache))  # "meta"

# 2. Uso di directory cache alternativa -----
data <- download_istat_data("150_908",
                             cache_dir = "/percorso/alternativo/meta")

# 3. Metadata con cache personalizzata -----
metadata <- download_metadata(cache_dir = "/percorso/alternativo/meta")
```

Portabilità e versionamento:

``` r
# 1. Portabilità tra macchine -----
# La directory meta/ può essere copiata tra sistemi
# system("cp -r meta/ /altro/progetto/meta/")

# 2. Controllo versione con git -----
# Considerare .gitignore per file cache voluminosi
# .gitignore:
#   meta/*.rds
#   !meta/flussi_istat.rds  # Tracciare solo metadata principale

# 3. Pulizia cache per fresh start -----
# unlink("meta", recursive = TRUE)
# dir.create("meta")
# Forza il re-download completo alla prossima chiamata
```

Best practice:

- Mantenere la cache nella directory radice del progetto per
  riproducibilità
- Copiare `meta/` quando si condivide il progetto per evitare
  re-download
- Documentare la data di creazione della cache per tracciabilità
- Usare `cache_dir` personalizzata solo per esigenze specifiche di
  organizzazione

## 11. Riepilogo e best practice

Albero decisionale per la gestione dei download:

``` r
# 1. Primo download di un dataset -----
metadata <- download_metadata()
data <- download_istat_data("150_908", start_time = "2020")

# 2. Aggiornamento periodico (job schedulato) -----
data_aggiornato <- download_istat_data("150_908",
                                        incremental = format(Sys.Date(), "%Y"),
                                        check_update = TRUE)

# 3. Integrazione con dati parziali esistenti -----
data_completo <- download_istat_data("150_908",
                                      start_time = "2025",
                                      existing_data = data_storico)

# 4. Download multipli correlati -----
data_list <- download_multiple_datasets(c("534_50", "534_51", "534_52"),
                                         start_time = "2020")

# 5. Download per frequenza specifica -----
data_trimestrale <- download_istat_data_by_freq("151_914",
                                                  freq = "Q",
                                                  start_time = "2020")
```

Workflow consigliato per pipeline produttive:

``` r
# 1. Setup iniziale del progetto -----
dir.create("data", showWarnings = FALSE)
dir.create("meta", showWarnings = FALSE)

# 2. Prima esecuzione: download completo -----
metadata <- download_metadata()
data_iniziale <- download_istat_data("150_908",
                                      start_time = "2020",
                                      check_update = TRUE)
saveRDS(data_iniziale, "data/dataset_150_908.rds")

# 3. Aggiornamenti periodici (script schedulato) -----
data_esistente <- readRDS("data/dataset_150_908.rds")
data_aggiornato <- download_istat_data("150_908",
                                        incremental = format(Sys.Date(), "%Y"),
                                        existing_data = data_esistente,
                                        check_update = TRUE)
if (!is.null(data_aggiornato)) {
  saveRDS(data_aggiornato, "data/dataset_150_908.rds")
  print("Dati aggiornati con successo")
} else {
  print("Nessun aggiornamento disponibile")
}

# 4. Verifica scadenza codelist -----
check_codelist_expiration("150_908")
refresh_expired_codelists("150_908")
```

Principi chiave:

1.  **Primo download**: Usare
    [`download_metadata()`](https://gmontaletti.github.io/istatlab/reference/download_metadata.md)
    e
    [`download_istat_data()`](https://gmontaletti.github.io/istatlab/reference/download_istat_data.md)
    senza parametri complessi
2.  **Aggiornamenti periodici**: Combinare `check_update = TRUE` con
    `incremental` per efficienza
3.  **Integrazione incrementale**: Usare `existing_data` per costruire
    serie storiche
4.  **Batch processing**: Preferire
    [`download_multiple_datasets()`](https://gmontaletti.github.io/istatlab/reference/download_multiple_datasets.md)
    per dataset correlati
5.  **Frequenze specifiche**: Usare
    `download_istat_data_by_freq(freq = "Q")` quando serve solo una
    frequenza

Riferimenti ad altre vignette:

- [`vignette("getting-started-it")`](https://gmontaletti.github.io/istatlab/articles/getting-started-it.md):
  Introduzione al pacchetto e workflow base
- [`vignette("api-istat-sdmx-it")`](https://gmontaletti.github.io/istatlab/articles/api-istat-sdmx-it.md):
  Dettagli tecnici sull’API SDMX di ISTAT

Per domande o problemi, consultare la documentazione delle funzioni con
[`?download_istat_data`](https://gmontaletti.github.io/istatlab/reference/download_istat_data.md)
o
[`?download_metadata`](https://gmontaletti.github.io/istatlab/reference/download_metadata.md).
