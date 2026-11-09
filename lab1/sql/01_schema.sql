SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF DB_ID(N'SportEventsDb') IS NULL
    CREATE DATABASE SportEventsDb;
GO

USE SportEventsDb;
GO

CREATE TABLE dbo.Roles (
    RoleId  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Roles PRIMARY KEY,
    Name    NVARCHAR(50)      NOT NULL CONSTRAINT UQ_Roles_Name UNIQUE
);

CREATE TABLE dbo.Users (
    UserId       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
    RoleId       INT           NOT NULL CONSTRAINT FK_Users_Roles REFERENCES dbo.Roles(RoleId),
    Email        NVARCHAR(255) NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    FullName     NVARCHAR(150) NOT NULL,
    Phone        NVARCHAR(20)  NULL,
    CreatedAt    DATETIME2(0)  NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt    DATETIME2(0)  NULL,
    UpdatedBy    INT           NULL CONSTRAINT FK_Users_UpdatedBy REFERENCES dbo.Users(UserId),
    IsDeleted    BIT           NOT NULL CONSTRAINT DF_Users_IsDeleted DEFAULT 0,
    DeletedAt    DATETIME2(0)  NULL,
    CONSTRAINT CK_Users_Email CHECK (Email LIKE N'%_@_%._%')
);

CREATE TABLE dbo.Sports (
    SportId     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Sports PRIMARY KEY,
    Name        NVARCHAR(100) NOT NULL CONSTRAINT UQ_Sports_Name UNIQUE,
    IsTeamSport BIT           NOT NULL CONSTRAINT DF_Sports_IsTeamSport DEFAULT 1,
    Description NVARCHAR(500) NULL
);

CREATE TABLE dbo.Venues (
    VenueId   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Venues PRIMARY KEY,
    Name      NVARCHAR(150) NOT NULL,
    City      NVARCHAR(100) NOT NULL,
    Address   NVARCHAR(255) NOT NULL,
    Capacity  INT           NOT NULL CONSTRAINT CK_Venues_Capacity CHECK (Capacity > 0),
    CreatedAt DATETIME2(0)  NOT NULL CONSTRAINT DF_Venues_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0)  NULL,
    UpdatedBy INT           NULL CONSTRAINT FK_Venues_UpdatedBy REFERENCES dbo.Users(UserId),
    IsDeleted BIT           NOT NULL CONSTRAINT DF_Venues_IsDeleted DEFAULT 0,
    DeletedAt DATETIME2(0)  NULL
);

CREATE TABLE dbo.VenueSectors (
    SectorId        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_VenueSectors PRIMARY KEY,
    VenueId         INT          NOT NULL CONSTRAINT FK_VenueSectors_Venues REFERENCES dbo.Venues(VenueId),
    Name            NVARCHAR(50) NOT NULL,
    RowsCount       SMALLINT     NOT NULL CONSTRAINT CK_VenueSectors_Rows CHECK (RowsCount > 0),
    SeatsPerRow     SMALLINT     NOT NULL CONSTRAINT CK_VenueSectors_Seats CHECK (SeatsPerRow > 0),
    PriceMultiplier DECIMAL(4,2) NOT NULL CONSTRAINT DF_VenueSectors_Mult DEFAULT 1.00
                                 CONSTRAINT CK_VenueSectors_Mult CHECK (PriceMultiplier > 0),
    CONSTRAINT UQ_VenueSectors_Venue_Name UNIQUE (VenueId, Name)
);

CREATE TABLE dbo.Tournaments (
    TournamentId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Tournaments PRIMARY KEY,
    SportId      INT           NOT NULL CONSTRAINT FK_Tournaments_Sports REFERENCES dbo.Sports(SportId),
    Name         NVARCHAR(150) NOT NULL,
    Season       NVARCHAR(20)  NOT NULL,
    StartDate    DATE          NOT NULL,
    EndDate      DATE          NOT NULL,
    Status       NVARCHAR(20)  NOT NULL CONSTRAINT DF_Tournaments_Status DEFAULT N'Planned',
    CreatedAt    DATETIME2(0)  NOT NULL CONSTRAINT DF_Tournaments_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt    DATETIME2(0)  NULL,
    UpdatedBy    INT           NULL CONSTRAINT FK_Tournaments_UpdatedBy REFERENCES dbo.Users(UserId),
    IsDeleted    BIT           NOT NULL CONSTRAINT DF_Tournaments_IsDeleted DEFAULT 0,
    DeletedAt    DATETIME2(0)  NULL,
    CONSTRAINT CK_Tournaments_Dates  CHECK (EndDate >= StartDate),
    CONSTRAINT CK_Tournaments_Status CHECK (Status IN (N'Planned', N'Ongoing', N'Finished', N'Cancelled'))
);

