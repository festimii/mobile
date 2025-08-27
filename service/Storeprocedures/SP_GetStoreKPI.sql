USE [wtrgksvf]
GO

/****** Object:  StoredProcedure [dbo].[SP_GetStoreKPI]    Script Date: 8/28/2025 12:46:40 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SP_GetStoreKPI]
    @ForDate                 date         = NULL,     -- NULL or today → "today/partial" path
    @AsOf                    datetime     = NULL,     -- used only on "today" path
    @CutoffHour              int          = NULL,     -- used only on "today" path
    @DatePick                nvarchar(32) = NULL,     -- optional; passed only if target proc supports it
    @ExcludedTokenStampSPro  bigint       = 160621121005298
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Today date = CONVERT(date, GETDATE());
    DECLARE @HasDatePick bit =
    (
        SELECT CASE WHEN EXISTS
        (
            SELECT 1
            FROM sys.parameters
            WHERE object_id = OBJECT_ID(N'dbo.SP_GetStoreKPI_Today')
              AND name = N'@DatePick'
        )
        THEN 1 ELSE 0 END
    );

    IF @ForDate IS NULL OR @ForDate = @Today
    BEGIN
        -- Today / partial path
        IF @HasDatePick = 1
        BEGIN
            EXEC dbo.SP_GetStoreKPI_Today
                 @ForDate                = @ForDate,
                 @AsOf                   = @AsOf,
                 @CutoffHour             = @CutoffHour,
                 @DatePick               = @DatePick,
                 @ExcludedTokenStampSPro = @ExcludedTokenStampSPro;
        END
        ELSE
        BEGIN
            EXEC dbo.SP_GetStoreKPI_Today
                 @ForDate                = @ForDate,
                 @AsOf                   = @AsOf,
                 @CutoffHour             = @CutoffHour,
                 @ExcludedTokenStampSPro = @ExcludedTokenStampSPro;
        END
    END
    ELSE
    BEGIN
        -- Historic full-day path (force full-day: ignore @AsOf/@CutoffHour/@DatePick)
        IF @HasDatePick = 1
        BEGIN
            EXEC dbo.SP_GetStoreKPI_Today
                 @ForDate                = @ForDate,
                 @AsOf                   = NULL,
                 @CutoffHour             = NULL,
                 @DatePick               = NULL,
                 @ExcludedTokenStampSPro = @ExcludedTokenStampSPro;
        END
        ELSE
        BEGIN
            EXEC dbo.SP_GetStoreKPI_Today
                 @ForDate                = @ForDate,
                 @AsOf                   = NULL,
                 @CutoffHour             = NULL,
                 @ExcludedTokenStampSPro = @ExcludedTokenStampSPro;
        END
    END
END
GO


