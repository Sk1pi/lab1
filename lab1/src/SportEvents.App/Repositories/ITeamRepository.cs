using SportEvents.App.Models;

namespace SportEvents.App.Repositories;

public interface ITeamRepository
{
    Task<TeamView?> GetByIdAsync(int teamId);
    Task<IReadOnlyList<TeamView>> GetBySportAsync(int sportId);
    Task<IReadOnlyList<RosterItem>> GetRosterAsync(int teamId);

    Task<int> CreateAsync(NewTeam team);
    Task UpdateAsync(UpdateTeam team);
    Task SoftDeleteAsync(int teamId);
    Task RegisterInTournamentAsync(int tournamentId, int teamId, string? groupName);
}
