CREATE OR REPLACE PROCEDURE deploy_code AS
    l_owner     varchar2(100) := 'loiclefevre';
    l_repo_name varchar2(100) := 'adb_jsp';
    l_repo CLOB;
    l_file_content CLOB;
BEGIN
    l_repo := DBMS_CLOUD_REPO.init_github_repo(
            repo_name       => l_repo_name,
            owner           => l_owner
        );

    for c in (SELECT name,
                     regexp_substr(name,'[^/]*$') as short_name,
                     replace(replace(substr(name,1,length(name)-5), 'src/main/java/',''),'/','/') as fqcn
                FROM DBMS_CLOUD_REPO.LIST_FILES(repo => l_repo)
               WHERE name like '%.java')
        LOOP
            DBMS_OUTPUT.put_line('File: ' || c.short_name || ' (' || c.fqcn || ')');

            l_file_content := DBMS_CLOUD_REPO.GET_FILE(
                    repo             => l_repo,
                    file_path        => c.name
                );
            -- DBMS_OUTPUT.put_line('File content: ' || l_file_content);

            -- dbms_output.put_line('create or replace and compile java source named "' || c.fqcn || '" AS ' || l_file_content);
            execute immediate 'create or replace and compile java source named "' || c.fqcn || '" AS ' || l_file_content;

            DBMS_CLOUD_REPO.INSTALL_FILE(
                    repo             => l_repo,
                    file_path        => replace(c.name, '.java', '.sql'),
                    stop_on_error    => true
                );
        END LOOP;
END;

/
