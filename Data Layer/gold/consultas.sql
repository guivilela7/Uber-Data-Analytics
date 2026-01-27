-- ============================================================================
-- GOLD LAYER: CONSULTAS ANALITICAS
-- Queries para analise de performance de crr Uber
-- Proposito: Fornecer insights para dashboards Power BI
-- ============================================================================


-- ============================================================================
-- 1. VERIFICACAO DO SCHEMA DW
-- ============================================================================
-- Proposito: Validar integridade e contagem de registros em cada tabela
-- Expectativa: Verificar se todas as tabelas foram populadas corretamente
-- Power BI: Card com ttl de registros por tabela
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
SELECT 'fat_crr' AS tabela, COUNT(*) AS linhas FROM dw.fat_crr
ORDER BY tabela;


-- ============================================================================
-- 2. DESEMPENHO POR ZONA GEOGRAFICA
-- ============================================================================
-- Proposito: Medir volume, receita e rentabilidade por zona
-- Expectativa: Identificar zonas mais lucrativas e com maior demanda
-- Power BI: Grafico de barras (receita por zna) + Mapa de calor
SELECT
    lo.zna AS zna_org,
    ld.zna AS zna_dst,
    COUNT(*) AS ttl_crr,
    SUM(f.dtc_km) AS dtc_ttl_km,
    SUM(f.vlr_crr) AS rct_ttl,
    AVG(f.vlr_por_km) AS vlr_mdo_por_km,
    AVG(f.drc_min) AS drc_mda_min,
    AVG(f.avl_mtr) AS avl_mtr_mda,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crr_cpl,
    ROUND(100.0 * SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS txa_ccl_pct
FROM dw.fat_crr f
JOIN dw.dim_loc lo ON f.srk_loc_ori = lo.srk_loc
JOIN dw.dim_loc ld ON f.srk_loc_dst = ld.srk_loc
GROUP BY lo.zna, ld.zna
ORDER BY rct_ttl DESC;


-- ============================================================================
-- 3. TOP 20 ROTAS MAIS RENTAVEIS (CTE)
-- ============================================================================
-- Proposito: Descobrir rotas com melhor valor por km
-- Expectativa: Identificar rotas premium para otimizacao de frota
-- Power BI: Tabela com ranking de rotas + Grafico de dispersao
WITH bse_rta AS (
    SELECT
        lo.lcl AS lcl_org,
        ld.lcl AS lcl_dtn,
        lo.zna AS zna_org,
        ld.zna AS zna_dtn,
        lo.reg AS reg_org,
        ld.reg AS reg_dtn,
        COUNT(*) AS ttl_crr,
        SUM(f.vlr_crr) AS rct_ttl,
        AVG(f.vlr_por_km) AS vlr_mdo_por_km,
        AVG(f.dtc_km) AS dtc_mda_km,
        AVG(f.drc_min) AS drc_mda_min
    FROM dw.fat_crr f
    JOIN dw.dim_loc lo ON f.srk_loc_ori = lo.srk_loc
    JOIN dw.dim_loc ld ON f.srk_loc_dst = ld.srk_loc
    WHERE f.ver_crr_cpl = TRUE
    GROUP BY lo.lcl, ld.lcl, lo.zna, ld.zna, lo.reg, ld.reg
),
rnk_rta AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY vlr_mdo_por_km DESC) AS pos_rnt,
        SUM(rct_ttl) OVER () AS rct_grl
    FROM bse_rta
    WHERE ttl_crr >= 10
)
SELECT
    lcl_org,
    lcl_dtn,
    zna_org,
    zna_dtn,
    reg_org,
    reg_dtn,
    ttl_crr,
    rct_ttl,
    vlr_mdo_por_km,
    dtc_mda_km,
    drc_mda_min,
    ROUND(100.0 * rct_ttl / NULLIF(rct_grl, 0), 2) AS pct_rct_grl
FROM rnk_rta
WHERE pos_rnt <= 20
ORDER BY pos_rnt;

