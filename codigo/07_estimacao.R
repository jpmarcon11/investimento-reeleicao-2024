# 07_estimacao.R
# Resultados: tabelas 3 a 6, figura 2 e magnitudes

library(AER)
library(stargazer)
library(marginaleffects)

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
b <- readRDS("dados/base_final.rds")

b <- b[b$amostra_principal == 1, ]

# receitas de 2023 (antes do ano eleitoral)
b$rec100_2023    <- b$rec_trib_pc_2023_w / 100
b$transf100_2023 <- b$transf_corr_pc_2023_w / 100
b$uf <- factor(b$uf)

# Tabela 3: MPL com controles em blocos
m1 <- lm(reeleito_2024 ~ inv100_2024, data = b)
m2 <- lm(reeleito_2024 ~ inv100_2024 + inv100_2023, data = b)
# controles
x_inv    <- "inv100_2024 + inv100_2023"
ctrl_pol <- "margem_2020 + alinhado_governador + alinhado_presidente + mulher + superior"
ctrl_mun <- "log_pop_2024 + log_pib_pc_2023 + alfabetizacao_2022"
ctrl_rec <- "rec100_2023 + transf100_2023"
f3 <- as.formula(paste("reeleito_2024 ~", x_inv, "+", ctrl_pol, "+", ctrl_mun))
f4 <- as.formula(paste("reeleito_2024 ~", x_inv, "+", ctrl_pol, "+", ctrl_mun, "+", ctrl_rec))
f5 <- as.formula(paste("reeleito_2024 ~", x_inv, "+", ctrl_pol, "+", ctrl_mun, "+", ctrl_rec, "+ uf"))
m3 <- lm(f3, data = b)
m4 <- lm(f4, data = b)
m5 <- lm(f5, data = b)

ct5 <- coeftest(m5, vcov. = vcovHC, type = "HC1")
ct5[!grepl("^uf|Intercept", rownames(ct5)), ]

# heterocedasticidade
bp5 <- bptest(m5); print(bp5)

# multicolinearidade
cat("Correlação inv2024 x inv2023:", round(cor(b$inv100_2024, b$inv100_2023), 2), "\n")
vif5 <- vif(m5)
print(round(vif5[c("inv100_2024", "inv100_2023"), ], 2))

# testes F: efeitos fixos de UF, controles políticos e receitas
lh_uf <- linearHypothesis(m5, grep("^uf", names(coef(m5)), value = TRUE), vcov. = vcovHC(m5, type = "HC1"))
lh_pol <- linearHypothesis(m5, c("margem_2020 = 0", "alinhado_governador = 0", "alinhado_presidente = 0"),
                           vcov. = vcovHC(m5, type = "HC1"))
lh_rec <- linearHypothesis(m5, c("rec100_2023 = 0", "transf100_2023 = 0"), vcov. = vcovHC(m5, type = "HC1"))

# nível x aceleração: b2 = -b1
lh_nivel <- linearHypothesis(m5, "inv100_2024 + inv100_2023 = 0", vcov. = vcovHC(m5, type = "HC1"))
lh_igual <- linearHypothesis(m5, "inv100_2024 = inv100_2023", vcov. = vcovHC(m5, type = "HC1"))
m_dif <- update(m5, . ~ . - inv100_2024 - inv100_2023 + I(inv100_2024 - inv100_2023))
coeftest(m_dif, vcov. = vcovHC, type = "HC1")["I(inv100_2024 - inv100_2023)", ]

# H3: interação com a margem de 2020
f6 <- as.formula(paste("reeleito_2024 ~ inv100_2024 * margem_2020 + inv100_2023 +",
                       "alinhado_governador + alinhado_presidente + mulher + superior +", ctrl_mun, "+", ctrl_rec, "+ uf"))
m6 <- lm(f6, data = b)
coeftest(m6, vcov. = vcovHC, type = "HC1")[c("inv100_2024", "margem_2020", "inv100_2024:margem_2020"), ]

