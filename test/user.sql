CREATE TABLE public."user"
(
    "id"       SERIAL PRIMARY KEY,
    "nickname" VARCHAR(100) NOT NULL UNIQUE
)
    INHERITS (public."timestamp_del");

