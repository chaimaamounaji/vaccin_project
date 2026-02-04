--- Create two pluggable databases: one primary and second standby
CREATE PLUGGABLE DATABASE PDB_VACCINATION_PRIMARY
ADMIN USER pdb_primary_admin IDENTIFIED BY oracle
FILE_NAME_CONVERT = ('pdbseed', 'pdb_vaccination_primary');
--
CREATE PLUGGABLE DATABASE PDB_VACCINATION_STANDBY
ADMIN USER pdb_standby_admin IDENTIFIED BY oracle
FILE_NAME_CONVERT = ('pdbseed', 'pdb_vaccination_standby');

ALTER PLUGGABLE DATABASE PDB_VACCINATION_PRIMARY OPEN;
ALTER PLUGGABLE DATABASE PDB_VACCINATION_STANDBY OPEN;

ALTER SESSION SET CONTAINER = PDB_VACCINATION_PRIMARY;

--create table to hold raw vaccination record
-- PRIMARY PDB : données de vaccination brutes
ALTER SESSION SET CONTAINER = PDB_VACCINATION_PRIMARY;

CREATE TABLE vaccination_records_raw (
    vaccination_id NUMBER,
    patient_id NUMBER,
    vaccin_id NUMBER,
    centre_id NUMBER,
    dose_number NUMBER,
    adverse_effect CHAR(1),
    vaccination_date DATE
);


--create wallet and encryption key for secure pluggable database
ALTER SESSION SET CONTAINER = PDB_VACCINATION_STANDBY;

ADMINISTER KEY MANAGEMENT CREATE KEYSTORE '/opt/oracle/wallet'
IDENTIFIED BY walletpass;

---open the keystore
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN
IDENTIFIED BY walletpass;

---create encryption key
ADMINISTER KEY MANAGEMENT SET KEY
IDENTIFIED BY walletpass WITH BACKUP;

ALTER SESSION SET CONTAINER = PDB_VACCINATION_STANDBY;
--create tablespace with encryption
-- Encrypted tablespace (STANDBY)
CREATE TABLESPACE ts_secure_vaccination
DATAFILE 'ts_secure_vaccination01.dbf' SIZE 100M
ENCRYPTION USING 'AES256'
DEFAULT STORAGE (ENCRYPT);



--create table and indexes in the encrypted tablespace
CREATE TABLE vaccination_record_secure (
    vaccination_id NUMBER,
    patient_id NUMBER,
    vaccin_id NUMBER,
    centre_id NUMBER,
    dose_number NUMBER,
    adverse_effect CHAR(1),
    vaccination_date DATE
)

TABLESPACE ts_secure_vaccination;
CREATE INDEX idx_patient_id ON vaccination_records_secure(patient_id)
TABLESPACE ts_secure_vaccination;
CREATE INDEX idx_vaccination_date ON vaccination_records_secure(vaccination_date)

TABLESPACE ts_secure_vaccination;
