-- ============================================================================
-- GOLD LAYER: STAR SCHEMA - DDL
-- Business Objective: Uber Data Analytics - Ride Performance Analysis
-- ============================================================================


DROP SCHEMA IF EXISTS dw CASCADE;
CREATE SCHEMA dw;


COMMENT ON SCHEMA dw IS 'Camada Gold (DataWarverouse) - Dados agregados e otimizados para analise';


-- ============================================================================
-- DIMENSAO 1: TEMPO
-- ============================================================================
CREATE TABLE dw.dim_tmp (
    srk_tmp SERIAL PRIMARY KEY,
    dat DATE NOT NULL UNIQUE,
    ano INTEGER,
    mes INTEGER,
    dia INTEGER,
    dia_smn INTEGER,
    nme_dia_smn VARCHAR(10),
    trm INTEGER,
    smn_ano INTEGER,
    ver_fim_smn BOOLEAN,
    mes_ano VARCHAR(7),
    ano_trm VARCHAR(7),
    prd_dia VARCHAR(10),
    ver_hrr_pico BOOLEAN
);


CREATE INDEX idx_tmp_dat ON dw.dim_tmp(dat);
CREATE INDEX idx_tmp_mes_ano ON dw.dim_tmp(mes_ano);
CREATE INDEX idx_tmp_trm ON dw.dim_tmp(ano_trm);
CREATE INDEX idx_tmp_prd ON dw.dim_tmp(prd_dia);


COMMENT ON TABLE dw.dim_tmp IS 'Dimensao Tempo - Hierarquia temporal para analises';
COMMENT ON COLUMN dw.dim_tmp.tmp_srk IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.dim_tmp.ver_fim_smn IS 'Indica se e sabado ou domingo';
COMMENT ON COLUMN dw.dim_tmp.prd_dia IS 'Perido do dia (Manha/Tarde/Noite/Madrugada)';
COMMENT ON COLUMN dw.dim_tmp.ver_hrr_pico IS 'Indica se e hrario de pico (7-10h ou 17-20h)';


-- ============================================================================
-- DIMENSAO 2: LOCALIZACAO
-- ============================================================================
CREATE TABLE dw.dim_loc (
    srk_loc SERIAL PRIMARY KEY,
    lcl VARCHAR(100) NOT NULL UNIQUE,
    zna VARCHAR(50),
    reg VARCHAR(50),
    tpo_ara VARCHAR(30)
);


CREATE INDEX idx_loc_lcl ON dw.dim_loc(lcl);
CREATE INDEX idx_loc_zna ON dw.dim_loc(zna);
CREATE INDEX idx_loc_reg ON dw.dim_loc(reg);


COMMENT ON TABLE dw.dim_loc IS 'Dimensao Localizacao - Informacoes geograficas';
COMMENT ON COLUMN dw.dim_loc.loc_srk IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.dim_loc.zna IS 'Zona geografica (South Delhi, NCR-Gurgaon, etc.)';
COMMENT ON COLUMN dw.dim_loc.reg IS 'Regiao (Delhi, NCR, Special Zone)';
COMMENT ON COLUMN dw.dim_loc.tpo_ara IS 'Tipo de area (Residencial, Comercial, Aeroporto)';


-- ============================================================================
-- DIMENSAO 3: VEICULO
-- ============================================================================
CREATE TABLE dw.dim_vei (
    srk_vei SERIAL PRIMARY KEY,
    tpo_vei VARCHAR(50) NOT NULL UNIQUE,
    ctg_vei VARCHAR(30)
);


CREATE INDEX idx_vei_tpo ON dw.dim_vei(tpo_vei);
CREATE INDEX idx_vei_ctg ON dw.dim_vei(ctg_vei);


COMMENT ON TABLE dw.dim_vei IS 'Dimensao Veiculo - tipos e categorias de veiculos';
COMMENT ON COLUMN dw.dim_vei.vei_srk IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.dim_vei.ctg_vei IS 'Categoria (Economy, Premium, Luxury)';


-- ============================================================================
-- DIMENSAO 4: CLIENTE
-- ============================================================================
CREATE TABLE dw.dim_cli (
    srk_cli SERIAL PRIMARY KEY,
    id_cli VARCHAR(50) NOT NULL UNIQUE,
    sgm_cli VARCHAR(30),
    ttl_vig_hst INTEGER
);


CREATE INDEX idx_cli_id ON dw.dim_cli(id_cli);
CREATE INDEX idx_cli_sgm ON dw.dim_cli(sgm_cli);


COMMENT ON TABLE dw.dim_cli IS 'Dimensao Cliente - Perfil dos clients';
COMMENT ON COLUMN dw.dim_cli.cli_srk IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.dim_cli.sgm_cli IS 'Segmento (Occasional, Regular, VIP)';


