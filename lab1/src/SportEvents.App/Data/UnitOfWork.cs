using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using SportEvents.App.Repositories;

namespace SportEvents.App.Data;

public sealed class UnitOfWork : IUnitOfWork
{
    private readonly DbSession _session;
    private ITeamRepository? _teams;
    private IEventRepository? _events;
    private IEventResultRepository? _results;
    private bool _completed;

    private UnitOfWork(DbSession session) => _session = session;

    public static async Task<UnitOfWork> BeginAsync(string connectionString, int currentUserId)
    {
        var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        await connection.ExecuteAsync(
            "sys.sp_set_session_context",
            new { key = "UserId", value = currentUserId },
            commandType: CommandType.StoredProcedure);

        var transaction = connection.BeginTransaction(IsolationLevel.ReadCommitted);
        return new UnitOfWork(new DbSession(connection, transaction, currentUserId));
    }

    public ITeamRepository Teams => _teams ??= new TeamRepository(_session);
    public IEventRepository Events => _events ??= new EventRepository(_session);
    public IEventResultRepository Results => _results ??= new EventResultRepository(_session);

    public async Task CommitAsync()
    {
        EnsureActive();
        await _session.Transaction.CommitAsync();
        _completed = true;
    }

    public async Task RollbackAsync()
    {
        EnsureActive();
        if (_session.Transaction.Connection is not null)
            await _session.Transaction.RollbackAsync();
        _completed = true;
    }

    public async ValueTask DisposeAsync()
    {
        if (!_completed && _session.Transaction.Connection is not null)
            await _session.Transaction.RollbackAsync();

        await _session.Transaction.DisposeAsync();
        await _session.Connection.DisposeAsync();
    }

    private void EnsureActive()
    {
        if (_completed)
            throw new InvalidOperationException("Цю одиницю роботи вже завершено.");
    }
}
