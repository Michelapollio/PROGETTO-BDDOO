
CREATE OR REPLACE FUNCTION top_three_places()
    RETURNS TABLE(id_luogo integer, nome character varying, latitudine double precision, longitudine double precision, num_foto integer) 
AS 
$$
BEGIN
    RETURN QUERY 
    SELECT 
        p.id_luogo,
        p.nome,
        p.latitudine,
        p.longitudine,
        COUNT(*) AS num_foto
    FROM 
        luogo p
        INNER JOIN foto ph ON p.id_luogo = ph.location_id
    GROUP BY 
        p.id_luogo,
        p.nome,
        p.latitudine,
        p.longitudine
    ORDER BY 
        num_foto DESC
    LIMIT 3;
END;
$$;

