using SportEvents.App.Repositories;

namespace SportEvents.App.Data;

public interface IUnitOfWork : IAsyncDisposable
{
    ITeamRepository Teams { get; }
    IEventRepository Events { get; }
    IEventResultRepository Results { get; }

    Task CommitAsync();
    Task RollbackAsync();
}
