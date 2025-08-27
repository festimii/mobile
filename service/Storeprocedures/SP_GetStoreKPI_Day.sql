USE [wtrgksvf]
GO

/****** Object:  StoredProcedure [dbo].[SP_GetStoreKPI_Day]    Script Date: 8/28/2025 12:47:09 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Time-synchronized with SP_GetDashboardData_Day, with flexible date picking:
-- - FULL DAY when both @AsOf and @CutoffHour are NULL  → cutoff = 23
-- - PARTIAL when @AsOf and/or @CutoffHour is provided → cutoff resolved from inputs
-- - @DatePick lets callers choose date semantically (TODAY/YESTERDAY/PY/D+N/D-N or explicit 'YYYY-MM-DD')
Create PROCEDURE [dbo].[SP_GetStoreKPI_Day]
    @ForDate                 date        = NULL,   -- optional: explicit date
    @AsOf                    datetime    = NULL,   -- optional: reference timestamp (derives date / cutoff)
    @CutoffHour              int         = NULL,   -- optional [0..23]; default HOUR(@AsOf-1h) in partial mode
    @DatePick                nvarchar(32)= NULL,   -- optional semantic picker: TODAY | YESTERDAY | PY | D+N | D-N | 'YYYY-MM-DD'
    @ExcludedTokenStampSPro  bigint      = 160621121005298
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    ----------------------------------------------------------------------
    -- 0) Resolve anchors & cutoff (same rules as dashboard proc) + DatePick
    ----------------------------------------------------------------------
    DECLARE @AsOfLocal datetime = ISNULL(@AsOf, GETDATE());
    DECLARE @TodayDate date     = CONVERT(date, @AsOfLocal);

    -- If @DatePick provided, it overrides @ForDate
    IF @DatePick IS NOT NULL
    BEGIN
        DECLARE @p nvarchar(32) = UPPER(LTRIM(RTRIM(@DatePick)));

        IF @p = N'TODAY'
            SET @ForDate = @TodayDate;
        ELSE IF @p = N'YESTERDAY'
            SET @ForDate = DATEADD(day, -1, @TodayDate);
        ELSE IF @p = N'PY'
            -- Previous year same calendar date relative to TODAY (or @AsOf)
            SET @ForDate = DATEADD(year, -1, @TodayDate);
        ELSE IF @p LIKE N'D+%' OR @p LIKE N'D-%'
        BEGIN
            -- Relative day offset: D+N or D-N, N is integer days relative to @AsOfLocal date
            DECLARE @sign int = CASE WHEN SUBSTRING(@p,2,1)='+' THEN 1 ELSE -1 END;
            DECLARE @num  int = TRY_CAST(SUBSTRING(@p,3, LEN(@p)-2) AS int);
            IF @num IS NULL
            BEGIN
                RAISERROR('Invalid @DatePick relative format. Use D+N or D-N (e.g., D+3, D-2).',16,1);
                RETURN;
            END
            SET @ForDate = DATEADD(day, @sign * @num, @TodayDate);
        END
        ELSE
        BEGIN
            -- Try explicit ISO date
            SET @ForDate = TRY_CONVERT(date, @DatePick, 23); -- 'YYYY-MM-DD'
            IF @ForDate IS NULL
            BEGIN
                RAISERROR('Invalid @DatePick. Use TODAY, YESTERDAY, PY, D+N, D-N, or YYYY-MM-DD.',16,1);
                RETURN;
            END
        END
    END

    -- Final work date
    DECLARE @WorkDate date = ISNULL(@ForDate, @TodayDate);
    DECLARE @PrevYear date = DATEADD(year, -1, @WorkDate);

    -- Optional guard: prevent future dates relative to @AsOfLocal (can remove if not desired)
    IF @WorkDate > @TodayDate
    BEGIN
        RAISERROR('ForDate cannot be in the future relative to @AsOf.',16,1);
        RETURN;
    END

    -- Full vs Partial day resolution
    DECLARE @IsFullDay bit =
        CASE WHEN @AsOf IS NULL AND @CutoffHour IS NULL THEN 1 ELSE 0 END;

    DECLARE @Cutoff int =
        CASE 
            WHEN @IsFullDay = 1 THEN 23
            ELSE ISNULL(@CutoffHour, DATEPART(hour, DATEADD(hour, -1, @AsOfLocal)))
        END;
    IF @Cutoff < 0  SET @Cutoff = 0;
    IF @Cutoff > 23 SET @Cutoff = 23;

    ----------------------------------------------------------------------
    -- 1) TODAY (at @WorkDate) per-store aggregates (Revenue, TxCount)
    ----------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#TodayStore') IS NOT NULL DROP TABLE #TodayStore;

    SELECT
        p.Sifra_Oe,
        RevenueToday = SUM(CAST(s.Kolic * s.Cena * (1.0 - s.Popust/100.0) AS decimal(19,2))),
        TxToday      = COUNT(DISTINCT
                             CAST(p.Sifra_Oe AS varchar(10)) + ':' +
                             CAST(p.Grp_Kasa AS varchar(10)) + ':' +
                             CAST(p.BrKasa   AS varchar(10)) + ':' +
                             CAST(p.Broj_Ska AS varchar(10)))
    INTO #TodayStore
    FROM Promet AS p WITH (NOLOCK)
    JOIN SPromet AS s WITH (NOLOCK)
      ON s.Sifra_Oe = p.Sifra_Oe
     AND s.Grp_Kasa = p.Grp_Kasa
     AND s.BrKasa   = p.BrKasa
     AND s.Broj_Ska = p.Broj_Ska
    WHERE p.Datum_Evid = @WorkDate
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
      AND DATEPART(hour, p.DatumVreme) <= @Cutoff
    GROUP BY p.Sifra_Oe;

    ----------------------------------------------------------------------
    -- 2) PY (same calendar date) per-store aggregates, same cutoff
    ----------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#PYStore') IS NOT NULL DROP TABLE #PYStore;

    SELECT
        p.Sifra_Oe,
        RevenuePY = SUM(CAST(s.Kolic * s.Cena * (1.0 - s.Popust/100.0) AS decimal(19,2))),
        TxPY      = COUNT(DISTINCT
                          CAST(p.Sifra_Oe AS varchar(10)) + ':' +
                          CAST(p.Grp_Kasa AS varchar(10)) + ':' +
                          CAST(p.BrKasa   AS varchar(10)) + ':' +
                          CAST(p.Broj_Ska AS varchar(10)))
    INTO #PYStore
    FROM Promet AS p WITH (NOLOCK)
    JOIN SPromet AS s WITH (NOLOCK)
      ON s.Sifra_Oe = p.Sifra_Oe
     AND s.Grp_Kasa = p.Grp_Kasa
     AND s.BrKasa   = p.BrKasa
     AND s.Broj_Ska = p.Broj_Ska
    WHERE p.Datum_Evid = @PrevYear
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
      AND DATEPART(hour, p.DatumVreme) <= @Cutoff
    GROUP BY p.Sifra_Oe;

    ----------------------------------------------------------------------
    -- 3) TODAY hourly revenue per store -> peak hour (up to @Cutoff)
    ----------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#TodayHourly') IS NOT NULL DROP TABLE #TodayHourly;

    SELECT
        p.Sifra_Oe,
        H       = DATEPART(hour, p.DatumVreme),
        Revenue = SUM(CAST(s.Kolic * s.Cena * (1.0 - s.Popust/100.0) AS decimal(19,2)))
    INTO #TodayHourly
    FROM Promet AS p WITH (NOLOCK)
    JOIN SPromet AS s WITH (NOLOCK)
      ON s.Sifra_Oe = p.Sifra_Oe
     AND s.Grp_Kasa = p.Grp_Kasa
     AND s.BrKasa   = p.BrKasa
     AND s.Broj_Ska = p.Broj_Ska
    WHERE p.Datum_Evid = @WorkDate
      AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
      AND DATEPART(hour, p.DatumVreme) <= @Cutoff
    GROUP BY p.Sifra_Oe, DATEPART(hour, p.DatumVreme);

    ;WITH RankedPeak AS
    (
        SELECT
            th.Sifra_Oe,
            PeakHour        = th.H,
            PeakHourRevenue = th.Revenue,
            rn = ROW_NUMBER() OVER (PARTITION BY th.Sifra_Oe ORDER BY th.Revenue DESC, th.H ASC)
        FROM #TodayHourly th
    ),
    Peak AS
    (
        SELECT Sifra_Oe, PeakHour, PeakHourRevenue
        FROM RankedPeak
        WHERE rn = 1
    ),

    ----------------------------------------------------------------------
    -- 4) Top Article per Store (by revenue @WorkDate up to @Cutoff)
    ----------------------------------------------------------------------
    TopArtAgg AS
    (
        SELECT
            p.Sifra_Oe,
            s.Sifra_Art,
            Revenue = SUM(CAST(s.Kolic * s.Cena * (1.0 - s.Popust/100.0) AS decimal(19,2)))
        FROM Promet p WITH (NOLOCK)
        JOIN SPromet s WITH (NOLOCK)
          ON s.Sifra_Oe = p.Sifra_Oe
         AND s.Grp_Kasa = p.Grp_Kasa
         AND s.BrKasa   = p.BrKasa
         AND s.Broj_Ska = p.Broj_Ska
        WHERE p.Datum_Evid = @WorkDate
          AND (s.TokenStampSPro IS NULL OR s.TokenStampSPro <> @ExcludedTokenStampSPro)
          AND DATEPART(hour, p.DatumVreme) <= @Cutoff
        GROUP BY p.Sifra_Oe, s.Sifra_Art
    ),
    RankedTopArt AS
    (
        SELECT
            ta.Sifra_Oe,
            ta.Sifra_Art,
            ta.Revenue,
            rn = ROW_NUMBER() OVER (PARTITION BY ta.Sifra_Oe ORDER BY ta.Revenue DESC, ta.Sifra_Art ASC)
        FROM TopArtAgg ta
    ),
    TopArt AS
    (
        SELECT Sifra_Oe, Sifra_Art, Revenue
        FROM RankedTopArt
        WHERE rn = 1
    ),

    ----------------------------------------------------------------------
    -- 5) Name source: arkakatprom (dedup by Sifra_Art)
    ----------------------------------------------------------------------
    NameSrc AS
    (
        SELECT
            LTRIM(RTRIM(akp.Sifra_Art)) AS Sifra_Art,
            MAX(akp.ImeArt)             AS ImeArt
        FROM dbo.arkakatprom akp WITH (NOLOCK)
        WHERE akp.Sifra_Art IS NOT NULL
        GROUP BY LTRIM(RTRIM(akp.Sifra_Art))
    ),
    KeyOE AS
    (
        SELECT Sifra_Oe FROM #TodayStore
        UNION
        SELECT Sifra_Oe FROM #PYStore
    )
    SELECT
        sKey.Sifra_Oe                                                   AS StoreId,
        StoreName        = COALESCE(o2.ImeOrg, 'OE ' + CAST(sKey.Sifra_Oe AS varchar(10))),
        EffectiveDate    = @WorkDate,        -- <== picked date echo
        CutoffHourUsed   = @Cutoff,          -- <== applied cutoff echo

        -- Core KPIs (time-synchronized)
        RevenueToday = ISNULL(t.RevenueToday, 0.00),
        RevenuePY    = ISNULL(py.RevenuePY, 0.00),
        TxToday      = ISNULL(t.TxToday, 0),
        TxPY         = ISNULL(py.TxPY, 0),

        -- Derived: Average Basket
        AvgBasketToday = CASE WHEN ISNULL(t.TxToday, 0) = 0 THEN NULL
                              ELSE CAST(ISNULL(t.RevenueToday, 0.00) / NULLIF(t.TxToday, 0) AS decimal(19, 2)) END,
        AvgBasketPY    = CASE WHEN ISNULL(py.TxPY, 0) = 0 THEN NULL
                              ELSE CAST(ISNULL(py.RevenuePY, 0.00) / NULLIF(py.TxPY, 0)   AS decimal(19, 2)) END,

        -- Deltas & % changes
        RevenueDiff    = CAST(ISNULL(t.RevenueToday,0.00) - ISNULL(py.RevenuePY,0.00) AS decimal(19,2)),
        RevenuePct     = CASE WHEN ISNULL(py.RevenuePY,0) = 0 THEN NULL
                              ELSE CAST( (ISNULL(t.RevenueToday,0.00) - ISNULL(py.RevenuePY,0.00))
                                         / NULLIF(py.RevenuePY,0.00) * 100.0 AS decimal(9,2)) END,
        TxDiff         = CAST(ISNULL(t.TxToday,0) - ISNULL(py.TxPY,0) AS int),
        TxPct          = CASE WHEN ISNULL(py.TxPY,0) = 0 THEN NULL
                              ELSE CAST( (ISNULL(t.TxToday,0.0) - ISNULL(py.TxPY,0.0))
                                         / NULLIF(CONVERT(float, py.TxPY),0.0) * 100.0 AS decimal(9,2)) END,
        AvgBasketDiff  = CASE
                            WHEN (CASE WHEN ISNULL(py.TxPY,0)=0 THEN NULL
                                       ELSE CAST(ISNULL(py.RevenuePY,0.00) / NULLIF(py.TxPY,0) AS decimal(19,2)) END) IS NULL
                            THEN NULL
                            ELSE CAST(
                                 (CASE WHEN ISNULL(t.TxToday,0)=0 THEN NULL
                                       ELSE CAST(ISNULL(t.RevenueToday,0.00)/NULLIF(t.TxToday,0) AS decimal(19,2)) END)
                                 -
                                 (CASE WHEN ISNULL(py.TxPY,0)=0 THEN NULL
                                       ELSE CAST(ISNULL(py.RevenuePY,0.00)/NULLIF(py.TxPY,0) AS decimal(19,2)) END)
                                 AS decimal(19,2))
                         END,

        -- Peak hour (today @WorkDate)
        PeakHour         = p.PeakHour,
        PeakHourLabel    = CASE WHEN p.PeakHour IS NULL THEN NULL ELSE CAST(p.PeakHour AS varchar(2)) + 'h' END,
        PeakHourRevenue  = p.PeakHourRevenue,

        -- Top article (today @WorkDate)
        TopArtCode       = ta.Sifra_Art,
        TopArtRevenue    = ta.Revenue,
        TopArtName       = COALESCE(ns.ImeArt, ta.Sifra_Art)
    FROM KeyOE sKey
    LEFT JOIN #TodayStore t ON t.Sifra_Oe = sKey.Sifra_Oe
    LEFT JOIN #PYStore   py ON py.Sifra_Oe = sKey.Sifra_Oe
    LEFT JOIN Peak       p  ON p.Sifra_Oe  = sKey.Sifra_Oe
    LEFT JOIN TopArt     ta ON ta.Sifra_Oe = sKey.Sifra_Oe
    LEFT JOIN orged o2   WITH (NOLOCK)
           ON o2.Sifra_Oe = CASE WHEN sKey.Sifra_Oe = 33 THEN 3 ELSE sKey.Sifra_Oe END
    LEFT JOIN NameSrc ns ON ns.Sifra_Art = LTRIM(RTRIM(ta.Sifra_Art))
    ORDER BY StoreName ASC;
END
GO


