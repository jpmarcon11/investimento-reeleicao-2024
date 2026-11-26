# 00_main.R
# Roda o trabalho do início ao fim. Antes:
#   1. definir a pasta do trabalho como diretório de trabalho (setwd);
#   2. colocar os 7 zips do FINBRA em dados_brutos/siconfi_finbra/ (passo manual, ver LEIAME.md);
#   3. instalar os pacotes: install.packages(c("data.table", "jsonlite", "AER", "stargazer", "marginaleffects"))
# Os scripts 01 a 04 só baixam o que ainda não está em dados_brutos/importados/.

# dados brutos guardados em dados_brutos.zip: descompacta se a pasta não existir
if (!dir.exists("dados_brutos/importados") && file.exists("dados_brutos.zip")) unzip("dados_brutos.zip")

scripts <- c("01_download_tse.R", "03_download_ibge.R", "04_importar_finbra.R",
             "05_limpeza.R", "06_descritivas.R", "07_estimacao.R", "08_robustez.R")
for (s in scripts) {
  cat("\n==========", s, "==========\n")
  t0 <- Sys.time()
  source(file.path("codigo", s), encoding = "UTF-8", local = new.env(), print.eval = TRUE)   # mostra os testes no console
  cat("tempo:", round(difftime(Sys.time(), t0, units = "secs")), "s\n")
}

# versões do R e dos pacotes usados
writeLines(capture.output(sessionInfo()), "saidas/sessionInfo.txt")
