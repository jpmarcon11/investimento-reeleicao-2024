# 05_limpeza.R
# Monta a base final a partir de dados_brutos/importados/.
# Saídas: dados/base_final.rds (e .csv) e contagens em saidas/

imp <- "dados_brutos/importados"
le  <- function(arquivo) as.data.frame(readRDS(file.path(imp, arquivo)))
dir.create("dados", showWarnings = FALSE)
dir.create("saidas", showWarnings = FALSE)
ORD <- "ELEIÇÃO ORDINÁRIA"

# 1. TSE: candidatos a prefeito e votos
pref <- function(ano) { x <- le(sprintf("consulta_cand_%d.rds", ano)); x[x$CD_CARGO == "11", ] }
c16 <- pref(2016); c20 <- pref(2020); c24 <- pref(2024)

# 2020: votos válidos por candidato e turno (eleição ordinária)
v <- le("votacao_candidato_munzona_2020.rds")
v <- v[v$CD_CARGO == "11" & v$NM_TIPO_ELEICAO == "Eleição Ordinária", ]   # neste arquivo vem assim
stopifnot(nrow(v) > 0)
v$votos <- as.numeric(v$QT_VOTOS_NOMINAIS_VALIDOS)
v20 <- aggregate(votos ~ SG_UE + NR_TURNO + SQ_CANDIDATO, data = v, FUN = sum)

# 2024: candidaturas com votos anulados (indeferidas ou cassadas)
v <- le("votacao_candidato_munzona_2024.rds")
sq_anulado <- unique(v$SQ_CANDIDATO[v$CD_CARGO == "11" &
                                    v$NM_TIPO_DESTINACAO_VOTOS %in% c("Anulado", "Anulado sub judice")])
stopifnot(length(sq_anulado) > 0)
rm(v); gc()

# 2. Prefeitos eleitos em 2020
ord20 <- c20[c20$NM_TIPO_ELEICAO == ORD, ]
el <- ord20[ord20$DS_SIT_TOT_TURNO == "ELEITO", ]
stopifnot(nrow(el) > 0)
n_eleitos <- tapply(el$NR_TITULO_ELEITORAL_CANDIDATO, el$SG_UE, function(x) length(unique(x)))
el <- el[!el$SG_UE %in% names(n_eleitos)[n_eleitos > 1], ]
el <- el[!duplicated(el$SG_UE), ]   # uma linha por município

am <- data.frame(sg_ue_tse = el$SG_UE, uf = el$SG_UF, municipio = el$NM_UE,
                 nome_prefeito = el$NM_CANDIDATO, titulo = el$NR_TITULO_ELEITORAL_CANDIDATO,
                 genero = el$DS_GENERO, instrucao = el$DS_GRAU_INSTRUCAO, partido_2020 = el$SG_PARTIDO)

# 3. Situação em 2024 (município + título de eleitor)
ord24 <- c24[c24$NM_TIPO_ELEICAO == ORD, ]
stopifnot(nrow(ord24) > 0)
chave24 <- paste(ord24$SG_UE, ord24$NR_TITULO_ELEITORAL_CANDIDATO)
valida  <- tapply(ord24$DS_SIT_TOT_TURNO != "#NULO", chave24, any)
eleito  <- tapply(ord24$DS_SIT_TOT_TURNO == "ELEITO", chave24, any)
anulado <- tapply(ord24$SQ_CANDIDATO %in% sq_anulado, chave24, any)

chave <- paste(am$sg_ue_tse, am$titulo)
concorreu <- chave %in% names(valida)
# #NULO: fora da votação (renúncia, substituição ou indeferimento antes da urna)
am$status_2024 <- ifelse(!concorreu, "não concorreu",
                  ifelse(!valida[chave], "candidatura sem votos válidos (#NULO)",
                  ifelse(eleito[chave], "ELEITO", "NÃO ELEITO")))
am$concorreu_2024      <- as.integer(am$status_2024 %in% c("ELEITO", "NÃO ELEITO"))
am$reeleito_2024       <- as.integer(am$status_2024 == "ELEITO")
am$votos_anulados_2024 <- as.integer(concorreu & anulado[chave] %in% TRUE)
am$suplementar_2024    <- as.integer(am$sg_ue_tse %in% c24$SG_UE[c24$NM_TIPO_ELEICAO != ORD])
# eleição suplementar para o mandato 2021-2024: o prefeito eleito em 2020 deixou o cargo
am$suplementar_2021_2024 <- as.integer(am$sg_ue_tse %in% c20$SG_UE[c20$NM_TIPO_ELEICAO != ORD])

