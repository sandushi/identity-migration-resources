ALTER TABLE IDN_OAUTH_CONSUMER_APPS ADD ID_TOKEN_EXPIRE_TIME BIGINT DEFAULT 3600000;

IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[IDN_AUTH_TEMP_SESSION_DATA_STORE]') AND TYPE IN (N'U'))
CREATE TABLE IDN_AUTH_TEMP_SESSION_DATA_STORE (
  SESSION_ID VARCHAR (100) NOT NULL,
  SESSION_TYPE VARCHAR(100) NOT NULL,
  OPERATION VARCHAR(10) NOT NULL,
  SESSION_OBJECT VARBINARY(MAX),
  TIME_CREATED BIGINT,
  TENANT_ID INTEGER DEFAULT -1,
  PRIMARY KEY (SESSION_ID, SESSION_TYPE, TIME_CREATED, OPERATION)
);

IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[SP_CLAIM_DIALECT]') AND TYPE IN (N'U'))
CREATE TABLE SP_CLAIM_DIALECT (
  ID INTEGER NOT NULL IDENTITY,
  TENANT_ID INTEGER NOT NULL,
  SP_DIALECT VARCHAR (512) NOT NULL,
  APP_ID INTEGER NOT NULL,
  PRIMARY KEY (ID),
  CONSTRAINT DIALECTID_APPID_CONSTRAINT FOREIGN KEY (APP_ID) REFERENCES SP_APP (ID) ON DELETE CASCADE
);