USE SportEventsDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE UNIQUE NONCLUSTERED INDEX UX_Users_Email_Active
    ON dbo.Users (Email)
    WHERE IsDeleted = 0;

CREATE UNIQUE NONCLUSTERED INDEX UX_Tickets_Seat_Active
    ON dbo.Tickets (EventId, SectorId, RowNumber, SeatNumber)
    WHERE Status IN (N'Reserved', N'Sold', N'Used');

CREATE UNIQUE NONCLUSTERED INDEX UX_TeamMembers_Jersey_Active
    ON dbo.TeamMembers (TeamId, JerseyNumber)
    WHERE LeftAt IS NULL;

CREATE NONCLUSTERED INDEX IX_Events_StartTime_Covering
    ON dbo.Events (StartTime, Status)
    INCLUDE (TournamentId, VenueId, HomeTeamId, AwayTeamId, BaseTicketPrice)
    WHERE IsDeleted = 0;

CREATE NONCLUSTERED INDEX IX_Events_Tournament   ON dbo.Events (TournamentId) WHERE IsDeleted = 0;
CREATE NONCLUSTERED INDEX IX_Events_Venue_Start  ON dbo.Events (VenueId, StartTime);
CREATE NONCLUSTERED INDEX IX_Events_HomeTeam     ON dbo.Events (HomeTeamId);
CREATE NONCLUSTERED INDEX IX_Events_AwayTeam     ON dbo.Events (AwayTeamId);
CREATE NONCLUSTERED INDEX IX_Teams_Sport_Name    ON dbo.Teams (SportId, Name) WHERE IsDeleted = 0;
CREATE NONCLUSTERED INDEX IX_TeamMembers_Athlete ON dbo.TeamMembers (AthleteId);
CREATE NONCLUSTERED INDEX IX_Tickets_Order       ON dbo.Tickets (OrderId);
CREATE NONCLUSTERED INDEX IX_Payments_Order      ON dbo.Payments (OrderId);
CREATE NONCLUSTERED INDEX IX_Orders_User_Date    ON dbo.Orders (UserId, OrderDate DESC) WHERE IsDeleted = 0;
CREATE NONCLUSTERED INDEX IX_AuditLog_Record     ON dbo.AuditLog (TableName, RecordId, ChangedAt DESC);

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_Tickets_Analytics
    ON dbo.Tickets (EventId, SectorId, Price, Status, CreatedAt);
GO
