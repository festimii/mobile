USE [wtrgksvf]
GO

/****** Object:  StoredProcedure [dbo].[SP_GetDashboardData]    Script Date: 8/28/2025 12:44:02 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SP_GetDashboardData]
    @ForDate                 date         = NULL,     -- NULL or today → "today" path
    @AsOf                    datetime     = NULL,     -- optional; forwarded to today proc
    @CutoffHour              int          = NULL,     -- optional; forwarded to today proc
    @DatePick                nvarchar(32) = NULL      -- optional semantic picker
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Today date = CONVERT(date, GETDATE());
    DECLARE @WorkDate date = ISNULL(@ForDate, @Today);

    IF @DatePick IS NOT NULL
    BEGIN
        DECLARE @p nvarchar(32) = UPPER(LTRIM(RTRIM(@DatePick)));
        IF @p = N'TODAY'
            SET @WorkDate = @Today;
        ELSE IF @p = N'YESTERDAY'
            SET @WorkDate = DATEADD(day, -1, @Today);
        ELSE IF @p = N'PY'
            SET @WorkDate = DATEADD(year, -1, @Today);
        ELSE IF @p LIKE N'D+%' OR @p LIKE N'D-%'
        BEGIN
            DECLARE @sign int = CASE WHEN SUBSTRING(@p,2,1)='+' THEN 1 ELSE -1 END;
            DECLARE @num  int = TRY_CAST(SUBSTRING(@p,3,LEN(@p)-2) AS int);
            IF @num IS NULL
            BEGIN
                RAISERROR('Invalid @DatePick relative format. Use D+N or D-N (e.g., D+3, D-2).',16,1);
                RETURN;
            END
            SET @WorkDate = DATEADD(day, @sign * @num, @Today);
        END
        ELSE
        BEGIN
            SET @WorkDate = TRY_CONVERT(date, @DatePick, 23);
            IF @WorkDate IS NULL
            BEGIN
                RAISERROR('Invalid @DatePick. Use TODAY, YESTERDAY, PY, D+N, D-N, or YYYY-MM-DD.',16,1);
                RETURN;
            END
        END
    END

    DECLARE @HasDatePickToday bit =
    (
        SELECT CASE WHEN EXISTS
        (
            SELECT 1 FROM sys.parameters
            WHERE object_id = OBJECT_ID(N'dbo.SP_GetDashboardData_Today')
              AND name = N'@DatePick'
        ) THEN 1 ELSE 0 END
    );

    IF @WorkDate = @Today
    BEGIN
        IF @HasDatePickToday = 1
        BEGIN
            EXEC dbo.SP_GetDashboardData_Today
                 @ForDate    = @WorkDate,
                 @AsOf       = @AsOf,
                 @CutoffHour = @CutoffHour,
                 @DatePick   = @DatePick;
        END
        ELSE
        BEGIN
            EXEC dbo.SP_GetDashboardData_Today
                 @ForDate    = @WorkDate,
                 @AsOf       = @AsOf,
                 @CutoffHour = @CutoffHour;
        END
    END
    ELSE
    BEGIN
        EXEC dbo.SP_GetDashboardData_Day
             @ForDate    = @WorkDate,
             @AsOf       = NULL,
             @CutoffHour = NULL,
             @DatePick   = @DatePick;
    END
END
GO


