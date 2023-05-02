CREATE OR REPLACE FUNCTION public.add_to_gallery()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    INSERT INTO folders (id_album, id_foto)
    SELECT album_id, NEW.foto_id 
	FROM album WHERE id_owner = NEW.user_id;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER add_to_gallery_trigger
AFTER INSERT ON foto
for each row 
execute add_to_gallery();
