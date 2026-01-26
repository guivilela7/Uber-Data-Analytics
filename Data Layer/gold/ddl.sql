-- ============================================================================
-- GOLD LAYER: STAR SCHEMA - DDL
-- Business Objective: Uber Data Analytics - Ride Performance Analysis
-- ============================================================================


DROP SCHEMA IF EXISTS dw CASCADE;
CREATE SCHEMA dw;


COMMENT ON SCHEMA dw IS 'Camada Gold (DW) - Dados agregados e otimizados para analise';


-- ============================================================================
-- DIMENSION 1: TEMPO
-- ============================================================================
CREATE TABLE dw.dim_tmp (
    tmp_srk SERIAL PRIMARY KEY,
    data DATE NOT NULL UNIQUE,
    ano INTEGER,
    mes INTEGER,
    dia INTEGER,
    dia_semana INTEGER,
    nome_dia_semana VARCHAR(10),
    trimestre INTEGER,
    semana_ano INTEGER,
    eh_fim_semana BOOLEAN,
    mes_ano VARCHAR(7),
    ano_trimestre VARCHAR(7),
    periodo_dia VARCHAR(10),
    eh_horario_pico BOOLEAN
);


CREATE INDEX idx_tmp_data ON dw.dim_tmp(data);
CREATE INDEX idx_tmp_mes_ano ON dw.dim_tmp(mes_ano);
CREATE INDEX idx_tmp_trimestre ON dw.dim_tmp(ano_trimestre);
CREATE INDEX idx_tmp_periodo ON dw.dim_tmp(periodo_dia);


COMMENT ON TABLE dw.dim_tmp IS 'Dimensao Tempo - Hierarquia temporal para analises';
COMMENT ON COLUMN dw.dim_tmp.tmp_srk IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.dim_tmp.eh_fim_semana IS 'Indica se e sabado ou domingo';
COMMENT ON COLUMN dw.dim_tmp.periodo_dia IS 'Periodo do dia (Manha/Tarde/Noite/Madrugada)';
COMMENT ON COLUMN dw.dim_tmp.eh_horario_pico IS 'Indica se e horario de pico (7-10h ou 17-20h)';


-- ============================================================================
-- DIMENSION 2: LOCALIZACAO
-- ============================================================================
CREATE TABLE dw.dim_loc (
    loc_srk SERIAL PRIMARY KEY,
    local VARCHAR(100) NOT NULL UNIQUE,
    zona VARCHAR(50),
    regiao VARCHAR(50),
    tipo_area VARCHAR(30)
);


CREATE INDEX idx_loc_local ON dw.dim_loc(local);
CREATE INDEX idx_loc_zona ON dw.dim_loc(zona);
CREATE INDEX idx_loc_regiao ON dw.dim_loc(regiao);


COMMENT ON TABLE dw.dim_loc IS 'Dimensao Localizacao - Informacoes geograficas';
COMMENT ON COLUMN dw.dim_loc.loc_srk IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.dim_loc.zona IS 'Zona geografica (South Delhi, NCR-Gurgaon, etc.)';
COMMENT ON COLUMN dw.dim_loc.regiao IS 'Regiao (Delhi, NCR, Special Zone)';
COMMENT ON COLUMN dw.dim_loc.tipo_area IS 'Tipo de area (Residencial, Comercial, Aeroporto)';


-- ============================================================================
-- DIMENSION 3: VEICULO
-- ============================================================================
CREATE TABLE dw.dim_vei (
    vei_srk SERIAL PRIMARY KEY,
    tipo_veiculo VARCHAR(50) NOT NULL UNIQUE,
    categoria_veiculo VARCHAR(30)
);


CREATE INDEX idx_vei_tipo ON dw.dim_vei(tipo_veiculo);
CREATE INDEX idx_vei_categoria ON dw.dim_vei(categoria_veiculo);


COMMENT ON TABLE dw.dim_vei IS 'Dimensao Veiculo - Tipos e categorias de veiculos';
COMMENT ON COLUMN dw.dim_vei.vei_srk IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.dim_vei.categoria_veiculo IS 'Categoria (Economy, Premium, Luxury)';


-- ============================================================================
-- DIMENSION 4: CLIENTE
-- ============================================================================
CREATE TABLE dw.dim_cli (
    cli_srk SERIAL PRIMARY KEY,
    id_cliente VARCHAR(50) NOT NULL UNIQUE,
    segmento_cliente VARCHAR(30),
    total_viagens_historico INTEGER
);


