CREATE TABLE IF NOT EXISTS IDN_OAUTH2_AUTHZ_CODE_SCOPE(
    CODE_ID VARCHAR(255),
    SCOPE VARCHAR(60),
    TENANT_ID INTEGER DEFAULT -1,
    PRIMARY KEY (CODE_ID, SCOPE),
    FOREIGN KEY (CODE_ID) REFERENCES IDN_OAUTH2_AUTHORIZATION_CODE (CODE_ID) ON DELETE CASCADE);

CREATE TABLE IF NOT EXISTS IDN_OAUTH2_TOKEN_BINDING (
    TOKEN_ID VARCHAR(255),
    TOKEN_BINDING_TYPE VARCHAR(32),
    TOKEN_BINDING_REF VARCHAR(32),
    TOKEN_BINDING_VALUE VARCHAR(1024),
    TENANT_ID INTEGER DEFAULT -1,
    PRIMARY KEY (TOKEN_ID),
    FOREIGN KEY (TOKEN_ID) REFERENCES IDN_OAUTH2_ACCESS_TOKEN(TOKEN_ID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS IDN_FED_AUTH_SESSION_MAPPING (
    IDP_SESSION_ID VARCHAR(255) NOT NULL,
    SESSION_ID VARCHAR(255) NOT NULL,
    IDP_NAME VARCHAR(255) NOT NULL,
    AUTHENTICATOR_ID VARCHAR(255),
    PROTOCOL_TYPE VARCHAR(255),
    TIME_CREATED TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (IDP_SESSION_ID)
);

CREATE TABLE IF NOT EXISTS IDN_OAUTH2_CIBA_AUTH_CODE (
    AUTH_CODE_KEY CHAR(36),
    AUTH_REQ_ID CHAR(36),
    ISSUED_TIME TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSUMER_KEY VARCHAR(255),
    LAST_POLLED_TIME TIMESTAMP NOT NULL,
    POLLING_INTERVAL INTEGER,
    EXPIRES_IN  INTEGER,
    AUTHENTICATED_USER_NAME VARCHAR(255),
    USER_STORE_DOMAIN VARCHAR(100),
    TENANT_ID INTEGER,
    AUTH_REQ_STATUS VARCHAR(100) DEFAULT 'REQUESTED',
    IDP_ID INTEGER,
    UNIQUE(AUTH_REQ_ID),
    PRIMARY KEY (AUTH_CODE_KEY),
    FOREIGN KEY (CONSUMER_KEY) REFERENCES IDN_OAUTH_CONSUMER_APPS(CONSUMER_KEY) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS IDN_OAUTH2_CIBA_REQUEST_SCOPES (
    AUTH_CODE_KEY CHAR(36),
    SCOPE VARCHAR(255),
    FOREIGN KEY (AUTH_CODE_KEY) REFERENCES IDN_OAUTH2_CIBA_AUTH_CODE(AUTH_CODE_KEY) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS IDN_OAUTH2_DEVICE_FLOW (
    CODE_ID VARCHAR(255),
    DEVICE_CODE VARCHAR(255),
    USER_CODE VARCHAR(25),
    CONSUMER_KEY_ID INTEGER,
    LAST_POLL_TIME TIMESTAMP NOT NULL,
    EXPIRY_TIME TIMESTAMP NOT NULL,
    TIME_CREATED TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    POLL_TIME BIGINT,
    STATUS VARCHAR(25) DEFAULT 'PENDING',
    AUTHZ_USER VARCHAR(100),
    TENANT_ID INTEGER,
    USER_DOMAIN VARCHAR(50),
    IDP_ID INTEGER,
    PRIMARY KEY (DEVICE_CODE),
    UNIQUE (CODE_ID),
    FOREIGN KEY (CONSUMER_KEY_ID) REFERENCES IDN_OAUTH_CONSUMER_APPS(ID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS IDN_OAUTH2_DEVICE_FLOW_SCOPES (
    ID SERIAL PRIMARY KEY,
    SCOPE_ID VARCHAR(255),
    SCOPE VARCHAR(255),
    FOREIGN KEY (SCOPE_ID) REFERENCES IDN_OAUTH2_DEVICE_FLOW(CODE_ID) ON DELETE CASCADE
);

ALTER TABLE IDN_OAUTH2_ACCESS_TOKEN
    ADD COLUMN TOKEN_BINDING_REF VARCHAR(32) DEFAULT 'NONE',
    DROP CONSTRAINT CON_APP_KEY,
    ADD CONSTRAINT CON_APP_KEY UNIQUE (CONSUMER_KEY_ID,AUTHZ_USER,TENANT_ID,USER_DOMAIN,USER_TYPE,TOKEN_SCOPE_HASH,TOKEN_STATE,TOKEN_STATE_ID,IDP_ID,TOKEN_BINDING_REF);

/* User should have the Superuser permission */
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

ALTER TABLE IDN_ASSOCIATED_ID ADD COLUMN ASSOCIATION_ID CHAR(36) NOT NULL DEFAULT uuid_generate_v4();

ALTER TABLE SP_APP
    ADD COLUMN UUID CHAR(36) DEFAULT uuid_generate_v4(),
    ADD COLUMN IMAGE_URL VARCHAR(1024),
    ADD COLUMN ACCESS_URL VARCHAR(1024),
    ADD COLUMN IS_DISCOVERABLE CHAR(1) DEFAULT '0',
    ADD CONSTRAINT APPLICATION_UUID_CONSTRAINT UNIQUE (UUID);

ALTER TABLE IDP
    ADD COLUMN IMAGE_URL VARCHAR(1024),
    ADD COLUMN UUID CHAR(36) DEFAULT uuid_generate_v4(),
    ADD CONSTRAINT IDP_UUID_CONSTRAINT UNIQUE(UUID);

ALTER TABLE IF EXISTS IDN_CONFIG_FILE ADD COLUMN IF NOT EXISTS NAME VARCHAR(255) NULL;

ALTER TABLE FIDO2_DEVICE_STORE
    ADD COLUMN DISPLAY_NAME VARCHAR(255),
    ADD COLUMN IS_USERNAMELESS_SUPPORTED CHAR(1) DEFAULT '0';

ALTER TABLE IDN_OAUTH2_SCOPE_BINDING
    ADD COLUMN BINDING_TYPE VARCHAR(255) NOT NULL DEFAULT 'DEFAULT',
    ALTER COLUMN SCOPE_BINDING SET NOT NULL,
    ADD UNIQUE (SCOPE_ID, SCOPE_BINDING, BINDING_TYPE);

-- Related to Scope Management --

ALTER TABLE IDN_OAUTH2_SCOPE
    ADD COLUMN SCOPE_TYPE VARCHAR(255) NOT NULL DEFAULT 'OAUTH2',
    ADD UNIQUE (NAME, SCOPE_TYPE, TENANT_ID);

CREATE TABLE IF NOT EXISTS IDN_OIDC_SCOPE_CLAIM_MAPPING_NEW (
    ID SERIAL,
    SCOPE_ID INTEGER NOT NULL,
    EXTERNAL_CLAIM_ID INTEGER NOT NULL,
    PRIMARY KEY (ID),
    FOREIGN KEY (SCOPE_ID) REFERENCES IDN_OAUTH2_SCOPE(SCOPE_ID) ON DELETE CASCADE,
    FOREIGN KEY (EXTERNAL_CLAIM_ID) REFERENCES IDN_CLAIM(ID) ON DELETE CASCADE,
    UNIQUE (SCOPE_ID, EXTERNAL_CLAIM_ID)
);

DROP PROCEDURE IF EXISTS OIDC_SCOPE_DATA_MIGRATE_PROCEDURE;

--<![CDATA[Start of Procedure]]>--
CREATE OR REPLACE PROCEDURE OIDC_SCOPE_DATA_MIGRATE_PROCEDURE() AS $$
DECLARE
    oidc_scope_count INT:= 0;
    row_offset INT:= 0;
    oauth_scope_id INT:= 0;
    oidc_scope_id INT:= 0;
BEGIN
    SELECT COUNT(*) FROM IDN_OIDC_SCOPE INTO oidc_scope_count;
    WHILE row_offset < oidc_scope_count LOOP
        SELECT ID INTO oidc_scope_id FROM IDN_OIDC_SCOPE OFFSET row_offset LIMIT 1;
        INSERT INTO IDN_OAUTH2_SCOPE (NAME, DISPLAY_NAME, TENANT_ID, SCOPE_TYPE) SELECT NAME, NAME, TENANT_ID, 'OIDC' FROM IDN_OIDC_SCOPE OFFSET row_offset LIMIT 1 RETURNING SCOPE_ID INTO oauth_scope_id;
        INSERT INTO IDN_OIDC_SCOPE_CLAIM_MAPPING_NEW (SCOPE_ID, EXTERNAL_CLAIM_ID) SELECT @oauth_scope_id, EXTERNAL_CLAIM_ID FROM IDN_OIDC_SCOPE_CLAIM_MAPPING WHERE SCOPE_ID = oidc_scope_id;
        row_offset := row_offset + 1;
    END LOOP;
END;
$$
LANGUAGE 'plpgsql';
--<![CDATA[End of Procedure]]>--

CALL OIDC_SCOPE_DATA_MIGRATE_PROCEDURE();

DROP PROCEDURE IF EXISTS OIDC_SCOPE_DATA_MIGRATE_PROCEDURE;

DROP TABLE IDN_OIDC_SCOPE_CLAIM_MAPPING;

ALTER TABLE IDN_OIDC_SCOPE_CLAIM_MAPPING_NEW RENAME TO IDN_OIDC_SCOPE_CLAIM_MAPPING;

DROP TABLE IDN_OIDC_SCOPE;

CREATE INDEX IDX_IDN_AUTH_BIND ON IDN_OAUTH2_TOKEN_BINDING (TOKEN_BINDING_REF);

CREATE INDEX IDX_AI_DN_UN_AI ON IDN_ASSOCIATED_ID(DOMAIN_NAME, USER_NAME, ASSOCIATION_ID);

CREATE INDEX IDX_AT_CKID_AU_TID_UD_TSH_TS ON IDN_OAUTH2_ACCESS_TOKEN(CONSUMER_KEY_ID, AUTHZ_USER, TENANT_ID, USER_DOMAIN, TOKEN_SCOPE_HASH, TOKEN_STATE);

CREATE INDEX IDX_FEDERATED_AUTH_SESSION_ID ON IDN_FED_AUTH_SESSION_MAPPING (SESSION_ID);
