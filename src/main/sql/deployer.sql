CREATE OR REPLACE PROCEDURE deploy_code AS
    l_owner     varchar2(100) := 'loiclefevre';
    l_repo_name varchar2(100) := 'adb_jsp';
    l_repo CLOB;
    l_file_content CLOB;
    l_plsqlspec_content CLOB;

    l_cursor NUMBER;

    l_last_edition VARCHAR2(4000);

    edition_already_exist exception;
    PRAGMA EXCEPTION_INIT(edition_already_exist, -955);
BEGIN
    select object_name into l_last_edition
    from all_objects
    where object_type='EDITION'
    order by timestamp desc
        fetch first 1 ROW ONLY;

    l_repo := DBMS_CLOUD_REPO.init_github_repo(
            repo_name       => l_repo_name,
            owner           => l_owner
        );

    for c in (SELECT 'v'||ID as commit_id,
                     name,
                     regexp_substr(name,'[^/]*$') as short_name,
                     replace(regexp_substr(name,'[^/]*$'),'.java','') as class_name,
                     replace(replace(substr(name,1,length(name)-5), 'src/main/java/',''),'/','/') as fqcn
              FROM DBMS_CLOUD_REPO.LIST_FILES(repo => l_repo)
              WHERE name like '%.java')
        LOOP
            DBMS_OUTPUT.put_line('File: ' || c.short_name || ' (' || c.fqcn || ')');

            l_file_content := DBMS_CLOUD_REPO.GET_FILE(
                    repo             => l_repo,
                    file_path        => c.name
                );

            l_plsqlspec_content := DBMS_CLOUD_REPO.GET_FILE(
                    repo             => l_repo,
                    file_path        => replace(c.name, '.java', '.sql')
                );
            -- DBMS_OUTPUT.put_line('File content: ' || l_file_content);

            begin
               execute immediate 'create edition ' || c.commit_id || ' as child of ' || l_last_edition;
            exception
                when edition_already_exist then null;
                when others then raise;
            end;

            -- dbms_output.put_line('create or replace and compile java source named "' || c.fqcn || c.commit_id || '" AS ' || replace( l_file_content, c.class_name, c.class_name || c.commit_id));
            execute immediate 'create or replace and compile java source named "' || c.fqcn || c.commit_id || '" AS ' || replace( l_file_content, c.class_name, c.class_name || c.commit_id);

            -- dbms_output.put_line( replace( l_plsqlspec_content, c.class_name, c.class_name || c.commit_id) );

            l_cursor := dbms_sql.open_cursor();
            dbms_sql.parse(c => l_cursor,
                           statement => replace( l_plsqlspec_content, c.class_name, c.class_name || c.commit_id),
                           language_flag => dbms_sql.native,
                           edition => c.commit_id);
            dbms_sql.close_cursor(l_cursor);

            execute immediate 'ALTER DATABASE DEFAULT EDITION = ' || c.commit_id;

            -- Now force reconnection
            for u in (select inst_id, sid, serial# from gv$session where sid != (SELECT SYS_CONTEXT('userenv', 'sessionid') FROM DUAL))
                loop
                    execute immediate 'alter system disconnect session ''' || u.sid || ',' || u.serial# || ''' post_transaction immediate';
                end loop;

        END LOOP;
END;

/
