USE SportEventsDb;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_CurrentUserId()
RETURNS INT
AS
BEGIN
    RETURN TRY_CAST(SESSION_CONTEXT(N'UserId') AS INT);
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_GetTicketPrice(@EventId INT, @SectorId INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @price DECIMAL(10,2);

    SELECT @price = CAST(e.BaseTicketPrice * vs.PriceMultiplier AS DECIMAL(10,2))
    FROM dbo.Events e
    JOIN dbo.VenueSectors vs ON vs.VenueId = e.VenueId
    WHERE e.EventId = @EventId
      AND vs.SectorId = @SectorId
      AND e.IsDeleted = 0;

    RETURN @price;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_GetAvailableSeats(@EventId INT)
RETURNS INT
AS
BEGIN
    DECLARE @capacity INT, @taken INT;

    SELECT @capacity = SUM(CAST(vs.RowsCount AS INT) * vs.SeatsPerRow)
    FROM dbo.Events e
    JOIN dbo.VenueSectors vs ON vs.VenueId = e.VenueId
    WHERE e.EventId = @EventId;

    SELECT @taken = COUNT(*)
    FROM dbo.Tickets
    WHERE EventId = @EventId
      AND Status IN (N'Reserved', N'Sold', N'Used');

    RETURN ISNULL(@capacity, 0) - @taken;
END;
GO

CREATE OR ALTER VIEW dbo.vw_ActiveEvents
AS
SELECT
    e.EventId,
    e.TournamentId,
    t.Name          AS TournamentName,
    s.Name          AS SportName,
    e.VenueId,
    v.Name          AS VenueName,
    v.City,
    e.HomeTeamId,
    ht.Name         AS HomeTeamName,
    e.AwayTeamId,
    awt.Name        AS AwayTeamName,
    e.StartTime,
    e.Status,
    e.BaseTicketPrice,
    r.HomeScore,
    r.AwayScore,
    e.CreatedAt,
    e.UpdatedAt,
    e.UpdatedBy
FROM dbo.Events e
JOIN dbo.Tournaments t   ON t.TournamentId = e.TournamentId
JOIN dbo.Sports s        ON s.SportId = t.SportId
JOIN dbo.Venues v        ON v.VenueId = e.VenueId
JOIN dbo.Teams ht        ON ht.TeamId = e.HomeTeamId
JOIN dbo.Teams awt       ON awt.TeamId = e.AwayTeamId
LEFT JOIN dbo.EventResults r ON r.EventId = e.EventId
WHERE e.IsDeleted = 0
  AND t.IsDeleted = 0;
GO

CREATE OR ALTER VIEW dbo.vw_DeletedEvents
AS
SELECT
    e.EventId,
    e.TournamentId,
    ht.Name     AS HomeTeamName,
    awt.Name    AS AwayTeamName,
    e.StartTime,
    e.DeletedAt,
    e.UpdatedBy AS DeletedBy,
    u.FullName  AS DeletedByName
FROM dbo.Events e
JOIN dbo.Teams ht      ON ht.TeamId = e.HomeTeamId
JOIN dbo.Teams awt     ON awt.TeamId = e.AwayTeamId
LEFT JOIN dbo.Users u  ON u.UserId = e.UpdatedBy
WHERE e.IsDeleted = 1;
GO

CREATE OR ALTER VIEW dbo.vw_ActiveTeams
AS
SELECT
    tm.TeamId,
    tm.Name,
    tm.City,
    tm.FoundedYear,
    tm.SportId,
    s.Name AS SportName,
    (SELECT COUNT(*)
       FROM dbo.TeamMembers m
       JOIN dbo.Athletes a ON a.AthleteId = m.AthleteId
      WHERE m.TeamId = tm.TeamId AND m.LeftAt IS NULL AND a.IsDeleted = 0) AS ActivePlayers,
    tm.CreatedAt,
    tm.UpdatedAt,
    tm.UpdatedBy
FROM dbo.Teams tm
JOIN dbo.Sports s ON s.SportId = tm.SportId
WHERE tm.IsDeleted = 0;
GO

CREATE OR ALTER VIEW dbo.vw_TeamRoster
AS
SELECT
    tm.TeamId,
    tm.Name                            AS TeamName,
    a.AthleteId,
    a.FirstName + N' ' + a.LastName    AS FullName,
    m.JerseyNumber,
    m.Position,
    m.JoinedAt
FROM dbo.TeamMembers m
JOIN dbo.Teams tm   ON tm.TeamId = m.TeamId
JOIN dbo.Athletes a ON a.AthleteId = m.AthleteId
WHERE m.LeftAt IS NULL
  AND tm.IsDeleted = 0
  AND a.IsDeleted = 0;
GO

CREATE OR ALTER VIEW dbo.vw_TournamentStandings
AS
WITH Games AS (
    SELECT e.TournamentId, e.HomeTeamId AS TeamId, r.HomeScore AS GF, r.AwayScore AS GA
    FROM dbo.Events e
    JOIN dbo.EventResults r ON r.EventId = e.EventId
    WHERE e.IsDeleted = 0 AND e.Status = N'Finished'
    UNION ALL
    SELECT e.TournamentId, e.AwayTeamId, r.AwayScore, r.HomeScore
    FROM dbo.Events e
    JOIN dbo.EventResults r ON r.EventId = e.EventId
    WHERE e.IsDeleted = 0 AND e.Status = N'Finished'
)
SELECT
    tt.TournamentId,
    tt.TeamId,
    tm.Name AS TeamName,
    tt.GroupName,
    COUNT(g.TeamId)                                                       AS Played,
    SUM(CASE WHEN g.GF > g.GA THEN 1 ELSE 0 END)                          AS Wins,
    SUM(CASE WHEN g.GF = g.GA THEN 1 ELSE 0 END)                          AS Draws,
    SUM(CASE WHEN g.GF < g.GA THEN 1 ELSE 0 END)                          AS Losses,
    ISNULL(SUM(CAST(g.GF AS INT)), 0)                                     AS GoalsFor,
    ISNULL(SUM(CAST(g.GA AS INT)), 0)                                     AS GoalsAgainst,
    SUM(CASE WHEN g.GF > g.GA THEN 3 WHEN g.GF = g.GA THEN 1 ELSE 0 END)  AS Points
FROM dbo.TournamentTeams tt
JOIN dbo.Teams tm ON tm.TeamId = tt.TeamId
LEFT JOIN Games g ON g.TournamentId = tt.TournamentId AND g.TeamId = tt.TeamId
WHERE tm.IsDeleted = 0
GROUP BY tt.TournamentId, tt.TeamId, tm.Name, tt.GroupName;
GO

CREATE OR ALTER VIEW dbo.vw_EventSales
AS
SELECT
    e.EventId,
    e.StartTime,
    e.Status,
    ht.Name + N' — ' + awt.Name                                               AS MatchTitle,
    v.Name                                                                    AS VenueName,
    cap.TotalSeats,
    ISNULL(s.TicketsSold, 0)                                                  AS TicketsSold,
    ISNULL(s.Revenue, 0)                                                      AS Revenue,
    CAST(100.0 * ISNULL(s.TicketsSold, 0) / NULLIF(cap.TotalSeats, 0) AS DECIMAL(5,2)) AS OccupancyPct
FROM dbo.Events e
JOIN dbo.Venues v  ON v.VenueId = e.VenueId
JOIN dbo.Teams ht  ON ht.TeamId = e.HomeTeamId
JOIN dbo.Teams awt ON awt.TeamId = e.AwayTeamId
CROSS APPLY (
    SELECT SUM(CAST(vs.RowsCount AS INT) * vs.SeatsPerRow) AS TotalSeats
    FROM dbo.VenueSectors vs
    WHERE vs.VenueId = e.VenueId
) cap
OUTER APPLY (
    SELECT COUNT(*) AS TicketsSold, SUM(t.Price) AS Revenue
    FROM dbo.Tickets t
    WHERE t.EventId = e.EventId AND t.Status IN (N'Sold', N'Used')
) s
WHERE e.IsDeleted = 0;
GO

CREATE OR ALTER FUNCTION dbo.fn_GetTeamPoints(@TournamentId INT, @TeamId INT)
RETURNS INT
AS
BEGIN
    RETURN ISNULL((SELECT Points
                     FROM dbo.vw_TournamentStandings
                    WHERE TournamentId = @TournamentId AND TeamId = @TeamId), 0);
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_GetTeamSchedule(@TeamId INT, @From DATETIME2(0), @To DATETIME2(0))
RETURNS TABLE
AS
RETURN
(
    SELECT EventId, TournamentName, VenueName, HomeTeamName, AwayTeamName,
           StartTime, Status, HomeScore, AwayScore
    FROM dbo.vw_ActiveEvents
    WHERE (HomeTeamId = @TeamId OR AwayTeamId = @TeamId)
      AND StartTime >= @From
      AND StartTime <  @To
);
GO

CREATE OR ALTER PROCEDURE dbo.sp_Team_Create
    @SportId     INT,
    @Name        NVARCHAR(150),
    @City        NVARCHAR(100),
    @FoundedYear SMALLINT = NULL,
    @ChangedBy   INT,
    @TeamId      INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.Teams WHERE SportId = @SportId AND Name = @Name AND IsDeleted = 0)
        THROW 50101, N'Команда з такою назвою вже існує в цьому виді спорту.', 1;

    INSERT INTO dbo.Teams (SportId, Name, City, FoundedYear, UpdatedBy)
    VALUES (@SportId, @Name, @City, @FoundedYear, @ChangedBy);

    SET @TeamId = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Team_Update
    @TeamId      INT,
    @Name        NVARCHAR(150),
    @City        NVARCHAR(100),
    @FoundedYear SMALLINT = NULL,
    @ChangedBy   INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Teams
       SET Name = @Name, City = @City, FoundedYear = @FoundedYear, UpdatedBy = @ChangedBy
     WHERE TeamId = @TeamId AND IsDeleted = 0;

    IF @@ROWCOUNT = 0
        THROW 50102, N'Команду не знайдено або її видалено.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Team_SoftDelete
    @TeamId    INT,
    @ChangedBy INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.Events
                WHERE (HomeTeamId = @TeamId OR AwayTeamId = @TeamId)
                  AND IsDeleted = 0
                  AND Status IN (N'Scheduled', N'Live', N'Postponed'))
        THROW 50103, N'Неможливо видалити команду з запланованими матчами.', 1;

    UPDATE dbo.Teams
       SET IsDeleted = 1, DeletedAt = SYSUTCDATETIME(), UpdatedBy = @ChangedBy
     WHERE TeamId = @TeamId AND IsDeleted = 0;

    IF @@ROWCOUNT = 0
        THROW 50102, N'Команду не знайдено або її вже видалено.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Tournament_RegisterTeam
    @TournamentId INT,
    @TeamId       INT,
    @GroupName    NVARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1
                     FROM dbo.Tournaments t
                     JOIN dbo.Teams tm ON tm.SportId = t.SportId
                    WHERE t.TournamentId = @TournamentId AND tm.TeamId = @TeamId
                      AND t.IsDeleted = 0 AND tm.IsDeleted = 0)
        THROW 50104, N'Турнір або команду не знайдено, або вид спорту не збігається.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.TournamentTeams WHERE TournamentId = @TournamentId AND TeamId = @TeamId)
        INSERT INTO dbo.TournamentTeams (TournamentId, TeamId, GroupName)
        VALUES (@TournamentId, @TeamId, @GroupName);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Event_Create
    @TournamentId    INT,
    @VenueId         INT,
    @HomeTeamId      INT,
    @AwayTeamId      INT,
    @StartTime       DATETIME2(0),
    @BaseTicketPrice DECIMAL(10,2),
    @ChangedBy       INT,
    @EventId         INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.TournamentTeams WHERE TournamentId = @TournamentId AND TeamId = @HomeTeamId)
       OR NOT EXISTS (SELECT 1 FROM dbo.TournamentTeams WHERE TournamentId = @TournamentId AND TeamId = @AwayTeamId)
        THROW 50201, N'Обидві команди мають бути зареєстровані в турнірі.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Venues WHERE VenueId = @VenueId AND IsDeleted = 0)
        THROW 50202, N'Арену не знайдено.', 1;

    IF EXISTS (SELECT 1 FROM dbo.Events
                WHERE VenueId = @VenueId
                  AND IsDeleted = 0
                  AND Status <> N'Cancelled'
                  AND ABS(DATEDIFF(MINUTE, StartTime, @StartTime)) < 180)
        THROW 50203, N'Арена зайнята: інша подія ближче ніж за 3 години.', 1;

    INSERT INTO dbo.Events (TournamentId, VenueId, HomeTeamId, AwayTeamId, StartTime, BaseTicketPrice, UpdatedBy)
    VALUES (@TournamentId, @VenueId, @HomeTeamId, @AwayTeamId, @StartTime, @BaseTicketPrice, @ChangedBy);

    SET @EventId = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Event_Update
    @EventId         INT,
    @VenueId         INT,
    @StartTime       DATETIME2(0),
    @Status          NVARCHAR(20),
    @BaseTicketPrice DECIMAL(10,2),
    @ChangedBy       INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.Events
                WHERE VenueId = @VenueId
                  AND EventId <> @EventId
                  AND IsDeleted = 0
                  AND Status <> N'Cancelled'
                  AND ABS(DATEDIFF(MINUTE, StartTime, @StartTime)) < 180)
        THROW 50203, N'Арена зайнята: інша подія ближче ніж за 3 години.', 1;

    UPDATE dbo.Events
       SET VenueId = @VenueId,
           StartTime = @StartTime,
           Status = @Status,
           BaseTicketPrice = @BaseTicketPrice,
           UpdatedBy = @ChangedBy
     WHERE EventId = @EventId AND IsDeleted = 0;

    IF @@ROWCOUNT = 0
        THROW 50204, N'Подію не знайдено або її видалено.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Event_SoftDelete
    @EventId   INT,
    @ChangedBy INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.Tickets WHERE EventId = @EventId AND Status IN (N'Sold', N'Reserved'))
        THROW 50205, N'Спочатку скасуйте продані квитки на цю подію.', 1;

    UPDATE dbo.Events
       SET IsDeleted = 1, DeletedAt = SYSUTCDATETIME(), UpdatedBy = @ChangedBy
     WHERE EventId = @EventId AND IsDeleted = 0;

    IF @@ROWCOUNT = 0
        THROW 50204, N'Подію не знайдено або її вже видалено.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Event_Restore
    @EventId   INT,
    @ChangedBy INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Events
       SET IsDeleted = 0, DeletedAt = NULL, UpdatedBy = @ChangedBy
     WHERE EventId = @EventId AND IsDeleted = 1;

    IF @@ROWCOUNT = 0
        THROW 50206, N'Серед видалених такої події немає.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_EventResult_Set
    @EventId   INT,
    @HomeScore SMALLINT,
    @AwayScore SMALLINT,
    @Notes     NVARCHAR(500) = NULL,
    @ChangedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @ownTran BIT = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION; SET @ownTran = 1; END;

        IF NOT EXISTS (SELECT 1 FROM dbo.Events WHERE EventId = @EventId AND IsDeleted = 0 AND Status <> N'Cancelled')
            THROW 50207, N'Подію не знайдено, видалено або скасовано.', 1;

        IF EXISTS (SELECT 1 FROM dbo.EventResults WHERE EventId = @EventId)
            UPDATE dbo.EventResults
               SET HomeScore = @HomeScore, AwayScore = @AwayScore, Notes = @Notes, UpdatedBy = @ChangedBy
             WHERE EventId = @EventId;
        ELSE
            INSERT INTO dbo.EventResults (EventId, HomeScore, AwayScore, Notes, UpdatedBy)
            VALUES (@EventId, @HomeScore, @AwayScore, @Notes, @ChangedBy);

        UPDATE dbo.Events
           SET Status = N'Finished', UpdatedBy = @ChangedBy
         WHERE EventId = @EventId AND Status <> N'Finished';

        IF @ownTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @ownTran = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Ticket_Purchase
    @UserId     INT,
    @EventId    INT,
    @SectorId   INT,
    @RowNumber  SMALLINT,
    @SeatNumber SMALLINT,
    @OrderId    INT OUTPUT,
    @TicketId   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @ownTran BIT = 0, @price DECIMAL(10,2);

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION; SET @ownTran = 1; END;

        SET @price = dbo.fn_GetTicketPrice(@EventId, @SectorId);
        IF @price IS NULL
            THROW 50301, N'Подію або сектор не знайдено.', 1;

        IF dbo.fn_GetAvailableSeats(@EventId) <= 0
            THROW 50302, N'Квитки на подію розпродано.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Tickets WITH (UPDLOCK, HOLDLOCK)
                    WHERE EventId = @EventId AND SectorId = @SectorId
                      AND RowNumber = @RowNumber AND SeatNumber = @SeatNumber
                      AND Status IN (N'Reserved', N'Sold', N'Used'))
            THROW 50303, N'Це місце вже зайняте.', 1;

        INSERT INTO dbo.Orders (UserId, TotalAmount, Status, UpdatedBy)
        VALUES (@UserId, @price, N'Pending', @UserId);
        SET @OrderId = SCOPE_IDENTITY();

        INSERT INTO dbo.Tickets (OrderId, EventId, SectorId, RowNumber, SeatNumber, Price, Status)
        VALUES (@OrderId, @EventId, @SectorId, @RowNumber, @SeatNumber, @price, N'Reserved');
        SET @TicketId = SCOPE_IDENTITY();

        IF @ownTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @ownTran = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Order_Pay
    @OrderId        INT,
    @Method         NVARCHAR(20),
    @TransactionRef NVARCHAR(100) = NULL,
    @PaymentId      INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @ownTran BIT = 0, @amount DECIMAL(12,2), @userId INT;

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION; SET @ownTran = 1; END;

        SELECT @amount = TotalAmount, @userId = UserId
        FROM dbo.Orders WITH (UPDLOCK)
        WHERE OrderId = @OrderId AND Status = N'Pending' AND IsDeleted = 0;

        IF @amount IS NULL
            THROW 50304, N'Замовлення не знайдено або воно вже не очікує оплати.', 1;

        INSERT INTO dbo.Payments (OrderId, Amount, Method, Status, TransactionRef)
        VALUES (@OrderId, @amount, @Method, N'Succeeded', @TransactionRef);
        SET @PaymentId = SCOPE_IDENTITY();

        UPDATE dbo.Orders  SET Status = N'Paid', UpdatedAt = SYSUTCDATETIME(), UpdatedBy = @userId WHERE OrderId = @OrderId;
        UPDATE dbo.Tickets SET Status = N'Sold' WHERE OrderId = @OrderId AND Status = N'Reserved';

        IF @ownTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @ownTran = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Order_Cancel
    @OrderId   INT,
    @ChangedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @ownTran BIT = 0, @status NVARCHAR(20);

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION; SET @ownTran = 1; END;

        SELECT @status = Status FROM dbo.Orders WITH (UPDLOCK) WHERE OrderId = @OrderId AND IsDeleted = 0;

        IF @status IS NULL OR @status IN (N'Cancelled', N'Refunded')
            THROW 50305, N'Замовлення не знайдено або вже скасоване.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Tickets WHERE OrderId = @OrderId AND Status = N'Used')
            THROW 50306, N'Квиток уже використано, скасування неможливе.', 1;

        UPDATE dbo.Tickets  SET Status = N'Cancelled' WHERE OrderId = @OrderId;
        UPDATE dbo.Payments SET Status = N'Refunded'  WHERE OrderId = @OrderId AND Status = N'Succeeded';
        UPDATE dbo.Orders
           SET Status = CASE WHEN @status = N'Paid' THEN N'Refunded' ELSE N'Cancelled' END,
               UpdatedAt = SYSUTCDATETIME(),
               UpdatedBy = @ChangedBy
         WHERE OrderId = @OrderId;

        IF @ownTran = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @ownTran = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Audit_GetHistory
    @TableName NVARCHAR(128),
    @RecordId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT a.AuditId, a.TableName, a.RecordId, a.Action,
           a.ChangedBy, u.FullName AS ChangedByName, a.ChangedAt,
           a.OldData, a.NewData
    FROM dbo.AuditLog a
    LEFT JOIN dbo.Users u ON u.UserId = a.ChangedBy
    WHERE a.TableName = @TableName AND a.RecordId = @RecordId
    ORDER BY a.ChangedAt DESC, a.AuditId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Tournament_GetStandings
    @TournamentId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TournamentId, TeamId, TeamName, GroupName, Played, Wins, Draws, Losses,
           GoalsFor, GoalsAgainst, Points
    FROM dbo.vw_TournamentStandings
    WHERE TournamentId = @TournamentId
    ORDER BY Points DESC, (GoalsFor - GoalsAgainst) DESC, GoalsFor DESC, TeamName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Report_Sales
    @From DATETIME2(0),
    @To   DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT EventId, StartTime, MatchTitle, VenueName, TotalSeats, TicketsSold, Revenue, OccupancyPct
    FROM dbo.vw_EventSales
    WHERE StartTime >= @From AND StartTime < @To
    ORDER BY Revenue DESC;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Events_AfterUpdate
