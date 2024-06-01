-- таблица с полями created_at, updated_at для использования в наследовании
CREATE TABLE public."timestamp"
(
    "created_at" TIMESTAMP NOT NULL DEFAULT NOW(),
    "updated_at" TIMESTAMP NOT NULL DEFAULT NOW()
);
-- запрет на вставку, обновление и удаление данных в таблице
CREATE RULE "insert" AS ON INSERT TO public."timestamp" DO INSTEAD NOTHING;
CREATE RULE "update" AS ON UPDATE TO public."timestamp" DO INSTEAD NOTHING;
CREATE RULE "delete" AS ON DELETE TO public."timestamp" DO INSTEAD NOTHING;

-- создание триггера на автоматическое обновление полей created_at, updated_at
CREATE TRIGGER "timestamp"
    BEFORE INSERT OR UPDATE
    ON public."timestamp"
    FOR EACH ROW
EXECUTE FUNCTION public.trigger_timestamp();
