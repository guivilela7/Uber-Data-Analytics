-- ============================================================================
-- GOLD LAYER: CONSULTAS ANALITICAS
-- Queries para analise de performance de corridas Uber
-- Proposito: Fornecer insights para dashboards Power BI
-- ============================================================================


-- ============================================================================
-- 1. VERIFICACAO DO SCHEMA DW
-- ============================================================================
-- Proposito: Validar integridade e contagem de registros em cada tabela
-- Expectativa: Verificar se todas as tabelas foram populadas corretamente
-- Power BI: Card com total de registros por tabela
SELECT 'dim_tmp' AS tabela, COUNT(*) AS linhas FROM dw.dim_tmp
UNION ALL
SELECT 'dim_loc' AS tabela, COUNT(*) AS linhas FROM dw.dim_loc
UNION ALL
SELECT 'dim_vei' AS tabela, COUNT(*) AS linhas FROM dw.dim_vei
UNION ALL
SELECT 'dim_cli' AS tabela, COUNT(*) AS linhas FROM dw.dim_cli
UNION ALL
SELECT 'dim_pag' AS tabela, COUNT(*) AS linhas FROM dw.dim_pag
UNION ALL
SELECT 'ft_crr' AS tabela, COUNT(*) AS linhas FROM dw.ft_crr
ORDER BY tabela;


-- ============================================================================
-- 2. DESEMPENHO POR ZONA GEOGRAFICA
-- ============================================================================
-- Proposito: Medir volume, receita e rentabilidade por zona
-- Expectativa: Identificar zonas mais lucrativas e com maior demanda
-- Power BI: Grafico de barras (receita por zona) + Mapa de calor
SELECT
    lo.zona AS zona_origem,
    ld.zona AS zona_destino,
    COUNT(*) AS total_corridas,
    SUM(f.distancia_km) AS distancia_total_km,
    SUM(f.valor_corrida) AS receita_total,
    AVG(f.valor_por_km) AS valor_medio_por_km,
    AVG(f.duracao_minutos) AS duracao_media_min,
    AVG(f.avaliacao_motorista) AS avaliacao_motorista_media,
    SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) AS corridas_completas,
    ROUND(100.0 * SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS taxa_conclusao_pct
FROM dw.ft_crr f
JOIN dw.dim_loc lo ON f.loc_ori_srk = lo.loc_srk
JOIN dw.dim_loc ld ON f.loc_dst_srk = ld.loc_srk
GROUP BY lo.zona, ld.zona
ORDER BY receita_total DESC;


-- ============================================================================
-- 3. TOP 20 ROTAS MAIS RENTAVEIS (CTE)
-- ============================================================================
-- Proposito: Descobrir rotas com melhor valor por km
-- Expectativa: Identificar rotas premium para otimizacao de frota
-- Power BI: Tabela com ranking de rotas + Grafico de dispersao
WITH base_rotas AS (
    SELECT
        lo.local AS local_origem,
        ld.local AS local_destino,
        lo.zona AS zona_origem,
        ld.zona AS zona_destino,
        lo.regiao AS regiao_origem,
        ld.regiao AS regiao_destino,
        COUNT(*) AS total_corridas,
        SUM(f.valor_corrida) AS receita_total,
        AVG(f.valor_por_km) AS valor_medio_por_km,
        AVG(f.distancia_km) AS distancia_media_km,
        AVG(f.duracao_minutos) AS duracao_media_min
    FROM dw.ft_crr f
    JOIN dw.dim_loc lo ON f.loc_ori_srk = lo.loc_srk
    JOIN dw.dim_loc ld ON f.loc_dst_srk = ld.loc_srk
    WHERE f.eh_corrida_completa = TRUE
    GROUP BY lo.local, ld.local, lo.zona, ld.zona, lo.regiao, ld.regiao
),
ranked_rotas AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY valor_medio_por_km DESC) AS pos_rentabilidade,
        SUM(receita_total) OVER () AS receita_geral
    FROM base_rotas
    WHERE total_corridas >= 10
)
SELECT
    local_origem,
    local_destino,
    zona_origem,
    zona_destino,
    regiao_origem,
    regiao_destino,
    total_corridas,
    receita_total,
    valor_medio_por_km,
    distancia_media_km,
    duracao_media_min,
    ROUND(100.0 * receita_total / NULLIF(receita_geral, 0), 2) AS pct_receita_geral
