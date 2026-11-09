namespace SportEvents.App.Models;

public sealed class EventView
{
    public int EventId { get; set; }
    public int TournamentId { get; set; }
    public string TournamentName { get; set; } = "";
    public string SportName { get; set; } = "";
    public int VenueId { get; set; }
    public string VenueName { get; set; } = "";
    public string City { get; set; } = "";
    public int HomeTeamId { get; set; }
    public string HomeTeamName { get; set; } = "";
    public int AwayTeamId { get; set; }
    public string AwayTeamName { get; set; } = "";
    public DateTime StartTime { get; set; }
    public string Status { get; set; } = "";
    public decimal BaseTicketPrice { get; set; }
    public short? HomeScore { get; set; }
    public short? AwayScore { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }

    public override string ToString() =>
        $"#{EventId} {StartTime:dd.MM HH:mm} {HomeTeamName} — {AwayTeamName}" +
        (HomeScore is null ? $" [{Status}]" : $" {HomeScore}:{AwayScore}");
}

public sealed class DeletedEventView
{
    public int EventId { get; set; }
    public int TournamentId { get; set; }
    public string HomeTeamName { get; set; } = "";
    public string AwayTeamName { get; set; } = "";
    public DateTime StartTime { get; set; }
    public DateTime? DeletedAt { get; set; }
    public int? DeletedBy { get; set; }
    public string? DeletedByName { get; set; }
}

public sealed class TeamView
{
    public int TeamId { get; set; }
    public string Name { get; set; } = "";
    public string City { get; set; } = "";
    public short? FoundedYear { get; set; }
    public int SportId { get; set; }
    public string SportName { get; set; } = "";
    public int ActivePlayers { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}

public sealed class RosterItem
{
    public int TeamId { get; set; }
    public string TeamName { get; set; } = "";
    public int AthleteId { get; set; }
    public string FullName { get; set; } = "";
    public byte JerseyNumber { get; set; }
    public string? Position { get; set; }
    public DateTime JoinedAt { get; set; }
}

public sealed class TournamentStanding
{
    public int TournamentId { get; set; }
    public int TeamId { get; set; }
    public string TeamName { get; set; } = "";
    public string? GroupName { get; set; }
    public int Played { get; set; }
    public int Wins { get; set; }
    public int Draws { get; set; }
    public int Losses { get; set; }
    public int GoalsFor { get; set; }
    public int GoalsAgainst { get; set; }
    public int Points { get; set; }
    public int GoalDifference => GoalsFor - GoalsAgainst;
}

public sealed class AuditEntry
{
    public long AuditId { get; set; }
    public string TableName { get; set; } = "";
    public int RecordId { get; set; }
    public string Action { get; set; } = "";
    public int? ChangedBy { get; set; }
    public string? ChangedByName { get; set; }
    public DateTime ChangedAt { get; set; }
    public string? OldData { get; set; }
    public string? NewData { get; set; }
}

public sealed record NewTeam(int SportId, string Name, string City, short? FoundedYear);

public sealed record UpdateTeam(int TeamId, string Name, string City, short? FoundedYear);

public sealed record NewEvent(
    int TournamentId, int VenueId, int HomeTeamId, int AwayTeamId,
    DateTime StartTime, decimal BaseTicketPrice);

public sealed record UpdateEvent(
    int EventId, int VenueId, DateTime StartTime, string Status, decimal BaseTicketPrice);
