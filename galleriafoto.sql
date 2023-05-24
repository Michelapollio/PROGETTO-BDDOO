DROP SCHEMA IF EXISTS s1 CASCADE;
CREATE SCHEMA s1;

CREATE TYPE stato AS ENUM ('privato', 'pubblico', 'deleted');

CREATE TABLE s1.Utente
(
    IdUtente SERIAL,
    Nome     VARCHAR(50) NOT NULL,
    Cognome  VARCHAR(50) NOT NULL,
    Email    VARCHAR(50) NOT NULL,
    Password VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Utente PRIMARY KEY (IdUtente)
);

CREATE TABLE s1.Dispostivo
(
    IdDispositivo SERIAL,
    Tipologia     VARCHAR(50) NOT NULL,
    IdUtente      INTEGER     NOT NULL,
    CONSTRAINT PK_Dispositivo PRIMARY KEY (IdDispositivo),
    CONSTRAINT FK_Dispositivo_Utente FOREIGN KEY (IdUtente) REFERENCES s1.Utente (IdUtente)
);

CREATE TABLE s1.Foto
(
    IdFoto        SERIAL,
    Stato         stato,
    IdUtente      INTEGER NOT NULL,
    IdDispositivo INTEGER NOT NULL,
    CONSTRAINT PK_Foto PRIMARY KEY (IdFoto),
    CONSTRAINT FK_Foto_Utente FOREIGN KEY (IdUtente) REFERENCES s1.Utente (IdUtente),
    CONSTRAINT FK_Foto_Dispositivo FOREIGN KEY (IdDispositivo) REFERENCES s1.Dispostivo (IdDispositivo)
);

CREATE TABLE s1.Luogo
(
    IdLuogo     SERIAL,
    Nome        VARCHAR(50)    NOT NULL,
    Latitudine  DECIMAL(10, 8) NOT NULL,
    Longitudine DECIMAL(11, 8) NOT NULL,
    CONSTRAINT PK_Luogo PRIMARY KEY (IdLuogo),
    CONSTRAINT UQ_Coordinate UNIQUE (Latitudine, Longitudine),
    CONSTRAINT UQ_Nome UNIQUE (Nome)
);

CREATE TABLE s1.LuogoFoto
(
    IdLuogo INTEGER NOT NULL,
    IdFoto  INTEGER NOT NULL,
    CONSTRAINT PK_LuogoFoto PRIMARY KEY (IdLuogo, IdFoto),
    CONSTRAINT FK_LuogoFoto_Luogo FOREIGN KEY (IdLuogo) REFERENCES s1.Luogo (IdLuogo),
    CONSTRAINT FK_LuogoFoto_Foto FOREIGN KEY (IdFoto) REFERENCES s1.Foto (IdFoto)
);

CREATE TABLE s1.Soggetto
(
    IdSoggetto SERIAL,
    Categoria  VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Soggetto PRIMARY KEY (IdSoggetto)
);

CREATE TABLE s1.SoggettoFoto
(
    IdSoggetto INTEGER NOT NULL,
    IdFoto     INTEGER NOT NULL,
    CONSTRAINT PK_SoggettoFoto PRIMARY KEY (IdSoggetto, IdFoto),
    CONSTRAINT FK_SoggettoFoto_Soggetto FOREIGN KEY (IdSoggetto) REFERENCES s1.Soggetto (IdSoggetto),
    CONSTRAINT FK_SoggettoFoto_Foto FOREIGN KEY (IdFoto) REFERENCES s1.Foto (IdFoto)
);

CREATE TABLE s1.Tag
(
    IdUtente INTEGER NOT NULL,
    IdFoto   INTEGER NOT NULL,
    CONSTRAINT PK_Tag PRIMARY KEY (IdUtente, IdFoto),
    CONSTRAINT FK_Tag_Utente FOREIGN KEY (IdUtente) REFERENCES s1.Utente (IdUtente),
    CONSTRAINT FK_Tag_Foto FOREIGN KEY (IdFoto) REFERENCES s1.Foto (IdFoto)
);

CREATE TABLE s1.Album
(
    IdAlbum       Serial,
    Nome          VARCHAR(50) NOT NULL,
    DataCreazione DATE,
    IdOwner       INTEGER     NOT NULL,
    Privacy       BOOLEAN     NOT NULL,
    CONSTRAINT PK_Album PRIMARY KEY (IdAlbum),
    CONSTRAINT FK_Album_Utente FOREIGN KEY (IdOwner) REFERENCES s1.Utente (IdUtente)
);

CREATE TABLE s1.FotoAlbum
(
    IdFoto  INTEGER NOT NULL,
    IdAlbum INTEGER NOT NULL,
    CONSTRAINT PK_FotoAlbum PRIMARY KEY (IdFoto, IdAlbum),
    CONSTRAINT FK_FotoAlbum_Foto FOREIGN KEY (IdFoto) REFERENCES s1.Foto (IdFoto),
    CONSTRAINT FK_FotoAlbum_Album FOREIGN KEY (IdAlbum) REFERENCES s1.Album (IdAlbum)
);

CREATE TABLE s1.AlbumUtente
(
    IdAlbum  INTEGER NOT NULL,
    IdUtente INTEGER NOT NULL,
    CONSTRAINT PK_AlbumUtente PRIMARY KEY (IdAlbum, IdUtente),
    CONSTRAINT FK_AlbumUtente_Album FOREIGN KEY (IdAlbum) REFERENCES s1.Album (IdAlbum),
    CONSTRAINT FK_AlbumUtente_Utente FOREIGN KEY (IdUtente) REFERENCES s1.Utente (IdUtente)
);

