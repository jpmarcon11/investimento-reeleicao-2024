# 08_robustez.R
# Robustez: tabelas 7 a 10 e figura 3

library(AER)
library(stargazer)

# salva a tabela em .txt e .tex
tabela <- function(..., arquivo) {
  stargazer(..., type = "text", out = paste0(arquivo, ".txt"))
  invisible(capture.output(stargazer(..., type = "latex", header = FALSE, out = paste0(arquivo, ".tex"))))
}
# salva a figura em .png e .pdf
salva_figura <- function(arquivo, desenho, largura = 16, altura = 10) {
  png(paste0(arquivo, ".png"), width = largura, height = altura, units = "cm", res = 300); desenho(); dev.off()
  pdf(paste0(arquivo, ".pdf"), width = largura / 2.54, height = altura / 2.54); desenho(); dev.off()
}

dir.create("saidas", showWarnings = FALSE)
b   <- readRDS("dados/base_final.rds")

# mesma preparação do 07_estimacao.R
b$rec100_2023    <- b$rec_trib_pc_2023_w / 100
b$transf100_2023 <- b$transf_corr_pc_2023_w / 100
b$rec100_2024    <- b$rec_trib_pc_2024_w / 100
b$transf100_2024 <- b$transf_corr_pc_2024_w / 100
# transferências de capital da União (sem linha no RREO = 0)
b$transf_cap_uniao_pc_2024_w[is.na(b$transf_cap_uniao_pc_2024_w)] <- 0
b$transfcap100_2024 <- b$transf_cap_uniao_pc_2024_w / 100
b$uf <- factor(b$uf)

# X sem winsorização
b$inv100_bruto_2024 <- b$inv_pc_2024 / 100
b$inv100_bruto_2023 <- b$inv_pc_2023 / 100

# votos anulados e suplementar 2021-2024: só na tabela 9
b_todos <- b
b <- b[b$amostra_principal == 1, ]

# modelo principal (coluna 5 da tabela 3)
m5 <- lm(reeleito_2024 ~ inv100_2024 + inv100_2023 + margem_2020 + alinhado_governador +
           alinhado_presidente + mulher + superior + log_pop_2024 + log_pib_pc_2023 + alfabetizacao_2022 +
           rec100_2023 + transf100_2023 + uf, data = b)


# Tabela 7: medida do X e amostra
r_emp  <- update(m5, . ~ . - inv100_2024 - inv100_2023 + inv100_emp_2024 + inv100_emp_2023)
r_pago <- update(m5, . ~ . - inv100_2024 - inv100_2023 + inv100_pago_2024 + inv100_pago_2023)
r_brut <- update(m5, . ~ . - inv100_2024 - inv100_2023 + inv100_bruto_2024 + inv100_bruto_2023)
# base: média de 2022 e 2023
b$inv100_base_2223 <- (b$inv100_2022 + b$inv100_2023) / 2
r_media <- update(m5, . ~ . - inv100_2023 + inv100_base_2223)
r_rec24 <- update(m5, . ~ . - rec100_2023 - transf100_2023 + rec100_2024 + transf100_2024)
r_tcap <- update(m5, . ~ . + transfcap100_2024)
r_supl <- update(m5, data = b[b$suplementar_2024 == 0, ])
r_conc <- update(m5, data = b[b$concorreu_2024 == 1, ])
r_yconc <- update(m5, concorreu_2024 ~ .)
r_peq  <- update(m5, data = b[b$pop_2024 <= 10000, ])
r_gra  <- update(m5, data = b[b$pop_2024 >  10000, ])
r_apert <- update(m5, data = b[b$margem_2020 <  0.05, ])
r_folg  <- update(m5, data = b[b$margem_2020 >= 0.05, ])
r_inel  <- update(m5, data = b_todos[b_todos$suplementar_2021_2024 == 0, ])   # com votos anulados (Y = 0)
r_cass  <- update(m5, data = b_todos[b_todos$inelegivel_2024 == 0, ])        # com suplementar 2021-2024
r_dummy <- update(m5, . ~ . - margem_2020 + eleicao_apertada_2020)
m5_22   <- update(m5, data = b[!is.na(b$inv100_2022), ])   # amostra com RREO de 2022

# cada exercício muda uma coisa só: modelo = mesmo N; amostra = N + casos que voltaram
n0 <- nobs(m5)
volta <- function(d) nrow(model.frame(formula(m5), data = d))
stopifnot(sapply(list(r_emp, r_pago, r_brut, r_rec24, r_tcap, r_dummy), nobs) == n0,
          nobs(r_inel) == n0 + volta(b_todos[b_todos$inelegivel_2024 == 1 & b_todos$suplementar_2021_2024 == 0, ]),
          nobs(r_cass) == n0 + volta(b_todos[b_todos$suplementar_2021_2024 == 1 & b_todos$inelegivel_2024 == 0, ]),
          nobs(r_media) == nobs(m5_22))