-- ============================================================================
-- 4. PERFORMANCE TEMPORAL POR PERIODO DO DIA
-- ============================================================================
-- Proposito: Analisar padroes de demanda por periodo e dia da semana
-- Expectativa: Identificar horarios de pico e oportunidades de otimizacao
-- Power BI: Grafico de linha (receita por hora) + Matriz (dia x periodo)
SELECT
    t.nme_dia_smn,
    t.prd_dia,
    t.ver_hrr_pic,
    COUNT(*) AS ttl_crr,
    SUM(f.dtc_km) AS dtc_ttl_km,
    SUM(f.vlr_crr) AS rct_ttl,
    AVG(f.vlr_por_km) AS vlr_mdo_por_km,
    AVG(f.avl_mtr) AS avl_mtr_mda,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crr_cpl,
    ROUND(100.0 * SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS txa_ccl_pct
FROM dw.fat_crr f
JOIN dw.dim_tmp t ON f.srk_tmp = t.srk_tmp
GROUP BY t.nme_dia_smn, t.prd_dia, t.ver_hrr_pic
ORDER BY 
    CASE t.nme_dia_smn
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END,
    CASE t.prd_dia
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
    v.ctg_vei,
    v.tpo_vei,
    COUNT(*) AS ttl_crr,
    SUM(f.vlr_crr) AS rct_ttl,
    AVG(f.vlr_por_km) AS vlr_mdo_por_km,
    AVG(f.dtc_km) AS dtc_mda_km,
    AVG(f.drc_min) AS drc_mda_min,
    AVG(f.avl_mtr) AS avl_mtr_mda,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crr_cpl,
    ROUND(100.0 * SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS txa_ccl_pct
FROM dw.fat_crr f
JOIN dw.dim_vei v ON f.srk_vei = v.srk_vei
GROUP BY v.ctg_vei, v.tpo_vei
ORDER BY rct_ttl DESC;

-- ============================================================================
-- 6. PERFIL E SEGMENTACAO DE CLIENTES (CTE)
-- ============================================================================
-- Proposito: Analisar comportamento e valor por segmento de cliente
-- Expectativa: Identificar clientes VIP e oportunidades de fidelizacao
-- Power BI: Grafico de pizza (distribuicao de clientes) + Funil de segmentos
WITH bse_cli AS (
    SELECT
        c.sgm_cli,
        COUNT(DISTINCT c.srk_cli) AS ttl_cli,
        COUNT(*) AS ttl_crr,
        AVG(f.vlr_crr) AS vlr_mdo_crr,
        AVG(f.dtc_km) AS dtc_mda_km,
        SUM(f.vlr_crr) AS rct_ttl,
        AVG(f.avl_cli) AS avl_cli_mda
    FROM dw.fat_crr f
    JOIN dw.dim_cli c ON f.srk_cli = c.srk_cli
    WHERE f.ver_crr_cpl = TRUE
    GROUP BY c.sgm_cli
),
tts AS (
    SELECT 
        SUM(rct_ttl) AS rct_grl,
        SUM(ttl_cli) AS cli_grl
    FROM bse_cli
)
SELECT
    bc.sgm_cli,
    bc.ttl_cli,
    ROUND(100.0 * bc.ttl_cli / NULLIF(t.cli_grl, 0), 2) AS pct_cli,
    bc.ttl_crr,
    ROUND(bc.ttl_crr::NUMERIC / NULLIF(bc.ttl_cli, 0), 2) AS crr_por_cli,
    bc.vlr_mdo_crr,
    bc.dtc_mda_km,
    bc.rct_ttl,
    ROUND(100.0 * bc.rct_ttl / NULLIF(t.rct_grl, 0), 2) AS pct_rct,
    bc.avl_cli_mda
FROM bse_cli bc
CROSS JOIN tts t
ORDER BY bc.rct_ttl DESC;


-- ============================================================================
-- 7. ANALISE DE METODOS DE PAGAMENTO
-- ============================================================================
-- Proposito: Comparar preferencias e valores por metodo de pagamento
-- Expectativa: Identificar tendencias de digitalizacao e ticket medio
-- Power BI: Grafico de rosca (distribuicao) + Barras (valor medio)
SELECT
    p.ctg_pag,
    p.mtd_pag,
    COUNT(*) AS ttl_crr,
    SUM(f.vlr_crr) AS rct_ttl,
    AVG(f.vlr_crr) AS vlr_mdo_crr,
    AVG(f.dtc_km) AS dtc_mda_km,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crr_cpl,
    ROUND(100.0 * SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS txa_ccl_pct
FROM dw.fat_crr f
JOIN dw.dim_pag p ON f.srk_pag = p.srk_pag
GROUP BY p.ctg_pag, p.mtd_pag
ORDER BY rct_ttl DESC;


-- ============================================================================
-- 8. ANALISE DE DISTANCIA POR CATEGORIA
-- ============================================================================
-- Proposito: Avaliar rentabilidade e demanda por categoria de distancia
-- Expectativa: Identificar categorias mais lucrativas (curta/media/longa)
-- Power BI: Grafico de barras agrupadas + Cards com metricas
SELECT
    f.ctg_dtc,
    COUNT(*) AS ttl_crr,
    SUM(f.vlr_crr) AS rct_ttl,
    AVG(f.vlr_crr) AS vlr_mdo_crr,
    AVG(f.dtc_km) AS dtc_mda_km,
    AVG(f.drc_min) AS drc_mda_min,
    AVG(f.avl_mtr) AS avl_mtr_mda,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crr_cpl,
    ROUND(100.0 * SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS txa_ccl_pct
FROM dw.fat_crr f
WHERE f.ctg_dtc IS NOT NULL
GROUP BY f.ctg_dtc
ORDER BY 
    CASE f.ctg_dtc
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
WITH bse_rgl AS (
    SELECT
        CASE WHEN f.ver_rta_itr_rgl THEN 'Inter-Regional' ELSE 'Intra-Regional' END AS tpo_rta,
        lo.reg AS reg_org,
        ld.reg AS reg_dtn,
        COUNT(*) AS ttl_crr,
        SUM(f.vlr_crr) AS rct_ttl,
        AVG(f.vlr_crr) AS vlr_mdo_crr,
        AVG(f.dtc_km) AS dtc_mda_km,
        AVG(f.drc_min) AS drc_mda_min
    FROM dw.fat_crr f
    JOIN dw.dim_loc lo ON f.srk_loc_ori = lo.srk_loc
    JOIN dw.dim_loc ld ON f.srk_loc_dst = ld.srk_loc
    WHERE f.ver_crr_cpl = TRUE
    GROUP BY tpo_rta, reg_org, reg_dtn
),
tts AS (
    SELECT SUM(rct_ttl) AS rct_grl FROM bse_rgl
)
SELECT
    br.tpo_rta,
    br.reg_org,
    br.reg_dtn,
    br.ttl_crr,
    br.rct_ttl,
    ROUND(100.0 * br.rct_ttl / NULLIF(t.rct_grl, 0), 2) AS pct_rct,
    br.vlr_mdo_crr,
    br.dtc_mda_km,
    br.drc_mda_min
FROM bse_rgl br
CROSS JOIN tts t
ORDER BY br.rct_ttl DESC;


-- ============================================================================
-- 10. ANALISE DE AVALIACOES E QUALIDADE
-- ============================================================================
-- Proposito: Correlacionar avaliacoes com outras metricas
-- Expectativa: Identificar fatores que influenciam satisfacao
-- Power BI: Scatter plot (avaliacao x valor) + Histograma
SELECT
    CASE 
        WHEN f.avl_mtr >= 4.5 THEN 'Excelente (4.5-5.0)'
        WHEN f.avl_mtr >= 4.0 THEN 'Bom (4.0-4.5)'
        WHEN f.avl_mtr >= 3.5 THEN 'Regular (3.5-4.0)'
        ELSE 'Baixo (<3.5)'
    END AS fxa_avl_mtr,
    COUNT(*) AS ttl_crr,
    AVG(f.vlr_crr) AS vlr_mdo_crr,
    AVG(f.dtc_km) AS dtc_mda_km,
    AVG(f.drc_min) AS drc_mda_min,
    AVG(f.avl_cli) AS avl_cli_mda,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crr_cpl,
    ROUND(100.0 * SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS txa_ccl_pct
FROM dw.fat_crr f
WHERE f.avl_mtr IS NOT NULL
GROUP BY fxa_avl_mtr
ORDER BY 1;


-- ============================================================================
-- 11. TENDENCIA MENSAL DE RECEITA E VOLUME
-- ============================================================================
-- Proposito: Analisar evolucao temporal de metricas chave
-- Expectativa: Identificar saznalidade e tendencias de crescimento
-- Power BI: Grafico de linha temporal + Area chart
SELECT
    t.ano,
    t.mes,
    t.mes_ano,
    t.trm,
    COUNT(*) AS ttl_crr,
    SUM(f.dtc_km) AS dtc_ttl_km,
    SUM(f.vlr_crr) AS rct_ttl,
    AVG(f.vlr_por_km) AS vlr_mdo_por_km,
    AVG(f.avl_mtr) AS avl_mtr_mda,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crr_cpl,
    ROUND(100.0 * SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS txa_ccl_pct
FROM dw.fat_crr f
JOIN dw.dim_tmp t ON f.srk_tmp = t.srk_tmp
GROUP BY t.ano, t.mes, t.mes_ano, t.trm
ORDER BY t.ano, t.mes;


-- ============================================================================
-- 12. TOP 10 LOCAIS DE org COM MAIOR DEMANDA
-- ============================================================================
-- Proposito: Identificar pontos de alta demanda para otimizacao de frota
-- Expectativa: Concentrar veiculos em locais estrategicos
-- Power BI: Grafico de barras horizontais + Mapa de calor
SELECT
    lo.lcl AS lcl_org,
    lo.zna AS zna_org,
    lo.reg AS reg_org,
    lo.tpo_ara AS tpo_ara_org,
    COUNT(*) AS ttl_crr,
    SUM(f.vlr_crr) AS rct_ttl,
    AVG(f.vlr_por_km) AS vlr_mdo_por_km,
    AVG(f.dtc_km) AS dtc_mda_km,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crr_cpl,
    ROUND(100.0 * SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) / 
          NULLIF(COUNT(*), 0), 2) AS txa_ccl_pct
FROM dw.fat_crr f
JOIN dw.dim_loc lo ON f.srk_loc_ori = lo.srk_loc
GROUP BY lo.lcl, lo.zna, lo.reg, lo.tpo_ara
ORDER BY ttl_crr DESC
LIMIT 10;


-- ============================================================================
-- FIM DAS CONSULTAS
-- ============================================================================