CREATE INDEX idx_cli_id ON dw.dim_cli(id_cliente);
CREATE INDEX idx_cli_segmento ON dw.dim_cli(segmento_cliente);


COMMENT ON TABLE dw.dim_cli IS 'Dimensao Cliente - Perfil dos clientes';
COMMENT ON COLUMN dw.dim_cli.cli_srk IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.dim_cli.segmento_cliente IS 'Segmento (Occasional, Regular, VIP)';


-- ============================================================================
-- DIMENSION 5: PAGAMENTO
-- ============================================================================
CREATE TABLE dw.dim_pag (
    pag_srk SERIAL PRIMARY KEY,
    metodo_pagamento VARCHAR(50) NOT NULL UNIQUE,
    categoria_pagamento VARCHAR(30)
);


CREATE INDEX idx_pag_metodo ON dw.dim_pag(metodo_pagamento);
CREATE INDEX idx_pag_categoria ON dw.dim_pag(categoria_pagamento);


COMMENT ON TABLE dw.dim_pag IS 'Dimensao Pagamento - Metodos de pagamento';
COMMENT ON COLUMN dw.dim_pag.pag_srk IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.dim_pag.categoria_pagamento IS 'Categoria (Digital, Cash)';


-- ============================================================================
-- FACT TABLE: CORRIDAS
-- ============================================================================
CREATE TABLE dw.ft_crr (
    crr_srk SERIAL PRIMARY KEY,
    
    tmp_srk INTEGER NOT NULL REFERENCES dw.dim_tmp(tmp_srk),
    loc_ori_srk INTEGER NOT NULL REFERENCES dw.dim_loc(loc_srk),
    loc_dst_srk INTEGER NOT NULL REFERENCES dw.dim_loc(loc_srk),
    vei_srk INTEGER NOT NULL REFERENCES dw.dim_vei(vei_srk),
    cli_srk INTEGER NOT NULL REFERENCES dw.dim_cli(cli_srk),
    pag_srk INTEGER NOT NULL REFERENCES dw.dim_pag(pag_srk),
    
    distancia_km NUMERIC(10,2),
    duracao_minutos INTEGER,
    valor_corrida NUMERIC(10,2),
    valor_por_km NUMERIC(10,2),
    avaliacao_motorista NUMERIC(3,2),
    avaliacao_cliente NUMERIC(3,2),
    status_corrida VARCHAR(30),
    categoria_distancia VARCHAR(20),
    
    eh_corrida_completa BOOLEAN,
    eh_corrida_cancelada BOOLEAN,
    eh_rota_inter_regional BOOLEAN,
    
    data_hora_coleta TIMESTAMP,
    id_booking_original VARCHAR(50)
);


CREATE INDEX idx_ft_crr_tmp ON dw.ft_crr(tmp_srk);
CREATE INDEX idx_ft_crr_loc_ori ON dw.ft_crr(loc_ori_srk);
CREATE INDEX idx_ft_crr_loc_dst ON dw.ft_crr(loc_dst_srk);
CREATE INDEX idx_ft_crr_vei ON dw.ft_crr(vei_srk);
CREATE INDEX idx_ft_crr_cli ON dw.ft_crr(cli_srk);
CREATE INDEX idx_ft_crr_pag ON dw.ft_crr(pag_srk);
CREATE INDEX idx_ft_crr_valor ON dw.ft_crr(valor_corrida);
CREATE INDEX idx_ft_crr_distancia ON dw.ft_crr(distancia_km);
CREATE INDEX idx_ft_crr_status ON dw.ft_crr(status_corrida);
CREATE INDEX idx_ft_crr_booking ON dw.ft_crr(id_booking_original);


COMMENT ON TABLE dw.ft_crr IS 'Fato Corridas - Metricas de performance de corridas';
COMMENT ON COLUMN dw.ft_crr.crr_srk IS 'Chave primaria surrogate';
COMMENT ON COLUMN dw.ft_crr.tmp_srk IS 'Chave estrangeira surrogate para dim_tmp';
COMMENT ON COLUMN dw.ft_crr.loc_ori_srk IS 'Chave estrangeira surrogate para dim_loc (origem)';
COMMENT ON COLUMN dw.ft_crr.loc_dst_srk IS 'Chave estrangeira surrogate para dim_loc (destino)';
COMMENT ON COLUMN dw.ft_crr.vei_srk IS 'Chave estrangeira surrogate para dim_vei';
COMMENT ON COLUMN dw.ft_crr.cli_srk IS 'Chave estrangeira surrogate para dim_cli';
COMMENT ON COLUMN dw.ft_crr.pag_srk IS 'Chave estrangeira surrogate para dim_pag';
COMMENT ON COLUMN dw.ft_crr.distancia_km IS 'Distancia da corrida em quilometros';
COMMENT ON COLUMN dw.ft_crr.duracao_minutos IS 'Duracao da corrida em minutos';
COMMENT ON COLUMN dw.ft_crr.valor_por_km IS 'Valor por quilometro (rentabilidade)';
COMMENT ON COLUMN dw.ft_crr.eh_rota_inter_regional IS 'Indica se a rota cruza regioes diferentes';


