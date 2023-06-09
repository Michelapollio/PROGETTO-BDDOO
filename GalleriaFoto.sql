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
    datascatto    date,
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
    Nome        VARCHAR(50),
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
    FROM s1.album
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
    c1 cursor for select idalbum
                  from s1.album a
                  where a.idowner = OLD.idutente
                    and a.privacy = true;
    albumid s1.Album.idalbum%TYPE;

BEGIN
    open c1;
    loop
        fetch c1 into albumid;
        exit when not found;

        delete
        from s1.fotoalbum
        where idalbum = albumid
          and idfoto = OLD.idfoto;

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
    new.datacreazione = CURRENT_TIMESTAMP;
    RETURN NEW;
end;
$$ language plpgsql;

create trigger t4
    before insert
    on s1.album
    for each row
execute function s1.add_data();

create or replace function s1.add_datafoto() returns trigger as
$$
BEGIN
    new.datascatto = CURRENT_TIMESTAMP;
    return new;
end;
$$ language plpgsql;

create trigger t5
    before insert
    on s1.foto
    for each row
execute function s1.add_datafoto();

create or replace function s1.add_utentealbum() returns trigger as
$$
BEGIN
    insert into s1.albumutente(idalbum, idutente)
    VALUES (NEW.idalbum, NEW.idowner);
    return new;
end;
$$ language plpgsql;

create trigger t5
    after insert
    on s1.album
    for each row
execute function s1.add_utentealbum();

insert into s1.utente (nome, cognome, email, password)
values ('Elisa', 'Tiberio', 'elisatiberio@live.it', 'nene26'),
       ('Michela', 'Pollio', 'michelapollio19@icloud.com', 'baldusie19');


insert into s1.album(nome, idowner, privacy)
VALUES ('Praia', 1, true);

insert into s1.dispostivo(tipologia, idutente)
VALUES ('iphone', 2);

insert into s1.foto(stato, idutente, iddispositivo)
VALUES ('privato', 2, 1);

insert into s1.Luogo(nome, latitudine, longitudine)
VALUES ('Complesso Studi Montesant’angelo', 40.839026294160135, 14.184969766924183),
       ('Stadio Diego Armando Maradona', 40.828123191020495, 14.193061095758704),
       ('O’Murzillo', 40.8269492735944, 14.1956988245939),
       ('Piazza Plebiscito', 40.83597168245228, 14.248550909253588),
       (null, 40.838643293527596, 14.252676480418668),
       ('Galleria Umberto Primo ', 40.83847283745015, 14.249436372193905),
       ('Colosseo', 41.89029802621207, 12.49223089581815),
       ('Piazza di Spagna', 41.90584948385739, 12.482326995819047),
       (null, 41.89929104233426, 12.473192213005643),
       ('Duomo di Milano', 45.464217966695536, 9.191969411368579),
       ('Duel Club', 40.828068108592305, 14.155206995758762),
       ('Piazza Tasso', 40.626241621412944, 14.37565197856061),
       ('Katarì beach lounge bar', 40.63883580921175, 14.39993868410017),
       ('Palazzo di Schönbrum', 48.18595543300895, 16.3126888943512),
       (null, 35.88852486514128, 14.40577501577596),
       (null, 40.83679554625882, 14.189438780418527);