# efeito do investimento nos percentis 25, 50 e 75 da margem
g <- c("inv100_2024", "inv100_2024:margem_2020")
V6 <- vcovHC(m6, type = "HC1")[g, g]
ef_h3 <- t(sapply(quantile(b$margem_2020, c(0.25, 0.5, 0.75)), function(mg) {
  w <- c(1, mg); est <- sum(w * coef(m6)[g]); ep <- sqrt(drop(t(w) %*% V6 %*% w))
  c(margem = mg, efeito = est, ep = ep, ic95_inf = est - 1.96 * ep, ic95_sup = est + 1.96 * ep)
}))
rownames(ef_h3) <- c("p25", "p50", "p75")
cat("\nH3: efeito de +R$ 100 pc conforme a margem de 2020:\n"); print(round(ef_h3, 4))
write.csv(round(ef_h3, 4), "saidas/h3_efeito_por_margem.csv", fileEncoding = "UTF-8")

rob_se <- lapply(list(m1, m2, m3, m4, m5, m6), function(m) sqrt(diag(vcovHC(m, type = "HC1"))))
tabela(m1, m2, m3, m4, m5, m6, se = rob_se, digits = 3,
       omit = "^uf", add.lines = list(c("Efeitos fixos de UF", "Não", "Não", "Não", "Não", "Sim", "Sim")),
       omit.stat = c("ser", "f"), dep.var.labels = "Reeleito em 2024",
       arquivo = "saidas/tabela3_mpl")

# previsões do MPL fora de [0, 1]
p5 <- fitted(m5)
cat("\nMPL (5): previsões < 0:", sum(p5 < 0), " | > 1:", sum(p5 > 1), "de", length(p5), "\n")

# Tabela 4: MPL x Probit x Logit
# RR: todos reeleitos (previsão perfeita)
b_bin <- droplevels(b[b$uf != "RR", ])
probit5 <- glm(f5, family = binomial(link = "probit"), data = b_bin)
logit5  <- glm(f5, family = binomial(link = "logit"),  data = b_bin)
m5_semRR <- update(m5, data = b_bin)   # mesma amostra do Probit e do Logit

# observações de cada modelo
cat("\nObservações por modelo:\n")
print(sapply(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6, m5_semRR = m5_semRR,
                  probit = probit5, logit = logit5), nobs))


# efeito marginal médio de +R$ 100 per capita, com erro-padrão HC1
ame <- function(m) {
  if (inherits(m, "glm")) {
    s <- avg_slopes(m, variables = "inv100_2024", vcov = "HC1")
    c(efeito = s$estimate, ep = s$std.error)
  } else c(efeito = coef(m)[["inv100_2024"]], ep = sqrt(vcovHC(m, type = "HC1")["inv100_2024", "inv100_2024"]))
}
ef <- sapply(list(MPL = m5, MPL_sem_RR = m5_semRR, Probit = probit5, Logit = logit5), ame)
print(round(ef, 4))

# pseudo-R2 de McFadden
pseudoR2 <- function(m) 1 - as.numeric(logLik(m)) / as.numeric(logLik(update(m, . ~ 1)))
cat("Pseudo-R2: probit", round(pseudoR2(probit5), 3), "| logit", round(pseudoR2(logit5), 3), "\n")

# prefeito típico: investimento no 1º e no 3º quartil
tipico <- data.frame(inv100_2023 = median(b$inv100_2023, na.rm = TRUE), margem_2020 = median(b$margem_2020, na.rm = TRUE),
                     alinhado_governador = 0, alinhado_presidente = 0, mulher = 0, superior = 1,
                     log_pop_2024 = median(b$log_pop_2024, na.rm = TRUE), log_pib_pc_2023 = median(b$log_pib_pc_2023, na.rm = TRUE),
                     alfabetizacao_2022 = median(b$alfabetizacao_2022, na.rm = TRUE),
                     rec100_2023 = median(b$rec100_2023, na.rm = TRUE), transf100_2023 = median(b$transf100_2023, na.rm = TRUE),
                     uf = factor(names(which.max(table(b$uf))), levels = levels(b$uf)))
tipico <- tipico[c(1, 1), ]; tipico$inv100_2024 <- quantile(b$inv100_2024, c(0.25, 0.75))
prev <- sapply(list(MPL = m5, Probit = probit5, Logit = logit5),
               function(m) predict(m, newdata = tipico, type = "response"))
rownames(prev) <- c("inv no 1º quartil", "inv no 3º quartil")
cat("\nProbabilidade prevista de reeleição, prefeito típico:\n"); print(round(prev, 3))
cat("Diferença (Q3 - Q1):\n"); print(round(prev[2, ] - prev[1, ], 3))