-- ============================================================================
-- DIMENSAO 5: PAGAMENTO
-- ============================================================================
CREATE TABLE dw.dim_pag (
    srk_pag SERIAL PRIMARY KEY,
    mtd_pag VARCHAR(50) NOT NULL UNIQUE,
    ctg_pag VARCHAR(30)
);


CREATE INDEX idx_pag_mtd ON dw.dim_pag(mtd_pag);
CREATE INDEX idx_pag_ctg ON dw.dim_pag(ctg_pag);


COMMENT ON TABLE dw.dim_pag IS 'Dimensao Pagamento - metodos de pagamento';
COMMENT ON COLUMN dw.dim_pag.pag_srk IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.dim_pag.ctg_pag IS 'Categoria (Digital, Cash)';


-- ============================================================================
-- TABELA FATO: CORRIDAS
-- ============================================================================
CREATE TABLE dw.fat_crr (
    crr_srk SERIAL PRIMARY KEY,
    
    tmp_srk INTEGER NOT NULL REFERENCES dw.dim_tmp(tmp_srk),
    loc_ori_srk INTEGER NOT NULL REFERENCES dw.dim_loc(loc_srk),
    loc_dst_srk INTEGER NOT NULL REFERENCES dw.dim_loc(loc_srk),
    vei_srk INTEGER NOT NULL REFERENCES dw.dim_vei(vei_srk),
    cli_srk INTEGER NOT NULL REFERENCES dw.dim_cli(cli_srk),
    pag_srk INTEGER NOT NULL REFERENCES dw.dim_pag(pag_srk),
    
    dtc_km NUMERIC(10,2),
    drc_min INTEGER,
    vlr_crr NUMERIC(10,2),
    vlr_por_km NUMERIC(10,2),
    avl_mtr NUMERIC(3,2),
    avl_cli NUMERIC(3,2),
    stt_crr VARCHAR(30),
    ctg_dtc VARCHAR(20),
    
    ver_crr_cpl BOOLEAN,
    ver_crr_cnl BOOLEAN,
    ver_rta_itr_rgl BOOLEAN,
    
    dat_hra_clt TIMESTAMP,
    id_bok_org VARCHAR(50)
);


CREATE INDEX idx_fat_crr_tmp ON dw.fat_crr(tmp_srk);
CREATE INDEX idx_fat_crr_loc_ori ON dw.fat_crr(loc_ori_srk);
CREATE INDEX idx_fat_crr_loc_dst ON dw.fat_crr(loc_dst_srk);
CREATE INDEX idx_fat_crr_vei ON dw.fat_crr(vei_srk);
CREATE INDEX idx_fat_crr_cli ON dw.fat_crr(cli_srk);
CREATE INDEX idx_fat_crr_pag ON dw.fat_crr(pag_srk);
CREATE INDEX idx_fat_crr_vlr ON dw.fat_crr(vlr_crr);
CREATE INDEX idx_fat_crr_dtc ON dw.fat_crr(dtc_km);
CREATE INDEX idx_fat_crr_stt ON dw.fat_crr(stt_crr);
CREATE INDEX idx_fat_crr_bok ON dw.fat_crr(id_bok_org);


COMMENT ON TABLE dw.fat_crr IS 'Fato Corridas - Metricas de performance de corridas';
COMMENT ON COLUMN dw.fat_crr.crr_srk IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.fat_crr.tmp_srk IS 'Chave estrangeira surrogate para dim_tmp';
COMMENT ON COLUMN dw.fat_crr.loc_ori_srk IS 'Chave estrangeira surrogate para dim_loc (origem)';
COMMENT ON COLUMN dw.fat_crr.loc_dst_srk IS 'Chave estrangeira surrogate para dim_loc (destino)';
COMMENT ON COLUMN dw.fat_crr.vei_srk IS 'Chave estrangeira surrogate para dim_vei';
COMMENT ON COLUMN dw.fat_crr.cli_srk IS 'Chave estrangeira surrogate para dim_cli';
COMMENT ON COLUMN dw.fat_crr.pag_srk IS 'Chave estrangeira surrogate para dim_pag';
COMMENT ON COLUMN dw.fat_crr.dtc_km IS 'Distancia da corrida em quilometros';
COMMENT ON COLUMN dw.fat_crr.drc_min IS 'Duracao da corrida em minutos';
COMMENT ON COLUMN dw.fat_crr.vlr_por_km IS 'Valor por quilometro (rentabilidade)';
COMMENT ON COLUMN dw.fat_crr.ver_rta_itr_rgl IS 'Indica se a rota cruza regioes diferentes';


