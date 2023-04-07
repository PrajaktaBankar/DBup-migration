----Header-----------------------------------------------------------------------------------
IF not exists(select top 1 1 from Header pdf WITH(NOLOCK) where pdf.ProjectId is NULL)
BEGIN

	SELECT * into #tmpHeader from OPENJSON('[{"HeaderId":859,"IsLocked":false,"ShowFirstPage":true,"CreatedBy":0,"CreatedDate":"2019-02-04T04:42:49.9133333","ModifiedBy":0,"ModifiedDate":"2019-02-04T04:42:49.9133333","TypeId":1,"HeaderFooterCategoryId":1,"DateFormat":"Short","TimeFormat":"Short","HeaderFooterDisplayTypeId":1,"DefaultHeader":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\"><br><\/td><td style=\"width: 33.0000%;text-align:center;\"><\/td><td style=\"width:33.0000%;text-align:right;\"><\/td><\/tr><\/tbody><\/table>","FirstPageHeader":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\"><br><\/td><td style=\"width: 33.0000%;text-align:center;\"><\/td><td style=\"width:33.0000%;text-align:right;\"><\/td><\/tr><\/tbody><\/table>","OddPageHeader":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\"><br><\/td><td style=\"width: 33.0000%;text-align:center;\"><\/td><td style=\"width:33.0000%;text-align:right;\"><\/td><\/tr><\/tbody><\/table>","EvenPageHeader":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\"><br><\/td><td style=\"width: 33.0000%;text-align:center;\"><\/td><td style=\"width:33.0000%;text-align:right;\"><\/td><\/tr><\/tbody><\/table>","DocumentTypeId":1},{"HeaderId":8141,"IsLocked":false,"ShowFirstPage":true,"CreatedBy":0,"CreatedDate":"2019-10-12T04:49:57.2600000","ModifiedBy":0,"ModifiedDate":"2019-10-12T04:49:57.2600000","TypeId":1,"HeaderFooterCategoryId":1,"DateFormat":"Short","TimeFormat":"Short","HeaderFooterDisplayTypeId":1,"DocumentTypeId":2},{"HeaderId":9795,"IsLocked":false,"ShowFirstPage":true,"CreatedBy":0,"CreatedDate":"2019-11-30T06:04:23.1900000","ModifiedBy":0,"ModifiedDate":"2019-11-30T06:04:23.1900000","TypeId":1,"HeaderFooterCategoryId":1,"DateFormat":"Short","TimeFormat":"Short","HeaderFooterDisplayTypeId":1,"DocumentTypeId":3}]')
	WITH(
	ShowFirstPage bit,
	TypeId int,
	HeaderFooterCategoryId int,
	[DateFormat] NVARCHAR(100),
	TimeFormat	NVARCHAR(100),
	HeaderFooterDisplayTypeId int,
	DefaultHeader NVARCHAR(1000),
	FirstPageHeader NVARCHAR(1000),
	OddPageHeader NVARCHAR(1000),
	EvenPageHeader NVARCHAR(1000),
	DocumentTypeId int)


	insert into Header(ShowFirstPage,TypeId,HeaderFooterCategoryId,[DateFormat],TimeFormat,HeaderFooterDisplayTypeId,DefaultHeader,FirstPageHeader,OddPageHeader,EvenPageHeader,DocumentTypeId,CreatedDate,CreatedBy)
	select t.*,getutcdate(),0 #tmpHeader  t
END

