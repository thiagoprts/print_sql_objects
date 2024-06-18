CREATE OR REPLACE PROCEDURE pr_inventario
AS 
CURSOR cr_objects IS SELECT object_name, object_type, created FROM user_objects ORDER BY object_name;
CURSOR cr_sources IS SELECT name, text FROM user_source;
CURSOR cr_table_columns IS (SELECT table_name, column_name, data_type, data_length, nullable FROM user_tab_columns);
CURSOR cr_segments IS (SELECT segment_name,
                        CASE 
                            WHEN (SUM(bytes)/1024/1024) < 1 THEN '0' || (SUM(bytes)/1024/1024)
                            ELSE TO_CHAR(SUM(bytes)/1024/1024) 
                        END "tamanho" 
                        FROM user_segments GROUP BY segment_name);
CURSOR cr_indexes IS SELECT index_name, table_name FROM user_indexes;
CURSOR cr_indexes_column_name IS SELECT index_name, column_name FROM user_ind_columns;
username VARCHAR2(3000);
records_amount NUMBER;
column_name VARCHAR(4000);
BEGIN

    SELECT username INTO username FROM user_users;

    FOR objects IN cr_objects LOOP
                
        -- HANDLING WITH TABLES ================================================       
        FOR segments IN cr_segments LOOP
            IF  objects.object_type = 'TABLE' AND segments.segment_name = objects.object_name
            THEN
                SELECT num_rows INTO records_amount FROM user_tables WHERE table_name = objects.object_name;
                
                dbms_output.put_line('USUARIO: ' || username);
                dbms_output.put_line('NOME DO OBJETO: ' || objects.object_name || '           ' || 'DATA CRIACAO: ' || TO_CHAR(objects.created, 'DD/MM/YYYY') || '          ' || 'TIPO DO OBJETO: ' || objects.object_type);
                dbms_output.put_line('REGISTROS: ' || records_amount);
                dbms_output.put_line('TAMANHO: ' || segments."tamanho" || 'MB');
                dbms_output.put_line('DDL: ');
                dbms_output.put_line('CREATE TABLE ' || objects.object_name || '(');
                FOR z IN cr_table_columns LOOP
                    IF objects.object_name = z.table_name THEN
                        dbms_output.put_line('  ' || z.column_name || ' ' || z.data_type || '(' || z.data_length || ')' 
                        || CASE WHEN z.nullable = 'N' THEN ' NOT NULL' END || ',');
                    END IF;
                END LOOP;
                    dbms_output.put_line(');');
                
            END IF;
        END LOOP;
        
        -- HANDLING WITH INDEXES ================================================       
        FOR indexe IN cr_indexes LOOP
            IF  objects.object_type = 'INDEX' AND indexe.index_name = objects.object_name
            THEN
                dbms_output.put_line('USUARIO: ' || username);
                dbms_output.put_line('NOME DO OBJETO: ' || objects.object_name || '           ' || 'DATA CRIACAO: ' || TO_CHAR(objects.created, 'DD/MM/YYYY') || '          ' || 'TIPO DO OBJETO: ' || objects.object_type);
                dbms_output.put_line('DDL: ');
                dbms_output.put_line('CREATE INDEX ' || indexe.index_name);
                dbms_output.put('ON ' || indexe.table_name || '(');
                FOR z IN cr_indexes_column_name LOOP
                    IF z.index_name = indexe.index_name THEN
                        dbms_output.put(z.column_name || ',');
                    END IF;
                END LOOP;
                dbms_output.put_line(');');

                
            END IF;
        END LOOP;
    
    
        -- OTHERS ================================================           
        IF objects.object_type <> 'TABLE' AND objects.object_type <> 'INDEX'
            THEN
                dbms_output.put_line('USUARIO: ' || username);
                dbms_output.put_line('NOME DO OBJETO: ' || objects.object_name || '           ' || 'DATA CRIACAO: ' || TO_CHAR(objects.created, 'DD/MM/YYYY') || '          ' || 'TIPO DO OBJETO: ' || objects.object_type);
                dbms_output.put_line('DDL: ');
                
                FOR sources IN cr_sources LOOP
                    IF objects.object_name = sources.name 
                    THEN
                        IF objects.object_type <> 'TABLE'
                        THEN
                            dbms_output.put(sources.text);
                        END IF;
                        
                    END IF;
                END LOOP;
        END IF;
        
        
        dbms_output.put_line('');
        dbms_output.put_line('############################################################################################');
        dbms_output.put_line('############################################################################################');
        dbms_output.put_line('');

    END LOOP;
    

END;
/

CLEAR SCREEN;
SET SERVEROUTPUT ON;
CALL pr_inventario();