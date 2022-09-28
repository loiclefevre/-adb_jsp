package com.oracle.adb.jsp;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class CopyEx {
	public static void copyCollection(String collectionName, String credentialName, String fileURIList, String format) throws SQLException {
		try (Connection c = DriverManager.getConnection("jdbc:default:connection:")) {
			try (PreparedStatement p = c.prepareStatement("select OBJECT_NAME, BYTES from table(dbms_cloud.list_objects(credential_name => ?, location_uri => ?))")) {
				p.setString(1, credentialName);
				p.setString(2, fileURIList);
				try (ResultSet r = p.executeQuery()) {
					while (r.next()) {
						System.out.println("- object: " + r.getString(1) + " with size: " + r.getLong(2) + " bytes");
					}
				}
			}
		}
	}
}
