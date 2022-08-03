BEGIN
    DECLARE const_name VARCHAR(128);
	DECLARE STMT VARCHAR(200);
	SELECT  k.CONSTNAME
	INTO const_name
	FROM SYSCAT.KEYCOLUSE k JOIN SYSCAT.TABCONST t ON k.CONSTNAME = t.CONSTNAME AND k.TABSCHEMA = t.TABSCHEMA
	WHERE t.TABNAME = 'UM_USER' AND t.TYPE='U' AND k.COLNAME = 'UM_USER_ID';

	IF const_name IS NOT NULL THEN
		SET STMT = 'ALTER TABLE UM_USER DROP CONSTRAINT ' ||  const_name;
		PREPARE S1 FROM STMT;
 		EXECUTE S1;
 	END IF;

	SELECT  k.CONSTNAME
	INTO const_name
	FROM SYSCAT.KEYCOLUSE k JOIN SYSCAT.TABCONST t ON k.CONSTNAME = t.CONSTNAME AND k.TABSCHEMA = t.TABSCHEMA
	WHERE t.TABNAME = 'UM_USER' AND t.TYPE='U' AND k.COLNAME = 'UM_USER_NAME';

	IF const_name IS NULL THEN
		SET STMT = 'ALTER TABLE UM_USER ADD UNIQUE(UM_USER_NAME,UM_TENANT_ID)';
		PREPARE S1 FROM STMT;
 		EXECUTE S1 ;
	END IF;
END
/

ALTER TABLE UM_USER ADD UNIQUE(UM_USER_ID)
/

CREATE UNIQUE INDEX INDEX_UM_USERNAME_UM_TENANT_ID ON UM_USER(UM_USER_NAME, UM_TENANT_ID)
/

ALTER TABLE UM_TENANT ADD COLUMN UM_ORG_UUID VARCHAR(36) DEFAULT NULL
/
