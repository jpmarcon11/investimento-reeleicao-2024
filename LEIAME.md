# Trabalho de Econometria I — Reeleição de prefeitos e investimento em 2024

## Estrutura da pasta
| Pasta | Conteúdo |
|---|---|
| `codigo/` | Scripts em R (00 a 08) |
| `dados_brutos.zip` | Dados brutos guardados num arquivo só: `dados_brutos/importados/` e `dados_brutos/siconfi_finbra/`. O `00_main.R` descompacta quando necessário |
| `dados_brutos/siconfi_finbra/` | Os 7 zips do FINBRA, baixados à mão (ver abaixo) |
| `dados_brutos/tse/` | Zips do TSE, criados pelo script 01 só se ele precisar baixar os dados |
| `dados_brutos/importados/` | Dados de entrada já importados para o R (`.rds`), gerados pelos scripts 01, 03 e 04 |
| `dados/` | Base final "merged" (`base_final.rds` e `.csv`): TSE, Siconfi e IBGE, uma linha por município; é a única base usada nas análises |
| `saidas/` | Contagens, tabelas (`.txt` e `.tex` para o LaTeX), figuras (`.png` e `.pdf`) e versões dos pacotes |

## Como rodar
1. Definir a pasta do trabalho como diretório de trabalho: `setwd(".../trabalho_econometria")`.
2. Instalar os pacotes: `install.packages(c("data.table", "jsonlite", "AER", "stargazer", "marginaleffects"))`.
3. Executar `source("codigo/00_main.R")`. Se a pasta `dados_brutos/importados/` não existir, o script descompacta `dados_brutos.zip`, que guarda os dados importados e os 7 zips do FINBRA. Sem esse arquivo, os scripts 01 e 03 baixam os dados do TSE e do IBGE, e os zips do FINBRA precisam ser baixados à mão (ver abaixo) e colocados em `dados_brutos/siconfi_finbra/`. As versões do R e dos pacotes ficam em `saidas/sessionInfo.txt`.

## Dados de entrada
| Arquivo em `dados_brutos/importados/` | Fonte | Como |
|---|---|---|
| `consulta_cand_2016/2020/2022/2024.rds` | TSE, Portal de Dados Abertos — Candidatos | script 01 |
| `votacao_candidato_munzona_2020/2024.rds` | TSE, Portal de Dados Abertos — Resultados | script 01 |
| `ibge_populacao_2024.rds` | IBGE/SIDRA, tabela 6579 (população estimada) | script 03 |
| `ibge_pib_2023.rds` | IBGE/SIDRA, tabela 5938 (PIB municipal) | script 03 |
| `ibge_alfabetizacao_2022.rds` | IBGE/SIDRA, tabela 9543 (taxa de alfabetização, 15 anos ou mais, Censo 2022) | script 03 |
| `correspondencia_tse_ibge.rds` | Correspondência de códigos TSE ↔ IBGE (repositório betafcc/Municipios-Brasileiros-TSE, GitHub) | script 03 |
| `finbra_rreo_despesas_2022/2023/2024_b4.rds` | Siconfi/FINBRA, RREO Anexo 01, Despesas Orçamentárias | manual + script 04 |
| `finbra_rreo_receitas_2023/2024_b4.rds` | Siconfi/FINBRA, RREO Anexo 01, Receitas Orçamentárias | manual + script 04 |
| `finbra_rreo_funcao_2023/2024_b4.rds` | Siconfi/FINBRA, RREO Anexo 02, Despesa por Função/Subfunção | manual + script 04 |

### Download manual do FINBRA (único passo manual)
A API do Siconfi exige uma consulta por município (cerca de 33 mil) e bloqueia por excesso de pedidos; o site do FINBRA pede captcha. Por isso o RREO foi baixado à mão.

