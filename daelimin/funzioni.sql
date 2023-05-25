CREATE OR REPLACE FUNCTION s1.getsameplace(luogoid int)
    returns table
            (
                idfoto        integer,
                stato         stato,
                idutente      integer,
                iddispositivo integer
            )
as
$$
begin
    return query select f.idfoto, f.stato, f.idutente, f.iddispositivo
                 from s1.foto f
                          natural join s1.luogofoto lf
                 where lf.IdLuogo = luogoid;
end;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION s1.getsamesubject(soggettoid int)
    returns table
            (
                idfoto        integer,
                stato         stato,
                idutente      integer,
                iddispositivo integer
            )
as
$$
begin
    return query select f.idfoto, f.stato, f.idutente, f.iddispositivo
                 from s1.foto f
                          natural join s1.soggettofoto sf
                 where sf.IdSoggetto = soggettoid;
end;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION s1.getsameuser(utenteid int)
    returns table
            (
                idfoto        integer,
                stato         stato,
                idutente      integer,
                iddispositivo integer
            )
as
$$
begin
    return query select f.idfoto, f.stato, f.idutente, f.iddispositivo
                 from s1.foto f
                          natural join s1.tag t
                 where t.IdUtente = utenteid;
end;
$$ language plpgsql; get