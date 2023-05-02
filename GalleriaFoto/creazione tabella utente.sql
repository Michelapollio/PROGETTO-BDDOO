CREATE TABLE utente
(
    id_user serial NOT NULL,
    nome character varying(50) NOT NULL,
    cognome character varying(50) NOT NULL,
    email character varying(50) NOT NULL,
    password character varying(100) NOT NULL,
    CONSTRAINT utente_pkey PRIMARY KEY (id_user)
)

CREATE TRIGGER creazione_album_personale_trigger
    AFTER INSERT
    ON public.utente
    FOR EACH ROW
    EXECUTE FUNCTION public.creazione_album_personale();