CREATE TABLE dbo.Teams (
    TeamId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Teams PRIMARY KEY,
    SportId     INT           NOT NULL CONSTRAINT FK_Teams_Sports REFERENCES dbo.Sports(SportId),
    Name        NVARCHAR(150) NOT NULL,
    City        NVARCHAR(100) NOT NULL,
    FoundedYear SMALLINT      NULL CONSTRAINT CK_Teams_FoundedYear CHECK (FoundedYear BETWEEN 1800 AND 2100),
    CreatedAt   DATETIME2(0)  NOT NULL CONSTRAINT DF_Teams_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt   DATETIME2(0)  NULL,
    UpdatedBy   INT           NULL CONSTRAINT FK_Teams_UpdatedBy REFERENCES dbo.Users(UserId),
    IsDeleted   BIT           NOT NULL CONSTRAINT DF_Teams_IsDeleted DEFAULT 0,
    DeletedAt   DATETIME2(0)  NULL
);

CREATE TABLE dbo.Athletes (
    AthleteId   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Athletes PRIMARY KEY,
    FirstName   NVARCHAR(100) NOT NULL,
    LastName    NVARCHAR(100) NOT NULL,
    BirthDate   DATE          NOT NULL,
    Gender      CHAR(1)       NOT NULL CONSTRAINT CK_Athletes_Gender CHECK (Gender IN ('M', 'F')),
    Nationality NVARCHAR(60)  NULL,
    CreatedAt   DATETIME2(0)  NOT NULL CONSTRAINT DF_Athletes_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt   DATETIME2(0)  NULL,
    UpdatedBy   INT           NULL CONSTRAINT FK_Athletes_UpdatedBy REFERENCES dbo.Users(UserId),
    IsDeleted   BIT           NOT NULL CONSTRAINT DF_Athletes_IsDeleted DEFAULT 0,
    DeletedAt   DATETIME2(0)  NULL
);

CREATE TABLE dbo.TeamMembers (
    TeamMemberId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TeamMembers PRIMARY KEY,
    TeamId       INT          NOT NULL CONSTRAINT FK_TeamMembers_Teams REFERENCES dbo.Teams(TeamId),
    AthleteId    INT          NOT NULL CONSTRAINT FK_TeamMembers_Athletes REFERENCES dbo.Athletes(AthleteId),
    JerseyNumber TINYINT      NOT NULL,
    Position     NVARCHAR(50) NULL,
    JoinedAt     DATE         NOT NULL,
    LeftAt       DATE         NULL,
    CONSTRAINT CK_TeamMembers_Dates CHECK (LeftAt IS NULL OR LeftAt >= JoinedAt)
);

CREATE TABLE dbo.Coaches (
    CoachId       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Coaches PRIMARY KEY,
    TeamId        INT           NULL CONSTRAINT FK_Coaches_Teams REFERENCES dbo.Teams(TeamId),
    FirstName     NVARCHAR(100) NOT NULL,
    LastName      NVARCHAR(100) NOT NULL,
    LicenseNumber NVARCHAR(30)  NOT NULL CONSTRAINT UQ_Coaches_License UNIQUE,
    IsHeadCoach   BIT           NOT NULL CONSTRAINT DF_Coaches_IsHead DEFAULT 0
);

CREATE TABLE dbo.Referees (
    RefereeId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Referees PRIMARY KEY,
    SportId   INT           NOT NULL CONSTRAINT FK_Referees_Sports REFERENCES dbo.Sports(SportId),
    FirstName NVARCHAR(100) NOT NULL,
    LastName  NVARCHAR(100) NOT NULL,
    Category  NVARCHAR(30)  NOT NULL
);