CREATE VIEW s1.Top3LuogiPiùImmortalati AS
(
SELECT l.IdLuogo, l.Nome, l.Latitudine, l.Longitudine, COUNT(*) AS NumeroFoto
FROM s1.Luogo l,
     s1.LuogoFoto lf
WHERE l.IdLuogo = lf.IdLuogo
GROUP BY l.IdLuogo, l.Nome, l.Latitudine, l.Longitudine
ORDER BY NumeroFoto DESC
LIMIT 3);

create or replace function f1() returns trigger as
$$
declare
    nome1 varchar(50);
begin
    nome1 = concat(NEW.nome, ' ', 'album personale');
    insert into s1.album (nome, datacreazione, idowner, privacy)
    values (nome1, CURRENT_TIMESTAMP, NEW.idutente, false);

    return NEW;
END;
$$ language plpgsql;

create trigger t1
    after insert
    on s1.utente
    for each row
execute function f1();

CREATE OR REPLACE FUNCTION s1.add_to_gallery() RETURNS trigger
AS
$$
BEGIN
    INSERT INTO s1.fotoalbum (idalbum, idfoto)
    SELECT idalbum, NEW.idfoto
    FROM album
    WHERE idowner = NEW.idutente;
    RETURN NEW;
END;
$$ language plpgsql;


CREATE OR REPLACE TRIGGER add_to_gallery_trigger
    AFTER INSERT
    ON s1.foto
    for each row
execute function s1.add_to_gallery();

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
$$ language plpgsql;

create or replace function s1.f2() returns trigger as
$$
    declare
        c1 cursor for select idalbum from s1.album a where a.idowner = OLD.idutente and a.privacy = true;
        albumid s1.Album.idalbum%TYPE;

BEGIN
        open c1;
        loop
            fetch c1 into albumid;
            exit when not found;

            delete from s1.fotoalbum
            where idalbum = albumid and idfoto = OLD.idfoto;

        end loop;
end;
$$ language plpgsql;

create trigger t2
    after update
    on s1.foto
    for each row
execute function s1.f2();

create or replace function s1.add_data() returns trigger as
    $$
    BEGIN
        insert into s1.album(nome, datacreazione, idowner, privacy)
        values (new.nome, CURRENT_TIMESTAMP, new.idowner, new.privacy);
    end;
    $$ language plpgsql;


create or replace function s1.add_utentealbum() returns trigger as
    $$
    BEGIN
        insert into s1.albumutente(idalbum, idutente)
        VALUES (NEW.idalbum, NEW.idowner);
        return new;
    end;
    $$ language plpgsql;

create trigger t4
    after insert on s1.album
    for each row
    execute function s1.add_utentealbum();

insert into s1.utente (nome, cognome, email, password)
values  ('elisa', 'tiberio', 'elisatiberio@live.it', 'nene26'),
        ('michela', 'pollio', 'michelapollio19@icloud.com', 'balusie19');
        ('giovanni', 'fiume', 'giovannifiume2014@libero.it', 'fiume');
        ('andrea', 'dota', 'andreadota2000@gmail.com', 'dota');
        ('alan', 'autorino', 'alan_autorino@hotmail.it', 'autorino');
        ('emmanuel', 'manna', 'manumanna99@gmail.com', 'manna');
        ('ilaria', 'gilardi', 'ilariag@live.it', 'gilardi');
        ('ilaria', 'risimini', 'ilariarisimini@hotmail.it', 'risimini');
        ('andrea', 'tiberio', 'a.tiberio@gmail.com', 'tibe');
        ('noemi', 'spera', 'noemis@gmail.com', 'spera');
        ('rosa', 'liguori', 'rosaliguori05@live.it', 'liguori');
        ('lisa', 'liguori', 'lisaliguori04@hotmail.it', 'liguori2');
        ('angela', 'pollio', 'angelapollio@live.it', 'pollio');
        ('antonio', 'sisimbro', 'tonysisi@hotmail.it', 'sisimbro');
        ('lorenzo', 'tecchia', 'thewatcher@live.it', 'tecchia');
        ('tipo', 'frizzantino', 'tipofrizz@icloud.com', 'frizzantino');
        ('giovanni', 'zampetti', 'algebra.9@icloud.com', 'zampetti');
        ('alfredo', 'top', 'alfredotop@live.it', 'top');
        ('francesco', 'ilgemello', 'frageme00@hotmail.it', 'ilgemello');
        ('marco', 'pastore', 'pastorepecora@outlook.it', 'pastore');
        ('sabrina', 'amicamichela', 'sabri2001@gmail.com', 'amicamichela');
        ('alessandro', 'rossi', 'alerossi@libero.it', 'rossi');
        ('francesca', 'ferrari', 'fraferrari@libero.it', 'ferrari');
        ('matteo', 'spavone', 'matteospav1@outlook.it', 'spavone');
        ('sofia', 'bianchi', 'sofiabianchi99@hotmail.it', 'bianchi');
        ('giulia', 'gallo', 'g.gallo@libero.it', 'gallo');
        ('giulia', 'conti', 'giualiaconti@live.it', 'conti');
        ('leonardo', 'marino', 'leomarino@live.it', 'marino');
        ('emma', 'de luca', 'emmadeluca@libero.it', 'deluca');
        ('gabriele', 'esposito', 'gabriespo@libero.it', 'esposito');
        ('chiara', 'rizzo', 'chiararizzo@outlook.it', 'rizzo');

insert into s1.soggetto (categoria)
values ('ritratti', 'natura', 'paesaggi', 'persone', 'animali', 'architettura', 'cibo')