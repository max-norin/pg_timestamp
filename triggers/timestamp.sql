-- триггер на автоматическое обновление полей created_at, updated_at
-- триггер запускается под правами того, что создал триггер
CREATE FUNCTION public.trigger_timestamp() RETURNS TRIGGER AS
$$
BEGIN
    NEW."updated_at" = NOW();
    NEW."created_at" = CASE WHEN TG_OP = 'INSERT' THEN NEW."updated_at" ELSE OLD."created_at" END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql
VOLATILE -- может делать всё, что угодно, в том числе, модифицировать базу данных
SECURITY DEFINER; -- функция выполняется с правами пользователя, владеющего ей
