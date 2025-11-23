--- Create DB Tables--------------------------------------------------------------------------------------------------
CREATE DATABASE KaylahHammondPortfolio;
GO

USE KaylahHammondPortfolio;
GO


CREATE TABLE dbo.project(
	projectID INT IDENTITY (1,1) PRIMARY KEY,
	projectName VARCHAR (100)  NOT NULL,
	[description] VARCHAR (500),
	GitHubURL VARCHAR (255),
	liveDemoURL VARCHAR (255),
	isFeatured BIT DEFAULT 0
);

CREATE TABLE dbo.technologies(
technologyID INT IDENTITY (1,1)PRIMARY KEY,
technologyName  VARCHAR (100) NOT NULL,
category VARCHAR(50)
);


CREATE TABLE dbo.projectTechnologies(
projectTechID INT IDENTITY (1,1)PRIMARY KEY, 
projectID INT NOT NULL,
technologyID INT NOT NULL,
FOREIGN KEY (projectID) REFERENCES dbo.project(projectID),
FOREIGN KEY (technologyID) REFERENCES dbo.technologies(technologyID)
);

CREATE TABLE dbo.experience(
experienceID INT IDENTITY(1,1) PRIMARY KEY,
roleTitle VARCHAR (100) NOT NULL,
organization VARCHAR(100) ,
startDate DATE NOT NULL,
endDate DATE NULL,
[description] VARCHAR(500)
);

CREATE TABLE dbo.[application](
 applicationID INT IDENTITY(1,1) PRIMARY KEY,
    companyName VARCHAR(100) NOT NULL,
    positionTitle VARCHAR(100) NOT NULL,
    applicationStatus VARCHAR(50) NOT NULL,
    dateApplied DATE NOT NULL,
    notes VARCHAR(500)
);


CREATE TABLE dbo.applicationStatusHistory (
    historyID INT IDENTITY(1,1) PRIMARY KEY,
    applicationID INT NOT NULL,
    oldStatus VARCHAR(50),
    newStatus VARCHAR(50),
    changeDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (applicationID) REFERENCES dbo.[application](applicationID)
);







--Create View 1----------------------------------------------------------------------------------------------------------------

USE KaylahHammondPortfolio
GO

CREATE VIEW v_ActiveApllications AS
(SELECT applicationID,companyName,applicationStatus,dateApplied,notes
FROM dbo.[application]
WHERE applicationStatus IN ('Applied','Interview','Offered')
);


-- create view 2
USE KaylahHammondPortfolio
GO

CREATE VIEW v_FeaturedProjects AS
(SELECT  projectID,projectName,[description],GitHubURL,liveDemoURL,isFeatured
FROM dbo.project
WHERE isFeatured = 1);






--Stored Procedure---------------------------------------------------------------------------------------------------

USE KaylahHammondPortfolio
GO

CREATE PROCEDURE p_GetProjectWithTechnology
@ProjectID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.project WHERE projectID = @ProjectID)
    BEGIN
        PRINT 'No project found with the specified ProjectID.';
END

ELSE

BEGIN
SELECT 
	p.projectID,
	p.projectName,
	p.[description], 
	p.GitHubURL,
	p.liveDemoURL,
	p.isFeatured,
	t.technologyName,
	t.category
FROM dbo.project AS p LEFT JOIN dbo.projectTechnologies pt
ON p.projectID = pt.projectID
LEFT JOIN dbo.technologies AS t
ON pt.technologyID = t.technologyID
WHERE p.projectID = @ProjectID;
END
END;


EXECUTE p_GetProjectWithTechnology
@ProjectID = 1;


--trigger----------------------------------------------------------------------------------------------------------------
USE KaylahHammondPortfolio
GO


CREATE TRIGGER tr_ApplicationStatusChange
ON dbo.[application]
AFTER UPDATE

AS 
BEGIN
INSERT INTO dbo.applicationStatusHistory
( 
applicationID,
oldStatus,
newStatus,
changeDate
)

SELECT 
d.applicationID,
d.applicationStatus,
i.applicationStatus,
GETDATE()
FROM deleted AS d
JOIN inserted AS i
ON d.applicationID = i.applicationID
WHERE d.applicationStatus <> i.applicationStatus

IF @@ROWCOUNT > 0
	PRINT 'Trigger fired: application status changed logged';

END;
GO







--Sercurity----------------------------------------------------------------------------------------------------------
CREATE LOGIN PortfolioReader
WITH PASSWORD = 'Pa$$w0rd',
DEFAULT_DATABASE = KaylahHammondPortfolio, CHECK_POLICY = OFF;

GO

USE KaylahHammondPortfolio
GO

CREATE USER portfolio_user 
FOR LOGIN PortfolioReader;
GO

GRANT SELECT ON dbo.[application] TO portfolio_user;


REVOKE SELECT ON dbo.[application] TO portfolio_user;