FROM ranked_rotas
WHERE pos_rentabilidade <= 20
ORDER BY pos_rentabilidade;


-- ============================================================================
-- 4. PERFORMANCE TEMPORAL POR PERIODO DO DIA
-- ============================================================================
-- Proposito: Analisar padroes de demanda por periodo e dia da semana
-- Expectativa: Identificar horarios de pico e oportunidades de otimizacao
-- Power BI: Grafico de linha (receita por hora) + Matriz (dia x periodo)
SELECT
    t.nome_dia_semana,
    t.periodo_dia,
    t.eh_horario_pico,
    COUNT(*) AS total_corridas,
    SUM(f.distancia_km) AS distancia_total_km,
    SUM(f.valor_corrida) AS receita_total,
    AVG(f.valor_por_km) AS valor_medio_por_km,
    AVG(f.avaliacao_motorista) AS avaliacao_motorista_media,
    SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) AS corridas_completas,
    ROUND(100.0 * SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS taxa_conclusao_pct
FROM dw.ft_crr f
JOIN dw.dim_tmp t ON f.tmp_srk = t.tmp_srk
GROUP BY t.nome_dia_semana, t.periodo_dia, t.eh_horario_pico
ORDER BY 
    CASE t.nome_dia_semana
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END,
    CASE t.periodo_dia
        WHEN 'Madrugada' THEN 1
        WHEN 'Manha' THEN 2
        WHEN 'Tarde' THEN 3
        WHEN 'Noite' THEN 4
    END;


-- ============================================================================
-- 5. ANALISE DE VEICULOS POR CATEGORIA
-- ============================================================================
-- Proposito: Comparar performance de diferentes categorias de veiculos
-- Expectativa: Identificar categorias mais rentaveis e com melhor avaliacao
-- Power BI: Grafico de barras empilhadas + Cards com KPIs por categoria
SELECT
    v.categoria_veiculo,
    v.tipo_veiculo,
    COUNT(*) AS total_corridas,
    SUM(f.valor_corrida) AS receita_total,
    AVG(f.valor_por_km) AS valor_medio_por_km,
    AVG(f.distancia_km) AS distancia_media_km,
    AVG(f.duracao_minutos) AS duracao_media_min,
    AVG(f.avaliacao_motorista) AS avaliacao_motorista_media,
    SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) AS corridas_completas,
    ROUND(100.0 * SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS taxa_conclusao_pct
FROM dw.ft_crr f
JOIN dw.dim_vei v ON f.vei_srk = v.vei_srk
GROUP BY v.categoria_veiculo, v.tipo_veiculo
ORDER BY receita_total DESC;


-- ============================================================================
-- 6. PERFIL E SEGMENTACAO DE CLIENTES (CTE)
-- ============================================================================
-- Proposito: Analisar comportamento e valor por segmento de cliente
-- Expectativa: Identificar clientes VIP e oportunidades de fidelizacao
-- Power BI: Grafico de pizza (distribuicao de clientes) + Funil de segmentos
WITH base_clientes AS (
    SELECT
        c.segmento_cliente,
        COUNT(DISTINCT c.cli_srk) AS total_clientes,
        COUNT(*) AS total_corridas,
        AVG(f.valor_corrida) AS valor_medio_corrida,
        AVG(f.distancia_km) AS distancia_media_km,
        SUM(f.valor_corrida) AS receita_total,
        AVG(f.avaliacao_cliente) AS avaliacao_cliente_media
    FROM dw.ft_crr f
    JOIN dw.dim_cli c ON f.cli_srk = c.cli_srk
    WHERE f.eh_corrida_completa = TRUE
    GROUP BY c.segmento_cliente
),
totais AS (
    SELECT 
        SUM(receita_total) AS receita_geral,
        SUM(total_clientes) AS clientes_geral
    FROM base_clientes
)
SELECT
    bc.segmento_cliente,
    bc.total_clientes,
    ROUND(100.0 * bc.total_clientes / NULLIF(t.clientes_geral, 0), 2) AS pct_clientes,
    bc.total_corridas,
    ROUND(bc.total_corridas::NUMERIC / NULLIF(bc.total_clientes, 0), 2) AS corridas_por_cliente,
    bc.valor_medio_corrida,
    bc.distancia_media_km,
    bc.receita_total,
    ROUND(100.0 * bc.receita_total / NULLIF(t.receita_geral, 0), 2) AS pct_receita,
    bc.avaliacao_cliente_media
FROM base_clientes bc
CROSS JOIN totais t
ORDER BY bc.receita_total DESC;


-- ============================================================================
-- 7. ANALISE DE METODOS DE PAGAMENTO
-- ============================================================================
-- Proposito: Comparar preferencias e valores por metodo de pagamento
-- Expectativa: Identificar tendencias de digitalizacao e ticket medio
-- Power BI: Grafico de rosca (distribuicao) + Barras (valor medio)
SELECT
    p.categoria_pagamento,
    p.metodo_pagamento,
    COUNT(*) AS total_corridas,
    SUM(f.valor_corrida) AS receita_total,
    AVG(f.valor_corrida) AS valor_medio_corrida,
    AVG(f.distancia_km) AS distancia_media_km,
    SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) AS corridas_completas,
    ROUND(100.0 * SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS taxa_conclusao_pct
FROM dw.ft_crr f
JOIN dw.dim_pag p ON f.pag_srk = p.pag_srk
GROUP BY p.categoria_pagamento, p.metodo_pagamento
ORDER BY receita_total DESC;


-- ============================================================================
-- 8. ANALISE DE DISTANCIA POR CATEGORIA
-- ============================================================================
-- Proposito: Avaliar rentabilidade e demanda por categoria de distancia
-- Expectativa: Identificar categorias mais lucrativas (curta/media/longa)
-- Power BI: Grafico de barras agrupadas + Cards com metricas
SELECT
    f.categoria_distancia,
    COUNT(*) AS total_corridas,
    SUM(f.valor_corrida) AS receita_total,
    AVG(f.valor_por_km) AS valor_medio_por_km,
    AVG(f.distancia_km) AS distancia_media_km,
    AVG(f.duracao_minutos) AS duracao_media_min,
    AVG(f.avaliacao_motorista) AS avaliacao_motorista_media,
    SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) AS corridas_completas,
    ROUND(100.0 * SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS taxa_conclusao_pct
FROM dw.ft_crr f
WHERE f.categoria_distancia IS NOT NULL
GROUP BY f.categoria_distancia
ORDER BY 
    CASE f.categoria_distancia
        WHEN 'Curta' THEN 1
        WHEN 'Media' THEN 2
        WHEN 'Longa' THEN 3
    END;


-- ============================================================================
-- 9. ROTAS INTER-REGIONAIS VS INTRA-REGIONAIS (CTE)
-- ============================================================================
-- Proposito: Comparar performance de rotas que cruzam regioes
-- Expectativa: Identificar potencial de rotas longas entre regioes
-- Power BI: Grafico de barras comparativas + Sankey diagram
WITH base_regional AS (
    SELECT
        CASE WHEN f.eh_rota_inter_regional THEN 'Inter-Regional' ELSE 'Intra-Regional' END AS tipo_rota,
        lo.regiao AS regiao_origem,
        ld.regiao AS regiao_destino,
        COUNT(*) AS total_corridas,
        SUM(f.valor_corrida) AS receita_total,
        AVG(f.valor_por_km) AS valor_medio_por_km,
        AVG(f.distancia_km) AS distancia_media_km,
        AVG(f.duracao_minutos) AS duracao_media_min
    FROM dw.ft_crr f
    JOIN dw.dim_loc lo ON f.loc_ori_srk = lo.loc_srk
    JOIN dw.dim_loc ld ON f.loc_dst_srk = ld.loc_srk
    WHERE f.eh_corrida_completa = TRUE
    GROUP BY tipo_rota, lo.regiao, ld.regiao
),
totais AS (
    SELECT SUM(receita_total) AS receita_geral FROM base_regional
)
SELECT
    br.tipo_rota,
    br.regiao_origem,
    br.regiao_destino,
    br.total_corridas,
    br.receita_total,
    ROUND(100.0 * br.receita_total / NULLIF(t.receita_geral, 0), 2) AS pct_receita,
    br.valor_medio_por_km,
    br.distancia_media_km,
    br.duracao_media_min
FROM base_regional br
CROSS JOIN totais t
ORDER BY br.receita_total DESC;


-- ============================================================================
-- 10. ANALISE DE AVALIACOES E QUALIDADE
-- ============================================================================
-- Proposito: Correlacionar avaliacoes com outras metricas
-- Expectativa: Identificar fatores que influenciam satisfacao
-- Power BI: Scatter plot (avaliacao x valor) + Histograma
SELECT
    CASE 
        WHEN f.avaliacao_motorista >= 4.5 THEN 'Excelente (4.5-5.0)'
        WHEN f.avaliacao_motorista >= 4.0 THEN 'Bom (4.0-4.5)'
        WHEN f.avaliacao_motorista >= 3.5 THEN 'Regular (3.5-4.0)'
        ELSE 'Baixo (<3.5)'
    END AS faixa_avaliacao_motorista,
    COUNT(*) AS total_corridas,
    AVG(f.valor_corrida) AS valor_medio_corrida,
    AVG(f.distancia_km) AS distancia_media_km,
    AVG(f.duracao_minutos) AS duracao_media_min,
    AVG(f.avaliacao_cliente) AS avaliacao_cliente_media,
    SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) AS corridas_completas,
    ROUND(100.0 * SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS taxa_conclusao_pct
FROM dw.ft_crr f
WHERE f.avaliacao_motorista IS NOT NULL
GROUP BY faixa_avaliacao_motorista
ORDER BY 
    CASE faixa_avaliacao_motorista
        WHEN 'Excelente (4.5-5.0)' THEN 1
        WHEN 'Bom (4.0-4.5)' THEN 2
        WHEN 'Regular (3.5-4.0)' THEN 3
        WHEN 'Baixo (<3.5)' THEN 4
    END;


-- ============================================================================
-- 11. TENDENCIA MENSAL DE RECEITA E VOLUME
-- ============================================================================
-- Proposito: Analisar evolucao temporal de metricas chave
-- Expectativa: Identificar sazonalidade e tendencias de crescimento
-- Power BI: Grafico de linha temporal + Area chart
SELECT
    t.ano,
    t.mes,
    t.mes_ano,
    t.trimestre,
    COUNT(*) AS total_corridas,
    SUM(f.distancia_km) AS distancia_total_km,
    SUM(f.valor_corrida) AS receita_total,
    AVG(f.valor_por_km) AS valor_medio_por_km,
    AVG(f.avaliacao_motorista) AS avaliacao_motorista_media,
    SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) AS corridas_completas,
    ROUND(100.0 * SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS taxa_conclusao_pct
FROM dw.ft_crr f
JOIN dw.dim_tmp t ON f.tmp_srk = t.tmp_srk
GROUP BY t.ano, t.mes, t.mes_ano, t.trimestre
ORDER BY t.ano, t.mes;


-- ============================================================================
-- 12. TOP 10 LOCAIS DE ORIGEM COM MAIOR DEMANDA
-- ============================================================================
-- Proposito: Identificar pontos de alta demanda para otimizacao de frota
-- Expectativa: Concentrar veiculos em locais estrategicos
-- Power BI: Grafico de barras horizontais + Mapa de calor
SELECT
    lo.local AS local_origem,
    lo.zona AS zona_origem,
    lo.regiao AS regiao_origem,
    lo.tipo_area,
    COUNT(*) AS total_corridas,
    SUM(f.valor_corrida) AS receita_total,
    AVG(f.valor_por_km) AS valor_medio_por_km,
    AVG(f.distancia_km) AS distancia_media_km,
    SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) AS corridas_completas,
    ROUND(100.0 * SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS taxa_conclusao_pct
FROM dw.ft_crr f
JOIN dw.dim_loc lo ON f.loc_ori_srk = lo.loc_srk
GROUP BY lo.local, lo.zona, lo.regiao, lo.tipo_area
ORDER BY total_corridas DESC
LIMIT 10;


-- ============================================================================
-- FIM DAS CONSULTAS
-- ============================================================================
