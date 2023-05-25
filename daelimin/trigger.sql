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