-- ============================================================================
-- VIEWS ANALITICAS
-- ============================================================================


CREATE OR REPLACE VIEW dw.vw_resumo_zona AS
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
    SUM(CASE WHEN f.eh_corrida_cancelada THEN 1 ELSE 0 END) AS corridas_canceladas
FROM dw.ft_crr f
JOIN dw.dim_loc lo ON f.loc_ori_srk = lo.loc_srk
JOIN dw.dim_loc ld ON f.loc_dst_srk = ld.loc_srk
GROUP BY lo.zona, ld.zona
ORDER BY receita_total DESC;


CREATE OR REPLACE VIEW dw.vw_top_rotas AS
SELECT
    lo.local AS local_origem,
    ld.local AS local_destino,
    lo.zona AS zona_origem,
    ld.zona AS zona_destino,
    COUNT(*) AS total_corridas,
    SUM(f.valor_corrida) AS receita_total,
    AVG(f.valor_por_km) AS valor_medio_por_km,
    AVG(f.distancia_km) AS distancia_media_km,
    AVG(f.duracao_minutos) AS duracao_media_min
FROM dw.ft_crr f
JOIN dw.dim_loc lo ON f.loc_ori_srk = lo.loc_srk
JOIN dw.dim_loc ld ON f.loc_dst_srk = ld.loc_srk
WHERE f.eh_corrida_completa = TRUE
GROUP BY lo.local, ld.local, lo.zona, ld.zona
ORDER BY receita_total DESC
LIMIT 100;


CREATE OR REPLACE VIEW dw.vw_performance_temporal AS
SELECT
    t.ano,
    t.mes,
    t.mes_ano,
    t.trimestre,
    t.nome_dia_semana,
    t.periodo_dia,
    COUNT(*) AS total_corridas,
    SUM(f.distancia_km) AS distancia_total_km,
    SUM(f.valor_corrida) AS receita_total,
    AVG(f.valor_por_km) AS valor_medio_por_km,
    AVG(f.avaliacao_motorista) AS avaliacao_motorista_media,
    SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) AS corridas_completas
FROM dw.ft_crr f
JOIN dw.dim_tmp t ON f.tmp_srk = t.tmp_srk
GROUP BY t.ano, t.mes, t.mes_ano, t.trimestre, t.nome_dia_semana, t.periodo_dia
ORDER BY t.ano, t.mes;


CREATE OR REPLACE VIEW dw.vw_analise_veiculo AS
SELECT
    v.tipo_veiculo,
    v.categoria_veiculo,
    COUNT(*) AS total_corridas,
    SUM(f.valor_corrida) AS receita_total,
    AVG(f.valor_por_km) AS valor_medio_por_km,
    AVG(f.distancia_km) AS distancia_media_km,
    AVG(f.avaliacao_motorista) AS avaliacao_motorista_media,
    SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) AS corridas_completas,
    ROUND(100.0 * SUM(CASE WHEN f.eh_corrida_completa THEN 1 ELSE 0 END) / COUNT(*), 2) AS taxa_conclusao_pct
FROM dw.ft_crr f
JOIN dw.dim_vei v ON f.vei_srk = v.vei_srk
GROUP BY v.tipo_veiculo, v.categoria_veiculo
ORDER BY receita_total DESC;


CREATE OR REPLACE VIEW dw.vw_perfil_cliente AS
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
ORDER BY receita_total DESC;


-- ============================================================================
-- GRANTS (opcional - para usuarios BI)
-- ============================================================================
-- GRANT SELECT ON ALL TABLES IN SCHEMA dw TO powerbi_user;
-- GRANT SELECT ON ALL SEQUENCES IN SCHEMA dw TO powerbi_user;
-- GRANT USAGE ON SCHEMA dw TO powerbi_user;


-- ============================================================================
-- FIM DO DDL GOLD (DW)
-- ============================================================================
