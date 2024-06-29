CREATE PROCEDURE prcLogEmail
AS
BEGIN

    -- Drop the temporary table if it exists
    IF OBJECT_ID('tempdb..#ENVIOLOG') IS NOT NULL
        DROP TABLE #EnvioLog;

    -- Select and transform data into the temporary table
    SELECT 
        CASE WHEN a.LogEnd IS NULL THEN 'Yellow' ELSE 'Green' END AS ExecutionStatus,
        a.IdLog AS col1,
        b.Dealer AS col2,
        CONVERT(date, GETDATE()) AS col3,
        SUBSTRING(CONVERT(varchar(100), CONVERT(time, a.LogStart)), 0, 9) AS col4,
        CASE WHEN a.LogEnd IS NULL THEN '-' ELSE SUBSTRING(CONVERT(varchar(100), CONVERT(time, a.LogEnd)), 0, 9) END AS col5,
        CASE WHEN a.SalesFileExist = 0 THEN 'Yellow' ELSE 'Green' END AS SalesFileExist,
        ISNULL(QtyArquivoVentaStage, 0) AS SalesQty,
        CASE WHEN a.SalesFileExist = 0 THEN 'Yellow' ELSE 'Green' END AS StockExists,
        ISNULL(QtyArquivoStockStage, 0) AS StockQty,
        CASE
            WHEN a.LogEnd IS NULL THEN '-'
            ELSE
                RIGHT('0' + CAST((DATEDIFF(SECOND, a.[LogStart], a.[LogEnd])/ 60) % 60 AS VARCHAR),2) + ':' +
                RIGHT('0' + CAST(DATEDIFF(SECOND, a.[LogStart], a.[LogEnd]) % 60 AS VARCHAR),2)
        END AS ExecutionTime
    INTO #EnvioLog
    FROM PCAP_ARG_HOM.dbo.tbLogImportacao a 
    LEFT JOIN PCAP_ARG_HOM.dbo.tbControleImportacao b 
        ON a.IdDistribuidor = b.IdDistribuidor
    WHERE 1=1
    AND a.LogStart BETWEEN DATEADD(HOUR, -1.5, GETDATE()) AND DATEADD(HOUR, 1.5, GETDATE())
    ORDER BY IdLog DESC

    -- Declare variables for email content
    DECLARE @STATUS_EXEC VARCHAR(100),
            @col1 VARCHAR(100),
            @col2 VARCHAR(100),
            @col3 VARCHAR(100),
            @col4 VARCHAR(100),
            @col5 VARCHAR(100),
            @STATUS_VENTA VARCHAR(100),
            @SalesQty VARCHAR(100),
            @STATUS_STOCK VARCHAR(100),
            @StockQty VARCHAR(100),
            @TEMPOEXEC VARCHAR(100),
            @HTML VARCHAR(MAX)

    -- Initialize HTML content for the email
    SET @HTML = '
    <HTML>
        <HEAD>
            <STYLE>
                TABLE {TEXT-ALIGN: LEFT; BORDER-COLLAPSE: COLLAPSE; FONT-FAMILY: VERDANA; FONT-SIZE: XX-SMALL;}
                TABLE, TD, TH {BORDER: 1PX SOLID BLACK; PADDING: 4PX;}
                TH {TEXT-ALIGN: CENTER; BACKGROUND-COLOR: #006cf0; COLOR: WHITE;}
                TH.SUBHEADER {BACKGROUND-COLOR: #006cf0;}
                TH.SUBHEADER_CANTO {BACKGROUND-COLOR: #006cf0; BORDER: NONE;}
            </STYLE>
        </HEAD>
        <BODY>
            <TABLE>
                <TR>
                    <TH COLSPAN="11">UNICARS</TH>
                </TR>
                <TR>
                    <TH CLASS="SUBHEADER">Exec</TH>
                    <TH CLASS="SUBHEADER">IdLog</TH>
                    <TH CLASS="SUBHEADER">Data</TH>
                    <TH CLASS="SUBHEADER">Dealer</TH>
                    <TH CLASS="SUBHEADER">Inicio</TH>
                    <TH CLASS="SUBHEADER">Fim</TH>
                    <TH CLASS="SUBHEADER">Arq_Venta</TH>
                    <TH CLASS="SUBHEADER">Qtd_Venta</TH>
                    <TH CLASS="SUBHEADER">Arq_Stock</TH>
                    <TH CLASS="SUBHEADER">Qtd_Stock</TH>
                    <TH CLASS="SUBHEADER">TempoExecucao</TH>
                </TR>'

    -- Declare cursor for iterating log records
    DECLARE curLog CURSOR FOR
        SELECT * FROM #EnvioLog ORDER BY IdLog DESC
    OPEN curLog;

    FETCH NEXT FROM curLog INTO @STATUS_EXEC, @col1, @col2, @col3, @col4, @col5, @STATUS_VENTA, @SalesQty, @STATUS_STOCK, @StockQty, @TEMPOEXEC

    WHILE @@FETCH_STATUS <> -1
    BEGIN
        -- Append log records to HTML content
        SET @HTML = @HTML + '<TR>';
        SET @HTML = @HTML + '<TD STYLE="BACKGROUND-COLOR: ' + CAST(@STATUS_EXEC AS VARCHAR(100)) + '"></TD>';
        SET @HTML = @HTML + '<TD>' + ISNULL(CAST(@col1 AS VARCHAR(100)), '-') + '</TD>';
        SET @HTML = @HTML + '<TD>' + ISNULL(CAST(@col2 AS VARCHAR(100)), '-') + '</TD>';
        SET @HTML = @HTML + '<TD>' + ISNULL(CAST(@col3 AS VARCHAR(100)), '-') + '</TD>';
        SET @HTML = @HTML + '<TD>' + ISNULL(CAST(@col4 AS VARCHAR(100)), '-') + '</TD>';
        SET @HTML = @HTML + '<TD>' + ISNULL(CAST(@col5 AS VARCHAR(100)), '-') + '</TD>';
        SET @HTML = @HTML + '<TD STYLE="BACKGROUND-COLOR: ' + CAST(@STATUS_VENTA AS VARCHAR(100)) + '"></TD>';
        SET @HTML = @HTML + '<TD>' + ISNULL(CAST(@SalesQty AS VARCHAR(100)), '-') + '</TD>';
        SET @HTML = @HTML + '<TD STYLE="BACKGROUND-COLOR: ' + CAST(@STATUS_STOCK AS VARCHAR(100)) + '"></TD>';
        SET @HTML = @HTML + '<TD>' + ISNULL(CAST(@StockQty AS VARCHAR(100)), '-') + '</TD>';
        SET @HTML = @HTML + '<TD>' + ISNULL(CAST(@TEMPOEXEC AS VARCHAR(100)), '-') + '</TD>';
        SET @HTML = @HTML + '</TR>';

        FETCH NEXT FROM curLog INTO @STATUS_EXEC, @col1, @col2, @col3, @col4, @col5, @STATUS_VENTA, @SalesQty, @STATUS_STOCK, @StockQty, @TEMPOEXEC
    END

    -- Close and deallocate the cursor
    CLOSE curLog;
    DEALLOCATE curLog;

    -- Finalize HTML content
    SET @HTML = @HTML + '</TABLE></BODY></HTML>'

    -- Define email subject
    DECLARE @ASSUNTO VARCHAR(100)
    SET @ASSUNTO = 'PCAP ARGENTINA - LOG - ' + CAST(CAST(GETDATE() AS DATE) AS VARCHAR(100))

    -- Send email with the generated HTML content
    EXEC msdb.dbo.sp_send_dbmail 
        @subject = @ASSUNTO,
        @body = @HTML,
        @body_format = 'HTML',
        @recipients = '"Fake Name 1" <fake.email1@example.com>; "Fake Name 2" <fake.email2@example.com>'

END
