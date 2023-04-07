ALTER TABLE [dbo].[Header] 
ADD IsShowLineAboveHeader bit 
DEFAULT 0 NOT NULL;


ALTER TABLE [dbo].[Header] 
ADD IsShowLineBelowHeader bit 
DEFAULT 0 NOT NULL;


ALTER TABLE [dbo].[footer]
ADD IsShowLineAboveFooter bit 
DEFAULT 0 NOT NULL;

ALTER TABLE [dbo].[footer]
ADD IsShowLineBelowFooter bit 
DEFAULT 0 NOT NULL;