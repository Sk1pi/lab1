using SportEvents.App.Models;

namespace SportEvents.App.Repositories;

public interface IEventResultRepository
{
    Task SetAsync(int eventId, short homeScore, short awayScore, string? notes = null);
    Task<IReadOnlyList<TournamentStanding>> GetStandingsAsync(int tournamentId);
}