rob_se4 <- lapply(list(m5, m5_semRR, probit5, logit5), function(m) sqrt(diag(vcovHC(m, type = "HC1"))))
tabela(m5, m5_semRR, probit5, logit5, se = rob_se4, digits = 3, omit = "^uf",
       column.labels = c("MPL", "MPL", "Probit", "Logit"), omit.stat = c("ser", "f"),
       add.lines = list(c("Efeitos fixos de UF", "Sim", "Sim", "Sim", "Sim"),
                        c("Amostra", "Completa", "Sem RR", "Sem RR", "Sem RR"),
                        c("Efeito marginal médio", sprintf("%.3f", ef["efeito", ])),
                        c("", sprintf("(%.3f)", ef["ep", ])),
                        c("Pseudo-R2 (McFadden)", "", "", sprintf("%.3f", pseudoR2(probit5)),
                          sprintf("%.3f", pseudoR2(logit5)))),
       arquivo = "saidas/tabela4_mpl_probit_logit")


# H2: tipo de gasto
h2a <- update(m5, . ~ . - inv100_2024 - inv100_2023 +
                visivel100_2024 + social100_2024 + invisivel100_2024)
h2b <- update(h2a, . ~ . + visivel100_2023 + social100_2023 + invisivel100_2023)
ct_h2 <- coeftest(h2b, vcov. = vcovHC, type = "HC1")
ct_h2[grep("^(visivel|social|invisivel)100", rownames(ct_h2)), ]

# visível = invisível?
lh_vis_inv <- linearHypothesis(h2b, "visivel100_2024 = invisivel100_2024", vcov. = vcovHC(h2b, type = "HC1"))
lh_vis_soc <- linearHypothesis(h2b, "visivel100_2024 = social100_2024", vcov. = vcovHC(h2b, type = "HC1"))
# visível: b2024 + b2023 = 0?
lh_vis_acel <- linearHypothesis(h2b, "visivel100_2024 + visivel100_2023 = 0", vcov. = vcovHC(h2b, type = "HC1"))
print(list(lh_uf, lh_pol, lh_rec, lh_nivel, lh_vis_inv, lh_vis_acel))

# tabela de diagnósticos
f_lh <- function(lh) c(lh$F[2], lh[2, "Pr(>F)"])
diag_tab <- data.frame(
  Teste = c("Breusch-Pagan", "VIF investimento 2024", "VIF investimento 2023", "F: efeitos fixos de UF",
            "F: controles políticos", "F: receitas", "Nível x aceleração (b2024 + b2023 = 0)",
            "b2024 = b2023", "H2: visível = invisível", "H2: visível = social", "H2: visível 2024 + 2023 = 0"),
  Estatistica = c(bp5$statistic, vif5[c("inv100_2024", "inv100_2023"), "GVIF"], f_lh(lh_uf)[1], f_lh(lh_pol)[1],
                  f_lh(lh_rec)[1], f_lh(lh_nivel)[1], f_lh(lh_igual)[1], f_lh(lh_vis_inv)[1], f_lh(lh_vis_soc)[1],
                  f_lh(lh_vis_acel)[1]),
  p_valor = c(bp5$p.value, NA, NA, f_lh(lh_uf)[2], f_lh(lh_pol)[2], f_lh(lh_rec)[2], f_lh(lh_nivel)[2],
              f_lh(lh_igual)[2], f_lh(lh_vis_inv)[2], f_lh(lh_vis_soc)[2], f_lh(lh_vis_acel)[2]))
write.csv(diag_tab, "saidas/tabela_diagnosticos.csv", row.names = FALSE, fileEncoding = "UTF-8")
diag_tex <- data.frame(Teste = diag_tab$Teste, "Estatística" = sprintf("%.2f", diag_tab$Estatistica),
                       "p-valor" = ifelse(is.na(diag_tab$p_valor), "", sprintf("%.3f", diag_tab$p_valor)),
                       check.names = FALSE)
tabela(diag_tex, summary = FALSE, rownames = FALSE, arquivo = "saidas/tabela_diagnosticos")

