# 06_descritivas.R
# Descritivas: tabelas 1, 1b e 2 e figura 1
# salva a figura em .png e .pdf
salva_figura <- function(arquivo, desenho, largura = 16, altura = 10) {
  png(paste0(arquivo, ".png"), width = largura, height = altura, units = "cm", res = 300); desenho(); dev.off()
  pdf(paste0(arquivo, ".pdf"), width = largura / 2.54, height = altura / 2.54); desenho(); dev.off()
}

dir.create("saidas", showWarnings = FALSE)
b <- readRDS("dados/base_final.rds")
b <- b[b$amostra_principal == 1, ]

vars <- c(reeleito_2024 = "Reeleito em 2024 (1/0)",
          concorreu_2024 = "Concorreu em 2024 (1/0)",
          inv_pc_2024_w = "Investimento per capita 2024, jan-ago (R$)",
          inv_pc_2023_w = "Investimento per capita 2023, jan-ago (R$)",
          inv_pc_2022_w = "Investimento per capita 2022, jan-ago (R$)",
          visivel_pc_2024_w = "Gasto visível per capita 2024, jan-ago (R$)",
          visivel_pc_2023_w = "Gasto visível per capita 2023, jan-ago (R$)",
          delta_visivel = "Variação do gasto visível per capita 2023-2024 (R$)",
          social_pc_2024_w = "Gasto social per capita 2024, jan-ago (R$)",
          invisivel_pc_2024_w = "Gasto invisível per capita 2024, jan-ago (R$)",
          rec_pc_2024_w = "Receita total per capita 2024, jan-ago (R$)",
          rec_trib_pc_2023_w = "Receita tributária per capita 2023, jan-ago (R$)",
          transf_corr_pc_2023_w = "Transferências correntes per capita 2023, jan-ago (R$)",
          alfabetizacao_2022 = "Taxa de alfabetização 2022, 15 anos ou mais (%)",
          margem_2020 = "Margem de vitória em 2020 (proporção)",
          pop_2024 = "População 2024",
          pib_pc_2023 = "PIB per capita 2023 (R$)",
          alinhado_governador = "Mesmo partido do governador (1/0)",
          alinhado_presidente = "Partido do presidente - PT (1/0)",
          mulher = "Prefeita mulher (1/0)",
          superior = "Prefeito com ensino superior (1/0)")

desc <- t(sapply(names(vars), function(v) {
  x <- b[[v]]
  c(n = sum(!is.na(x)), media = mean(x, na.rm = TRUE), dp = sd(x, na.rm = TRUE),
    min = min(x, na.rm = TRUE), mediana = median(x, na.rm = TRUE), max = max(x, na.rm = TRUE))
}))
desc <- data.frame(variavel = vars, round(desc, 3), row.names = NULL)
write.csv(desc, "saidas/tabela1_descritivas.csv", row.names = FALSE, fileEncoding = "UTF-8")
print(desc, right = FALSE)

# tabela 1b: acima x abaixo da mediana de investimento
acima <- b$inv_pc_2024_w > median(b$inv_pc_2024_w)
comp_vars <- c("reeleito_2024", "concorreu_2024", "inv_pc_2023_w", "rec_trib_pc_2023_w",
               "transf_corr_pc_2023_w", "alfabetizacao_2022", "margem_2020", "pop_2024", "pib_pc_2023",
               "alinhado_governador", "alinhado_presidente", "mulher", "superior")
comp <- t(sapply(comp_vars, function(v) {
  x <- b[[v]]
  c(abaixo = mean(x[!acima], na.rm = TRUE), acima = mean(x[acima], na.rm = TRUE),
    diferenca = mean(x[acima], na.rm = TRUE) - mean(x[!acima], na.rm = TRUE),
    p_valor = t.test(x[acima], x[!acima])$p.value)
}))
comp <- data.frame(variavel = vars[comp_vars], round(comp, 3), row.names = NULL)
write.csv(comp, "saidas/tabela1b_comparacao_mediana.csv", row.names = FALSE, fileEncoding = "UTF-8")
cat("\nAcima x abaixo da mediana de investimento per capita 2024:\n"); print(comp, right = FALSE)

# tabela 2 e figura 1: reeleição por quartil de investimento
b$quartil_inv <- cut(b$inv_pc_2024_w, unique(quantile(b$inv_pc_2024_w, 0:4 / 4)), include.lowest = TRUE,
                     labels = c("Q1 (menor)", "Q2", "Q3", "Q4 (maior)"))
