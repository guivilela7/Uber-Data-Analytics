-- ============================================================================
-- GOLD LAYER: STAR SCHEMA - DDL
-- Business Objective: Uber Data Analytics - Ride pfm Analysis
-- ============================================================================


DROP SCHEMA IF EXISTS dw CASCADE;
CREATE SCHEMA dw;


COMMENT ON SCHEMA dw IS 'Camada Gold (DataWarverouse) - Dados agregados e otimizados para anl';


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
    ver_hrr_pic BOOLEAN
);


CREATE INDEX idx_tmp_dat ON dw.dim_tmp(dat);
CREATE INDEX idx_tmp_mes_ano ON dw.dim_tmp(mes_ano);
CREATE INDEX idx_tmp_trm ON dw.dim_tmp(ano_trm);
CREATE INDEX idx_tmp_prd ON dw.dim_tmp(prd_dia);


COMMENT ON TABLE dw.dim_tmp IS 'Dimensao Tempo - Hierarquia tpr para anls';
COMMENT ON COLUMN dw.dim_tmp.srk_tmp IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.dim_tmp.ver_fim_smn IS 'Indica se e sabado ou domingo';
COMMENT ON COLUMN dw.dim_tmp.prd_dia IS 'Perido do dia (Manha/Tarde/Noite/Madrugada)';
COMMENT ON COLUMN dw.dim_tmp.ver_hrr_pic IS 'Indica se e hrario de pic (7-10h ou 17-20h)';


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


COMMENT ON TABLE dw.dim_loc IS 'Dimensao lclizacao - Informacoes geograficas';
COMMENT ON COLUMN dw.dim_loc.srk_loc IS 'Chave primaria surrogate';
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
COMMENT ON COLUMN dw.dim_vei.srk_vei IS 'Chave primaria surrogate';
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
COMMENT ON COLUMN dw.dim_cli.srk_cli IS 'Chave primaria surrogate';
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
COMMENT ON COLUMN dw.dim_pag.srk_pag IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.dim_pag.ctg_pag IS 'Categoria (Digital, Cash)';


-- ============================================================================
-- TABELA FATO: CORRIDAS
-- ============================================================================
CREATE TABLE dw.fat_crr (
    srk_crr SERIAL PRIMARY KEY,
    
    srk_tmp INTEGER NOT NULL REFERENCES dw.dim_tmp(srk_tmp),
    srk_loc_ori INTEGER NOT NULL REFERENCES dw.dim_loc(srk_loc),
    srk_loc_dst INTEGER NOT NULL REFERENCES dw.dim_loc(srk_loc),
    srk_vei INTEGER NOT NULL REFERENCES dw.dim_vei(srk_vei),
    srk_cli INTEGER NOT NULL REFERENCES dw.dim_cli(srk_cli),
    srk_pag INTEGER NOT NULL REFERENCES dw.dim_pag(srk_pag),
    
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
    
    dat_hra_col TIMESTAMP,
    id_bok_org VARCHAR(50)
);


CREATE INDEX idx_fat_crr_tmp ON dw.fat_crr(srk_tmp);
CREATE INDEX idx_fat_crr_loc_ori ON dw.fat_crr(srk_loc_ori);
CREATE INDEX idx_fat_crr_loc_dst ON dw.fat_crr(srk_loc_dst);
CREATE INDEX idx_fat_crr_vei ON dw.fat_crr(srk_vei);
CREATE INDEX idx_fat_crr_cli ON dw.fat_crr(srk_cli);
CREATE INDEX idx_fat_crr_pag ON dw.fat_crr(srk_pag);
CREATE INDEX idx_fat_crr_vlr ON dw.fat_crr(vlr_crr);
CREATE INDEX idx_fat_crr_dtc ON dw.fat_crr(dtc_km);
CREATE INDEX idx_fat_crr_stt ON dw.fat_crr(stt_crr);
CREATE INDEX idx_fat_crr_bok ON dw.fat_crr(id_bok_org);


COMMENT ON TABLE dw.fat_crr IS 'Fato Corridas - Metricas de pfm de corridas';
COMMENT ON COLUMN dw.fat_crr.srk_crr IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.fat_crr.srk_tmp IS 'Chave estrangeira surrogate para dim_tmp';
COMMENT ON COLUMN dw.fat_crr.srk_loc_ori IS 'Chave estrangeira surrogate para dim_loc (org)';
COMMENT ON COLUMN dw.fat_crr.srk_loc_dst IS 'Chave estrangeira surrogate para dim_loc (dtn)';
COMMENT ON COLUMN dw.fat_crr.srk_vei IS 'Chave estrangeira surrogate para dim_vei';
COMMENT ON COLUMN dw.fat_crr.srk_cli IS 'Chave estrangeira surrogate para dim_cli';
COMMENT ON COLUMN dw.fat_crr.srk_pag IS 'Chave estrangeira surrogate para dim_pag';
COMMENT ON COLUMN dw.fat_crr.dtc_km IS 'Distancia da corrida em quilometros';
COMMENT ON COLUMN dw.fat_crr.drc_min IS 'Duracao da corrida em minutos';
COMMENT ON COLUMN dw.fat_crr.vlr_por_km IS 'Valor por quilometro (rentabilidade)';
COMMENT ON COLUMN dw.fat_crr.ver_rta_itr_rgl IS 'Indica se a rota cruza regioes diferentes';


