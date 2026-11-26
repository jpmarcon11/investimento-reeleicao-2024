# 03_download_ibge.R
# Baixa do SIDRA população 2024 (6579), PIB 2023 (5938) e alfabetização 2022 (9543),
# e a correspondência de códigos TSE x IBGE (GitHub).
# Saída: dados_brutos/importados/*.rds

library(jsonlite)
library(data.table)
options(timeout = 600)

dir_import <- "dados_brutos/importados"
dir.create(dir_import, recursive = TRUE, showWarnings = FALSE)

ja_existe <- function(arq) {
  f <- file.path(dir_import, arq)
  if (file.exists(f)) message("Já importado: ", f)
  file.exists(f)
}

# a 1ª linha da resposta do SIDRA é o cabeçalho; D1C = código IBGE, V = valor
baixar_sidra <- function(url) {
  bruto <- fromJSON(url)
  dt <- as.data.table(bruto[-1, ])
  setattr(dt, "descricao_colunas", unlist(bruto[1, ]))
  dt
}

if (!ja_existe("ibge_populacao_2024.rds"))
  saveRDS(baixar_sidra("https://apisidra.ibge.gov.br/values/t/6579/n6/all/v/9324/p/2024"),
          file.path(dir_import, "ibge_populacao_2024.rds"))

# PIB a preços correntes, em mil reais
if (!ja_existe("ibge_pib_2023.rds"))
  saveRDS(baixar_sidra("https://apisidra.ibge.gov.br/values/t/5938/n6/all/v/37/p/2023"),
          file.path(dir_import, "ibge_pib_2023.rds"))

if (!ja_existe("correspondencia_tse_ibge.rds")) {
  corresp <- fread(paste0("https://raw.githubusercontent.com/betafcc/Municipios-Brasileiros-TSE/",
                          "master/municipios_brasileiros_tse.csv"), colClasses = "character", encoding = "UTF-8")
  corresp[, codigo_tse := formatC(as.integer(codigo_tse), width = 5, flag = "0")]   # TSE usa 5 dígitos
  saveRDS(corresp, file.path(dir_import, "correspondencia_tse_ibge.rds"))
}

# taxa de alfabetização, 15 anos ou mais; sem classificação na URL, o SIDRA devolve os totais
if (!ja_existe("ibge_alfabetizacao_2022.rds")) {
  alf <- baixar_sidra("https://apisidra.ibge.gov.br/values/t/9543/n6/all/v/all/p/all")
  cab <- attr(alf, "descricao_colunas")
  alf <- alf[grepl("^Taxa de alfabetiza", get(names(cab)[cab == "Variável"]))]
  stopifnot(!anyDuplicated(alf$D1C))   # um valor por município
  saveRDS(alf, file.path(dir_import, "ibge_alfabetizacao_2022.rds"))
}
