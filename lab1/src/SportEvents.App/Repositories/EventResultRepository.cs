using System.Data;
using Dapper;
using SportEvents.App.Data;
using SportEvents.App.Models;

namespace SportEvents.App.Repositories;

public sealed class EventResultRepository : IEventResultRepository
{
    private readonly DbSession _s;

    public EventResultRepository(DbSession session) => _s = session;

    public Task SetAsync(int eventId, short homeScore, short awayScore, string? notes = null) =>
        _s.Connection.ExecuteAsync("dbo.sp_EventResult_Set",
            new
            {
                EventId = eventId,
                HomeScore = homeScore,
                AwayScore = awayScore,
                Notes = notes,
                ChangedBy = _s.CurrentUserId
            },
            _s.Transaction, commandType: CommandType.StoredProcedure);

    public async Task<IReadOnlyList<TournamentStanding>> GetStandingsAsync(int tournamentId) =>
        (await _s.Connection.QueryAsync<TournamentStanding>(
            "dbo.sp_Tournament_GetStandings",
            new { TournamentId = tournamentId },
            _s.Transaction, commandType: CommandType.StoredProcedure)).AsList();
}
