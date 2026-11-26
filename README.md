# Investimento no ano eleitoral e reeleição de prefeitos em 2024

Trabalho final de Econometria I, FGV EESP, 2º semestre de 2026.
Autores: Francisco Maciel e João Paulo Marcon.

Pergunta: prefeitos de primeiro mandato que investiram mais no ano eleitoral de 2024 tiveram maior probabilidade de reeleição? A unidade de análise é o município, em *cross-section*.

## Estrutura da pasta
| Pasta ou arquivo | Conteúdo |
|---|---|
| `codigo/` | Scripts em R (00 a 08) |
| `dados/` | Base final "merged" (`base_final.rds` e `.csv`): TSE, Siconfi e IBGE, uma linha por município. É a única base usada nas análises |
| `saidas/` | Contagens, tabelas (`.txt`, `.csv` e `.tex`), figuras (`.png` e `.pdf`) e versões dos pacotes |
| `dados_brutos.zip` | Dados brutos na versão exata usada no trabalho (≈ 300 MB). Não está no GitHub, que recusa arquivos acima de 100 MB: baixar em [inserir link do Google Drive] e salvar na raiz da pasta |
| `trabalho_econometria.Rproj` | Projeto do RStudio, que abre já na pasta certa |

Dentro de `dados_brutos.zip`:
- `dados_brutos/importados/`: os dados de entrada já importados para o R (`.rds`), gerados pelos scripts 01, 03 e 04;
- `dados_brutos/siconfi_finbra/`: os 7 zips do FINBRA, baixados à mão (ver abaixo).

O script 01 cria `dados_brutos/tse/` só se precisar baixar os dados do TSE.

## Requisitos
- R 4.5.3 (versão usada; as versões dos pacotes estão em `saidas/sessionInfo.txt`).
- Pacotes: `install.packages(c("data.table", "jsonlite", "AER", "stargazer", "marginaleffects"))`.
- Só na opção 2 (ver abaixo), se for preciso baixar e importar os dados do TSE do zero (sem `dados_brutos.zip`), os arquivos de candidatos e de votação são grandes: a importação leva alguns minutos e recomendamos pelo menos 8 GB de memória RAM. Com o `dados_brutos.zip`, essa etapa é pulada.

## Como rodar
Abrir `trabalho_econometria.Rproj` no RStudio. Sem o RStudio, usar `setwd(".../trabalho_econometria")`.

### Opção 1: reproduzir as análises (recomendado)
A base final `dados/base_final.rds` contém todas as variáveis usadas nas análises, e os scripts 06 a 08 leem só esse arquivo. Basta executar:

```r
source("codigo/06_descritivas.R", encoding = "UTF-8")
source("codigo/07_estimacao.R", encoding = "UTF-8")
source("codigo/08_robustez.R", encoding = "UTF-8")
```

As tabelas, figuras e números do relatório são gravados em `saidas/`.

### Opção 2: reconstruir a base a partir dos dados brutos
1. Baixar `dados_brutos.zip` (link na estrutura da pasta, acima) e colocá-lo na raiz da pasta, para reproduzir exatamente a versão dos dados usada no relatório.
2. Executar `source("codigo/00_main.R")`, que roda os scripts 01 a 08 em ordem. Se a pasta `dados_brutos/importados/` não existir, o script descompacta `dados_brutos.zip`. Sem esse arquivo, os scripts 01 e 03 baixam os dados do TSE e do IBGE (possivelmente em versão mais nova, ver abaixo), e os zips do FINBRA precisam ser baixados à mão e colocados em `dados_brutos/siconfi_finbra/`.

## Dados de entrada
| Arquivo em `dados_brutos/importados/` | Fonte | Como | Baixado em |
|---|---|---|---|
| `consulta_cand_2016/2020/2022/2024.rds` | TSE, Portal de Dados Abertos, Candidatos | script 01 | 20/11/2026 |
| `votacao_candidato_munzona_2020/2024.rds` | TSE, Portal de Dados Abertos, Resultados | script 01 | 20/11/2026 |
| `ibge_populacao_2024.rds` | IBGE/SIDRA, tabela 6579 (população estimada) | script 03 | 20/11/2026 |
| `ibge_pib_2023.rds` | IBGE/SIDRA, tabela 5938 (PIB municipal) | script 03 | 20/11/2026 |
| `ibge_alfabetizacao_2022.rds` | IBGE/SIDRA, tabela 9543 (taxa de alfabetização, 15 anos ou mais, Censo 2022) | script 03 | 21/11/2026 |
| `correspondencia_tse_ibge.rds` | Correspondência de códigos TSE ↔ IBGE (repositório betafcc/Municipios-Brasileiros-TSE, GitHub) | script 03 | 20/11/2026 |
| `finbra_rreo_despesas_2022/2023/2024_b4.rds` | Siconfi/FINBRA, RREO Anexo 01, Despesas Orçamentárias | manual + script 04 | 09 e 10/11/2026 |
| `finbra_rreo_receitas_2023/2024_b4.rds` | Siconfi/FINBRA, RREO Anexo 01, Receitas Orçamentárias | manual + script 04 | 10/11/2026 |
| `finbra_rreo_funcao_2023/2024_b4.rds` | Siconfi/FINBRA, RREO Anexo 02, Despesa por Função/Subfunção | manual + script 04 | 10/11/2026 |

