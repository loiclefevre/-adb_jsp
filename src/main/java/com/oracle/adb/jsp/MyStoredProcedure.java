package com.oracle.adb.jsp;

import java.sql.SQLException;

/**
 * Java Stored Procedure!
 */
public class MyStoredProcedure {
	public static String hello(String name) throws SQLException {
		return String.format("Hello %s!", name == null ? "World" : name);
	}
}
