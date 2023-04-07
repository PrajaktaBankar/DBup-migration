--Script 3 - Execute on Server - 3
--Customer Support 30527: SLC Customer Seeing {CH#} Issue

USE SLCProject;

GO

update ps set Segmentdescription = 'Samples:  Submit {CH#25174} samples of {CH#25175} units, minimum 4 inches by 4 inches, to illustrate color, texture, and extremes of color range.'
from ProjectSegment PS WITH(NOLOCK) where Segmentid = 24553817;

GO

update ps set Segmentdescription = 'Product Data on {CH#193190} Glazing Types:  Provide structural, physical and environmental characteristics, size limitations, special handling and installation requirements.'
from ProjectSegment PS WITH(NOLOCK) where Segmentid = 24554418;

END