USE [wtrgksvf]
GO

/****** Object:  StoredProcedure [dbo].[SP_GetDashboardData_Today]    Script Date: 8/28/2025 12:46:08 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SP_GetDashboardData_Today]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE 
        @AsOf                   datetime = GETDATE(),
        @Today                  date     = CONVERT(date, GETDATE()),
        @Yesterday              date     = CONVERT(date, DATEADD(day, -1, GETDATE())),
        @PrevYearSameDate       date     = CONVERT(date, DATEADD(year, -1, GETDATE())),
        @CutoffHour             int      = DATEPART(hour, DATEADD(hour, -0, GETDATE())),
        @ExcludedTokenStampSPro bigint   = 160621121005298;

    DECLARE 
        @TotalRevenue              decimal(19,2) = 0,
        @Transactions              bigint        = 0,
        @AvgBasketSize             decimal(19,2) = NULL,
        @GrossRevenueToday         decimal(19,2) = 0,
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

    /* Sales today (0..@CutoffHour) */
    IF OBJECT_ID('tempdb..#SalesToday') IS NOT NULL DROP TABLE #SalesToday;
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
    INTO #SalesToday
    FROM Promet p WITH (NOLOCK)
    JOIN SPromet s WITH (NOLOCK)
      ON s.Sifra_Oe = p.Sifra_Oe
     AND s.Grp_Kasa = p.Grp_Kasa
     AND s.BrKasa   = p.BrKasa
     AND s.Broj_Ska = p.Broj_Ska
    WHERE p.Datum_Evid = @Today
      AND DATEPART(hour, p.DatumVreme) <= @CutoffHour
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
    GROUP BY p.Sifra_Oe, DATEPART(hour, p.DatumVreme);

    SELECT 
        @TotalRevenue = COALESCE(SUM(Amount),0),
        @Transactions = COALESCE(SUM(TxCount),0)
    FROM #SalesToday;

    SET @AvgBasketSize = CASE WHEN @Transactions > 0 THEN @TotalRevenue / @Transactions ELSE NULL END;


    /* PY + Yesterday up to the same @CutoffHour */
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
      AND DATEPART(hour, p.DatumVreme) <= @CutoffHour
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
      AND DATEPART(hour, p.DatumVreme) <= @CutoffHour
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

    /* 7-day series (only today limited by @CutoffHour) */
    IF OBJECT_ID('tempdb..#Days') IS NOT NULL DROP TABLE #Days;
    CREATE TABLE #Days (D date PRIMARY KEY);
    INSERT INTO #Days(D)
    SELECT DATEADD(day, v, @Today)
    FROM (VALUES(-6),(-5),(-4),(-3),(-2),(-1),(0)) AS t(v);

    IF OBJECT_ID('tempdb..#Rev') IS NOT NULL DROP TABLE #Rev;
    SELECT
        p.Datum_Evid AS D,
        Amount       = SUM(CAST(s.Kolic * s.Cena * (1 - s.Popust/100.0) AS decimal(19,2)))
    INTO #Rev
    FROM Promet p WITH (NOLOCK)
    JOIN SPromet s WITH (NOLOCK)
      ON s.Sifra_Oe = p.Sifra_Oe AND s.Grp_Kasa = p.Grp_Kasa AND s.BrKasa = p.BrKasa AND s.Broj_Ska = p.Broj_Ska
    WHERE p.Datum_Evid BETWEEN DATEADD(day,-6,@Today) AND @Today
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
      AND (p.Datum_Evid < @Today OR DATEPART(hour, p.DatumVreme) <= @CutoffHour)
    GROUP BY p.Datum_Evid;

    /* Hourly revenue today + PeakHour (0..@CutoffHour) */
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
    WHERE p.Datum_Evid = @Today
      AND DATEPART(hour, p.DatumVreme) <= @CutoffHour
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
    GROUP BY DATEPART(hour, p.DatumVreme);

    SELECT TOP (1)
        @PeakHour = r.HourOfDay
    FROM #RevH r
    ORDER BY r.Amount DESC, r.HourOfDay ASC;

    SET @PeakHourLabel = CASE WHEN @PeakHour IS NOT NULL 
                              THEN RIGHT('0' + CAST(@PeakHour AS varchar(2)), 2) + ':00' 
                              ELSE NULL END;

    /* Per-OE today & PY (limited to @CutoffHour) + Top store */
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
    WHERE p.Datum_Evid = @Today
      AND DATEPART(hour, p.DatumVreme) <= @CutoffHour
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
      AND DATEPART(hour, p.DatumVreme) <= @CutoffHour
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

    /* RESULT SETS */
    SELECT 
        CutoffHour             = @CutoffHour,
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
        PeakHourLabel          = @PeakHourLabel


    SELECT 
        Label  = CONVERT(varchar(10), d.D, 120),
        Amount = COALESCE(r.Amount, 0)
    FROM #Days d
    LEFT JOIN #Rev r ON r.D = d.D
    ORDER BY d.D;

    SELECT 
        HourLabel = CAST(h.H AS varchar(2)) + 'h',
        Amount    = COALESCE(r.Amount, 0)
    FROM #Hours h
    LEFT JOIN #RevH r ON r.HourOfDay = h.H
    WHERE h.H <= @CutoffHour
    ORDER BY h.H;

    SELECT Store, LastYear, ThisYear
    FROM #Store
    ORDER BY Store;
END
GO


