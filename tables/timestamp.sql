-- таблица с полями created_at, updated_at для использования в наследовании
CREATE TABLE "timestamp"
(
    "created_at" TIMESTAMP NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMP NOT NULL DEFAULT NOW()
);
-- запрет на вставку, обновление и удаление данных в таблице
CREATE RULE "timestamp__insert" AS ON INSERT TO "timestamp" DO INSTEAD NOTHING;
CREATE RULE "timestamp__update" AS ON UPDATE TO "timestamp" DO INSTEAD NOTHING;
CREATE RULE "timestamp__delete" AS ON DELETE TO "timestamp" DO INSTEAD NOTHING;

-- создание триггера на автоматическое обновление полей created_at, updated_at
CREATE TRIGGER "timestamp"
    BEFORE INSERT OR UPDATE
    ON "timestamp"
    FOR EACH ROW
EXECUTE FUNCTION @extschema@.trigger_timestamp();
