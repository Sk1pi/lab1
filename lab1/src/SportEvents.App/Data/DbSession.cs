using Microsoft.Data.SqlClient;

namespace SportEvents.App.Data;

public sealed class DbSession
{
    public DbSession(SqlConnection connection, SqlTransaction transaction, int currentUserId)
    {
        Connection = connection;
        Transaction = transaction;
        CurrentUserId = currentUserId;
    }

    public SqlConnection Connection { get; }
    public SqlTransaction Transaction { get; }
    public int CurrentUserId { get; }
}