CREATE TABLE dbo.TournamentTeams (
    TournamentId INT          NOT NULL CONSTRAINT FK_TournamentTeams_Tournaments REFERENCES dbo.Tournaments(TournamentId),
    TeamId       INT          NOT NULL CONSTRAINT FK_TournamentTeams_Teams REFERENCES dbo.Teams(TeamId),
    GroupName    NVARCHAR(10) NULL,
    RegisteredAt DATETIME2(0) NOT NULL CONSTRAINT DF_TournamentTeams_Reg DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_TournamentTeams PRIMARY KEY (TournamentId, TeamId)
);

CREATE TABLE dbo.Events (
    EventId         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Events PRIMARY KEY,
    TournamentId    INT           NOT NULL CONSTRAINT FK_Events_Tournaments REFERENCES dbo.Tournaments(TournamentId),
    VenueId         INT           NOT NULL CONSTRAINT FK_Events_Venues REFERENCES dbo.Venues(VenueId),
    HomeTeamId      INT           NOT NULL CONSTRAINT FK_Events_HomeTeam REFERENCES dbo.Teams(TeamId),
    AwayTeamId      INT           NOT NULL CONSTRAINT FK_Events_AwayTeam REFERENCES dbo.Teams(TeamId),
    StartTime       DATETIME2(0)  NOT NULL,
    Status          NVARCHAR(20)  NOT NULL CONSTRAINT DF_Events_Status DEFAULT N'Scheduled',
    BaseTicketPrice DECIMAL(10,2) NOT NULL CONSTRAINT CK_Events_Price CHECK (BaseTicketPrice >= 0),
    CreatedAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_Events_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2(0)  NULL,
    UpdatedBy       INT           NULL CONSTRAINT FK_Events_UpdatedBy REFERENCES dbo.Users(UserId),
    IsDeleted       BIT           NOT NULL CONSTRAINT DF_Events_IsDeleted DEFAULT 0,
    DeletedAt       DATETIME2(0)  NULL,
    CONSTRAINT CK_Events_Teams  CHECK (HomeTeamId <> AwayTeamId),
    CONSTRAINT CK_Events_Status CHECK (Status IN (N'Scheduled', N'Live', N'Finished', N'Postponed', N'Cancelled'))
);

CREATE TABLE dbo.EventReferees (
    EventId   INT          NOT NULL CONSTRAINT FK_EventReferees_Events REFERENCES dbo.Events(EventId),
    RefereeId INT          NOT NULL CONSTRAINT FK_EventReferees_Referees REFERENCES dbo.Referees(RefereeId),
    Role      NVARCHAR(30) NOT NULL CONSTRAINT CK_EventReferees_Role CHECK (Role IN (N'Main', N'Assistant', N'VAR', N'Fourth')),
    CONSTRAINT PK_EventReferees PRIMARY KEY (EventId, RefereeId)
);

CREATE TABLE dbo.EventResults (
    EventId      INT            NOT NULL CONSTRAINT PK_EventResults PRIMARY KEY
                                CONSTRAINT FK_EventResults_Events REFERENCES dbo.Events(EventId),
    HomeScore    SMALLINT       NOT NULL CONSTRAINT CK_EventResults_Home CHECK (HomeScore >= 0),
    AwayScore    SMALLINT       NOT NULL CONSTRAINT CK_EventResults_Away CHECK (AwayScore >= 0),
    WinnerTeamId INT            NULL CONSTRAINT FK_EventResults_Winner REFERENCES dbo.Teams(TeamId),
    Notes        NVARCHAR(500)  NULL,
    UpdatedAt    DATETIME2(0)   NULL,
    UpdatedBy    INT            NULL CONSTRAINT FK_EventResults_UpdatedBy REFERENCES dbo.Users(UserId)
);

CREATE TABLE dbo.Orders (
    OrderId     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
    UserId      INT           NOT NULL CONSTRAINT FK_Orders_Users REFERENCES dbo.Users(UserId),
    OrderDate   DATETIME2(0)  NOT NULL CONSTRAINT DF_Orders_Date DEFAULT SYSUTCDATETIME(),
    TotalAmount DECIMAL(12,2) NOT NULL CONSTRAINT CK_Orders_Total CHECK (TotalAmount >= 0),
    Status      NVARCHAR(20)  NOT NULL CONSTRAINT DF_Orders_Status DEFAULT N'Pending',
    UpdatedAt   DATETIME2(0)  NULL,
    UpdatedBy   INT           NULL CONSTRAINT FK_Orders_UpdatedBy REFERENCES dbo.Users(UserId),
    IsDeleted   BIT           NOT NULL CONSTRAINT DF_Orders_IsDeleted DEFAULT 0,
    DeletedAt   DATETIME2(0)  NULL,
    CONSTRAINT CK_Orders_Status CHECK (Status IN (N'Pending', N'Paid', N'Cancelled', N'Refunded'))
);