# 4. 1º mandato: não eleito prefeito no mesmo município em 2016
el16 <- c16[c16$DS_SIT_TOT_TURNO == "ELEITO", ]
am$primeiro_mandato <- as.integer(!chave %in% paste(el16$SG_UE, el16$NR_TITULO_ELEITORAL_CANDIDATO))

# 5. Margem de 2020: (1º - 2º) / válidos no turno decisivo; candidato único = 1
v20 <- v20[as.numeric(v20$NR_TURNO) == ave(as.numeric(v20$NR_TURNO), v20$SG_UE, FUN = max), ]
margem <- sapply(split(v20$votos, v20$SG_UE), function(x) {
  x <- sort(x, decreasing = TRUE)
  if (length(x) == 1) 1 else (x[1] - x[2]) / sum(x)
})
am$margem_2020 <- margem[am$sg_ue_tse]

# 6. Código IBGE
cw <- le("correspondencia_tse_ibge.rds")
am$cod_ibge <- cw$codigo_ibge[match(am$sg_ue_tse, sprintf("%05d", as.integer(cw$codigo_tse)))]

contagem <- c(
  "Municípios com prefeito eleito em 2020" = nrow(am),
  "2º mandato (eleitos também em 2016)"    = sum(am$primeiro_mandato == 0),
  "1º mandato"                             = sum(am$primeiro_mandato),
  "  ...concorreram em 2024"               = sum(am$concorreu_2024[am$primeiro_mandato == 1]),
  "  ...reeleitos em 2024"                 = sum(am$reeleito_2024[am$primeiro_mandato == 1]),
  "  ...fora da votação (#NULO)"           = sum(startsWith(am$status_2024, "candidatura")[am$primeiro_mandato == 1]),
  "  ...com votos anulados"                = sum(am$votos_anulados_2024[am$primeiro_mandato == 1]),
  "  ...com eleição suplementar 2021-2024" = sum(am$suplementar_2021_2024[am$primeiro_mandato == 1]),
  "Sem margem de 2020 ou código IBGE"      = sum(is.na(am$margem_2020) | is.na(am$cod_ibge)))
txt <- paste0(names(contagem), ": ", contagem)
writeLines(txt, "saidas/contagem_amostra.txt"); cat(txt, sep = "\n")
rm(c16, c20, c24, ord20, ord24, el, el16, v20, cw); gc()

# 7. Siconfi: RREO Anexo 01 (despesas 2022-2024, receitas 2023-2024)
# uma linha por município; colunas = conta_estágio
le_finbra <- function(arquivo, contas, colunas) {
  d <- le(arquivo)
  d <- d[d$id_conta %in% names(contas) & d$coluna %in% names(colunas), ]
  d$var <- paste(contas[d$id_conta], colunas[d$coluna], sep = "_")
  stopifnot(all(outer(contas, colunas, paste, sep = "_") %in% d$var))   # todas as contas encontradas
  stopifnot(!anyDuplicated(d[, c("cod_ibge", "var")]))
  w <- reshape(d[, c("cod_ibge", "var", "valor")], idvar = "cod_ibge", timevar = "var", direction = "wide")
  names(w) <- sub("^valor\\.", "", names(w))
  w
}
contas_desp  <- c("siconfi-cor_DespesasExcetoIntraOrcamentarias" = "desp_total",
                  "siconfi-cor_Investimentos" = "investimentos")
colunas_desp <- c("DESPESAS EMPENHADAS ATÉ O BIMESTRE (f)" = "emp",
                  "DESPESAS LIQUIDADAS ATÉ O BIMESTRE (h)" = "liq",
                  "DESPESAS PAGAS ATÉ O BIMESTRE (j)"      = "pago")
contas_rec   <- c("siconfi-cor_ReceitasExcetoIntraOrcamentarias" = "rec_total",
                  "siconfi-cor_ReceitaTributaria" = "rec_tributaria",
                  "siconfi-cor_TransferenciasCorrentes" = "transf_corr",
                  "siconfi-cor_TransferenciasDeCapitalDaUniaoEDeSuasEntidades" = "transf_cap_uniao")

siconfi <- list()
for (ano in 2022:2024) {
  w <- le_finbra(sprintf("finbra_rreo_despesas_%d_b4.rds", ano), contas_desp, colunas_desp)
  if (ano > 2022)
    w <- merge(w, le_finbra(sprintf("finbra_rreo_receitas_%d_b4.rds", ano), contas_rec,
                            c("Até o Bimestre (c)" = "realiz")), by = "cod_ibge", all = TRUE)
  w$ano <- ano
  siconfi[[length(siconfi) + 1]] <- w
}
cols <- unique(unlist(lapply(siconfi, names)))   # 2022 não tem receitas: colunas ficam NA
siconfi <- do.call(rbind, lapply(siconfi, function(x) { x[setdiff(cols, names(x))] <- NA; x[cols] }))