ON dbo.Events
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL(@@PROCID) > 1 RETURN;

    DECLARE @sessionUser INT = dbo.fn_CurrentUserId();
    DECLARE @byColumn BIT = 0;
    IF UPDATE(UpdatedBy) SET @byColumn = 1;

    UPDATE e
       SET UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = CASE WHEN @byColumn = 1 THEN i.UpdatedBy
                            ELSE COALESCE(@sessionUser, i.UpdatedBy) END
    FROM dbo.Events e
    JOIN inserted i ON i.EventId = e.EventId;

    INSERT INTO dbo.AuditLog (TableName, RecordId, Action, ChangedBy, OldData, NewData)
    SELECT
        N'Events',
        i.EventId,
        CASE WHEN i.IsDeleted = 1 AND d.IsDeleted = 0 THEN N'DELETE'
             WHEN i.IsDeleted = 0 AND d.IsDeleted = 1 THEN N'RESTORE'
             ELSE N'UPDATE' END,
        CASE WHEN @byColumn = 1 THEN i.UpdatedBy ELSE COALESCE(@sessionUser, i.UpdatedBy) END,
        (SELECT d.VenueId, d.StartTime, d.Status, d.BaseTicketPrice, d.IsDeleted
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.VenueId, i.StartTime, i.Status, i.BaseTicketPrice, i.IsDeleted
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i
    JOIN deleted d ON d.EventId = i.EventId;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Events_InsteadOfDelete
ON dbo.Events
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE e
       SET IsDeleted = 1,
           DeletedAt = SYSUTCDATETIME(),
           UpdatedBy = COALESCE(dbo.fn_CurrentUserId(), e.UpdatedBy)
    FROM dbo.Events e
    JOIN deleted d ON d.EventId = e.EventId
    WHERE e.IsDeleted = 0;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Teams_AfterUpdate
ON dbo.Teams
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL(@@PROCID) > 1 RETURN;

    DECLARE @sessionUser INT = dbo.fn_CurrentUserId();
    DECLARE @byColumn BIT = 0;
    IF UPDATE(UpdatedBy) SET @byColumn = 1;

    UPDATE t
       SET UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = CASE WHEN @byColumn = 1 THEN i.UpdatedBy
                            ELSE COALESCE(@sessionUser, i.UpdatedBy) END
    FROM dbo.Teams t
    JOIN inserted i ON i.TeamId = t.TeamId;

    INSERT INTO dbo.AuditLog (TableName, RecordId, Action, ChangedBy, OldData, NewData)
    SELECT
        N'Teams',
        i.TeamId,
        CASE WHEN i.IsDeleted = 1 AND d.IsDeleted = 0 THEN N'DELETE'
             WHEN i.IsDeleted = 0 AND d.IsDeleted = 1 THEN N'RESTORE'
             ELSE N'UPDATE' END,
        CASE WHEN @byColumn = 1 THEN i.UpdatedBy ELSE COALESCE(@sessionUser, i.UpdatedBy) END,
        (SELECT d.Name, d.City, d.FoundedYear, d.IsDeleted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.Name, i.City, i.FoundedYear, i.IsDeleted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM inserted i
    JOIN deleted d ON d.TeamId = i.TeamId;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Teams_InsteadOfDelete
ON dbo.Teams
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t
       SET IsDeleted = 1,
           DeletedAt = SYSUTCDATETIME(),
           UpdatedBy = COALESCE(dbo.fn_CurrentUserId(), t.UpdatedBy)
    FROM dbo.Teams t
    JOIN deleted d ON d.TeamId = t.TeamId
    WHERE t.IsDeleted = 0;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_EventResults_SetWinner
ON dbo.EventResults
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF TRIGGER_NESTLEVEL(@@PROCID) > 1 RETURN;

    UPDATE r
       SET WinnerTeamId = CASE WHEN r.HomeScore > r.AwayScore THEN e.HomeTeamId
                               WHEN r.HomeScore < r.AwayScore THEN e.AwayTeamId
                               ELSE NULL END,
           UpdatedAt = SYSUTCDATETIME(),
           UpdatedBy = COALESCE(i.UpdatedBy, dbo.fn_CurrentUserId())
    FROM dbo.EventResults r
    JOIN inserted i   ON i.EventId = r.EventId
    JOIN dbo.Events e ON e.EventId = r.EventId;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Tickets_ValidateSeat
ON dbo.Tickets
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.Events e        ON e.EventId = i.EventId
        JOIN dbo.VenueSectors vs ON vs.SectorId = i.SectorId
        WHERE vs.VenueId <> e.VenueId
           OR i.RowNumber  NOT BETWEEN 1 AND vs.RowsCount
           OR i.SeatNumber NOT BETWEEN 1 AND vs.SeatsPerRow
           OR e.IsDeleted = 1
           OR e.Status IN (N'Finished', N'Cancelled')
    )
        THROW 50310, N'Некоректне місце або подія недоступна для продажу.', 1;
END;
GO
