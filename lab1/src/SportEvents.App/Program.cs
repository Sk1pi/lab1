using System.Text;
using Microsoft.Data.SqlClient;
using SportEvents.App.Data;
using SportEvents.App.Models;

Console.OutputEncoding = Encoding.UTF8;

const string ConnectionString =
    "Server=localhost,1433;Database=SportEventsDb;Trusted_Connection=True;TrustServerCertificate=True;";

const int OrganizerId = 2;
const int FootballId = 1;
const int CupId = 1;

int newEventId;

Console.WriteLine("=== 1. Створення команди та матчу в одній транзакції ===");
await using (var uow = await UnitOfWork.BeginAsync(ConnectionString, OrganizerId))
{
    var teamId = await uow.Teams.CreateAsync(
        new NewTeam(FootballId, $"Сталеві Вовки {Random.Shared.Next(100, 999)}", "Запоріжжя", 2015));

    await uow.Teams.RegisterInTournamentAsync(CupId, teamId, "A");

    newEventId = await uow.Events.CreateAsync(new NewEvent(
        TournamentId: CupId,
        VenueId: 2,
        HomeTeamId: teamId,
        AwayTeamId: 1,
        StartTime: new DateTime(2026, 12, 1, 12, 0, 0).AddDays(Random.Shared.Next(0, 14)).AddHours(Random.Shared.Next(0, 3) * 4),
        BaseTicketPrice: 250m));

    var created = await uow.Events.GetByIdAsync(newEventId);

    await uow.CommitAsync();
    Console.WriteLine($"Створено: {created}");
}

Console.WriteLine("\n=== 2. Результат матчу і турнірна таблиця ===");
await using (var uow = await UnitOfWork.BeginAsync(ConnectionString, OrganizerId))
{
    await uow.Results.SetAsync(newEventId, homeScore: 3, awayScore: 1, notes: "Хет-трик капітана");
    await uow.CommitAsync();
}

await using (var uow = await UnitOfWork.BeginAsync(ConnectionString, OrganizerId))
{
    Console.WriteLine($"{"Команда",-26} {"І",3} {"В",3} {"Н",3} {"П",3} {"М'ячі",7} {"О",4}");
    foreach (var row in await uow.Results.GetStandingsAsync(CupId))
        Console.WriteLine($"{row.TeamName,-26} {row.Played,3} {row.Wins,3} {row.Draws,3} {row.Losses,3} " +
                          $"{row.GoalsFor + ":" + row.GoalsAgainst,7} {row.Points,4}");

    Console.WriteLine("\nСклад команди «Сокіл»:");
    foreach (var p in await uow.Teams.GetRosterAsync(1))
        Console.WriteLine($"  #{p.JerseyNumber,-3} {p.FullName} ({p.Position})");
}

Console.WriteLine("\n=== 3. Відкат транзакції при помилці ===");
var tempTeamName = $"Тимчасова команда {Random.Shared.Next(100, 999)}";
try
{
    await using var uow = await UnitOfWork.BeginAsync(ConnectionString, OrganizerId);

    var teamId = await uow.Teams.CreateAsync(new NewTeam(FootballId, tempTeamName, "Полтава", null));
    await uow.Teams.RegisterInTournamentAsync(CupId, teamId, "B");

    await uow.Events.CreateAsync(new NewEvent(CupId, 1, teamId, 2, new DateTime(2026, 11, 20, 20, 0, 0), 100m));

    await uow.CommitAsync();
}
catch (SqlException ex) when (ex.Number >= 50000)
{
    Console.WriteLine($"Бізнес-помилка {ex.Number}: {ex.Message}");
}

await using (var uow = await UnitOfWork.BeginAsync(ConnectionString, OrganizerId))
{
    var exists = (await uow.Teams.GetBySportAsync(FootballId)).Any(t => t.Name == tempTeamName);
    Console.WriteLine($"Команда «{tempTeamName}» у БД: {(exists ? "так (помилка!)" : "ні — відкат спрацював")}");
}

Console.WriteLine("\n=== 4. Soft delete та аудит ===");
await using (var uow = await UnitOfWork.BeginAsync(ConnectionString, OrganizerId))
{
    await uow.Events.SoftDeleteAsync(newEventId);
    Console.WriteLine($"Після видалення GetById: {(await uow.Events.GetByIdAsync(newEventId))?.ToString() ?? "null"}");

    foreach (var d in await uow.Events.GetDeletedAsync())
        Console.WriteLine($"  У кошику: #{d.EventId} {d.HomeTeamName} — {d.AwayTeamName}, видалив {d.DeletedByName}");

    await uow.Events.RestoreAsync(newEventId);
    await uow.CommitAsync();
}

await using (var uow = await UnitOfWork.BeginAsync(ConnectionString, OrganizerId))
{
    Console.WriteLine($"Після відновлення: {await uow.Events.GetByIdAsync(newEventId)}");
    Console.WriteLine("Історія змін:");
    foreach (var a in await uow.Events.GetHistoryAsync(newEventId))
        Console.WriteLine($"  {a.ChangedAt:dd.MM HH:mm:ss} {a.Action,-8} {a.ChangedByName}: {a.NewData}");
}