insert into s1.Utente(nome, cognome, email, password)
VALUES ('Mario', 'Rossi', 'mario@email.com', 'password123'),
       ('Luca', 'Bianchi', 'luca@email.com', 'securepassword'),
       ('giovanni', 'fiume', 'giovannifiume2014@libero.it', 'fiume'),
       ('andrea', 'dota', 'andreadota2000@gmail.com', 'dota'),
       ('alan', 'autorino', 'alan_autorino@hotmail.it', 'autorino'),
       ('emmanuel', 'manna', 'manumanna99@gmail.com', 'manna'),
       ('ilaria', 'gilardi', 'ilariag@live.it', 'gilardi'),
       ('ilaria', 'risimini', 'ilariarisimini@hotmail.it', 'risimini'),
       ('andrea', 'tiberio', 'a.tiberio@gmail.com', 'tibe'),
       ('noemi', 'spera', 'noemis@gmail.com', 'spera'),
       ('rosa', 'liguori', 'rosaliguori05@live.it', 'liguori'),
       ('lisa', 'liguori', 'lisaliguori04@hotmail.it', 'liguori2'),
       ('angela', 'pollio', 'angelapollio@live.it', 'pollio'),
       ('antonio', 'sisimbro', 'tonysisi@hotmail.it', 'sisimbro'),
       ('lorenzo', 'tecchia', 'thewatcher@live.it', 'tecchia'),
       ('tipo', 'frizzantino', 'tipofrizz@icloud.com', 'frizzantino'),
       ('giovanni', 'zampetti', 'algebra.9@icloud.com', 'zampetti'),
       ('alfredo', 'top', 'alfredotop@live.it', 'top'),
       ('francesco', 'ilgemello', 'frageme00@hotmail.it', 'ilgemello'),
       ('marco', 'pastore', 'pastorepecora@outlook.it', 'pastore'),
       ('sabrina', 'amicamichela', 'sabri2001@gmail.com', 'amicamichela'),
       ('alessandro', 'rossi', 'alerossi@libero.it', 'rossi'),
       ('francesca', 'ferrari', 'fraferrari@libero.it', 'ferrari'),
       ('matteo', 'spavone', 'matteospav1@outlook.it', 'spavone'),
       ('sofia', 'bianchi', 'sofiabianchi99@hotmail.it', 'bianchi'),
       ('giulia', 'gallo', 'g.gallo@libero.it', 'gallo'),
       ('giulia', 'conti', 'giualiaconti@live.it', 'conti'),
       ('leonardo', 'marino', 'leomarino@live.it', 'marino'),
       ('emma', 'de luca', 'emmadeluca@libero.it', 'deluca'),
       ('gabriele', 'esposito', 'gabriespo@libero.it', 'esposito'),
       ('chiara', 'rizzo', 'chiararizzo@outlook.it', 'rizzo');



insert into s1.album(nome, idowner, privacy)
VALUES ('Roma', 10, true),
       ('Padova2021', 18, false),
       ('Galleria Univerità', 5, true),
       ('Vacanza a Pestum', 18, true),
       ('Milano2022', 7, false),
       ('Gita a Vienna', 12, true),
       ('Londra', 3, false),
       ('Barcellona', 9, true),
       ('Amsterdam', 20, false),
       ('MSCGrandiosa', 15, true),
       ('Madrid', 6, false),
       ('Estate a Diamante', 14, true),
       ('Atene', 4, true),
       ('Partita16/05', 11, false);


insert into s1.albumutente(idalbum, idutente)
VALUES (3, 2),
       (3, 5);

insert into s1.dispostivo(tipologia, idutente)
VALUES ('macchina fotografica', 5),
       ('cellulare', 1),
       ('cellulare', 16),
       ('cellulare', 19),
       ('cellulare', 18),
       ('cellulare', 9),
       ('macchina fotografica', 6),
       ('macchina fotografica', 20),
       ('macchina fotografica', 15),
       ('macchina fotografica', 7),
       ('ipad', 3),
       ('ipad', 14),
       ('ipad', 13);

INSERT INTO s1.foto(idutente, stato, iddispositivo)
VALUES (1, 'pubblico', 14),
       (2, 'privato', 6),
       (3, 'pubblico', 6),
       (4, 'privato', 3),
       (5, 'pubblico', 2),
       (6, 'privato', 2),
       (7, 'pubblico', 1),
       (8, 'privato', 5),
       (9, 'pubblico', 6),
       (10, 'privato', 7),
       (11, 'pubblico', 8),
       (12, 'privato', 9),
       (13, 'pubblico', 4),
       (14, 'privato', 2),
       (15, 'pubblico', 9),
       (16, 'privato', 3),
       (17, 'pubblico', 1),
       (18, 'privato', 3),
       (19, 'pubblico', 3),
       (20, 'privato', 14),
       (1, 'pubblico', 13),
       (2, 'privato', 6),
       (3, 'pubblico', 3),
       (4, 'privato', 8),
       (5, 'pubblico', 9),
       (6, 'privato', 4),
       (7, 'pubblico', 2),
       (8, 'privato', 9),
       (9, 'pubblico', 3),
       (10, 'privato', 1);


insert into s1.luogofoto(idluogo, idfoto)
VALUES (16, 15),
       (1, 21),
       (1, 26),
       (1, 29),
       (5, 19),
       (1, 6),
       (4, 30),
       (4, 5),
       (2, 7),
       (1, 3),
       (4, 1),
       (2, 23);

insert into s1.soggetto (categoria)
values ('ritratti'),
       ('natura'),
       ('paesaggi'),
       ('persone'),
       ('animali'),
       ('architettura'),
       ('cibo');