# Faixas de variação do gasto visível (referência: -R$ 50 a +R$ 50)
b$faixa_delta <- cut(b$delta_visivel, c(-Inf, -50, 50, 150, 300, 500, Inf),
                     labels = c("Caiu mais de 50", "Estável", "+50 a 150", "+150 a 300",
                                "+300 a 500", "+500 ou mais"))
b$faixa_delta <- relevel(b$faixa_delta, ref = "Estável")
nl_delta <- update(h2b, . ~ . - visivel100_2024 + faixa_delta)
cat("\nMunicípios e aumento médio (R$ pc) por faixa de variação do gasto visível:\n")
print(rbind(n = table(b$faixa_delta), aumento_medio = round(tapply(b$delta_visivel, b$faixa_delta, mean))))

rob_se3 <- lapply(list(m5, h2a, h2b, nl_delta), function(m) sqrt(diag(vcovHC(m, type = "HC1"))))
tabela(m5, h2a, h2b, nl_delta, se = rob_se3, digits = 3, omit = "^uf",
       column.labels = c("Investimento", "Por função", "Por função + 2023", "Faixas visível"),
       order = c("^inv100", "^visivel", "^faixa", "^social", "^invisivel"),
       omit.stat = c("ser", "f"), dep.var.labels = "Reeleito em 2024",
       add.lines = list(c("Efeitos fixos de UF", "Sim", "Sim", "Sim", "Sim")),
       notes = "Faixas: referência = gasto visível estável (de -50 a +50 reais per capita).",
       arquivo = "saidas/tabela5_h2_tipo_de_gasto")

# figura 2
ct_delta <- coeftest(nl_delta, vcov. = vcovHC, type = "HC1")
lin <- grep("^faixa_delta", rownames(ct_delta))
fig <- data.frame(faixa = c("Estável", sub("faixa_delta", "", rownames(ct_delta)[lin])),
                  coef = c(0, ct_delta[lin, 1]), ep = c(0, ct_delta[lin, 2]))
fig <- fig[match(c("Caiu mais de 50", "Estável", "+50 a 150", "+150 a 300", "+300 a 500", "+500 ou mais"),
                 fig$faixa), ]
salva_figura("saidas/figura2_reeleicao_por_aumento_visivel", function() {
  par(mar = c(5, 5, 1, 1))
  x <- seq_len(nrow(fig))
  plot(x, 100 * fig$coef, ylim = range(100 * c(fig$coef - 1.96 * fig$ep, fig$coef + 1.96 * fig$ep)),
       xaxt = "n", pch = 19, xlab = "Variação do gasto visível per capita, 2023 -> 2024 (R$)",
       ylab = "Diferença na prob. de reeleição (p.p.)\nvs. gasto estável")
  tem_ic <- fig$ep > 0
  arrows(x[tem_ic], 100 * (fig$coef - 1.96 * fig$ep)[tem_ic], x[tem_ic],
         100 * (fig$coef + 1.96 * fig$ep)[tem_ic], angle = 90, code = 3, length = 0.05)
  abline(h = 0, lty = 2, col = "grey50")
  axis(1, at = x, labels = fig$faixa, cex.axis = 0.8)
})

# Tabela 6: forma funcional
nl_quad <- update(m5, . ~ . + I(inv100_2024^2))
b$log_inv_2024 <- log(b$inv_pc_2024_w)
b$log_inv_2023 <- log(b$inv_pc_2023_w)
nl_log <- update(m5, . ~ . - inv100_2024 - inv100_2023 + log_inv_2024 + log_inv_2023)
b$quartil_inv_2024 <- cut(b$inv_pc_2024_w, unique(quantile(b$inv_pc_2024_w, 0:4 / 4)), include.lowest = TRUE,
                          labels = c("Q1", "Q2", "Q3", "Q4"))
nl_quart <- update(m5, . ~ . - inv100_2024 + quartil_inv_2024)

bq <- coef(nl_quad)
cat("\nQuadrático - efeito de +R$ 100 avaliado em diferentes níveis de investimento (p.p.):\n")
print(round(sapply(c(R100 = 1, R300 = 3, R600 = 6, R1000 = 10, R1500 = 15),
                   function(x) 100 * (bq["inv100_2024"] + 2 * bq["I(inv100_2024^2)"] * x)), 1))
cat("Faixas dos quartis (R$ per capita):", round(quantile(b$inv_pc_2024_w, 0:4 / 4)), "\n")