# Tabela 10 e figura 3: resumo da robustez (um exercício por linha)
resumo <- function(m, var = "inv100_2024", V = vcovHC(m, type = "HC1")) {
  est <- coef(m)[[var]]; ep <- sqrt(V[var, var])
  c(coef = est, ep = ep, ic95_inf = est - 1.96 * ep, ic95_sup = est + 1.96 * ep, n = nobs(m))
}
res <- as.data.frame(rbind(
  "Principal"                    = resumo(m5),
  "Cluster por UF"               = resumo(m5, V = vcovCL(m5, cluster = ~uf, type = "HC1")),
  "Empenhado"                    = resumo(r_emp, "inv100_emp_2024"),
  "Pago"                         = resumo(r_pago, "inv100_pago_2024"),
  "Sem winsorização"             = resumo(r_brut, "inv100_bruto_2024"),
  "Base: média 2022-2023"        = resumo(r_media),
  "Receitas de 2024"             = resumo(r_rec24),
  "Com transf. de capital"       = resumo(r_tcap),
  "Margem como dummy (< 5 p.p.)" = resumo(r_dummy),
  "Sem suplementar de 2025-2026" = resumo(r_supl),
  "Com votos anulados"           = resumo(r_inel),
  "Com suplementar 2021-2024"    = resumo(r_cass)))
write.csv(round(res, 4), "saidas/tabela10_resumo_robustez.csv", fileEncoding = "UTF-8")

# empenhado x liquidado: média e efeito de +1 desvio-padrão (p.p.)
emp_liq <- data.frame(
  medida = c("Liquidado", "Empenhado"),
  media_pc = c(mean(b$inv100_2024), mean(b$inv100_emp_2024)) * 100,
  dp_pc = c(sd(b$inv100_2024), sd(b$inv100_emp_2024)) * 100,
  efeito_1dp_pp = 100 * c(coef(m5)[["inv100_2024"]] * sd(b$inv100_2024),
                          coef(r_emp)[["inv100_emp_2024"]] * sd(b$inv100_emp_2024)))
print(emp_liq)
emp_liq[-1] <- round(emp_liq[-1], 2)
write.csv(emp_liq, "saidas/empenhado_liquidado.csv", row.names = FALSE, fileEncoding = "UTF-8")
tab10 <- data.frame(Coeficiente = sprintf("%.4f", res$coef), EP = sprintf("%.4f", res$ep),
                    IC95 = sprintf("[%.4f; %.4f]", res$ic95_inf, res$ic95_sup), N = format(res$n, big.mark = "."),
                    row.names = rownames(res))
tabela(tab10, summary = FALSE, arquivo = "saidas/tabela10_resumo_robustez")

salva_figura("saidas/figura3_robustez", function() {
  par(mar = c(4.5, 12, 1, 1))
  y <- rev(seq_len(nrow(res)))
  plot(100 * res$coef, y, xlim = 100 * range(0, res$ic95_inf, res$ic95_sup), yaxt = "n", pch = 19,
       xlab = "Efeito de +R$ 100 pc na prob. de reeleição (p.p.)", ylab = "")
  segments(100 * res$ic95_inf, y, 100 * res$ic95_sup, y)
  axis(2, at = y, labels = rownames(res), las = 1, cex.axis = 0.75)
  abline(v = 0, lty = 2, col = "grey50")
  abline(v = 100 * res$coef[1], lty = 3)
}, altura = 12)

renomeia <- function(m, de) { names(m$coefficients)[names(m$coefficients) == de] <- "inv100_2024"; m }
r_emp  <- renomeia(r_emp,  "inv100_emp_2024")
r_pago <- renomeia(r_pago, "inv100_pago_2024")
r_brut <- renomeia(r_brut, "inv100_bruto_2024")

mods7 <- list(m5, r_emp, r_pago, r_brut, r_supl, r_media, r_rec24, r_tcap, m5)
rob7 <- lapply(mods7, function(m) {
  se <- sqrt(diag(vcovHC(m, type = "HC1"))); names(se) <- names(coef(m)); se })
