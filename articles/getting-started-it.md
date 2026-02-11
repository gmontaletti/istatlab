# Introduzione a istatlab

``` r
library(istatlab)
library(data.table)
```

## Introduzione

Il pacchetto **istatlab** fornisce strumenti per scaricare, elaborare e
analizzare i dati statistici italiani dall’ISTAT (Istituto Nazionale di
Statistica) attraverso la sua API SDMX.

Questa vignette illustra il flusso di lavoro di base per il recupero e
l’etichettatura dei dati ISTAT. Funzionalità avanzate come le previsioni
e la visualizzazione sono documentate separatamente.

## Panoramica del flusso di lavoro

L’utilizzo di istatlab segue un flusso di lavoro in 6 fasi:

    +-------------+     +---------------+     +------------------+
    | 1. Verifica | --> | 2. Scarica    | --> | 3. Identifica    |
    |    API      |     |    Metadati   |     |    Dataset       |
    +-------------+     +---------------+     +------------------+
                                                       |
                                                       v
    +-------------+     +---------------+     +------------------+
    | 6. Applica  | <-- | 5. Scarica    | <-- | 4. Ottieni       |
    |    Etichette|     |    Dati       |     |    Codelist      |
    +-------------+     +---------------+     +------------------+
           |
           v
      [Dati etichettati pronti per l'analisi]

Ogni fase si basa sulla precedente. Il pacchetto memorizza in cache i
metadati e le codelist per ridurre al minimo le chiamate API nelle
sessioni successive.

## Fase 1: Verifica della connettività API

Prima di iniziare, verificare che l’API ISTAT sia accessibile:

``` r
status <- test_endpoint_connectivity("data", verbose = FALSE)
if (status$accessible[1]) {
  message("API ISTAT accessibile")
} else {
  message("API ISTAT non accessibile. Verificare la connessione internet.")
}
```

Questa funzione testa l’endpoint API e riporta se risponde
correttamente. Eseguire questo controllo per primo aiuta a diagnosticare
problemi di connettività prima di tentare il download dei dati.

## Fase 2: Download dei metadati

Il catalogo dei metadati contiene informazioni su tutti i dataset
disponibili:

``` r
metadata <- download_metadata()
```

I metadati includono:

- `id`: Identificatore del dataset (es. “150_908”)
- `Name.it`: Nome italiano del dataset
- `Name.en`: Nome inglese del dataset

``` r
head(metadata[, .(id, Name.it)])
```

I metadati sono memorizzati in cache localmente con un ciclo di
aggiornamento di 14 giorni. Le chiamate successive restituiscono la
versione in cache se non scaduta.

## Fase 3: Identificazione del dataset

Si possono cercare i dataset filtrando i metadati o usando
[`search_dataflows()`](https://gmontaletti.github.io/istatlab/reference/search_dataflows.md):

``` r
# Metodo 1: Filtrare i metadati direttamente
dataset_occupazione <- metadata[grepl("occupati|employment", Name.it, ignore.case = TRUE)]
dataset_occupazione[1:5, .(id, Name.it)]
```

``` r
# Metodo 2: Usare search_dataflows per la ricerca per parole chiave
risultati_ricerca <- search_dataflows("occupati")
head(risultati_ricerca[, .(id, Name.it)])
```

Per questa vignette, utilizziamo il dataset **“150_908”** (dati mensili
sull’occupazione).

Alcuni dataset hanno varianti multiple (dataset base più sotto-dataset).
Usare
[`expand_dataset_ids()`](https://gmontaletti.github.io/istatlab/reference/expand_dataset_ids.md)
per scoprire i dataset correlati:

``` r
correlati <- expand_dataset_ids("150_908")
print(correlati)
```

## Fase 4: Ottenere le codelist

I dati ISTAT utilizzano valori codificati (es. “IT” per Italia, “M” per
maschio). Le codelist mappano questi codici a etichette leggibili.

Prima, esaminare le dimensioni del dataset:

``` r
dimensioni <- get_dataset_dimensions("150_908")
print(dimensioni)
```

Poi scaricare le codelist per ogni dimensione:

``` r
codelists <- download_codelists("150_908")
names(codelists)
```

Ogni codelist è una data.table con `id` (il codice) e `name`
(l’etichetta):

``` r
# Visualizzare una codelist di esempio (es. territorio)
if ("ITTER107" %in% names(codelists)) {
  head(codelists[["ITTER107"]])
}
```

Si può verificare che tutte le codelist richieste siano disponibili con
[`ensure_codelists()`](https://gmontaletti.github.io/istatlab/reference/ensure_codelists.md):

``` r
ensure_codelists("150_908")
```

Le codelist sono memorizzate in cache per evitare download ripetuti. La
cache utilizza un sistema TTL sfalsato per distribuire i tempi di
aggiornamento.

## Fase 5: Download dei dati

Scaricare i dati effettivi usando
[`download_istat_data()`](https://gmontaletti.github.io/istatlab/reference/download_istat_data.md):

``` r
dati_grezzi <- download_istat_data("150_908", start_time = "2023")
```

I dati grezzi contengono valori codificati, non etichette:

``` r
dim(dati_grezzi)
head(dati_grezzi)
```

Parametri principali di
[`download_istat_data()`](https://gmontaletti.github.io/istatlab/reference/download_istat_data.md):

- `dataset_id`: Identificatore del dataset
- `start_time`: Filtrare i dati da questo periodo temporale in poi
- `end_time`: Filtrare i dati fino a questo periodo temporale
- `incremental`: Se TRUE, scaricare solo i dati più recenti rispetto
  alla versione in cache

## Fase 6: Applicazione delle etichette

Trasformare i valori codificati in etichette leggibili con
[`apply_labels()`](https://gmontaletti.github.io/istatlab/reference/apply_labels.md):

``` r
dati_etichettati <- apply_labels(dati_grezzi)
```

I dati etichettati includono:

- Colonne originali preservate
- `tempo`: Colonna data (convertita da TIME_PERIOD)
- `valore`: Colonna valore numerico (convertita da OBS_VALUE)
- Colonne `*_label`: Etichette leggibili per ogni dimensione

``` r
head(dati_etichettati)
```

Confrontare i codici originali con le etichette applicate:

``` r
# Mostrare la trasformazione da codici a etichette
colonne_da_mostrare <- grep("label$|tempo|valore", names(dati_etichettati), value = TRUE)
head(dati_etichettati[, ..colonne_da_mostrare])
```

## Lavorare con il risultato

I dati etichettati sono una data.table pronta per l’analisi:

``` r
# Statistiche di base
summary(dati_etichettati$valore)
```

``` r
# Intervallo temporale
range(dati_etichettati$tempo)
```

### Filtraggio per periodo temporale

Usare
[`filter_by_time()`](https://gmontaletti.github.io/istatlab/reference/filter_by_time.md)
per estrarre periodi specifici:

``` r
dati_recenti <- filter_by_time(dati_etichettati, start_date = "2024-01-01", time_col = "tempo")
nrow(dati_recenti)
```

### Validazione dei dati

Usare
[`validate_istat_data()`](https://gmontaletti.github.io/istatlab/reference/validate_istat_data.md)
per verificare la struttura e la qualità dei dati:

``` r
validazione <- validate_istat_data(dati_etichettati)
print(validazione)
```

## Esempio di flusso di lavoro completo

Ecco il flusso di lavoro completo in un singolo blocco di codice:

``` r
library(istatlab)

# 1. Verificare la connettività API
test_endpoint_connectivity("data", verbose = TRUE)

# 2. Scaricare i metadati
metadata <- download_metadata()

# 3. Identificare il dataset (es. dati mensili occupazione)
dataset_id <- "150_908"

# 4. Ottenere le codelist
ensure_codelists(dataset_id)

# 5. Scaricare i dati
dati_grezzi <- download_istat_data(dataset_id, start_time = "2023")

# 6. Applicare le etichette
dati_etichettati <- apply_labels(dati_grezzi)

# Risultato: dati etichettati pronti per l'analisi
head(dati_etichettati)
```

## Passi successivi

Dopo aver completato questo flusso di lavoro di base:

- Usare
  [`download_multiple_datasets()`](https://gmontaletti.github.io/istatlab/reference/download_multiple_datasets.md)
  per operazioni batch su più dataset
- Esplorare
  [`forecast_series()`](https://gmontaletti.github.io/istatlab/reference/forecast_series.md)
  per le previsioni delle serie temporali
- Consultare la documentazione del pacchetto per funzioni aggiuntive:
  [`?istatlab`](https://gmontaletti.github.io/istatlab/reference/istatlab-package.md)

Per l’elenco completo dei dataset disponibili, fare riferimento al
[catalogo SDMX
dell’ISTAT](https://www.istat.it/it/metodi-e-strumenti/web-service-sdmx).