# 8. Siconfi: despesa liquidada por função (2023-2024), RREO Anexo 02
funcoes <- c("Urbanismo" = "urbanismo", "Transporte" = "transporte", "Saneamento" = "saneamento",
             "Habitação" = "habitacao", "Desporto e Lazer" = "desporto_e_lazer", "Saúde" = "saude",
             "Educação" = "educacao", "Administração" = "administracao", "Legislativa" = "legislativa",
             "Encargos Especiais" = "encargos_especiais", "Previdência Social" = "previdencia_social",
             "Cultura" = "cultura", "Assistência Social" = "assistencia_social",
             "Segurança Pública" = "seguranca_publica")
fun <- do.call(rbind, lapply(2023:2024, function(ano) {
  d <- le(sprintf("finbra_rreo_funcao_%d_b4.rds", ano))
  d <- d[d$coluna == "DESPESAS LIQUIDADAS ATÉ O BIMESTRE (d)" & d$conta %in% names(funcoes), ]
  stopifnot(all(names(funcoes) %in% d$conta), !anyDuplicated(d[, c("cod_ibge", "conta")]))
  w <- reshape(data.frame(cod_ibge = d$cod_ibge, var = paste0("f_", funcoes[d$conta], "_liq"), valor = d$valor),
               idvar = "cod_ibge", timevar = "var", direction = "wide")
  names(w) <- sub("^valor\\.", "", names(w))
  w[setdiff(paste0("f_", funcoes, "_liq"), names(w))] <- NA
  w$ano <- ano
  w[, c("cod_ibge", "ano", paste0("f_", funcoes, "_liq"))]
}))

# visível: obra ou serviço perceptível; social: saúde e educação; invisível: administração e obrigações
grupos <- list(visivel   = c("urbanismo", "transporte", "saneamento", "habitacao", "desporto_e_lazer"),
               social    = c("saude", "educacao"),
               invisivel = c("administracao", "legislativa", "encargos_especiais", "previdencia_social"))
# visível amplo (robustez): inclui cultura, assistência social e segurança
grupos$visivel_amplo <- c(grupos$visivel, "cultura", "assistencia_social", "seguranca_publica")
for (g in names(grupos)) fun[[g]] <- rowSums(fun[, paste0("f_", grupos[[g]], "_liq")], na.rm = TRUE)

# 9. IBGE e alinhamento
sidra <- function(arquivo) { d <- le(arquivo); setNames(suppressWarnings(as.numeric(d$V)), d$D1C) }
am$pop_2024           <- sidra("ibge_populacao_2024.rds")[am$cod_ibge]
am$pib_pc_2023        <- sidra("ibge_pib_2023.rds")[am$cod_ibge] * 1000 / am$pop_2024   # PIB em mil reais
am$alfabetizacao_2022 <- sidra("ibge_alfabetizacao_2022.rds")[am$cod_ibge]
am$log_pop_2024    <- log(am$pop_2024)
am$log_pib_pc_2023 <- log(am$pib_pc_2023)

c22 <- le("consulta_cand_2022.rds")
gov <- unique(c22[c22$CD_CARGO == "3" & c22$DS_SIT_TOT_TURNO == "ELEITO", c("SG_UF", "SG_PARTIDO")])
stopifnot(!anyDuplicated(gov$SG_UF))
rm(c22); gc()
# DEM e PSL se fundiram no União Brasil em 2022
partido_eq <- ifelse(am$partido_2020 %in% c("DEM", "PSL"), "UNIÃO", am$partido_2020)
am$alinhado_governador <- as.integer(partido_eq == gov$SG_PARTIDO[match(am$uf, gov$SG_UF)])
am$alinhado_presidente <- as.integer(am$partido_2020 == "PT")   # Lula, eleito em 2022

# 10. Junção: 1º mandato + Siconfi
base <- am[am$primeiro_mandato == 1, ]
n1 <- nrow(base)
pega <- function(tab, ano, var) tab[[var]][tab$ano == ano][match(base$cod_ibge, tab$cod_ibge[tab$ano == ano])]