Caminho: https://siconfi.tesouro.gov.br → Consultas → Consultar FINBRA → Relatório Resumido de Execução Orçamentária (RREO). Em todos os arquivos: Escopo = Municípios; Período = 4º bimestre (acumulado de janeiro a agosto). Clicar em "Baixar" (CSV compactado em ZIP), renomear o arquivo como abaixo e salvar em `dados_brutos/siconfi_finbra/`.

| Exercício | Anexo | Tabela | Nome do arquivo |
|---|---|---|---|
| 2022 | Anexo 01 | Despesas Orçamentárias | `finbra_rreo_despesas_2022_b4.zip` |
| 2023 | Anexo 01 | Despesas Orçamentárias | `finbra_rreo_despesas_2023_b4.zip` |
| 2024 | Anexo 01 | Despesas Orçamentárias | `finbra_rreo_despesas_2024_b4.zip` |
| 2023 | Anexo 01 | Receitas Orçamentárias | `finbra_rreo_receitas_2023_b4.zip` |
| 2024 | Anexo 01 | Receitas Orçamentárias | `finbra_rreo_receitas_2024_b4.zip` |
| 2023 | Anexo 02 | Despesa por Função/Subfunção | `finbra_rreo_funcao_2023_b4.zip` |
| 2024 | Anexo 02 | Despesa por Função/Subfunção | `finbra_rreo_funcao_2024_b4.zip` |

O script 04 importa esses zips. Todos os demais dados são baixados pelos scripts 01 e 03.

## Scripts
0. `00_main.R` — roda os scripts em ordem e grava `saidas/sessionInfo.txt`.
1. `01_download_tse.R` — baixa e importa candidatos (2016, 2020, 2022, 2024) e votação (2020, 2024) do TSE.
2. RREO do Siconfi: download manual no FINBRA (ver "Download manual do FINBRA", acima).
3. `03_download_ibge.R` — baixa população, PIB, alfabetização (SIDRA) e a correspondência TSE ↔ IBGE.
4. `04_importar_finbra.R` — importa os zips do FINBRA.
5. `05_limpeza.R` — monta a amostra (eleitos em 2020, 1º mandato, situação em 2024, margem de 2020), organiza o Siconfi, junta os controles e cria todas as variáveis usadas nos scripts 06 a 08 (inclusive as da robustez) → `dados/base_final.rds` e `.csv`.
6. `06_descritivas.R` — tabela 1 (descritivas), tabela 1b (acima × abaixo da mediana de investimento), tabela 2 e figura 1 (reeleição por quartil de investimento), investimento médio per capita por ano (2022–2024) , distribuição do investimento de 2024 com os cortes da winsorização e gasto médio por tipo (visível, social e invisível) em 2023 e 2024; mediana e percentuais do investimento de 2024 (`saidas/descritivas_investimento.csv`).
7. `07_estimacao.R` — **resultados**: MPL com controles em blocos e interação com a margem de 2020 (tabela 3); diagnósticos (Breusch-Pagan, VIF, testes F, previsões fora de [0, 1], nível × aceleração); MPL × Probit × Logit com efeitos marginais e prefeito típico (tabela 4); tipo de gasto e faixas de aumento do gasto visível (tabela 5, figura 2); forma funcional (tabela 6); tabela de diagnósticos (`saidas/tabela_diagnosticos`: Breusch-Pagan, VIF e testes F); efeito da H3 nos percentis da margem de 2020 (`saidas/h3_efeito_por_margem.csv`); magnitudes em cenários (`saidas/magnitudes.txt`).
8. `08_robustez.R` — **robustez**: tabela-resumo com um exercício por linha (coeficiente, EP, IC 95% e N; tabela 10) e gráfico de coeficientes (figura 3); medida do X, amostra, receita de 2024, transferências de capital e cluster por UF (tabela 7); placebo com o investimento de 2022, com o p-valor do teste 2024 = 2022 (tabela 8); H2 com o grupo visível amplo; seleção, heterogeneidade, votos anulados e eleição suplementar 2021-2024 (tabela 9); teste da diferença por porte do município (`saidas/heterogeneidade_porte.csv`); empenhado × liquidado: média e efeito por desvio-padrão (`saidas/empenhado_liquidado.csv`).

