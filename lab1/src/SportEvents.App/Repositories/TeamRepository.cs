using System.Data;
using Dapper;
using SportEvents.App.Data;
using SportEvents.App.Models;

namespace SportEvents.App.Repositories;

public sealed class TeamRepository : ITeamRepository
{
    private readonly DbSession _s;

    public TeamRepository(DbSession session) => _s = session;

    public Task<TeamView?> GetByIdAsync(int teamId) =>
        _s.Connection.QuerySingleOrDefaultAsync<TeamView>(
            "SELECT * FROM dbo.vw_ActiveTeams WHERE TeamId = @teamId",
            new { teamId }, _s.Transaction);

    public async Task<IReadOnlyList<TeamView>> GetBySportAsync(int sportId) =>
        (await _s.Connection.QueryAsync<TeamView>(
            "SELECT * FROM dbo.vw_ActiveTeams WHERE SportId = @sportId ORDER BY Name",
            new { sportId }, _s.Transaction)).AsList();

    public async Task<IReadOnlyList<RosterItem>> GetRosterAsync(int teamId) =>
        (await _s.Connection.QueryAsync<RosterItem>(
            "SELECT * FROM dbo.vw_TeamRoster WHERE TeamId = @teamId ORDER BY JerseyNumber",
            new { teamId }, _s.Transaction)).AsList();

    public async Task<int> CreateAsync(NewTeam team)
    {
        var p = new DynamicParameters();
        p.Add("SportId", team.SportId);
        p.Add("Name", team.Name);
        p.Add("City", team.City);
        p.Add("FoundedYear", team.FoundedYear, DbType.Int16);
        p.Add("ChangedBy", _s.CurrentUserId);
        p.Add("TeamId", dbType: DbType.Int32, direction: ParameterDirection.Output);

        await _s.Connection.ExecuteAsync("dbo.sp_Team_Create", p, _s.Transaction,
            commandType: CommandType.StoredProcedure);

        return p.Get<int>("TeamId");
    }

    public Task UpdateAsync(UpdateTeam team) =>
        _s.Connection.ExecuteAsync("dbo.sp_Team_Update",
            new { team.TeamId, team.Name, team.City, team.FoundedYear, ChangedBy = _s.CurrentUserId },
            _s.Transaction, commandType: CommandType.StoredProcedure);

    public Task SoftDeleteAsync(int teamId) =>
        _s.Connection.ExecuteAsync("dbo.sp_Team_SoftDelete",
            new { TeamId = teamId, ChangedBy = _s.CurrentUserId },
            _s.Transaction, commandType: CommandType.StoredProcedure);

    public Task RegisterInTournamentAsync(int tournamentId, int teamId, string? groupName) =>
        _s.Connection.ExecuteAsync("dbo.sp_Tournament_RegisterTeam",
            new { TournamentId = tournamentId, TeamId = teamId, GroupName = groupName },
            _s.Transaction, commandType: CommandType.StoredProcedure);
}