rob_se6 <- lapply(list(m5, nl_quad, nl_log, nl_quart), function(m) sqrt(diag(vcovHC(m, type = "HC1"))))
tabela(m5, nl_quad, nl_log, nl_quart, se = rob_se6, digits = 3,
       keep = c("inv100_2024", "log_inv", "quartil"),
       column.labels = c("Linear", "Quadrático", "Log", "Quartis"),
       omit.stat = c("ser", "f"), dep.var.labels = "Reeleito em 2024",
       add.lines = list(c("Controles e EF de UF", rep("Sim", 4))),
       arquivo = "saidas/tabela6_nao_linearidades")

# Magnitudes
cenarios <- function(m, var, x_reais) {
  co <- coef(m)[[var]]; ep <- sqrt(vcovHC(m, type = "HC1")[var, var])
  dp <- sd(x_reais)
  passos <- c("+R$ 100" = 1, "+R$ 200" = 2, "+R$ 500" = 5, "+1 desvio-padrão" = dp / 100)
  data.frame(cenario = names(passos), reais_pc = round(passos * 100),
             efeito_pp = round(100 * co * passos, 1),
             ic95_inf = round(100 * (co - 1.96 * ep) * passos, 1),
             ic95_sup = round(100 * (co + 1.96 * ep) * passos, 1), row.names = NULL)
}
sink("saidas/magnitudes.txt", split = TRUE)
tryCatch({
  cat("Média de reeleição na amostra:", round(100 * mean(b$reeleito_2024), 1), "%\n")

  cat("\n(a) Investimento liquidado jan-ago 2024 (Tabela 3, coluna 5), investimento de 2023 constante\n")
  print(cenarios(m5, "inv100_2024", b$inv_pc_2024_w))

  cat("\n(b) Gasto visível jan-ago 2024 (Tabela 5, coluna 3), gasto visível de 2023 constante\n")
  print(cenarios(h2b, "visivel100_2024", b$visivel_pc_2024_w))
  cat("Gasto visível médio per capita: 2023 =", round(mean(b$visivel_pc_2023_w)),
      "| 2024 =", round(mean(b$visivel_pc_2024_w)), "\n")
  cat("Variação 2023 -> 2024 (R$ pc), quantis 10/25/50/75/90:",
      round(quantile(b$delta_visivel, c(.1, .25, .5, .75, .9))), "\n")
  q <- quantile(b$delta_visivel, c(.25, .75))
  cat("Aumentar como o p75 em vez do p25 (", round(q[2] - q[1]), "R$ pc ):",
      round(100 * coef(h2b)[["visivel100_2024"]] * (q[2] - q[1]) / 100, 1), "p.p.\n")
  cat("% de municípios com variação: caiu", round(100 * mean(b$delta_visivel < 0), 1),
      "| >= +100:", round(100 * mean(b$delta_visivel >= 100), 1),
      "| >= +200:", round(100 * mean(b$delta_visivel >= 200), 1),
      "| >= +500:", round(100 * mean(b$delta_visivel >= 500), 1), "\n")

  cat("\n(c) Perfil dos municípios que aumentaram o gasto visível em R$ 500 pc ou mais\n")
  g <- b$delta_visivel >= 500
  perfil <- function(x) round(c(grupo = median(x[g]), resto = median(x[!g])))
  print(rbind(populacao_mediana = perfil(b$pop_2024),
              receita_pc_mediana = perfil(b$rec_pc_2024_w),
              visivel_pc_2023_mediano = perfil(b$visivel_pc_2023_w)))
  cat("Aumento como % da receita (mediana do grupo):",
      round(100 * median(b$delta_visivel[g] / b$rec_pc_2024_w[g]), 1), "%\n")
  cat("Até 10 mil habitantes: grupo", round(100 * mean(b$pop_2024[g] <= 10000)), "% | resto",
      round(100 * mean(b$pop_2024[!g] <= 10000)), "%\n")

  cat("\n(d) A variação do gasto visível tem efeito não linear? (termo quadrático)\n")
  b$d100 <- b$delta_visivel / 100
  m_dq <- update(h2b, . ~ . - visivel100_2024 + d100 + I(d100^2))
  print(round(coeftest(m_dq, vcov. = vcovHC, type = "HC1")[c("d100", "I(d100^2)"), ], 4))
}, finally = sink())