tab <- aggregate(cbind(reeleito_2024, concorreu_2024, inv_pc_2024_w) ~ quartil_inv, data = b, FUN = mean)
tab$n <- as.vector(table(b$quartil_inv))
write.csv(tab, "saidas/tabela2_reeleicao_por_quartil.csv", row.names = FALSE, fileEncoding = "UTF-8")
cat("\nReeleição por quartil de investimento per capita 2024:\n"); print(tab)

# intervalo de 95% da proporção
tab$ep <- sqrt(tab$reeleito_2024 * (1 - tab$reeleito_2024) / tab$n)
salva_figura("saidas/figura1_reeleicao_por_quartil", function() {
  par(mar = c(4.5, 4.5, 1, 1))
  bp <- barplot(100 * tab$reeleito_2024, names.arg = tab$quartil_inv, ylim = c(0, 100), col = "grey70", border = NA,
                ylab = "Prefeitos reeleitos (%)", xlab = "Quartil de investimento per capita (jan-ago 2024)")
  arrows(bp, 100 * (tab$reeleito_2024 - 1.96 * tab$ep), bp, 100 * (tab$reeleito_2024 + 1.96 * tab$ep),
         angle = 90, code = 3, length = 0.05)
  text(bp, 100 * (tab$reeleito_2024 + 1.96 * tab$ep) + 4, sprintf("%.1f%%", 100 * tab$reeleito_2024))
})

# investimento médio per capita por ano (jan-ago)
media_ano <- sapply(2022:2024, function(a) mean(b[[paste0("inv_pc_", a, "_w")]], na.rm = TRUE))
names(media_ano) <- 2022:2024
print(round(media_ano))
salva_figura("saidas/figura_investimento_por_ano", function() {
  par(mar = c(4.5, 4.5, 1, 1))
  bp <- barplot(media_ano, ylim = c(0, 1.15 * max(media_ano)), col = "grey70", border = NA,
                ylab = "Investimento médio per capita (R$)", xlab = "Ano (janeiro a agosto)")
  text(bp, media_ano + 0.05 * max(media_ano), sprintf("R$ %.0f", media_ano))
})

# distribuição do investimento per capita de 2024 e cortes da winsorização
cortes <- range(b$inv_pc_2024_w)
salva_figura("saidas/figura_distribuicao_investimento", function() {
  par(mar = c(4.5, 4.5, 1, 1))
  hist(b$inv_pc_2024, breaks = 80, col = "grey70", border = "white", main = "",
       xlab = "Investimento per capita 2024, jan-ago (R$)", ylab = "Municípios")
  abline(v = cortes, lty = 2)
  legend("topright", lty = 2, legend = "Cortes da winsorização (1% e 99%)", bty = "n")
})

# gasto médio per capita por tipo em 2023 e 2024
grupos <- c(Visível = "visivel", Social = "social", Invisível = "invisivel")
comp <- sapply(grupos, function(g) sapply(2023:2024, function(a) mean(b[[paste0(g, "_pc_", a, "_w")]], na.rm = TRUE)))
rownames(comp) <- 2023:2024
print(round(comp))
cat("Variação 2023-2024 (%):", round(100 * (comp["2024", ] / comp["2023", ] - 1), 1), "\n")
salva_figura("saidas/figura_gasto_por_tipo", function() {
  par(mar = c(4.5, 4.5, 1, 1))
  bp <- barplot(comp, beside = TRUE, col = c("grey75", "grey35"), border = NA, ylim = c(0, 1.15 * max(comp)),
                ylab = "Gasto médio per capita, jan-ago (R$)")
  text(colMeans(bp), apply(comp, 2, max) + 0.05 * max(comp),
       sprintf("%+.0f%%", 100 * (comp["2024", ] / comp["2023", ] - 1)))
  legend("topleft", fill = c("grey75", "grey35"), legend = 2023:2024, border = NA, bty = "n")
})

# investimento de 2024: quem aumentou em relação a 2023 e quem passou de R$ 1.000 per capita
inv_desc <- c(mediana_2024 = median(b$inv_pc_2024_w),
              pct_aumentou = 100 * mean(b$inv_pc_2024 > b$inv_pc_2023),
              pct_acima_1000 = 100 * mean(b$inv_pc_2024 > 1000))
print(round(inv_desc, 1))
write.csv(data.frame(indicador = names(inv_desc), valor = round(inv_desc, 1)), "saidas/descritivas_investimento.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
