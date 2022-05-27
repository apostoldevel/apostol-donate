--------------------------------------------------------------------------------
-- CLIENT ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.client ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.client
AS
  SELECT o.*, b.data::json as bindings
    FROM ObjectClient o LEFT JOIN db.object_data b ON b.object = o.object AND b.type = 'json' AND b.code = 'bindings';

GRANT SELECT ON api.client TO administrator;

--------------------------------------------------------------------------------
-- api.client ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.client (
  pState	uuid
) RETURNS	SETOF api.client
AS $$
  SELECT * FROM api.client WHERE state = pState;
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.client ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.client (
  pState	text
) RETURNS	SETOF api.client
AS $$
BEGIN
  RETURN QUERY SELECT * FROM api.client(GetState(GetClass('client'), pState));
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.add_client --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет нового клиента.
 * @param {uuid} pParent - Идентификатор родителя | null
 * @param {uuid} pType - Идентификатор типа
 * @param {text} pCode - ИНН - для юридического лица | Имя пользователя (login) | null
 * @param {uuid} pUserId - Идентификатор пользователя системы | null
 * @param {jsonb} pName - Полное наименование компании/Ф.И.О.
 * @param {jsonb} pPhone - Телефоны
 * @param {jsonb} pEmail - Электронные адреса
 * @param {jsonb} pInfo - Дополнительная информация
 * @param {timestamptz} pBirthDate - Дата открытия | Дата рождения | null
 * @param {text} pBirthPlace - Место рождения | null
 * @param {text} pDescription - Информация о клиенте
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_client (
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pUserId       uuid,
  pName         jsonb,
  pPhone        jsonb DEFAULT null,
  pEmail        jsonb DEFAULT null,
  pInfo         jsonb DEFAULT null,
  pBirthDate    timestamptz default null,
  pBirthPlace	text default null,
  pDescription  text DEFAULT null
) RETURNS       uuid
AS $$
DECLARE
  uClient       uuid;
  arKeys        text[];
BEGIN
  arKeys := array_cat(arKeys, ARRAY['name', 'short', 'first', 'last', 'middle']);
  PERFORM CheckJsonbKeys('add_client', arKeys, pName);

  uClient := CreateClient(pParent, coalesce(pType, GetType('author.client')), pCode, pUserId, pName, pPhone, pEmail, pInfo, pBirthDate, pBirthPlace, pDescription);

  RETURN uClient;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_client -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет данные клиента.
 * @param {uuid} pId - Идентификатор (api.get_client)
 * @param {uuid} pParent - Идентификатор родителя | null
 * @param {uuid} pType - Идентификатор типа
 * @param {text} pCode - ИНН - для юридического лица | Имя пользователя (login) | null
 * @param {uuid} pUserId - Идентификатор пользователя системы | null
 * @param {jsonb} pName - Полное наименование компании/Ф.И.О.
 * @param {jsonb} pPhone - Телефоны
 * @param {jsonb} pEmail - Электронные адреса
 * @param {jsonb} pInfo - Дополнительная информация
 * @param {timestamptz} pBirthDate - Дата открытия | Дата рождения | null
 * @param {text} pBirthPlace - Место рождения | null
 * @param {text} pDescription - Информация о клиенте
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_client (
  pId           uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pCode         text default null,
  pUserId       uuid default null,
  pName         jsonb default null,
  pPhone        jsonb DEFAULT null,
  pEmail        jsonb DEFAULT null,
  pInfo         jsonb DEFAULT null,
  pBirthDate    timestamptz default null,
  pBirthPlace	text default null,
  pDescription  text DEFAULT null
) RETURNS       void
AS $$
DECLARE
  uClient       uuid;
  arKeys        text[];
BEGIN
  SELECT c.id INTO uClient FROM db.client c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('клиент', 'id', pId);
  END IF;

  arKeys := array_cat(arKeys, ARRAY['name', 'short', 'first', 'last', 'middle']);
  PERFORM CheckJsonbKeys('update_client', arKeys, pName);

  PERFORM EditClient(uClient, pParent, pType, pCode, pUserId, pName, pPhone, pEmail, pInfo, pBirthDate, pBirthPlace, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_client --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_client (
  pId           uuid,
  pParent       uuid,
  pType         uuid,
  pCode         text,
  pUserId       uuid,
  pName         jsonb,
  pPhone        jsonb DEFAULT null,
  pEmail        jsonb DEFAULT null,
  pInfo         jsonb DEFAULT null,
  pBirthDate    timestamptz default null,
  pBirthPlace	text default null,
  pDescription  text DEFAULT null
) RETURNS       SETOF api.client
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_client(pParent, pType, pCode, pUserId, pName, pPhone, pEmail, pInfo, pBirthDate, pBirthPlace, pDescription);
  ELSE
    PERFORM api.update_client(pId, pParent, pType, pCode, pUserId, pName, pPhone, pEmail, pInfo, pBirthDate, pBirthPlace, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.client WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_client --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает клиента
 * @param {uuid} pId - Идентификатор
 * @return {api.client} - Клиент
 */
CREATE OR REPLACE FUNCTION api.get_client (
  pId		uuid
) RETURNS	SETOF api.client
AS $$
  SELECT * FROM api.client WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_client -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список клиентов.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.client} - Клиенты
 */
CREATE OR REPLACE FUNCTION api.list_client (
  pSearch	jsonb DEFAULT null,
  pFilter	jsonb DEFAULT null,
  pLimit	integer DEFAULT null,
  pOffSet	integer DEFAULT null,
  pOrderBy	jsonb DEFAULT null
) RETURNS	SETOF api.client
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'client', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
