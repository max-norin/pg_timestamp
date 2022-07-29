CREATE TABLE "timestamp"
(
    "created_at" TIMESTAMP NOT NULL DEFAULT NOW(), -- TODO может вообще запретить редактирование
    "updated_at" TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE RULE "timestamp__insert" AS ON INSERT TO "timestamp" DO INSTEAD NOTHING;

CREATE TRIGGER "timestamp"
    BEFORE INSERT OR UPDATE
    ON "timestamp"
    FOR EACH ROW
EXECUTE FUNCTION trigger_timestamp();
