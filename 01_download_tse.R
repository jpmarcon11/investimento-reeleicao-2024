# 01_download_tse.R
# Baixa e importa do TSE: candidatos (2016, 2020, 2022, 2024) e votação por zona (2020, 2024).
# Saída: dados_brutos/importados/<base>.rds

library(data.table)
options(timeout = 3600)   # arquivos de votação são grandes

dir_brutos <- "dados_brutos/tse"
dir_import <- "dados_brutos/importados"
dir.create(dir_brutos, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_import, recursive = TRUE, showWarnings = FALSE)

base_url <- "https://cdn.tse.jus.br/estatistica/sead/odsele"
bases <- data.frame(
  nome  = c("consulta_cand_2016", "consulta_cand_2020", "consulta_cand_2022", "consulta_cand_2024",
            "votacao_candidato_munzona_2020", "votacao_candidato_munzona_2024"),
  pasta = c(rep("consulta_cand", 4), rep("votacao_candidato_munzona", 2))
)

baixar_zip <- function(nome, pasta) {
  arq <- file.path(dir_brutos, paste0(nome, ".zip"))
  if (!file.exists(arq))
    download.file(paste0(base_url, "/", pasta, "/", nome, ".zip"), arq, mode = "wb")
  arq
}

importar_zip <- function(arq_zip, nome) {
  destino <- file.path(dir_brutos, nome)
  unzip(arq_zip, exdir = destino)
  csvs <- list.files(destino, pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE)
  brasil <- grep("BRASIL", csvs, value = TRUE)
  if (length(brasil) == 1) csvs <- brasil   # usa o arquivo nacional, se existir, para não duplicar
  # tudo como texto: preserva zeros à esquerda (título, município)
  rbindlist(lapply(csvs, fread, sep = ";", encoding = "Latin-1", colClasses = "character"),
            use.names = TRUE, fill = TRUE)
}

for (i in seq_len(nrow(bases))) {
  saida <- file.path(dir_import, paste0(bases$nome[i], ".rds"))
  if (file.exists(saida)) { message("Já importado: ", saida); next }
  dt <- importar_zip(baixar_zip(bases$nome[i], bases$pasta[i]), bases$nome[i])
  saveRDS(dt, saida)
  message(bases$nome[i], ": ", nrow(dt), " linhas")
  rm(dt); gc()
}