-- ============================================================================
-- VIEWS ANALITICAS
-- ============================================================================


CREATE OR REPLACE VIEW dw.vw_rsm_zna AS
SELECT
    lo.zna AS zna_org,
    ld.zna AS zna_dtn,
    COUNT(*) AS ttl_crrs,
    SUM(f.dtc_km) AS dtc_ttl_km,
    SUM(f.vlr_crr) AS rct_ttl,
    AVG(f.vlr_por_km) AS vlr_mdo_por_km,
    AVG(f.drc_min) AS drc_mda_min,
    AVG(f.avl_mtr) AS avl_mtr_mda,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crrs_cpls,
    SUM(CASE WHEN f.ver_crr_cnl THEN 1 ELSE 0 END) AS crrs_cnls
FROM dw.fat_crr f
JOIN dw.dim_loc lo ON f.srk_loc_ori = lo.srk_loc
JOIN dw.dim_loc ld ON f.srk_loc_dst = ld.srk_loc
GROUP BY lo.zna, ld.zna
ORDER BY rct_ttl DESC;


CREATE OR REPLACE VIEW dw.vw_top_rtas AS
SELECT
    lo.lcl AS lcl_org,
    ld.lcl AS lcl_dtn,
    lo.zna AS zna_org,
    ld.zna AS zna_dtn,
    COUNT(*) AS ttl_crrs,
    SUM(f.vlr_crr) AS rct_ttl,
    AVG(f.vlr_por_km) AS vlr_mdo_por_km,
    AVG(f.dtc_km) AS dtc_mda_km,
    AVG(f.drc_min) AS drc_mda_min
FROM dw.fat_crr f
JOIN dw.dim_loc lo ON f.srk_loc_ori = lo.srk_loc
JOIN dw.dim_loc ld ON f.srk_loc_dst = ld.srk_loc
WHERE f.ver_crr_cpl = TRUE
GROUP BY lo.lcl, ld.lcl, lo.zna, ld.zna
ORDER BY rct_ttl DESC
LIMIT 100;


CREATE OR REPLACE VIEW dw.vw_pfm_tpr AS
SELECT
    t.ano,
    t.mes,
    t.mes_ano,
    t.trm,
    t.nme_dia_smn,
    t.prd_dia,
    COUNT(*) AS ttl_crrs,
    SUM(f.dtc_km) AS dtc_ttl_km,
    SUM(f.vlr_crr) AS rct_ttl,
    AVG(f.vlr_por_km) AS vlr_mdo_por_km,
    AVG(f.avl_mtr) AS avl_mtr_mda,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crrs_cpls
FROM dw.fat_crr f
JOIN dw.dim_tmp t ON f.srk_tmp = t.srk_tmp
GROUP BY t.ano, t.mes, t.mes_ano, t.trm, t.nme_dia_smn, t.prd_dia
ORDER BY t.ano, t.mes;


CREATE OR REPLACE VIEW dw.vw_anl_vei AS
SELECT
    v.tpo_vei,
    v.ctg_vei,
    COUNT(*) AS ttl_crrs,
    SUM(f.vlr_crr) AS rct_ttl,
    AVG(f.vlr_por_km) AS vlr_mdo_por_km,
    AVG(f.dtc_km) AS dtc_mda_km,
    AVG(f.avl_mtr) AS avl_mtr_mda,
    SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) AS crrs_cpls,
    ROUND(100.0 * SUM(CASE WHEN f.ver_crr_cpl THEN 1 ELSE 0 END) / COUNT(*), 2) AS txa_ccl_pct
FROM dw.fat_crr f
JOIN dw.dim_vei v ON f.srk_vei = v.srk_vei
GROUP BY v.tpo_vei, v.ctg_vei
ORDER BY rct_ttl DESC;


CREATE OR REPLACE VIEW dw.vw_perfil_cli AS
SELECT
    c.sgm_cli,
    COUNT(DISTINCT c.srk_cli) AS ttl_clis,
    COUNT(*) AS ttl_crrs,
    AVG(f.vlr_crr) AS vlr_mdo_crr,
    AVG(f.dtc_km) AS dtc_mda_km,
    SUM(f.vlr_crr) AS rct_ttl,
    AVG(f.avl_cli) AS avl_cli_mda
FROM dw.fat_crr f
JOIN dw.dim_cli c ON f.srk_cli = c.srk_cli
WHERE f.ver_crr_cpl = TRUE
GROUP BY c.sgm_cli
ORDER BY rct_ttl DESC;


-- ============================================================================
-- GRANTS (para BI)
-- ============================================================================

-- GRANT SELECT ON ALL TABLES IN SCHEMA dw TO powerbi_user;
-- GRANT SELECT ON ALL SEQUENCES IN SCHEMA dw TO powerbi_user;
-- GRANT USAGE ON SCHEMA dw TO powerbi_user;


-- ============================================================================
-- FIM DO DDL GOLD (DW)
-- ============================================================================
