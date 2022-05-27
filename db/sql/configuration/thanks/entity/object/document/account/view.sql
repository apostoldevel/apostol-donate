--------------------------------------------------------------------------------
-- Account ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Account (Id, Document,
  Currency, CurrencyCode, CurrencyDigital, CurrencyName, CurrencyDescription,
  Category, CategoryCode, CategoryName, CategoryDescription,
  Client, ClientCode, ClientName,
  Code, Balance
)
AS
  SELECT a.id, a.document,
         a.currency, r.code, r.name, r.description, r.digital,
         a.category, g.code, g.name, g.description,
         a.client, c.code, c.fullname,
         a.code, b.amount AS balance
    FROM db.account a INNER JOIN Currency   r ON a.currency = r.id
                       LEFT JOIN Category   g ON a.category = g.id
                       LEFT JOIN Client     c ON a.client = c.id
                       LEFT JOIN db.balance b ON a.id = b.account AND b.type = 1 AND b.validFromDate <= oper_date() AND b.validToDate > oper_date();

GRANT SELECT ON Account TO administrator;

--------------------------------------------------------------------------------
-- VIEW Balance ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Balance
AS
  SELECT * FROM db.balance;

GRANT SELECT ON Balance TO administrator;

--------------------------------------------------------------------------------
-- VIEW Turnover ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Turnover
AS
  SELECT * FROM db.turnover;

GRANT SELECT ON Turnover TO administrator;

--------------------------------------------------------------------------------
-- AccessAccount ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessAccount
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('account'), current_userid())
  )
  SELECT a.* FROM Account a INNER JOIN access ac ON a.id = ac.object;

GRANT SELECT ON AccessAccount TO administrator;

--------------------------------------------------------------------------------
-- ObjectAccount ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectAccount (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Currency, CurrencyCode, CurrencyDigital, CurrencyName, CurrencyDescription,
  Category, CategoryCode, CategoryName, CategoryDescription,
  Client, ClientCode, ClientName,
  Code, Label, Description, Balance,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Area, AreaCode, AreaName, AreaDescription,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT t.id, d.object, d.parent,
         d.entity, d.entitycode, d.entityname,
         d.class, d.classcode, d.classlabel,
         d.type, d.typecode, d.typename, d.typedescription,
         t.currency, t.currencycode, t.currencydigital, t.currencyname, t.currencydescription,
         t.category, t.categorycode, t.categoryname, t.categorydescription,
         t.client, t.clientcode, t.clientname,
         t.code, d.label, d.description, t.balance,
         d.statetype, d.statetypecode, d.statetypename,
         d.state, d.statecode, d.statelabel, d.lastupdate,
         d.owner, d.ownercode, d.ownername, d.created,
         d.oper, d.opercode, d.opername, d.operdate,
         d.area, d.areacode, d.areaname, d.areadescription,
         d.scope, d.scopecode, d.scopename, d.scopedescription
    FROM AccessAccount t INNER JOIN ObjectDocument d ON t.document = d.id;

GRANT SELECT ON ObjectAccount TO administrator;