### Versão dos dados do TSE
O TSE atualiza os arquivos de dados abertos. O arquivo de candidatos de 2024, por exemplo, passou de 463.877 para 463.935 linhas entre outubro e novembro de 2026. Quem rodar o script 01 no futuro pode receber outra versão e encontrar contagens um pouco diferentes. O `dados_brutos.zip` guarda exatamente a versão usada no trabalho. Data de geração informada pelo TSE (colunas `DT_GERACAO` e `HH_GERACAO`):

| Arquivo | Linhas | Gerado pelo TSE em |
|---|---|---|
| Candidatos 2016 | 498.391 | 13/03/2023 |
| Candidatos 2020 | 558.804 | 06/01/2026 |
| Candidatos 2022 | 29.322 | 20/11/2026 |
| Candidatos 2024 | 463.935 | 20/11/2026 |
| Votação 2020 | 983.614 | 06/01/2026 |
| Votação 2024 | 717.172 | 20/11/2026 |

### Download manual do FINBRA (único passo manual)
A API do Siconfi exige uma consulta por município (cerca de 33 mil) e bloqueia por excesso de pedidos, e o site do FINBRA pede captcha. Por isso o RREO foi baixado à mão.

Caminho: https://siconfi.tesouro.gov.br → Consultas → Consultar FINBRA → Relatório Resumido de Execução Orçamentária (RREO). Em todos os arquivos: Escopo = Municípios; Periodicidade = Bimestral; Período = 4º bimestre (acumulado de janeiro a agosto). Clicar em "Baixar" (CSV compactado em ZIP), renomear o arquivo como abaixo e salvar em `dados_brutos/siconfi_finbra/`.

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
0. `00_main.R`: roda os scripts em ordem e grava `saidas/sessionInfo.txt`.
1. `01_download_tse.R`: baixa e importa candidatos (2016, 2020, 2022 e 2024) e votação (2020 e 2024) do TSE.
2. RREO do Siconfi: download manual no FINBRA (ver acima).
3. `03_download_ibge.R`: baixa população, PIB e alfabetização (SIDRA) e a correspondência TSE ↔ IBGE.
4. `04_importar_finbra.R`: importa os zips do FINBRA.
5. `05_limpeza.R`: monta a amostra (eleitos em 2020, 1º mandato, situação em 2024, margem de 2020), organiza o Siconfi, junta os controles e cria todas as variáveis usadas nos scripts 06 a 08 → `dados/base_final.rds` e `.csv`.
6. `06_descritivas.R`: estatísticas descritivas, reeleição por quartil de investimento e figuras do investimento e do gasto por tipo.
7. `07_estimacao.R`: MPL, diagnósticos, Probit e Logit, tipo de gasto (H2), interação com a margem de 2020 (H3), forma funcional e magnitudes.
8. `08_robustez.R`: exercícios de robustez, investimento de 2022, seleção e heterogeneidade por porte.

## Correspondência entre o relatório e os arquivos de saída
Os nomes dos arquivos seguem a ordem em que os scripts os geram, e não a numeração final do relatório.

| No relatório | Arquivo em `saidas/` |
|---|---|
| Tabela 1 (construção da amostra) | `contagem_amostra.txt` |
| Tabela 2 (estatísticas descritivas) | `tabela1_descritivas.csv` |
| Figura 1a (investimento, 2022 a 2024) | `figura_investimento_por_ano.png/.pdf` |
| Figura 1b (gasto por tipo, 2023 e 2024) | `figura_gasto_por_tipo.png/.pdf` |
| Texto da seção Dados (mediana, % acima de R$ 1.000, % que aumentou, quartis) | `descritivas_investimento.csv`, `tabela2_reeleicao_por_quartil.csv` |
| Tabela 3 (testes de diagnóstico) | `tabela_diagnosticos.csv/.tex/.txt` |
| Tabela 4 (MPL) | `tabela3_mpl.tex/.txt` |
| Texto: Probit, Logit e MPL sem RR | `tabela4_mpl_probit_logit.tex/.txt` |
| Texto: efeito por desvio-padrão e por R$ 100 | `magnitudes.txt` |
| Tabela 5 (despesas por função) | `tabela5_h2_tipo_de_gasto.tex/.txt`, colunas 2 e 3 |
| Texto: H3 nos percentis da margem | `h3_efeito_por_margem.csv` |
| Texto: forma funcional (quadrática e log) | `tabela6_nao_linearidades.tex/.txt` |
| Tabela 6 (resumo da robustez) | `tabela10_resumo_robustez.csv/.tex/.txt` |
| Texto: empenhado × liquidado | `empenhado_liquidado.csv` |
| Tabela 7 (seleção, heterogeneidade e investimento de 2022) | `tabela9_selecao_heterogeneidade.tex/.txt` (concorreu), `heterogeneidade_porte.csv` (porte), `tabela8_placebo_2022.tex/.txt` (2022) |

