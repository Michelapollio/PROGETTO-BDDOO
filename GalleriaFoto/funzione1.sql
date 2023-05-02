-- FUNCTION: public.get_photos_same_place(integer)

-- DROP FUNCTION IF EXISTS public.get_photos_same_place(integer);

CREATE OR REPLACE FUNCTION public.get_photos_same_place(
	place_id_param integer)
    RETURNS TABLE(photo_id integer) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN
    RETURN QUERY SELECT foto_id FROM foto WHERE location_id = place_id_param;
END;
$BODY$;

ALTER FUNCTION public.get_photos_same_place(integer)
    OWNER TO postgres;
