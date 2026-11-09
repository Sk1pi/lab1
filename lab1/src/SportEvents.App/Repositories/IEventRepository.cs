using SportEvents.App.Models;

namespace SportEvents.App.Repositories;

public interface IEventRepository
{
    Task<EventView?> GetByIdAsync(int eventId);
    Task<IReadOnlyList<EventView>> GetScheduleAsync(DateTime from, DateTime to);
    Task<IReadOnlyList<EventView>> GetByTournamentAsync(int tournamentId);
    Task<IReadOnlyList<DeletedEventView>> GetDeletedAsync();
    Task<IReadOnlyList<AuditEntry>> GetHistoryAsync(int eventId);

    Task<int> CreateAsync(NewEvent newEvent);
    Task UpdateAsync(UpdateEvent changes);
    Task SoftDeleteAsync(int eventId);
    Task RestoreAsync(int eventId);
}