----Footer----------------------------------------------------------------------------
IF not exists(select top 1 1 from Footer pdf WITH(NOLOCK) where pdf.ProjectId is NULL)
BEGIN
	SELECT * into #tmpFooter from OPENJSON('[{"FooterId":849,"IsLocked":false,"ShowFirstPage":true,"CreatedBy":0,"CreatedDate":"2019-02-04T04:42:49.9266667","ModifiedBy":0,"ModifiedDate":"2019-02-04T04:42:49.9266667","TypeId":1,"HeaderFooterCategoryId":1,"DateFormat":"Short","TimeFormat":"Short","HeaderFooterDisplayTypeId":1,"DefaultFooter":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\">{KW#ProjectName}&nbsp;<\/td><td style=\"width: 33.0000%;text-align:center;\">{KW#SectionID} - {KW#PageNumber}&nbsp;<\/td><td style=\"width:33.0000%;text-align:right;\">{KW#SectionName}&nbsp;<\/td><\/tr><\/table>","FirstPageFooter":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\">{KW#ProjectName}&nbsp;<\/td><td style=\"width: 33.0000%;text-align:center;\">{KW#SectionID} - {KW#PageNumber}&nbsp;<\/td><td style=\"width:33.0000%;text-align:right;\">{KW#SectionName}&nbsp;<\/td><\/tr><\/table>","OddPageFooter":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\">{KW#ProjectName}&nbsp;<\/td><td style=\"width: 33.0000%;text-align:center;\">{KW#SectionID} - {KW#PageNumber}&nbsp;<\/td><td style=\"width:33.0000%;text-align:right;\">{KW#SectionName}&nbsp;<\/td><\/tr><\/table>","EvenPageFooter":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\">{KW#ProjectName}&nbsp;<\/td><td style=\"width: 33.0000%;text-align:center;\">{KW#SectionID} - {KW#PageNumber}&nbsp;<\/td><td style=\"width:33.0000%;text-align:right;\">{KW#SectionName}&nbsp;<\/td><\/tr><\/table>","DocumentTypeId":1},{"FooterId":8138,"IsLocked":false,"ShowFirstPage":true,"CreatedBy":0,"CreatedDate":"2019-10-12T04:49:57.2766667","ModifiedBy":0,"ModifiedDate":"2019-10-12T04:49:57.2766667","TypeId":1,"HeaderFooterCategoryId":1,"DateFormat":"Short","TimeFormat":"Short","HeaderFooterDisplayTypeId":1,"DefaultFooter":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\">{KW#ProjectName}&nbsp;<\/td><td style=\"width: 33.0000%;text-align:center;\">{KW#ReportName}&nbsp;<\/td><td style=\"width:33.0000%;text-align:right;\">{KW#DateField}&nbsp;<\/td><\/tr><\/table>","FirstPageFooter":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\">{KW#ProjectName}&nbsp;<\/td><td style=\"width: 33.0000%;text-align:center;\">{KW#ReportName}&nbsp;<\/td><td style=\"width:33.0000%;text-align:right;\">{KW#DateField}&nbsp;<\/td><\/tr><\/table>","OddPageFooter":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\">{KW#ProjectName}&nbsp;<\/td><td style=\"width: 33.0000%;text-align:center;\">{KW#ReportName}&nbsp;<\/td><td style=\"width:33.0000%;text-align:right;\">{KW#DateField}&nbsp;<\/td><\/tr><\/table>","EvenPageFooter":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\">{KW#ProjectName}&nbsp;<\/td><td style=\"width: 33.0000%;text-align:center;\">{KW#ReportName}&nbsp;<\/td><td style=\"width:33.0000%;text-align:right;\">{KW#DateField}&nbsp;<\/td><\/tr><\/table>","DocumentTypeId":2},{"FooterId":9796,"IsLocked":false,"ShowFirstPage":true,"CreatedBy":0,"CreatedDate":"2019-11-30T06:04:23.2000000","ModifiedBy":0,"ModifiedDate":"2019-11-30T06:04:23.2000000","TypeId":1,"HeaderFooterCategoryId":1,"DateFormat":"Short","TimeFormat":"Short","HeaderFooterDisplayTypeId":1,"DefaultFooter":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\">{KW#ProjectName}&nbsp;<\/td><td style=\"width: 33.0000%;text-align:center;\">{KW#ReportName}&nbsp;<\/td><td style=\"width:33.0000%;text-align:right;\">{KW#DateField}&nbsp;<\/td><\/tr><\/table>","FirstPageFooter":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\">{KW#ProjectName}&nbsp;<\/td><td style=\"width: 33.0000%;text-align:center;\">{KW#ReportName}&nbsp;<\/td><td style=\"width:33.0000%;text-align:right;\">{KW#DateField}&nbsp;<\/td><\/tr><\/table>","OddPageFooter":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\">{KW#ProjectName}&nbsp;<\/td><td style=\"width: 33.0000%;text-align:center;\">{KW#ReportName}&nbsp;<\/td><td style=\"width:33.0000%;text-align:right;\">{KW#DateField}&nbsp;<\/td><\/tr><\/table>","EvenPageFooter":"<table style=\"width: 100%;\" class=\"fr-invisible-borders\"><tbody><tr><td style=\"width: 33.0000%;text-align:left;\">{KW#ProjectName}&nbsp;<\/td><td style=\"width: 33.0000%;text-align:center;\">{KW#ReportName}&nbsp;<\/td><td style=\"width:33.0000%;text-align:right;\">{KW#DateField}&nbsp;<\/td><\/tr><\/table>","DocumentTypeId":3}]')
	WITH(
	ShowFirstPage bit,
	TypeId int,
	HeaderFooterCategoryId int,
	[DateFormat] NVARCHAR(100),
	TimeFormat	NVARCHAR(100),
	HeaderFooterDisplayTypeId int,
	DefaultFooter NVARCHAR(1000),
	FirstPageFooter NVARCHAR(1000),
	OddPageFooter NVARCHAR(1000),
	EvenPageFooter NVARCHAR(1000),
	DocumentTypeId int)

	insert into Footer(ShowFirstPage,TypeId,HeaderFooterCategoryId,[DateFormat],TimeFormat,HeaderFooterDisplayTypeId,DefaultFooter,FirstPageFooter,OddPageFooter,EvenPageFooter,DocumentTypeId,CreatedDate)
	select t.*,getutcdate() from #tmpFooter
	
END

----ProjectDateFormat----------------------------------------------------------------------------------
if not exists(select top 1 1 from ProjectDateFormat pdf WITH(NOLOCK) where pdf.ProjectId is NULL)
BEGIN
	drop TABLE if EXISTS #tmpProjectDateFormat 
	SELECT * into #tmpProjectDateFormat from OPENJSON('[{"MasterDataTypeId":1,"ClockFormat":"12-hr","DateFormat":"MM-dd-yyyy"},{"MasterDataTypeId":2,"ClockFormat":"12-hr","DateFormat":"dd-MM-yyyy"},{"MasterDataTypeId":3,"ClockFormat":"24-hr","DateFormat":"dd-MM-yyyy"},{"MasterDataTypeId":4,"ClockFormat":"12-hr","DateFormat":"dd-MM-yyyy"}]')
	WITH(
		MasterDataTypeId INT,
		ClockFormat NVARCHAR(100),
		DateFormat NVARCHAR(100)
	)

	insert into ProjectDateFormat(MasterDataTypeId,ClockFormat,DateFormat,CreateDate)
	select t.*,GETUTCDATE() from #tmpProjectDateFormat t
END

----ProjectPrintSetting-----------------------------------------------------------------------------------
if not exists(select top 1 1 from ProjectPrintSetting pdf WITH(NOLOCK) where pdf.ProjectId is NULL)
BEGIN
	insert into ProjectPrintSetting(IsExportInMultipleFiles,IsBeginSectionOnOddPage,IsIncludeAuthorInFileName,TCPrintModeId,IsIncludePageCount,IsIncludeHyperLink)
	SELECT 0,0,1,3,0,0
END
--------------------------------------------------------------------------------------------------------