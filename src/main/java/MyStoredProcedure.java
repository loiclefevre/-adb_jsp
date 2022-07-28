import java.sql.SQLException;

public class MyStoredProcedure {
	public static String main(String name) throws SQLException {
/*		try (Connection c = DriverManager.getConnection("jdbc:default:connection:")) {
			try(Statement s = c.createStatement()) {
				try( ResultSet r = s.executeQuery("SELECT current_date FROM dual")) {
					if(r.next()) {
						return String.format( "Hello %s, today is %s!", name == null ? "World" : name, r.getString(1));
					}
				}
			}*/
		return String.format("Hello %s!", name == null ? "World" : name);
		//}
	}
}
