using System.Data;
using Dapper;
using SportEvents.App.Data;
using SportEvents.App.Models;

namespace SportEvents.App.Repositories;

public sealed class EventRepository : IEventRepository
{
    private readonly DbSession _s;

    public EventRepository(DbSession session) => _s = session;

    public Task<EventView?> GetByIdAsync(int eventId) =>
        _s.Connection.QuerySingleOrDefaultAsync<EventView>(
            "SELECT * FROM dbo.vw_ActiveEvents WHERE EventId = @eventId",
            new { eventId }, _s.Transaction);

    public async Task<IReadOnlyList<EventView>> GetScheduleAsync(DateTime from, DateTime to) =>
        (await _s.Connection.QueryAsync<EventView>(
            "SELECT * FROM dbo.vw_ActiveEvents WHERE StartTime >= @from AND StartTime < @to ORDER BY StartTime",
            new { from, to }, _s.Transaction)).AsList();

    public async Task<IReadOnlyList<EventView>> GetByTournamentAsync(int tournamentId) =>
        (await _s.Connection.QueryAsync<EventView>(
            "SELECT * FROM dbo.vw_ActiveEvents WHERE TournamentId = @tournamentId ORDER BY StartTime",
            new { tournamentId }, _s.Transaction)).AsList();

    public async Task<IReadOnlyList<DeletedEventView>> GetDeletedAsync() =>
        (await _s.Connection.QueryAsync<DeletedEventView>(
            "SELECT * FROM dbo.vw_DeletedEvents ORDER BY DeletedAt DESC",
            transaction: _s.Transaction)).AsList();

    public async Task<IReadOnlyList<AuditEntry>> GetHistoryAsync(int eventId) =>
        (await _s.Connection.QueryAsync<AuditEntry>(
            "dbo.sp_Audit_GetHistory",
            new { TableName = "Events", RecordId = eventId },
            _s.Transaction, commandType: CommandType.StoredProcedure)).AsList();

    public async Task<int> CreateAsync(NewEvent e)
    {
        var p = new DynamicParameters();
        p.Add("TournamentId", e.TournamentId);
        p.Add("VenueId", e.VenueId);
        p.Add("HomeTeamId", e.HomeTeamId);
        p.Add("AwayTeamId", e.AwayTeamId);
        p.Add("StartTime", e.StartTime, DbType.DateTime2);
        p.Add("BaseTicketPrice", e.BaseTicketPrice, DbType.Decimal, precision: 10, scale: 2);
        p.Add("ChangedBy", _s.CurrentUserId);
        p.Add("EventId", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await _s.Connection.ExecuteAsync("dbo.sp_Event_Create", p, _s.Transaction,
            commandType: CommandType.StoredProcedure);

        return p.Get<int>("EventId");
    }

    public Task UpdateAsync(UpdateEvent c)
    {
        var p = new DynamicParameters();
        p.Add("EventId", c.EventId);
        p.Add("VenueId", c.VenueId);
        p.Add("StartTime", c.StartTime, DbType.DateTime2);
        p.Add("Status", c.Status);
        p.Add("BaseTicketPrice", c.BaseTicketPrice, DbType.Decimal, precision: 10, scale: 2);
        p.Add("ChangedBy", _s.CurrentUserId);

        return _s.Connection.ExecuteAsync("dbo.sp_Event_Update", p, _s.Transaction,
            commandType: CommandType.StoredProcedure);
    }

    public Task SoftDeleteAsync(int eventId) =>
        _s.Connection.ExecuteAsync("dbo.sp_Event_SoftDelete",
            new { EventId = eventId, ChangedBy = _s.CurrentUserId },
            _s.Transaction, commandType: CommandType.StoredProcedure);

    public Task RestoreAsync(int eventId) =>
        _s.Connection.ExecuteAsync("dbo.sp_Event_Restore",
            new { EventId = eventId, ChangedBy = _s.CurrentUserId },
            _s.Transaction, commandType: CommandType.StoredProcedure);
}