-- ============================================================================
-- VIEWS ANALITICAS
-- ============================================================================


CREATE OR REPLACE VIEW dw.vw_resumo_zna AS
SELECT
    lo.zna AS zna_origem,
    ld.zna AS zna_destino,
    COUNT(*) AS ttl_crrs,
    SUM(f.dtc_km) AS dtc_ttl_km,
    SUM(f.vlr_crr) AS receita_ttl,
    AVG(f.vlr_por_km) AS vlr_medio_por_km,
    AVG(f.drc_min) AS drc_media_min,
    AVG(f.avl_mtr) AS avl_mtr_media,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crrs_cpls,
    SUM(CASE WHEN f.ver_crr_cnl THEN 1 ELSE 0 END) AS crrs_cnls
FROM dw.fat_crr f
JOIN dw.dim_loc lo ON f.loc_ori_srk = lo.loc_srk
JOIN dw.dim_loc ld ON f.loc_dst_srk = ld.loc_srk
GROUP BY lo.zna, ld.zna
ORDER BY receita_ttl DESC;


CREATE OR REPLACE VIEW dw.vw_top_rtas AS
SELECT
    lo.local AS local_origem,
    ld.local AS local_destino,
    lo.zna AS zna_origem,
    ld.zna AS zna_destino,
    COUNT(*) AS ttl_crrs,
    SUM(f.vlr_crr) AS receita_ttl,
    AVG(f.vlr_por_km) AS vlr_medio_por_km,
    AVG(f.dtc_km) AS dtc_media_km,
    AVG(f.drc_min) AS drc_media_min
FROM dw.fat_crr f
JOIN dw.dim_loc lo ON f.loc_ori_srk = lo.loc_srk
JOIN dw.dim_loc ld ON f.loc_dst_srk = ld.loc_srk
WHERE f.ver_crr_cpl = TRUE
GROUP BY lo.local, ld.local, lo.zna, ld.zna
ORDER BY receita_ttl DESC
LIMIT 100;


CREATE OR REPLACE VIEW dw.vw_performance_temporal AS
SELECT
    t.ano,
    t.mes,
    t.mes_ano,
    t.trm,
    t.nme_dia_smn,
    t.prd_dia,
    COUNT(*) AS ttl_crrs,
    SUM(f.dtc_km) AS dtc_ttl_km,
    SUM(f.vlr_crr) AS receita_ttl,
    AVG(f.vlr_por_km) AS vlr_medio_por_km,
    AVG(f.avl_mtr) AS avl_mtr_media,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crrs_cpls
FROM dw.fat_crr f
JOIN dw.dim_tmp t ON f.tmp_srk = t.tmp_srk
GROUP BY t.ano, t.mes, t.mes_ano, t.trm, t.nme_dia_smn, t.prd_dia
ORDER BY t.ano, t.mes;


CREATE OR REPLACE VIEW dw.vw_analise_vei AS
SELECT
    v.tpo_vei,
    v.ctg_vei,
    COUNT(*) AS ttl_crrs,
    SUM(f.vlr_crr) AS receita_ttl,
    AVG(f.vlr_por_km) AS vlr_medio_por_km,
    AVG(f.dtc_km) AS dtc_media_km,
    AVG(f.avl_mtr) AS avl_mtr_media,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crrs_cpls,
    ROUND(100.0 * SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) / COUNT(*), 2) AS taxa_conclusao_pct
FROM dw.fat_crr f
JOIN dw.dim_vei v ON f.vei_srk = v.vei_srk
GROUP BY v.tpo_vei, v.ctg_vei
ORDER BY receita_ttl DESC;


CREATE OR REPLACE VIEW dw.vw_perfil_cli AS
SELECT
    c.sgm_cli,
    COUNT(DISTINCT c.cli_srk) AS ttl_clis,
    COUNT(*) AS ttl_crrs,
    AVG(f.vlr_crr) AS vlr_medio_crr,
    AVG(f.dtc_km) AS dtc_media_km,
    SUM(f.vlr_crr) AS receita_ttl,
    AVG(f.avl_cli) AS avl_cli_media
FROM dw.fat_crr f
JOIN dw.dim_cli c ON f.cli_srk = c.cli_srk
WHERE f.ver_crr_cpl = TRUE
GROUP BY c.sgm_cli
ORDER BY receita_ttl DESC;


-- ============================================================================
-- GRANTS (para BI)
-- ============================================================================

GRANT SELECT ON ALL TABLES IN SCHEMA dw TO powerbi_user;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA dw TO powerbi_user;
GRANT USAGE ON SCHEMA dw TO powerbi_user;


-- ============================================================================
-- FIM DO DDL GOLD (DW)
-- ============================================================================
