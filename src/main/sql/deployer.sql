CREATE OR REPLACE PROCEDURE deploy_code AS
    l_owner     varchar2(100) := 'loiclefevre';
    l_repo_name varchar2(100) := 'adb_jsp';
    l_repo CLOB;
    l_file_content CLOB;
    l_plsqlspec_content CLOB;

    l_cursor NUMBER;
BEGIN
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

            execute immediate 'create edition ' || c.commit_id;


            dbms_output.put_line('create or replace and compile java source named "' || c.fqcn || c.commit_id || '" AS ' || replace( l_file_content, c.class_name, c.class_name || c.commit_id));
            execute immediate 'create or replace and compile java source named "' || c.fqcn || c.commit_id || '" AS ' || replace( l_file_content, c.class_name, c.class_name || c.commit_id);

            dbms_output.put_line( replace( l_plsqlspec_content, c.class_name, c.class_name || c.commit_id) );

            l_cursor := dbms_sql.open_cursor();
            dbms_sql.parse(c => l_cursor,
                           statement => replace( l_plsqlspec_content, c.class_name, c.class_name || c.commit_id),
                           language_flag => dbms_sql.native,
                           edition => c.commit_id);
            dbms_sql.close_cursor(l_cursor);

        END LOOP;
END;

/