CREATE TABLE dbo.Tickets (
    TicketId   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Tickets PRIMARY KEY,
    OrderId    INT           NOT NULL CONSTRAINT FK_Tickets_Orders REFERENCES dbo.Orders(OrderId),
    EventId    INT           NOT NULL CONSTRAINT FK_Tickets_Events REFERENCES dbo.Events(EventId),
    SectorId   INT           NOT NULL CONSTRAINT FK_Tickets_Sectors REFERENCES dbo.VenueSectors(SectorId),
    RowNumber  SMALLINT      NOT NULL,
    SeatNumber SMALLINT      NOT NULL,
    Price      DECIMAL(10,2) NOT NULL CONSTRAINT CK_Tickets_Price CHECK (Price >= 0),
    Status     NVARCHAR(20)  NOT NULL CONSTRAINT DF_Tickets_Status DEFAULT N'Reserved',
    CreatedAt  DATETIME2(0)  NOT NULL CONSTRAINT DF_Tickets_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Tickets_Status CHECK (Status IN (N'Reserved', N'Sold', N'Cancelled', N'Used'))
);

CREATE TABLE dbo.Payments (
    PaymentId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Payments PRIMARY KEY,
    OrderId        INT           NOT NULL CONSTRAINT FK_Payments_Orders REFERENCES dbo.Orders(OrderId),
    Amount         DECIMAL(12,2) NOT NULL CONSTRAINT CK_Payments_Amount CHECK (Amount > 0),
    Method         NVARCHAR(20)  NOT NULL CONSTRAINT CK_Payments_Method CHECK (Method IN (N'Card', N'ApplePay', N'GooglePay', N'Cash')),
    Status         NVARCHAR(20)  NOT NULL CONSTRAINT CK_Payments_Status CHECK (Status IN (N'Pending', N'Succeeded', N'Failed', N'Refunded')),
    PaidAt         DATETIME2(0)  NOT NULL CONSTRAINT DF_Payments_PaidAt DEFAULT SYSUTCDATETIME(),
    TransactionRef NVARCHAR(100) NULL
);

CREATE TABLE dbo.Sponsors (
    SponsorId    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Sponsors PRIMARY KEY,
    Name         NVARCHAR(150) NOT NULL CONSTRAINT UQ_Sponsors_Name UNIQUE,
    Website      NVARCHAR(255) NULL,
    ContactEmail NVARCHAR(255) NULL
);

CREATE TABLE dbo.TournamentSponsors (
    TournamentId INT           NOT NULL CONSTRAINT FK_TournamentSponsors_Tournaments REFERENCES dbo.Tournaments(TournamentId),
    SponsorId    INT           NOT NULL CONSTRAINT FK_TournamentSponsors_Sponsors REFERENCES dbo.Sponsors(SponsorId),
    Amount       DECIMAL(14,2) NOT NULL CONSTRAINT CK_TournamentSponsors_Amount CHECK (Amount > 0),
    Tier         NVARCHAR(20)  NOT NULL CONSTRAINT CK_TournamentSponsors_Tier CHECK (Tier IN (N'Title', N'Gold', N'Silver', N'Partner')),
    CONSTRAINT PK_TournamentSponsors PRIMARY KEY (TournamentId, SponsorId)
);

CREATE TABLE dbo.AuditLog (
    AuditId   BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AuditLog PRIMARY KEY,
    TableName NVARCHAR(128) NOT NULL,
    RecordId  INT           NOT NULL,
    Action    NVARCHAR(10)  NOT NULL CONSTRAINT CK_AuditLog_Action CHECK (Action IN (N'INSERT', N'UPDATE', N'DELETE', N'RESTORE')),
    ChangedBy INT           NULL CONSTRAINT FK_AuditLog_Users REFERENCES dbo.Users(UserId),
    ChangedAt DATETIME2(0)  NOT NULL CONSTRAINT DF_AuditLog_ChangedAt DEFAULT SYSUTCDATETIME(),
    OldData   NVARCHAR(MAX) NULL,
    NewData   NVARCHAR(MAX) NULL
);
GO