Saídas complementares, que não entram no relatório: `tabela1b_comparacao_mediana.csv`, `tabela7_robustez`, `figura1_reeleicao_por_quartil`, `figura2_reeleicao_por_aumento_visivel`, `figura3_robustez`, `figura_distribuicao_investimento` e `contagem_base_final.txt`.

## Decisões de construção
- Cruzamento 2020 → 2024 pelo **título de eleitor** (o CPF vem oculto em 2024).
- Só eleição ordinária. Municípios em que a eleição de 2024 foi anulada e refeita em eleição suplementar (2025-2026) ficam marcados (`suplementar_2024`) e saem em um exercício de robustez. Os municípios com eleição suplementar durante o mandato 2021-2024 (`suplementar_2021_2024`) saem da análise principal.
- Margem de 2020 = (votos do 1º − votos do 2º) / votos válidos, no turno decisivo; candidato único = 1.
- X: investimento **liquidado** de janeiro a agosto (4º bimestre, antes da eleição de 6/10), per capita (população de 2024 em todos os anos), winsorizado em 1%/99%, em centenas de reais. O modelo usa o nível de 2024 controlando pelo de 2023.
- Y: reeleito em 2024 entre todos os aptos (quem não concorreu = 0).
- Controles fiscais: receita tributária (própria) e transferências correntes per capita de 2023, anteriores ao ano eleitoral (as de 2024 entram na robustez). A receita total não entra porque já contém as transferências e as operações de crédito. As transferências de capital ficam de fora porque financiam o próprio investimento (entram na robustez).
- Município que publicou o RREO sem linha de investimento = investimento zero; sem RREO no ano = ausente (sai da amostra).
- Candidaturas de 2024 com votos anulados ("Anulado" ou "Anulado sub judice" no arquivo de votação, ou seja, indeferidas ou cassadas) saem da análise principal e voltam na robustez, com Y = 0.
- Municípios com eleição suplementar para prefeito entre 2021 e 2024 (arquivo de candidatos de 2020) saem da análise principal: o prefeito eleito em 2020 deixou o cargo durante o mandato (cassação, indeferimento ou morte), e o investimento de 2023 e 2024 foi decidido pelo substituto. Voltam na robustez.
- Candidaturas sem resultado na votação ("#NULO": renúncia, substituição ou indeferimento antes da urna) contam como não concorreu (Y = 0); o arquivo de candidatos não permite separar os motivos.
- Alfabetização de 2022 (Censo) entra como controle do perfil do eleitorado.
- Características do prefeito (gênero e escolaridade) e partido para o alinhamento vêm de 2020, disponíveis para todos.
- Probit e Logit sem RR: os 8 prefeitos de RR na amostra foram reeleitos (previsão perfeita pela dummy de UF). O MPL principal usa a amostra completa; o MPL sem RR é estimado para comparar na mesma amostra.
- Grupos de despesa liquidada por função (H2):
  - **Visível:** Urbanismo, Transporte, Saneamento, Habitação, Desporto e Lazer.
  - **Social:** Saúde, Educação.
  - **Invisível:** Administração, Legislativa, Encargos Especiais, Previdência Social.
  - Cultura, Assistência Social e Segurança Pública ficam fora da classificação principal (ambíguas); na robustez entram no grupo visível.
- A base final também é salva em `dados/base_final.rds`, que preserva os tipos das colunas.

## Amostra
- 5.494 municípios com prefeito eleito identificado em 2020; 3.373 em 1º mandato.
- Entre os de 1º mandato, 2.805 concorreram e 2.334 foram reeleitos.
- Base final: 3.364 municípios (9 sem RREO de 2023 ou 2024). Análise principal: 3.326 (sem as 19 candidaturas com votos anulados e os 19 municípios com eleição suplementar entre 2021 e 2024). As regressões usam 3.323, porque 3 municípios não têm receita tributária de 2023 no RREO.
- Contagens completas em `saidas/contagem_amostra.txt` e `saidas/contagem_base_final.txt`.

## Limitações de dados
- Gasto de campanha de 2024 não incluído: além de o arquivo ser grande, ele tende a depender da chance esperada de vitória (possível *bad control*).

## Uso de inteligência artificial
Usamos IA ao longo do trabalho: um tutor configurado com o prompt da disciplina (conversa: [inserir link da conversa]) e o Claude (Anthropic). A IA foi usada para discutir as decisões de amostra, variáveis e especificação, para escrever, revisar e depurar o código dos scripts 01 a 08 e para revisar o texto e as tabelas do relatório. As decisões empíricas foram tomadas pela dupla, que conferiu os resultados com os arquivos de saída. A declaração completa está no relatório.

## Licença
O código está sob a licença MIT (arquivo `LICENSE`). Os dados usados são públicos (TSE, Tesouro Nacional/Siconfi e IBGE).
