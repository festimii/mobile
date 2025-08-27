USE [wtrgksvf]
GO

/****** Object:  StoredProcedure [dbo].[SP_GetDashboardData_Day]    Script Date: 8/28/2025 12:45:23 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SP_GetDashboardData_Day]
    @ForDate date  -- required: the calendar date to compute (full day, no cutoff)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @ForDate IS NULL
    BEGIN
        RAISERROR('ForDate is required.', 16, 1);
        RETURN;
    END

    ------------------------------------------------------------
    -- Anchors (historic mode: full day)
    ------------------------------------------------------------
    DECLARE 
        @WorkDate               date     = @ForDate,
        @Yesterday              date     = DATEADD(day, -1, @ForDate),
        @PrevYearSameDate       date     = DATEADD(year, -1, @ForDate),
        @CutoffHour             int      = NULL,   -- FULL DAY → return NULL to signal no cutoff
        @ExcludedTokenStampSPro bigint   = 160621121005298;

    ------------------------------------------------------------
    -- Output aggregates
    ------------------------------------------------------------
    DECLARE 
        @TotalRevenue              decimal(19,2) = 0,
        @Transactions              bigint        = 0,
        @AvgBasketSize             decimal(19,2) = NULL,
        @TotalRevenuePY            decimal(19,2) = 0,
        @TransactionsPY            bigint        = 0,
        @AvgBasketSizePY           decimal(19,2) = NULL,
        @RevenueYesterday          decimal(19,2) = 0,
        @TransactionsYesterday     bigint        = 0,
        @AvgBasketSizeYesterday    decimal(19,2) = NULL,
        @RevenueVsPYPct            decimal(9,2)  = NULL,
        @RevenueVsYesterdayPct     decimal(9,2)  = NULL,
        @TopStoreOE                int           = NULL,
        @TopStoreName              nvarchar(200) = NULL,
        @TopStoreRevenue           decimal(19,2) = NULL,
        @PeakHour                  int           = NULL,
        @PeakHourLabel             varchar(6)    = NULL;

    ------------------------------------------------------------
    -- Sales @WorkDate (FULL DAY)
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#SalesDay') IS NOT NULL DROP TABLE #SalesDay;
    SELECT
        p.Sifra_Oe,
        HourOfDay = DATEPART(hour, p.DatumVreme),
        Amount    = SUM(CAST(s.Kolic * s.Cena * (1 - s.Popust/100.0) AS decimal(19,2))),
        TxCount   = COUNT_BIG(DISTINCT (
                      CAST(p.Sifra_Oe AS varchar(10)) + ':' +
                      CAST(p.Grp_Kasa AS varchar(10)) + ':' +
                      CAST(p.BrKasa   AS varchar(10)) + ':' +
                      CAST(p.Broj_Ska AS varchar(10))
                   ))
    INTO #SalesDay
    FROM Promet p WITH (NOLOCK)
    JOIN SPromet s WITH (NOLOCK)
      ON s.Sifra_Oe = p.Sifra_Oe AND s.Grp_Kasa = p.Grp_Kasa AND s.BrKasa = p.BrKasa AND s.Broj_Ska = p.Broj_Ska
    WHERE p.Datum_Evid = @WorkDate
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
    GROUP BY p.Sifra_Oe, DATEPART(hour, p.DatumVreme);

    SELECT 
        @TotalRevenue = COALESCE(SUM(Amount),0),
        @Transactions = COALESCE(SUM(TxCount),0)
    FROM #SalesDay;

    SET @AvgBasketSize = CASE WHEN @Transactions > 0 THEN @TotalRevenue / @Transactions ELSE NULL END;

    ------------------------------------------------------------
    -- PY & Yesterday (FULL DAY)
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#SalesPY') IS NOT NULL DROP TABLE #SalesPY;
    SELECT
        HourOfDay = DATEPART(hour, p.DatumVreme),
        Amount    = SUM(CAST(s.Kolic * s.Cena * (1 - s.Popust/100.0) AS decimal(19,2))),
        TxCount   = COUNT_BIG(DISTINCT (
                      CAST(p.Sifra_Oe AS varchar(10)) + ':' +
                      CAST(p.Grp_Kasa AS varchar(10)) + ':' +
                      CAST(p.BrKasa   AS varchar(10)) + ':' +
                      CAST(p.Broj_Ska AS varchar(10))
                   ))
    INTO #SalesPY
    FROM Promet p WITH (NOLOCK)
    JOIN SPromet s WITH (NOLOCK)
      ON s.Sifra_Oe = p.Sifra_Oe AND s.Grp_Kasa = p.Grp_Kasa AND s.BrKasa = p.BrKasa AND s.Broj_Ska = p.Broj_Ska
    WHERE p.Datum_Evid = @PrevYearSameDate
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
    GROUP BY DATEPART(hour, p.DatumVreme);

    SELECT 
        @TotalRevenuePY = COALESCE(SUM(Amount),0),
        @TransactionsPY = COALESCE(SUM(TxCount),0)
    FROM #SalesPY;

    SET @AvgBasketSizePY = CASE WHEN @TransactionsPY > 0 THEN @TotalRevenuePY / @TransactionsPY ELSE NULL END;

    IF OBJECT_ID('tempdb..#SalesY') IS NOT NULL DROP TABLE #SalesY;
    SELECT
        HourOfDay = DATEPART(hour, p.DatumVreme),
        Amount    = SUM(CAST(s.Kolic * s.Cena * (1 - s.Popust/100.0) AS decimal(19,2))),
        TxCount   = COUNT_BIG(DISTINCT (
                      CAST(p.Sifra_Oe AS varchar(10)) + ':' +
                      CAST(p.Grp_Kasa AS varchar(10)) + ':' +
                      CAST(p.BrKasa   AS varchar(10)) + ':' +
                      CAST(p.Broj_Ska AS varchar(10))
                   ))
    INTO #SalesY
    FROM Promet p WITH (NOLOCK)
    JOIN SPromet s WITH (NOLOCK)
      ON s.Sifra_Oe = p.Sifra_Oe AND s.Grp_Kasa = p.Grp_Kasa AND s.BrKasa = p.BrKasa AND s.Broj_Ska = p.Broj_Ska
    WHERE p.Datum_Evid = @Yesterday
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
    GROUP BY DATEPART(hour, p.DatumVreme);

    SELECT 
        @RevenueYesterday      = COALESCE(SUM(Amount),0),
        @TransactionsYesterday = COALESCE(SUM(TxCount),0)
    FROM #SalesY;

    SET @AvgBasketSizeYesterday = CASE WHEN @TransactionsYesterday > 0 
                                       THEN @RevenueYesterday / @TransactionsYesterday 
                                       ELSE NULL END;

    SET @RevenueVsPYPct        = CASE WHEN @TotalRevenuePY   > 0 THEN ROUND((@TotalRevenue - @TotalRevenuePY) * 100.0 / @TotalRevenuePY, 2) ELSE NULL END;
    SET @RevenueVsYesterdayPct = CASE WHEN @RevenueYesterday > 0 THEN ROUND((@TotalRevenue - @RevenueYesterday) * 100.0 / @RevenueYesterday, 2) ELSE NULL END;

    ------------------------------------------------------------
    -- 7-day series around @WorkDate (FULL days)
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Days') IS NOT NULL DROP TABLE #Days;
    CREATE TABLE #Days (D date PRIMARY KEY);
    INSERT INTO #Days(D)
    SELECT DATEADD(day, v, @WorkDate)
    FROM (VALUES(-6),(-5),(-4),(-3),(-2),(-1),(0)) AS t(v);

    IF OBJECT_ID('tempdb..#Rev') IS NOT NULL DROP TABLE #Rev;
    SELECT
        p.Datum_Evid AS D,
        Amount       = SUM(CAST(s.Kolic * s.Cena * (1 - s.Popust/100.0) AS decimal(19,2)))
    INTO #Rev
    FROM Promet p WITH (NOLOCK)
    JOIN SPromet s WITH (NOLOCK)
      ON s.Sifra_Oe = p.Sifra_Oe AND s.Grp_Kasa = p.Grp_Kasa AND s.BrKasa = p.BrKasa AND s.Broj_Ska = p.Broj_Ska
    WHERE p.Datum_Evid BETWEEN DATEADD(day,-6,@WorkDate) AND @WorkDate
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
    GROUP BY p.Datum_Evid;

    ------------------------------------------------------------
    -- Hourly revenue @WorkDate (FULL 0..23) + PeakHour
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Hours') IS NOT NULL DROP TABLE #Hours;
    CREATE TABLE #Hours (H int PRIMARY KEY);
    INSERT INTO #Hours(H)
    SELECT v FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),
                          (12),(13),(14),(15),(16),(17),(18),(19),(20),(21),
                          (22),(23)) AS t(v);

    IF OBJECT_ID('tempdb..#RevH') IS NOT NULL DROP TABLE #RevH;
    SELECT
        HourOfDay = DATEPART(hour, p.DatumVreme),
        Amount    = SUM(CAST(s.Kolic * s.Cena * (1 - s.Popust/100.0) AS decimal(19,2)))
    INTO #RevH
    FROM Promet p WITH (NOLOCK)
    JOIN SPromet s WITH (NOLOCK)
      ON s.Sifra_Oe = p.Sifra_Oe AND s.Grp_Kasa = p.Grp_Kasa AND s.BrKasa = p.BrKasa AND s.Broj_Ska = p.Broj_Ska
    WHERE p.Datum_Evid = @WorkDate
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
    GROUP BY DATEPART(hour, p.DatumVreme);

    SELECT TOP (1)
        @PeakHour = r.HourOfDay
    FROM #RevH r
    ORDER BY r.Amount DESC, r.HourOfDay ASC;

    SET @PeakHourLabel = CASE WHEN @PeakHour IS NOT NULL 
                              THEN RIGHT('0' + CAST(@PeakHour AS varchar(2)), 2) + ':00' 
                              ELSE NULL END;

    ------------------------------------------------------------
    -- Per-OE @WorkDate & PY (FULL days) + Top store
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#TodayOe') IS NOT NULL DROP TABLE #TodayOe;
    IF OBJECT_ID('tempdb..#PYOe')    IS NOT NULL DROP TABLE #PYOe;
    IF OBJECT_ID('tempdb..#Store')   IS NOT NULL DROP TABLE #Store;

    SELECT
        p.Sifra_Oe,
        Amount = SUM(CAST(s.Kolic * s.Cena * (1 - s.Popust/100.0) AS decimal(19,2)))
    INTO #TodayOe
    FROM Promet p WITH (NOLOCK)
    JOIN SPromet s WITH (NOLOCK)
      ON s.Sifra_Oe = p.Sifra_Oe AND s.Grp_Kasa = p.Grp_Kasa AND s.BrKasa = p.BrKasa AND s.Broj_Ska = p.Broj_Ska
    WHERE p.Datum_Evid = @WorkDate
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
    GROUP BY p.Sifra_Oe;

    SELECT
        p.Sifra_Oe,
        Amount = SUM(CAST(s.Kolic * s.Cena * (1 - s.Popust/100.0) AS decimal(19,2)))
    INTO #PYOe
    FROM Promet p WITH (NOLOCK)
    JOIN SPromet s WITH (NOLOCK)
      ON s.Sifra_Oe = p.Sifra_Oe AND s.Grp_Kasa = p.Grp_Kasa AND s.BrKasa = p.BrKasa AND s.Broj_Ska = p.Broj_Ska
    WHERE p.Datum_Evid = @PrevYearSameDate
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
    GROUP BY p.Sifra_Oe;

    IF OBJECT_ID('tempdb..#KeyOe') IS NOT NULL DROP TABLE #KeyOe;
    SELECT Sifra_Oe AS OE INTO #KeyOe
    FROM #TodayOe
    UNION
    SELECT Sifra_Oe FROM #PYOe;

    SELECT 
        Store =
            CASE 
                WHEN o2.Sifra_Oe = 3 THEN 'VFS 03 Ferizaj'
                WHEN o2.Sifra_Oe IS NULL
                     THEN 'OE ' + CAST(CASE WHEN k.OE = 33 THEN 3 ELSE k.OE END AS varchar(10))
                ELSE o2.ImeOrg
            END,
        LastYear = COALESCE(py.Amount, 0),
        ThisYear = COALESCE(t.Amount, 0),
        OE       = k.OE
    INTO #Store
    FROM #KeyOe AS k
    LEFT JOIN #TodayOe AS t ON t.Sifra_Oe = k.OE
    LEFT JOIN #PYOe   AS py ON py.Sifra_Oe = k.OE
    LEFT JOIN orged   AS o2 WITH (NOLOCK)
           ON o2.Sifra_Oe = CASE WHEN k.OE = 33 THEN 3 ELSE k.OE END;

    SELECT TOP (1)
        @TopStoreOE      = s.OE,
        @TopStoreName    = s.Store,
        @TopStoreRevenue = s.ThisYear
    FROM #Store s
    ORDER BY s.ThisYear DESC, s.Store ASC;

    ------------------------------------------------------------
    -- RESULT SETS (same shape as *_Today)
    ------------------------------------------------------------
    -- 1) Summary KPIs
    SELECT 
        CutoffHour             = @CutoffHour,   -- NULL = full day
        TotalRevenue           = @TotalRevenue,
        Transactions           = CAST(@Transactions AS int),
        AvgBasketSize          = @AvgBasketSize,
        TotalRevenuePY         = @TotalRevenuePY,
        TransactionsPY         = CAST(@TransactionsPY AS int),
        AvgBasketSizePY        = @AvgBasketSizePY,
        RevenueYesterday       = @RevenueYesterday,
        RevenueVsYesterdayPct  = @RevenueVsYesterdayPct,
        RevenueVsPYPct         = @RevenueVsPYPct,
        TopStoreOE             = @TopStoreOE,
        TopStoreName           = @TopStoreName,
        TopStoreRevenue        = @TopStoreRevenue,
        PeakHour               = @PeakHour,
        PeakHourLabel          = @PeakHourLabel;

    -- 2) 7-day series (Label, Amount)
    SELECT 
        Label  = CONVERT(varchar(10), d.D, 120),
        Amount = COALESCE(r.Amount, 0)
    FROM #Days d
    LEFT JOIN #Rev r ON r.D = d.D
    ORDER BY d.D;

    -- 3) Hourly series (0..23)
    SELECT 
        HourLabel = CAST(h.H AS varchar(2)) + 'h',
        Amount    = COALESCE(r.Amount, 0)
    FROM #Hours h
    LEFT JOIN #RevH r ON r.HourOfDay = h.H
    WHERE h.H <= 23
    ORDER BY h.H;

    -- 4) Store comparison
    SELECT Store, LastYear, ThisYear
    FROM #Store
    ORDER BY Store;
END
GO


