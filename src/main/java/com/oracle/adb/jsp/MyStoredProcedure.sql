CREATE OR REPLACE FUNCTION hello(name VARCHAR2) RETURN VARCHAR2 AS LANGUAGE JAVA
    NAME 'com.oracle.adb.jsp.MyStoredProcedure.hello(java.lang.String) return java.lang.String';