## Decisões de construção
- Cruzamento 2020 → 2024 pelo **título de eleitor** (o CPF vem oculto em 2024).
- Só eleição ordinária. Municípios em que a eleição de 2024 foi anulada e refeita em eleição suplementar (2025-2026) ficam marcados (`suplementar_2024`) e saem em um exercício de robustez; os com eleição suplementar durante o mandato 2021-2024 (`suplementar_2021_2024`) saem da análise principal.
- Margem de 2020 = (votos do 1º − votos do 2º) / votos válidos, no turno decisivo; candidato único = 1.
- X: investimento **liquidado** de janeiro a agosto (4º bimestre, antes da eleição de 6/10), per capita (população 2024 em todos os anos), winsorizado em 1%/99%, em centenas de reais; modelo com o nível de 2024 controlando pelo de 2023.
- Y: reeleito em 2024 entre todos os aptos (quem não concorreu = 0).
- Controles fiscais: receita tributária (própria) e transferências correntes per capita de 2023, anteriores ao ano eleitoral (as de 2024 entram como robustez na Tabela 7). A receita total não entra porque já contém as transferências e as operações de crédito; transferências de capital ficam de fora porque financiam o próprio investimento (entram como robustez na Tabela 7).
- Município que publicou o RREO sem linha de investimento = investimento zero; sem RREO no ano = ausente (sai da amostra).
- Candidaturas de 2024 com votos anulados ("Anulado" ou "Anulado sub judice" no arquivo de votação, ou seja, indeferidas ou cassadas) saem da análise principal e voltam como robustez na Tabela 9 (com Y = 0).
- Municípios com eleição suplementar para prefeito entre 2021 e 2024 (arquivo de candidatos de 2020) saem da análise principal: o prefeito eleito em 2020 deixou o cargo durante o mandato (cassação, indeferimento ou morte), e o investimento de 2023 e 2024 foi decidido pelo substituto. Voltam como robustez na Tabela 9.
- Candidaturas sem resultado na votação ("#NULO": renúncia, substituição ou indeferimento antes da urna) contam como não concorreu (Y = 0); o arquivo de candidatos não permite separar os motivos.
- Alfabetização de 2022 (Censo) entra como controle do perfil do eleitorado.
- Base final salva também em `dados/base_final.rds`, que preserva os tipos das colunas.
- Características do prefeito (gênero, escolaridade) e partido para o alinhamento vêm de 2020, disponíveis para todos.
- Probit e Logit sem RR: os 8 prefeitos de RR na amostra foram reeleitos (previsão perfeita pela dummy de UF). O MPL principal usa a amostra completa; a Tabela 4 também traz o MPL sem RR, para comparar na mesma amostra.
- Grupos de despesa liquidada por função (H2):
  - **Visível:** Urbanismo, Transporte, Saneamento, Habitação, Desporto e Lazer.
  - **Social:** Saúde, Educação.
  - **Invisível:** Administração, Legislativa, Encargos Especiais, Previdência Social.
  - Cultura, Assistência Social e Segurança Pública ficam fora da classificação principal (ambíguas); na robustez entram no grupo visível.

## Amostra
- 5.494 municípios com prefeito eleito identificado em 2020; 3.373 em 1º mandato.
- Entre os de 1º mandato: 2.805 concorreram e 2.334 foram reeleitos.
- Base final: 3.364 municípios (9 sem RREO de 2023 ou 2024). Análise principal: 3.326 (sem as 19 candidaturas com votos anulados e os 19 municípios com eleição suplementar entre 2021 e 2024); as regressões usam 3.323, porque 3 municípios não têm receita tributária de 2023 no RREO.
- Contagens completas em `saidas/contagem_amostra.txt` e `saidas/contagem_base_final.txt`.

## Limitações de dados
- Gasto de campanha de 2024 não incluído: além do arquivo grande, tende a depender da chance esperada de vitória (possível *bad control*).
