package com.oracle.adb.jsp;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * Java Stored Procedure!
 */
public class MyStoredProcedure {
	public static String hello(String name) throws SQLException {
		try (Connection c = DriverManager.getConnection("jdbc:default:connection:")) {
			try (Statement s = c.createStatement()) {
				try (ResultSet r = s.executeQuery("SELECT current_date FROM dual")) {
					if (r.next()) {
						return String.format("Hello %s. For your information today is %s!",
								name == null ? "World" : name, r.getString(1));
					}
				}
			}
		}

		return String.format("Hello %s!", name == null ? "World" : name);
	}
}
