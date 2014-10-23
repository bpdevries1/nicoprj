IF OBJECT_ID('dbo.queuecount') IS NULL BEGIN 
	CREATE TABLE [dbo].[queuecount] (
		[cur_ts] [datetime] NULL,
		[queue] [varchar](255) NULL,
		[CEventID] [int] NULL,
		[aantal] [int] NULL
	)
END