for (ano in 2022:2024) {
  inv <- pega(siconfi, ano, "investimentos_liq")
  inv[is.na(inv) & !is.na(pega(siconfi, ano, "desp_total_liq"))] <- 0   # publicou o RREO sem linha = zero
  base[[paste0("investimentos_liq_", ano)]] <- inv
}
base <- base[!is.na(base$investimentos_liq_2024) & !is.na(base$investimentos_liq_2023), ]   # sem RREO: sai
n2 <- nrow(base)

# 11. Per capita (população 2024), winsorização 1%/99% e centenas de reais
for (ano in 2022:2024) base[[paste0("inv_pc_", ano)]] <- base[[paste0("investimentos_liq_", ano)]] / base$pop_2024
fontes <- list(rec_pc_2024 = c(2024, "rec_total_realiz"),
               rec_trib_pc_2024 = c(2024, "rec_tributaria_realiz"), rec_trib_pc_2023 = c(2023, "rec_tributaria_realiz"),
               transf_corr_pc_2024 = c(2024, "transf_corr_realiz"), transf_corr_pc_2023 = c(2023, "transf_corr_realiz"),
               transf_cap_uniao_pc_2024 = c(2024, "transf_cap_uniao_realiz"))
for (v in names(fontes)) base[[v]] <- pega(siconfi, fontes[[v]][1], fontes[[v]][2]) / base$pop_2024
for (g in names(grupos)) for (ano in 2023:2024)
  base[[paste0(g, "_pc_", ano)]] <- pega(fun, ano, g) / base$pop_2024

winsor <- function(x) { q <- quantile(x, c(0.01, 0.99), na.rm = TRUE); pmin(pmax(x, q[1]), q[2]) }
for (v in c(paste0("inv_pc_", 2022:2024), names(fontes), paste0(rep(names(grupos), each = 2), "_pc_", 2023:2024)))
  base[[paste0(v, "_w")]] <- winsor(base[[v]])

for (ano in 2022:2024) base[[paste0("inv100_", ano)]] <- base[[paste0("inv_pc_", ano, "_w")]] / 100
for (g in names(grupos)) for (ano in 2023:2024)
  base[[paste0(g, "100_", ano)]] <- base[[paste0(g, "_pc_", ano, "_w")]] / 100

# investimento empenhado e pago (robustez), com a mesma regra do zero
for (estagio in c("emp", "pago")) for (ano in 2023:2024) {
  inv <- pega(siconfi, ano, paste0("investimentos_", estagio))
  inv[is.na(inv) & !is.na(pega(siconfi, ano, "desp_total_liq"))] <- 0
  base[[paste0("inv100_", estagio, "_", ano)]] <- winsor(inv / base$pop_2024) / 100
}

# 12. Variáveis finais, checagens e salvamento
base$eleicao_apertada_2020 <- as.integer(base$margem_2020 < 0.05)   # margem < 5 p.p. (robustez)
base$mulher          <- as.integer(base$genero == "FEMININO")
base$superior        <- as.integer(base$instrucao == "SUPERIOR COMPLETO")
base$delta_visivel   <- base$visivel_pc_2024_w - base$visivel_pc_2023_w
base$inelegivel_2024 <- base$votos_anulados_2024
# fora da análise principal: votos anulados em 2024 ou prefeito que deixou o cargo (suplementar 2021-2024)
base$amostra_principal <- as.integer(base$inelegivel_2024 == 0 & base$suplementar_2021_2024 == 0)

stopifnot(!anyDuplicated(base$cod_ibge))
vars_modelo <- c("reeleito_2024", "inv100_2024", "inv100_2023", "margem_2020", "alinhado_governador",
                 "alinhado_presidente", "mulher", "superior", "log_pop_2024", "log_pib_pc_2023",
                 "alfabetizacao_2022", "rec_trib_pc_2023_w", "transf_corr_pc_2023_w", "uf")
cat("\nValores ausentes nas variáveis do modelo:\n"); print(colSums(is.na(base[, vars_modelo])))

base <- base[order(base$cod_ibge), ]
saveRDS(base, "dados/base_final.rds")
write.csv(base, "dados/base_final.csv", row.names = FALSE, fileEncoding = "UTF-8")

cat("1º mandato:", n1, "\n",
    "  - sem RREO de 2023 ou 2024 (excluídos):", n1 - n2, "\n",
    "Base final:", n2, "\n",
    "  - com votos anulados em 2024:", sum(base$inelegivel_2024), "\n",
    "  - com eleição suplementar 2021-2024:", sum(base$suplementar_2021_2024), "\n",
    "Amostra da análise principal:", sum(base$amostra_principal), "\n", file = "saidas/contagem_base_final.txt")
cat(readLines("saidas/contagem_base_final.txt"), sep = "\n")
