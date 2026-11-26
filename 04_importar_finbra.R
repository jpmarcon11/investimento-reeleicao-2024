# 04_importar_finbra.R
# Importa os zips do RREO baixados à mão no FINBRA (ver LEIAME.md).
# Entrada: dados_brutos/siconfi_finbra/*.zip
# Saída:   dados_brutos/importados/finbra_rreo_<tabela>_<ano>_b4.rds

library(data.table)

dir_finbra <- "dados_brutos/siconfi_finbra"
dir_import <- "dados_brutos/importados"
dir.create(dir_import, recursive = TRUE, showWarnings = FALSE)

zips <- list.files(dir_finbra, pattern = "^finbra_rreo_.*\\.zip$", full.names = TRUE)
if (length(zips) == 0 && length(list.files(dir_import, "^finbra_rreo_.*\\.rds$")) == 0)
  stop("Nenhum arquivo finbra_rreo_*.zip em ", dir_finbra)

# CSV do FINBRA: 5 linhas de metadados, separador ";", decimal ",", Latin-1
importar_finbra <- function(arq_zip) {
  tmp <- file.path(tempdir(), sub("\\.zip$", "", basename(arq_zip)))
  unzip(arq_zip, exdir = tmp)
  csv <- list.files(tmp, pattern = "\\.csv$", full.names = TRUE)
  meta <- iconv(readLines(csv, n = 5, encoding = "latin1"), from = "latin1", to = "UTF-8")

  dt <- fread(csv, skip = 5, sep = ";", dec = ",", encoding = "Latin-1", colClasses = "character")
  setnames(dt, c("instituicao", "cod_ibge", "uf", "populacao", "coluna", "conta", "id_conta", "valor"))
  for (v in c("instituicao", "coluna", "conta")) set(dt, j = v, value = enc2utf8(dt[[v]]))
  dt[, valor := as.numeric(gsub(",", ".", gsub(".", "", valor, fixed = TRUE), fixed = TRUE))]   # "1.234,56" -> 1234.56
  dt[, `:=`(exercicio = regmatches(meta[1], regexpr("20[0-9]{2}", meta[1])),
            tabela_finbra = sub("^Tabela: ", "", meta[5]))]
  unlink(tmp, recursive = TRUE)
  dt
}

for (z in zips) {
  saida <- file.path(dir_import, sub("\\.zip$", ".rds", basename(z)))
  if (file.exists(saida)) { message("Já importado: ", saida); next }
  dt <- importar_finbra(z)
  saveRDS(dt, saida)
  message(basename(saida), ": ", nrow(dt), " linhas, ", uniqueN(dt$cod_ibge), " municípios")
  rm(dt); gc()
}
