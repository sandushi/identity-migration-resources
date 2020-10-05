INSERT INTO IDN_CONFIG_TYPE (ID, NAME, DESCRIPTION) VALUES
('8ec6dbf1-218a-49bf-bc34-0d2db52d151c', 'CORS_CONFIGURATION', 'A resource type to keep the tenant CORS configurations');

IF NOT  EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[IDN_CORS_ORIGIN]') AND TYPE IN (N'U'))

CREATE TABLE IDN_CORS_ORIGIN (
    ID                INT           NOT NULL IDENTITY,
    TENANT_ID         INT           NOT NULL,
    ORIGIN            VARCHAR(2048) NOT NULL,
    UUID              CHAR(36)      NOT NULL,

    PRIMARY KEY (ID),
    UNIQUE (TENANT_ID, ORIGIN),
    UNIQUE (UUID)
);

IF NOT EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID(N'[DBO].[IDN_CORS_ASSOCIATION]') AND TYPE IN (N'U'))
CREATE TABLE IDN_CORS_ASSOCIATION (
    IDN_CORS_ORIGIN_ID INT NOT NULL,
    SP_APP_ID          INT NOT NULL,

    PRIMARY KEY (IDN_CORS_ORIGIN_ID, SP_APP_ID),
    FOREIGN KEY (IDN_CORS_ORIGIN_ID) REFERENCES IDN_CORS_ORIGIN (ID) ON DELETE CASCADE,
    FOREIGN KEY (SP_APP_ID) REFERENCES SP_APP (ID) ON DELETE CASCADE
);
CREATE INDEX IDX_IDN_CORS_ASSOCIATION_SP_APP_ID ON IDN_CORS_ASSOCIATION (SP_APP_ID);

CREATE INDEX IDX_IDN_CORS_ASSOCIATION_IDN_CORS_ORIGIN_ID ON IDN_CORS_ASSOCIATION (IDN_CORS_ORIGIN_ID);