# cluster por UF
rob7[[9]] <- sqrt(diag(vcovCL(m5, cluster = ~uf, type = "HC1")))
tabela(mods7, se = rob7, digits = 3, keep = "^inv100_2024$",
       covariate.labels = "Investimento 2024 (100 reais pc)",
       column.labels = c("Principal", "Empenhado", "Pago", "Sem winsor.", "Sem supl. 2025-26", "Base 22-23", "Receita 2024", "Com transf. cap.", "Cluster UF"),
       dep.var.labels = "Reeleito em 2024", omit.stat = c("ser", "f", "adj.rsq"),
       add.lines = list(c("Base de comparação", "2023", "2023", "2023", "2023", "2023", "Média 22-23", "2023", "2023", "2023"),
                        c("Controles e EF de UF", rep("Sim", 9))),
       arquivo = "saidas/tabela7_robustez")

# Tabela 8: placebo (investimento de 2022)
# passa se 2022 não prever a reeleição e se o efeito de 2024 for maior
p1 <- update(m5, . ~ . - inv100_2024 - inv100_2023 + inv100_2022)
p2 <- update(m5, . ~ . - inv100_2024 + inv100_2022)
p3 <- update(m5, . ~ . + inv100_2022)
stopifnot(sapply(list(p1, p2, p3), nobs) == nobs(m5_22))
lh_placebo <- linearHypothesis(p3, "inv100_2024 = inv100_2022", vcov. = vcovHC(p3, type = "HC1"))
print(lh_placebo)
rob8 <- lapply(list(p1, p2, p3, m5_22), function(m) sqrt(diag(vcovHC(m, type = "HC1"))))
tabela(p1, p2, p3, m5_22, se = rob8, digits = 3,
       keep = c("inv100_2024", "inv100_2023", "inv100_2022"),
       order = c("inv100_2024", "inv100_2023", "inv100_2022"),
       column.labels = c("Só 2022", "2022 e 2023", "2022 a 2024", "Principal"),
       dep.var.labels = "Reeleito em 2024", omit.stat = c("ser", "f"),
       add.lines = list(c("Controles e EF de UF", rep("Sim", 4)),
                        c("Teste 2024 = 2022 (p-valor)", "", "", sprintf("%.3f", lh_placebo[2, "Pr(>F)"]), "")),
       arquivo = "saidas/tabela8_placebo_2022")

# H2 com o grupo visível amplo
h2b <- update(m5, . ~ . - inv100_2024 - inv100_2023 + visivel100_2024 + social100_2024 +
                invisivel100_2024 + visivel100_2023 + social100_2023 + invisivel100_2023)
h2_amplo <- update(h2b, . ~ . - visivel100_2024 - visivel100_2023 +
                     visivel_amplo100_2024 + visivel_amplo100_2023)
coeftest(h2_amplo, vcov. = vcovHC, type = "HC1")[c("visivel_amplo100_2024", "visivel_amplo100_2023",
                                                   "social100_2024", "invisivel100_2024"), ]
linearHypothesis(h2_amplo, "visivel_amplo100_2024 = invisivel100_2024", vcov. = vcovHC(h2_amplo, type = "HC1"))

# Tabela 9: seleção e heterogeneidade
# teste da diferença por porte: interação na amostra completa (corte perto da mediana, 11 mil hab.)
b$acima_10mil <- as.integer(b$pop_2024 > 10000)
m_porte <- update(m5, . ~ . + acima_10mil + inv100_2024:acima_10mil)
ct_porte <- coeftest(m_porte, vcov. = vcovHC(m_porte, type = "HC1"))
print(ct_porte[c("inv100_2024", "inv100_2024:acima_10mil"), ])
write.csv(round(ct_porte[c("inv100_2024", "inv100_2024:acima_10mil"), ], 4),
          "saidas/heterogeneidade_porte.csv", fileEncoding = "UTF-8")
mods9 <- list(m5, r_conc, r_yconc, r_peq, r_gra, r_apert, r_folg, r_inel, r_cass)
rob9 <- lapply(mods9, function(m) sqrt(diag(vcovHC(m, type = "HC1"))))
tabela(mods9, se = rob9, digits = 3, keep = "^inv100_2024$",
       covariate.labels = "Investimento 2024 (100 reais pc)",
       column.labels = c("Principal", "Só concorreu", "Y=concorreu", "Até 10 mil", "Acima 10 mil",
                         "Apertada 2020", "Folgada 2020", "Com barrados", "Com supl. 21-24"),
       dep.var.labels.include = FALSE, omit.stat = c("ser", "f", "adj.rsq"),
       add.lines = list(c("Variável dependente", "Reeleito", "Reeleito", "Concorreu", "Reeleito",
                          "Reeleito", "Reeleito", "Reeleito", "Reeleito", "Reeleito"),
                        c("Controles, 2023 e EF de UF", rep("Sim", 9))),
       arquivo = "saidas/tabela9_selecao_heterogeneidade")
