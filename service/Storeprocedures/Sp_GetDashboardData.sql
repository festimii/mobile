USE [wtrgksvf]
GO

/****** Object:  StoredProcedure [dbo].[SP_GetDashboardData]    Script Date: 8/28/2025 12:44:02 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[SP_GetDashboardData]
    @ForDate date = NULL   -- if NULL → today, else historic date
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @ForDate IS NULL OR @ForDate = CONVERT(date, GETDATE())
    BEGIN
        -- Call today's version
        EXEC [dbo].[SP_GetDashboardData_Today];
    END
    ELSE
    BEGIN
        -- Call historic version
        EXEC [dbo].[SP_GetDashboardData_Day] @ForDate = @ForDate;
    END
END
GO


